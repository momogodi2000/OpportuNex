"""Process-wide engine state: the single unlocked profile and its session.

Only one local profile is unlocked at a time (D-26: one engine per OS user). Locking or
logging out closes the database and drops the data key from memory (arch §9.1 point 5).
"""

from __future__ import annotations

import hashlib
import threading
import time
from dataclasses import dataclass, field
from typing import TYPE_CHECKING

from api.events import EventBus
from core.config import DataPaths, Settings
from core.errors import Unauthorized
from persistence.database import ProfileDatabase, Tables
from persistence.registry import ProfileRegistry
from security.crypto import KdfParams, constant_time_equals
from security.vault import Vault

if TYPE_CHECKING:
    from services.jobs import JobManager


def token_hash(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


@dataclass
class ActiveProfile:
    user_id: str
    db: ProfileDatabase
    vault: Vault
    data_key: bytearray
    session_hash: str
    session_id: str
    session_expires: float
    auto_lock_minutes: int
    last_activity: float = field(default_factory=time.monotonic)

    @property
    def tables(self) -> Tables:
        return self.db.tables

    @property
    def key_bytes(self) -> bytes:
        return bytes(self.data_key)

    def wipe(self) -> None:
        for i in range(len(self.data_key)):
            self.data_key[i] = 0


@dataclass
class LockedSession:
    """Remembers who was locked so the UI can offer an unlock screen for that profile."""

    user_id: str
    reason: str


class EngineState:
    def __init__(self, settings: Settings, events: EventBus) -> None:
        self.settings = settings
        self.paths: DataPaths = settings.paths
        self.paths.ensure()
        self.registry = ProfileRegistry(self.paths.registry_file)
        self.events = events
        self.kdf = KdfParams(memory_kib=settings.kdf_memory_kib, iterations=settings.kdf_iterations)
        self.active: ActiveProfile | None = None
        self.locked: LockedSession | None = None
        self.lock = threading.RLock()
        self.jobs: JobManager | None = None

    # ------------------------------------------------------------- sessions
    def require(self, bearer: str | None) -> ActiveProfile:
        with self.lock:
            active = self.active
            if active is None:
                if self.locked is not None:
                    raise Unauthorized(
                        "session locked",
                        code="session_locked",
                        extra={"profile_id": self.locked.user_id, "reason": self.locked.reason},
                    )
                raise Unauthorized("not signed in", code="not_authenticated")
            if not bearer or not constant_time_equals(token_hash(bearer), active.session_hash):
                raise Unauthorized("invalid session token", code="invalid_session")
            if time.time() > active.session_expires:
                self.close_active(reason="expired")
                raise Unauthorized(
                    "session expired", code="session_locked", extra={"profile_id": active.user_id, "reason": "expired"}
                )
            active.last_activity = time.monotonic()
            return active

    def set_active(self, active: ActiveProfile) -> None:
        with self.lock:
            if self.active is not None and self.active.user_id != active.user_id:
                self.close_active(reason="switched")
            self.active = active
            self.locked = None

    def close_active(self, *, reason: str, remember_lock: bool = True) -> str | None:
        """Close the database and wipe the key. Returns the user id that was active."""
        with self.lock:
            active = self.active
            if active is None:
                return None
            if self.jobs is not None:
                self.jobs.cancel_all_for(active.user_id)
            active.db.close()
            active.wipe()
            self.active = None
            self.locked = LockedSession(active.user_id, reason) if remember_lock else None
            return active.user_id

    def auto_lock_tick(self) -> str | None:
        """Called periodically; locks the profile after its inactivity delay."""
        with self.lock:
            active = self.active
            if active is None:
                return None
            idle = time.monotonic() - active.last_activity
            if idle < active.auto_lock_minutes * 60:
                return None
            if self.jobs is not None and self.jobs.has_running_for(active.user_id):
                return None  # do not interrupt a running search; lock when it finishes
            user_id = self.close_active(reason="inactivity")
        if user_id:
            self.events.publish("auth.locked", {"profile_id": user_id, "reason": "inactivity"})
        return user_id
