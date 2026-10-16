from __future__ import annotations

import asyncio
import io
import os
import subprocess
import sys
import threading
import time
from pathlib import Path

from sqlalchemy import select

import main
from services.jobs import JobContext
from tests.conftest import EngineClient


def test_read_token_times_out_on_silent_stdin() -> None:
    class Silent(io.StringIO):
        def readline(self, *_: object) -> str:
            time.sleep(2)
            return ""

    t0 = time.monotonic()
    assert main._read_token(Silent(), timeout=0.2) == ""
    assert time.monotonic() - t0 < 1.5
    assert main._read_token(io.StringIO("abc\n"), timeout=1) == "abc"


def test_single_instance_lock(tmp_path: Path) -> None:
    first = main.SingleInstanceLock(tmp_path / "engine.lock")
    assert first.acquire()
    second = main.SingleInstanceLock(tmp_path / "engine.lock")
    assert not second.acquire()


def test_serve_refuses_short_token(monkeypatch: object) -> None:
    import pytest

    mp = pytest.MonkeyPatch()
    mp.setattr(main.sys, "stdin", io.StringIO("short\n"))
    try:
        assert main.serve() == 2
    finally:
        mp.undo()


def _sleeper() -> subprocess.Popen[bytes]:
    return subprocess.Popen([sys.executable, "-c", "import time; time.sleep(60)"])


def test_watch_parent_fires_when_the_process_ends() -> None:
    from core.parent_watch import watch_parent

    proc = _sleeper()
    fired = threading.Event()
    watch_parent(proc.pid, fired.set)
    assert not fired.wait(0.5)
    proc.kill()
    proc.wait()
    assert fired.wait(10)


def test_engine_stops_when_the_desktop_app_dies(tmp_path: Path) -> None:
    """Regression: a crashed or force-killed app left the engine running, holding the instance lock."""
    app = _sleeper()
    env = {**os.environ, "OPX_DATA_DIR": str(tmp_path), "PYTHONUNBUFFERED": "1"}
    engine = subprocess.Popen(  # noqa: S603 - fixed argv: this interpreter and main.py
        [sys.executable, str(Path(main.__file__)), "--parent-pid", str(app.pid)],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        env=env,
        cwd=Path(main.__file__).parent,
    )
    try:
        assert engine.stdin and engine.stdout
        engine.stdin.write(b"t" * 40 + b"\n")
        engine.stdin.close()
        assert engine.stdout.readline().startswith(b"PORT:")
        assert engine.poll() is None
        app.kill()
        app.wait()
        assert engine.wait(timeout=20) == 0
        assert main.SingleInstanceLock(tmp_path / "engine.lock").acquire()
    finally:
        for p in (app, engine):
            if p.poll() is None:
                p.kill()


def test_self_test_mode_passes() -> None:
    assert main.main(["--self-test"]) == 0


def test_job_lifecycle_progress_and_cancel(signed_in: EngineClient) -> None:
    state = signed_in.state
    active = state.active
    jobs = state.jobs
    seen: list[int] = []

    async def scenario() -> tuple[str, str]:
        async def quick(ctx: JobContext) -> dict[str, int]:
            await ctx.progress(50, "half")
            seen.append(50)
            return {"n": 1}

        async def slow(ctx: JobContext) -> None:
            for _ in range(200):
                ctx.raise_if_cancelled()
                await asyncio.sleep(0.01)

        state.events.bind_loop(asyncio.get_running_loop())
        done_id = jobs.submit(active, "export", {}, quick)
        slow_id = jobs.submit(active, "search", {}, slow)
        assert jobs.has_running_for(active.user_id)
        jobs.cancel(active, slow_id)
        for _ in range(300):
            if not jobs.has_running_for(active.user_id):
                break
            await asyncio.sleep(0.01)
        return done_id, slow_id

    done_id, slow_id = asyncio.run(scenario())
    T = active.tables
    with active.db.read() as conn:
        statuses = dict(conn.execute(select(T.background_jobs.c.id, T.background_jobs.c.status)).all())
    assert statuses[done_id] == "completed"
    assert statuses[slow_id] == "cancelled"
    assert seen == [50]


def test_interrupted_jobs_are_marked_paused(signed_in: EngineClient) -> None:
    from sqlalchemy import insert

    from core.ids import uuid7

    active = signed_in.state.active
    T = active.tables
    job_id = uuid7()
    with active.db.tx() as conn:
        conn.execute(
            insert(T.background_jobs).values(id=job_id, user_id=active.user_id, job_type="search", status="running")
        )
    paused = signed_in.state.jobs.interrupted_jobs(active)
    assert [j["id"] for j in paused] == [job_id]
    assert paused[0]["status"] == "paused"
