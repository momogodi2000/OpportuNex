"""CV import (M03)."""

from __future__ import annotations

import asyncio
from typing import Annotated, Any, Literal

from fastapi import APIRouter, File, Form, UploadFile
from pydantic import BaseModel

from api.deps import Active, StateDep
from documents.cv_parser import MAX_BYTES
from services import ai_tasks
from services.cv_service import CvService
from services.profile_service import ProfileService

router = APIRouter(prefix="/cv-imports", tags=["CV import"])


class DecisionIn(BaseModel):
    decision: Literal["accepted", "rejected", "edited"]
    payload: dict[str, Any] | None = None


@router.get("")
def list_imports(active: Active) -> dict[str, Any]:
    return {"items": CvService(active).list_items()}


@router.post("", status_code=201)
async def upload(
    active: Active,
    state: StateDep,
    file: Annotated[UploadFile, File()],
    keep_file: Annotated[bool, Form()] = False,
    use_ai: Annotated[bool, Form()] = False,
) -> dict[str, Any]:
    data = await file.read(MAX_BYTES + 1)
    svc = CvService(active)
    # Consent is checked before anything is parsed so the user is asked first (EF-14.09).
    ai_ready = use_ai and await asyncio.to_thread(ai_tasks.preflight, active, state, "cv_parsing", ai_tasks.CV_PURPOSES)
    result, text = await asyncio.to_thread(svc.upload_with_text, file.filename or "cv", data, keep_file)
    if not ai_ready:
        return result | {"ai_used": False}
    full_name = await asyncio.to_thread(lambda: ProfileService(active).get()["general"].get("full_name"))
    items = await ai_tasks.cv_items(active, state, text, full_name)
    if items is None:
        return result | {"ai_used": False}
    return await asyncio.to_thread(svc.replace_with_ai, result["id"], items) | {"ai_used": True}


@router.get("/{import_id}")
def get_import(import_id: str, active: Active) -> dict[str, Any]:
    return CvService(active).get(import_id)


@router.put("/{import_id}/items/{item_id}")
def decide(import_id: str, item_id: int, body: DecisionIn, active: Active) -> dict[str, Any]:
    return CvService(active).decide(import_id, item_id, body.decision, body.payload)


@router.post("/{import_id}/apply")
def apply(import_id: str, active: Active) -> dict[str, Any]:
    return CvService(active).apply(import_id)


@router.delete("/{import_id}/file", status_code=204)
def delete_file(import_id: str, active: Active) -> None:
    CvService(active).delete_source_file(import_id)


@router.delete("/{import_id}", status_code=204)
def discard(import_id: str, active: Active) -> None:
    CvService(active).discard(import_id)
