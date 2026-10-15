"""Persist collected items: raw documents, deduplicated opportunities, provenance, versions.

Implements EF-05.10 (verbatim clauses kept), EF-07.02/03 (field provenance with evidence),
EF-09.02/03 (dedup by URL, source id, fingerprint, then approximate similarity; prefer the
original publisher) and EF-10.04 (change detection into ``opportunity_versions``).
"""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from typing import Any

from sqlalchemy import Connection, delete, insert, select, update

from collection.adapters import RawItem
from collection.dedup import fingerprint, normalize_url, same_opportunity, simhash
from collection.normalize import Normalized
from core.ids import uuid7
from core.timeutil import now_iso
from persistence.database import Tables

TRACKED_FIELDS = (
    "title",
    "deadline_on",
    "amount_min_minor",
    "amount_max_minor",
    "eligibility_raw",
    "application_url",
    "organization_name",
)


@dataclass
class StoreOutcome:
    opportunity_id: str
    created: bool
    changed_fields: list[str]


def _category_id(conn: Connection, T: Tables, code: str) -> int | None:
    row = conn.execute(select(T.opportunity_categories.c.id).where(T.opportunity_categories.c.code == code)).first()
    if row is None and "." in code:
        row = conn.execute(
            select(T.opportunity_categories.c.id).where(T.opportunity_categories.c.code == code.split(".")[0])
        ).first()
    return int(row[0]) if row else None


def _known_currency(conn: Connection, T: Tables, code: str | None) -> str | None:
    if not code:
        return None
    return code if conn.execute(select(T.currencies.c.code).where(T.currencies.c.code == code)).first() else None


def _known_country(conn: Connection, T: Tables, code: str | None) -> str | None:
    if not code:
        return None
    return code if conn.execute(select(T.countries.c.code).where(T.countries.c.code == code)).first() else None


def store_item(
    conn: Connection,
    T: Tables,
    *,
    source: dict[str, Any],
    scan_run_id: str | None,
    item: RawItem,
    normalized: Normalized,
    detail_text: str,
    structured: dict[str, Any] | None,
) -> StoreOutcome:
    norm_url = normalize_url(item.url)
    body = "\n".join([normalized.title, detail_text or item.summary])
    content_hash = hashlib.sha256(body.encode("utf-8")).hexdigest()

    raw_id = conn.execute(
        select(T.raw_documents.c.id).where(
            T.raw_documents.c.source_id == source["id"],
            T.raw_documents.c.normalized_url == norm_url,
            T.raw_documents.c.content_sha256 == content_hash,
        )
    ).scalar()
    if raw_id is None:
        raw_id = uuid7()
        conn.execute(
            insert(T.raw_documents).values(
                id=raw_id,
                source_id=source["id"],
                scan_run_id=scan_run_id,
                url=item.url,
                normalized_url=norm_url,
                external_id=item.external_id,
                content_type="text/html" if detail_text else "application/rss+xml",
                content_sha256=content_hash,
                extracted_text=(detail_text or item.summary)[:200_000],
                structured_data=json.dumps(structured, default=str)[:200_000] if structured else None,
                language_code=normalized.language_code,
                processing_status="extracted",
            )
        )

    fp = fingerprint(normalized.title, normalized.organization, normalized.deadline)
    sim = simhash(f"{normalized.title} {normalized.description[:4000]}")
    deadline = normalized.deadline.isoformat() if normalized.deadline else None

    existing, method = _find_existing(
        conn, T, source["id"], norm_url, item.external_id, fp, normalized.title, sim, deadline
    )
    currency = _known_currency(conn, T, normalized.amount.currency if normalized.amount else None)
    values: dict[str, Any] = {
        "title": normalized.title,
        "category_id": _category_id(conn, T, normalized.category),
        "organization_name": normalized.organization,
        "summary": normalized.summary,
        "description_text": normalized.description[:100_000] or None,
        "language_code": normalized.language_code
        if normalized.language_code in ("fr", "en", "es", "pt", "de", "ar", "zh", "sw")
        else None,
        "country_code": _known_country(conn, T, normalized.country_code),
        "eligible_regions": json.dumps(normalized.eligible_regions) if normalized.eligible_regions else None,
        "location_text": normalized.location_text,
        "work_mode": normalized.work_mode or "unspecified",
        "education_required": normalized.education_required,
        "experience_min_years": normalized.experience_min_years,
        "amount_min_minor": normalized.amount.minimum if (normalized.amount and currency) else None,
        "amount_max_minor": normalized.amount.maximum if (normalized.amount and currency) else None,
        "amount_currency": currency if normalized.amount else None,
        "published_on": normalized.published.isoformat() if normalized.published else None,
        "deadline_on": deadline,
        "deadline_raw": normalized.deadline_raw,
        "eligibility_raw": normalized.eligibility_raw,
        "application_url": item.url,
        "verification_status": "unverified" if not deadline or deadline >= now_iso()[:10] else "expired",
        "analysis_method": "deterministic",
        "analysis_version": "rules-1.0",
        "last_checked_at": now_iso(),
    }
    if existing is None:
        opp_id = uuid7()
        conn.execute(
            insert(T.opportunities).values(
                id=opp_id,
                canonical_url=item.url,
                normalized_url=norm_url,
                primary_source_id=source["id"],
                dedup_fingerprint=fp,
                simhash=sim,
                **values,
            )
        )
        created, changed = True, []
    else:
        opp_id = existing["id"]
        changed = [f for f in TRACKED_FIELDS if values.get(f) is not None and existing.get(f) != values.get(f)]
        update_values = {k: v for k, v in values.items() if v is not None}
        if changed and method != "simhash":
            conn.execute(
                insert(T.opportunity_versions).values(
                    opportunity_id=opp_id,
                    changed_fields=json.dumps(changed),
                    previous_values=json.dumps({f: existing.get(f) for f in changed}, default=str),
                )
            )
            update_values["last_changed_at"] = now_iso()
            if existing.get("verification_status") == "verified":
                update_values["verification_status"] = "modified"
        if method == "simhash":
            # A repost on another site: keep the original's content, only refresh freshness.
            update_values = {"last_checked_at": now_iso()}
            changed = []
        conn.execute(update(T.opportunities).where(T.opportunities.c.id == opp_id).values(**update_values))
        created = False

    is_original = bool(source.get("is_official")) or (
        normalized.organization is not None
        and source.get("publisher_name") is not None
        and normalized.organization.lower() in str(source["publisher_name"]).lower()
    )
    link = conn.execute(
        select(T.opportunity_sources.c.raw_document_id).where(
            T.opportunity_sources.c.opportunity_id == opp_id, T.opportunity_sources.c.raw_document_id == raw_id
        )
    ).first()
    if link is None:
        conn.execute(
            insert(T.opportunity_sources).values(
                opportunity_id=opp_id,
                raw_document_id=raw_id,
                source_id=source["id"],
                url=item.url,
                is_original=1 if is_original else 0,
                match_method=method or "url",
            )
        )
    if is_original and not created:
        conn.execute(
            update(T.opportunities)
            .where(T.opportunities.c.id == opp_id)
            .values(canonical_url=item.url, primary_source_id=source["id"])
        )

    _write_fields(conn, T, opp_id, raw_id, normalized)
    _write_requirements(conn, T, opp_id, normalized)
    return StoreOutcome(opp_id, created, changed)


def _find_existing(
    conn: Connection,
    T: Tables,
    source_id: str,
    norm_url: str,
    external_id: str | None,
    fp: str,
    title: str,
    sim: int,
    deadline: str | None,
) -> tuple[dict[str, Any] | None, str | None]:
    o = T.opportunities
    row = conn.execute(select(o).where(o.c.normalized_url == norm_url)).mappings().first()
    if row:
        return dict(row), "url"
    if external_id:
        row = (
            conn.execute(
                select(o)
                .join(T.opportunity_sources, T.opportunity_sources.c.opportunity_id == o.c.id)
                .join(T.raw_documents, T.raw_documents.c.id == T.opportunity_sources.c.raw_document_id)
                .where(T.raw_documents.c.source_id == source_id, T.raw_documents.c.external_id == external_id)
            )
            .mappings()
            .first()
        )
        if row:
            return dict(row), "external_id"
    row = conn.execute(select(o).where(o.c.dedup_fingerprint == fp)).mappings().first()
    if row:
        return dict(row), "fingerprint"
    candidates = conn.execute(
        select(o.c.id, o.c.title, o.c.simhash, o.c.deadline_on)
        .where((o.c.deadline_on == deadline) if deadline else o.c.deadline_on.is_(None))
        .order_by(o.c.last_checked_at.desc())
        .limit(300)
    ).all()
    for cid, ctitle, csim, cdeadline in candidates:
        if same_opportunity(title, ctitle, sim, csim, deadline, cdeadline):
            full = conn.execute(select(o).where(o.c.id == cid)).mappings().first()
            return (dict(full) if full else None), "simhash"
    return None, None


FIELD_COLUMNS = {
    "category": "category_id",
    "organization_name": "organization_name",
    "deadline_on": "deadline_on",
    "country_code": "country_code",
    "work_mode": "work_mode",
    "amount": "amount_min_minor",
    "eligibility_raw": "eligibility_raw",
    "education_required": "education_required",
    "summary": "summary",
}


def _write_fields(conn: Connection, T: Tables, opp_id: str, raw_id: str, n: Normalized) -> None:
    values = {
        "category": n.category,
        "organization_name": n.organization,
        "deadline_on": n.deadline.isoformat() if n.deadline else None,
        "country_code": n.country_code,
        "work_mode": n.work_mode,
        "amount": (f"{n.amount.minimum}-{n.amount.maximum or ''} {n.amount.currency}" if n.amount else None),
        "eligibility_raw": n.eligibility_raw,
        "education_required": n.education_required,
        "summary": n.summary,
    }
    for name, value in values.items():
        prov = n.provenance.get(name)
        conn.execute(
            delete(T.opportunity_fields).where(
                T.opportunity_fields.c.opportunity_id == opp_id, T.opportunity_fields.c.field_name == name
            )
        )
        if value is None:
            conn.execute(
                insert(T.opportunity_fields).values(
                    opportunity_id=opp_id,
                    field_name=name,
                    value_text=None,
                    provenance="not_specified",
                    extracted_by="rules",
                )
            )
            continue
        provenance, evidence, by = prov if prov else ("inferred", None, "rules")
        extracted_by = by if by in ("adapter", "structured_data", "rules", "ai") else "rules"
        conn.execute(
            insert(T.opportunity_fields).values(
                opportunity_id=opp_id,
                field_name=name,
                value_text=str(value)[:4000],
                provenance=provenance,
                evidence_excerpt=(evidence or None) and str(evidence)[:1000],
                raw_document_id=raw_id,
                confidence=0.9 if provenance == "explicit" else 0.6,
                extracted_by=extracted_by,
            )
        )


def _write_requirements(conn: Connection, T: Tables, opp_id: str, n: Normalized) -> None:
    conn.execute(delete(T.opportunity_requirements).where(T.opportunity_requirements.c.opportunity_id == opp_id))
    for r in n.requirements:
        skill_id = None
        if r.skill_name:
            from core.text import fold

            skill_id = conn.execute(select(T.skills.c.id).where(T.skills.c.normalized == fold(r.skill_name))).scalar()
        conn.execute(
            insert(T.opportunity_requirements).values(
                opportunity_id=opp_id,
                req_type=r.req_type,
                label=r.label[:300],
                skill_id=skill_id,
                language_code=r.language_code
                if r.language_code in ("fr", "en", "es", "pt", "de", "ar", "zh", "sw")
                else None,
                min_level=r.min_level,
                is_mandatory=1,
                provenance="explicit",
                original_text=r.original_text[:1000],
            )
        )
