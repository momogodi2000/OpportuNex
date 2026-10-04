"""
FastAPI application factory for the OpportuNex engine.
All routes require the session token in the Authorization header.
"""

from __future__ import annotations

from contextlib import asynccontextmanager
from typing import AsyncGenerator

import structlog
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from api.dependencies import SessionTokenMiddleware
from api.routers import (
    auth_router,
    profile_router,
    cv_import_router,
    ref_router,
    search_router,
    opportunity_router,
    source_router,
    saved_router,
    application_router,
    monitor_router,
    workspace_router,
    dashboard_router,
    ai_router,
    export_router,
    privacy_router,
    organization_router,
    sync_router,
    maintenance_router,
    system_router,
)

log = structlog.get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan: startup → yield → shutdown."""
    log.info("api_startup")
    yield
    log.info("api_shutdown")


def create_app(session_token: str) -> FastAPI:
    """Create and configure the FastAPI application."""

    app = FastAPI(
        title="OpportuNex Engine API",
        description="Local REST API for the OpportuNex desktop application.",
        version="0.1.0",
        docs_url="/api/docs",          # Only accessible on 127.0.0.1
        redoc_url="/api/redoc",
        openapi_url="/api/openapi.json",
        lifespan=lifespan,
    )

    # ── Security: block all non-localhost origins ───────────────────────────
    # The engine only accepts requests from the Flutter app (same machine).
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[],        # No cross-origin allowed
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ── Session token middleware ────────────────────────────────────────────
    app.add_middleware(SessionTokenMiddleware, session_token=session_token)

    # ── API v1 routers ──────────────────────────────────────────────────────
    prefix = "/api/v1"

    app.include_router(system_router,       prefix=prefix, tags=["System"])
    app.include_router(auth_router,         prefix=prefix, tags=["Auth"])
    app.include_router(profile_router,      prefix=prefix, tags=["Profile"])
    app.include_router(cv_import_router,    prefix=prefix, tags=["CV Import"])
    app.include_router(ref_router,          prefix=prefix, tags=["Reference Data"])
    app.include_router(search_router,       prefix=prefix, tags=["Search"])
    app.include_router(opportunity_router,  prefix=prefix, tags=["Opportunities"])
    app.include_router(source_router,       prefix=prefix, tags=["Sources"])
    app.include_router(saved_router,        prefix=prefix, tags=["Saved & Applications"])
    app.include_router(application_router,  prefix=prefix, tags=["Applications"])
    app.include_router(monitor_router,      prefix=prefix, tags=["Monitors"])
    app.include_router(workspace_router,    prefix=prefix, tags=["Workspaces"])
    app.include_router(dashboard_router,    prefix=prefix, tags=["Dashboard"])
    app.include_router(ai_router,           prefix=prefix, tags=["AI"])
    app.include_router(export_router,       prefix=prefix, tags=["Exports"])
    app.include_router(privacy_router,      prefix=prefix, tags=["Privacy"])
    app.include_router(organization_router, prefix=prefix, tags=["Organizations"])
    app.include_router(sync_router,         prefix=prefix, tags=["Sync"])
    app.include_router(maintenance_router,  prefix=prefix, tags=["Maintenance"])

    # ── Global exception handler ─────────────────────────────────────────────
    @app.exception_handler(Exception)
    async def _unhandled(request: Request, exc: Exception) -> Response:
        log.error("unhandled_exception", path=request.url.path, exc=str(exc))
        return JSONResponse(
            status_code=500,
            content={
                "type": "about:blank",
                "title": "Internal Server Error",
                "status": 500,
                "code": "INTERNAL_ERROR",
            },
        )

    return app
