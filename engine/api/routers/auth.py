"""Local accounts: profiles, register, sign in/out, lock/unlock, recovery, password, deletion."""

from __future__ import annotations

from typing import Annotated, Any, Literal

from fastapi import APIRouter, Depends
from pydantic import BaseModel, EmailStr, Field

from api.deps import Active, StateDep
from services.auth_service import AuthService, SignInResult

router = APIRouter(prefix="/auth", tags=["Auth"])


def get_auth(state: StateDep) -> AuthService:
    return AuthService(state)


Auth = Annotated[AuthService, Depends(get_auth)]


class RegisterIn(BaseModel):
    display_name: str = Field(min_length=1, max_length=120)
    email: EmailStr
    password: str = Field(min_length=1, max_length=256)
    confirm_password: str = Field(min_length=1, max_length=256)
    locale: Literal["fr", "en"] = "fr"
    accept_terms: bool


class LoginIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=256)


class UnlockIn(BaseModel):
    profile_id: str = Field(min_length=36, max_length=36)
    password: str = Field(min_length=1, max_length=256)


class RecoverIn(BaseModel):
    email: EmailStr
    recovery_phrase: str = Field(min_length=10, max_length=400)
    new_password: str = Field(min_length=1, max_length=256)
    confirm_password: str = Field(min_length=1, max_length=256)


class ChangePasswordIn(BaseModel):
    current_password: str = Field(min_length=1, max_length=256)
    new_password: str = Field(min_length=1, max_length=256)
    confirm_password: str = Field(min_length=1, max_length=256)


class DeleteAccountIn(BaseModel):
    password: str = Field(min_length=1, max_length=256)
    confirmation: Literal["DELETE"]


class StrengthIn(BaseModel):
    password: str = Field(max_length=256)
    hints: list[str] = Field(default_factory=list, max_length=5)


class PreferencesIn(BaseModel):
    display_name: str | None = Field(default=None, min_length=1, max_length=120)
    preferred_locale: Literal["fr", "en"] | None = None
    theme: Literal["light", "dark", "system"] | None = None
    auto_lock_minutes: int | None = Field(default=None, ge=1, le=240)


def _signed_in(result: SignInResult) -> dict[str, Any]:
    body: dict[str, Any] = {"session_token": result.session_token, "user": result.user}
    if result.recovery_phrase is not None:
        body["recovery_phrase"] = result.recovery_phrase
    return body


@router.get("/profiles")
def list_profiles(auth: Auth) -> dict[str, Any]:
    return {"items": auth.list_profiles()}


@router.get("/status")
def status(state: StateDep) -> dict[str, Any]:
    if state.active is not None:
        return {"state": "signed_in", "profile_id": state.active.user_id}
    if state.locked is not None:
        return {"state": "locked", "profile_id": state.locked.user_id, "reason": state.locked.reason}
    return {"state": "signed_out", "has_profiles": bool(state.registry.all())}


@router.post("/password-strength")
def password_strength(body: StrengthIn, auth: Auth) -> dict[str, Any]:
    return auth.password_strength(body.password, body.hints)


@router.post("/register", status_code=201)
def register(body: RegisterIn, auth: Auth) -> dict[str, Any]:
    return _signed_in(auth.register(
        display_name=body.display_name, email=str(body.email), password=body.password,
        confirm_password=body.confirm_password, locale=body.locale, accept_terms=body.accept_terms))


@router.post("/login")
def login(body: LoginIn, auth: Auth) -> dict[str, Any]:
    return _signed_in(auth.sign_in(email=str(body.email), password=body.password))


@router.post("/unlock")
def unlock(body: UnlockIn, auth: Auth) -> dict[str, Any]:
    return _signed_in(auth.sign_in(profile_id=body.profile_id, password=body.password))


@router.post("/recover")
def recover(body: RecoverIn, auth: Auth) -> dict[str, Any]:
    return _signed_in(auth.recover(email=str(body.email), phrase=body.recovery_phrase,
                                   new_password=body.new_password,
                                   confirm_password=body.confirm_password))


@router.post("/lock", status_code=204)
def lock(_active: Active, auth: Auth) -> None:
    auth.lock()


@router.post("/logout", status_code=204)
def logout(active: Active, auth: Auth) -> None:
    auth.sign_out(active)


@router.get("/me")
def me(active: Active, auth: Auth) -> dict[str, Any]:
    return auth.current_user(active)


@router.patch("/me")
def update_me(body: PreferencesIn, active: Active, auth: Auth) -> dict[str, Any]:
    return auth.update_preferences(active, body.model_dump(exclude_none=True))


@router.put("/password", status_code=204)
def change_password(body: ChangePasswordIn, active: Active, auth: Auth) -> None:
    auth.change_password(active, current_password=body.current_password,
                         new_password=body.new_password, confirm_password=body.confirm_password)


@router.post("/account/delete", status_code=204)
def delete_account(body: DeleteAccountIn, active: Active, auth: Auth) -> None:
    auth.delete_account(active, password=body.password)
