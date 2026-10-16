from __future__ import annotations

import zipfile
from pathlib import Path

from sqlalchemy import func, insert, select

from services.backup_service import KEEP, BackupService
from tests.conftest import STRONG_PASSWORD, EngineClient


def _count_workspaces(client: EngineClient) -> int:
    active = client.state.active
    T = active.tables
    with active.db.read() as conn:
        return int(conn.execute(select(func.count()).select_from(T.research_workspaces)).scalar())


def _add_workspace(client: EngineClient, name: str) -> None:
    from core.ids import uuid7

    active = client.state.active
    T = active.tables
    with active.db.tx() as conn:
        conn.execute(insert(T.research_workspaces).values(id=uuid7(), user_id=active.user_id, name=name))


def test_manual_backup_is_encrypted_listed_and_verifiable(signed_in: EngineClient) -> None:
    signed_in.state.active.vault.put(b"attached diploma")
    r = signed_in.post("/backups")
    assert r.status_code == 201, r.text
    backup = r.json()
    assert backup["kind"] == "manual" and backup["status"] == "ok" and backup["available"]
    archive = signed_in.state.paths.profile_backups(signed_in.state.active.user_id) / backup["file_path"]
    with zipfile.ZipFile(archive) as zf:
        names = set(zf.namelist())
        assert {"db/pio.db", "manifest.json", "profile.json"} <= names
        assert any(n.startswith("vault/") for n in names)
        assert not zf.read("db/pio.db").startswith(b"SQLite format 3")
        assert b"attached diploma" not in b"".join(zf.read(n) for n in names)
    listing = signed_in.get("/backups").json()
    assert [b["id"] for b in listing["items"]] == [backup["id"]]
    assert listing["settings"]["auto_enabled"] is True
    assert signed_in.post(f"/backups/{backup['id']}/verify").json()["valid"] is True


def test_corrupted_archive_is_rejected(signed_in: EngineClient) -> None:
    backup = signed_in.post("/backups").json()
    archive = signed_in.state.paths.profile_backups(signed_in.state.active.user_id) / backup["file_path"]
    data = bytearray(archive.read_bytes())
    data[len(data) // 3] ^= 0xFF
    archive.write_bytes(bytes(data))
    r = signed_in.post(f"/backups/{backup['id']}/verify")
    assert r.status_code == 422 and r.json()["code"] == "backup_corrupted"


def test_restore_requires_password_and_brings_data_back(signed_in: EngineClient) -> None:
    _add_workspace(signed_in, "Bourses 2027")
    backup = signed_in.post("/backups").json()
    _add_workspace(signed_in, "Emplois")
    assert _count_workspaces(signed_in) == 2
    bad = signed_in.post(f"/backups/{backup['id']}/restore", json={"password": "wrong", "confirmation": "RESTORE"})
    assert bad.status_code == 401
    r = signed_in.post(
        f"/backups/{backup['id']}/restore", json={"password": STRONG_PASSWORD, "confirmation": "RESTORE"}
    )
    assert r.status_code == 200, r.text
    assert _count_workspaces(signed_in) == 1
    # Still signed in, and the pre-restore safety backup is known after reconciliation.
    kinds = {b["kind"] for b in signed_in.get("/backups").json()["items"]}
    assert {"manual", "pre_restore"} <= kinds
    restored = [b for b in signed_in.get("/backups").json()["items"] if b["id"] == backup["id"]]
    assert restored[0]["status"] == "restored"


def test_retention_keeps_seven_scheduled_backups(signed_in: EngineClient) -> None:
    active = signed_in.state.active
    svc = BackupService(
        db=active.db,
        user_id=active.user_id,
        backups_dir=signed_in.state.paths.profile_backups(active.user_id),
        vault_dir=signed_in.state.paths.profile_vault(active.user_id),
        record=signed_in.state.registry.get(active.user_id),
    )
    for _ in range(KEEP["scheduled"] + 2):
        svc.create("scheduled")
    svc.create("manual")
    items = svc.list_items()
    assert sum(1 for b in items if b["kind"] == "scheduled") == KEEP["scheduled"]
    assert sum(1 for b in items if b["kind"] == "manual") == 1
    files = list(svc.dir.glob("*.opxbak"))
    assert len(files) == KEEP["scheduled"] + 1


def test_scheduled_backup_runs_once_per_day(signed_in: EngineClient) -> None:
    from services.maintenance_service import MaintenanceService

    svc = MaintenanceService(signed_in.state)
    active = signed_in.state.active
    assert svc.run_scheduled_backup_if_due(active) is not None
    assert svc.run_scheduled_backup_if_due(active) is None
    signed_in.put("/backups/settings", json={"auto_enabled": False})
    assert signed_in.get("/backups").json()["settings"]["auto_enabled"] is False


def test_import_profile_from_backup_on_new_machine(signed_in: EngineClient, tmp_path: Path, settings: object) -> None:
    import secrets

    from fastapi.testclient import TestClient

    from api.app import create_app
    from core.config import Settings

    _add_workspace(signed_in, "Marchés publics")
    backup = signed_in.post("/backups").json()
    archive = signed_in.state.paths.profile_backups(signed_in.state.active.user_id) / backup["file_path"]

    other = Settings(data_dir=tmp_path / "other-machine", kdf_memory_kib=1024, kdf_iterations=1)
    token = secrets.token_urlsafe(32)
    with TestClient(create_app(other, token), base_url="http://127.0.0.1") as client:
        h = {"X-Engine-Token": token}
        bad = client.post(
            "/api/v1/auth/profiles/import",
            headers=h,
            files={"file": ("b.opxbak", archive.read_bytes())},
            data={"password": "x"},
        )
        assert bad.status_code == 401
        ok = client.post(
            "/api/v1/auth/profiles/import",
            headers=h,
            files={"file": ("b.opxbak", archive.read_bytes())},
            data={"password": STRONG_PASSWORD},
        )
        assert ok.status_code == 201, ok.text
        login = client.post(
            "/api/v1/auth/login", headers=h, json={"email": "awa@example.com", "password": STRONG_PASSWORD}
        )
        assert login.status_code == 200
        state = client.app.state.engine
        T = state.active.tables
        with state.active.db.read() as conn:
            names = conn.execute(select(T.research_workspaces.c.name)).scalars().all()
        assert names == ["Marchés publics"]


def test_maintenance_endpoints(signed_in: EngineClient) -> None:
    assert signed_in.get("/maintenance/integrity").json()["ok"] is True
    assert signed_in.post("/maintenance/optimize").json()["ok"] is True
    storage = signed_in.get("/maintenance/storage").json()
    assert storage["database_bytes"] > 0
    r = signed_in.get("/maintenance/logs")
    assert r.status_code == 200 and r.headers["content-type"] == "application/zip"
