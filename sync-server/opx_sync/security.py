"""Passwords (Argon2id), opaque tokens, TOTP (RFC 6238) and login back-off."""

from __future__ import annotations

import base64
import hashlib
import hmac
import secrets
import struct
import time
from datetime import UTC, datetime, timedelta
from urllib.parse import quote

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError


def now() -> datetime:
    return datetime.now(UTC)


def iso(d: datetime) -> str:
    return d.strftime("%Y-%m-%dT%H:%M:%SZ")


def parse(s: str) -> datetime:
    return datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=UTC)


class Passwords:
    def __init__(self, memory_kib: int, iterations: int) -> None:
        self._ph = PasswordHasher(time_cost=iterations, memory_cost=memory_kib, parallelism=1)

    def hash(self, password: str) -> str:
        return self._ph.hash(password)

    def verify(self, stored: str, password: str) -> bool:
        try:
            return self._ph.verify(stored, password)
        except (VerificationError, InvalidHashError):
            return False


def new_token() -> str:
    return secrets.token_urlsafe(32)


def token_hash(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


# ------------------------------------------------------------------------ TOTP
def totp_secret() -> str:
    return base64.b32encode(secrets.token_bytes(20)).decode().rstrip("=")


def _hotp(secret: str, counter: int) -> str:
    key = base64.b32decode(secret + "=" * (-len(secret) % 8), casefold=True)
    digest = hmac.new(key, struct.pack(">Q", counter), hashlib.sha1).digest()
    offset = digest[-1] & 0x0F
    code = (struct.unpack(">I", digest[offset : offset + 4])[0] & 0x7FFFFFFF) % 1_000_000
    return f"{code:06d}"


def totp_now(secret: str, at: float | None = None) -> str:
    return _hotp(secret, int((at if at is not None else time.time()) // 30))


def totp_verify(secret: str, code: str, at: float | None = None) -> bool:
    """Accepts the current 30-second step and one step either side (clock drift)."""
    code = code.strip().replace(" ", "")
    if len(code) != 6 or not code.isdigit():
        return False
    step = int((at if at is not None else time.time()) // 30)
    return any(hmac.compare_digest(_hotp(secret, step + d), code) for d in (-1, 0, 1))


def totp_uri(secret: str, email: str) -> str:
    return f"otpauth://totp/Opportunex:{quote(email)}?secret={secret}&issuer=Opportunex&digits=6&period=30"


def lockout_until(failures: int) -> datetime | None:
    """From the 5th consecutive failure: 1 minute, doubling, at most 60 (same rule as the desktop)."""
    if failures < 5:
        return None
    return now() + timedelta(minutes=min(60, 2 ** (failures - 5)))
