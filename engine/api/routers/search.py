"""Search (M04): interpretation, runs as background jobs, results, history, local search."""

from __future__ import annotations

import asyncio
from typing import Any, Literal

from fastapi import APIRouter, Query
from pydantic import BaseModel, Field

from api.deps import Active, StateDep
from core.errors import ValidationFailed
from services.ai_tasks import interpret_query
from services.jobs import JobManager
from services.search_service import SORTS, SearchService
from services.state import EngineState

router = APIRouter(prefix="/search", tags=["Search"])


class InterpretIn(BaseModel):
    text: str = Field(min_length=1, max_length=500)
    # False keeps the rule-based interpreter even when AI is configured (e.g. consent declined).
    use_ai: bool = True


class Filters(BaseModel):
    raw: str | None = None
    categories: list[str] = Field(default_factory=list, max_length=10)
    countries: list[str] = Field(default_factory=list, max_length=30)
    languages: list[str] = Field(default_factory=list, max_length=5)
    keywords: list[str] = Field(default_factory=list, max_length=20)
    work_mode: Literal["remote", "hybrid", "onsite"] | None = None
    education: str | None = None
    experience_max_years: int | None = Field(default=None, ge=0, le=60)
    amount_min: int | None = Field(default=None, ge=0)
    amount_currency: str | None = Field(default=None, pattern=r"^[A-Z]{3}$")
    deadline_after: str | None = None
    deadline_before: str | None = None
    include_expired: bool = False


class RunIn(BaseModel):
    text: str = Field(min_length=1, max_length=500)
    filters: Filters | None = None
    workspace_id: str | None = None
    source_ids: list[str] | None = Field(default=None, max_length=100)


class SaveQueryIn(BaseModel):
    name: str | None = Field(default=None, max_length=120)


def _jobs(state: EngineState) -> JobManager:
    if state.jobs is None:
        raise RuntimeError("job manager not initialised")
    return state.jobs


@router.post("/interpret")
async def interpret(body: InterpretIn, active: Active, state: StateDep) -> dict[str, Any]:
    rules = await asyncio.to_thread(SearchService(active, state).interpret, body.text)
    if not body.use_ai:
        return rules
    return await interpret_query(active, state, body.text, rules["filters"])


async def _start(
    svc: SearchService,
    state: StateDep,
    text: str,
    filters: dict[str, Any],
    workspace_id: str | None,
    source_ids: list[str] | None,
    query_id: str | None = None,
    trigger: str = "manual",
) -> dict[str, Any]:
    prepared = await asyncio.to_thread(
        svc.prepare_run,
        text,
        filters,
        workspace_id=workspace_id,
        source_ids=source_ids,
        trigger=trigger,
        query_id=query_id,
    )
    if prepared["sources"] == 0:
        raise ValidationFailed("no enabled source matches this search", code="no_sources")
    job_id = _jobs(state).submit(svc.active, "search", {"run_id": prepared["run_id"]}, svc.runner(prepared["run_id"]))
    return prepared | {"job_id": job_id}


@router.post("/runs", status_code=202)
async def start_run(body: RunIn, active: Active, state: StateDep) -> dict[str, Any]:
    svc = SearchService(active, state)
    filters = (
        body.filters.model_dump() if body.filters else (await asyncio.to_thread(svc.interpret, body.text))["filters"]
    )
    return await _start(svc, state, body.text, filters, body.workspace_id, body.source_ids)


@router.get("/runs/compare")
def compare(active: Active, state: StateDep, a: str, b: str) -> dict[str, Any]:
    return SearchService(active, state).compare(a, b)


@router.get("/runs/{run_id}")
def get_run(run_id: str, active: Active, state: StateDep) -> dict[str, Any]:
    return SearchService(active, state).get_run(run_id)


@router.get("/runs/{run_id}/results")
def results(
    run_id: str,
    active: Active,
    state: StateDep,
    sort: str = Query(default="relevance"),
    cursor: str | None = None,
    limit: int = Query(default=30, ge=1, le=100),
    min_score: int | None = Query(default=None, ge=0, le=100),
    badge: str | None = None,
) -> dict[str, Any]:
    if sort not in SORTS:
        raise ValidationFailed("unknown sort", code="sort_invalid")
    return SearchService(active, state).results(
        run_id, sort=sort, cursor=cursor, limit=limit, min_score=min_score, badge=badge
    )


@router.post("/runs/{run_id}/cancel", status_code=204)
def cancel(run_id: str, active: Active, state: StateDep) -> None:
    SearchService(active, state).cancel(run_id)


@router.post("/runs/{run_id}/resume", status_code=202)
async def resume(run_id: str, active: Active, state: StateDep) -> dict[str, Any]:
    svc = SearchService(active, state)
    job_id, checkpoint = await asyncio.to_thread(svc.resumable, run_id)
    _jobs(state).submit(active, "search", {"run_id": run_id}, svc.runner(run_id), job_id=job_id, checkpoint=checkpoint)
    return {"run_id": run_id, "job_id": job_id}


@router.get("/history")
def history(active: Active, state: StateDep, saved: bool = False) -> dict[str, Any]:
    return {"items": SearchService(active, state).history(saved_only=saved)}


@router.delete("/history")
def clear_history(active: Active, state: StateDep, keep_saved: bool = True) -> dict[str, int]:
    return {"deleted": SearchService(active, state).clear_history(keep_saved)}


@router.put("/queries/{query_id}/save")
def save_query(query_id: str, body: SaveQueryIn, active: Active, state: StateDep) -> dict[str, Any]:
    return SearchService(active, state).save_query(query_id, body.name)


@router.post("/queries/{query_id}/rerun", status_code=202)
async def rerun(query_id: str, active: Active, state: StateDep) -> dict[str, Any]:
    svc = SearchService(active, state)
    text, filters, workspace_id = await asyncio.to_thread(svc.query_filters, query_id)
    return await _start(svc, state, text, filters, workspace_id, None, query_id=query_id, trigger="rerun")


@router.get("/suggestions")
def suggestions(active: Active, state: StateDep) -> dict[str, Any]:
    return {"items": SearchService(active, state).suggestions()}


@router.get("/local")
def local_search(
    active: Active,
    state: StateDep,
    q: str = Query(min_length=1, max_length=200),
    cursor: str | None = None,
    limit: int = Query(default=30, ge=1, le=100),
) -> dict[str, Any]:
    return SearchService(active, state).local_search(q, limit=limit, cursor=cursor)
