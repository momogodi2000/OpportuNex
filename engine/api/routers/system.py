"""Health, version and graceful shutdown."""

from __future__ import annotations

import os
import signal
import sys
import threading

from fastapi import APIRouter, Request

from api.deps import StateDep
from core.version import (
    AUTHOR,
    ENGINE_VERSION,
    LICENSE_SPDX,
    PRODUCT_NAME,
    PROJECT_URL,
    PUBLISHER,
)
from persistence.database import head_revision

router = APIRouter(tags=["System"])


@router.get("/health")
def health() -> dict[str, str]:
    """Liveness probe used by the UI supervisor. Public, reveals nothing sensitive."""
    return {"status": "ok"}


@router.get("/version")
def version(state: StateDep) -> dict[str, object]:
    return {
        "product": PRODUCT_NAME,
        "engine_version": ENGINE_VERSION,
        "schema_revision": head_revision(),
        "publisher": PUBLISHER,
        "author": AUTHOR,
        "license": LICENSE_SPDX,
        "project_url": PROJECT_URL,
        "python": sys.version.split()[0],
        "data_dir": str(state.paths.root),
        "signed_in": state.active is not None,
    }


@router.post("/system/shutdown", status_code=202)
def shutdown(request: Request, state: StateDep) -> dict[str, str]:
    """Close the profile cleanly (checkpoint WAL, persist jobs) then stop the process."""
    state.close_active(reason="shutdown", remember_lock=False)
    graceful = getattr(request.app.state, "request_shutdown", None)

    def _stop() -> None:
        if graceful is not None:
            graceful()
        else:
            os.kill(os.getpid(), signal.SIGTERM)

    threading.Timer(0.2, _stop).start()
    return {"status": "stopping"}
