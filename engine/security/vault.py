"""Encrypted document vault (EF-12.07, EF-03.05).

Files are stored as AES-256-GCM blobs under ``<profile>/vault/<2-char shard>/<uuid>.bin``.
Callers only ever handle opaque relative paths returned by :meth:`Vault.put`; any path
that would resolve outside the vault root is rejected.
"""

from __future__ import annotations

import os
from pathlib import Path

from core.errors import NotFound, ValidationFailed
from core.ids import uuid7
from security.crypto import decrypt_blob, encrypt_blob

MAX_FILE_BYTES = 25 * 1024 * 1024


class Vault:
    def __init__(self, root: Path, key: bytes) -> None:
        self.root = root.resolve()
        self._key = key

    def _resolve(self, rel: str) -> Path:
        candidate = (self.root / rel).resolve()
        if not candidate.is_relative_to(self.root) or candidate == self.root:
            raise ValidationFailed("invalid vault path", code="vault_path_invalid")
        return candidate

    def put(self, data: bytes) -> str:
        if not data:
            raise ValidationFailed("empty file", code="file_empty")
        if len(data) > MAX_FILE_BYTES:
            raise ValidationFailed("file too large", code="file_too_large")
        name = uuid7()
        rel = f"{name[-2:]}/{name}.bin"
        target = self._resolve(rel)
        target.parent.mkdir(parents=True, exist_ok=True)
        tmp = target.with_suffix(".tmp")
        tmp.write_bytes(encrypt_blob(data, self._key, rel.encode()))
        os.replace(tmp, target)
        return rel

    def get(self, rel: str) -> bytes:
        target = self._resolve(rel)
        if not target.is_file():
            raise NotFound("vault file missing", code="vault_file_missing")
        return decrypt_blob(target.read_bytes(), self._key, rel.encode())

    def delete(self, rel: str) -> None:
        target = self._resolve(rel)
        if target.is_file():
            size = target.stat().st_size
            # Best-effort overwrite before unlink; SSD wear-levelling may keep copies,
            # which is acceptable because the content was encrypted at rest anyway.
            with open(target, "r+b") as fh:
                fh.write(os.urandom(size))
                fh.flush()
                os.fsync(fh.fileno())
            target.unlink()

    def size_bytes(self) -> int:
        if not self.root.exists():
            return 0
        return sum(p.stat().st_size for p in self.root.rglob("*.bin"))
