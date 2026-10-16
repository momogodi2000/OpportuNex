"""Deduplication keys (ADR-009, arch §6.3): normalised URL, source id, fingerprint, simhash."""

from __future__ import annotations

import hashlib
import re
from datetime import date
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from rapidfuzz import fuzz

from core.text import fold_words

TRACKING_PARAMS = re.compile(r"^(utm_|fbclid$|gclid$|mc_cid$|mc_eid$|ref$|ref_src$|source$|_hs|yclid$|igshid$)")
FUZZY_TITLE_THRESHOLD = 92
SIMHASH_MAX_DISTANCE = 6


def normalize_url(url: str) -> str:
    parts = urlsplit(url.strip())
    scheme = "https" if parts.scheme in ("http", "https") else parts.scheme
    host = (parts.hostname or "").lower()
    if host.startswith("www."):
        host = host[4:]
    port = f":{parts.port}" if parts.port and parts.port not in (80, 443) else ""
    path = re.sub(r"/{2,}", "/", parts.path or "/")
    if len(path) > 1 and path.endswith("/"):
        path = path[:-1]
    query = urlencode(
        sorted(
            (k, v) for k, v in parse_qsl(parts.query, keep_blank_values=False) if not TRACKING_PARAMS.match(k.lower())
        )
    )
    return urlunsplit((scheme, host + port, path, query, ""))


def fingerprint(title: str, organization: str | None, deadline: date | None) -> str:
    key = "|".join([fold_words(title), fold_words(organization or ""), deadline.isoformat() if deadline else ""])
    return hashlib.sha1(key.encode("utf-8"), usedforsecurity=False).hexdigest()


def simhash(text: str) -> int:
    """64-bit simhash over word 3-shingles, stored as a signed SQLite INTEGER."""
    words = fold_words(text).split()[:400]
    shingles = [" ".join(words[i : i + 3]) for i in range(max(1, len(words) - 2))] or [""]
    vector = [0] * 64
    for sh in shingles:
        h = int.from_bytes(hashlib.blake2b(sh.encode("utf-8"), digest_size=8).digest(), "big")
        for bit in range(64):
            vector[bit] += 1 if (h >> bit) & 1 else -1
    value = sum(1 << bit for bit in range(64) if vector[bit] > 0)
    return value - (1 << 64) if value >= (1 << 63) else value


def hamming(a: int, b: int) -> int:
    return bin((a ^ b) & ((1 << 64) - 1)).count("1")


def same_opportunity(
    title_a: str, title_b: str, sim_a: int | None, sim_b: int | None, deadline_a: str | None, deadline_b: str | None
) -> bool:
    """Approximate match used after exact keys failed (multi-site reposts)."""
    if deadline_a and deadline_b and deadline_a != deadline_b:
        return False
    title_score = fuzz.token_set_ratio(fold_words(title_a), fold_words(title_b))
    if title_score < FUZZY_TITLE_THRESHOLD:
        return False
    if sim_a is None or sim_b is None:
        return title_score >= 97
    return hamming(sim_a, sim_b) <= SIMHASH_MAX_DISTANCE or title_score >= 97
