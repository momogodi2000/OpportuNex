"""Sync cryptography (D-29): XChaCha20-Poly1305 records, X25519 sealed boxes, pairing codes.

Every record is bound to its scope and operation id as associated data, so the server cannot move
a record into another scope or replay it under a different id without decryption failing.
"""

from __future__ import annotations

import base64
import hashlib
import os

from nacl import bindings
from nacl.exceptions import CryptoError
from nacl.public import PrivateKey, PublicKey, SealedBox

KEY_BYTES = 32
NONCE_BYTES = bindings.crypto_aead_xchacha20poly1305_ietf_NPUBBYTES  # 24


class DecryptError(Exception):
    """Wrong key, altered ciphertext or record moved to another scope."""


def b64(data: bytes) -> str:
    return base64.b64encode(data).decode()


def unb64(text: str) -> bytes:
    return base64.b64decode(text, validate=True)


def new_key() -> bytes:
    return os.urandom(KEY_BYTES)


def new_device_key() -> tuple[bytes, str]:
    """(private key bytes, public key base64)."""
    sk = PrivateKey.generate()
    return bytes(sk), b64(bytes(sk.public_key))


def public_of(private: bytes) -> str:
    return b64(bytes(PrivateKey(private).public_key))


def encrypt(key: bytes, plaintext: bytes, aad: str) -> tuple[str, str]:
    """(nonce b64, ciphertext b64) with a random 192-bit nonce (safe to draw at random)."""
    nonce = os.urandom(NONCE_BYTES)
    ct = bindings.crypto_aead_xchacha20poly1305_ietf_encrypt(plaintext, aad.encode(), nonce, key)
    return b64(nonce), b64(ct)


def decrypt(key: bytes, nonce_b64: str, ciphertext_b64: str, aad: str) -> bytes:
    try:
        return bytes(
            bindings.crypto_aead_xchacha20poly1305_ietf_decrypt(
                unb64(ciphertext_b64), aad.encode(), unb64(nonce_b64), key
            )
        )
    except (CryptoError, ValueError) as exc:
        raise DecryptError(type(exc).__name__) from exc


def seal(public_b64: str, secret: bytes) -> str:
    """Anonymous sealed box: only the holder of the matching private key can open it."""
    return b64(SealedBox(PublicKey(unb64(public_b64))).encrypt(secret))


def unseal(private: bytes, sealed_b64: str) -> bytes:
    try:
        return bytes(SealedBox(PrivateKey(private)).decrypt(unb64(sealed_b64)))
    except (CryptoError, ValueError) as exc:
        raise DecryptError(type(exc).__name__) from exc


def pairing_code(public_b64: str) -> str:
    """12-digit code derived from a device's public key, shown on both devices (D-30)."""
    digest = hashlib.sha256(b"opportunex-pairing-v1" + unb64(public_b64)).digest()
    number = int.from_bytes(digest[:8], "big") % 10**12
    s = f"{number:012d}"
    return " ".join(s[i : i + 4] for i in range(0, 12, 4))


def same_code(a: str, b: str) -> bool:
    return "".join(a.split()) == "".join(b.split())
