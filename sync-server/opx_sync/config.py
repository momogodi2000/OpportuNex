"""Server settings, all from environment variables prefixed ``OPX_SYNC_`` (documented in README.md)."""

from __future__ import annotations

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="OPX_SYNC_", extra="ignore")

    database_url: str = "sqlite:///./data/sync.db"
    # Public address of this instance, used in e-mailed links (e.g. https://sync.example.org).
    public_url: str = "http://127.0.0.1:8080"
    allow_registration: bool = True
    quota_mb: int = 200
    session_days: int = 30
    max_batch: int = 500
    max_record_kb: int = 512
    smtp_host: str | None = None
    smtp_port: int = 587
    smtp_user: str | None = None
    smtp_password: str | None = None
    smtp_from: str = "Opportunex <no-reply@example.invalid>"
    smtp_starttls: bool = True
    # Argon2id cost for account passwords (tests lower it).
    argon2_memory_kib: int = 65536
    argon2_iterations: int = 3
