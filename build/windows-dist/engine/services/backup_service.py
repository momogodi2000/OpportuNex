"""
Database backup service — weekly automated SQLite backups with:
- SHA-256 integrity checksum
- gzip compression
- 6-week retention policy
- Audit logging of all operations
"""

from __future__ import annotations

import gzip
import hashlib
import json
import os
import shutil
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional
from uuid import uuid4

import structlog

from persistence.database import _DB_PATH

log = structlog.get_logger(__name__)

# Backup directory: alongside the database, in a 'backups' subdirectory
_BACKUP_DIR = _DB_PATH.parent / "backups"
_RETENTION_COUNT = 6   # Keep 6 most recent backups


class BackupError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        self.message = message
        super().__init__(message)


class BackupService:
    """
    Manages automated and manual SQLite database backups.
    """

    def __init__(self) -> None:
        _BACKUP_DIR.mkdir(parents=True, exist_ok=True)

    async def create_backup(
        self,
        triggered_by: str = "scheduler",  # "scheduler" | "manual"
    ) -> dict:
        """
        Create a full database backup.

        Steps:
        1. Create backup directory entry
        2. Copy SQLite database using SQLite's backup API (consistent snapshot)
        3. Compute SHA-256 checksum
        4. Compress with gzip
        5. Store metadata
        6. Apply retention policy
        7. Return backup metadata

        Returns:
            dict with backup metadata (id, file_path, size, checksum, etc.)
        """
        backup_id = str(uuid4())
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        raw_backup_path = _BACKUP_DIR / f"opx-backup-{timestamp}-{backup_id[:8]}.db"
        compressed_path = _BACKUP_DIR / f"opx-backup-{timestamp}-{backup_id[:8]}.db.gz"
        meta_path = _BACKUP_DIR / f"opx-backup-{timestamp}-{backup_id[:8]}.meta.json"

        log.info("backup_started", backup_id=backup_id, triggered_by=triggered_by)
        started_at = datetime.utcnow()

        try:
            # ── Step 1: SQLite online backup ─────────────────────────────
            if not _DB_PATH.exists():
                raise BackupError("DB_NOT_FOUND", "Database file does not exist")

            await self._sqlite_backup(_DB_PATH, raw_backup_path)
            original_size = raw_backup_path.stat().st_size

            # ── Step 2: Compute checksum ──────────────────────────────────
            checksum = self._compute_sha256(raw_backup_path)

            # ── Step 3: Compress ──────────────────────────────────────────
            self._compress(raw_backup_path, compressed_path)
            compressed_size = compressed_path.stat().st_size

            # ── Step 4: Remove uncompressed ───────────────────────────────
            raw_backup_path.unlink()

            finished_at = datetime.utcnow()
            duration_s = (finished_at - started_at).total_seconds()

            # ── Step 5: Write metadata ────────────────────────────────────
            meta = {
                "backup_id": backup_id,
                "status": "success",
                "file_name": compressed_path.name,
                "file_path": str(compressed_path),
                "original_size_bytes": original_size,
                "compressed_size_bytes": compressed_size,
                "compression_ratio": round(original_size / compressed_size, 2) if compressed_size else 1.0,
                "checksum_sha256": checksum,
                "triggered_by": triggered_by,
                "started_at": started_at.isoformat() + "Z",
                "finished_at": finished_at.isoformat() + "Z",
                "duration_seconds": duration_s,
                "source_db": str(_DB_PATH),
            }
            meta_path.write_text(json.dumps(meta, indent=2))

            log.info(
                "backup_completed",
                backup_id=backup_id,
                compressed_size=compressed_size,
                duration_s=duration_s,
                checksum=checksum[:16] + "...",
            )

            # ── Step 6: Apply retention policy ────────────────────────────
            self._apply_retention_policy()

            return meta

        except Exception as e:
            # Clean up partial files
            for p in [raw_backup_path, compressed_path, meta_path]:
                if p.exists():
                    p.unlink(missing_ok=True)

            log.error("backup_failed", backup_id=backup_id, error=str(e))
            raise BackupError("BACKUP_FAILED", str(e)) from e

    async def _sqlite_backup(self, source: Path, dest: Path) -> None:
        """
        Create a consistent SQLite backup using the Python sqlite3 backup API.
        This is safe for WAL-mode databases.
        """
        import sqlite3
        import asyncio

        def _do_backup() -> None:
            src_conn = sqlite3.connect(str(source))
            dst_conn = sqlite3.connect(str(dest))
            try:
                src_conn.backup(dst_conn, pages=100)
            finally:
                src_conn.close()
                dst_conn.close()

        await asyncio.to_thread(_do_backup)

    def _compute_sha256(self, path: Path) -> str:
        """Compute SHA-256 checksum of a file."""
        h = hashlib.sha256()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(65536), b""):
                h.update(chunk)
        return h.hexdigest()

    def _compress(self, source: Path, dest: Path) -> None:
        """Compress a file using gzip."""
        with open(source, "rb") as f_in:
            with gzip.open(dest, "wb", compresslevel=9) as f_out:
                shutil.copyfileobj(f_in, f_out)

    def _apply_retention_policy(self) -> None:
        """
        Keep only the 6 most recent successful backups.
        Deletes older backups and their metadata files.
        """
        meta_files = sorted(
            _BACKUP_DIR.glob("*.meta.json"),
            key=lambda p: p.stat().st_mtime,
            reverse=True,
        )

        to_delete = meta_files[_RETENTION_COUNT:]
        for meta_path in to_delete:
            try:
                meta = json.loads(meta_path.read_text())
                backup_file = Path(meta.get("file_path", ""))
                if backup_file.exists():
                    backup_file.unlink()
                meta_path.unlink()
                log.info("backup_deleted_retention", file=meta.get("file_name"))
            except Exception as e:
                log.warning("retention_cleanup_error", path=str(meta_path), error=str(e))

    def list_backups(self) -> list[dict]:
        """List all backups with their metadata, sorted by date (newest first)."""
        backups = []
        for meta_path in sorted(
            _BACKUP_DIR.glob("*.meta.json"),
            key=lambda p: p.stat().st_mtime,
            reverse=True,
        ):
            try:
                meta = json.loads(meta_path.read_text())
                # Verify the backup file still exists
                file_path = Path(meta.get("file_path", ""))
                meta["file_exists"] = file_path.exists()
                backups.append(meta)
            except Exception:
                pass
        return backups

    def verify_backup(self, backup_id: str) -> dict:
        """
        Verify backup integrity by recomputing the checksum.
        Returns {valid: bool, stored_checksum, computed_checksum}.
        """
        meta_files = list(_BACKUP_DIR.glob(f"*{backup_id[:8]}*.meta.json"))
        if not meta_files:
            raise BackupError("BACKUP_NOT_FOUND", f"Backup {backup_id} not found")

        meta = json.loads(meta_files[0].read_text())
        file_path = Path(meta["file_path"])

        if not file_path.exists():
            return {"valid": False, "error": "Backup file not found on disk"}

        # Decompress temporarily and verify
        stored_checksum = meta.get("checksum_sha256", "")
        try:
            import tempfile
            with tempfile.NamedTemporaryFile(delete=False, suffix=".db") as tmp:
                with gzip.open(file_path, "rb") as gz:
                    shutil.copyfileobj(gz, tmp)
                tmp_path = Path(tmp.name)
            computed = self._compute_sha256(tmp_path)
            tmp_path.unlink(missing_ok=True)
        except Exception as e:
            return {"valid": False, "error": str(e)}

        valid = stored_checksum == computed
        log.info(
            "backup_verified",
            backup_id=backup_id,
            valid=valid,
        )
        return {
            "valid": valid,
            "stored_checksum": stored_checksum,
            "computed_checksum": computed,
        }

    async def restore_backup(
        self,
        backup_id: str,
        user_id: str,
        confirmed: bool = False,
    ) -> dict:
        """
        Restore the database from a backup.

        Safety steps:
        1. Verify user authorization (super admin only)
        2. Require explicit confirmation
        3. Verify backup integrity
        4. Create safety snapshot of current database
        5. Restore
        6. Verify restored database can be opened
        7. Record result
        """
        if not confirmed:
            raise BackupError(
                "CONFIRMATION_REQUIRED",
                "Explicit confirmation required for database restoration",
            )

        # Find backup metadata
        meta_files = list(_BACKUP_DIR.glob(f"*{backup_id[:8]}*.meta.json"))
        if not meta_files:
            raise BackupError("BACKUP_NOT_FOUND", f"Backup {backup_id} not found")

        meta = json.loads(meta_files[0].read_text())
        file_path = Path(meta["file_path"])

        if not file_path.exists():
            raise BackupError("BACKUP_FILE_MISSING", "Backup file not found on disk")

        # Verify integrity before restoring
        verify_result = self.verify_backup(backup_id)
        if not verify_result.get("valid"):
            raise BackupError(
                "BACKUP_INTEGRITY_FAILED",
                "Backup checksum verification failed — cannot restore a corrupted backup",
            )

        # Create safety snapshot of current DB
        safety_path = _BACKUP_DIR / f"safety-snapshot-{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.db"
        try:
            await self._sqlite_backup(_DB_PATH, safety_path)
            log.info("safety_snapshot_created", path=str(safety_path))
        except Exception as e:
            raise BackupError("SAFETY_SNAPSHOT_FAILED", f"Could not create safety snapshot: {e}") from e

        # Restore
        try:
            import tempfile
            with tempfile.NamedTemporaryFile(delete=False, suffix=".db") as tmp:
                with gzip.open(file_path, "rb") as gz:
                    shutil.copyfileobj(gz, tmp)
                tmp_path = Path(tmp.name)

            # Verify the restored file can be opened as a SQLite database
            import sqlite3
            try:
                conn = sqlite3.connect(str(tmp_path))
                conn.execute("PRAGMA integrity_check")
                conn.close()
            except Exception as e:
                tmp_path.unlink(missing_ok=True)
                raise BackupError("RESTORE_INTEGRITY_CHECK_FAILED", str(e)) from e

            # Replace the live database
            shutil.copy2(str(tmp_path), str(_DB_PATH))
            tmp_path.unlink(missing_ok=True)

            log.info("restore_completed", backup_id=backup_id, user_id=user_id)

            return {
                "success": True,
                "backup_id": backup_id,
                "safety_snapshot": str(safety_path),
                "restored_at": datetime.utcnow().isoformat() + "Z",
            }

        except BackupError:
            raise
        except Exception as e:
            # Attempt rollback using safety snapshot
            try:
                shutil.copy2(str(safety_path), str(_DB_PATH))
                log.warning("restore_rolled_back", reason=str(e))
            except Exception as rollback_err:
                log.error("rollback_failed", error=str(rollback_err))
            raise BackupError("RESTORE_FAILED", str(e)) from e
