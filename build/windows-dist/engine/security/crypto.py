import re
import secrets
from typing import Tuple
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend

# Configure Argon2id as requested: memory=65536, iterations=3, parallelism=1
ph = PasswordHasher(
    time_cost=3,
    memory_cost=65536,
    parallelism=1,
    hash_len=32,
    salt_len=16
)

# 100-word subset of BIP39 English wordlist
WORDLIST = [
    "abandon", "ability", "able", "about", "above", "absent", "absorb", "abstract", "absurd", "abuse",
    "access", "accident", "account", "accuse", "achieve", "acid", "acoustic", "acquire", "across", "act",
    "action", "actor", "actress", "actual", "adapt", "add", "addict", "address", "adjust", "admit",
    "adult", "advance", "advice", "aerobic", "afford", "afraid", "again", "age", "agent", "agree",
    "ahead", "aim", "air", "airport", "aisle", "alarm", "album", "alcohol", "alert", "alien",
    "all", "alley", "allow", "almost", "alone", "alpha", "already", "alter", "always", "amateur",
    "amazing", "among", "amount", "amused", "analyst", "anchor", "ancient", "anger", "angle", "angry",
    "animal", "ankle", "announce", "annual", "another", "answer", "antenna", "antique", "anxiety", "any",
    "apart", "apology", "appear", "apple", "approve", "april", "arch", "arctic", "area", "arena",
    "argue", "arm", "armed", "armor", "army", "around"
]

def hash_password(password: str) -> str:
    """Hashes a password using Argon2id."""
    return ph.hash(password)

def verify_password(password: str, hash_str: str) -> bool:
    """Verifies a password against a hash. Returns True if valid, False otherwise."""
    try:
        return ph.verify(hash_str, password)
    except VerifyMismatchError:
        return False

def generate_recovery_phrase() -> Tuple[str, str]:
    """Generates a 12-word recovery phrase and its Argon2id hash."""
    words = [secrets.choice(WORDLIST) for _ in range(12)]
    phrase = " ".join(words)
    hashed_phrase = hash_password(phrase)
    return phrase, hashed_phrase

def verify_recovery_phrase(phrase: str, stored_hash: str) -> bool:
    """Verifies a recovery phrase against its stored Argon2id hash."""
    return verify_password(phrase, stored_hash)

def derive_key_from_password(password: str, salt: bytes) -> bytes:
    """Derives a 32-byte key from a password and salt using Argon2id KDF logic."""
    import argon2.low_level as al
    
    return al.hash_secret_raw(
        secret=password.encode("utf-8"),
        salt=salt,
        time_cost=3,
        memory_cost=65536,
        parallelism=1,
        hash_len=32,
        type=al.Type.ID
    )

def generate_data_key() -> bytes:
    """Generates a random 32-byte data key."""
    return secrets.token_bytes(32)

def wrap_key(key: bytes, wrapping_key: bytes) -> bytes:
    """Encrypts a key using AES-256-GCM with the provided wrapping key."""
    iv = secrets.token_bytes(12)
    cipher = Cipher(algorithms.AES(wrapping_key), modes.GCM(iv), backend=default_backend())
    encryptor = cipher.encryptor()
    ciphertext = encryptor.update(key) + encryptor.finalize()
    return iv + encryptor.tag + ciphertext

def unwrap_key(wrapped: bytes, wrapping_key: bytes) -> bytes:
    """Decrypts a key using AES-256-GCM with the provided wrapping key."""
    iv = wrapped[:12]
    tag = wrapped[12:28]
    ciphertext = wrapped[28:]
    
    cipher = Cipher(algorithms.AES(wrapping_key), modes.GCM(iv, tag), backend=default_backend())
    decryptor = cipher.decryptor()
    return decryptor.update(ciphertext) + decryptor.finalize()

def expurgate_log(text: str) -> str:
    """Removes sensitive information like emails, phone numbers, and API keys from text."""
    # Remove emails
    text = re.sub(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', '[EMAIL REDACTED]', text)
    
    # Remove phone numbers (simple pattern for international formats)
    text = re.sub(r'\+?\d{1,3}[-.\s]?\(?\d{1,4}\)?[-.\s]?\d{1,4}[-.\s]?\d{1,9}', '[PHONE REDACTED]', text)
    
    # Remove Bearer tokens
    text = re.sub(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', 'Bearer [TOKEN REDACTED]', text)
    
    # Remove API keys (sk-*, AIza*, key=*)
    text = re.sub(r'\bsk-[A-Za-z0-9_-]+\b', '[API KEY REDACTED]', text)
    text = re.sub(r'\bAIza[A-Za-z0-9_-]+\b', '[API KEY REDACTED]', text)
    text = re.sub(r'(?i)key=[A-Za-z0-9_-]+', 'key=[API KEY REDACTED]', text)
    
    return text
