"""
FastAPI dependencies: session-token middleware, user resolution, pagination.
"""

from __future__ import annotations

import hmac
import time
from typing import Annotated, Optional
from uuid import UUID

import structlog
from fastapi import Depends, Header, HTTPException, Request, Response, status
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint

from persistence.repositories.user_repo import UserRepository
from domain.entities.user import User

log = structlog.get_logger(__name__)

# ── Routes that do NOT require a logged-in user ──────────────────────────────
_PUBLIC_PATHS = frozenset(
    [
        "/api/v1/health",
        "/api/v1/version",
        "/api/v1/auth/register",
        "/api/v1/auth/login",
        "/api/v1/auth/recover",
        "/api/v1/auth/local-profiles",
        "/api/docs",
        "/api/redoc",
        "/api/openapi.json",
    ]
)


class SessionTokenMiddleware(BaseHTTPMiddleware):
    """
    Validates the engine session token on every request.
    Token is set by the Flutter supervisor at launch and passed via HTTP header.
    Also rejects requests from browser origins to prevent CSRF via LAN.
    """

    def __init__(self, app, *, session_token: str) -> None:
        super().__init__(app)
        self._token = session_token.encode()

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        # Block requests that come with an Origin header from external sites
        origin = request.headers.get("origin", "")
        if origin and not origin.startswith("http://127.0.0.1"):
            return JSONResponse(
                status_code=status.HTTP_403_FORBIDDEN,
                content={"code": "ORIGIN_REJECTED", "title": "Forbidden"},
            )

        # Skip token check for WebSocket upgrade (handled in route)
        if request.url.path == "/api/v1/events":
            return await call_next(request)

        auth = request.headers.get("x-engine-token", "")
        if not hmac.compare_digest(auth.encode(), self._token):
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={"code": "INVALID_ENGINE_TOKEN", "title": "Unauthorized"},
            )

        return await call_next(request)


# ── Per-request user resolution ──────────────────────────────────────────────

async def get_current_user(
    x_user_id: Annotated[Optional[str], Header()] = None,
) -> User:
    """
    Resolve the logged-in user from the X-User-Id header (set by the Flutter
    app after authentication). Raises 401 if the user cannot be resolved.
    """
    if not x_user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "AUTH_REQUIRED", "title": "Authentication required"},
        )
    try:
        uid = UUID(x_user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "INVALID_USER_ID", "title": "Invalid user identifier"},
        )

    repo = UserRepository()
    user = await repo.get_by_id(uid)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "USER_NOT_FOUND", "title": "User not found"},
        )
    if user.is_locked:
        raise HTTPException(
            status_code=status.HTTP_423_LOCKED,
            detail={"code": "SESSION_LOCKED", "title": "Session is locked"},
        )
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]


# ── Cursor-based pagination ───────────────────────────────────────────────────

class Pagination:
    """Cursor-based pagination parameters."""

    MAX_LIMIT = 200
    DEFAULT_LIMIT = 50

    def __init__(
        self,
        cursor: Optional[str] = None,
        limit: int = DEFAULT_LIMIT,
    ) -> None:
        self.cursor = cursor
        self.limit = min(limit, self.MAX_LIMIT)


PaginationDep = Annotated[Pagination, Depends(Pagination)]
