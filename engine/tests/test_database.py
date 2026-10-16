from __future__ import annotations

import hashlib
import os
import re
from pathlib import Path

import pytest
from alembic import command
from sqlalchemy import insert, select, text

from core.config import resource_dir
from persistence.database import (
    ProfileDatabase,
    SchemaTooNewError,
    WrongKeyError,
    _alembic_config,
    head_revision,
)

DOC_SCHEMA = resource_dir().parent / "documentation" / "cahier_de_charge" / "pio_schema.sql"
ENGINE_SCHEMA = resource_dir() / "persistence" / "schema" / "pio_schema.sql"


def _db(tmp_path: Path, key: bytes | None = None) -> tuple[ProfileDatabase, bytes]:
    key = key or os.urandom(32)
    return ProfileDatabase(tmp_path / "db" / "pio.db", key), key


def test_bundled_schema_is_identical_to_reference_document() -> None:
    assert hashlib.sha256(ENGINE_SCHEMA.read_bytes()).hexdigest() == hashlib.sha256(DOC_SCHEMA.read_bytes()).hexdigest()


def test_fresh_database_has_every_schema_object(tmp_path: Path) -> None:
    db, _ = _db(tmp_path)
    try:
        sql = ENGINE_SCHEMA.read_text(encoding="utf-8")
        expected_tables = set(re.findall(r"CREATE TABLE (\w+)", sql))
        expected_views = set(re.findall(r"CREATE VIEW (\w+)", sql))
        reflected = set(db.tables.metadata.tables)
        assert expected_tables <= reflected
        assert expected_views <= reflected
        with db.read() as conn:
            baseline = conn.exec_driver_sql(
                "SELECT count(*) FROM sqlite_master WHERE type='trigger' AND name NOT LIKE 'trg_sync_%'"
            ).scalar()
            assert baseline == len(re.findall(r"CREATE TRIGGER", sql))
            # Migration 0004: three change-capture triggers per captured table, plus saved searches and orgs.
            import importlib.util

            path = Path(__file__).parents[1] / "persistence" / "migrations" / "versions" / "0004_sync.py"
            spec = importlib.util.spec_from_file_location("migration_0004", path)
            assert spec is not None and spec.loader is not None
            _sync_capture = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(_sync_capture)

            capture = conn.exec_driver_sql(
                "SELECT count(*) FROM sqlite_master WHERE type='trigger' AND name LIKE 'trg_sync_%'"
            ).scalar()
            assert capture == 3 * len(_sync_capture.CAPTURE) + 4
            assert {"sync_shadow", "sync_cursors", "sync_keys", "sync_guard"} <= reflected
            assert conn.exec_driver_sql("PRAGMA foreign_keys").scalar() == 1
            assert conn.exec_driver_sql("PRAGMA journal_mode").scalar() == "wal"
            assert conn.exec_driver_sql("PRAGMA user_version").scalar() == 103
        assert db.revision == head_revision()
    finally:
        db.close()


def test_database_file_is_encrypted_and_wrong_key_rejected(tmp_path: Path) -> None:
    db, _key = _db(tmp_path)
    db.close()
    header = (tmp_path / "db" / "pio.db").read_bytes()[:16]
    assert header != b"SQLite format 3\x00"
    with pytest.raises(WrongKeyError):
        ProfileDatabase(tmp_path / "db" / "pio.db", os.urandom(32))


def test_fts5_index_follows_opportunity_rows(tmp_path: Path) -> None:
    db, _ = _db(tmp_path)
    T = db.tables
    try:
        with db.tx() as conn:
            conn.execute(
                insert(T.opportunities).values(
                    id="o1",
                    canonical_url="https://a.example/1",
                    normalized_url="https://a.example/1",
                    dedup_fingerprint="f",
                    title="Bourse de master en géomatique",
                    organization_name="Université de Douala",
                )
            )
        with db.read() as conn:
            hit = conn.execute(
                text(
                    "SELECT o.id FROM opportunities_fts f JOIN opportunities o ON o.rowid = f.rowid "
                    "WHERE opportunities_fts MATCH :q"
                ),
                {"q": "geomatique"},
            ).scalar()
        assert hit == "o1"
    finally:
        db.close()


def test_migration_is_reversible(tmp_path: Path) -> None:
    db, key = _db(tmp_path)
    T = db.tables
    ua = select(T.application_settings.c.value).where(T.application_settings.c.key == "http.user_agent")
    with db.read() as conn:
        assert conn.execute(ua).scalar().startswith("Opportunex/")
    with db.engine.begin() as conn:
        command.downgrade(_alembic_config(conn), "0001_baseline")
    with db.read() as conn:
        assert conn.execute(ua).scalar().startswith("PIO/")
    db.close()
    db2 = ProfileDatabase(tmp_path / "db" / "pio.db", key)  # re-applies 0002 on open
    with db2.read() as conn:
        assert conn.execute(ua).scalar().startswith("Opportunex/")
    db2.close()


def test_pre_migration_hook_runs_only_when_revisions_are_pending(tmp_path: Path) -> None:
    db, key = _db(tmp_path)
    with db.engine.begin() as conn:
        command.downgrade(_alembic_config(conn), "0001_baseline")
    db.close()
    calls: list[tuple[str, str]] = []
    db2 = ProfileDatabase(tmp_path / "db" / "pio.db", key, before_migrate=lambda a, b: calls.append((a, b)))
    db2.close()
    assert calls == [("0001_baseline", head_revision())]
    db3 = ProfileDatabase(tmp_path / "db" / "pio.db", key, before_migrate=lambda a, b: calls.append((a, b)))
    db3.close()
    assert len(calls) == 1


def test_refuses_database_from_newer_version(tmp_path: Path) -> None:
    db, key = _db(tmp_path)
    with db.tx() as conn:
        conn.exec_driver_sql("UPDATE alembic_version SET version_num = '9999_future'")
    db.close()
    with pytest.raises(SchemaTooNewError):
        ProfileDatabase(tmp_path / "db" / "pio.db", key)


def test_schema_constraints_are_enforced(tmp_path: Path) -> None:
    from sqlalchemy.exc import IntegrityError

    db, _ = _db(tmp_path)
    T = db.tables
    try:
        with pytest.raises(IntegrityError), db.tx() as conn:
            conn.execute(
                insert(T.users).values(
                    id="u", email="a@b.c", display_name="x", password_hash="h", recovery_key_hash="r", theme="purple"
                )
            )
    finally:
        db.close()
