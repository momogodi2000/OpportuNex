"""Local accounts (module M01): register, sign in, lock/unlock, recover, change password,
delete account. Implements arch §9.1 key management and EF-01.01..08, .11, .12.
"""

from __future__ import annotations

import secrets
import shutil
import time
from dataclasses import dataclass
from datetime import timedelta
from typing import Any

import structlog
from sqlalchemy import insert, select, update

from collection.catalog import sync_catalog
from core.errors import AppError, Conflict, Locked, NotFound, Unauthorized, ValidationFailed
from core.ids import uuid7
from core.timeutil import iso, now_iso, parse_iso, utcnow
from persistence.database import ProfileDatabase, WrongKeyError
from persistence.registry import ProfileRecord, email_digest
from security import passwords, recovery
from security.crypto import (
    KdfParams,
    UnwrapError,
    b64d,
    b64e,
    derive_kek,
    hash_secret,
    new_data_key,
    new_salt,
    unwrap_key,
    verify_secret,
    wrap_key,
)
from security.vault import Vault
from services.backup_service import snapshot_db_file
from services.state import ActiveProfile, EngineState, token_hash

log = structlog.get_logger(__name__)

LOCKOUT_THRESHOLD = 5
LOCKOUT_MAX_MINUTES = 60
SUPPORTED_LOCALES = ("fr", "en")


@dataclass
class SignInResult:
    session_token: str
    user: dict[str, Any]
    recovery_phrase: str | None = None


def _aad(profile_id: str, purpose: str) -> bytes:
    return f"opportunex:{profile_id}:{purpose}".encode()


def lockout_minutes(failed_count: int) -> int:
    """Progressive back-off (EF-01.05): 5th failure → 1 min, then doubling, capped at 60."""
    if failed_count < LOCKOUT_THRESHOLD:
        return 0
    return min(2 ** (failed_count - LOCKOUT_THRESHOLD), LOCKOUT_MAX_MINUTES)


class AuthService:
    def __init__(self, state: EngineState) -> None:
        self.state = state
        self._dummy_hash: str | None = None

    @property
    def kdf(self) -> KdfParams:
        return self.state.kdf

    def _params_of(self, record: ProfileRecord) -> KdfParams:
        return KdfParams(memory_kib=record.kdf_memory_kib, iterations=record.kdf_iterations)

    # ---------------------------------------------------------------- queries
    def list_profiles(self) -> list[dict[str, object]]:
        return [p.public() for p in self.state.registry.all()]

    def password_strength(self, password: str, hints: list[str]) -> dict[str, Any]:
        a = passwords.assess(password, hints)
        return {"score": a.score, "acceptable": a.acceptable, "problems": a.problems, "suggestions": a.suggestions}

    # --------------------------------------------------------------- register
    def register(
        self, *, display_name: str, email: str, password: str, confirm_password: str, locale: str, accept_terms: bool
    ) -> SignInResult:
        display_name = display_name.strip()
        email = email.strip()
        if not display_name:
            raise ValidationFailed("display name required", code="display_name_required")
        if not accept_terms:
            raise ValidationFailed("terms must be accepted", code="terms_not_accepted")
        if password != confirm_password:
            raise ValidationFailed("passwords differ", code="password_mismatch")
        if locale not in SUPPORTED_LOCALES:
            raise ValidationFailed("unsupported locale", code="locale_unsupported")
        assessment = passwords.assess(password, [display_name, email])
        if not assessment.acceptable:
            raise ValidationFailed("password rejected", code="password_policy", extra={"problems": assessment.problems})
        registry = self.state.registry
        if registry.find_by_email(email) is not None:
            raise Conflict("an account already uses this e-mail", code="email_taken")

        profile_id = uuid7()
        data_key = new_data_key()
        pw_salt, rec_salt = new_salt(), new_salt()
        phrase = recovery.generate_phrase(locale)
        norm_phrase = recovery.normalize_phrase(phrase)
        record = ProfileRecord(
            id=profile_id,
            display_name=display_name,
            email_sha256=email_digest(email),
            locale=locale,
            created_at=now_iso(),
            auth_hash=hash_secret(password, self.kdf),
            pw_salt=b64e(pw_salt),
            pw_wrapped_key=b64e(wrap_key(data_key, derive_kek(password, pw_salt, self.kdf), _aad(profile_id, "pw"))),
            recovery_hash=hash_secret(norm_phrase, self.kdf),
            rec_salt=b64e(rec_salt),
            rec_wrapped_key=b64e(
                wrap_key(data_key, derive_kek(norm_phrase, rec_salt, self.kdf), _aad(profile_id, "rec"))
            ),
            kdf_memory_kib=self.kdf.memory_kib,
            kdf_iterations=self.kdf.iterations,
        )
        paths = self.state.paths
        db = ProfileDatabase(paths.profile_db(profile_id), data_key, echo=self.state.settings.sql_echo)
        try:
            T = db.tables
            with db.tx() as conn:
                conn.execute(
                    insert(T.users).values(
                        id=profile_id,
                        email=email,
                        display_name=display_name,
                        password_hash=record.auth_hash,
                        recovery_key_hash=record.recovery_hash,
                        wrapped_db_key=b64d(record.pw_wrapped_key),
                        account_mode="local",
                        preferred_locale=locale,
                        theme="system",
                        password_changed_at=now_iso(),
                    )
                )
                conn.execute(insert(T.user_profiles).values(user_id=profile_id, full_name=display_name))
                conn.execute(insert(T.matching_weights).values(user_id=profile_id))
                for purpose in ("terms", "privacy_policy"):
                    conn.execute(
                        insert(T.consents).values(
                            id=uuid7(), user_id=profile_id, purpose=purpose, policy_version="1.0", granted=1
                        )
                    )
                conn.execute(
                    insert(T.audit_logs).values(
                        user_id=profile_id, action="account.create", entity_table="users", entity_id=profile_id
                    )
                )
            registry.add(record)
        except BaseException:
            db.close()
            shutil.rmtree(paths.profile_dir(profile_id), ignore_errors=True)
            raise
        result = self._activate(record, db, bytearray(data_key))
        result.recovery_phrase = phrase
        log.info("account_registered")
        return result

    # ----------------------------------------------------------------- sign in
    def _dummy_verify(self, password: str) -> None:
        if self._dummy_hash is None:
            self._dummy_hash = hash_secret(secrets.token_hex(16), self.kdf)
        verify_secret(password, self._dummy_hash, self.kdf)

    def _check_lockout(self, record: ProfileRecord) -> None:
        until = parse_iso(record.locked_until)
        if until and until > utcnow():
            retry = int((until - utcnow()).total_seconds()) + 1
            raise Locked("too many failed attempts", extra={"retry_after_seconds": retry})

    def _register_failure(self, record: ProfileRecord, reason: str) -> None:
        record.failed_count += 1
        minutes = lockout_minutes(record.failed_count)
        record.locked_until = iso(utcnow() + timedelta(minutes=minutes)) if minutes else None
        attempt: dict[str, object] = {"succeeded": 0, "reason": reason, "attempted_at": now_iso()}
        record.pending_attempts = [*record.pending_attempts, attempt][-50:]
        self.state.registry.update(record)
        if minutes:
            raise Locked("too many failed attempts", extra={"retry_after_seconds": minutes * 60})

    def sign_in(self, *, email: str | None = None, profile_id: str | None = None, password: str) -> SignInResult:
        registry = self.state.registry
        record = registry.get(profile_id) if profile_id else registry.find_by_email(email or "")
        if record is None:
            self._dummy_verify(password)
            raise Unauthorized("invalid credentials", code="invalid_credentials")
        self._check_lockout(record)
        params = self._params_of(record)
        if not verify_secret(password, record.auth_hash, params):
            self._register_failure(record, "bad_password")
            raise Unauthorized("invalid credentials", code="invalid_credentials")
        try:
            kek = derive_kek(password, b64d(record.pw_salt), params)
            data_key = unwrap_key(b64d(record.pw_wrapped_key), kek, _aad(record.id, "pw"))
        except UnwrapError as exc:
            raise AppError("profile key cannot be unwrapped", code="profile_corrupted", status=500) from exc
        db = self._open_db(record, data_key)
        return self._activate(record, db, bytearray(data_key))

    def _open_db(self, record: ProfileRecord, data_key: bytes) -> ProfileDatabase:
        paths = self.state.paths
        db_path = paths.profile_db(record.id)
        if not db_path.is_file():
            raise NotFound("profile database missing", code="profile_db_missing")

        def pre_migration(current: str, head: str) -> None:
            target = paths.profile_backups(record.id) / f"pre-migration-{current}-to-{head}.db"
            snapshot_db_file(db_path, target, data_key)
            log.info("pre_migration_snapshot", from_revision=current, to_revision=head)

        try:
            return ProfileDatabase(db_path, data_key, echo=self.state.settings.sql_echo, before_migrate=pre_migration)
        except WrongKeyError as exc:
            raise AppError("profile database cannot be decrypted", code="profile_corrupted", status=500) from exc

    def _activate(self, record: ProfileRecord, db: ProfileDatabase, data_key: bytearray) -> SignInResult:
        token = secrets.token_urlsafe(32)
        ttl_hours = self.state.settings.session_ttl_hours
        session_id = uuid7()
        T = db.tables
        now = now_iso()
        with db.tx() as conn:
            sync_catalog(conn, T)
            for attempt in record.pending_attempts:
                conn.execute(insert(T.login_attempts).values(email=record.email_sha256[:12], **attempt))
            conn.execute(insert(T.login_attempts).values(email=record.email_sha256[:12], succeeded=1))
            conn.execute(
                insert(T.user_sessions).values(
                    id=session_id,
                    user_id=record.id,
                    token_hash=token_hash(token),
                    device_name="desktop",
                    expires_at=iso(utcnow() + timedelta(hours=ttl_hours)),
                )
            )
            conn.execute(
                update(T.users)
                .where(T.users.c.id == record.id)
                .values(last_login_at=now, failed_login_count=0, locked_until=None)
            )
            user = conn.execute(select(T.users).where(T.users.c.id == record.id)).mappings().one()
        record.failed_count = 0
        record.locked_until = None
        record.pending_attempts = []
        record.last_login_at = now
        self.state.registry.update(record)
        active = ActiveProfile(
            user_id=record.id,
            db=db,
            vault=Vault(self.state.paths.profile_vault(record.id), bytes(data_key)),
            data_key=data_key,
            session_hash=token_hash(token),
            session_id=session_id,
            session_expires=time.time() + ttl_hours * 3600,
            auto_lock_minutes=int(user["auto_lock_minutes"]),
        )
        self.state.set_active(active)
        self.state.events.publish("auth.signed_in", {"profile_id": record.id})
        return SignInResult(session_token=token, user=present_user(dict(user)))

    # ----------------------------------------------------- lock / sign out
    def lock(self) -> None:
        user_id = self.state.close_active(reason="manual")
        if user_id:
            self.state.events.publish("auth.locked", {"profile_id": user_id, "reason": "manual"})

    def sign_out(self, active: ActiveProfile) -> None:
        T = active.tables
        with active.db.tx() as conn:
            conn.execute(
                update(T.user_sessions).where(T.user_sessions.c.id == active.session_id).values(revoked_at=now_iso())
            )
        self.state.close_active(reason="signed_out", remember_lock=False)

    # --------------------------------------------------------------- recovery
    def recover(self, *, email: str, phrase: str, new_password: str, confirm_password: str) -> SignInResult:
        record = self.state.registry.find_by_email(email)
        if record is None or not recovery.is_well_formed(phrase):
            raise Unauthorized("invalid recovery phrase", code="invalid_recovery")
        self._check_lockout(record)
        if new_password != confirm_password:
            raise ValidationFailed("passwords differ", code="password_mismatch")
        assessment = passwords.assess(new_password, [record.display_name, email])
        if not assessment.acceptable:
            raise ValidationFailed("password rejected", code="password_policy", extra={"problems": assessment.problems})
        params = self._params_of(record)
        norm = recovery.normalize_phrase(phrase)
        if not verify_secret(norm, record.recovery_hash, params):
            self._register_failure(record, "bad_recovery_phrase")
            raise Unauthorized("invalid recovery phrase", code="invalid_recovery")
        kek = derive_kek(norm, b64d(record.rec_salt), params)
        try:
            data_key = unwrap_key(b64d(record.rec_wrapped_key), kek, _aad(record.id, "rec"))
        except UnwrapError as exc:
            raise AppError("profile key cannot be unwrapped", code="profile_corrupted", status=500) from exc
        self._rewrap_password(record, data_key, new_password)
        db = self._open_db(record, data_key)
        self._sync_user_hash(db, record)
        with db.tx() as conn:
            conn.execute(
                insert(db.tables.audit_logs).values(
                    user_id=record.id, action="account.recover", entity_table="users", entity_id=record.id
                )
            )
        return self._activate(record, db, bytearray(data_key))

    def _rewrap_password(self, record: ProfileRecord, data_key: bytes, new_password: str) -> None:
        salt = new_salt()
        record.pw_salt = b64e(salt)
        record.pw_wrapped_key = b64e(
            wrap_key(data_key, derive_kek(new_password, salt, self.kdf), _aad(record.id, "pw"))
        )
        record.auth_hash = hash_secret(new_password, self.kdf)
        record.kdf_memory_kib = self.kdf.memory_kib
        record.kdf_iterations = self.kdf.iterations
        # The recovery wrap keeps its own salt/params; re-derive with stored params on use.
        self.state.registry.update(record)

    def _sync_user_hash(self, db: ProfileDatabase, record: ProfileRecord) -> None:
        T = db.tables
        with db.tx() as conn:
            conn.execute(
                update(T.users)
                .where(T.users.c.id == record.id)
                .values(
                    password_hash=record.auth_hash,
                    wrapped_db_key=b64d(record.pw_wrapped_key),
                    password_changed_at=now_iso(),
                )
            )

    # --------------------------------------------------------- change password
    def change_password(
        self, active: ActiveProfile, *, current_password: str, new_password: str, confirm_password: str
    ) -> None:
        record = self.state.registry.get(active.user_id)
        if record is None:
            raise NotFound("profile not found", code="profile_not_found")
        if not verify_secret(current_password, record.auth_hash, self._params_of(record)):
            raise Unauthorized("current password is wrong", code="invalid_credentials")
        if new_password != confirm_password:
            raise ValidationFailed("passwords differ", code="password_mismatch")
        if new_password == current_password:
            raise ValidationFailed("new password must differ", code="password_unchanged")
        assessment = passwords.assess(new_password, [record.display_name])
        if not assessment.acceptable:
            raise ValidationFailed("password rejected", code="password_policy", extra={"problems": assessment.problems})
        self._rewrap_password(record, active.key_bytes, new_password)
        self._sync_user_hash(active.db, record)
        with active.db.tx() as conn:
            conn.execute(
                insert(active.tables.audit_logs).values(
                    user_id=record.id, action="account.password_change", entity_table="users", entity_id=record.id
                )
            )

    # ---------------------------------------------------------------- delete
    def delete_account(self, active: ActiveProfile, *, password: str) -> None:
        record = self.state.registry.get(active.user_id)
        if record is None:
            raise NotFound("profile not found", code="profile_not_found")
        if not verify_secret(password, record.auth_hash, self._params_of(record)):
            raise Unauthorized("password is wrong", code="invalid_credentials")
        user_id = active.user_id
        self.state.close_active(reason="deleted", remember_lock=False)
        paths = self.state.paths
        shutil.rmtree(paths.profile_dir(user_id), ignore_errors=True)
        shutil.rmtree(paths.profile_backups(user_id), ignore_errors=True)
        self.state.registry.remove(user_id)
        self.state.events.publish("auth.account_deleted", {"profile_id": user_id})
        log.info("account_deleted")

    # ------------------------------------------------------------ preferences
    def update_preferences(self, active: ActiveProfile, changes: dict[str, Any]) -> dict[str, Any]:
        allowed = {"display_name", "preferred_locale", "theme", "auto_lock_minutes"}
        values = {k: v for k, v in changes.items() if k in allowed and v is not None}
        T = active.tables
        with active.db.tx() as conn:
            if values:
                conn.execute(update(T.users).where(T.users.c.id == active.user_id).values(**values))
            user = conn.execute(select(T.users).where(T.users.c.id == active.user_id)).mappings().one()
        if "auto_lock_minutes" in values:
            active.auto_lock_minutes = int(values["auto_lock_minutes"])
        record = self.state.registry.get(active.user_id)
        if record is not None and ("display_name" in values or "preferred_locale" in values):
            record.display_name = str(user["display_name"])
            record.locale = str(user["preferred_locale"])
            self.state.registry.update(record)
        return present_user(dict(user))

    def current_user(self, active: ActiveProfile) -> dict[str, Any]:
        T = active.tables
        with active.db.read() as conn:
            user = conn.execute(select(T.users).where(T.users.c.id == active.user_id)).mappings().one()
        return present_user(dict(user))


def present_user(row: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": row["id"],
        "email": row["email"],
        "display_name": row["display_name"],
        "account_mode": row["account_mode"],
        "preferred_locale": row["preferred_locale"],
        "theme": row["theme"],
        "auto_lock_minutes": row["auto_lock_minutes"],
        "onboarding_completed": bool(row["onboarding_completed"]),
        "totp_enabled": bool(row["totp_enabled"]),
        "last_login_at": row["last_login_at"],
        "created_at": row["created_at"],
    }
