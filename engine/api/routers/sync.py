"""Online account, devices, sync rounds, conflicts and organisations (EF-01.09/10, M17)."""

from __future__ import annotations

from typing import Any, Literal

from fastapi import APIRouter
from pydantic import BaseModel, EmailStr, Field, SecretStr

from api.deps import Active, StateDep
from sync.service import SyncService

router = APIRouter(tags=["Sync"])

Role = Literal["owner", "admin", "editor", "viewer"]


class ServerIn(BaseModel):
    server_url: str = Field(min_length=8, max_length=300)


class RegisterIn(ServerIn):
    email: EmailStr
    password: SecretStr


class VerifyIn(ServerIn):
    code: str = Field(min_length=10, max_length=200)


class EmailIn(ServerIn):
    email: EmailStr


class ResetIn(ServerIn):
    code: str = Field(min_length=10, max_length=200)
    password: SecretStr


class LinkIn(ServerIn):
    email: EmailStr
    password: SecretStr
    totp: str | None = Field(default=None, max_length=10)
    device_name: str | None = Field(default=None, max_length=120)


class CodeIn(BaseModel):
    code: str = Field(min_length=6, max_length=20)


class PasswordIn(BaseModel):
    password: SecretStr


class ResolveIn(BaseModel):
    choice: Literal["local", "remote"]


class OrgIn(BaseModel):
    name: str = Field(min_length=1, max_length=160)
    org_type: Literal["association", "ngo", "sme", "startup", "cooperative", "public", "academic", "other"] = (
        "association"
    )
    country_code: str | None = Field(default=None, pattern=r"^[A-Z]{2}$")
    sector: str | None = Field(default=None, max_length=120)
    description: str | None = Field(default=None, max_length=2000)


class InviteIn(BaseModel):
    email: EmailStr | None = None
    role: Literal["admin", "editor", "viewer"] = "editor"


class JoinIn(BaseModel):
    token: str = Field(min_length=10, max_length=200)


class RoleIn(BaseModel):
    role: Role


class ShareIn(BaseModel):
    kind: Literal["workspace", "saved"]
    id: str
    organization_id: str | None = None


# ------------------------------------------------------------------ account
@router.get("/sync/status")
def status(active: Active, state: StateDep) -> dict[str, Any]:
    return SyncService(active, state).status()


@router.post("/sync/account/register", status_code=201)
async def register(body: RegisterIn, active: Active, state: StateDep) -> dict[str, Any]:
    return await SyncService(active, state).register(body.server_url, body.email, body.password.get_secret_value())


@router.post("/sync/account/verify")
async def verify(body: VerifyIn, active: Active, state: StateDep) -> dict[str, Any]:
    return await SyncService(active, state).verify(body.server_url, body.code)


@router.post("/sync/account/verification", status_code=202)
async def resend(body: EmailIn, active: Active, state: StateDep) -> dict[str, str]:
    await SyncService(active, state).resend(body.server_url, body.email)
    return {"status": "accepted"}


@router.post("/sync/account/password-reset/request", status_code=202)
async def reset_request(body: EmailIn, active: Active, state: StateDep) -> dict[str, str]:
    await SyncService(active, state).reset_request(body.server_url, body.email)
    return {"status": "accepted"}


@router.post("/sync/account/password-reset")
async def reset(body: ResetIn, active: Active, state: StateDep) -> dict[str, str]:
    await SyncService(active, state).reset(body.server_url, body.code, body.password.get_secret_value())
    return {"status": "reset"}


@router.post("/sync/account/link")
async def link(body: LinkIn, active: Active, state: StateDep) -> dict[str, Any]:
    return await SyncService(active, state).link(
        body.server_url, body.email, body.password.get_secret_value(), body.totp, body.device_name
    )


@router.post("/sync/account/unlink")
async def unlink(active: Active, state: StateDep) -> dict[str, Any]:
    return await SyncService(active, state).unlink()


@router.get("/sync/account")
async def account(active: Active, state: StateDep) -> dict[str, Any]:
    return await SyncService(active, state).account()


@router.post("/sync/account/totp/setup")
async def totp_setup(active: Active, state: StateDep) -> dict[str, Any]:
    return await SyncService(active, state).totp("setup")


@router.post("/sync/account/totp/{action}")
async def totp_toggle(
    action: Literal["enable", "disable"], body: CodeIn, active: Active, state: StateDep
) -> dict[str, Any]:
    return await SyncService(active, state).totp(action, body.code)


@router.post("/sync/account/delete")
async def delete_remote(body: PasswordIn, active: Active, state: StateDep) -> dict[str, Any]:
    return await SyncService(active, state).delete_remote(body.password.get_secret_value())


# ------------------------------------------------------------------ devices and rounds
@router.get("/sync/devices")
async def devices(active: Active, state: StateDep) -> dict[str, Any]:
    return {"items": await SyncService(active, state).devices()}


@router.post("/sync/devices/{device_id}/approve")
async def approve(device_id: str, body: CodeIn, active: Active, state: StateDep) -> dict[str, Any]:
    return await SyncService(active, state).approve(device_id, body.code)


@router.post("/sync/devices/{device_id}/revoke", status_code=204)
async def revoke(device_id: str, active: Active, state: StateDep) -> None:
    await SyncService(active, state).revoke(device_id)


@router.post("/sync/run")
async def run(active: Active, state: StateDep) -> dict[str, Any]:
    return await SyncService(active, state).run()


@router.get("/sync/conflicts")
def conflicts(active: Active, state: StateDep) -> dict[str, Any]:
    return {"items": SyncService(active, state).conflicts()}


@router.post("/sync/conflicts/{conflict_id}/resolve")
def resolve(conflict_id: int, body: ResolveIn, active: Active, state: StateDep) -> dict[str, Any]:
    return SyncService(active, state).resolve(conflict_id, body.choice)


# ------------------------------------------------------------------ organisations
@router.get("/orgs")
async def orgs(active: Active, state: StateDep) -> dict[str, Any]:
    return {"items": await SyncService(active, state).orgs()}


@router.post("/orgs", status_code=201)
async def create_org(body: OrgIn, active: Active, state: StateDep) -> dict[str, Any]:
    return await SyncService(active, state).create_org(body.model_dump())


@router.post("/orgs/join")
async def join(body: JoinIn, active: Active, state: StateDep) -> dict[str, Any]:
    return await SyncService(active, state).join(body.token)


@router.post("/orgs/{org_id}/invites", status_code=201)
async def invite(org_id: str, body: InviteIn, active: Active, state: StateDep) -> dict[str, Any]:
    return await SyncService(active, state).invite(org_id, body.email, body.role)


@router.get("/orgs/{org_id}/members")
async def members(org_id: str, active: Active, state: StateDep) -> dict[str, Any]:
    return await SyncService(active, state).members(org_id)


@router.patch("/orgs/{org_id}/members/{account_id}")
async def set_role(org_id: str, account_id: str, body: RoleIn, active: Active, state: StateDep) -> dict[str, Any]:
    return await SyncService(active, state).set_role(org_id, account_id, body.role)


@router.delete("/orgs/{org_id}/members/{account_id}", status_code=204)
async def remove_member(org_id: str, account_id: str, active: Active, state: StateDep) -> None:
    await SyncService(active, state).remove_member(org_id, account_id)


@router.post("/orgs/{org_id}/leave")
async def leave(org_id: str, active: Active, state: StateDep) -> dict[str, Any]:
    return await SyncService(active, state).leave(org_id)


@router.get("/orgs/{org_id}/audit")
async def audit(org_id: str, active: Active, state: StateDep) -> dict[str, Any]:
    return {"items": await SyncService(active, state).audit(org_id)}


@router.post("/orgs/share")
def share(body: ShareIn, active: Active, state: StateDep) -> dict[str, Any]:
    return SyncService(active, state).share(body.kind, body.id, body.organization_id)
