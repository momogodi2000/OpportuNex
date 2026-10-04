from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/privacy", tags=["Privacy"])

def require_user(x_user_id: Optional[str] = Header(None)) -> str:
    if not x_user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"type": "about:blank", "title": "Unauthorized", "status": 401, "detail": "Missing X-User-Id"}
        )
    return x_user_id

class PurgeRequest(BaseModel):
    start_date: str
    end_date: str

class AccountDeleteRequest(BaseModel):
    password: str

class ConsentRequest(BaseModel):
    granted: bool

@router.get("/audit-log")
async def get_audit_log(x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"items": []}

@router.get("/data-export")
async def data_export(x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"status": "export_started"}

@router.post("/purge")
async def purge_data(req: PurgeRequest, x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"status": "purged"}

@router.get("/consents")
async def list_consents(x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"consents": []}

@router.post("/consents/{purpose}")
async def update_consent(purpose: str, req: ConsentRequest, x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"status": "updated", "purpose": purpose, "granted": req.granted}

@router.delete("/account")
async def delete_account(req: AccountDeleteRequest, x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    if not req.password:
        raise HTTPException(
            status_code=400,
            detail={"type": "about:blank", "title": "Bad Request", "status": 400, "detail": "Password required"}
        )
    return {"status": "deleted"}
