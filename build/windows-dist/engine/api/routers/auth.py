from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, EmailStr, field_validator
from typing import Dict, Any, List

from persistence.database import get_db_session
from sqlalchemy.ext.asyncio import AsyncSession
from services.auth_service import AuthService, AuthError
from persistence.repositories.user_repo import UserRepo

router = APIRouter(tags=["auth"])

class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    confirm_password: str

    @field_validator('password')
    def password_complexity(cls, v: str) -> str:
        if len(v) < 12:
            raise ValueError("Password must be at least 12 characters")
        return v

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

def get_auth_service(db: AsyncSession = Depends(get_db_session)) -> AuthService:
    repo = UserRepo(db)
    return AuthService(repo)

@router.post("/auth/register")
async def register(req: RegisterRequest, auth: AuthService = Depends(get_auth_service)) -> Dict[str, Any]:
    try:
        user_id, display_name, recovery_phrase = await auth.register(
            display_name=req.name,
            email=req.email,
            password=req.password,
            confirm_password=req.confirm_password,
        )
        return {"user_id": user_id, "display_name": display_name, "recovery_phrase": recovery_phrase}
    except AuthError as e:
        raise HTTPException(status_code=400, detail=e.message)

@router.post("/auth/login")
async def login(req: LoginRequest, auth: AuthService = Depends(get_auth_service)) -> Dict[str, Any]:
    try:
        user_id, display_name = await auth.login(email=req.email, password=req.password)
        # Note: session creation logic should happen here or frontend should get token
        # Since it's local first desktop app, return the id for now.
        return {"user_id": str(user_id), "display_name": display_name, "sync_mode": "local"}
    except AuthError as e:
        status_code = 429 if e.code == "AUTH_LOCKED" else 401
        raise HTTPException(status_code=status_code, detail=e.message)

class RecoverRequest(BaseModel):
    email: EmailStr
    recovery_phrase: str
    new_password: str
    confirm_new_password: str

class PasswordChangeRequest(BaseModel):
    user_id: str
    current_password: str
    new_password: str
    confirm_new_password: str

class DeleteAccountRequest(BaseModel):
    user_id: str
    password: str

from persistence.database import configure_db_key, reset_engine
from persistence.system_registry import registry

@router.post("/auth/logout")
async def logout() -> Dict[str, str]:
    configure_db_key("")
    reset_engine()
    return {"detail": "Logged out"}

@router.post("/auth/lock")
async def lock() -> Dict[str, str]:
    configure_db_key("")
    reset_engine()
    return {"detail": "Locked"}

@router.post("/auth/unlock")
async def unlock(req: LoginRequest, auth: AuthService = Depends(get_auth_service)) -> Dict[str, Any]:
    # Unlock is basically the same as login - verifies password and configures key
    try:
        user_id, display_name = await auth.login(email=req.email, password=req.password)
        return {"user_id": str(user_id), "display_name": display_name, "sync_mode": "local"}
    except AuthError as e:
        status_code = 429 if e.code == "AUTH_LOCKED" else 401
        raise HTTPException(status_code=status_code, detail=e.message)

@router.post("/auth/recover")
async def recover(req: RecoverRequest, auth: AuthService = Depends(get_auth_service)) -> Dict[str, str]:
    try:
        user_id = await auth.recover_account(
            email=req.email,
            recovery_phrase=req.recovery_phrase,
            new_password=req.new_password,
            confirm_new_password=req.confirm_new_password,
        )
        return {"detail": "Recovered", "user_id": user_id}
    except AuthError as e:
        raise HTTPException(status_code=400, detail=e.message)

@router.put("/auth/password")
async def password(req: PasswordChangeRequest, auth: AuthService = Depends(get_auth_service)) -> Dict[str, str]:
    try:
        await auth.change_password(
            user_id=req.user_id,
            current_password=req.current_password,
            new_password=req.new_password,
            confirm_new_password=req.confirm_new_password,
        )
        return {"detail": "Password changed"}
    except AuthError as e:
        status_code = 401 if e.code == "INVALID_CREDENTIALS" else 400
        raise HTTPException(status_code=status_code, detail=e.message)

@router.delete("/auth/account")
async def delete_account(req: DeleteAccountRequest, auth: AuthService = Depends(get_auth_service)) -> Dict[str, str]:
    try:
        await auth.delete_account(user_id=req.user_id, password=req.password)
        return {"detail": "Account deleted"}
    except AuthError as e:
        status_code = 401 if e.code == "INVALID_CREDENTIALS" else 400
        raise HTTPException(status_code=status_code, detail=e.message)

@router.get("/auth/local-profiles")
async def local_profiles() -> List[Dict[str, str]]:
    profiles = await registry.get_all_profiles()
    return [
        {"id": p.user_id, "display_name": p.display_name, "email": p.email, "created_at": p.created_at}
        for p in profiles
    ]
