"""Deterministic post-checks on model output (arch §7.2-5, EF-07.04).

A value is kept as ``explicit`` only when its evidence is found in the source text *and* the value is
recognisable in that evidence; a value justified only by a real excerpt is ``inferred``; anything else
is downgraded to ``unverifiable``. Nothing the model says is trusted on its own.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import date
from urllib.parse import urlsplit

from ai.schemas import Evidenced, ExtractionOut
from core.text import fold

_DIGITS = re.compile(r"\D+")
MONTHS_FR = (
    "janvier", "fevrier", "mars", "avril", "mai", "juin",
    "juillet", "aout", "septembre", "octobre", "novembre", "decembre",
)  # fmt: skip
MONTHS_EN = (
    "january", "february", "march", "april", "may", "june",
    "july", "august", "september", "october", "november", "december",
)  # fmt: skip


@dataclass(frozen=True)
class CheckedField:
    name: str
    value: str | None
    provenance: str  # explicit | inferred | unverifiable | not_specified | generated
    evidence: str | None


def _norm(text: str) -> str:
    return " ".join(fold(text).replace("’", "'").split())


def in_source(excerpt: str | None, source: str) -> bool:
    return bool(excerpt) and len(_norm(excerpt or "")) >= 3 and _norm(excerpt or "") in _norm(source)


def date_forms(d: date) -> set[str]:
    fr, en = MONTHS_FR[d.month - 1], MONTHS_EN[d.month - 1]
    day = f"{d.day}"
    forms = {
        d.isoformat(),
        f"{d.day:02d}/{d.month:02d}/{d.year}",
        f"{day}/{d.month}/{d.year}",
        f"{d.day:02d}-{d.month:02d}-{d.year}",
        f"{d.day:02d}.{d.month:02d}.{d.year}",
        f"{day} {fr} {d.year}",
        f"{day} {en} {d.year}",
        f"{en} {day}, {d.year}",
        f"{en} {day} {d.year}",
    }
    if d.day == 1:
        forms.add(f"1er {fr} {d.year}")
    return forms


def _date_in(value: str, evidence: str) -> bool:
    try:
        d = date.fromisoformat(value)
    except ValueError:
        return False
    ev = _norm(evidence)
    return any(f in ev for f in date_forms(d))


def _amount_in(value: str, evidence: str) -> bool:
    digits = _DIGITS.sub("", value)
    return len(digits) >= 2 and digits in _DIGITS.sub("", evidence)


def _check(name: str, f: Evidenced, source: str, *, recognise: bool, allowed: set[str] | None = None) -> CheckedField:
    value = f.value.strip() if f.value else None
    if not value:
        return CheckedField(name, None, "not_specified", None)
    if allowed is not None and value not in allowed:
        return CheckedField(name, value, "unverifiable", f.evidence)
    if not in_source(f.evidence, source):
        return CheckedField(name, value, "unverifiable", f.evidence)
    evidence = f.evidence or ""
    if name == "deadline":
        recognised = _date_in(value, evidence)
    elif name == "amount":
        recognised = _amount_in(value, evidence)
    else:
        recognised = _norm(value) in _norm(evidence)
    if recognised and not f.inferred:
        return CheckedField(name, value, "explicit", evidence)
    if recognise and not recognised:
        # Dates and amounts must be readable in the cited excerpt (arch §7.2-5).
        return CheckedField(name, value, "unverifiable", evidence)
    return CheckedField(name, value, "inferred", evidence)


def check_extraction(
    out: ExtractionOut, source: str, source_url: str, categories: set[str], countries: set[str]
) -> tuple[list[CheckedField], list[str], list[str], list[str]]:
    """Return (fields, verbatim eligibility clauses, documents, summary lines)."""
    fields = [
        _check("organization_name", out.organization, source, recognise=False),
        _check("deadline", out.deadline, source, recognise=True),
        _check("amount", out.amount, source, recognise=True),
        _check("currency", out.currency, source, recognise=False),
        _check("country_code", out.country, source, recognise=False, allowed=countries),
        _check("work_mode", out.work_mode, source, recognise=False, allowed={"remote", "hybrid", "onsite"}),
        _check("category", out.category, source, recognise=False, allowed=categories),
        _check("target_audience", out.target_audience, source, recognise=False),
    ]
    url = out.application_url
    if url.value:
        host = (urlsplit(url.value).hostname or "").lower()
        source_host = (urlsplit(source_url).hostname or "").lower()
        same_site = bool(host) and (host == source_host or host.endswith("." + source_host.removeprefix("www.")))
        ok = url.value.startswith("https://") and (same_site or url.value in source)
        fields.append(CheckedField("application_url", url.value, "explicit" if ok else "unverifiable", url.evidence))
    else:
        fields.append(CheckedField("application_url", None, "not_specified", None))
    # Verbatim requirement (EF-05.10): clauses not found word for word in the source are dropped.
    clauses = [c for c in out.eligibility if in_source(c, source)]
    documents = [d for d in out.required_documents if d and len(d) <= 300]
    summary = [s for s in out.summary if s][:5]
    return fields, clauses, documents, summary
