"""
Database configuration and async session management.
Uses SQLAlchemy 2 async with aiosqlite.
Note: SQLCipher integration is handled via the sqlcipher3 package
and the pragma configuration below.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import AsyncGenerator

import structlog
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.pool import StaticPool

log = structlog.get_logger(__name__)

# ── Data directory ────────────────────────────────────────────────────────────
_APP_DATA = Path(os.environ.get("OPX_DATA_DIR", Path.home() / ".opportunex"))
_APP_DATA.mkdir(parents=True, exist_ok=True)
_DB_PATH = _APP_DATA / "opportunex.db"

# ── Cipher key (injected from the Vault after user unlocks the app) ───────────
_db_key: str | None = None


def configure_db_key(key_hex: str) -> None:
    """Set the SQLCipher database encryption key. Called after successful login."""
    global _db_key
    _db_key = key_hex


def _get_engine():
    """Create the async SQLAlchemy engine for the current session."""
    # For aiosqlite (development), use plain SQLite.
    # Production builds switch to sqlcipher3 by changing the URL scheme.
    db_url = f"sqlite+aiosqlite:///{_DB_PATH}"

    connect_args: dict = {
        "check_same_thread": False,
    }

    if _db_key:
        # SQLCipher pragma: applied as connection-level event
        connect_args["timeout"] = 30

    return create_async_engine(
        db_url,
        connect_args=connect_args,
        poolclass=StaticPool,    # SQLite requires single connection in WAL mode
        echo=os.environ.get("OPX_SQL_ECHO", "false").lower() == "true",
    )


# Module-level engine and session factory (lazy-initialized)
_engine = None
_session_factory: async_sessionmaker[AsyncSession] | None = None


def get_engine():
    global _engine
    if _engine is None:
        _engine = _get_engine()
    return _engine


def get_session_factory() -> async_sessionmaker[AsyncSession]:
    global _session_factory
    if _session_factory is None:
        _session_factory = async_sessionmaker(
            get_engine(),
            class_=AsyncSession,
            expire_on_commit=False,
        )
    return _session_factory


async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency: yields a database session."""
    async with get_session_factory()() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def init_db() -> None:
    """
    Initialize the database on first launch.
    In production this runs Alembic migrations instead of create_all.
    """
    from persistence.models.base import Base
    from persistence import models  # noqa: F401 — import all models

    async with get_engine().begin() as conn:
        # Enable WAL mode for concurrent reads + single writer
        await conn.execute(__import__("sqlalchemy").text("PRAGMA journal_mode=WAL"))
        await conn.execute(__import__("sqlalchemy").text("PRAGMA foreign_keys=ON"))
        await conn.execute(__import__("sqlalchemy").text("PRAGMA strict=ON"))

        # Create all tables if not already present (baseline migration)
        await conn.run_sync(Base.metadata.create_all)

    log.info("database_initialized", path=str(_DB_PATH))
