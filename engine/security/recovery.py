"""12-word recovery phrases from the BIP-39 wordlists (128 bits of entropy).

The phrase is generated in the user's language (FR or EN). Verification normalises case,
accents-insensitive spacing and accepts either list, so a phrase stays valid if the UI
language changes later.
"""

from __future__ import annotations

import secrets
import unicodedata
from functools import lru_cache

from core.config import resource_dir

WORD_COUNT = 12


@lru_cache(maxsize=4)
def wordlist(lang: str) -> tuple[str, ...]:
    name = "bip39_fr.txt" if lang == "fr" else "bip39_en.txt"
    path = resource_dir() / "security" / "wordlists" / name
    words = tuple(w.strip() for w in path.read_text(encoding="utf-8").splitlines() if w.strip())
    if len(words) != 2048:
        raise RuntimeError(f"corrupted wordlist {name}: {len(words)} words")
    return words


def generate_phrase(lang: str = "fr") -> str:
    words = wordlist(lang)
    return " ".join(secrets.choice(words) for _ in range(WORD_COUNT))


def _fold(word: str) -> str:
    decomposed = unicodedata.normalize("NFKD", word.lower())
    return "".join(c for c in decomposed if not unicodedata.combining(c))


def normalize_phrase(phrase: str) -> str:
    """Canonical form used as KDF input: lower-case, accents stripped, single spaces."""
    return " ".join(_fold(w) for w in phrase.split())


def is_well_formed(phrase: str) -> bool:
    words = normalize_phrase(phrase).split()
    if len(words) != WORD_COUNT:
        return False
    known = {_fold(w) for w in wordlist("fr")} | {_fold(w) for w in wordlist("en")}
    return all(w in known for w in words)
