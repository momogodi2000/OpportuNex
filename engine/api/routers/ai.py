"""AI providers, routing, consent and usage (M14); AI is off until the user turns it on (D-15)."""

from __future__ import annotations

import asyncio
from typing import Any, Literal

from fastapi import APIRouter
from pydantic import BaseModel, Field, SecretStr

from api.deps import Active, StateDep
from services.ai_service import AIService

router = APIRouter(prefix="/ai", tags=["AI"])

Kind = Literal["openai_compatible", "mistral", "groq", "openrouter", "gemini", "anthropic", "ollama", "lmstudio"]
Purpose = Literal["ai_remote_processing", "profile_to_ai", "cv_parsing_ai"]


class EnabledIn(BaseModel):
    enabled: bool


class RoutingIn(BaseModel):
    provider_id: str | None = None


class ProviderIn(BaseModel):
    kind: Kind
    display_name: str = Field(min_length=1, max_length=80)
    model: str = Field(min_length=1, max_length=200)
    base_url: str | None = Field(default=None, max_length=300)
    # SecretStr keeps the key out of reprs, validation errors and logs.
    api_key: SecretStr | None = None
    timeout_seconds: int = Field(default=60, ge=5, le=600)
    max_retries: int = Field(default=2, ge=0, le=5)
    daily_call_cap: int | None = Field(default=None, gt=0, le=100000)


class ProviderPatch(BaseModel):
    display_name: str | None = Field(default=None, min_length=1, max_length=80)
    model: str | None = Field(default=None, min_length=1, max_length=200)
    base_url: str | None = Field(default=None, max_length=300)
    api_key: SecretStr | None = None
    enabled: bool | None = None
    timeout_seconds: int | None = Field(default=None, ge=5, le=600)
    max_retries: int | None = Field(default=None, ge=0, le=5)
    daily_call_cap: int | None = Field(default=None, gt=0, le=100000)


class OrderIn(BaseModel):
    ids: list[str] = Field(min_length=1, max_length=20)


class ConsentIn(BaseModel):
    purposes: list[Purpose] = Field(min_length=1, max_length=3)


@router.get("/settings")
def get_settings(active: Active, state: StateDep) -> dict[str, Any]:
    return AIService(active, state).settings()


@router.put("/settings")
def put_settings(body: EnabledIn, active: Active, state: StateDep) -> dict[str, Any]:
    return AIService(active, state).set_enabled(body.enabled)


@router.put("/routing/{task}")
def put_routing(task: str, body: RoutingIn, active: Active, state: StateDep) -> dict[str, Any]:
    return AIService(active, state).set_routing(task, body.provider_id)


@router.get("/providers")
def list_providers(active: Active, state: StateDep) -> dict[str, Any]:
    return {"items": AIService(active, state).list_items()}


@router.post("/providers", status_code=201)
def create_provider(body: ProviderIn, active: Active, state: StateDep) -> dict[str, Any]:
    return AIService(active, state).create(
        kind=body.kind,
        display_name=body.display_name,
        model=body.model,
        base_url=body.base_url,
        api_key=body.api_key.get_secret_value() if body.api_key else None,
        timeout_seconds=body.timeout_seconds,
        max_retries=body.max_retries,
        daily_call_cap=body.daily_call_cap,
    )


@router.put("/providers/order")
def reorder(body: OrderIn, active: Active, state: StateDep) -> dict[str, Any]:
    return {"items": AIService(active, state).reorder(body.ids)}


@router.patch("/providers/{provider_id}")
def patch_provider(provider_id: str, body: ProviderPatch, active: Active, state: StateDep) -> dict[str, Any]:
    values = body.model_dump(exclude_unset=True)
    if body.api_key is not None:
        values["api_key"] = body.api_key.get_secret_value()
    return AIService(active, state).update(provider_id, values)


@router.delete("/providers/{provider_id}", status_code=204)
def delete_provider(provider_id: str, active: Active, state: StateDep) -> None:
    AIService(active, state).delete(provider_id)


@router.post("/providers/{provider_id}/test")
async def test_provider(provider_id: str, active: Active, state: StateDep) -> dict[str, Any]:
    return await AIService(active, state).test(provider_id)


@router.post("/providers/{provider_id}/consents")
def grant_consent(provider_id: str, body: ConsentIn, active: Active, state: StateDep) -> dict[str, Any]:
    return AIService(active, state).grant(provider_id, list(body.purposes))


@router.get("/usage")
async def usage(active: Active, state: StateDep, days: int = 30) -> dict[str, Any]:
    return await asyncio.to_thread(AIService(active, state).usage, max(1, min(days, 365)))
