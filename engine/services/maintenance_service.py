"""Backups, verified restore, profile import, integrity and storage maintenance (M18)."""

from __future__ import annotations

import io
import json
import shutil
import tempfile
import zipfile
from pathlib import Path
from typing import Any

import structlog
from sqlalchemy import func, insert, select

from core.errors import Conflict, NotFound, Unauthorized, ValidationFailed
from core.timeutil import now_iso
from persistence.database import ProfileDatabase, integrity_check
from persistence.registry import ProfileRecord
from security.crypto import KdfParams, UnwrapError, b64d, derive_kek, unwrap_key, verify_secret
from security.redaction import redact
from security.vault import Vault
from services.backup_service import (
    BackupService,
    discard_rollback,
    extract_restore_payload,
    rollback_restore,
    swap_in_restored,
)
from services.state import ActiveProfile, EngineState

log = structlog.get_logger(__name__)

MAX_IMPORT_BYTES = 2 * 1024 * 1024 * 1024


def _record_params(record: ProfileRecord) -> KdfParams:
    return KdfParams(memory_kib=record.kdf_memory_kib, iterations=record.kdf_iterations)


class MaintenanceService:
    def __init__(self, state: EngineState) -> None:
        self.state = state

    def _record(self, user_id: str) -> ProfileRecord:
        record = self.state.registry.get(user_id)
        if record is None:
            raise NotFound("profile not found", code="profile_not_found")
        return record

    def backups(self, active: ActiveProfile) -> BackupService:
        paths = self.state.paths
        return BackupService(
            db=active.db,
            user_id=active.user_id,
            backups_dir=paths.profile_backups(active.user_id),
            vault_dir=paths.profile_vault(active.user_id),
            record=self._record(active.user_id),
        )

    def _require_password(self, active: ActiveProfile, password: str) -> None:
        record = self._record(active.user_id)
        if not verify_secret(password, record.auth_hash, _record_params(record)):
            raise Unauthorized("password is wrong", code="invalid_credentials")

    # ------------------------------------------------------------- backups
    def create_backup(self, active: ActiveProfile, kind: str = "manual") -> dict[str, Any]:
        self.state.events.publish("backup.started", {"kind": kind})
        result = self.backups(active).create(kind)
        self.state.events.publish("backup.completed", {"backup_id": result["id"], "kind": kind})
        return result

    def run_scheduled_backup_if_due(self, active: ActiveProfile) -> dict[str, Any] | None:
        T = active.tables
        with active.db.read() as conn:
            enabled = conn.execute(
                select(T.application_settings.c.value).where(T.application_settings.c.key == "backup.auto_enabled")
            ).scalar_one_or_none()
        if enabled != "true":
            return None
        svc = self.backups(active)
        if not svc.scheduled_backup_due():
            return None
        return self.create_backup(active, "scheduled")

    def set_auto_backup(self, active: ActiveProfile, enabled: bool) -> None:
        T = active.tables
        with active.db.tx() as conn:
            conn.execute(
                T.application_settings.update()
                .where(T.application_settings.c.key == "backup.auto_enabled")
                .values(value="true" if enabled else "false", updated_at=now_iso())
            )

    def backup_settings(self, active: ActiveProfile) -> dict[str, Any]:
        T = active.tables
        with active.db.read() as conn:
            rows = dict(
                conn.execute(
                    select(T.application_settings.c.key, T.application_settings.c.value).where(
                        T.application_settings.c.key.like("backup.%")
                    )
                ).all()
            )
        svc = self.backups(active)
        return {
            "auto_enabled": rows.get("backup.auto_enabled") == "true",
            "retention_count": int(rows.get("backup.retention_count", "7")),
            "last_scheduled_at": svc.last_scheduled_at(),
            "directory": str(svc.dir),
        }

    def reconcile_records(self, active: ActiveProfile) -> int:
        """Re-create metadata for archives on disk that the (restored) database doesn't know."""
        svc = self.backups(active)
        T = active.tables
        if not svc.dir.exists():
            return 0
        with active.db.read() as conn:
            known = set(conn.execute(select(T.backup_records.c.file_path)).scalars())
        added = 0
        for archive in sorted(svc.dir.glob("*.opxbak")):
            if archive.name in known:
                continue
            try:
                with zipfile.ZipFile(archive) as zf:
                    manifest = json.loads(zf.read("manifest.json"))
            except (zipfile.BadZipFile, KeyError, json.JSONDecodeError):
                continue
            if manifest.get("profile_id") != active.user_id:
                continue
            import hashlib

            digest = hashlib.sha256(archive.read_bytes()).hexdigest()
            with active.db.tx() as conn:
                exists = conn.execute(
                    select(func.count())
                    .select_from(T.backup_records)
                    .where(T.backup_records.c.id == manifest["backup_id"])
                ).scalar()
                if exists:
                    continue
                conn.execute(
                    insert(T.backup_records).values(
                        id=manifest["backup_id"],
                        user_id=active.user_id,
                        kind=manifest["kind"],
                        file_path=archive.name,
                        size_bytes=archive.stat().st_size,
                        sha256=digest,
                        schema_version=manifest["schema_revision"],
                        encrypted=1,
                        status="ok",
                        created_at=manifest["created_at"],
                    )
                )
            added += 1
        return added

    # ------------------------------------------------------------- restore
    def restore(self, active: ActiveProfile, backup_id: str, password: str) -> dict[str, Any]:
        self._require_password(active, password)
        svc = self.backups(active)
        archive = svc._archive_path(backup_id)
        svc.verify(backup_id, active.key_bytes)
        self.create_backup(active, "pre_restore")
        key = active.key_bytes
        user_id = active.user_id
        profile_dir = self.state.paths.profile_dir(user_id)
        self.state.events.publish("restore.started", {"backup_id": backup_id})
        # Close the live database but keep the session: the user stays signed in.
        if self.state.jobs is not None:
            self.state.jobs.cancel_all_for(user_id)
        active.db.close()
        with tempfile.TemporaryDirectory(prefix="opx-restore-", dir=str(profile_dir)) as tmp:
            workdir = Path(tmp)
            extract_restore_payload(archive, workdir)
            rollback = swap_in_restored(profile_dir, workdir)
        try:
            new_db = ProfileDatabase(self.state.paths.profile_db(user_id), key, echo=self.state.settings.sql_echo)
            integrity_check(new_db.engine)
        except Exception:
            log.exception("restore_failed_rolling_back")
            rollback_restore(profile_dir, rollback)
            active.db = ProfileDatabase(self.state.paths.profile_db(user_id), key)
            self.state.events.publish("restore.failed", {"backup_id": backup_id})
            raise
        discard_rollback(rollback)
        active.db = new_db
        active.vault = Vault(self.state.paths.profile_vault(user_id), key)
        self.reconcile_records(active)
        T = active.tables
        with active.db.tx() as conn:
            conn.execute(T.backup_records.update().where(T.backup_records.c.id == backup_id).values(status="restored"))
            conn.execute(
                insert(T.audit_logs).values(
                    user_id=user_id, action="backup.restore", entity_table="backup_records", entity_id=backup_id
                )
            )
        self.state.events.publish("restore.completed", {"backup_id": backup_id})
        return {"restored": True, "backup_id": backup_id, "schema_revision": active.db.revision}

    # -------------------------------------------------- import on a new machine
    def import_profile(self, archive_bytes: bytes, password: str) -> ProfileRecord:
        if len(archive_bytes) > MAX_IMPORT_BYTES:
            raise ValidationFailed("archive too large", code="file_too_large")
        with tempfile.TemporaryDirectory(prefix="opx-import-") as tmp:
            workdir = Path(tmp)
            archive = workdir / "import.opxbak"
            archive.write_bytes(archive_bytes)
            payload = workdir / "payload"
            payload.mkdir()
            extract_restore_payload(archive, payload)
            record = ProfileRecord(**json.loads((payload / "profile.json").read_text(encoding="utf-8")))
            if not verify_secret(password, record.auth_hash, _record_params(record)):
                raise Unauthorized("password is wrong", code="invalid_credentials")
            if self.state.registry.get(record.id) is not None:
                raise Conflict("this profile already exists on this computer", code="profile_exists")
            if any(p.email_sha256 == record.email_sha256 for p in self.state.registry.all()):
                raise Conflict("an account already uses this e-mail", code="email_taken")
            try:
                key = unwrap_key(
                    b64d(record.pw_wrapped_key),
                    derive_kek(password, b64d(record.pw_salt), _record_params(record)),
                    f"opportunex:{record.id}:pw".encode(),
                )
            except UnwrapError as exc:
                raise ValidationFailed("backup key cannot be unwrapped", code="backup_corrupted") from exc
            profile_dir = self.state.paths.profile_dir(record.id)
            profile_dir.mkdir(parents=True)
            try:
                (profile_dir / "db").mkdir()
                shutil.move(str(payload / "db" / "pio.db"), profile_dir / "db" / "pio.db")
                if (payload / "vault").exists():
                    shutil.move(str(payload / "vault"), profile_dir / "vault")
                db = ProfileDatabase(profile_dir / "db" / "pio.db", key)
                db.close()
            except Exception:
                shutil.rmtree(profile_dir, ignore_errors=True)
                raise
        record.failed_count = 0
        record.locked_until = None
        record.pending_attempts = []
        self.state.registry.add(record)
        log.info("profile_imported")
        return record

    # ------------------------------------------------------------ diagnostics
    def integrity(self, active: ActiveProfile) -> dict[str, Any]:
        integrity_check(active.db.engine)
        with active.db.read() as conn:
            conn.exec_driver_sql("INSERT INTO opportunities_fts(opportunities_fts) VALUES ('integrity-check')")
        return {"ok": True, "checked_at": now_iso()}

    def optimize(self, active: ActiveProfile) -> dict[str, Any]:
        raw = active.db.engine.raw_connection()
        try:
            drv = raw.driver_connection
            drv.execute(  # type: ignore[union-attr]
                "INSERT INTO opportunities_fts(opportunities_fts) VALUES ('optimize')"
            )
            drv.execute("PRAGMA optimize")  # type: ignore[union-attr]
            drv.execute("VACUUM")  # type: ignore[union-attr]
        finally:
            raw.close()
        return {"ok": True}

    def storage(self, active: ActiveProfile) -> dict[str, Any]:
        paths = self.state.paths
        db_file = paths.profile_db(active.user_id)
        db_bytes = sum(p.stat().st_size for p in db_file.parent.glob("pio.db*") if p.is_file())
        backups_dir = paths.profile_backups(active.user_id)
        backup_bytes = (
            sum(p.stat().st_size for p in backups_dir.glob("*") if p.is_file()) if backups_dir.exists() else 0
        )
        return {
            "database_bytes": db_bytes,
            "vault_bytes": active.vault.size_bytes(),
            "backups_bytes": backup_bytes,
            "data_dir": str(paths.root),
        }

    def export_logs(self) -> bytes:
        """ZIP of the technical logs, re-redacted line by line (EF-18.12)."""
        buf = io.BytesIO()
        with zipfile.ZipFile(buf, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            for log_file in sorted(self.state.paths.logs.glob("*.log*")):
                text = log_file.read_text(encoding="utf-8", errors="replace")
                zf.writestr(log_file.name, "\n".join(redact(line) for line in text.splitlines()))
            zf.writestr("README.txt", "Opportunex technical logs, redacted (no e-mails, tokens or keys).\n")
        return buf.getvalue()
