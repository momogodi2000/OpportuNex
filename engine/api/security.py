"""Transport guard for the local API (arch §9.2, threat model).

Pure ASGI middleware so it covers HTTP *and* WebSocket scopes:

* every request must carry the per-launch engine token (``X-Engine-Token``) except the
  health probe;
* browsers are rejected (any ``Origin`` header) to defeat CSRF from web pages;
* the ``Host`` header must be the loopback address (DNS-rebinding defence).
"""

from __future__ import annotations

import hmac
import json
from typing import Any

from starlette.types import ASGIApp, Receive, Scope, Send

PUBLIC_PATHS = frozenset({"/api/v1/health"})
ALLOWED_HOSTS = ("127.0.0.1", "localhost", "[::1]")


def _problem(status: int, code: str, title: str) -> bytes:
    return json.dumps({"type": f"https://opportunex.app/problems/{code}", "title": title,
                       "status": status, "code": code}).encode()


class EngineGuard:
    def __init__(self, app: ASGIApp, *, engine_token: str) -> None:
        self.app = app
        self._token = engine_token.encode()

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] not in ("http", "websocket"):
            await self.app(scope, receive, send)
            return
        headers = {k.decode("latin-1").lower(): v.decode("latin-1") for k, v in scope["headers"]}
        raw_host = headers.get("host", "")
        host = raw_host.split("]")[0] + "]" if raw_host.startswith("[") else raw_host.split(":")[0]
        if host not in ALLOWED_HOSTS:
            await self._reject(scope, send, 421, "host_rejected", "Misdirected request")
            return
        if "origin" in headers:
            await self._reject(scope, send, 403, "origin_rejected", "Browser requests are not allowed")
            return
        if scope["path"] not in PUBLIC_PATHS:
            supplied = headers.get("x-engine-token", "").encode()
            if not hmac.compare_digest(supplied, self._token):
                await self._reject(scope, send, 401, "invalid_engine_token", "Invalid engine token")
                return
        await self.app(scope, receive, send)

    async def _reject(self, scope: Scope, send: Send, status: int, code: str, title: str) -> None:
        if scope["type"] == "websocket":
            # Close before accept → the client sees an HTTP 403 on the upgrade.
            await send({"type": "websocket.close", "code": 1008})
            return
        body = _problem(status, code, title)
        start: dict[str, Any] = {
            "type": "http.response.start",
            "status": status,
            "headers": [(b"content-type", b"application/problem+json"),
                        (b"content-length", str(len(body)).encode())],
        }
        await send(start)
        await send({"type": "http.response.body", "body": body})
