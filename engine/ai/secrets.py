"""API keys live in the operating-system keychain only (EF-14.02, ENF-SEC-03, ADR-011).

The database keeps a reference (``keychain_ref``); the key itself never touches SQLite, logs or exports.
Windows Credential Manager, macOS Keychain and Linux Secret Service are reached through ``keyring``.
"""

from __future__ import annotations

import threading
from typing import Protocol

SERVICE = "Opportunex"


class SecretStoreError(Exception):
    """The OS keychain is missing or refused the operation."""


class SecretStore(Protocol):
    def get(self, ref: str) -> str | None: ...
    def set(self, ref: str, secret: str) -> None: ...
    def delete(self, ref: str) -> None: ...


class KeyringStore:
    def get(self, ref: str) -> str | None:
        import keyring
        from keyring.errors import KeyringError

        try:
            return keyring.get_password(SERVICE, ref)
        except KeyringError as exc:
            raise SecretStoreError(type(exc).__name__) from exc

    def set(self, ref: str, secret: str) -> None:
        import keyring
        from keyring.errors import KeyringError

        try:
            keyring.set_password(SERVICE, ref, secret)
        except KeyringError as exc:
            raise SecretStoreError(type(exc).__name__) from exc

    def delete(self, ref: str) -> None:
        import keyring
        from keyring.errors import KeyringError, PasswordDeleteError

        try:
            keyring.delete_password(SERVICE, ref)
        except PasswordDeleteError:
            return
        except KeyringError as exc:
            raise SecretStoreError(type(exc).__name__) from exc


class MemoryStore:
    """Process-local store used by the test-suite so tests never write to the real keychain."""

    def __init__(self) -> None:
        self._data: dict[str, str] = {}
        self._lock = threading.Lock()

    def get(self, ref: str) -> str | None:
        with self._lock:
            return self._data.get(ref)

    def set(self, ref: str, secret: str) -> None:
        with self._lock:
            self._data[ref] = secret

    def delete(self, ref: str) -> None:
        with self._lock:
            self._data.pop(ref, None)


def make_store(kind: str) -> SecretStore:
    return MemoryStore() if kind == "memory" else KeyringStore()


def provider_ref(user_id: str, provider_id: str) -> str:
    return f"ai-provider:{user_id}:{provider_id}"
