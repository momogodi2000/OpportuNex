from __future__ import annotations

from pathlib import Path

import pytest

from core.errors import NotFound, ValidationFailed
from core.ids import uuid7
from security import passwords, recovery
from security.crypto import (
    KdfParams,
    UnwrapError,
    derive_kek,
    hash_secret,
    new_data_key,
    new_salt,
    unwrap_key,
    verify_secret,
    wrap_key,
)
from security.redaction import redact
from security.vault import Vault

FAST = KdfParams(memory_kib=1024, iterations=1)


def test_wrap_unwrap_roundtrip_and_tamper_detection() -> None:
    key = new_data_key()
    kek = derive_kek("secret", new_salt(), FAST)
    wrapped = wrap_key(key, kek, b"aad")
    assert unwrap_key(wrapped, kek, b"aad") == key
    with pytest.raises(UnwrapError):
        unwrap_key(wrapped, kek, b"other-aad")
    with pytest.raises(UnwrapError):
        unwrap_key(wrapped, derive_kek("wrong", new_salt(), FAST), b"aad")
    tampered = bytearray(wrapped)
    tampered[-1] ^= 1
    with pytest.raises(UnwrapError):
        unwrap_key(bytes(tampered), kek, b"aad")


def test_hash_and_kdf_use_distinct_salts() -> None:
    phc = hash_secret("pw", FAST)
    assert phc.startswith("$argon2id$")
    assert verify_secret("pw", phc, FAST)
    assert not verify_secret("nope", phc, FAST)
    assert not verify_secret("pw", "not-a-hash", FAST)
    s1, s2 = new_salt(), new_salt()
    assert derive_kek("pw", s1, FAST) != derive_kek("pw", s2, FAST)


def test_production_kdf_defaults_match_spec() -> None:
    from core.config import Settings

    s = Settings()
    assert s.kdf_memory_kib == 65536 and s.kdf_iterations == 3


def test_recovery_phrase_is_12_bip39_words_and_normalised() -> None:
    for lang in ("fr", "en"):
        phrase = recovery.generate_phrase(lang)
        assert len(phrase.split()) == 12
        assert recovery.is_well_formed(phrase)
        assert recovery.is_well_formed("  " + phrase.upper() + "  ")
    assert recovery.normalize_phrase("Élève  ÉLÉPHANT") == "eleve elephant"
    assert not recovery.is_well_formed("abandon " * 11)
    assert not recovery.is_well_formed("zzzz " * 12)
    assert len(recovery.wordlist("fr")) == 2048 and len(recovery.wordlist("en")) == 2048


def test_password_policy_rejects_short_compromised_and_weak() -> None:
    assert "too_short" in passwords.assess("Ab1!").problems
    compromised = passwords.assess("password1234")
    assert "compromised" in compromised.problems or "too_weak" in compromised.problems
    assert not compromised.acceptable
    good = passwords.assess("Baobab-Lumiere-Kribi-2026!")
    assert good.acceptable and good.score >= 3


def test_redaction_masks_secrets_but_keeps_dates() -> None:
    text = (
        "mail awa@example.com token=abc123 Bearer abc.def sk-0123456789abcdef "
        "tel +237 6 99 88 77 66 date 2026-10-15T09:40:00Z"
    )
    out = redact(text)
    assert "awa@example.com" not in out and "[email]" in out
    assert "abc123" not in out and "sk-0123456789abcdef" not in out
    assert "699" not in out.replace(" ", "")
    assert "2026-10-15T09:40:00Z" in out


def test_uuid7_is_version_7_and_time_ordered() -> None:
    ids = [uuid7() for _ in range(5000)]
    assert all(i[14] == "7" for i in ids)
    assert ids == sorted(ids) and len(set(ids)) == len(ids)


def test_vault_encrypts_and_refuses_path_traversal(tmp_path: Path) -> None:
    vault = Vault(tmp_path / "vault", new_data_key())
    rel = vault.put(b"secret letter")
    stored = next((tmp_path / "vault").rglob("*.bin")).read_bytes()
    assert b"secret letter" not in stored
    assert vault.get(rel) == b"secret letter"
    with pytest.raises(ValidationFailed):
        vault.get("../../etc/passwd")
    with pytest.raises(ValidationFailed):
        vault.put(b"")
    vault.delete(rel)
    with pytest.raises(NotFound):
        vault.get(rel)
    other = Vault(tmp_path / "vault", new_data_key())
    rel2 = vault.put(b"x")
    with pytest.raises(UnwrapError):
        other.get(rel2)


def test_log_file_is_redacted(tmp_path: Path) -> None:
    import logging

    import structlog

    from core.logging import configure_logging

    configure_logging(tmp_path, "INFO")
    try:
        structlog.get_logger("t").info("signup", email="awa@example.com", note="token=abcdef123")
        for h in logging.getLogger().handlers:
            h.flush()
        content = (tmp_path / "engine.log").read_text(encoding="utf-8")
        assert "signup" in content
        assert "awa@example.com" not in content and "abcdef123" not in content
    finally:
        for h in list(logging.getLogger().handlers):
            h.close()
            logging.getLogger().removeHandler(h)
