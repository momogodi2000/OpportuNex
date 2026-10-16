"""HTTP API of the sync server (arch §10.3).

The server never sees business data: it stores account metadata, device public keys, sealed key
envelopes and ciphertext records with their size, scope and order. Errors are RFC 9457 problems
with a stable ``code``, like the local engine.
"""

import base64
import logging
import time
import uuid
from collections import defaultdict, deque
from collections.abc import Iterator
from contextlib import contextmanager
from datetime import timedelta
from typing import Annotated, Any, Literal

from fastapi import Depends, FastAPI, Header, Request
from fastapi.responses import HTMLResponse, JSONResponse, PlainTextResponse
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import Connection, delete, func, insert, select, update

from opx_sync import VERSION
from opx_sync.config import Settings
from opx_sync.db import (
    accounts,
    changes,
    devices,
    email_tokens,
    make_engine,
    org_audit,
    org_invites,
    org_keys,
    org_members,
    orgs,
    sessions,
)
from opx_sync.mail import Mailer
from opx_sync.security import (
    Passwords,
    iso,
    lockout_until,
    new_token,
    now,
    parse,
    token_hash,
    totp_secret,
    totp_uri,
    totp_verify,
)

log = logging.getLogger("opx_sync")

ROLES = ("owner", "admin", "editor", "viewer")
WRITERS = {"owner", "admin", "editor"}
MANAGERS = {"owner", "admin"}
B64KEY = r"^[A-Za-z0-9+/=_-]{40,64}$"


class Problem(Exception):
    def __init__(self, status: int, code: str, detail: str = "", **extra: Any) -> None:
        super().__init__(code)
        self.status, self.code, self.detail, self.extra = status, code, detail or code, extra


# ---------------------------------------------------------------------- bodies
class DeviceIn(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    platform: Literal["windows", "linux", "macos"]
    public_key: str = Field(pattern=B64KEY)


class RegisterIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=12, max_length=256)


class TokenIn(BaseModel):
    token: str = Field(min_length=10, max_length=200)


class EmailIn(BaseModel):
    email: EmailStr


class LoginIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=256)
    totp: str | None = Field(default=None, max_length=10)
    device: DeviceIn


class ResetIn(BaseModel):
    token: str = Field(min_length=10, max_length=200)
    password: str = Field(min_length=12, max_length=256)


class CodeIn(BaseModel):
    code: str = Field(min_length=6, max_length=10)


class PasswordIn(BaseModel):
    password: str = Field(min_length=1, max_length=256)


class IdentityIn(BaseModel):
    public_key: str = Field(pattern=B64KEY)
    private_sealed: str = Field(min_length=40, max_length=400)


class EnvelopeIn(BaseModel):
    envelope: str = Field(min_length=40, max_length=400)


class RecordIn(BaseModel):
    op_id: str = Field(min_length=8, max_length=36)
    key_version: int = Field(ge=1)
    nonce: str = Field(min_length=24, max_length=48)
    ciphertext: str = Field(min_length=4)


class PushIn(BaseModel):
    scope: str = Field(max_length=48)
    items: list[RecordIn] = Field(max_length=1000)


class InviteIn(BaseModel):
    email: EmailStr | None = None
    role: Literal["admin", "editor", "viewer"] = "editor"


class RoleIn(BaseModel):
    role: Literal["owner", "admin", "editor", "viewer"]


class KeysIn(BaseModel):
    key_version: int = Field(ge=1)
    envelopes: dict[str, str] = Field(max_length=500)


def create_app(settings: Settings | None = None) -> FastAPI:
    s = settings or Settings()
    engine = make_engine(s.database_url)
    pw = Passwords(s.argon2_memory_kib, s.argon2_iterations)
    mailer = Mailer(s)
    app = FastAPI(title="Opportunex sync server", version=VERSION, docs_url=None, redoc_url=None)
    app.state.mailer = mailer
    app.state.engine = engine
    metrics: dict[str, int] = defaultdict(int)
    hits: dict[str, deque[float]] = defaultdict(deque)

    @contextmanager
    def tx() -> Iterator[Connection]:
        with engine.begin() as conn:
            yield conn

    @app.exception_handler(Problem)
    async def _problem(_req: Request, exc: Problem) -> JSONResponse:
        metrics[f"errors_{exc.status}"] += 1
        return JSONResponse(
            {"type": f"https://opportunex.app/problems/{exc.code}", "title": exc.code, "status": exc.status,
             "code": exc.code, "detail": exc.detail, **exc.extra},
            status_code=exc.status,
            media_type="application/problem+json",
        )  # fmt: skip

    def limit(key: str, per_minute: int) -> None:
        """Small in-memory limiter for authentication endpoints."""
        q, t = hits[key], time.monotonic()
        while q and t - q[0] > 60:
            q.popleft()
        if len(q) >= per_minute:
            raise Problem(429, "rate_limited", "too many attempts, retry later")
        q.append(t)

    # ---------------------------------------------------------------- auth
    class Ctx(BaseModel):
        account_id: str
        device_id: str
        device_status: str
        email: str

    def ctx(authorization: Annotated[str | None, Header()] = None) -> Ctx:
        if not authorization or not authorization.startswith("Bearer "):
            raise Problem(401, "not_authenticated")
        with tx() as conn:
            row = (
                conn.execute(
                    select(sessions, devices.c.status, accounts.c.email)
                    .join(devices, devices.c.id == sessions.c.device_id)
                    .join(accounts, accounts.c.id == sessions.c.account_id)
                    .where(sessions.c.token_hash == token_hash(authorization[7:]))
                )
                .mappings()
                .first()
            )
            if row is None or parse(row["expires_at"]) < now() or row["status"] == "revoked":
                raise Problem(401, "invalid_session")
            conn.execute(update(devices).where(devices.c.id == row["device_id"]).values(last_seen_at=iso(now())))
        return Ctx(
            account_id=row["account_id"], device_id=row["device_id"], device_status=row["status"], email=row["email"]
        )

    Auth = Annotated[Ctx, Depends(ctx)]  # noqa: N806 - type alias used in signatures

    def active(c: Ctx) -> Ctx:
        if c.device_status != "active":
            raise Problem(403, "device_not_paired", "approve this device from a paired device first")
        return c

    def send_token(conn: Connection, account_id: str, email: str, purpose: str) -> None:
        token = new_token()
        conn.execute(
            insert(email_tokens).values(
                token_hash=token_hash(token), account_id=account_id, purpose=purpose,
                expires_at=iso(now() + timedelta(hours=24 if purpose == "verify" else 1)),
            )
        )  # fmt: skip
        if purpose == "verify":
            mailer.send(
                email,
                "Opportunex — confirmez votre adresse / confirm your address",
                f"Code : {token}\n\nOu ouvrez / or open: {s.public_url}/v1/accounts/verify?token={token}\n",
            )
        else:
            mailer.send(
                email,
                "Opportunex — réinitialisation du mot de passe / password reset",
                f"Code : {token}\n\nCollez ce code dans Opportunex. Vos données restent chiffrées : seul un appareil "
                f"déjà couplé peut les lire.\nPaste this code in Opportunex. Your data stays encrypted: only a "
                f"paired device can read it.\n",
            )

    def use_token(conn: Connection, token: str, purpose: str) -> str:
        row = (
            conn.execute(
                select(email_tokens).where(
                    email_tokens.c.token_hash == token_hash(token), email_tokens.c.purpose == purpose
                )
            )
            .mappings()
            .first()
        )
        if row is None or row["used_at"] or parse(row["expires_at"]) < now():
            raise Problem(400, "token_invalid", "the code is invalid or expired")
        conn.execute(
            update(email_tokens).where(email_tokens.c.token_hash == row["token_hash"]).values(used_at=iso(now()))
        )
        return str(row["account_id"])

    # ------------------------------------------------------------- routes
    @app.get("/v1/health")
    def health() -> dict[str, Any]:
        with tx() as conn:
            conn.execute(select(1))
        return {"status": "ok", "version": VERSION}

    @app.get("/metrics", response_class=PlainTextResponse)
    def prometheus() -> str:
        with tx() as conn:
            n_accounts = conn.execute(select(func.count()).select_from(accounts)).scalar()
            n_changes = conn.execute(select(func.count()).select_from(changes)).scalar()
            n_bytes = conn.execute(select(func.coalesce(func.sum(changes.c.size), 0))).scalar()
        lines = [
            f"opx_sync_accounts {n_accounts}",
            f"opx_sync_records {n_changes}",
            f"opx_sync_record_bytes {n_bytes}",
            *[f'opx_sync_events_total{{kind="{k}"}} {v}' for k, v in sorted(metrics.items())],
        ]
        return "\n".join(lines) + "\n"

    @app.post("/v1/accounts", status_code=201)
    def register(body: RegisterIn, request: Request) -> dict[str, Any]:
        if not s.allow_registration:
            raise Problem(403, "registration_closed")
        limit(f"register:{request.client.host if request.client else '-'}", 10)
        email = body.email.lower()
        with tx() as conn:
            if conn.execute(select(accounts.c.id).where(accounts.c.email == email)).first():
                raise Problem(409, "email_taken")
            aid = str(uuid.uuid4())
            conn.execute(
                insert(accounts).values(
                    id=aid, email=email, email_verified=False, password_hash=pw.hash(body.password),
                    totp_enabled=False, bytes_used=0, failed_logins=0, created_at=iso(now()),
                )
            )  # fmt: skip
            send_token(conn, aid, email, "verify")
        metrics["accounts_created"] += 1
        return {"id": aid, "email": email, "verification": "sent"}

    def _verify(token: str) -> None:
        with tx() as conn:
            aid = use_token(conn, token, "verify")
            conn.execute(update(accounts).where(accounts.c.id == aid).values(email_verified=True))

    @app.post("/v1/accounts/verify")
    def verify(body: TokenIn) -> dict[str, str]:
        _verify(body.token)
        return {"status": "verified"}

    @app.get("/v1/accounts/verify", response_class=HTMLResponse)
    def verify_link(token: str) -> str:
        try:
            _verify(token)
            msg = "Adresse confirmée. Vous pouvez revenir dans Opportunex. / Address confirmed."
        except Problem:
            msg = "Lien invalide ou expiré. / Invalid or expired link."
        return f"<!doctype html><meta charset=utf-8><title>Opportunex</title><p>{msg}</p>"

    @app.post("/v1/accounts/verification", status_code=202)
    def resend(body: EmailIn, request: Request) -> dict[str, str]:
        limit(f"resend:{body.email.lower()}", 3)
        with tx() as conn:
            row = conn.execute(select(accounts).where(accounts.c.email == body.email.lower())).mappings().first()
            if row is not None and not row["email_verified"]:
                send_token(conn, row["id"], row["email"], "verify")
        return {"status": "accepted"}  # same answer whether or not the account exists

    @app.post("/v1/password-reset/request", status_code=202)
    def reset_request(body: EmailIn) -> dict[str, str]:
        limit(f"reset:{body.email.lower()}", 3)
        with tx() as conn:
            row = conn.execute(select(accounts).where(accounts.c.email == body.email.lower())).mappings().first()
            if row is not None:
                send_token(conn, row["id"], row["email"], "reset")
        return {"status": "accepted"}

    @app.post("/v1/password-reset")
    def reset(body: ResetIn) -> dict[str, str]:
        with tx() as conn:
            aid = use_token(conn, body.token, "reset")
            conn.execute(
                update(accounts)
                .where(accounts.c.id == aid)
                .values(password_hash=pw.hash(body.password), failed_logins=0, locked_until=None)
            )
            conn.execute(delete(sessions).where(sessions.c.account_id == aid))
        return {"status": "reset"}

    @app.post("/v1/sessions", status_code=201)
    def login(body: LoginIn, request: Request) -> dict[str, Any]:
        limit(f"login:{request.client.host if request.client else '-'}", 30)
        email = body.email.lower()
        with tx() as conn:
            acc = conn.execute(select(accounts).where(accounts.c.email == email)).mappings().first()
            if acc is None:
                pw.verify(pw.hash("x" * 12), body.password)  # same cost as a real check
                raise Problem(401, "invalid_credentials")
            if acc["locked_until"] and parse(acc["locked_until"]) > now():
                raise Problem(423, "account_locked", locked_until=acc["locked_until"])
            wrong = not pw.verify(acc["password_hash"], body.password)
        if wrong:
            # Recorded in its own committed transaction: raising inside one would roll the count back.
            failures = acc["failed_logins"] + 1
            until = lockout_until(failures)
            with tx() as conn:
                conn.execute(
                    update(accounts)
                    .where(accounts.c.id == acc["id"])
                    .values(failed_logins=failures, locked_until=iso(until) if until else None)
                )
            metrics["login_failed"] += 1
            raise Problem(401, "invalid_credentials")
        with tx() as conn:
            if not acc["email_verified"]:
                raise Problem(403, "email_not_verified")
            if acc["totp_enabled"]:
                if not body.totp:
                    raise Problem(401, "totp_required")
                if not totp_verify(acc["totp_secret"], body.totp):
                    raise Problem(401, "totp_invalid")
            conn.execute(update(accounts).where(accounts.c.id == acc["id"]).values(failed_logins=0, locked_until=None))
            existing = (
                conn.execute(
                    select(devices).where(
                        devices.c.account_id == acc["id"], devices.c.public_key == body.device.public_key
                    )
                )
                .mappings()
                .first()
            )
            if existing is not None and existing["status"] != "revoked":
                device_id, status = existing["id"], existing["status"]
            else:
                has_active = conn.execute(
                    select(devices.c.id).where(devices.c.account_id == acc["id"], devices.c.status == "active")
                ).first()
                device_id = str(uuid.uuid4())
                # The first device creates the sync key; later ones wait for pairing (D-30).
                status = "pending" if has_active else "active"
                conn.execute(
                    insert(devices).values(
                        id=device_id, account_id=acc["id"], name=body.device.name, platform=body.device.platform,
                        public_key=body.device.public_key, status=status, created_at=iso(now()),
                    )
                )  # fmt: skip
            token = new_token()
            conn.execute(
                insert(sessions).values(
                    token_hash=token_hash(token), account_id=acc["id"], device_id=device_id,
                    expires_at=iso(now() + timedelta(days=s.session_days)),
                )
            )  # fmt: skip
        metrics["login_ok"] += 1
        return {"token": token, "account_id": acc["id"], "device_id": device_id, "device_status": status}

    @app.delete("/v1/sessions", status_code=204)
    def logout(c: Auth, authorization: Annotated[str, Header()]) -> None:
        with tx() as conn:
            conn.execute(delete(sessions).where(sessions.c.token_hash == token_hash(authorization[7:])))

    # ------------------------------------------------------------- account
    @app.get("/v1/account")
    def account(c: Auth) -> dict[str, Any]:
        with tx() as conn:
            a = conn.execute(select(accounts).where(accounts.c.id == c.account_id)).mappings().one()
        return {
            "id": a["id"], "email": a["email"], "totp_enabled": a["totp_enabled"],
            "identity_public_key": a["identity_public_key"], "identity_private_sealed": a["identity_private_sealed"],
            "bytes_used": a["bytes_used"], "quota_bytes": s.quota_mb * 1024 * 1024,
            "device_id": c.device_id, "device_status": c.device_status,
        }  # fmt: skip

    @app.put("/v1/account/identity")
    def set_identity(body: IdentityIn, c: Auth) -> dict[str, str]:
        active(c)
        with tx() as conn:
            current = conn.execute(select(accounts.c.identity_public_key).where(accounts.c.id == c.account_id)).scalar()
            if current and current != body.public_key:
                raise Problem(409, "identity_exists")
            conn.execute(
                update(accounts)
                .where(accounts.c.id == c.account_id)
                .values(identity_public_key=body.public_key, identity_private_sealed=body.private_sealed)
            )
        return {"status": "ok"}

    @app.post("/v1/account/totp/setup")
    def totp_setup(c: Auth) -> dict[str, str]:
        secret = totp_secret()
        with tx() as conn:
            enabled = conn.execute(select(accounts.c.totp_enabled).where(accounts.c.id == c.account_id)).scalar()
            if enabled:
                raise Problem(409, "totp_already_enabled")
            conn.execute(update(accounts).where(accounts.c.id == c.account_id).values(totp_secret=secret))
        return {"secret": secret, "uri": totp_uri(secret, c.email)}

    @app.post("/v1/account/totp/enable")
    def totp_enable(body: CodeIn, c: Auth) -> dict[str, bool]:
        with tx() as conn:
            secret = conn.execute(select(accounts.c.totp_secret).where(accounts.c.id == c.account_id)).scalar()
            if not secret or not totp_verify(secret, body.code):
                raise Problem(400, "totp_invalid")
            conn.execute(update(accounts).where(accounts.c.id == c.account_id).values(totp_enabled=True))
        return {"totp_enabled": True}

    @app.post("/v1/account/totp/disable")
    def totp_disable(body: CodeIn, c: Auth) -> dict[str, bool]:
        with tx() as conn:
            secret = conn.execute(select(accounts.c.totp_secret).where(accounts.c.id == c.account_id)).scalar()
            if not secret or not totp_verify(secret, body.code):
                raise Problem(400, "totp_invalid")
            conn.execute(
                update(accounts).where(accounts.c.id == c.account_id).values(totp_enabled=False, totp_secret=None)
            )
        return {"totp_enabled": False}

    @app.post("/v1/account/delete", status_code=204)
    def delete_account(body: PasswordIn, c: Auth) -> None:
        """EF-01.11 (remote part): every record, device and membership of the account is erased."""
        with tx() as conn:
            a = conn.execute(select(accounts).where(accounts.c.id == c.account_id)).mappings().one()
            if not pw.verify(a["password_hash"], body.password):
                raise Problem(401, "invalid_credentials")
            owned = [
                r[0]
                for r in conn.execute(
                    select(org_members.c.org_id).where(
                        org_members.c.account_id == c.account_id, org_members.c.role == "owner"
                    )
                )
            ]
            for org_id in owned:
                others = conn.execute(
                    select(func.count()).where(
                        org_members.c.org_id == org_id,
                        org_members.c.role == "owner",
                        org_members.c.account_id != c.account_id,
                    )
                ).scalar()
                if not others:
                    raise Problem(
                        409, "last_owner", "transfer ownership or delete the organisation first", org_id=org_id
                    )
            conn.execute(delete(changes).where(changes.c.scope == f"user:{c.account_id}"))
            for org_id in [
                r[0] for r in conn.execute(select(org_members.c.org_id).where(org_members.c.account_id == c.account_id))
            ]:
                conn.execute(update(orgs).where(orgs.c.id == org_id).values(rotation_needed=True))
                audit(conn, org_id, c.account_id, "member.account_deleted", None)
            conn.execute(delete(accounts).where(accounts.c.id == c.account_id))

    # ------------------------------------------------------------- devices
    @app.get("/v1/devices")
    def list_devices(c: Auth) -> dict[str, Any]:
        with tx() as conn:
            rows = conn.execute(
                select(devices.c.id, devices.c.name, devices.c.platform, devices.c.public_key, devices.c.status,
                       devices.c.created_at, devices.c.last_seen_at)
                .where(devices.c.account_id == c.account_id)
                .order_by(devices.c.created_at)
            ).mappings()  # fmt: skip
            return {"items": [dict(r) | {"current": r["id"] == c.device_id} for r in rows]}

    @app.post("/v1/devices/{device_id}/approve")
    def approve(device_id: str, body: EnvelopeIn, c: Auth) -> dict[str, str]:
        active(c)
        with tx() as conn:
            r = conn.execute(
                update(devices)
                .where(devices.c.id == device_id, devices.c.account_id == c.account_id, devices.c.status == "pending")
                .values(status="active", envelope=body.envelope)
            )
            if r.rowcount == 0:
                raise Problem(404, "device_not_pending")
        return {"status": "active"}

    @app.post("/v1/devices/{device_id}/revoke")
    def revoke(device_id: str, c: Auth) -> dict[str, str]:
        active(c)
        with tx() as conn:
            r = conn.execute(
                update(devices)
                .where(devices.c.id == device_id, devices.c.account_id == c.account_id)
                .values(status="revoked", envelope=None)
            )
            if r.rowcount == 0:
                raise Problem(404, "device_not_found")
            conn.execute(delete(sessions).where(sessions.c.device_id == device_id))
        return {"status": "revoked"}

    @app.get("/v1/devices/me/envelope")
    def my_envelope(c: Auth) -> dict[str, Any]:
        with tx() as conn:
            env = conn.execute(select(devices.c.envelope).where(devices.c.id == c.device_id)).scalar()
        return {"status": c.device_status, "envelope": env}

    # ---------------------------------------------------------------- sync
    def scope_role(conn: Connection, c: Ctx, scope: str) -> str:
        if scope == "user":
            return "owner"
        if scope.startswith("org:"):
            role = conn.execute(
                select(org_members.c.role).where(
                    org_members.c.org_id == scope[4:], org_members.c.account_id == c.account_id
                )
            ).scalar()
            if role is None:
                raise Problem(403, "not_a_member")
            return str(role)
        raise Problem(422, "scope_invalid")

    def scope_key(c: Ctx, scope: str) -> str:
        return f"user:{c.account_id}" if scope == "user" else scope

    @app.post("/v1/sync/push")
    def push(body: PushIn, c: Auth) -> dict[str, Any]:
        active(c)
        if len(body.items) > s.max_batch:
            raise Problem(413, "batch_too_large", max_batch=s.max_batch)
        with tx() as conn:
            role = scope_role(conn, c, body.scope)
            if role not in WRITERS:
                raise Problem(403, "read_only_role", role=role)
            key = scope_key(c, body.scope)
            used = conn.execute(select(accounts.c.bytes_used).where(accounts.c.id == c.account_id)).scalar() or 0
            accepted = duplicates = 0
            added = 0
            for it in body.items:
                try:
                    blob = base64.b64decode(it.ciphertext, validate=True)
                except ValueError as exc:
                    raise Problem(422, "ciphertext_invalid") from exc
                if len(blob) > s.max_record_kb * 1024:
                    raise Problem(413, "record_too_large", max_kb=s.max_record_kb)
                if conn.execute(
                    select(changes.c.seq).where(changes.c.scope == key, changes.c.op_id == it.op_id)
                ).first():
                    duplicates += 1  # replay after a network failure (EF-17.06)
                    continue
                if used + added + len(blob) > s.quota_mb * 1024 * 1024:
                    raise Problem(507, "quota_exceeded", quota_mb=s.quota_mb)
                conn.execute(
                    insert(changes).values(
                        scope=key, op_id=it.op_id, device_id=c.device_id, key_version=it.key_version,
                        nonce=it.nonce, ciphertext=blob, size=len(blob), created_at=iso(now()),
                    )
                )  # fmt: skip
                added += len(blob)
                accepted += 1
            conn.execute(update(accounts).where(accounts.c.id == c.account_id).values(bytes_used=used + added))
            cursor = conn.execute(select(func.max(changes.c.seq)).where(changes.c.scope == key)).scalar() or 0
        metrics["records_pushed"] += accepted
        return {"accepted": accepted, "duplicates": duplicates, "cursor": cursor}

    @app.get("/v1/sync/pull")
    def pull(c: Auth, scope: str = "user", after: int = 0, limit: int = 500) -> dict[str, Any]:
        active(c)
        limit = max(1, min(limit, s.max_batch))
        with tx() as conn:
            scope_role(conn, c, scope)
            rows = (
                conn.execute(
                    select(changes)
                    .where(changes.c.scope == scope_key(c, scope), changes.c.seq > after)
                    .order_by(changes.c.seq)
                    .limit(limit + 1)
                )
                .mappings()
                .all()
            )
        items = [
            {"seq": r["seq"], "op_id": r["op_id"], "device_id": r["device_id"], "key_version": r["key_version"],
             "nonce": r["nonce"], "ciphertext": base64.b64encode(r["ciphertext"]).decode()}
            for r in rows[:limit]
        ]  # fmt: skip
        return {"items": items, "cursor": items[-1]["seq"] if items else after, "has_more": len(rows) > limit}

    # ---------------------------------------------------------------- orgs
    def audit(conn: Connection, org_id: str, account_id: str | None, action: str, target: str | None) -> None:
        conn.execute(
            insert(org_audit).values(
                org_id=org_id, account_id=account_id, action=action, target=target, created_at=iso(now())
            )
        )

    def require_role(conn: Connection, org_id: str, c: Ctx, allowed: set[str]) -> str:
        role = conn.execute(
            select(org_members.c.role).where(org_members.c.org_id == org_id, org_members.c.account_id == c.account_id)
        ).scalar()
        if role is None:
            raise Problem(404, "org_not_found")
        if role not in allowed:
            raise Problem(403, "role_forbidden", role=role)
        return str(role)

    @app.post("/v1/orgs", status_code=201)
    def create_org(c: Auth) -> dict[str, Any]:
        active(c)
        oid = str(uuid.uuid4())
        with tx() as conn:
            conn.execute(
                insert(orgs).values(
                    id=oid, created_by=c.account_id, key_version=1, rotation_needed=False, created_at=iso(now())
                )
            )
            conn.execute(
                insert(org_members).values(org_id=oid, account_id=c.account_id, role="owner", joined_at=iso(now()))
            )
            audit(conn, oid, c.account_id, "org.create", None)
        return {"id": oid, "key_version": 1, "role": "owner"}

    @app.get("/v1/orgs")
    def my_orgs(c: Auth) -> dict[str, Any]:
        with tx() as conn:
            rows = (
                conn.execute(
                    select(orgs, org_members.c.role)
                    .join(org_members, org_members.c.org_id == orgs.c.id)
                    .where(org_members.c.account_id == c.account_id)
                )
                .mappings()
                .all()
            )
            out = []
            for r in rows:
                keys = {
                    k["key_version"]: k["envelope"]
                    for k in conn.execute(
                        select(org_keys).where(org_keys.c.org_id == r["id"], org_keys.c.account_id == c.account_id)
                    ).mappings()
                }
                out.append(
                    {
                        "id": r["id"],
                        "role": r["role"],
                        "key_version": r["key_version"],
                        "rotation_needed": r["rotation_needed"],
                        "envelopes": {str(k): v for k, v in keys.items()},
                    }
                )
        return {"items": out}

    @app.get("/v1/orgs/{org_id}/members")
    def members(org_id: str, c: Auth) -> dict[str, Any]:
        with tx() as conn:
            require_role(conn, org_id, c, set(ROLES))
            version = conn.execute(select(orgs.c.key_version).where(orgs.c.id == org_id)).scalar()
            rows = conn.execute(
                select(org_members.c.account_id, org_members.c.role, org_members.c.joined_at, accounts.c.email,
                       accounts.c.identity_public_key)
                .join(accounts, accounts.c.id == org_members.c.account_id)
                .where(org_members.c.org_id == org_id)
                .order_by(org_members.c.joined_at)
            ).mappings().all()  # fmt: skip
            with_key = {
                r[0]
                for r in conn.execute(
                    select(org_keys.c.account_id).where(org_keys.c.org_id == org_id, org_keys.c.key_version == version)
                )
            }
        return {"key_version": version,
                "items": [dict(r) | {"has_current_key": r["account_id"] in with_key} for r in rows]}  # fmt: skip

    @app.put("/v1/orgs/{org_id}/keys")
    def put_keys(org_id: str, body: KeysIn, c: Auth) -> dict[str, Any]:
        """Hand the organisation key to members, or rotate it after a departure (key_version + 1)."""
        active(c)
        with tx() as conn:
            require_role(conn, org_id, c, MANAGERS)
            o = conn.execute(select(orgs).where(orgs.c.id == org_id)).mappings().one()
            if body.key_version not in (o["key_version"], o["key_version"] + 1):
                raise Problem(409, "key_version_conflict", key_version=o["key_version"])
            member_ids = {
                r[0] for r in conn.execute(select(org_members.c.account_id).where(org_members.c.org_id == org_id))
            }
            unknown = set(body.envelopes) - member_ids
            if unknown:
                raise Problem(422, "not_members", accounts=sorted(unknown))
            if body.key_version == o["key_version"] + 1 and set(body.envelopes) != member_ids:
                raise Problem(422, "rotation_incomplete", "a new key version must reach every member")
            for aid, env in body.envelopes.items():
                conn.execute(
                    delete(org_keys).where(
                        org_keys.c.org_id == org_id,
                        org_keys.c.account_id == aid,
                        org_keys.c.key_version == body.key_version,
                    )
                )
                conn.execute(
                    insert(org_keys).values(org_id=org_id, account_id=aid, key_version=body.key_version, envelope=env)
                )
            if body.key_version == o["key_version"] + 1:
                conn.execute(
                    update(orgs).where(orgs.c.id == org_id).values(key_version=body.key_version, rotation_needed=False)
                )
                audit(conn, org_id, c.account_id, "key.rotate", str(body.key_version))
            else:
                audit(conn, org_id, c.account_id, "key.share", ",".join(sorted(body.envelopes)))
        return {"key_version": body.key_version}

    @app.post("/v1/orgs/{org_id}/invites", status_code=201)
    def invite(org_id: str, body: InviteIn, c: Auth) -> dict[str, Any]:
        token = new_token()
        iid = str(uuid.uuid4())
        expires = iso(now() + timedelta(days=7))
        with tx() as conn:
            require_role(conn, org_id, c, MANAGERS)
            conn.execute(
                insert(org_invites).values(
                    id=iid, org_id=org_id, email=body.email.lower() if body.email else None, role=body.role,
                    token_hash=token_hash(token), created_by=c.account_id, expires_at=expires,
                )
            )  # fmt: skip
            audit(conn, org_id, c.account_id, "invite.create", body.email.lower() if body.email else "link")
        if body.email:
            mailer.send(
                body.email,
                "Opportunex — invitation",
                f"{c.email} vous invite dans une organisation Opportunex / invites you to an Opportunex organisation.\n"
                f"Code : {token}\nServeur / server: {s.public_url}\n",
            )
        return {"id": iid, "token": token, "expires_at": expires, "role": body.role}

    @app.get("/v1/orgs/{org_id}/invites")
    def invites(org_id: str, c: Auth) -> dict[str, Any]:
        with tx() as conn:
            require_role(conn, org_id, c, MANAGERS)
            rows = conn.execute(
                select(org_invites.c.id, org_invites.c.email, org_invites.c.role, org_invites.c.expires_at,
                       org_invites.c.accepted_at, org_invites.c.revoked_at)
                .where(org_invites.c.org_id == org_id)
            ).mappings()  # fmt: skip
            return {"items": [dict(r) for r in rows]}

    @app.delete("/v1/orgs/{org_id}/invites/{invite_id}", status_code=204)
    def revoke_invite(org_id: str, invite_id: str, c: Auth) -> None:
        with tx() as conn:
            require_role(conn, org_id, c, MANAGERS)
            conn.execute(
                update(org_invites)
                .where(org_invites.c.id == invite_id, org_invites.c.org_id == org_id)
                .values(revoked_at=iso(now()))
            )
            audit(conn, org_id, c.account_id, "invite.revoke", invite_id)

    @app.post("/v1/invites/accept")
    def accept(body: TokenIn, c: Auth) -> dict[str, Any]:
        active(c)
        with tx() as conn:
            inv = (
                conn.execute(select(org_invites).where(org_invites.c.token_hash == token_hash(body.token)))
                .mappings()
                .first()
            )
            if inv is None or inv["revoked_at"] or inv["accepted_at"] or parse(inv["expires_at"]) < now():
                raise Problem(400, "invite_invalid")
            if inv["email"] and inv["email"] != c.email:
                raise Problem(403, "invite_other_email")
            exists = conn.execute(
                select(org_members.c.role).where(
                    org_members.c.org_id == inv["org_id"], org_members.c.account_id == c.account_id
                )
            ).first()
            if exists is None:
                conn.execute(
                    insert(org_members).values(
                        org_id=inv["org_id"], account_id=c.account_id, role=inv["role"], joined_at=iso(now())
                    )
                )
            conn.execute(
                update(org_invites)
                .where(org_invites.c.id == inv["id"])
                .values(accepted_by=c.account_id, accepted_at=iso(now()))
            )
            audit(conn, inv["org_id"], c.account_id, "member.join", c.email)
        return {"org_id": inv["org_id"], "role": inv["role"]}

    @app.patch("/v1/orgs/{org_id}/members/{account_id}")
    def set_role(org_id: str, account_id: str, body: RoleIn, c: Auth) -> dict[str, str]:
        with tx() as conn:
            mine = require_role(conn, org_id, c, MANAGERS)
            target = conn.execute(
                select(org_members.c.role).where(org_members.c.org_id == org_id, org_members.c.account_id == account_id)
            ).scalar()
            if target is None:
                raise Problem(404, "member_not_found")
            if mine != "owner" and ("owner" in (target, body.role)):
                raise Problem(403, "owner_only")
            if target == "owner" and body.role != "owner" and _owners(conn, org_id) <= 1:
                raise Problem(409, "last_owner")
            conn.execute(
                update(org_members)
                .where(org_members.c.org_id == org_id, org_members.c.account_id == account_id)
                .values(role=body.role)
            )
            audit(conn, org_id, c.account_id, "member.role", f"{account_id}:{body.role}")
        return {"role": body.role}

    def _owners(conn: Connection, org_id: str) -> int:
        return int(
            conn.execute(
                select(func.count()).where(org_members.c.org_id == org_id, org_members.c.role == "owner")
            ).scalar()
            or 0
        )

    @app.delete("/v1/orgs/{org_id}/members/{account_id}", status_code=204)
    def remove_member(org_id: str, account_id: str, c: Auth) -> None:
        """Removal by a manager, or leaving (self). The key must then be rotated (D-33)."""
        with tx() as conn:
            if account_id == c.account_id:
                role = require_role(conn, org_id, c, set(ROLES))
                if role == "owner" and _owners(conn, org_id) <= 1:
                    raise Problem(409, "last_owner", "transfer ownership before leaving")
                action = "member.leave"
            else:
                mine = require_role(conn, org_id, c, MANAGERS)
                target = conn.execute(
                    select(org_members.c.role).where(
                        org_members.c.org_id == org_id, org_members.c.account_id == account_id
                    )
                ).scalar()
                if target is None:
                    raise Problem(404, "member_not_found")
                if target == "owner" and mine != "owner":
                    raise Problem(403, "owner_only")
                action = "member.remove"
            conn.execute(
                delete(org_members).where(org_members.c.org_id == org_id, org_members.c.account_id == account_id)
            )
            conn.execute(delete(org_keys).where(org_keys.c.org_id == org_id, org_keys.c.account_id == account_id))
            conn.execute(update(orgs).where(orgs.c.id == org_id).values(rotation_needed=True))
            audit(conn, org_id, c.account_id, action, account_id)

    @app.delete("/v1/orgs/{org_id}", status_code=204)
    def delete_org(org_id: str, c: Auth) -> None:
        with tx() as conn:
            require_role(conn, org_id, c, {"owner"})
            conn.execute(delete(changes).where(changes.c.scope == f"org:{org_id}"))
            conn.execute(delete(orgs).where(orgs.c.id == org_id))

    @app.get("/v1/orgs/{org_id}/audit")
    def org_audit_log(org_id: str, c: Auth) -> dict[str, Any]:
        """EF-17.11: who did what in the organisation (no content)."""
        with tx() as conn:
            require_role(conn, org_id, c, MANAGERS)
            rows = conn.execute(
                select(org_audit, accounts.c.email)
                .join(accounts, accounts.c.id == org_audit.c.account_id, isouter=True)
                .where(org_audit.c.org_id == org_id)
                .order_by(org_audit.c.id.desc())
                .limit(500)
            ).mappings()
            return {"items": [dict(r) for r in rows]}

    return app


def get_app() -> FastAPI:
    """ASGI entry point for uvicorn: ``uvicorn opx_sync.app:get_app --factory``."""
    return create_app()
