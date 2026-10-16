"""Key management primitives (architecture §9.1).

* Authentication hash: Argon2id PHC string (own random salt).
* Key-encryption keys: Argon2id raw derivation with a *different* random salt.
* The 256-bit data key (SQLCipher + vault) is wrapped with AES-256-GCM, once by the
  password-derived key and once by the recovery-phrase-derived key.
"""

from __future__ import annotations

import base64
import hmac
import secrets
from dataclasses import dataclass

import argon2.low_level as argon2_ll
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError
from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

DATA_KEY_BYTES = 32
SALT_BYTES = 16
NONCE_BYTES = 12


@dataclass(frozen=True)
class KdfParams:
    memory_kib: int = 65536
    iterations: int = 3
    parallelism: int = 1

    def hasher(self) -> PasswordHasher:
        return PasswordHasher(
            time_cost=self.iterations,
            memory_cost=self.memory_kib,
            parallelism=self.parallelism,
            hash_len=32,
            salt_len=SALT_BYTES,
        )


class UnwrapError(Exception):
    """Wrong secret or tampered wrapped key."""


def b64e(data: bytes) -> str:
    return base64.b64encode(data).decode("ascii")


def b64d(text: str) -> bytes:
    return base64.b64decode(text.encode("ascii"))


def new_salt() -> bytes:
    return secrets.token_bytes(SALT_BYTES)


def new_data_key() -> bytes:
    return secrets.token_bytes(DATA_KEY_BYTES)


def hash_secret(secret: str, params: KdfParams) -> str:
    return params.hasher().hash(secret)


def verify_secret(secret: str, phc: str, params: KdfParams) -> bool:
    try:
        return params.hasher().verify(phc, secret)
    except (VerifyMismatchError, VerificationError, InvalidHashError):
        return False


def derive_kek(secret: str, salt: bytes, params: KdfParams) -> bytes:
    return argon2_ll.hash_secret_raw(
        secret=secret.encode("utf-8"),
        salt=salt,
        time_cost=params.iterations,
        memory_cost=params.memory_kib,
        parallelism=params.parallelism,
        hash_len=DATA_KEY_BYTES,
        type=argon2_ll.Type.ID,
    )


def wrap_key(data_key: bytes, kek: bytes, aad: bytes) -> bytes:
    nonce = secrets.token_bytes(NONCE_BYTES)
    return nonce + AESGCM(kek).encrypt(nonce, data_key, aad)


def unwrap_key(wrapped: bytes, kek: bytes, aad: bytes) -> bytes:
    try:
        return AESGCM(kek).decrypt(wrapped[:NONCE_BYTES], wrapped[NONCE_BYTES:], aad)
    except (InvalidTag, ValueError) as exc:
        raise UnwrapError("invalid secret or corrupted key") from exc


def encrypt_blob(data: bytes, key: bytes, aad: bytes) -> bytes:
    nonce = secrets.token_bytes(NONCE_BYTES)
    return nonce + AESGCM(key).encrypt(nonce, data, aad)


def decrypt_blob(blob: bytes, key: bytes, aad: bytes) -> bytes:
    try:
        return AESGCM(key).decrypt(blob[:NONCE_BYTES], blob[NONCE_BYTES:], aad)
    except (InvalidTag, ValueError) as exc:
        raise UnwrapError("cannot decrypt blob") from exc


def sqlcipher_key_pragma(data_key: bytes) -> str:
    """Raw-key PRAGMA so SQLCipher skips its own PBKDF2 (our key is already strong)."""
    return f"PRAGMA key = \"x'{data_key.hex()}'\""


def constant_time_equals(a: str, b: str) -> bool:
    return hmac.compare_digest(a.encode("utf-8"), b.encode("utf-8"))
