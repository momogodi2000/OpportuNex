"""Opportunity sheet (M10): 13 sections, provenance, re-verification, feedback."""

from __future__ import annotations

import json
from typing import Any

from sqlalchemy import desc, select, update

from collection.adapters import RawItem, extract_detail, structured_fields
from collection.http import FetchError, PoliteClient
from collection.normalize import CountryIndex, normalize
from collection.store import store_item
from core.errors import NotFound
from core.timeutil import now_iso
from services.matching_service import MatchingService
from services.opportunity_view import badges
from services.state import ActiveProfile, EngineState


class OpportunityService:
    def __init__(self, active: ActiveProfile, state: EngineState) -> None:
        self.active = active
        self.state = state
        self.T = active.tables
        self.uid = active.user_id

    def _row(self, conn: Any, opp_id: str) -> dict[str, Any]:
        row = conn.execute(select(self.T.opportunities).where(self.T.opportunities.c.id == opp_id)).mappings().first()
        if row is None:
            raise NotFound("opportunity not found", code="opportunity_not_found")
        return dict(row)

    def detail(self, opp_id: str) -> dict[str, Any]:
        T = self.T
        match = MatchingService(self.active).score_many([opp_id]).get(opp_id)
        with self.active.db.read() as conn:
            o = self._row(conn, opp_id)
            category = (
                conn.execute(
                    select(
                        T.opportunity_categories.c.code,
                        T.opportunity_categories.c.name_fr,
                        T.opportunity_categories.c.name_en,
                    ).where(T.opportunity_categories.c.id == o["category_id"])
                )
                .mappings()
                .first()
                if o["category_id"]
                else None
            )
            sources = [
                dict(r)
                for r in conn.execute(
                    select(
                        T.sources.c.id,
                        T.sources.c.name,
                        T.sources.c.is_official,
                        T.sources.c.publisher_name,
                        T.opportunity_sources.c.url,
                        T.opportunity_sources.c.is_original,
                        T.opportunity_sources.c.linked_at,
                    )
                    .join(T.sources, T.sources.c.id == T.opportunity_sources.c.source_id)
                    .where(T.opportunity_sources.c.opportunity_id == opp_id)
                    .order_by(desc(T.opportunity_sources.c.is_original))
                ).mappings()
            ]
            fields = {
                r["field_name"]: dict(r)
                for r in conn.execute(
                    select(
                        T.opportunity_fields.c.field_name,
                        T.opportunity_fields.c.value_text,
                        T.opportunity_fields.c.provenance,
                        T.opportunity_fields.c.evidence_excerpt,
                        T.opportunity_fields.c.extracted_by,
                        T.opportunity_fields.c.confidence,
                    ).where(T.opportunity_fields.c.opportunity_id == opp_id)
                ).mappings()
            }
            reqs = [
                dict(r)
                for r in conn.execute(
                    select(T.opportunity_requirements).where(T.opportunity_requirements.c.opportunity_id == opp_id)
                ).mappings()
            ]
            versions = [
                dict(r)
                | {
                    "changed_fields": json.loads(r["changed_fields"]),
                    "previous_values": json.loads(r["previous_values"]),
                }
                for r in conn.execute(
                    select(T.opportunity_versions)
                    .where(T.opportunity_versions.c.opportunity_id == opp_id)
                    .order_by(desc(T.opportunity_versions.c.detected_at))
                ).mappings()
            ]
            saved = conn.execute(
                select(T.saved_opportunities.c.id).where(
                    T.saved_opportunities.c.user_id == self.uid, T.saved_opportunities.c.opportunity_id == opp_id
                )
            ).scalar()
            checklist = (
                [
                    dict(r) | {"is_done": bool(r["is_done"])}
                    for r in conn.execute(
                        select(T.checklist_items)
                        .where(T.checklist_items.c.saved_id == saved)
                        .order_by(T.checklist_items.c.sort_order)
                    ).mappings()
                ]
                if saved
                else []
            )
        by_type: dict[str, list[dict[str, Any]]] = {}
        for r in reqs:
            by_type.setdefault(r["req_type"], []).append(
                {
                    "label": r["label"],
                    "original_text": r["original_text"],
                    "min_level": r["min_level"],
                    "language_code": r["language_code"],
                    "provenance": r["provenance"],
                }
            )
        amount = None
        if o["amount_currency"]:
            amount = {
                "min_minor": o["amount_min_minor"],
                "max_minor": o["amount_max_minor"],
                "currency": o["amount_currency"],
                "period": o["amount_period"],
                "fully_funded": o["is_fully_funded"],
            }
        return {
            "id": o["id"],
            "badges": badges(o, match),
            "overview": {
                "title": o["title"],
                "category": dict(category) if category else None,
                "summary": o["summary"],
                "description": o["description_text"],
                "location_text": o["location_text"],
                "country_code": o["country_code"],
                "work_mode": o["work_mode"],
                "language_code": o["language_code"],
                "published_on": o["published_on"],
                "target_audience": o["target_audience"],
            },
            "publisher": {
                "organization_name": o["organization_name"],
                "organization_type": o["organization_type"],
                "sources": sources,
            },
            "eligibility": {
                "clauses": (o["eligibility_raw"] or "").split("\n") if o["eligibility_raw"] else [],
                "regions": json.loads(o["eligible_regions"]) if o["eligible_regions"] else [],
            },
            "qualifications": {k: v for k, v in by_type.items() if k != "document"},
            "documents_required": by_type.get("document", []),
            "deadline": {"date": o["deadline_on"], "raw": o["deadline_raw"], "timezone": o["deadline_timezone"]},
            "financial": amount,
            "procedure": {
                "channel": o["application_channel"],
                "application_url": o["application_url"],
                "contact_public": o["contact_public"],
            },
            "official_link": o["canonical_url"],
            "verification": {
                "status": o["verification_status"],
                "last_checked_at": o["last_checked_at"],
                "last_changed_at": o["last_changed_at"],
                "analysis_method": o["analysis_method"],
                "versions": versions,
            },
            "relevance": match,
            "eligibility_gaps": {
                "gaps": (match or {}).get("gaps", []),
                "to_verify": (match or {}).get("to_verify", []),
            },
            "checklist": checklist,
            "saved_id": saved,
            "fields": fields,
            "submission_notice": "official_channel_only",
        }

    async def recheck(self, opp_id: str) -> dict[str, Any]:
        """EF-10.04: fetch the official page again; detect modification or withdrawal."""
        import asyncio

        T = self.T
        with self.active.db.read() as conn:
            o = self._row(conn, opp_id)
            source = conn.execute(select(T.sources).where(T.sources.c.id == o["primary_source_id"])).mappings().first()
            countries = CountryIndex.from_rows([dict(r) for r in conn.execute(select(T.countries)).mappings()])
            aliases = dict(
                conn.execute(
                    select(T.skill_aliases.c.alias, T.skills.c.name).join(
                        T.skills, T.skills.c.id == T.skill_aliases.c.skill_id
                    )
                ).all()
            )
        url = o["canonical_url"]
        async with PoliteClient(allow_private=self.state.settings.allow_private_network) as client:
            try:
                res = await client.get(url, use_cache=False)
            except FetchError as exc:
                gone = exc.code in ("http_404", "http_410")
                status = "withdrawn" if gone else "error"
                await asyncio.to_thread(self._set_status, opp_id, status)
                return {"status": status, "reason": exc.code, "changed_fields": []}
        text, obj = await asyncio.to_thread(extract_detail, res.body, url)
        structured = structured_fields(obj) if obj else None
        item = RawItem(url=url, title=o["title"], summary=o["summary"] or "")
        normalized = normalize(
            o["title"],
            o["summary"] or "",
            {},
            text,
            structured,
            countries,
            aliases,
            o["country_code"],
            o["language_code"],
        )
        if source is None:
            await asyncio.to_thread(self._set_status, opp_id, "verified")
            return {"status": "verified", "changed_fields": []}

        def _store() -> list[str]:
            with self.active.db.tx() as conn:
                out = store_item(
                    conn,
                    T,
                    source=dict(source),
                    scan_run_id=None,
                    item=item,
                    normalized=normalized,
                    detail_text=text,
                    structured=structured,
                )
            return out.changed_fields

        changed = await asyncio.to_thread(_store)
        status = "modified" if changed else "verified"
        await asyncio.to_thread(self._set_status, opp_id, status)
        if changed:
            await asyncio.to_thread(self._notify_change, opp_id, o["title"], changed)
        return {"status": status, "changed_fields": changed}

    def _set_status(self, opp_id: str, status: str) -> None:
        with self.active.db.tx() as conn:
            conn.execute(
                update(self.T.opportunities)
                .where(self.T.opportunities.c.id == opp_id)
                .values(verification_status=status, last_checked_at=now_iso())
            )

    def _notify_change(self, opp_id: str, title: str, changed: list[str]) -> None:
        """EF-13.03: tell the user when a tracked opportunity changes, honouring notification preferences."""
        from services.monitor_service import NotificationService

        T = self.T
        with self.active.db.tx() as conn:
            saved = conn.execute(
                select(T.saved_opportunities.c.id).where(
                    T.saved_opportunities.c.user_id == self.uid, T.saved_opportunities.c.opportunity_id == opp_id
                )
            ).first()
            if saved is None:
                return
            NotificationService(self.active, self.state).notify(
                conn,
                "opportunity_changed",
                title,
                ", ".join(changed),
                {"opportunity_id": opp_id, "saved_id": saved[0]},
            )
