"""Sources (M06): catalogue, health, custom sources."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter
from pydantic import BaseModel, Field

from api.deps import Active, StateDep
from services.source_service import SourceService, health_summary

router = APIRouter(prefix="/sources", tags=["Sources"])


class SourceUpdateIn(BaseModel):
    enabled: bool | None = None
    min_interval_minutes: int | None = Field(default=None, ge=60, le=60 * 24 * 30)
    categories: list[str] | None = Field(default=None, max_length=15)


class SourceAddIn(BaseModel):
    url: str = Field(min_length=10, max_length=500)
    name: str | None = Field(default=None, max_length=120)
    categories: list[str] = Field(default_factory=list, max_length=15)


@router.get("")
def list_sources(active: Active, state: StateDep, category: str | None = None, q: str | None = None) -> dict[str, Any]:
    svc = SourceService(active, state)
    svc.sync()
    return {"items": svc.list_items(category=category, q=q)}


@router.get("/health")
def health(active: Active) -> dict[str, Any]:
    return health_summary(active)


@router.post("", status_code=201)
async def add_source(body: SourceAddIn, active: Active, state: StateDep) -> dict[str, Any]:
    return await SourceService(active, state).discover_and_add(body.url, body.name, body.categories)


@router.patch("/{source_id}")
def update_source(source_id: str, body: SourceUpdateIn, active: Active, state: StateDep) -> dict[str, Any]:
    return SourceService(active, state).update(
        source_id, enabled=body.enabled, min_interval_minutes=body.min_interval_minutes, category_codes=body.categories
    )


@router.delete("/{source_id}", status_code=204)
def delete_source(source_id: str, active: Active, state: StateDep) -> None:
    SourceService(active, state).delete(source_id)


@router.get("/{source_id}/runs")
def source_runs(source_id: str, active: Active, state: StateDep) -> dict[str, Any]:
    return {"items": SourceService(active, state).runs(source_id)}
