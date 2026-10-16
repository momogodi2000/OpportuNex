"""FastAPI application factory."""

from __future__ import annotations

import asyncio
import contextlib
import time
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import date

import structlog
from fastapi import FastAPI, Request, WebSocket
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from api.events import EventBus
from api.routers import (
    ai,
    auth,
    cv_import,
    insights,
    maintenance,
    opportunities,
    profile,
    reference,
    search,
    sources,
    sync,
    system,
    tracking,
)
from api.security import EngineGuard
from core.config import Settings
from core.errors import AppError
from core.version import ENGINE_VERSION
from security.redaction import redact
from services.jobs import JobManager
from services.maintenance_service import MaintenanceService
from services.state import EngineState

log = structlog.get_logger(__name__)

PREFIX = "/api/v1"
AUTO_LOCK_TICK_SECONDS = 30.0
BACKUP_CHECK_SECONDS = 600.0
SCHEDULER_TICK_SECONDS = 60.0
SYNC_INTERVAL_SECONDS = 300

PROBLEM = "application/problem+json"


def _problem_response(status: int, body: dict[str, object]) -> JSONResponse:
    return JSONResponse(status_code=status, content=body, media_type=PROBLEM)


def create_app(settings: Settings, engine_token: str) -> FastAPI:
    events = EventBus()
    state = EngineState(settings, events)
    state.jobs = JobManager(state)

    @asynccontextmanager
    async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
        events.bind_loop(asyncio.get_running_loop())

        async def auto_lock_loop() -> None:
            while True:
                await asyncio.sleep(AUTO_LOCK_TICK_SECONDS)
                await asyncio.to_thread(state.auto_lock_tick)

        async def scheduled_backup_loop() -> None:
            maintenance_svc = MaintenanceService(state)
            while True:
                await asyncio.sleep(BACKUP_CHECK_SECONDS)
                active = state.active
                if active is None:
                    continue
                try:
                    await asyncio.to_thread(maintenance_svc.run_scheduled_backup_if_due, active)
                except Exception as exc:  # noqa: BLE001 - retried at next tick
                    log.warning("scheduled_backup_failed", error=type(exc).__name__)

        async def scheduler_loop() -> None:
            """Monitors, reminders, source alerts and expiry sweep for the signed-in profile."""
            from services.monitor_service import MonitorService
            from services.tracking_service import TrackingService

            last_daily = ""
            last_sync = 0.0
            while True:
                await asyncio.sleep(SCHEDULER_TICK_SECONDS)
                active = state.active
                if active is None:
                    continue
                try:
                    monitors = MonitorService(active, state)
                    for m in await asyncio.to_thread(monitors.due):
                        await monitors.run(m["id"])
                    await asyncio.to_thread(monitors.due_reminders)
                    await asyncio.to_thread(monitors.source_failure_alerts)
                    # End-to-end encrypted sync every 5 minutes while linked (silent when offline).
                    if time.monotonic() - last_sync >= SYNC_INTERVAL_SECONDS:
                        from sync.service import run_if_linked

                        last_sync = time.monotonic()
                        await run_if_linked(active, state)
                    today = date.today().isoformat()
                    if last_daily != today:
                        tracking = TrackingService(active)
                        await asyncio.to_thread(tracking.mark_expired)
                        await asyncio.to_thread(tracking.auto_archive)
                        last_daily = today
                except Exception as exc:  # noqa: BLE001 - retried at next tick
                    log.warning("scheduler_tick_failed", error=type(exc).__name__)

        tickers = [
            asyncio.create_task(auto_lock_loop()),
            asyncio.create_task(scheduled_backup_loop()),
            asyncio.create_task(scheduler_loop()),
        ]
        log.info("engine_api_started", version=ENGINE_VERSION)
        try:
            yield
        finally:
            for ticker in tickers:
                ticker.cancel()
                with contextlib.suppress(asyncio.CancelledError):
                    await ticker
            state.close_active(reason="shutdown", remember_lock=False)
            log.info("engine_api_stopped")

    app = FastAPI(
        title="Opportunex Engine API",
        version=ENGINE_VERSION,
        docs_url=f"{PREFIX}/docs",
        redoc_url=None,
        openapi_url=f"{PREFIX}/openapi.json",
        lifespan=lifespan,
    )
    app.state.engine = state
    app.add_middleware(EngineGuard, engine_token=engine_token)

    @app.exception_handler(AppError)
    async def _app_error(request: Request, exc: AppError) -> JSONResponse:
        return _problem_response(exc.status, exc.to_problem(request.url.path))

    @app.exception_handler(RequestValidationError)
    async def _validation(request: Request, exc: RequestValidationError) -> JSONResponse:
        errors = [
            {"loc": [str(p) for p in e.get("loc", ())], "type": e.get("type"), "msg": e.get("msg")}
            for e in exc.errors()
        ]
        return _problem_response(
            422,
            {
                "type": "https://opportunex.app/problems/validation_failed",
                "title": "Validation failed",
                "status": 422,
                "code": "validation_failed",
                "instance": request.url.path,
                "errors": errors,
            },
        )

    @app.exception_handler(Exception)
    async def _unhandled(request: Request, exc: Exception) -> JSONResponse:
        log.error("unhandled_error", path=request.url.path, error=type(exc).__name__, message=redact(str(exc))[:300])
        return _problem_response(
            500,
            {
                "type": "https://opportunex.app/problems/internal_error",
                "title": "Internal error",
                "status": 500,
                "code": "internal_error",
                "instance": request.url.path,
            },
        )

    app.include_router(system.router, prefix=PREFIX)
    app.include_router(auth.router, prefix=PREFIX)
    app.include_router(maintenance.router, prefix=PREFIX)
    app.include_router(reference.router, prefix=PREFIX)
    app.include_router(profile.router, prefix=PREFIX)
    app.include_router(cv_import.router, prefix=PREFIX)
    app.include_router(sources.router, prefix=PREFIX)
    app.include_router(search.router, prefix=PREFIX)
    app.include_router(opportunities.router, prefix=PREFIX)
    app.include_router(tracking.router, prefix=PREFIX)
    app.include_router(insights.router, prefix=PREFIX)
    app.include_router(ai.router, prefix=PREFIX)
    app.include_router(sync.router, prefix=PREFIX)

    @app.websocket(f"{PREFIX}/events")
    async def events_ws(websocket: WebSocket) -> None:
        await events.serve(websocket)

    return app
