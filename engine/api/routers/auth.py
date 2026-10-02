from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr, validator
import hmac
import time
from typing import Dict, Any, List

router = APIRouter(tags=["auth"])

class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    confirm_password: str

    @validator('password')
    def password_complexity(cls, v: str) -> str:
        if len(v) < 12:
            raise ValueError("Password must be at least 12 characters")
        return v

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

LOGIN_ATTEMPTS: Dict[str, Dict[str, Any]] = {}

@router.post("/auth/register")
async def register(req: RegisterRequest) -> Dict[str, Any]:
    if not hmac.compare_digest(req.password.encode(), req.confirm_password.encode()):
        raise HTTPException(400, "Passwords do not match")
    return {"user_id": "uuid", "display_name": req.name, "recovery_phrase": "phrase"}

@router.post("/auth/login")
async def login(req: LoginRequest) -> Dict[str, Any]:
    email = req.email
    now = time.time()
    
    if email in LOGIN_ATTEMPTS:
        attempt_info = LOGIN_ATTEMPTS[email]
        failures = attempt_info.get("failures", 0)
        lockout_until = attempt_info.get("lockout_until", 0)
        
        if now < lockout_until:
            raise HTTPException(429, f"Account locked until {lockout_until}")
            
    success = False
    
    if not success:
        if email not in LOGIN_ATTEMPTS:
            LOGIN_ATTEMPTS[email] = {"failures": 1, "lockout_until": 0}
        else:
            LOGIN_ATTEMPTS[email]["failures"] += 1
            f = LOGIN_ATTEMPTS[email]["failures"]
            if f >= 5:
                delays = {5: 30, 6: 120, 7: 900, 8: 3600}
                delay = delays.get(f, 3600 * 24 * 365 * 100)
                LOGIN_ATTEMPTS[email]["lockout_until"] = now + delay
        raise HTTPException(401, "Invalid credentials")
        
    LOGIN_ATTEMPTS.pop(email, None)
    return {"user_id": "uuid", "display_name": "name"}

@router.post("/auth/logout")
async def logout() -> Dict[str, str]:
    return {"detail": "Logged out"}

@router.post("/auth/lock")
async def lock() -> Dict[str, str]:
    return {"detail": "Locked"}

@router.post("/auth/unlock")
async def unlock() -> Dict[str, str]:
    return {"detail": "Unlocked"}

@router.post("/auth/recover")
async def recover() -> Dict[str, str]:
    return {"detail": "Recovered"}

@router.put("/auth/password")
async def password() -> Dict[str, str]:
    return {"detail": "Password changed"}

@router.delete("/auth/account")
async def delete_account() -> Dict[str, str]:
    return {"detail": "Account deleted"}

@router.get("/auth/local-profiles")
async def local_profiles() -> List[Dict[str, str]]:
    return []
