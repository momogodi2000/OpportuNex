"""Opportunity sheet, re-verification, feedback and matching weights (M08, M10)."""

from __future__ import annotations

import asyncio
from typing import Any, Literal

from fastapi import APIRouter
from pydantic import BaseModel, Field

from api.deps import Active, StateDep
from services.ai_tasks import analyze_opportunity, translate_opportunity
from services.matching_service import MatchingService
from services.opportunity_service import OpportunityService

router = APIRouter(tags=["Opportunities"])


class FeedbackIn(BaseModel):
    feedback: Literal["relevant", "not_relevant", "dismissed", "wrong_category", "expired_report"]
    reason: str | None = Field(default=None, max_length=500)


class LanguageIn(BaseModel):
    language: Literal["fr", "en"] = "fr"


class WeightsIn(BaseModel):
    skills: float | None = Field(default=None, ge=0, le=1)
    education: float | None = Field(default=None, ge=0, le=1)
    experience: float | None = Field(default=None, ge=0, le=1)
    location: float | None = Field(default=None, ge=0, le=1)
    language: float | None = Field(default=None, ge=0, le=1)
    objectives: float | None = Field(default=None, ge=0, le=1)
    deadline: float | None = Field(default=None, ge=0, le=1)


@router.get("/opportunities/{opportunity_id}")
def detail(opportunity_id: str, active: Active, state: StateDep) -> dict[str, Any]:
    return OpportunityService(active, state).detail(opportunity_id)


@router.post("/opportunities/{opportunity_id}/recheck")
async def recheck(opportunity_id: str, active: Active, state: StateDep) -> dict[str, Any]:
    return await OpportunityService(active, state).recheck(opportunity_id)


@router.post("/opportunities/{opportunity_id}/feedback", status_code=204)
def feedback(opportunity_id: str, body: FeedbackIn, active: Active) -> None:
    MatchingService(active).feedback(opportunity_id, body.feedback, body.reason)


@router.get("/matching/weights")
def get_weights(active: Active) -> dict[str, float]:
    return MatchingService(active).weights()


@router.put("/matching/weights")
def set_weights(body: WeightsIn, active: Active) -> dict[str, float]:
    return MatchingService(active).set_weights(body.model_dump(exclude_none=True))


@router.post("/opportunities/{opportunity_id}/analyze")
async def analyze(opportunity_id: str, body: LanguageIn, active: Active, state: StateDep) -> dict[str, Any]:
    """EF-07.01-05: AI extraction verified against the source; ``status: unavailable`` without AI."""
    result = await analyze_opportunity(active, state, opportunity_id, body.language)
    detail = await asyncio.to_thread(OpportunityService(active, state).detail, opportunity_id)
    return result | {"opportunity": detail}


@router.post("/opportunities/{opportunity_id}/translate")
async def translate(opportunity_id: str, body: LanguageIn, active: Active, state: StateDep) -> dict[str, Any]:
    """EF-07.08: on-demand translation, labelled as generated."""
    return await translate_opportunity(active, state, opportunity_id, body.language)
