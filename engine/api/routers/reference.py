"""Reference data: countries, currencies, languages, categories, objectives, skills."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Query
from sqlalchemy import func, select

from api.deps import Active
from core.text import fold

router = APIRouter(prefix="/ref", tags=["Reference"])


@router.get("/countries")
def countries(active: Active) -> dict[str, Any]:
    T = active.tables
    with active.db.read() as conn:
        rows = conn.execute(select(T.countries).order_by(T.countries.c.name_fr)).mappings().all()
    return {"items": [dict(r) | {"is_cemac": bool(r["is_cemac"])} for r in rows]}


@router.get("/currencies")
def currencies(active: Active) -> dict[str, Any]:
    T = active.tables
    with active.db.read() as conn:
        rows = conn.execute(select(T.currencies).order_by(T.currencies.c.code)).mappings().all()
    return {"items": [dict(r) for r in rows]}


@router.get("/languages")
def languages(active: Active) -> dict[str, Any]:
    T = active.tables
    with active.db.read() as conn:
        rows = conn.execute(select(T.languages).order_by(T.languages.c.name_fr)).mappings().all()
    return {"items": [dict(r) for r in rows]}


@router.get("/categories")
def categories(active: Active) -> dict[str, Any]:
    T = active.tables
    with active.db.read() as conn:
        rows = [
            dict(r)
            for r in conn.execute(
                select(T.opportunity_categories).order_by(T.opportunity_categories.c.sort_order)
            ).mappings()
        ]
    roots = [r | {"children": []} for r in rows if r["parent_id"] is None]
    by_id = {r["id"]: r for r in roots}
    for r in rows:
        if r["parent_id"] is not None and r["parent_id"] in by_id:
            by_id[r["parent_id"]]["children"].append(r)
    return {"items": roots}


@router.get("/objectives")
def objectives(active: Active) -> dict[str, Any]:
    T = active.tables
    with active.db.read() as conn:
        rows = conn.execute(select(T.objectives).order_by(T.objectives.c.id)).mappings().all()
    return {"items": [dict(r) for r in rows]}


@router.get("/skills")
def skills(
    active: Active, q: str = Query(default="", max_length=60), limit: int = Query(default=20, ge=1, le=100)
) -> dict[str, Any]:
    T = active.tables
    needle = fold(q)
    stmt = select(T.skills.c.id, T.skills.c.name, T.skills.c.kind).distinct()
    if needle:
        stmt = stmt.join(T.skill_aliases, T.skill_aliases.c.skill_id == T.skills.c.id).where(
            T.skill_aliases.c.alias.like(f"%{needle}%")
        )
    stmt = stmt.order_by(func.length(T.skills.c.name), T.skills.c.name).limit(limit)
    with active.db.read() as conn:
        return {"items": [dict(r) for r in conn.execute(stmt).mappings()]}
