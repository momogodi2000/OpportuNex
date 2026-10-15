"""Application errors rendered as RFC 9457 Problem Details with a stable ``code``.

The UI localises messages from ``code``; ``detail`` is a developer-oriented English hint
that never contains secrets or personal data.
"""

from __future__ import annotations

from typing import Any


class AppError(Exception):
    status: int = 400
    code: str = "bad_request"
    title: str = "Bad request"

    def __init__(
        self,
        detail: str | None = None,
        *,
        code: str | None = None,
        status: int | None = None,
        extra: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(detail or self.title)
        self.detail = detail or self.title
        if code:
            self.code = code
        if status:
            self.status = status
        self.extra = extra or {}

    def to_problem(self, instance: str | None = None) -> dict[str, Any]:
        body: dict[str, Any] = {
            "type": f"https://opportunex.app/problems/{self.code}",
            "title": self.title,
            "status": self.status,
            "code": self.code,
            "detail": self.detail,
        }
        if instance:
            body["instance"] = instance
        body.update(self.extra)
        return body


class ValidationFailed(AppError):
    status = 422
    code = "validation_failed"
    title = "Validation failed"


class NotFound(AppError):
    status = 404
    code = "not_found"
    title = "Resource not found"


class Conflict(AppError):
    status = 409
    code = "conflict"
    title = "Conflict"


class Unauthorized(AppError):
    status = 401
    code = "unauthorized"
    title = "Authentication required"


class Forbidden(AppError):
    status = 403
    code = "forbidden"
    title = "Forbidden"


class Locked(AppError):
    status = 423
    code = "account_locked"
    title = "Account temporarily locked"


class TooManyRequests(AppError):
    status = 429
    code = "rate_limited"
    title = "Too many requests"


class UpstreamUnavailable(AppError):
    status = 502
    code = "upstream_unavailable"
    title = "External service unavailable"


class PreconditionFailed(AppError):
    status = 412
    code = "precondition_failed"
    title = "Precondition failed"
