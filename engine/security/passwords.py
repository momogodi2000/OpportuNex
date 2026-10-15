"""Password policy (EF-01.02): length >= 12, strength score, local compromised-password list."""

from __future__ import annotations

from dataclasses import dataclass, field
from functools import lru_cache

from zxcvbn import zxcvbn

from core.config import resource_dir

MIN_LENGTH = 12
MIN_SCORE = 3  # zxcvbn 0..4


@lru_cache(maxsize=1)
def _compromised() -> frozenset[str]:
    path = resource_dir() / "security" / "compromised_passwords.txt"
    lines = path.read_text(encoding="utf-8").splitlines()
    return frozenset(
        line.strip().lower() for line in lines if line.strip() and not line.startswith("#"))


@dataclass
class PasswordAssessment:
    score: int
    acceptable: bool
    problems: list[str] = field(default_factory=list)
    suggestions: list[str] = field(default_factory=list)


def assess(password: str, user_inputs: list[str] | None = None) -> PasswordAssessment:
    problems: list[str] = []
    if len(password) < MIN_LENGTH:
        problems.append("too_short")
    if password.lower() in _compromised():
        problems.append("compromised")
    result = zxcvbn(password[:128], user_inputs=[u for u in (user_inputs or []) if u])
    score = int(result["score"])
    if score < MIN_SCORE:
        problems.append("too_weak")
    suggestions = list(result.get("feedback", {}).get("suggestions", []))
    return PasswordAssessment(score=score, acceptable=not problems, problems=problems,
                              suggestions=suggestions)
