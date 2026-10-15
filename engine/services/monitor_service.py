"""Scheduled monitors, reminders and notifications (module M13).

The schedule is persisted (``monitors.next_run_at``), so a monitor that was due while the
application was closed runs at the next start (EF-13.08: local monitoring only runs while the
app is open or minimised to the tray — the UI says so).
"""

from __future__ import annotations

import json
from datetime import UTC, datetime, timedelta
from typing import Any

import structlog
from sqlalchemy import and_, delete, desc, insert, select, update

from core.errors import NotFound, ValidationFailed
from core.ids import uuid7
from core.timeutil import iso, now_iso, utcnow
from services.state import ActiveProfile, EngineState

log = structlog.get_logger(__name__)

NOTIFICATION_KINDS = (
    "new_opportunities",
    "opportunity_changed",
    "deadline",
    "source_failure",
    "expired",
    "monitor_failed",
    "sync",
    "update_available",
    "system",
)
MIN_INTERVAL_HOURS = 24  # catalogue sources allow at most one scan per day
DAYS = {
    "mon": 0,
    "tue": 1,
    "wed": 2,
    "thu": 3,
    "fri": 4,
    "sat": 5,
    "sun": 6,
    "lun": 0,
    "mar": 1,
    "mer": 2,
    "jeu": 3,
    "ven": 4,
    "sam": 5,
    "dim": 6,
}


def next_run(kind: str, expr: str, after: datetime) -> datetime:
    """daily 'HH:MM' · weekly 'DOW HH:MM' · custom_cron 'every Nh' (N >= 24) — times in UTC."""
    if kind == "daily":
        h, m = (int(x) for x in expr.split(":"))
        candidate = after.replace(hour=h, minute=m, second=0, microsecond=0)
        return candidate if candidate > after else candidate + timedelta(days=1)
    if kind == "weekly":
        dow, hm = expr.split()
        h, m = (int(x) for x in hm.split(":"))
        days_ahead = (DAYS[dow.lower()[:3]] - after.weekday()) % 7
        candidate = (after + timedelta(days=days_ahead)).replace(hour=h, minute=m, second=0, microsecond=0)
        return candidate if candidate > after else candidate + timedelta(days=7)
    if kind == "custom_cron":
        hours = int(expr.lower().replace("every", "").replace("h", "").strip())
        return after + timedelta(hours=hours)
    raise ValueError(kind)


def validate_schedule(kind: str, expr: str) -> None:
    try:
        if kind == "custom_cron":
            hours = int(expr.lower().replace("every", "").replace("h", "").strip())
            if hours < MIN_INTERVAL_HOURS:
                raise ValidationFailed(
                    "monitors cannot run more than once a day",
                    code="monitor_too_frequent",
                    extra={"minimum_hours": MIN_INTERVAL_HOURS},
                )
        next_run(kind, expr, utcnow())
    except ValidationFailed:
        raise
    except (ValueError, KeyError) as exc:
        raise ValidationFailed("invalid schedule", code="monitor_schedule_invalid") from exc


class NotificationService:
    def __init__(self, active: ActiveProfile, state: EngineState) -> None:
        self.active = active
        self.state = state
        self.T = active.tables
        self.uid = active.user_id

    def _enabled(self, conn: Any, kind: str) -> tuple[bool, bool]:
        """(enabled, within quiet hours)."""
        pref = (
            conn.execute(
                select(self.T.notification_preferences).where(
                    self.T.notification_preferences.c.user_id == self.uid,
                    self.T.notification_preferences.c.kind == kind,
                )
            )
            .mappings()
            .first()
        )
        if pref is None:
            return True, False
        quiet = False
        if pref["quiet_from"] and pref["quiet_to"]:
            now = datetime.now().strftime("%H:%M")
            a, b = pref["quiet_from"], pref["quiet_to"]
            quiet = (a <= now < b) if a <= b else (now >= a or now < b)
        return bool(pref["enabled"]), quiet

    def notify(self, conn: Any, kind: str, title: str, body: str | None, payload: dict[str, Any]) -> str | None:
        enabled, quiet = self._enabled(conn, kind)
        if not enabled:
            return None
        nid = uuid7()
        conn.execute(
            insert(self.T.notification_records).values(
                id=nid,
                user_id=self.uid,
                kind=kind,
                title=title[:200],
                body=(body or "")[:1000] or None,
                payload=json.dumps(payload),
                channel="in_app" if quiet else "native",
            )
        )
        self.state.events.publish(
            "notification",
            {"id": nid, "kind": kind, "title": title, "body": body, "native": not quiet, "payload": payload},
        )
        return nid

    def list_items(self, unread_only: bool = False, limit: int = 100) -> list[dict[str, Any]]:
        T = self.T
        stmt = select(T.notification_records).where(T.notification_records.c.user_id == self.uid)
        if unread_only:
            stmt = stmt.where(T.notification_records.c.read_at.is_(None))
        with self.active.db.read() as conn:
            return [
                dict(r) | {"payload": json.loads(r["payload"]) if r["payload"] else {}}
                for r in conn.execute(stmt.order_by(desc(T.notification_records.c.created_at)).limit(limit)).mappings()
            ]

    def mark_read(self, ids: list[str] | None) -> None:
        T = self.T
        stmt = update(T.notification_records).where(
            T.notification_records.c.user_id == self.uid, T.notification_records.c.read_at.is_(None)
        )
        if ids:
            stmt = stmt.where(T.notification_records.c.id.in_(ids))
        with self.active.db.tx() as conn:
            conn.execute(stmt.values(read_at=now_iso()))

    def preferences(self) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.read() as conn:
            stored = {
                r["kind"]: dict(r)
                for r in conn.execute(
                    select(T.notification_preferences).where(T.notification_preferences.c.user_id == self.uid)
                ).mappings()
            }
            offsets = conn.execute(
                select(T.application_settings.c.value).where(
                    T.application_settings.c.key == "reminders.default_offsets"
                )
            ).scalar()
        prefs = [
            stored.get(k, {"kind": k, "enabled": 1, "quiet_from": None, "quiet_to": None}) for k in NOTIFICATION_KINDS
        ]
        return [
            p | {"enabled": bool(p["enabled"]), "reminder_offsets": json.loads(offsets or "[14,7,3,1]")} for p in prefs
        ]

    def set_preference(self, kind: str, enabled: bool, quiet_from: str | None, quiet_to: str | None) -> None:
        if kind not in NOTIFICATION_KINDS:
            raise ValidationFailed("unknown notification kind", code="notification_kind_invalid")
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(
                delete(T.notification_preferences).where(
                    T.notification_preferences.c.user_id == self.uid, T.notification_preferences.c.kind == kind
                )
            )
            conn.execute(
                insert(T.notification_preferences).values(
                    user_id=self.uid, kind=kind, enabled=int(enabled), quiet_from=quiet_from, quiet_to=quiet_to
                )
            )

    def set_reminder_offsets(self, offsets: list[int]) -> None:
        clean = sorted({o for o in offsets if 0 <= o <= 90}, reverse=True)
        if not clean:
            raise ValidationFailed("at least one reminder offset", code="reminder_offsets_invalid")
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(
                update(T.application_settings)
                .where(T.application_settings.c.key == "reminders.default_offsets")
                .values(value=json.dumps(clean), updated_at=now_iso())
            )


class MonitorService:
    def __init__(self, active: ActiveProfile, state: EngineState) -> None:
        self.active = active
        self.state = state
        self.T = active.tables
        self.uid = active.user_id

    def _get(self, conn: Any, monitor_id: str) -> dict[str, Any]:
        row = (
            conn.execute(
                select(self.T.monitors).where(self.T.monitors.c.id == monitor_id, self.T.monitors.c.user_id == self.uid)
            )
            .mappings()
            .first()
        )
        if row is None:
            raise NotFound("monitor not found", code="monitor_not_found")
        return dict(row)

    def _present(self, conn: Any, m: dict[str, Any]) -> dict[str, Any]:
        T = self.T
        sources = (
            conn.execute(select(T.monitor_sources.c.source_id).where(T.monitor_sources.c.monitor_id == m["id"]))
            .scalars()
            .all()
        )
        last = (
            conn.execute(
                select(T.monitor_runs)
                .where(T.monitor_runs.c.monitor_id == m["id"])
                .order_by(desc(T.monitor_runs.c.started_at))
                .limit(1)
            )
            .mappings()
            .first()
        )
        return m | {
            "filters": json.loads(m["filters"]),
            "enabled": bool(m["enabled"]),
            "source_ids": list(sources),
            "last_run": dict(last) if last else None,
        }

    def list_items(self) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.read() as conn:
            rows = [
                dict(r)
                for r in conn.execute(
                    select(T.monitors).where(T.monitors.c.user_id == self.uid).order_by(T.monitors.c.created_at)
                ).mappings()
            ]
            return [self._present(conn, r) for r in rows]

    def get(self, monitor_id: str) -> dict[str, Any]:
        with self.active.db.read() as conn:
            return self._present(conn, self._get(conn, monitor_id))

    def create(self, values: dict[str, Any]) -> dict[str, Any]:
        validate_schedule(values["schedule_kind"], values["schedule_expr"])
        T = self.T
        monitor_id = uuid7()
        with self.active.db.tx() as conn:
            conn.execute(
                insert(T.monitors).values(
                    id=monitor_id,
                    user_id=self.uid,
                    workspace_id=values.get("workspace_id"),
                    name=values["name"],
                    filters=json.dumps(values["filters"]),
                    schedule_kind=values["schedule_kind"],
                    schedule_expr=values["schedule_expr"],
                    min_score=values.get("min_score", 50),
                    enabled=1,
                    next_run_at=iso(next_run(values["schedule_kind"], values["schedule_expr"], utcnow())),
                )
            )
            for sid in values.get("source_ids") or []:
                conn.execute(insert(T.monitor_sources).values(monitor_id=monitor_id, source_id=sid))
        return self.get(monitor_id)

    def update(self, monitor_id: str, values: dict[str, Any]) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            current = self._get(conn, monitor_id)
            kind = values.get("schedule_kind", current["schedule_kind"])
            expr = values.get("schedule_expr", current["schedule_expr"])
            validate_schedule(kind, expr)
            changes: dict[str, Any] = {
                k: v
                for k, v in values.items()
                if k in ("name", "schedule_kind", "schedule_expr", "min_score") and v is not None
            }
            if "filters" in values and values["filters"] is not None:
                changes["filters"] = json.dumps(values["filters"])
            if "enabled" in values and values["enabled"] is not None:
                changes["enabled"] = 1 if values["enabled"] else 0
            changes["next_run_at"] = iso(next_run(kind, expr, utcnow()))
            changes["updated_at"] = now_iso()
            conn.execute(update(T.monitors).where(T.monitors.c.id == monitor_id).values(**changes))
            if values.get("source_ids") is not None:
                conn.execute(delete(T.monitor_sources).where(T.monitor_sources.c.monitor_id == monitor_id))
                for sid in values["source_ids"]:
                    conn.execute(insert(T.monitor_sources).values(monitor_id=monitor_id, source_id=sid))
        return self.get(monitor_id)

    def delete(self, monitor_id: str) -> None:
        with self.active.db.tx() as conn:
            self._get(conn, monitor_id)
            conn.execute(delete(self.T.monitors).where(self.T.monitors.c.id == monitor_id))

    def runs(self, monitor_id: str) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.read() as conn:
            self._get(conn, monitor_id)
            return [
                dict(r)
                for r in conn.execute(
                    select(T.monitor_runs)
                    .where(T.monitor_runs.c.monitor_id == monitor_id)
                    .order_by(desc(T.monitor_runs.c.started_at))
                    .limit(50)
                ).mappings()
            ]

    def due(self) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.read() as conn:
            return [
                dict(r)
                for r in conn.execute(
                    select(T.monitors).where(
                        T.monitors.c.user_id == self.uid,
                        T.monitors.c.enabled == 1,
                        T.monitors.c.next_run_at <= now_iso(),
                    )
                ).mappings()
            ]

    async def run(self, monitor_id: str) -> dict[str, Any]:
        """Run a monitor now: a search with trigger 'monitor', then notify new relevant items."""
        import asyncio

        from services.search_service import SearchService

        with self.active.db.read() as conn:
            m = self._present(conn, self._get(conn, monitor_id))
        search = SearchService(self.active, self.state)
        filters = dict(m["filters"])
        prepared = await asyncio.to_thread(
            search.prepare_run,
            filters.get("raw") or m["name"],
            filters,
            workspace_id=m["workspace_id"],
            source_ids=m["source_ids"] or None,
            trigger="monitor",
        )
        T = self.T
        run_row_id = uuid7()
        with self.active.db.tx() as conn:
            conn.execute(
                insert(T.monitor_runs).values(
                    id=run_row_id, monitor_id=monitor_id, search_run_id=prepared["run_id"], status="running"
                )
            )
            conn.execute(
                update(T.monitors)
                .where(T.monitors.c.id == monitor_id)
                .values(
                    last_run_at=now_iso(), next_run_at=iso(next_run(m["schedule_kind"], m["schedule_expr"], utcnow()))
                )
            )
        if prepared["sources"] == 0:
            await asyncio.to_thread(self._finish, run_row_id, "skipped_offline", 0, False, m, prepared["run_id"])
            return {"run_id": prepared["run_id"], "status": "skipped_offline"}

        async def runner(ctx: Any) -> dict[str, Any]:
            try:
                result = await search.runner(prepared["run_id"])(ctx)
            except BaseException:
                await asyncio.to_thread(self._finish, run_row_id, "failed", 0, False, m, prepared["run_id"])
                raise
            await asyncio.to_thread(self._after_run, run_row_id, m, prepared["run_id"])
            return result

        if self.state.jobs is None:
            raise RuntimeError("job manager not initialised")
        job_id = self.state.jobs.submit(self.active, "monitor", {"monitor_id": monitor_id}, runner)
        return {"run_id": prepared["run_id"], "job_id": job_id, "status": "running"}

    def _after_run(self, run_row_id: str, m: dict[str, Any], search_run_id: str) -> None:
        T = self.T
        with self.active.db.read() as conn:
            new_ids = (
                conn.execute(
                    select(T.search_results.c.opportunity_id).where(
                        T.search_results.c.search_run_id == search_run_id, T.search_results.c.is_new == 1
                    )
                )
                .scalars()
                .all()
            )
            relevant = (
                conn.execute(
                    select(T.match_scores.c.opportunity_id).where(
                        T.match_scores.c.user_id == self.uid,
                        T.match_scores.c.opportunity_id.in_(new_ids),
                        T.match_scores.c.score >= m["min_score"],
                    )
                )
                .scalars()
                .all()
                if new_ids
                else []
            )
            status = conn.execute(select(T.search_runs.c.status).where(T.search_runs.c.id == search_run_id)).scalar()
        self._finish(
            run_row_id,
            "completed" if status == "completed" else "partial",
            len(relevant),
            bool(relevant),
            m,
            search_run_id,
        )

    def _finish(
        self, run_row_id: str, status: str, new_items: int, notify: bool, m: dict[str, Any], search_run_id: str
    ) -> None:
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(
                update(T.monitor_runs)
                .where(T.monitor_runs.c.id == run_row_id)
                .values(status=status, new_items=new_items, notified=int(notify), finished_at=now_iso())
            )
            ns = NotificationService(self.active, self.state)
            if notify:
                ns.notify(
                    conn,
                    "new_opportunities",
                    f"{m['name']} : {new_items} nouvelle(s) opportunité(s)",
                    None,
                    {"monitor_id": m["id"], "run_id": search_run_id},
                )
            elif status == "failed":
                ns.notify(conn, "monitor_failed", f"{m['name']} : échec de la veille", None, {"monitor_id": m["id"]})

    # ------------------------------------------------------------ periodic
    def due_reminders(self) -> int:
        """Send pending reminders whose time has come (EF-13.05)."""
        T = self.T
        sent = 0
        with self.active.db.tx() as conn:
            rows = (
                conn.execute(
                    select(T.reminders).where(
                        T.reminders.c.user_id == self.uid,
                        T.reminders.c.status == "pending",
                        T.reminders.c.remind_at <= now_iso(),
                    )
                )
                .mappings()
                .all()
            )
            ns = NotificationService(self.active, self.state)
            for r in rows:
                body = f"J-{r['offset_days']}" if r["offset_days"] is not None else None
                ns.notify(conn, "deadline", r["title"], body, {"saved_id": r["saved_id"], "reminder_id": r["id"]})
                conn.execute(
                    update(T.reminders).where(T.reminders.c.id == r["id"]).values(status="sent", sent_at=now_iso())
                )
                sent += 1
        return sent

    def source_failure_alerts(self) -> int:
        """EF-13.06: alert once when a source fails three times in a row."""
        T = self.T
        alerted = 0
        with self.active.db.tx() as conn:
            failing = conn.execute(
                select(T.sources.c.id, T.sources.c.name).where(
                    T.sources.c.enabled == 1, T.sources.c.consecutive_failures == 3
                )
            ).all()
            ns = NotificationService(self.active, self.state)
            for sid, name in failing:
                already = conn.execute(
                    select(T.notification_records.c.id).where(
                        T.notification_records.c.user_id == self.uid,
                        T.notification_records.c.kind == "source_failure",
                        T.notification_records.c.payload.like(f'%"{sid}"%'),
                        T.notification_records.c.created_at >= iso(datetime.now(UTC) - timedelta(days=7)),
                    )
                ).first()
                if already is None:
                    ns.notify(conn, "source_failure", f"Source indisponible : {name}", None, {"source_id": sid})
                    alerted += 1
        return alerted

    def history(self) -> list[dict[str, Any]]:
        """EF-13.07: run history across all monitors."""
        T = self.T
        with self.active.db.read() as conn:
            return [
                dict(r)
                for r in conn.execute(
                    select(T.monitor_runs, T.monitors.c.name)
                    .join(T.monitors, T.monitors.c.id == T.monitor_runs.c.monitor_id)
                    .where(and_(T.monitors.c.user_id == self.uid))
                    .order_by(desc(T.monitor_runs.c.started_at))
                    .limit(100)
                ).mappings()
            ]
