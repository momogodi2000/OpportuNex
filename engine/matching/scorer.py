"""Relevance score 0–100 from weighted criteria (EF-08.01..05, arch §7.4).

The score is deterministic and every criterion is explained. Eligibility is never asserted
unless the opportunity publishes criteria *and* the profile satisfies all machine-checkable
ones (EF-08.04); otherwise it stays ``uncertain`` and the unverifiable clauses are listed.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date
from typing import Any

from core.text import fold

ALGORITHM_VERSION = "1.0"
DEFAULT_WEIGHTS = {
    "skills": 0.30,
    "education": 0.15,
    "experience": 0.15,
    "location": 0.15,
    "language": 0.10,
    "objectives": 0.10,
    "deadline": 0.05,
}
EDU_RANK = {
    "none": 0,
    "primary": 1,
    "secondary": 2,
    "vocational": 3,
    "bac": 3,
    "bac_plus_2": 4,
    "bachelor": 5,
    "master": 6,
    "doctorate": 7,
    "postdoc": 8,
}
CEFR_RANK = {"A1": 1, "A2": 2, "B1": 3, "B2": 4, "C1": 5, "C2": 6, "native": 7}
CEMAC = {"CM", "GA", "CG", "TD", "CF", "GQ"}
UNCHECKABLE = (
    "nationalit",
    "citizen",
    "ressortissant",
    "resident",
    "residence",
    "age ",
    "âge",
    "years old",
    "ans au plus",
    "moins de",
    "under the age",
    "femme",
    "women",
    "female",
    "genre",
    "gender",
)


@dataclass
class OpportunityFacts:
    category_code: str | None
    country_code: str | None
    work_mode: str | None
    language_code: str | None
    deadline: date | None
    education_required: str | None
    experience_min_years: float | None
    eligibility_raw: str | None
    text: str
    required_skills: list[str] = field(default_factory=list)
    required_languages: list[str] = field(default_factory=list)


@dataclass
class ProfileFacts:
    skills: list[str]
    education: str | None
    experience_years: float | None
    country_code: str | None
    preferred_countries: list[str]
    preferred_regions: list[str]
    work_mode_pref: str | None
    willing_to_relocate: bool
    languages: dict[str, str]
    objective_categories: set[str]


@dataclass
class MatchResult:
    score: int
    breakdown: dict[str, dict[str, Any]]
    strengths: list[str]
    gaps: list[str]
    eligibility: str
    to_verify: list[str]


def _criterion(score: float, reason: str, evaluated: bool = True) -> dict[str, Any]:
    return {"score": round(max(0.0, min(1.0, score)), 3), "reason": reason, "evaluated": evaluated}


def score(
    o: OpportunityFacts, p: ProfileFacts, weights: dict[str, float] | None = None, today: date | None = None
) -> MatchResult:
    w = {**DEFAULT_WEIGHTS, **(weights or {})}
    today = today or date.today()
    b: dict[str, dict[str, Any]] = {}
    strengths: list[str] = []
    gaps: list[str] = []
    hard_fail = False
    checks_passed: list[bool] = []

    # skills
    user_skills = {fold(s) for s in p.skills}
    if o.required_skills:
        req = {fold(s) for s in o.required_skills}
        hit = req & user_skills
        ratio = len(hit) / len(req)
        b["skills"] = _criterion(ratio, f"{len(hit)}/{len(req)}")
        if hit:
            strengths.append("skills_match:" + ", ".join(sorted(s for s in o.required_skills if fold(s) in hit)))
        missing = [s for s in o.required_skills if fold(s) not in user_skills]
        if missing:
            gaps.append("skills_missing:" + ", ".join(missing[:8]))
        checks_passed.append(ratio >= 0.5)
    elif user_skills:
        text = f" {fold(o.text[:20000])} "
        hit_names = [s for s in p.skills if f" {fold(s)} " in text]
        ratio = min(1.0, len(hit_names) / 3)
        b["skills"] = _criterion(0.4 + 0.6 * ratio, "keywords", evaluated=bool(hit_names))
        if hit_names:
            strengths.append("skills_mentioned:" + ", ".join(hit_names[:6]))
    else:
        b["skills"] = _criterion(0.5, "profile_has_no_skills", evaluated=False)

    # education
    req_rank = EDU_RANK.get(o.education_required or "")
    user_rank = EDU_RANK.get(p.education or "")
    if req_rank is not None and user_rank is not None:
        diff = user_rank - req_rank
        s = 1.0 if diff >= 0 else 0.5 if diff == -1 else 0.0
        b["education"] = _criterion(s, f"{p.education}>={o.education_required}" if diff >= 0 else "below")
        if diff >= 0:
            strengths.append(f"education_ok:{o.education_required}")
        else:
            gaps.append(f"education_required:{o.education_required}")
            if diff <= -2:
                hard_fail = True
        checks_passed.append(diff >= 0)
    else:
        b["education"] = _criterion(0.7, "not_specified", evaluated=False)

    # experience
    if o.experience_min_years:
        have = p.experience_years or 0.0
        s = min(1.0, have / o.experience_min_years)
        b["experience"] = _criterion(s, f"{have:g}/{o.experience_min_years:g}")
        if have >= o.experience_min_years:
            strengths.append(f"experience_ok:{o.experience_min_years:g}")
        else:
            gaps.append(f"experience_required:{o.experience_min_years:g}")
            if have < o.experience_min_years / 2:
                hard_fail = True
        checks_passed.append(have >= o.experience_min_years)
    else:
        b["experience"] = _criterion(0.7, "not_specified", evaluated=False)

    # location
    targets = {c for c in [p.country_code, *p.preferred_countries] if c}
    if o.work_mode == "remote":
        s = 1.0 if p.work_mode_pref in (None, "remote", "hybrid", "any") else 0.7
        b["location"] = _criterion(s, "remote")
        strengths.append("remote")
    elif o.country_code and o.country_code in targets:
        b["location"] = _criterion(1.0, f"country:{o.country_code}")
        strengths.append(f"location:{o.country_code}")
    elif (
        o.country_code
        and o.country_code in CEMAC
        and (targets & CEMAC or "afrique centrale" in {fold(r) for r in p.preferred_regions})
    ):
        b["location"] = _criterion(0.7, f"region:{o.country_code}")
    elif o.country_code:
        b["location"] = _criterion(0.5 if p.willing_to_relocate else 0.2, f"elsewhere:{o.country_code}")
        if not p.willing_to_relocate:
            gaps.append(f"location:{o.country_code}")
    else:
        b["location"] = _criterion(0.5, "not_specified", evaluated=False)

    # language
    if o.required_languages:
        ok = [code for code in o.required_languages if CEFR_RANK.get(p.languages.get(code, ""), 0) >= 3]
        s = len(ok) / len(o.required_languages)
        b["language"] = _criterion(s, f"{len(ok)}/{len(o.required_languages)}")
        missing = [c for c in o.required_languages if c not in ok]
        if missing:
            gaps.append("language_required:" + ",".join(missing))
        else:
            strengths.append("languages_ok")
        checks_passed.append(not missing)
    elif o.language_code:
        known = CEFR_RANK.get(p.languages.get(o.language_code, ""), 0) >= 3 or (
            o.language_code == "fr" and not p.languages
        )
        b["language"] = _criterion(1.0 if known else 0.4, f"posting_language:{o.language_code}")
        if not known:
            gaps.append(f"posting_language:{o.language_code}")
    else:
        b["language"] = _criterion(0.6, "not_specified", evaluated=False)

    # objectives
    if p.objective_categories:
        cat = o.category_code or "other"
        root = cat.split(".")[0]
        objective_hit = cat in p.objective_categories or root in p.objective_categories
        b["objectives"] = _criterion(1.0 if objective_hit else 0.2, f"category:{cat}")
        if objective_hit:
            strengths.append(f"objective:{root}")
    else:
        b["objectives"] = _criterion(0.5, "no_objectives", evaluated=False)

    # deadline
    if o.deadline:
        days = (o.deadline - today).days
        if days < 0:
            b["deadline"] = _criterion(0.0, "expired")
            hard_fail = True
        else:
            b["deadline"] = _criterion(0.4 if days <= 3 else 0.8 if days <= 14 else 1.0, f"days_left:{days}")
    else:
        b["deadline"] = _criterion(0.6, "not_specified", evaluated=False)

    total_w = sum(w.values()) or 1.0
    value = sum(w[k] * b[k]["score"] for k in w) / total_w
    final = round(100 * value)

    to_verify: list[str] = []
    if o.eligibility_raw:
        for clause in o.eligibility_raw.split("\n"):
            if any(cue in fold(clause) for cue in UNCHECKABLE):
                to_verify.append(clause.strip()[:300])
    expired = b["deadline"]["reason"] == "expired"
    if expired:
        eligibility = "not_eligible"
    elif hard_fail:
        eligibility = "unlikely"
    elif checks_passed and all(checks_passed) and o.eligibility_raw and not to_verify:
        eligibility = "likely"
    else:
        eligibility = "uncertain"
    if not o.eligibility_raw and not checks_passed:
        to_verify.append("no_published_criteria")
    return MatchResult(
        score=final, breakdown=b, strengths=strengths, gaps=gaps, eligibility=eligibility, to_verify=to_verify
    )
