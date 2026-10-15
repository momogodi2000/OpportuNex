"""Encrypted backup and verified restore (EF-18.05, EF-18.06, arch §13.2).

A backup is a ``.opxbak`` ZIP archive containing:

* ``db/pio.db``   — ``VACUUM INTO`` snapshot, still SQLCipher-encrypted with the data key;
* ``vault/**``    — the vault blobs (already AES-GCM encrypted);
* ``profile.json``— the registry record (hashes, salts and wrapped keys only) so the profile
  can be restored on another machine with the user's password;
* ``manifest.json``— format version, schema revision, engine version and SHA-256 of every
  member, checked before any restore.

Retention (spec over agent rule C-02): keep the 7 most recent ``scheduled`` backups and the
3 most recent ``pre_migration`` / ``pre_restore`` ones; ``manual`` backups are kept until the
user deletes them. Retention works from ``backup_records`` metadata, never file names.
"""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import tempfile
import zipfile
from dataclasses import asdict
from pathlib import Path
from typing import Any

import structlog
from sqlalchemy import delete, desc, insert, select, update

from core.errors import NotFound, ValidationFailed
from core.ids import uuid7
from core.timeutil import now_iso, parse_iso, utcnow
from core.version import ENGINE_VERSION
from persistence.database import ProfileDatabase, integrity_check, make_engine, vacuum_into
from persistence.registry import ProfileRecord

log = structlog.get_logger(__name__)

FORMAT_VERSION = 1
KEEP = {"scheduled": 7, "pre_migration": 3, "pre_restore": 3}
SCHEDULE_INTERVAL_HOURS = 24


def _sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def snapshot_db_file(db_path: Path, target: Path, key: bytes) -> None:
    """Consistent encrypted copy of a live database (used before migrations)."""
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        target.unlink()
    engine = make_engine(db_path, key)
    try:
        vacuum_into(engine, target)
    finally:
        engine.dispose()


class BackupService:
    def __init__(self, *, db: ProfileDatabase, user_id: str, backups_dir: Path,
                 vault_dir: Path, record: ProfileRecord) -> None:
        self.db = db
        self.user_id = user_id
        self.dir = backups_dir
        self.vault_dir = vault_dir
        self.record = record

    # ------------------------------------------------------------------ create
    def create(self, kind: str) -> dict[str, Any]:
        if kind not in ("manual", "scheduled", "pre_migration", "pre_restore"):
            raise ValidationFailed("unknown backup kind", code="backup_kind_invalid")
        self.dir.mkdir(parents=True, exist_ok=True)
        backup_id = uuid7()
        stamp = utcnow().strftime("%Y%m%dT%H%M%SZ")
        final = self.dir / f"opportunex-{stamp}-{kind}-{backup_id[-8:]}.opxbak"
        with tempfile.TemporaryDirectory(prefix="opx-bak-") as tmp:
            tmpdir = Path(tmp)
            snap = tmpdir / "pio.db"
            vacuum_into(self.db.engine, snap)
            members: dict[str, str] = {"db/pio.db": _sha256_file(snap)}
            partial = final.with_suffix(".partial")
            with zipfile.ZipFile(partial, "w", compression=zipfile.ZIP_DEFLATED) as zf:
                zf.write(snap, "db/pio.db")
                if self.vault_dir.exists():
                    for f in sorted(self.vault_dir.rglob("*.bin")):
                        arc = "vault/" + f.relative_to(self.vault_dir).as_posix()
                        zf.write(f, arc)
                        members[arc] = _sha256_file(f)
                profile_json = json.dumps(asdict(self.record), indent=2).encode()
                zf.writestr("profile.json", profile_json)
                members["profile.json"] = hashlib.sha256(profile_json).hexdigest()
                manifest = {
                    "format": FORMAT_VERSION,
                    "backup_id": backup_id,
                    "profile_id": self.user_id,
                    "kind": kind,
                    "created_at": now_iso(),
                    "schema_revision": self.db.revision,
                    "engine_version": ENGINE_VERSION,
                    "members": members,
                }
                zf.writestr("manifest.json", json.dumps(manifest, indent=2))
            os.replace(partial, final)
        size = final.stat().st_size
        digest = _sha256_file(final)
        T = self.db.tables
        with self.db.tx() as conn:
            conn.execute(insert(T.backup_records).values(
                id=backup_id, user_id=self.user_id, kind=kind, file_path=final.name,
                size_bytes=size, sha256=digest, schema_version=self.db.revision,
                encrypted=1, status="ok",
            ))
        log.info("backup_created", kind=kind, size=size)
        self.apply_retention()
        return self.get(backup_id)

    # ------------------------------------------------------------------- query
    def list(self) -> list[dict[str, Any]]:
        T = self.db.tables
        with self.db.read() as conn:
            rows = conn.execute(
                select(T.backup_records).where(T.backup_records.c.user_id == self.user_id,
                                               T.backup_records.c.status != "deleted")
                .order_by(desc(T.backup_records.c.created_at), desc(T.backup_records.c.id))
            ).mappings().all()
        return [self._present(dict(r)) for r in rows]

    def get(self, backup_id: str) -> dict[str, Any]:
        T = self.db.tables
        with self.db.read() as conn:
            row = conn.execute(select(T.backup_records).where(
                T.backup_records.c.id == backup_id, T.backup_records.c.user_id == self.user_id)
            ).mappings().first()
        if row is None:
            raise NotFound("backup not found", code="backup_not_found")
        return self._present(dict(row))

    def _present(self, row: dict[str, Any]) -> dict[str, Any]:
        row["available"] = (self.dir / row["file_path"]).is_file()
        return row

    def last_scheduled_at(self) -> str | None:
        T = self.db.tables
        with self.db.read() as conn:
            return conn.execute(
                select(T.backup_records.c.created_at)
                .where(T.backup_records.c.user_id == self.user_id,
                       T.backup_records.c.kind == "scheduled",
                       T.backup_records.c.status == "ok")
                .order_by(desc(T.backup_records.c.created_at)).limit(1)
            ).scalar_one_or_none()

    def scheduled_backup_due(self) -> bool:
        last = parse_iso(self.last_scheduled_at())
        return last is None or (utcnow() - last).total_seconds() >= SCHEDULE_INTERVAL_HOURS * 3600

    # ------------------------------------------------------------------ verify
    def _archive_path(self, backup_id: str) -> Path:
        row = self.get(backup_id)
        path = (self.dir / row["file_path"]).resolve()
        if not path.is_relative_to(self.dir.resolve()) or not path.is_file():
            raise NotFound("backup file missing", code="backup_file_missing")
        return path

    @staticmethod
    def read_manifest(archive: Path) -> dict[str, Any]:
        try:
            with zipfile.ZipFile(archive) as zf:
                manifest = json.loads(zf.read("manifest.json"))
                if manifest.get("format") != FORMAT_VERSION:
                    raise ValidationFailed("unsupported backup format", code="backup_format_unsupported")
                for name, digest in manifest["members"].items():
                    if not _safe_member(name):
                        raise ValidationFailed("unsafe path in backup", code="backup_corrupted")
                    if hashlib.sha256(zf.read(name)).hexdigest() != digest:
                        raise ValidationFailed("checksum mismatch", code="backup_corrupted")
                return manifest
        except (zipfile.BadZipFile, KeyError, json.JSONDecodeError) as exc:
            raise ValidationFailed("backup archive is corrupted", code="backup_corrupted") from exc

    def verify(self, backup_id: str, key: bytes) -> dict[str, Any]:
        archive = self._archive_path(backup_id)
        manifest = self.read_manifest(archive)
        if manifest["profile_id"] != self.user_id:
            raise ValidationFailed("backup belongs to another profile", code="backup_wrong_profile")
        with tempfile.TemporaryDirectory(prefix="opx-verify-") as tmp:
            db_file = Path(tmp) / "pio.db"
            with zipfile.ZipFile(archive) as zf:
                db_file.write_bytes(zf.read("db/pio.db"))
            engine = make_engine(db_file, key)
            try:
                integrity_check(engine)
            finally:
                engine.dispose()
        return {"backup_id": backup_id, "valid": True, "schema_revision": manifest["schema_revision"]}

    # --------------------------------------------------------------- retention
    def apply_retention(self) -> int:
        T = self.db.tables
        removed = 0
        for kind, keep in KEEP.items():
            with self.db.read() as conn:
                stale = conn.execute(
                    select(T.backup_records.c.id, T.backup_records.c.file_path)
                    .where(T.backup_records.c.user_id == self.user_id,
                           T.backup_records.c.kind == kind,
                           T.backup_records.c.status.in_(("ok", "restored")))
                    .order_by(desc(T.backup_records.c.created_at), desc(T.backup_records.c.id))
                    .offset(keep)
                ).all()
            for backup_id, file_name in stale:
                self._delete_file(file_name)
                with self.db.tx() as conn:
                    conn.execute(update(T.backup_records)
                                 .where(T.backup_records.c.id == backup_id)
                                 .values(status="deleted"))
                removed += 1
        return removed

    def delete(self, backup_id: str) -> None:
        row = self.get(backup_id)
        self._delete_file(row["file_path"])
        T = self.db.tables
        with self.db.tx() as conn:
            conn.execute(delete(T.backup_records).where(T.backup_records.c.id == backup_id))

    def _delete_file(self, file_name: str) -> None:
        path = (self.dir / file_name).resolve()
        if path.is_relative_to(self.dir.resolve()) and path.is_file():
            path.unlink()


def _safe_member(name: str) -> bool:
    p = Path(name)
    return not p.is_absolute() and ".." not in p.parts and (
        name in ("db/pio.db", "profile.json") or name.startswith("vault/"))


def extract_restore_payload(archive: Path, workdir: Path) -> dict[str, Any]:
    """Validate and unpack an archive into ``workdir`` (db/ and vault/). Returns the manifest."""
    manifest = BackupService.read_manifest(archive)
    with zipfile.ZipFile(archive) as zf:
        for name in manifest["members"]:
            target = (workdir / name).resolve()
            if not target.is_relative_to(workdir.resolve()):
                raise ValidationFailed("unsafe path in backup", code="backup_corrupted")
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(zf.read(name))
    return manifest


def swap_in_restored(profile_dir: Path, workdir: Path) -> Path:
    """Atomically replace db/ and vault/ of a closed profile. Returns the rollback folder."""
    rollback = profile_dir / f".rollback-{uuid7()[-8:]}"
    rollback.mkdir()
    for part in ("db", "vault"):
        current = profile_dir / part
        if current.exists():
            os.replace(current, rollback / part)
    try:
        (profile_dir / "db").mkdir()
        os.replace(workdir / "db" / "pio.db", profile_dir / "db" / "pio.db")
        restored_vault = workdir / "vault"
        if restored_vault.exists():
            os.replace(restored_vault, profile_dir / "vault")
    except Exception:
        rollback_restore(profile_dir, rollback)
        raise
    return rollback


def rollback_restore(profile_dir: Path, rollback: Path) -> None:
    for part in ("db", "vault"):
        restored = profile_dir / part
        if restored.exists():
            shutil.rmtree(restored)
        saved = rollback / part
        if saved.exists():
            os.replace(saved, restored)
    shutil.rmtree(rollback, ignore_errors=True)


def discard_rollback(rollback: Path) -> None:
    shutil.rmtree(rollback, ignore_errors=True)
