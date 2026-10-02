"""
Auth service — business logic for user authentication.
Orchestrates crypto, database, and session management.
"""

from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timedelta
from typing import Optional
from uuid import UUID

import structlog

from domain.entities.entities import User
from persistence.models.all_models import UserModel, UserSession, SecurityEvent
from persistence.repositories.user_repo import UserRepository
from security.crypto import (
    hash_password,
    verify_password,
    generate_recovery_phrase,
    verify_recovery_phrase,
    derive_key_from_password,
    generate_data_key,
    wrap_key,
    expurgate_log,
)

log = structlog.get_logger(__name__)

# Lockout thresholds (seconds): [1st, 2nd, 3rd, 4th, 5th+]
_LOCKOUT_DELAYS = [30, 120, 900, 3600, None]   # None = permanent until manual unlock


class AuthError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        self.message = message
        super().__init__(message)


class AuthService:
    """Handles all authentication operations."""

    def __init__(self, user_repo: UserRepository) -> None:
        self._repo = user_repo

    async def register(
        self,
        display_name: str,
        email: str,
        password: str,
        confirm_password: str,
    ) -> tuple[str, str, str]:
        """
        Register a new local user account.

        Returns:
            (user_id, display_name, recovery_phrase) — the phrase is shown ONCE
            and never stored in plain text.

        Raises:
            AuthError on validation failure.
        """
        # ── Input validation ──────────────────────────────────────────────
        if password != confirm_password:
            raise AuthError("PASSWORD_MISMATCH", "Passwords do not match")
        self._validate_password_strength(password)

        email_lower = email.strip().lower()
        existing = await self._repo.get_by_email(email_lower)
        if existing is not None:
            raise AuthError("EMAIL_TAKEN", "An account with this email already exists")

        # ── Credentials ───────────────────────────────────────────────────
        password_hash = hash_password(password)
        recovery_phrase, recovery_hash = generate_recovery_phrase()

        # ── Data key (encrypts local SQLite & vault) ──────────────────────
        password_salt = secrets.token_bytes(32)
        wrapping_key = derive_key_from_password(password, password_salt)
        data_key = generate_data_key()
        wrapped_key = wrap_key(data_key, wrapping_key)

        # ── Persist user ──────────────────────────────────────────────────
        user_id = await self._repo.create(
            display_name=display_name.strip(),
            email=email_lower,
            password_hash=password_hash,
            recovery_hash=recovery_hash,
            password_salt_hex=password_salt.hex(),
            wrapped_key_hex=wrapped_key.hex(),
        )

        log.info(
            "user_registered",
            user_id=user_id,
            email=expurgate_log(email_lower),
        )

        return user_id, display_name.strip(), recovery_phrase

    async def login(
        self,
        email: str,
        password: str,
        now: Optional[datetime] = None,
    ) -> tuple[str, str]:
        """
        Authenticate a user with email + password.

        Returns:
            (user_id, display_name)

        Raises:
            AuthError on failure (invalid credentials or locked account).
        """
        now = now or datetime.utcnow()
        email_lower = email.strip().lower()

        user_model = await self._repo.get_by_email(email_lower)
        if user_model is None:
            # Constant-time: still verify a dummy hash to prevent timing attacks
            hash_password("dummy_constant_time_check_!@#$%")
            raise AuthError("INVALID_CREDENTIALS", "Invalid email or password")

        # ── Lockout check ────────────────────────────────────────────────
        if user_model.is_locked:
            if user_model.lock_until is not None and now < user_model.lock_until:
                remaining = int((user_model.lock_until - now).total_seconds())
                raise AuthError(
                    "AUTH_LOCKED",
                    f"Account is temporarily locked. Try again in {remaining} seconds.",
                )
            # Lock expired — reset
            await self._repo.reset_lockout(user_model.id)
            user_model = await self._repo.get_by_id(UUID(user_model.id))

        # ── Password verification ─────────────────────────────────────────
        if not verify_password(password, user_model.password_hash):
            await self._handle_failed_login(user_model, now)
            raise AuthError("INVALID_CREDENTIALS", "Invalid email or password")

        # ── Success — reset failures ──────────────────────────────────────
        await self._repo.reset_lockout(user_model.id)

        await self._repo.record_security_event(
            event_type="LOGIN_SUCCESS",
            user_id=user_model.id,
        )
        log.info("login_success", user_id=user_model.id)

        return user_model.id, user_model.display_name

    async def _handle_failed_login(
        self, user_model: UserModel, now: datetime
    ) -> None:
        """Increment failure counter and apply progressive lockout."""
        attempts = user_model.failed_login_attempts + 1
        delay_index = min(attempts - 1, len(_LOCKOUT_DELAYS) - 1)
        delay = _LOCKOUT_DELAYS[delay_index]

        if delay is None:
            # Permanent lockout
            lock_until = None
            is_locked = True
        else:
            lock_until = now + timedelta(seconds=delay)
            is_locked = attempts >= 5

        await self._repo.update_login_failure(
            user_id=user_model.id,
            failed_attempts=attempts,
            is_locked=is_locked,
            lock_until=lock_until,
        )
        await self._repo.record_security_event(
            event_type="LOGIN_FAILED",
            user_id=user_model.id,
            details={"attempt": attempts, "lock_until": str(lock_until)},
        )
        log.warning(
            "login_failed",
            user_id=user_model.id,
            attempt=attempts,
            locked=is_locked,
        )

    async def change_password(
        self,
        user_id: str,
        current_password: str,
        new_password: str,
        confirm_new_password: str,
    ) -> None:
        """Change password and re-wrap the data key."""
        if new_password != confirm_new_password:
            raise AuthError("PASSWORD_MISMATCH", "New passwords do not match")
        self._validate_password_strength(new_password)

        user_model = await self._repo.get_by_id(UUID(user_id))
        if user_model is None:
            raise AuthError("USER_NOT_FOUND", "User not found")
        if not verify_password(current_password, user_model.password_hash):
            raise AuthError("INVALID_CREDENTIALS", "Current password is incorrect")

        new_hash = hash_password(new_password)
        new_salt = secrets.token_bytes(32)
        new_wrapping_key = derive_key_from_password(new_password, new_salt)

        # Re-wrap the existing data key with the new wrapping key
        old_salt = bytes.fromhex(user_model.password_salt_hex)
        old_wrapping_key = derive_key_from_password(current_password, old_salt)
        from security.crypto import unwrap_key, wrap_key
        data_key = unwrap_key(bytes.fromhex(user_model.wrapped_key_hex), old_wrapping_key)
        new_wrapped = wrap_key(data_key, new_wrapping_key)

        await self._repo.update_credentials(
            user_id=user_id,
            password_hash=new_hash,
            password_salt_hex=new_salt.hex(),
            wrapped_key_hex=new_wrapped.hex(),
        )
        await self._repo.record_security_event("PASSWORD_CHANGED", user_id=user_id)
        log.info("password_changed", user_id=user_id)

    async def recover_account(
        self,
        email: str,
        recovery_phrase: str,
        new_password: str,
        confirm_new_password: str,
    ) -> str:
        """Reset password using the 12-word recovery phrase."""
        if new_password != confirm_new_password:
            raise AuthError("PASSWORD_MISMATCH", "Passwords do not match")
        self._validate_password_strength(new_password)

        email_lower = email.strip().lower()
        user_model = await self._repo.get_by_email(email_lower)
        if user_model is None:
            raise AuthError("USER_NOT_FOUND", "No account found with this email")

        if not verify_recovery_phrase(recovery_phrase.strip(), user_model.recovery_hash):
            raise AuthError("INVALID_RECOVERY_PHRASE", "Recovery phrase is incorrect")

        new_hash = hash_password(new_password)
        new_salt = secrets.token_bytes(32)
        new_wrapping_key = derive_key_from_password(new_password, new_salt)

        # Re-wrap data key using the recovery key
        from security.crypto import unwrap_key, wrap_key, derive_key_from_password
        recovery_key = derive_key_from_password(recovery_phrase.strip(), b"recovery_static_salt_v1")
        data_key = unwrap_key(bytes.fromhex(user_model.recovery_wrapped_key_hex), recovery_key)
        new_wrapped = wrap_key(data_key, new_wrapping_key)

        await self._repo.update_credentials(
            user_id=user_model.id,
            password_hash=new_hash,
            password_salt_hex=new_salt.hex(),
            wrapped_key_hex=new_wrapped.hex(),
        )
        await self._repo.update_lockout_state(user_model.id, locked=False, until=None)
        await self._repo.record_security_event("ACCOUNT_RECOVERED", user_id=user_model.id)
        log.info("account_recovered", user_id=user_model.id)

        return user_model.id

    async def delete_account(self, user_id: str, password: str) -> None:
        """Permanently delete a user account and all associated data."""
        user_model = await self._repo.get_by_id(UUID(user_id))
        if user_model is None:
            raise AuthError("USER_NOT_FOUND", "User not found")
        if not verify_password(password, user_model.password_hash):
            raise AuthError("INVALID_CREDENTIALS", "Incorrect password")

        await self._repo.delete_user(user_id)
        log.info("account_deleted", user_id=user_id)

    @staticmethod
    def _validate_password_strength(password: str) -> None:
        """
        Enforce strong password policy:
        - At least 12 characters
        - At least one uppercase letter
        - At least one lowercase letter
        - At least one digit
        - At least one special character
        """
        if len(password) < 12:
            raise AuthError(
                "PASSWORD_TOO_SHORT",
                "Password must be at least 12 characters long",
            )
        if not any(c.isupper() for c in password):
            raise AuthError(
                "PASSWORD_NO_UPPERCASE",
                "Password must contain at least one uppercase letter",
            )
        if not any(c.islower() for c in password):
            raise AuthError(
                "PASSWORD_NO_LOWERCASE",
                "Password must contain at least one lowercase letter",
            )
        if not any(c.isdigit() for c in password):
            raise AuthError(
                "PASSWORD_NO_DIGIT",
                "Password must contain at least one digit",
            )
        special = set("!@#$%^&*()_+-=[]{}|;':\",./<>?")
        if not any(c in special for c in password):
            raise AuthError(
                "PASSWORD_NO_SPECIAL",
                "Password must contain at least one special character",
            )
