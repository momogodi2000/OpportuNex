"""Data minimisation before anything is sent to a model (EF-14.10, arch §7.1).

The anonymised profile keeps what a letter or a match explanation needs (degrees, roles, skills,
languages, objectives) and drops every direct identifier: name, e-mail, phone, links, address,
birth date, internal ids. Free text is scrubbed of e-mails, phone numbers and URLs.
"""

from __future__ import annotations

import re
from typing import Any

_EMAIL = re.compile(r"[\w.+-]+@[\w-]+(\.[\w-]+)+")
_URL = re.compile(r"\b(?:https?://|www\.)\S+", re.IGNORECASE)
_PHONE = re.compile(r"(?<!\w)(?:\+|00)?\d[\d\s().-]{7,}\d(?!\w)")


def scrub(text: str | None) -> str | None:
    if not text:
        return text
    out = _EMAIL.sub("[courriel retiré]", text)
    out = _URL.sub("[lien retiré]", out)
    return _PHONE.sub("[téléphone retiré]", out)


def scrub_names(text: str, names: list[str]) -> str:
    """Remove the user's own name from free text (e.g. a CV), whole words only."""
    for name in sorted({n for n in names if n and len(n) > 2}, key=len, reverse=True):
        text = re.sub(rf"(?<!\w){re.escape(name)}(?!\w)", "[nom retiré]", text, flags=re.IGNORECASE)
    return text


def _pick(row: dict[str, Any], keys: tuple[str, ...]) -> dict[str, Any]:
    return {
        k: (scrub(row[k]) if isinstance(row.get(k), str) else row.get(k)) for k in keys if row.get(k) not in (None, "")
    }


def anonymized_profile(profile: dict[str, Any]) -> dict[str, Any]:
    g = profile.get("general") or {}
    general = _pick(
        g,
        (
            "country_code",
            "city",
            "professional_status",
            "current_occupation",
            "highest_education",
            "experience_years",
            "work_mode_pref",
            "willing_to_relocate",
            "bio",
        ),
    )
    names = [n for n in str(g.get("full_name") or "").split() if n]
    if isinstance(general.get("bio"), str):
        general["bio"] = scrub_names(general["bio"], names)
    return {
        "general": general,
        "education": [
            _pick(
                e,
                (
                    "level",
                    "field_of_study",
                    "institution",
                    "start_date",
                    "end_date",
                    "is_ongoing",
                    "grade",
                    "achievements",
                ),
            )
            for e in profile.get("education", [])
        ],
        "experience": [
            _pick(x, ("job_title", "employer", "start_date", "end_date", "is_current", "description"))
            for x in profile.get("experiences", [])
        ],
        "certifications": [_pick(c, ("name", "issuer", "obtained_on")) for c in profile.get("certifications", [])],
        "skills": [s["name"] for s in profile.get("skills", []) if s.get("name")],
        "languages": [_pick(lang, ("language_code", "cefr_level")) for lang in profile.get("languages", [])],
        "objectives": [o["code"] for o in (profile.get("objectives") or {}).get("items", []) if o.get("code")],
        "projects": [
            _pick(p, ("title", "description", "stage", "beneficiaries", "timeline_months"))
            for p in profile.get("projects", [])
        ],
    }
