"""Backups, restore, profile import, integrity check, storage and log export."""

from __future__ import annotations

from typing import Annotated, Any

from fastapi import APIRouter, Depends, File, Form, Response, UploadFile
from pydantic import BaseModel, Field

from api.deps import Active, StateDep
from core.errors import ValidationFailed
from services.maintenance_service import MAX_IMPORT_BYTES, MaintenanceService

router = APIRouter(tags=["Maintenance"])


def get_service(state: StateDep) -> MaintenanceService:
    return MaintenanceService(state)


Svc = Annotated[MaintenanceService, Depends(get_service)]


class RestoreIn(BaseModel):
    password: str = Field(min_length=1, max_length=256)
    confirmation: str = Field(pattern="^RESTORE$")


class BackupSettingsIn(BaseModel):
    auto_enabled: bool


@router.get("/backups")
def list_backups(active: Active, svc: Svc) -> dict[str, Any]:
    svc.reconcile_records(active)
    return {"items": svc.backups(active).list(), "settings": svc.backup_settings(active)}


@router.post("/backups", status_code=201)
def create_backup(active: Active, svc: Svc) -> dict[str, Any]:
    return svc.create_backup(active, "manual")


@router.put("/backups/settings")
def update_backup_settings(body: BackupSettingsIn, active: Active, svc: Svc) -> dict[str, Any]:
    svc.set_auto_backup(active, body.auto_enabled)
    return svc.backup_settings(active)


@router.post("/backups/{backup_id}/verify")
def verify_backup(backup_id: str, active: Active, svc: Svc) -> dict[str, Any]:
    return svc.backups(active).verify(backup_id, active.key_bytes)


@router.post("/backups/{backup_id}/restore")
def restore_backup(backup_id: str, body: RestoreIn, active: Active, svc: Svc) -> dict[str, Any]:
    return svc.restore(active, backup_id, body.password)


@router.delete("/backups/{backup_id}", status_code=204)
def delete_backup(backup_id: str, active: Active, svc: Svc) -> None:
    svc.backups(active).delete(backup_id)


@router.post("/auth/profiles/import", status_code=201)
async def import_profile(svc: Svc, file: Annotated[UploadFile, File()],
                         password: Annotated[str, Form(min_length=1, max_length=256)]) -> dict[str, Any]:
    data = await file.read(MAX_IMPORT_BYTES + 1)
    if not data:
        raise ValidationFailed("empty file", code="file_empty")
    import asyncio

    record = await asyncio.to_thread(svc.import_profile, data, password)
    return record.public()


@router.get("/maintenance/integrity")
def integrity(active: Active, svc: Svc) -> dict[str, Any]:
    return svc.integrity(active)


@router.post("/maintenance/optimize")
def optimize(active: Active, svc: Svc) -> dict[str, Any]:
    return svc.optimize(active)


@router.get("/maintenance/storage")
def storage(active: Active, svc: Svc) -> dict[str, Any]:
    return svc.storage(active)


@router.get("/maintenance/logs")
def export_logs(_active: Active, svc: Svc) -> Response:
    return Response(content=svc.export_logs(), media_type="application/zip",
                    headers={"Content-Disposition": 'attachment; filename="opportunex-logs.zip"'})
