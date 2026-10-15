"""Encrypted per-profile database (ADR-003, arch §8.5 and §9.1).

* SQLCipher 4 with a raw 256-bit key, WAL, foreign keys, busy timeout.
* A brand-new database is created from ``pio_schema.sql`` (Alembic revision
  ``0001_baseline``), then Alembic applies later revisions. A ``pre_migration`` hook runs
  before pending revisions are applied to an existing database.
* The engine refuses to open a database whose revision it does not know (newer code).
"""

from __future__ import annotations

import threading
from collections.abc import Callable, Iterator
from contextlib import contextmanager
from pathlib import Path

import sqlcipher3
import structlog
from alembic import command
from alembic.config import Config
from alembic.runtime.migration import MigrationContext
from alembic.script import ScriptDirectory
from sqlalchemy import URL, Connection, Engine, MetaData, Table, create_engine, event, text
from sqlalchemy.pool import QueuePool

from core.config import resource_dir
from core.errors import AppError

log = structlog.get_logger(__name__)

BASELINE_REVISION = "0001_baseline"


class WrongKeyError(Exception):
    pass


class SchemaTooNewError(AppError):
    status = 409
    code = "schema_too_new"
    title = "Database was created by a newer version of Opportunex"


class IntegrityCheckFailed(AppError):
    status = 500
    code = "db_integrity_failed"
    title = "Database integrity check failed"


def schema_sql_path() -> Path:
    return resource_dir() / "persistence" / "schema" / "pio_schema.sql"


def migrations_dir() -> Path:
    return resource_dir() / "persistence" / "migrations"


def _alembic_config(conn: Connection) -> Config:
    cfg = Config()
    cfg.set_main_option("script_location", str(migrations_dir()))
    cfg.attributes["connection"] = conn
    return cfg


def make_engine(path: Path, key: bytes, *, echo: bool = False) -> Engine:
    url = URL.create("sqlite+pysqlcipher", password=f"x'{key.hex()}'", database=str(path))
    engine = create_engine(
        url,
        echo=echo,
        hide_parameters=True,
        poolclass=QueuePool,
        pool_size=4,
        max_overflow=4,
        pool_pre_ping=False,
        connect_args={"check_same_thread": False, "timeout": 5.0},
    )

    @event.listens_for(engine, "connect")
    def _pragmas(dbapi_conn: sqlcipher3.Connection, _record: object) -> None:
        cur = dbapi_conn.cursor()
        cur.execute("PRAGMA cipher_log_level = NONE")
        try:
            cur.execute("SELECT count(*) FROM sqlite_master")
        except sqlcipher3.DatabaseError as exc:
            raise WrongKeyError("cannot decrypt database") from exc
        cur.execute("PRAGMA foreign_keys = ON")
        cur.execute("PRAGMA busy_timeout = 30000")
        cur.execute("PRAGMA journal_mode = WAL")
        cur.execute("PRAGMA synchronous = NORMAL")
        cur.close()

    # The schema manages its own transactions; let SQLAlchemy emit BEGIN explicitly so
    # pysqlite's legacy implicit-transaction handling does not interfere with DDL.
    @event.listens_for(engine, "connect")
    def _autocommit_mode(dbapi_conn: sqlcipher3.Connection, _record: object) -> None:
        dbapi_conn.isolation_level = None

    @event.listens_for(engine, "begin")
    def _begin(conn: Connection) -> None:
        # Write transactions take the write lock up front: a deferred transaction that
        # upgrades from read to write fails with "database is locked" instead of waiting.
        immediate = conn.get_execution_options().get("immediate", False)
        conn.exec_driver_sql("BEGIN IMMEDIATE" if immediate else "BEGIN")

    return engine


def create_schema(engine: Engine) -> None:
    sql = schema_sql_path().read_text(encoding="utf-8")
    raw = engine.raw_connection()
    try:
        raw.driver_connection.executescript(sql)  # type: ignore[union-attr]
    finally:
        raw.close()


def vacuum_into(engine: Engine, target: Path) -> None:
    """Write a consistent, still-encrypted snapshot of the database to ``target``."""
    raw = engine.raw_connection()
    try:
        raw.driver_connection.execute("VACUUM INTO ?", (str(target),))  # type: ignore[union-attr]
    finally:
        raw.close()


def _is_empty(engine: Engine) -> bool:
    with engine.connect() as conn:
        n = conn.exec_driver_sql("SELECT count(*) FROM sqlite_master WHERE type='table'").scalar_one()
    return int(n) == 0


def current_revision(engine: Engine) -> str | None:
    with engine.connect() as conn:
        return MigrationContext.configure(conn).get_current_revision()


def head_revision() -> str:
    cfg = Config()
    cfg.set_main_option("script_location", str(migrations_dir()))
    head = ScriptDirectory.from_config(cfg).get_current_head()
    if head is None:
        raise RuntimeError("no alembic head revision")
    return head


def migrate(engine: Engine, before_migrate: Callable[[str, str], None] | None = None) -> str:
    """Bring the database to the head revision; returns the final revision."""
    if _is_empty(engine):
        create_schema(engine)
        log.info("db_schema_created", revision=BASELINE_REVISION)
    cfg = Config()
    cfg.set_main_option("script_location", str(migrations_dir()))
    script = ScriptDirectory.from_config(cfg)
    known = {rev.revision for rev in script.walk_revisions()}
    current = current_revision(engine)
    if current is None or current not in known:
        raise SchemaTooNewError(f"unknown schema revision {current!r}")
    head = script.get_current_head()
    if current != head:
        if before_migrate is not None:
            before_migrate(current, head or "")
        with engine.begin() as conn:
            command.upgrade(_alembic_config(conn), "head")
        log.info("db_migrated", from_revision=current, to_revision=head)
    return head or current


def integrity_check(engine: Engine) -> None:
    with engine.connect() as conn:
        result = conn.exec_driver_sql("PRAGMA quick_check").scalar_one()
        if result != "ok":
            raise IntegrityCheckFailed(f"quick_check: {result}")
        fk = conn.exec_driver_sql("PRAGMA foreign_key_check").fetchall()
        if fk:
            raise IntegrityCheckFailed(f"foreign_key_check reported {len(fk)} rows")


class Tables:
    """Schema tables reflected from the live database (single source of truth)."""

    def __init__(self, metadata: MetaData) -> None:
        self._metadata = metadata

    def __getattr__(self, name: str) -> Table:
        try:
            return self._metadata.tables[name]
        except KeyError as exc:
            raise AttributeError(name) from exc

    @property
    def metadata(self) -> MetaData:
        return self._metadata


_TABLES: Tables | None = None
_TABLES_REVISION: str | None = None


def reflect_tables(engine: Engine, revision: str) -> Tables:
    global _TABLES, _TABLES_REVISION
    if _TABLES is None or revision != _TABLES_REVISION:
        md = MetaData()
        md.reflect(bind=engine, views=True)
        _TABLES = Tables(md)
        _TABLES_REVISION = revision
    return _TABLES


def tables() -> Tables:
    if _TABLES is None:
        raise RuntimeError("tables not reflected yet: open a profile database first")
    return _TABLES


class ProfileDatabase:
    """Open, migrated and integrity-checked encrypted database of one local profile."""

    def __init__(
        self, path: Path, key: bytes, *, echo: bool = False, before_migrate: Callable[[str, str], None] | None = None
    ) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        self.path = path
        self._write_lock = threading.RLock()
        self.engine = make_engine(path, key, echo=echo)
        try:
            if not _is_empty(self.engine):
                integrity_check(self.engine)
            self.revision = migrate(self.engine, before_migrate)
            self.tables = reflect_tables(self.engine, self.revision)
        except BaseException:
            self.engine.dispose()
            raise

    @contextmanager
    def tx(self) -> Iterator[Connection]:
        # One writer at a time inside the engine process: concurrent jobs queue here instead
        # of racing for SQLite's write lock (which surfaces as "database is locked").
        with self._write_lock, self.engine.connect().execution_options(immediate=True) as conn, conn.begin():
            yield conn

    @contextmanager
    def read(self) -> Iterator[Connection]:
        with self.engine.connect() as conn:
            yield conn

    def checkpoint(self) -> None:
        with self.engine.connect() as conn:
            conn.exec_driver_sql("PRAGMA wal_checkpoint(TRUNCATE)")

    def close(self) -> None:
        try:
            self.checkpoint()
        except Exception:  # noqa: BLE001 - closing must never raise
            log.warning("db_checkpoint_failed")
        self.engine.dispose()


def schema_user_version(conn: Connection) -> int:
    return int(conn.execute(text("PRAGMA user_version")).scalar_one())
