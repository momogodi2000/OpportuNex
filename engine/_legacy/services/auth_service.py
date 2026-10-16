"""
Auth service — business logic for user authentication.
Orchestrates crypto, database, and session management.
"""

from __future__ import annotations

import secrets
from datetime import datetime, timedelta
from pathlib import Path

import structlog

from persistence.database import configure_db_key, init_db, reset_engine
from persistence.repositories.user_repo import UserRepo
from persistence.system_registry import ProfileEntry, registry
from security.crypto import (
    derive_key_from_password,
    expurgate_log,
    generate_data_key,
    generate_recovery_phrase,
    hash_password,
    unwrap_key,
    verify_password,
    verify_recovery_phrase,
    wrap_key,
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

    def __init__(self, user_repo: UserRepo) -> None:
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
        """
        if password != confirm_password:
            raise AuthError("PASSWORD_MISMATCH", "Passwords do not match")
        self._validate_password_strength(password)

        email_lower = email.strip().lower()
        
        # Check system registry first
        existing_profile = await registry.get_profile_by_email(email_lower)
        if existing_profile is not None:
            raise AuthError("EMAIL_TAKEN", "An account with this email already exists")

        password_hash = hash_password(password)
        recovery_phrase, recovery_hash = generate_recovery_phrase()

        password_salt = secrets.token_bytes(32)
        wrapping_key = derive_key_from_password(password, password_salt)
        
        # We share the same data key if the DB is already initialized by another user
        # But for now, we just generate one. Wait, if multiple profiles, we need the SAME data key.
        # But to read it, we'd need another user's password. 
        # So in local-first, the FIRST user creates the data key.
        # Subsequent users MUST be added while the DB is UNLOCKED (e.g. by an admin)
        # For this M01 implementation, we generate a new one. 
        # (A true multi-user DB requires the current data_key to wrap for the new user).
        # We assume this register is for the FIRST user or we just generate a new one if it's separate DBs.
        # We'll generate a new data key.
        data_key = generate_data_key()
        wrapped_key = wrap_key(data_key, wrapping_key)

        # Recovery wrapping
        recovery_key = derive_key_from_password(recovery_phrase, b"recovery_static_salt_v1")
        recovery_wrapped_key = wrap_key(data_key, recovery_key)

        import uuid
        user_id = str(uuid.uuid4())

        # Save to registry
        profile = ProfileEntry(
            user_id=user_id,
            email=email_lower,
            display_name=display_name.strip(),
            password_hash=password_hash,
            recovery_hash=recovery_hash,
            password_salt_hex=password_salt.hex(),
            wrapped_key_hex=wrapped_key.hex(),
            recovery_wrapped_key_hex=recovery_wrapped_key.hex(),
            created_at=datetime.utcnow().isoformat()
        )
        await registry.upsert_profile(profile)

        # Now unlock DB
        configure_db_key(data_key.hex())
        reset_engine()
        await init_db()

        # Save to DB
        db_user_id = await self._repo.create(
            display_name=display_name.strip(),
            email=email_lower,
            password_hash=password_hash,
            recovery_hash=recovery_hash
        )
        
        await registry.delete_profile(user_id)
        profile.user_id = db_user_id
        await registry.upsert_profile(profile)

        log.info("user_registered", user_id=db_user_id, email=expurgate_log(email_lower))
        return db_user_id, display_name.strip(), recovery_phrase

    async def login(
        self,
        email: str,
        password: str,
        now: datetime | None = None,
    ) -> tuple[str, str]:
        """
        Authenticate a user with email + password.
        """
        now = now or datetime.utcnow()
        email_lower = email.strip().lower()

        profile = await registry.get_profile_by_email(email_lower)
        if profile is None:
            hash_password("dummy_constant_time_check_!@#$%")
            raise AuthError("INVALID_CREDENTIALS", "Invalid email or password")

        # Lockout check via registry
        if profile.is_locked:
            if profile.lock_until is not None:
                lock_until_dt = datetime.fromisoformat(profile.lock_until)
                if now < lock_until_dt:
                    remaining = int((lock_until_dt - now).total_seconds())
                    raise AuthError("AUTH_LOCKED", f"Account is temporarily locked. Try again in {remaining} seconds.")
            profile.is_locked = False
            profile.failed_login_attempts = 0
            profile.lock_until = None
            await registry.upsert_profile(profile)

        if not verify_password(password, profile.password_hash):
            await self._handle_failed_login_registry(profile, now)
            raise AuthError("INVALID_CREDENTIALS", "Invalid email or password")

        # Success - unlock DB
        wrapping_key = derive_key_from_password(password, bytes.fromhex(profile.password_salt_hex))
        data_key = unwrap_key(bytes.fromhex(profile.wrapped_key_hex), wrapping_key)
        
        configure_db_key(data_key.hex())
        reset_engine()

        # Update DB state
        profile.is_locked = False
        profile.failed_login_attempts = 0
        profile.lock_until = None
        await registry.upsert_profile(profile)
        
        await self._repo.reset_lockout(profile.user_id)
        await self._repo.record_security_event("LOGIN_SUCCESS", profile.user_id)
        
        log.info("login_success", user_id=profile.user_id)
        return profile.user_id, profile.display_name

    async def _handle_failed_login_registry(self, profile: ProfileEntry, now: datetime) -> None:
        attempts = profile.failed_login_attempts + 1
        delay_index = min(attempts - 1, len(_LOCKOUT_DELAYS) - 1)
        delay = _LOCKOUT_DELAYS[delay_index]

        if delay is None:
            lock_until = None
            is_locked = True
        else:
            lock_until = now + timedelta(seconds=delay)
            is_locked = attempts >= 5

        profile.failed_login_attempts = attempts
        profile.is_locked = is_locked
        profile.lock_until = lock_until.isoformat() if lock_until else None
        await registry.upsert_profile(profile)
        
        log.warning("login_failed", user_id=profile.user_id, attempt=attempts, locked=is_locked)

    async def change_password(self, user_id: str, current_password: str, new_password: str, confirm_new_password: str) -> None:
        if new_password != confirm_new_password:
            raise AuthError("PASSWORD_MISMATCH", "New passwords do not match")
        self._validate_password_strength(new_password)

        profile = await registry.get_profile_by_id(user_id)
        if profile is None:
            raise AuthError("USER_NOT_FOUND", "User not found")
        if not verify_password(current_password, profile.password_hash):
            raise AuthError("INVALID_CREDENTIALS", "Current password is incorrect")

        new_hash = hash_password(new_password)
        new_salt = secrets.token_bytes(32)
        new_wrapping_key = derive_key_from_password(new_password, new_salt)

        old_salt = bytes.fromhex(profile.password_salt_hex)
        old_wrapping_key = derive_key_from_password(current_password, old_salt)
        data_key = unwrap_key(bytes.fromhex(profile.wrapped_key_hex), old_wrapping_key)
        new_wrapped = wrap_key(data_key, new_wrapping_key)

        # Update DB
        await self._repo.update_credentials(user_id, new_hash)
        
        # Update registry
        profile.password_hash = new_hash
        profile.password_salt_hex = new_salt.hex()
        profile.wrapped_key_hex = new_wrapped.hex()
        await registry.upsert_profile(profile)

        await self._repo.record_security_event("PASSWORD_CHANGED", user_id)
        log.info("password_changed", user_id=user_id)

    async def recover_account(self, email: str, recovery_phrase: str, new_password: str, confirm_new_password: str) -> str:
        if new_password != confirm_new_password:
            raise AuthError("PASSWORD_MISMATCH", "Passwords do not match")
        self._validate_password_strength(new_password)

        email_lower = email.strip().lower()
        profile = await registry.get_profile_by_email(email_lower)
        if profile is None:
            raise AuthError("USER_NOT_FOUND", "No account found with this email")

        if not verify_recovery_phrase(recovery_phrase.strip(), profile.recovery_hash):
            raise AuthError("INVALID_RECOVERY_PHRASE", "Recovery phrase is incorrect")

        new_hash = hash_password(new_password)
        new_salt = secrets.token_bytes(32)
        new_wrapping_key = derive_key_from_password(new_password, new_salt)

        recovery_key = derive_key_from_password(recovery_phrase.strip(), b"recovery_static_salt_v1")
        data_key = unwrap_key(bytes.fromhex(profile.recovery_wrapped_key_hex), recovery_key)
        new_wrapped = wrap_key(data_key, new_wrapping_key)

        # Need to unlock DB to update it!
        configure_db_key(data_key.hex())
        reset_engine()

        await self._repo.update_credentials(profile.user_id, new_hash)
        await self._repo.update_lockout_state(profile.user_id, locked=False, until=None)
        
        # Update registry
        profile.password_hash = new_hash
        profile.password_salt_hex = new_salt.hex()
        profile.wrapped_key_hex = new_wrapped.hex()
        profile.is_locked = False
        profile.failed_login_attempts = 0
        profile.lock_until = None
        await registry.upsert_profile(profile)

        await self._repo.record_security_event("ACCOUNT_RECOVERED", profile.user_id)
        return profile.user_id

    async def delete_account(self, user_id: str, password: str) -> None:
        profile = await registry.get_profile_by_id(user_id)
        if profile is None:
            raise AuthError("USER_NOT_FOUND", "User not found")
        if not verify_password(password, profile.password_hash):
            raise AuthError("INVALID_CREDENTIALS", "Incorrect password")

        await self._repo.delete_user(user_id)
        await registry.delete_profile(user_id)
        
        # Clear the key and reset engine so the database is locked out
        configure_db_key("")
        reset_engine()
        
        log.info("account_deleted", user_id=user_id)

    @staticmethod
    def _validate_password_strength(password: str) -> None:
        if len(password) < 12:
            raise AuthError("PASSWORD_TOO_SHORT", "Password must be at least 12 characters long")
        if not any(c.isupper() for c in password):
            raise AuthError("PASSWORD_NO_UPPERCASE", "Password must contain at least one uppercase letter")
        if not any(c.islower() for c in password):
            raise AuthError("PASSWORD_NO_LOWERCASE", "Password must contain at least one lowercase letter")
        if not any(c.isdigit() for c in password):
            raise AuthError("PASSWORD_NO_DIGIT", "Password must contain at least one digit")
        special = set("!@#$%^&*()_+-=[]{}|;':\",./<>?")
        if not any(c in special for c in password):
            raise AuthError("PASSWORD_NO_SPECIAL", "Password must contain at least one special character")
            
        # Compromised passwords check
        pwd_path = Path(__file__).parent.parent / "security" / "compromised_passwords.txt"
        if pwd_path.exists():
            with open(pwd_path, encoding="utf-8") as f:
                compromised = {line.strip() for line in f}
                if password in compromised:
                    raise AuthError("PASSWORD_COMPROMISED", "Password is in list of known compromised passwords")
