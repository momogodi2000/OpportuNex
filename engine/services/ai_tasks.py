"""AI-assisted features, each with the deterministic result as the fallback (EF-14.11).

* Query interpretation (EF-04.02) — AI values are merged into the rule-based filters, restricted to
  known reference codes.
* Opportunity analysis (EF-07.01-05) — fields are applied only when verified against the source text,
  and never overwrite values extracted from structured data.
* Translation on demand (EF-07.08).
* CV parsing (EF-03.03) — on scrubbed text; items not found in the CV are dropped.
* Document drafting (EF-10.06) — from the anonymised validated profile; the integrity check still runs.
"""

from __future__ import annotations

import json
from datetime import date
from typing import Any

from sqlalchemy import delete, insert, select, update

from ai.anonymize import anonymized_profile, scrub, scrub_names
from ai.checks import CheckedField, check_extraction, in_source
from ai.gateway import AIGateway, AIResult, ConsentRequired
from ai.schemas import CvOut, DraftOut, ExtractionOut, QueryOut, TranslationOut
from core.errors import NotFound
from core.text import fold
from services.state import ActiveProfile, EngineState

LANG_NAMES = {"fr": "français", "en": "anglais"}
DOC_LABELS = {
    "cover_letter": "lettre de motivation",
    "scholarship_statement": "lettre de candidature à une bourse",
    "grant_proposal": "proposition de subvention",
    "project_summary": "résumé de projet",
    "application_email": "e-mail de candidature",
    "cv_suggestions": "suggestions d'adaptation du CV à l'opportunité",
    "interview_prep": "préparation d'entretien (questions probables et pistes de réponse)",
}
LETTER_TYPES = {"cover_letter", "scholarship_statement", "application_email"}
# AI field name → (opportunity_fields name, opportunities column or None)
FIELD_MAP = {
    "organization_name": ("organization_name", "organization_name"),
    "deadline": ("deadline_on", "deadline_on"),
    "amount": ("amount", None),
    "currency": ("currency", None),
    "country_code": ("country_code", "country_code"),
    "work_mode": ("work_mode", "work_mode"),
    "category": ("category", None),
    "target_audience": ("target_audience", "target_audience"),
    "application_url": ("application_url", "application_url"),
}


def _info(res: AIResult[Any]) -> dict[str, Any]:
    return {
        "provider_id": res.provider_id,
        "model": res.model,
        "prompt_version": res.prompt_version,
        "from_cache": res.from_cache,
    }


def _reference(active: ActiveProfile) -> tuple[list[str], set[str], set[str], set[str]]:
    T = active.tables
    with active.db.read() as conn:
        categories = [
            r[0] for r in conn.execute(select(T.opportunity_categories.c.code).order_by(T.opportunity_categories.c.id))
        ]
        countries = {r[0] for r in conn.execute(select(T.countries.c.code))}
        languages = {r[0] for r in conn.execute(select(T.languages.c.code))}
        currencies = {r[0] for r in conn.execute(select(T.currencies.c.code))}
    return categories, countries, languages, currencies


def preflight(active: ActiveProfile, state: EngineState, task: str, purposes: tuple[str, ...]) -> bool:
    """True when AI would run; raises ConsentRequired before any work if consent is missing (EF-14.09)."""
    gw = AIGateway(active, state)
    if not gw.enabled():
        return False
    for p in gw.chain(task):
        if gw._suspended(p["id"]):
            continue
        if not p["is_local"]:
            missing = gw.missing_consents(p["id"], purposes)
            if missing:
                raise ConsentRequired(
                    "consent required before sending data to this AI provider",
                    code="ai_consent_required",
                    extra={"provider_id": p["id"], "provider_name": p["display_name"], "purposes": missing},
                )
        return True
    return False


# --------------------------------------------------------------------- query
async def interpret_query(
    active: ActiveProfile, state: EngineState, text: str, rules: dict[str, Any]
) -> dict[str, Any]:
    categories, countries, languages, currencies = _reference(active)
    res = await AIGateway(active, state).run(
        "query_interpretation",
        data=text,
        schema=QueryOut,
        data_category="search_query",
        interactive=True,
        params={"categories": ", ".join(categories), "today": date.today().isoformat()},
    )
    if res is None:
        return {"filters": rules, "interpreter": "rules"}
    q, f = res.data, dict(rules)

    def merge(key: str, values: list[str], allowed: set[str]) -> None:
        f[key] = list(dict.fromkeys([*rules.get(key, []), *[v for v in values if v in allowed]]))

    merge("categories", q.categories, set(categories))
    merge("countries", [c.upper() for c in q.countries], countries)
    merge("languages", [c.lower() for c in q.languages], languages)
    f["keywords"] = list(dict.fromkeys([*rules.get("keywords", []), *[k.lower() for k in q.keywords if k]]))[:12]
    f["work_mode"] = rules.get("work_mode") or q.work_mode
    if not rules.get("amount_min") and q.amount_min and q.amount_currency and q.amount_currency.upper() in currencies:
        f["amount_min"], f["amount_currency"] = q.amount_min, q.amount_currency.upper()
    if not rules.get("deadline_before") and q.deadline_before and q.deadline_before >= date.today().isoformat():
        f["deadline_before"] = q.deadline_before
    if rules.get("experience_max_years") is None:
        f["experience_max_years"] = q.experience_max_years
    return {"filters": f, "interpreter": "ai", "ai": _info(res)}


# --------------------------------------------------------------- opportunity
def _opportunity(active: ActiveProfile, opp_id: str) -> dict[str, Any]:
    T = active.tables
    with active.db.read() as conn:
        row = conn.execute(select(T.opportunities).where(T.opportunities.c.id == opp_id)).mappings().first()
    if row is None:
        raise NotFound("opportunity not found", code="opportunity_not_found")
    return dict(row)


def _source_text(o: dict[str, Any]) -> str:
    return "\n".join(x for x in (o["title"], o["summary"], o["description_text"], o["eligibility_raw"]) if x)


def _apply_analysis(
    active: ActiveProfile,
    opp_id: str,
    res: AIResult[ExtractionOut],
    fields: list[CheckedField],
    clauses: list[str],
    documents: list[str],
    summary: list[str],
    source: str,
) -> dict[str, list[str]]:
    T = active.tables
    applied: list[str] = []
    unverifiable: list[str] = []
    with active.db.tx() as conn:
        o = dict(conn.execute(select(T.opportunities).where(T.opportunities.c.id == opp_id)).mappings().one())
        existing = {
            r["field_name"]: dict(r)
            for r in conn.execute(
                select(T.opportunity_fields).where(T.opportunity_fields.c.opportunity_id == opp_id)
            ).mappings()
        }

        def write(name: str, value: str | None, provenance: str, evidence: str | None) -> None:
            conn.execute(
                delete(T.opportunity_fields).where(
                    T.opportunity_fields.c.opportunity_id == opp_id, T.opportunity_fields.c.field_name == name
                )
            )
            conn.execute(
                insert(T.opportunity_fields).values(
                    opportunity_id=opp_id,
                    field_name=name,
                    value_text=value,
                    provenance=provenance,
                    evidence_excerpt=(evidence or "")[:600] or None,
                    extracted_by="ai",
                    ai_provider_id=res.provider_id,
                    confidence=0.8 if provenance == "explicit" else 0.5,
                )
            )

        column_updates: dict[str, Any] = {}
        for f in fields:
            name, column = FIELD_MAP[f.name]
            prev = existing.get(name)
            replaceable = (
                prev is None or prev["value_text"] is None or prev["provenance"] in ("not_specified", "unverifiable")
            )
            if not replaceable or f.provenance == "not_specified":
                continue
            if f.provenance == "unverifiable":
                write(name, f.value, "unverifiable", f.evidence)
                unverifiable.append(name)
                continue
            write(name, f.value, f.provenance, f.evidence)
            applied.append(name)
            if column and o.get(column) in (None, ""):
                column_updates[column] = f.value
                if column == "deadline_on":
                    column_updates["deadline_raw"] = f.evidence
            if f.name == "category" and o.get("category_id") is None:
                cid = conn.execute(
                    select(T.opportunity_categories.c.id).where(T.opportunity_categories.c.code == f.value)
                ).scalar()
                if cid:
                    column_updates["category_id"] = cid
        if clauses and not o.get("eligibility_raw"):
            column_updates["eligibility_raw"] = "\n".join(clauses)
            write("eligibility_raw", "\n".join(clauses), "explicit", clauses[0])
            applied.append("eligibility_raw")
        known_docs = {
            fold(r[0])
            for r in conn.execute(
                select(T.opportunity_requirements.c.label).where(
                    T.opportunity_requirements.c.opportunity_id == opp_id,
                    T.opportunity_requirements.c.req_type == "document",
                )
            )
        }
        for d in documents:
            if fold(d) not in known_docs and in_source(d, source):
                conn.execute(
                    insert(T.opportunity_requirements).values(
                        opportunity_id=opp_id,
                        req_type="document",
                        label=d[:200],
                        provenance="explicit",
                        original_text=d,
                    )
                )
                known_docs.add(fold(d))
        if summary:
            write("ai_summary", "\n".join(summary), "generated", None)
        if applied or summary:
            column_updates["analysis_method"] = "mixed"
        if column_updates:
            conn.execute(update(T.opportunities).where(T.opportunities.c.id == opp_id).values(**column_updates))
    return {"applied": applied, "unverifiable": unverifiable}


async def analyze_opportunity(active: ActiveProfile, state: EngineState, opp_id: str, language: str) -> dict[str, Any]:
    o = _opportunity(active, opp_id)
    source = _source_text(o)
    categories, countries, _l, _c = _reference(active)
    res = await AIGateway(active, state).run(
        "extraction",
        data=source,
        schema=ExtractionOut,
        data_category="opportunity_text",
        interactive=True,
        params={"categories": ", ".join(categories), "language": LANG_NAMES.get(language, "français")},
    )
    if res is None:
        return {"status": "unavailable"}
    fields, clauses, documents, summary = check_extraction(
        res.data, source, o["canonical_url"] or "", set(categories), countries
    )
    outcome = _apply_analysis(active, opp_id, res, fields, clauses, documents, summary, source)
    return {"status": "analyzed", **outcome, "ai": _info(res)}


async def translate_opportunity(
    active: ActiveProfile, state: EngineState, opp_id: str, language: str
) -> dict[str, Any]:
    o = _opportunity(active, opp_id)
    payload = json.dumps(
        {"title": o["title"], "summary": o["summary"], "description": (o["description_text"] or "")[:8000]},
        ensure_ascii=False,
    )
    res = await AIGateway(active, state).run(
        "translation",
        data=payload,
        schema=TranslationOut,
        data_category="opportunity_text",
        interactive=True,
        params={"language": LANG_NAMES.get(language, "français")},
    )
    if res is None:
        return {"status": "unavailable"}
    return {
        "status": "translated",
        "language": language,
        "provenance": "generated",
        **res.data.model_dump(),
        "ai": _info(res),
    }


# ------------------------------------------------------------------------ CV
CV_PURPOSES = ("ai_remote_processing", "cv_parsing_ai")


async def cv_items(
    active: ActiveProfile, state: EngineState, text: str, full_name: str | None
) -> list[tuple[str, dict[str, Any], float]] | None:
    """Items verified against the CV text, or None when the deterministic extraction must be kept."""
    names = [n for n in (full_name or "").split() if n]
    data = scrub_names(scrub(text) or "", names)
    res = await AIGateway(active, state).run(
        "cv_parsing", data=data, schema=CvOut, data_category="cv_text", purposes=CV_PURPOSES, interactive=True
    )
    if res is None:
        return None
    cv, folded = res.data, fold(text)
    _cats, _countries, languages, _cur = _reference(active)
    seen = lambda s: bool(s) and fold(s) in folded  # noqa: E731 - anti-fabrication: must appear in the CV
    items: list[tuple[str, dict[str, Any], float]] = []
    for e in cv.education:
        if seen(e.degree):
            items.append(
                (
                    "education",
                    {
                        "level": e.degree[:60],
                        "field_of_study": (e.field_of_study or e.degree)[:160],
                        "institution": (e.institution or "—")[:200],
                        "start_date": e.start_date,
                        "end_date": None if e.ongoing else e.end_date,
                        "is_ongoing": e.ongoing,
                    },
                    0.7,
                )
            )
    for x in cv.experience:
        if seen(x.job_title):
            items.append(
                (
                    "experience",
                    {
                        "job_title": x.job_title[:160],
                        "employer": (x.employer or "—")[:200],
                        "start_date": x.start_date,
                        "end_date": None if x.current else x.end_date,
                        "is_current": x.current,
                        "description": x.description,
                    },
                    0.7,
                )
            )
    for s in dict.fromkeys(cv.skills):
        if seen(s):
            items.append(("skill", {"name": s[:80]}, 0.7))
    for lang in cv.languages:
        if lang.code.lower() in languages:
            items.append(
                (
                    "language",
                    {"language_code": lang.code.lower(), "cefr_level": lang.level or "B1"},
                    0.7 if lang.level else 0.4,
                )
            )
    for c in cv.certifications:
        if seen(c.name):
            items.append(("certification", {"name": c.name[:200], "obtained_on": c.obtained_on}, 0.65))
    return items


# ----------------------------------------------------------------- drafting
DRAFT_PURPOSES = ("ai_remote_processing", "profile_to_ai")


async def draft_body(
    active: ActiveProfile, state: EngineState, doc_type: str, profile: dict[str, Any], opp: dict[str, Any], lang: str
) -> tuple[str, str] | None:
    """(Markdown body, provider id) from the anonymised profile, or None for the template path."""
    payload = {
        "profil": anonymized_profile(profile),
        "opportunite": {
            "titre": opp["title"],
            "organisme": opp.get("organization_name"),
            "date_limite": opp.get("deadline_on"),
            "resume": opp.get("summary"),
            "eligibilite": opp.get("eligibility_raw"),
            "competences_demandees": opp.get("required_skills", []),
        },
    }
    res = await AIGateway(active, state).run(
        "document_drafting",
        data=json.dumps(payload, ensure_ascii=False, default=str),
        schema=DraftOut,
        data_category="profile_anonymized",
        purposes=DRAFT_PURPOSES,
        interactive=True,
        params={"language": LANG_NAMES.get(lang, "français"), "doc_type": DOC_LABELS.get(doc_type, doc_type)},
    )
    return (res.data.body, res.provider_id) if res else None
