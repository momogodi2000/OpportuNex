"""Remove personal data and secrets from free text before it is logged or exported."""

from __future__ import annotations

import re

_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"), "[email]"),
    (re.compile(r"(?i)bearer\s+[A-Za-z0-9\-._~+/]+=*"), "Bearer [token]"),
    (re.compile(r"\bsk-[A-Za-z0-9_-]{8,}\b"), "[api-key]"),
    (re.compile(r"\bAIza[A-Za-z0-9_-]{20,}\b"), "[api-key]"),
    (re.compile(r"\bgsk_[A-Za-z0-9]{20,}\b"), "[api-key]"),
    (re.compile(r"(?i)\b(api[_-]?key|token|password|secret|passphrase)\b\s*[=:]\s*\S+"), r"\1=[redacted]"),
    (re.compile(r"(?i)x'[0-9a-f]{32,}'"), "x'[key]'"),
    (re.compile(r"\b[0-9a-fA-F]{48,}\b"), "[hex]"),
    # Phone numbers: international (+237 6 99 ...) or space/dot-grouped local numbers.
    # Dash-separated digit runs are left alone so ISO dates survive.
    (re.compile(r"\+\d{1,3}(?:[\s.]?\d{1,4}){3,5}"), "[phone]"),
    (re.compile(r"(?<![\d.])\d{2,3}(?:[ .]\d{2,3}){3,4}(?![\d.])"), "[phone]"),
]


def redact(text: str) -> str:
    for pattern, repl in _PATTERNS:
        text = pattern.sub(repl, text)
    return text
