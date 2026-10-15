"""Engine configuration, read from ``OPX_*`` environment variables and validated at startup.

The data directory follows decision D-27:

* Windows: ``%APPDATA%\\PIO``
* Linux:   ``$XDG_DATA_HOME/pio`` (default ``~/.local/share/pio``)
* macOS:   ``~/Library/Application Support/PIO``
"""

from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


def default_data_dir() -> Path:
    if sys.platform.startswith("win"):
        base = os.environ.get("APPDATA") or str(Path.home() / "AppData" / "Roaming")
        return Path(base) / "PIO"
    if sys.platform == "darwin":
        return Path.home() / "Library" / "Application Support" / "PIO"
    xdg = os.environ.get("XDG_DATA_HOME")
    return Path(xdg) / "pio" if xdg else Path.home() / ".local" / "share" / "pio"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="OPX_", extra="ignore")

    data_dir: Path = Field(default_factory=default_data_dir)
    log_level: str = "INFO"
    sql_echo: bool = False
    # Argon2id cost for password hashing and key derivation (spec: 64 MiB, 3 iterations).
    # Tests lower these through the environment to stay fast; production never does.
    kdf_memory_kib: int = 65536
    kdf_iterations: int = 3
    session_ttl_hours: int = 12
    # Allow outbound requests to private/loopback addresses. Only the test suite's
    # local fixture server sets this; it must never be enabled in production.
    allow_private_network: bool = False

    @field_validator("log_level")
    @classmethod
    def _check_level(cls, v: str) -> str:
        v = v.upper()
        if v not in {"DEBUG", "INFO", "WARNING", "ERROR"}:
            raise ValueError("log_level must be DEBUG, INFO, WARNING or ERROR")
        return v

    @field_validator("kdf_memory_kib")
    @classmethod
    def _check_memory(cls, v: int) -> int:
        if v < 1024:
            raise ValueError("kdf_memory_kib must be >= 1024")
        return v

    @property
    def paths(self) -> DataPaths:
        return DataPaths(self.data_dir)


@dataclass(frozen=True)
class DataPaths:
    root: Path

    @property
    def registry_file(self) -> Path:
        return self.root / "profiles.json"

    @property
    def profiles(self) -> Path:
        return self.root / "profiles"

    def profile_dir(self, profile_id: str) -> Path:
        return self.profiles / profile_id

    def profile_db(self, profile_id: str) -> Path:
        return self.profile_dir(profile_id) / "db" / "pio.db"

    def profile_vault(self, profile_id: str) -> Path:
        return self.profile_dir(profile_id) / "vault"

    def profile_backups(self, profile_id: str) -> Path:
        return self.root / "backups" / profile_id

    def profile_exports(self, profile_id: str) -> Path:
        return self.profile_dir(profile_id) / "exports"

    @property
    def logs(self) -> Path:
        return self.root / "logs"

    @property
    def cache(self) -> Path:
        return self.root / "cache"

    @property
    def connectors(self) -> Path:
        return self.root / "connectors"

    @property
    def lock_file(self) -> Path:
        return self.root / "engine.lock"

    def ensure(self) -> None:
        for p in (self.root, self.profiles, self.root / "backups", self.logs, self.cache, self.connectors):
            p.mkdir(parents=True, exist_ok=True)


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()


def resource_dir() -> Path:
    """Directory holding bundled read-only resources (schema, wordlists, connectors).

    Works both from source and from a PyInstaller ``--onedir`` bundle.
    """
    bundle = getattr(sys, "_MEIPASS", None)
    if bundle:
        return Path(bundle)
    return Path(__file__).resolve().parent.parent
