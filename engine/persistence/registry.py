"""Local profile registry (``<data_dir>/profiles.json``).

The registry is the only plaintext store. It lets the engine find a profile and unwrap its
data key *before* the encrypted database can be opened. It never holds the e-mail address
in clear (only a SHA-256 of the normalised address), the password, the recovery phrase or
the data key: only Argon2id hashes, KDF salts and AES-GCM wrapped keys.
"""

from __future__ import annotations

import hashlib
import json
import os
import threading
from dataclasses import asdict, dataclass, field
from pathlib import Path

REGISTRY_VERSION = 1


def email_digest(email: str) -> str:
    return hashlib.sha256(email.strip().lower().encode("utf-8")).hexdigest()


@dataclass
class ProfileRecord:
    id: str
    display_name: str
    email_sha256: str
    locale: str
    created_at: str
    auth_hash: str
    pw_salt: str
    pw_wrapped_key: str
    recovery_hash: str
    rec_salt: str
    rec_wrapped_key: str
    kdf_memory_kib: int
    kdf_iterations: int
    failed_count: int = 0
    locked_until: str | None = None
    last_login_at: str | None = None
    pending_attempts: list[dict[str, object]] = field(default_factory=list)

    def public(self) -> dict[str, object]:
        return {
            "id": self.id,
            "display_name": self.display_name,
            "locale": self.locale,
            "created_at": self.created_at,
            "last_login_at": self.last_login_at,
        }


class ProfileRegistry:
    def __init__(self, path: Path) -> None:
        self.path = path
        self._lock = threading.RLock()

    def _read(self) -> list[ProfileRecord]:
        if not self.path.exists():
            return []
        data = json.loads(self.path.read_text(encoding="utf-8"))
        if data.get("version") != REGISTRY_VERSION:
            raise RuntimeError("unsupported profile registry version")
        return [ProfileRecord(**p) for p in data.get("profiles", [])]

    def _write(self, profiles: list[ProfileRecord]) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self.path.with_suffix(".tmp")
        payload = {"version": REGISTRY_VERSION, "profiles": [asdict(p) for p in profiles]}
        tmp.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        if os.name == "posix":
            os.chmod(tmp, 0o600)
        os.replace(tmp, self.path)

    def all(self) -> list[ProfileRecord]:
        with self._lock:
            return self._read()

    def get(self, profile_id: str) -> ProfileRecord | None:
        return next((p for p in self.all() if p.id == profile_id), None)

    def find_by_email(self, email: str) -> ProfileRecord | None:
        digest = email_digest(email)
        return next((p for p in self.all() if p.email_sha256 == digest), None)

    def add(self, record: ProfileRecord) -> None:
        with self._lock:
            profiles = self._read()
            if any(p.email_sha256 == record.email_sha256 for p in profiles):
                raise ValueError("email already registered")
            profiles.append(record)
            self._write(profiles)

    def update(self, record: ProfileRecord) -> None:
        with self._lock:
            profiles = [record if p.id == record.id else p for p in self._read()]
            self._write(profiles)

    def remove(self, profile_id: str) -> None:
        with self._lock:
            self._write([p for p in self._read() if p.id != profile_id])
