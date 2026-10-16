"""Text normalisation shared by matching, deduplication, search and the skills reference."""

from __future__ import annotations

import re
import unicodedata

_SPACES = re.compile(r"\s+")
_NON_WORD = re.compile(r"[^\w\s]", re.UNICODE)


def fold(text: str) -> str:
    """Lower-case, strip accents and collapse whitespace."""
    decomposed = unicodedata.normalize("NFKD", text.lower())
    stripped = "".join(c for c in decomposed if not unicodedata.combining(c))
    return _SPACES.sub(" ", stripped).strip()


def fold_words(text: str) -> str:
    """:func:`fold` plus punctuation removal — used for fingerprints and keyword matching."""
    return _SPACES.sub(" ", _NON_WORD.sub(" ", fold(text))).strip()


def truncate_lines(text: str, max_lines: int = 5, max_chars: int = 600) -> str:
    """Summary helper (EF-07.05): at most ``max_lines`` sentences and ``max_chars``."""
    sentences = re.split(r"(?<=[.!?])\s+", _SPACES.sub(" ", text).strip())
    out: list[str] = []
    for s in sentences:
        if not s:
            continue
        if len(" ".join([*out, s])) > max_chars or len(out) >= max_lines:
            break
        out.append(s)
    if not out and text:
        return text[: max_chars - 1].rstrip() + "…"
    return " ".join(out)
