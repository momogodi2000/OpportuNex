"""Shared presentation of opportunities (cards, badges) for search, saved items and dashboards."""

from __future__ import annotations

from datetime import date
from typing import Any

from sqlalchemy import Connection, func, select

from core.timeutil import parse_date
from persistence.database import Tables

SOON_DAYS = 7


def badges(opp: dict[str, Any], match: dict[str, Any] | None, today: date | None = None) -> list[str]:
    """EF-09.06: verified, AI-generated, expired, deadline soon, eligibility uncertain."""
    today = today or date.today()
    out: list[str] = []
    if opp.get("verification_status") == "verified":
        out.append("verified")
    if opp.get("verification_status") == "modified":
        out.append("modified")
    if opp.get("analysis_method") in ("ai", "mixed"):
        out.append("ai_generated")
    deadline = parse_date(opp.get("deadline_on"))
    if opp.get("verification_status") == "expired" or (deadline and deadline < today):
        out.append("expired")
    elif deadline and (deadline - today).days <= SOON_DAYS:
        out.append("deadline_soon")
    if match and match.get("eligibility") in ("uncertain", "unlikely"):
        out.append("eligibility_uncertain")
    if not deadline:
        out.append("deadline_unknown")
    return out


def card(
    conn: Connection, T: Tables, opp: dict[str, Any], match: dict[str, Any] | None, saved_ids: set[str] | None = None
) -> dict[str, Any]:
    category = None
    if opp.get("category_id"):
        category = conn.execute(
            select(T.opportunity_categories.c.code).where(T.opportunity_categories.c.id == opp["category_id"])
        ).scalar()
    sources = conn.execute(
        select(func.count())
        .select_from(T.opportunity_sources)
        .where(T.opportunity_sources.c.opportunity_id == opp["id"])
    ).scalar()
    deadline = parse_date(opp.get("deadline_on"))
    return {
        "id": opp["id"],
        "title": opp["title"],
        "organization_name": opp.get("organization_name"),
        "category": category,
        "summary": opp.get("summary"),
        "country_code": opp.get("country_code"),
        "location_text": opp.get("location_text"),
        "work_mode": opp.get("work_mode"),
        "deadline_on": opp.get("deadline_on"),
        "days_left": (deadline - date.today()).days if deadline else None,
        "published_on": opp.get("published_on"),
        "amount": (
            {
                "min_minor": opp.get("amount_min_minor"),
                "max_minor": opp.get("amount_max_minor"),
                "currency": opp.get("amount_currency"),
            }
            if opp.get("amount_currency")
            else None
        ),
        "canonical_url": opp.get("canonical_url"),
        "verification_status": opp.get("verification_status"),
        "sources_count": int(sources or 0),
        "score": match.get("score") if match else None,
        "eligibility": match.get("eligibility") if match else None,
        "badges": badges(opp, match),
        "is_saved": opp["id"] in (saved_ids or set()),
    }
