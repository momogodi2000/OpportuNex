"""CV import (M03)."""

from __future__ import annotations

import asyncio
from typing import Annotated, Any, Literal

from fastapi import APIRouter, File, Form, UploadFile
from pydantic import BaseModel

from api.deps import Active
from documents.cv_parser import MAX_BYTES
from services.cv_service import CvService

router = APIRouter(prefix="/cv-imports", tags=["CV import"])


class DecisionIn(BaseModel):
    decision: Literal["accepted", "rejected", "edited"]
    payload: dict[str, Any] | None = None


@router.get("")
def list_imports(active: Active) -> dict[str, Any]:
    return {"items": CvService(active).list_items()}


@router.post("", status_code=201)
async def upload(
    active: Active, file: Annotated[UploadFile, File()], keep_file: Annotated[bool, Form()] = False
) -> dict[str, Any]:
    data = await file.read(MAX_BYTES + 1)
    return await asyncio.to_thread(CvService(active).upload, file.filename or "cv", data, keep_file)


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
