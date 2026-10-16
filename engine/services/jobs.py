"""Background jobs (arch §4.2): persisted in ``background_jobs``, cancellable, resumable.

Each job runs as an asyncio task on the engine loop. Progress is written to the database
(heartbeat, progress, checkpoint) and published on the event bus as ``job.*`` events so the
UI can show per-job progress without polling.
"""

from __future__ import annotations

import asyncio
import json
from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from typing import Any

import structlog
from sqlalchemy import insert, select, update

from core.errors import NotFound
from core.ids import uuid7
from core.timeutil import now_iso
from services.state import ActiveProfile, EngineState

log = structlog.get_logger(__name__)


class JobCancelled(Exception):
    pass


@dataclass
class JobContext:
    job_id: str
    job_type: str
    active: ActiveProfile
    manager: JobManager
    params: dict[str, Any]
    checkpoint_data: dict[str, Any] | None = None
    _cancel: asyncio.Event = field(default_factory=asyncio.Event)

    @property
    def cancelled(self) -> bool:
        return self._cancel.is_set()

    def raise_if_cancelled(self) -> None:
        if self._cancel.is_set():
            raise JobCancelled()

    async def progress(self, percent: int, message: str = "", **data: Any) -> None:
        percent = max(0, min(100, int(percent)))
        T = self.active.tables
        values = {"progress": percent, "heartbeat_at": now_iso()}
        await asyncio.to_thread(
            self._write, update(T.background_jobs).where(T.background_jobs.c.id == self.job_id).values(**values)
        )
        self.manager.state.events.publish(
            "job.progress",
            {"job_id": self.job_id, "job_type": self.job_type, "progress": percent, "message": message, **data},
        )

    async def checkpoint(self, data: dict[str, Any]) -> None:
        T = self.active.tables
        await asyncio.to_thread(
            self._write,
            update(T.background_jobs)
            .where(T.background_jobs.c.id == self.job_id)
            .values(checkpoint=json.dumps(data), heartbeat_at=now_iso()),
        )

    def _write(self, stmt: Any) -> None:
        with self.active.db.tx() as conn:
            conn.execute(stmt)


JobRunner = Callable[[JobContext], Awaitable[dict[str, Any] | None]]


class JobManager:
    def __init__(self, state: EngineState) -> None:
        self.state = state
        self._tasks: dict[str, tuple[str, asyncio.Task[None], JobContext]] = {}

    def has_running_for(self, user_id: str) -> bool:
        return any(uid == user_id and not task.done() for uid, task, _ in self._tasks.values())

    def submit(
        self,
        active: ActiveProfile,
        job_type: str,
        params: dict[str, Any],
        runner: JobRunner,
        *,
        job_id: str | None = None,
        checkpoint: dict[str, Any] | None = None,
    ) -> str:
        T = active.tables
        if job_id is None:
            job_id = uuid7()
            with active.db.tx() as conn:
                conn.execute(
                    insert(T.background_jobs).values(
                        id=job_id,
                        user_id=active.user_id,
                        job_type=job_type,
                        status="running",
                        params=json.dumps(params),
                        started_at=now_iso(),
                        heartbeat_at=now_iso(),
                        attempts=1,
                    )
                )
        else:
            with active.db.tx() as conn:
                conn.execute(
                    update(T.background_jobs)
                    .where(T.background_jobs.c.id == job_id)
                    .values(
                        status="running",
                        started_at=now_iso(),
                        cancel_requested=0,
                        attempts=T.background_jobs.c.attempts + 1,
                    )
                )
        ctx = JobContext(
            job_id=job_id, job_type=job_type, active=active, manager=self, params=params, checkpoint_data=checkpoint
        )
        task = asyncio.get_running_loop().create_task(self._run(ctx, runner), name=f"job-{job_id}")
        self._tasks[job_id] = (active.user_id, task, ctx)
        self.state.events.publish("job.started", {"job_id": job_id, "job_type": job_type})
        return job_id

    async def _run(self, ctx: JobContext, runner: JobRunner) -> None:
        status, error, result = "completed", None, None
        try:
            result = await runner(ctx)
        except (JobCancelled, asyncio.CancelledError):
            status = "cancelled"
        except Exception as exc:
            status, error = "failed", type(exc).__name__
            log.exception("job_failed", job_type=ctx.job_type)
        finally:
            self._tasks.pop(ctx.job_id, None)
        if self.state.active is ctx.active:
            T = ctx.active.tables
            try:
                with ctx.active.db.tx() as conn:
                    conn.execute(
                        update(T.background_jobs)
                        .where(T.background_jobs.c.id == ctx.job_id)
                        .values(
                            status=status,
                            finished_at=now_iso(),
                            error_message=error,
                            progress=100 if status == "completed" else T.background_jobs.c.progress,
                        )
                    )
            except Exception:  # noqa: BLE001 - profile may have been locked meanwhile
                log.warning("job_status_not_saved", job_type=ctx.job_type)
        self.state.events.publish(
            f"job.{status}", {"job_id": ctx.job_id, "job_type": ctx.job_type, "error": error, "result": result or {}}
        )

    def cancel(self, active: ActiveProfile, job_id: str) -> None:
        entry = self._tasks.get(job_id)
        T = active.tables
        with active.db.tx() as conn:
            found = conn.execute(
                select(T.background_jobs.c.id).where(
                    T.background_jobs.c.id == job_id, T.background_jobs.c.user_id == active.user_id
                )
            ).first()
            if found is None:
                raise NotFound("job not found", code="job_not_found")
            conn.execute(update(T.background_jobs).where(T.background_jobs.c.id == job_id).values(cancel_requested=1))
        if entry is not None:
            entry[2]._cancel.set()

    def cancel_all_for(self, user_id: str) -> None:
        for uid, task, ctx in list(self._tasks.values()):
            if uid == user_id:
                ctx._cancel.set()
                task.cancel()

    def interrupted_jobs(self, active: ActiveProfile) -> list[dict[str, Any]]:
        """Jobs left running by a previous engine process (crash or close) — resumable."""
        T = active.tables
        with active.db.tx() as conn:
            rows = (
                conn.execute(
                    select(T.background_jobs).where(
                        T.background_jobs.c.user_id == active.user_id,
                        T.background_jobs.c.status.in_(("running", "queued")),
                    )
                )
                .mappings()
                .all()
            )
            ids = [r["id"] for r in rows if r["id"] not in self._tasks]
            if ids:
                conn.execute(update(T.background_jobs).where(T.background_jobs.c.id.in_(ids)).values(status="paused"))
        return [dict(r) | {"status": "paused"} for r in rows if r["id"] in ids]
