"""
OpportuNex Engine — Main Entry Point
Launched by the Flutter desktop app; receives session token via stdin.
Picks a random free port on 127.0.0.1 and announces it on stdout.
"""

from __future__ import annotations

import asyncio
import os
import secrets
import socket
import sys

import structlog
import uvicorn

from api.app import create_app
from persistence.database import init_db
from security.vault import Vault

log = structlog.get_logger(__name__)


def _find_free_port() -> int:
    """Pick a random free TCP port on localhost."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


async def _startup(session_token: str) -> None:
    """Initialise database and vault before serving."""
    await init_db()
    log.info("engine_ready", version="0.1.0")


def main() -> None:
    # ── Read session token from stdin (sent by Flutter supervisor) ──────────
    raw = sys.stdin.readline().strip()
    if not raw:
        # Fallback: accept env var for development convenience
        raw = os.environ.get("OPX_SESSION_TOKEN", "")
    if len(raw) < 32:
        print("FATAL: Missing or too-short session token", file=sys.stderr)
        sys.exit(1)

    session_token: str = raw
    port: int = _find_free_port()

    # Announce port to Flutter via stdout (first line)
    print(f"PORT:{port}", flush=True)
    log.info("engine_starting", port=port)

    # ── Create FastAPI app ──────────────────────────────────────────────────
    app = create_app(session_token=session_token)

    # Run startup tasks before serving
    asyncio.run(_startup(session_token))

    config = uvicorn.Config(
        app,
        host="127.0.0.1",
        port=port,
        log_config=None,  # structlog handles logging
        access_log=False,
    )
    server = uvicorn.Server(config)

    try:
        server.run()
    except KeyboardInterrupt:
        log.info("engine_shutdown_requested")
    finally:
        log.info("engine_stopped")


if __name__ == "__main__":
    main()
