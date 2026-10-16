"""HTTP client for the sync server. Server problems become engine errors with a ``sync_`` code."""

from __future__ import annotations

from typing import Any
from urllib.parse import urlsplit

import httpx

from ai.providers import is_loopback
from core.errors import AppError


class SyncError(AppError):
    status = 502
    code = "sync_error"
    title = "Sync server error"


def check_server_url(url: str) -> str:
    """HTTPS is required; plain HTTP only for a server on this computer (tests, local trial)."""
    url = url.strip().rstrip("/")
    parts = urlsplit(url)
    if parts.scheme not in ("http", "https") or not parts.hostname or parts.username or parts.password:
        raise SyncError("invalid server address", code="sync_url_invalid", status=422)
    if parts.scheme == "http" and not is_loopback(url):
        raise SyncError("the server must use HTTPS", code="sync_url_insecure", status=422)
    return url


class SyncClient:
    def __init__(
        self, base_url: str, token: str | None = None, proxy: str | None = None, timeout: float = 30.0
    ) -> None:
        self.base = check_server_url(base_url)
        self.token = token
        self._client = httpx.AsyncClient(
            base_url=self.base,
            timeout=timeout,
            proxy=None if is_loopback(self.base) else proxy,
            follow_redirects=False,
            trust_env=False,
        )

    async def __aenter__(self) -> SyncClient:
        return self

    async def __aexit__(self, *exc: object) -> None:
        await self._client.aclose()

    async def call(self, method: str, path: str, body: Any = None, params: dict[str, Any] | None = None) -> Any:
        headers = {"Authorization": f"Bearer {self.token}"} if self.token else {}
        try:
            r = await self._client.request(method, f"/v1{path}", json=body, params=params, headers=headers)
        except httpx.HTTPError as exc:
            raise SyncError("sync server unreachable", code="sync_unreachable", status=503) from exc
        if r.status_code == 204:
            return None
        try:
            data = r.json()
        except ValueError as exc:
            raise SyncError("unexpected answer from the sync server", code="sync_bad_response") from exc
        if r.status_code >= 400:
            code = data.get("code") if isinstance(data, dict) else None
            extra = (
                {k: v for k, v in data.items() if k not in ("type", "title", "status", "code", "detail")}
                if isinstance(data, dict)
                else {}
            )
            status = r.status_code if r.status_code in (400, 401, 403, 404, 409, 422, 423, 429) else 502
            raise SyncError(
                str(data.get("detail") if isinstance(data, dict) else r.text)[:300],
                code=f"sync_{code or r.status_code}",
                status=status,
                extra=extra,
            )
        return data
