"""Synchronised record kinds (D-32): how each is read from local tables and written back.

A record is a flat dict of fields; list fields hold child rows whose integer keys differ between
devices (links, tags, checklist...). Opportunities are referenced by canonical URL, sources by base
URL, organisations by their server id, skills and tags by name — never by local row ids.
"""

from __future__ import annotations

import json
from collections.abc import Callable
from typing import Any

from sqlalchemy import Connection, delete, insert, select, update
from sqlalchemy.exc import IntegrityError

from collection.dedup import fingerprint, normalize_url
from core.ids import uuid7
from core.timeutil import now_iso
from persistence.database import Tables

Data = dict[str, Any]

# Fields where two concurrent edits must not silently overwrite each other (manual choice, D-31).
TEXT_FIELDS: dict[str, set[str]] = {
    "profile": {"bio", "summary_text"},
    "experience": {"description"},
    "project": {"description"},
    "event": {"notes"},
    "note": {"body"},
    "workspace": {"description"},
    "ws_note": {"body"},
}
# Append-only lists merged by union (key function per field).
UNION_FIELDS: dict[str, dict[str, Callable[[Data], Any]]] = {
    "application": {"history": lambda h: (h.get("to_status"), h.get("changed_at"))},
    "document": {"versions": lambda v: v.get("version")},
}
# Order in which a pulled batch is applied (parents before children).
APPLY_ORDER = [
    "org",
    "profile",
    "education",
    "experience",
    "certification",
    "project",
    "workspace",
    "ws_note",
    "query",
    "monitor",
    "saved",
    "application",
    "event",
    "note",
    "document",
]

GENERAL = (
    "full_name",
    "country_code",
    "city",
    "professional_status",
    "current_occupation",
    "experience_years",
    "highest_education",
    "work_mode_pref",
    "willing_to_relocate",
    "contact_phone",
    "bio",
    "summary_text",
    "summary_approved",
)
WEIGHTS = ("w_skills", "w_education", "w_experience", "w_location", "w_language", "w_objectives", "w_deadline")
SIMPLE: dict[str, tuple[str, tuple[str, ...]]] = {
    "education": (
        "education_records",
        (
            "level",
            "field_of_study",
            "institution",
            "country_code",
            "start_date",
            "end_date",
            "is_ongoing",
            "grade",
            "achievements",
            "source",
        ),
    ),
    "experience": (
        "work_experiences",
        (
            "job_title",
            "employer",
            "employment_type",
            "country_code",
            "city",
            "start_date",
            "end_date",
            "is_current",
            "description",
            "source",
        ),
    ),
    "certification": ("certifications", ("name", "issuer", "obtained_on", "expires_on", "credential_url", "source")),
    "project": (
        "project_profiles",
        (
            "title",
            "description",
            "stage",
            "funding_need_minor",
            "funding_min_minor",
            "funding_max_minor",
            "currency_code",
            "operating_country",
            "beneficiaries",
            "legal_status",
            "existing_resources",
            "timeline_months",
            "category_id",
        ),
    ),
}
ORG_FIELDS = (
    "name",
    "org_type",
    "legal_status",
    "registration_no",
    "country_code",
    "sector",
    "description",
    "annual_budget_band",
    "website",
)


class SkipRecord(Exception):
    """The record cannot be applied on this device (reason in ``code``); it is reported as a conflict."""

    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


def _rows(conn: Connection, stmt: Any) -> list[Data]:
    return [dict(r) for r in conn.execute(stmt).mappings()]


def _one(conn: Connection, stmt: Any) -> Data | None:
    r = conn.execute(stmt).mappings().first()
    return dict(r) if r else None


def _exists(conn: Connection, table: Any, ident: str | None) -> str | None:
    if not ident:
        return None
    return ident if conn.execute(select(table.c.id).where(table.c.id == ident)).first() else None


# ------------------------------------------------------------------ references
def org_remote(conn: Connection, T: Tables, local_id: str | None) -> str | None:
    if not local_id:
        return None
    return conn.execute(select(T.organizations.c.remote_id).where(T.organizations.c.id == local_id)).scalar()


def org_local(conn: Connection, T: Tables, remote_id: str | None) -> str | None:
    if not remote_id:
        return None
    return conn.execute(select(T.organizations.c.id).where(T.organizations.c.remote_id == remote_id)).scalar()


def opportunity_ref(conn: Connection, T: Tables, opp_id: str) -> Data:
    o = _one(conn, select(T.opportunities).where(T.opportunities.c.id == opp_id)) or {}
    cat = None
    if o.get("category_id"):
        cat = conn.execute(
            select(T.opportunity_categories.c.code).where(T.opportunity_categories.c.id == o["category_id"])
        ).scalar()
    return {
        k: o.get(k)
        for k in (
            "canonical_url",
            "title",
            "organization_name",
            "deadline_on",
            "summary",
            "country_code",
            "application_url",
        )
    } | {"category": cat}


def ensure_opportunity(conn: Connection, T: Tables, ref: Data) -> str:
    """Local opportunity for a reference: a minimal row, collected again later if needed (arch §10.1-5)."""
    url = str(ref.get("canonical_url") or "")
    if not url:
        raise SkipRecord("opportunity_ref_missing")
    norm = normalize_url(url)
    found = conn.execute(select(T.opportunities.c.id).where(T.opportunities.c.normalized_url == norm)).scalar()
    if found:
        return str(found)
    from datetime import date

    deadline = None
    if ref.get("deadline_on"):
        try:
            deadline = date.fromisoformat(str(ref["deadline_on"]))
        except ValueError:
            deadline = None
    cat = None
    if ref.get("category"):
        cat = conn.execute(
            select(T.opportunity_categories.c.id).where(T.opportunity_categories.c.code == ref["category"])
        ).scalar()
    oid = uuid7()
    conn.execute(
        insert(T.opportunities).values(
            id=oid,
            canonical_url=url,
            normalized_url=norm,
            dedup_fingerprint=fingerprint(str(ref.get("title") or url), ref.get("organization_name"), deadline),
            title=str(ref.get("title") or url),
            organization_name=ref.get("organization_name"),
            summary=ref.get("summary"),
            deadline_on=ref.get("deadline_on"),
            country_code=ref.get("country_code"),
            application_url=ref.get("application_url"),
            category_id=cat,
        )
    )
    return oid


# ---------------------------------------------------------------- serialise
def serialize(conn: Connection, T: Tables, uid: str, kind: str, ident: str) -> Data | None:
    """Current local state of a record, or None if it no longer exists (or is not shareable)."""
    if kind == "profile":
        g = _one(conn, select(T.user_profiles).where(T.user_profiles.c.user_id == uid)) or {}
        w = _one(conn, select(T.matching_weights).where(T.matching_weights.c.user_id == uid)) or {}
        data: Data = {k: g.get(k) for k in GENERAL}
        data["weights"] = {k: w.get(k) for k in WEIGHTS}
        data["locations"] = [
            {k: r[k] for k in ("country_code", "region_label", "city", "priority")}
            for r in _rows(
                conn,
                select(T.profile_preferred_locations)
                .where(T.profile_preferred_locations.c.user_id == uid)
                .order_by(T.profile_preferred_locations.c.priority, T.profile_preferred_locations.c.id),
            )
        ]
        data["links"] = sorted(
            (
                {"kind": r["kind"], "url": r["url"]}
                for r in _rows(conn, select(T.profile_links).where(T.profile_links.c.user_id == uid))
            ),
            key=lambda x: (x["kind"], x["url"]),
        )
        data["custom_objectives"] = sorted(
            r["label"]
            for r in _rows(conn, select(T.user_custom_objectives).where(T.user_custom_objectives.c.user_id == uid))
        )
        data["skills"] = sorted(
            (
                {"name": r["name"], "level": r["level"], "years": r["years"], "is_primary": r["is_primary"]}
                for r in _rows(
                    conn,
                    select(T.user_skills, T.skills.c.name)
                    .join(T.skills, T.skills.c.id == T.user_skills.c.skill_id)
                    .where(T.user_skills.c.user_id == uid),
                )
            ),
            key=lambda x: str(x["name"]),
        )
        data["languages"] = sorted(
            (
                {"language_code": r["language_code"], "cefr_level": r["cefr_level"]}
                for r in _rows(conn, select(T.user_languages).where(T.user_languages.c.user_id == uid))
            ),
            key=lambda x: str(x["language_code"]),
        )
        data["objectives"] = sorted(
            (
                {"objective_id": r["objective_id"], "priority": r["priority"]}
                for r in _rows(conn, select(T.user_objectives).where(T.user_objectives.c.user_id == uid))
            ),
            key=lambda x: int(x["objective_id"]),
        )
        return data
    if kind in SIMPLE:
        table_name, cols = SIMPLE[kind]
        tbl = T.metadata.tables[table_name]
        row = _one(conn, select(tbl).where(tbl.c.id == ident, tbl.c.user_id == uid))
        return {k: row[k] for k in cols} if row else None
    if kind == "saved":
        s = _one(conn, select(T.saved_opportunities).where(T.saved_opportunities.c.id == ident))
        if s is None:
            return None
        tags = sorted(
            r["name"]
            for r in _rows(
                conn,
                select(T.tags.c.name)
                .join(T.saved_opportunity_tags, T.saved_opportunity_tags.c.tag_id == T.tags.c.id)
                .where(T.saved_opportunity_tags.c.saved_id == ident),
            )
        )
        checklist = [
            {k: r[k] for k in ("label", "origin", "is_done", "sort_order", "done_at")}
            for r in _rows(
                conn,
                select(T.checklist_items)
                .where(T.checklist_items.c.saved_id == ident)
                .order_by(T.checklist_items.c.sort_order, T.checklist_items.c.id),
            )
        ]
        return {
            **{
                k: s[k]
                for k in (
                    "priority",
                    "interest",
                    "ineligible_reason",
                    "personal_deadline",
                    "archived",
                    "saved_at",
                    "workspace_id",
                )
            },
            "organization": org_remote(conn, T, s["organization_id"]),
            "opportunity": opportunity_ref(conn, T, s["opportunity_id"]),
            "tags": tags,
            "checklist": checklist,
        }
    if kind == "application":
        a = _one(conn, select(T.applications).where(T.applications.c.id == ident))
        if a is None:
            return None
        history = [
            {k: r[k] for k in ("from_status", "to_status", "note", "changed_at")}
            for r in _rows(
                conn,
                select(T.application_status_history)
                .where(T.application_status_history.c.application_id == ident)
                .order_by(T.application_status_history.c.changed_at),
            )
        ]
        return {
            k: a[k]
            for k in (
                "saved_id",
                "status",
                "submitted_on",
                "submission_ref",
                "outcome_on",
                "outcome_note",
                "created_at",
            )
        } | {"history": history}
    if kind == "event":
        e = _one(conn, select(T.application_events).where(T.application_events.c.id == ident))
        return (
            {
                k: e[k]
                for k in (
                    "application_id",
                    "event_type",
                    "title",
                    "scheduled_at",
                    "location",
                    "contact_name",
                    "notes",
                    "done",
                    "created_at",
                )
            }
            if e
            else None
        )
    if kind == "note":
        n = _one(conn, select(T.application_notes).where(T.application_notes.c.id == ident))
        return {k: n[k] for k in ("saved_id", "body", "created_at")} if n else None
    if kind == "document":
        d = _one(conn, select(T.generated_documents).where(T.generated_documents.c.id == ident))
        if d is None:
            return None
        versions = [
            {k: r[k] for k in ("version", "content", "origin", "integrity_flags", "created_at")}
            for r in _rows(
                conn,
                select(T.generated_document_versions)
                .where(T.generated_document_versions.c.document_id == ident)
                .order_by(T.generated_document_versions.c.version),
            )
        ]
        return {k: d[k] for k in ("saved_id", "doc_type", "title", "language_code", "created_at")} | {
            "versions": versions
        }
    if kind == "workspace":
        ws = _one(conn, select(T.research_workspaces).where(T.research_workspaces.c.id == ident))
        if ws is None:
            return None
        opps = sorted(
            (
                opportunity_ref(conn, T, r["opportunity_id"])
                for r in _rows(
                    conn, select(T.workspace_opportunities).where(T.workspace_opportunities.c.workspace_id == ident)
                )
            ),
            key=lambda x: str(x["canonical_url"]),
        )
        return {k: ws[k] for k in ("name", "description", "template_code", "color", "archived", "created_at")} | {
            "organization": org_remote(conn, T, ws["organization_id"]),
            "opportunities": opps,
        }
    if kind == "ws_note":
        n = _one(conn, select(T.workspace_notes).where(T.workspace_notes.c.id == ident))
        return {k: n[k] for k in ("workspace_id", "body", "created_at")} if n else None
    if kind == "query":
        q = _one(conn, select(T.search_queries).where(T.search_queries.c.id == ident, T.search_queries.c.is_saved == 1))
        return (
            {
                k: q[k]
                for k in (
                    "workspace_id",
                    "raw_text",
                    "language_code",
                    "interpreted_filters",
                    "final_filters",
                    "interpreter",
                    "saved_name",
                    "created_at",
                )
            }
            if q
            else None
        )
    if kind == "monitor":
        m = _one(conn, select(T.monitors).where(T.monitors.c.id == ident))
        if m is None:
            return None
        sources = sorted(
            r["base_url"]
            for r in _rows(
                conn,
                select(T.sources.c.base_url)
                .join(T.monitor_sources, T.monitor_sources.c.source_id == T.sources.c.id)
                .where(T.monitor_sources.c.monitor_id == ident),
            )
        )
        return {
            k: m[k]
            for k in (
                "workspace_id",
                "query_id",
                "name",
                "filters",
                "schedule_kind",
                "schedule_expr",
                "min_score",
                "execution_site",
                "enabled",
                "created_at",
            )
        } | {"sources": sources}
    if kind == "org":
        o = _one(conn, select(T.organizations).where(T.organizations.c.remote_id == ident))
        return {k: o[k] for k in ORG_FIELDS} if o else None
    raise ValueError(f"unknown kind {kind}")


def scope_of(conn: Connection, T: Tables, kind: str, ident: str, data: Data | None) -> str:
    """``user`` or ``org:<server id>`` — shared records are encrypted with the organisation key (D-33)."""
    remote: str | None = None
    if kind == "org":
        remote = ident
    elif kind in ("saved", "workspace") and data:
        remote = data.get("organization")
    elif kind in ("application", "note", "document") and data:
        remote = _saved_org(conn, T, data.get("saved_id"))
    elif kind == "event" and data:
        saved = conn.execute(
            select(T.applications.c.saved_id).where(T.applications.c.id == data.get("application_id"))
        ).scalar()
        remote = _saved_org(conn, T, saved)
    elif kind == "ws_note" and data:
        org = conn.execute(
            select(T.research_workspaces.c.organization_id).where(
                T.research_workspaces.c.id == data.get("workspace_id")
            )
        ).scalar()
        remote = org_remote(conn, T, org)
    return f"org:{remote}" if remote else "user"


def _saved_org(conn: Connection, T: Tables, saved_id: str | None) -> str | None:
    if not saved_id:
        return None
    org = conn.execute(
        select(T.saved_opportunities.c.organization_id).where(T.saved_opportunities.c.id == saved_id)
    ).scalar()
    return org_remote(conn, T, org)


# -------------------------------------------------------------------- apply
def _upsert(conn: Connection, table: Any, ident: str, values: Data) -> None:
    if conn.execute(select(table.c.id).where(table.c.id == ident)).first():
        conn.execute(update(table).where(table.c.id == ident).values(**values))
    else:
        conn.execute(insert(table).values(id=ident, **values))


def apply(conn: Connection, T: Tables, uid: str, kind: str, ident: str, data: Data) -> None:
    """Write a record received from another device (called under the sync guard)."""
    if kind == "profile":
        from services.profile_service import resolve_skill

        conn.execute(
            update(T.user_profiles)
            .where(T.user_profiles.c.user_id == uid)
            .values(**{k: data.get(k) for k in GENERAL if k in data})
        )
        if data.get("weights"):
            conn.execute(
                update(T.matching_weights)
                .where(T.matching_weights.c.user_id == uid)
                .values(**{k: v for k, v in data["weights"].items() if k in WEIGHTS and v is not None})
            )
        for table, field, build in (
            (T.profile_preferred_locations, "locations", lambda x: x),
            (T.profile_links, "links", lambda x: x),
            (T.user_custom_objectives, "custom_objectives", lambda x: {"label": x}),
            (T.user_languages, "languages", lambda x: x),
            (T.user_objectives, "objectives", lambda x: x),
        ):
            if field in data:
                conn.execute(delete(table).where(table.c.user_id == uid))
                for item in data[field] or []:
                    conn.execute(insert(table).values(user_id=uid, **build(item)))
        if "skills" in data:
            conn.execute(delete(T.user_skills).where(T.user_skills.c.user_id == uid))
            for s in data["skills"] or []:
                conn.execute(
                    insert(T.user_skills).values(
                        user_id=uid,
                        skill_id=resolve_skill(conn, T, str(s["name"])),
                        level=s.get("level"),
                        years=s.get("years"),
                        is_primary=s.get("is_primary") or 0,
                    )
                )
        return
    if kind in SIMPLE:
        table_name, cols = SIMPLE[kind]
        _upsert(conn, T.metadata.tables[table_name], ident, {k: data.get(k) for k in cols} | {"user_id": uid})
        return
    if kind == "saved":
        opp = ensure_opportunity(conn, T, data.get("opportunity") or {})
        clash = conn.execute(
            select(T.saved_opportunities.c.id).where(
                T.saved_opportunities.c.user_id == uid,
                T.saved_opportunities.c.opportunity_id == opp,
                T.saved_opportunities.c.id != ident,
            )
        ).scalar()
        if clash:
            raise SkipRecord("saved_twice")  # the same opportunity was saved separately on two devices
        values: Data = {
            k: data.get(k)
            for k in ("priority", "interest", "ineligible_reason", "personal_deadline", "archived", "saved_at")
            if k in data
        }
        values |= {
            "user_id": uid,
            "opportunity_id": opp,
            "workspace_id": _exists(conn, T.research_workspaces, data.get("workspace_id")),
            "organization_id": org_local(conn, T, data.get("organization")),
            "updated_at": now_iso(),
        }
        _upsert(conn, T.saved_opportunities, ident, values)
        if "tags" in data:
            conn.execute(delete(T.saved_opportunity_tags).where(T.saved_opportunity_tags.c.saved_id == ident))
            for name in data["tags"] or []:
                tid = conn.execute(select(T.tags.c.id).where(T.tags.c.user_id == uid, T.tags.c.name == name)).scalar()
                if tid is None:
                    tid = conn.execute(insert(T.tags).values(user_id=uid, name=name)).inserted_primary_key[0]  # type: ignore[index]
                conn.execute(insert(T.saved_opportunity_tags).values(saved_id=ident, tag_id=tid))
        if "checklist" in data:
            conn.execute(delete(T.checklist_items).where(T.checklist_items.c.saved_id == ident))
            for item in data["checklist"] or []:
                conn.execute(insert(T.checklist_items).values(saved_id=ident, **item))
        return
    if kind == "application":
        if not _exists(conn, T.saved_opportunities, data.get("saved_id")):
            raise SkipRecord("parent_missing")
        values = {
            k: data.get(k)
            for k in (
                "saved_id",
                "status",
                "submitted_on",
                "submission_ref",
                "outcome_on",
                "outcome_note",
                "created_at",
            )
            if k in data
        }
        hist = T.application_status_history
        before = [
            {k: r[k] for k in ("from_status", "to_status", "note", "changed_at")}
            for r in _rows(conn, select(hist).where(hist.c.application_id == ident))
        ]
        _upsert(conn, T.applications, ident, values | {"user_id": uid, "updated_at": now_iso()})
        # The schema's own triggers log a status change with a local time when the row is written:
        # the history is rebuilt as the union of this device's entries and the received ones.
        union: dict[tuple[Any, Any], Data] = {(h["to_status"], h["changed_at"]): h for h in before}
        for h in data.get("history") or []:
            union.setdefault((h.get("to_status"), h.get("changed_at")), h)
        conn.execute(delete(hist).where(hist.c.application_id == ident))
        for h in sorted(union.values(), key=lambda x: str(x.get("changed_at"))):
            conn.execute(insert(hist).values(application_id=ident, changed_by=uid, **h))
        return
    if kind == "event":
        if not _exists(conn, T.applications, data.get("application_id")):
            raise SkipRecord("parent_missing")
        _upsert(
            conn,
            T.application_events,
            ident,
            {
                k: data.get(k)
                for k in (
                    "application_id",
                    "event_type",
                    "title",
                    "scheduled_at",
                    "location",
                    "contact_name",
                    "notes",
                    "done",
                    "created_at",
                )
                if k in data
            },
        )
        return
    if kind == "note":
        if not _exists(conn, T.saved_opportunities, data.get("saved_id")):
            raise SkipRecord("parent_missing")
        _upsert(
            conn,
            T.application_notes,
            ident,
            {
                "saved_id": data["saved_id"],
                "author_id": uid,
                "body": data.get("body") or "",
                "created_at": data.get("created_at") or now_iso(),
                "updated_at": now_iso(),
            },
        )
        return
    if kind == "document":
        if not _exists(conn, T.saved_opportunities, data.get("saved_id")):
            raise SkipRecord("parent_missing")
        versions = data.get("versions") or []
        current = max((int(v["version"]) for v in versions), default=1)
        _upsert(
            conn,
            T.generated_documents,
            ident,
            {k: data.get(k) for k in ("saved_id", "doc_type", "title", "language_code", "created_at") if k in data}
            | {"user_id": uid, "current_version": current, "updated_at": now_iso()},
        )
        have = {
            r[0]
            for r in conn.execute(
                select(T.generated_document_versions.c.version).where(
                    T.generated_document_versions.c.document_id == ident
                )
            )
        }
        for v in versions:
            if int(v["version"]) not in have:
                integrity = v.get("integrity_flags")
                conn.execute(
                    insert(T.generated_document_versions).values(
                        document_id=ident,
                        version=v["version"],
                        content=v["content"],
                        origin=v.get("origin") or "user_edit",
                        integrity_flags=integrity
                        if integrity is None or isinstance(integrity, str)
                        else json.dumps(integrity),
                        created_at=v.get("created_at") or now_iso(),
                    )
                )
        return
    if kind == "workspace":
        values = {
            k: data.get(k)
            for k in ("name", "description", "template_code", "color", "archived", "created_at")
            if k in data
        }
        values |= {
            "user_id": uid,
            "organization_id": org_local(conn, T, data.get("organization")),
            "updated_at": now_iso(),
        }
        try:
            with conn.begin_nested():
                _upsert(conn, T.research_workspaces, ident, values)
        except IntegrityError:
            # Same name already used here (names are unique per user): keep both, told apart by a suffix.
            values["name"] = f"{values.get('name')} ({ident[-4:]})"
            _upsert(conn, T.research_workspaces, ident, values)
        if "opportunities" in data:
            conn.execute(delete(T.workspace_opportunities).where(T.workspace_opportunities.c.workspace_id == ident))
            for ref in data["opportunities"] or []:
                conn.execute(
                    insert(T.workspace_opportunities).values(
                        workspace_id=ident, opportunity_id=ensure_opportunity(conn, T, ref)
                    )
                )
        return
    if kind == "ws_note":
        if not _exists(conn, T.research_workspaces, data.get("workspace_id")):
            raise SkipRecord("parent_missing")
        _upsert(
            conn,
            T.workspace_notes,
            ident,
            {
                "workspace_id": data["workspace_id"],
                "author_id": uid,
                "body": data.get("body") or "",
                "created_at": data.get("created_at") or now_iso(),
                "updated_at": now_iso(),
            },
        )
        return
    if kind == "query":
        values = {
            k: data.get(k)
            for k in (
                "raw_text",
                "language_code",
                "interpreted_filters",
                "final_filters",
                "interpreter",
                "saved_name",
                "created_at",
            )
            if k in data
        }
        values |= {
            "user_id": uid,
            "is_saved": 1,
            "workspace_id": _exists(conn, T.research_workspaces, data.get("workspace_id")),
        }
        _upsert(conn, T.search_queries, ident, values)
        return
    if kind == "monitor":
        from core.timeutil import iso, utcnow
        from services.monitor_service import next_run

        values = {
            k: data.get(k)
            for k in (
                "name",
                "filters",
                "schedule_kind",
                "schedule_expr",
                "min_score",
                "execution_site",
                "enabled",
                "created_at",
            )
            if k in data
        }
        values |= {
            "user_id": uid,
            "workspace_id": _exists(conn, T.research_workspaces, data.get("workspace_id")),
            "query_id": _exists(conn, T.search_queries, data.get("query_id")),
            "updated_at": now_iso(),
            "next_run_at": iso(next_run(str(data["schedule_kind"]), str(data["schedule_expr"]), utcnow())),
        }
        _upsert(conn, T.monitors, ident, values)
        if "sources" in data:
            conn.execute(delete(T.monitor_sources).where(T.monitor_sources.c.monitor_id == ident))
            for url in data["sources"] or []:
                sid = conn.execute(select(T.sources.c.id).where(T.sources.c.base_url == url)).scalar()
                if sid:  # a custom source of another device is not recreated here
                    conn.execute(insert(T.monitor_sources).values(monitor_id=ident, source_id=sid))
        return
    if kind == "org":
        local = org_local(conn, T, ident)
        values = {k: data.get(k) for k in ORG_FIELDS if k in data}
        if local:
            conn.execute(
                update(T.organizations).where(T.organizations.c.id == local).values(**values, updated_at=now_iso())
            )
        else:
            conn.execute(insert(T.organizations).values(id=uuid7(), remote_id=ident, created_by=uid, **values))
        return
    raise ValueError(f"unknown kind {kind}")


def remove(conn: Connection, T: Tables, uid: str, kind: str, ident: str) -> None:
    """Delete a record removed on another device (children cascade through foreign keys)."""
    table = {
        "education": T.education_records,
        "experience": T.work_experiences,
        "certification": T.certifications,
        "project": T.project_profiles,
        "saved": T.saved_opportunities,
        "application": T.applications,
        "event": T.application_events,
        "note": T.application_notes,
        "document": T.generated_documents,
        "workspace": T.research_workspaces,
        "ws_note": T.workspace_notes,
        "query": T.search_queries,
        "monitor": T.monitors,
    }.get(kind)
    if table is not None:
        conn.execute(delete(table).where(table.c.id == ident))


def all_records(conn: Connection, T: Tables, uid: str) -> list[tuple[str, str]]:
    """Every local record, used to send a full snapshot when sync is first linked."""
    out: list[tuple[str, str]] = [("profile", "profile")]
    for kind, (table_name, _cols) in SIMPLE.items():
        tbl = T.metadata.tables[table_name]
        out += [(kind, r[0]) for r in conn.execute(select(tbl.c.id).where(tbl.c.user_id == uid))]
    for kind, table, cond in (
        ("workspace", T.research_workspaces, T.research_workspaces.c.user_id == uid),
        ("ws_note", T.workspace_notes, None),
        ("query", T.search_queries, (T.search_queries.c.user_id == uid) & (T.search_queries.c.is_saved == 1)),
        ("monitor", T.monitors, T.monitors.c.user_id == uid),
        ("saved", T.saved_opportunities, T.saved_opportunities.c.user_id == uid),
        ("application", T.applications, T.applications.c.user_id == uid),
        ("event", T.application_events, None),
        ("note", T.application_notes, None),
        ("document", T.generated_documents, T.generated_documents.c.user_id == uid),
    ):
        stmt = select(table.c.id) if cond is None else select(table.c.id).where(cond)
        out += [(kind, r[0]) for r in conn.execute(stmt)]
    return out
