from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel
from typing import Optional, List

router = APIRouter(prefix="/maintenance", tags=["Maintenance"])

def require_user(x_user_id: Optional[str] = Header(None)) -> str:
    if not x_user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"type": "about:blank", "title": "Unauthorized", "status": 401, "detail": "Missing X-User-Id"}
        )
    return x_user_id

class RestoreRequest(BaseModel):
    confirmed: bool

@router.get("/backups")
async def list_backups(x_user_id: str = Header(None)):
    require_user(x_user_id)
    return []

@router.post("/backups")
async def trigger_backup(x_user_id: str = Header(None)):
    require_user(x_user_id)
    return {"status": "started"}

@router.get("/backups/{id}")
async def get_backup(id: str, x_user_id: str = Header(None)):
    require_user(x_user_id)
    return {"id": id}

@router.post("/backups/{id}/verify")
async def verify_backup(id: str, x_user_id: str = Header(None)):
    require_user(x_user_id)
    return {"status": "verified"}

@router.post("/backups/{id}/restore")
async def restore_backup(id: str, req: RestoreRequest, x_user_id: str = Header(None)):
    require_user(x_user_id)
    if not req.confirmed:
        raise HTTPException(
            status_code=400,
            detail={"type": "about:blank", "title": "Bad Request", "status": 400, "detail": "Must confirm restore"}
        )
    return {"status": "restoring"}

@router.delete("/backups/{id}")
async def delete_backup(id: str, x_user_id: str = Header(None)):
    require_user(x_user_id)
    return {"status": "deleted"}

@router.get("/status")
async def system_status(x_user_id: str = Header(None)):
    require_user(x_user_id)
    return {
        "health": "ok",
        "disk_usage": "50%",
        "db_size": "100MB",
        "backup_status": "ok"
    }
