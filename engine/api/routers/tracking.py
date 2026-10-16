"""Saved opportunities, applications, checklist, notes, documents, calendar (M12, M10)."""

from __future__ import annotations

import asyncio
from typing import Annotated, Any, Literal

from fastapi import APIRouter, File, Form, Query, Response, UploadFile
from pydantic import BaseModel, Field

from api.deps import Active, StateDep
from api.http_utils import attachment
from services import ai_tasks
from services.document_service import DocumentService
from services.profile_service import ProfileService
from services.tracking_service import MAX_ATTACHMENT, TrackingService

router = APIRouter(tags=["Tracking"])

IsoDate = Annotated[str, Field(pattern=r"^\d{4}-\d{2}-\d{2}$")]


class SaveIn(BaseModel):
    opportunity_id: str
    priority: Literal["high", "medium", "low"] = "medium"
    workspace_id: str | None = None


class SavedPatch(BaseModel):
    priority: Literal["high", "medium", "low"] | None = None
    interest: Literal["interested", "ineligible", "undecided"] | None = None
    ineligible_reason: str | None = Field(default=None, max_length=500)
    personal_deadline: IsoDate | None = None
    archived: bool | None = None
    workspace_id: str | None = None


class TagsIn(BaseModel):
    names: list[str] = Field(default_factory=list, max_length=20)


class NoteIn(BaseModel):
    body: str = Field(min_length=1, max_length=10_000)


class CheckIn(BaseModel):
    label: str = Field(min_length=1, max_length=300)


class CheckPatch(BaseModel):
    label: str | None = Field(default=None, max_length=300)
    is_done: bool | None = None
    sort_order: int | None = None


class TransitionIn(BaseModel):
    status: Literal[
        "discovered",
        "to_review",
        "preparing",
        "ready",
        "submitted",
        "interview",
        "accepted",
        "rejected",
        "withdrawn",
        "expired",
        "archived",
    ]
    note: str | None = Field(default=None, max_length=1000)
    submitted_on: IsoDate | None = None
    submission_ref: str | None = Field(default=None, max_length=120)
    outcome_note: str | None = Field(default=None, max_length=2000)


class EventIn(BaseModel):
    event_type: Literal["interview", "test", "follow_up", "call", "email", "meeting", "other"]
    title: str = Field(min_length=1, max_length=200)
    scheduled_at: str | None = Field(default=None, pattern=r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2})?Z?$")
    location: str | None = Field(default=None, max_length=200)
    contact_name: str | None = Field(default=None, max_length=120)
    notes: str | None = Field(default=None, max_length=4000)


class EventPatch(BaseModel):
    title: str | None = Field(default=None, max_length=200)
    scheduled_at: str | None = None
    location: str | None = Field(default=None, max_length=200)
    contact_name: str | None = Field(default=None, max_length=120)
    notes: str | None = Field(default=None, max_length=4000)
    done: bool | None = None


class GenerateIn(BaseModel):
    doc_type: Literal[
        "cover_letter",
        "scholarship_statement",
        "grant_proposal",
        "project_summary",
        "application_email",
        "cv_suggestions",
        "interview_prep",
    ]
    language: Literal["fr", "en"] = "fr"
    # True asks the configured AI for the body (anonymised profile); the template is the fallback.
    use_ai: bool = False


class VersionIn(BaseModel):
    content: str = Field(min_length=1, max_length=100_000)


# ------------------------------------------------------------------- saved
@router.post("/saved", status_code=201)
def save(body: SaveIn, active: Active) -> dict[str, Any]:
    return TrackingService(active).save(body.opportunity_id, body.priority, body.workspace_id)


@router.get("/saved")
def list_saved(
    active: Active,
    q: str | None = None,
    status: str | None = None,
    priority: str | None = None,
    tag: str | None = None,
    archived: bool = False,
    workspace_id: str | None = None,
    sort: Literal["deadline", "saved", "priority"] = "deadline",
) -> dict[str, Any]:
    return {
        "items": TrackingService(active).list_saved(
            q=q, status=status, priority=priority, tag=tag, archived=archived, workspace_id=workspace_id, sort=sort
        )
    }


@router.get("/saved/{saved_id}")
def get_saved(saved_id: str, active: Active) -> dict[str, Any]:
    return TrackingService(active).get_saved(saved_id)


@router.patch("/saved/{saved_id}")
def patch_saved(saved_id: str, body: SavedPatch, active: Active) -> dict[str, Any]:
    return TrackingService(active).update_saved(saved_id, body.model_dump(exclude_unset=True))


@router.delete("/saved/{saved_id}", status_code=204)
def unsave(saved_id: str, active: Active) -> None:
    TrackingService(active).unsave(saved_id)


@router.put("/saved/{saved_id}/tags")
def set_tags(saved_id: str, body: TagsIn, active: Active) -> dict[str, Any]:
    return TrackingService(active).set_tags(saved_id, body.names)


@router.get("/tags")
def tags(active: Active) -> dict[str, Any]:
    return {"items": TrackingService(active).tags()}


@router.get("/saved/{saved_id}/notes")
def notes(saved_id: str, active: Active) -> dict[str, Any]:
    return {"items": TrackingService(active).notes(saved_id)}


@router.post("/saved/{saved_id}/notes", status_code=201)
def add_note(saved_id: str, body: NoteIn, active: Active) -> dict[str, Any]:
    return {"items": TrackingService(active).add_note(saved_id, body.body)}


@router.put("/saved/{saved_id}/notes/{note_id}")
def edit_note(saved_id: str, note_id: str, body: NoteIn, active: Active) -> dict[str, Any]:
    return {"items": TrackingService(active).edit_note(saved_id, note_id, body.body)}


@router.delete("/saved/{saved_id}/notes/{note_id}", status_code=204)
def delete_note(saved_id: str, note_id: str, active: Active) -> None:
    TrackingService(active).delete_note(saved_id, note_id)


@router.get("/saved/{saved_id}/checklist")
def checklist(saved_id: str, active: Active) -> dict[str, Any]:
    return {"items": TrackingService(active).checklist(saved_id)}


@router.post("/saved/{saved_id}/checklist", status_code=201)
def add_check(saved_id: str, body: CheckIn, active: Active) -> dict[str, Any]:
    return {"items": TrackingService(active).add_check(saved_id, body.label)}


@router.patch("/saved/{saved_id}/checklist/{item_id}")
def patch_check(saved_id: str, item_id: int, body: CheckPatch, active: Active) -> dict[str, Any]:
    return {"items": TrackingService(active).update_check(saved_id, item_id, body.model_dump(exclude_unset=True))}


@router.delete("/saved/{saved_id}/checklist/{item_id}")
def delete_check(saved_id: str, item_id: int, active: Active) -> dict[str, Any]:
    return {"items": TrackingService(active).delete_check(saved_id, item_id)}


@router.post("/saved/{saved_id}/documents", status_code=201)
async def attach(
    saved_id: str,
    active: Active,
    file: Annotated[UploadFile, File()],
    label: Annotated[str, Form(min_length=1, max_length=200)],
    checklist_item_id: Annotated[int | None, Form()] = None,
) -> dict[str, Any]:
    import asyncio

    data = await file.read(MAX_ATTACHMENT + 1)
    return await asyncio.to_thread(
        TrackingService(active).attach,
        saved_id,
        label,
        file.filename or "document",
        file.content_type or "application/octet-stream",
        data,
        checklist_item_id,
    )


@router.get("/saved/{saved_id}/documents/{doc_id}")
def download(saved_id: str, doc_id: str, active: Active) -> Response:
    name, mime, data = TrackingService(active).document(saved_id, doc_id)
    return Response(content=data, media_type=mime, headers=attachment(name))


@router.delete("/saved/{saved_id}/documents/{doc_id}", status_code=204)
def delete_document(saved_id: str, doc_id: str, active: Active) -> None:
    TrackingService(active).delete_document(saved_id, doc_id)


# ------------------------------------------------------------ applications
@router.get("/applications/board")
def board(active: Active) -> dict[str, Any]:
    return TrackingService(active).board()


@router.get("/applications/calendar")
def calendar(
    active: Active, start: str = Query(pattern=r"^\d{4}-\d{2}-\d{2}$"), end: str = Query(pattern=r"^\d{4}-\d{2}-\d{2}$")
) -> dict[str, Any]:
    return {"items": TrackingService(active).calendar(start, end)}


@router.get("/applications/calendar.ics")
def calendar_ics(active: Active) -> Response:
    return Response(
        content=TrackingService(active).ics(),
        media_type="text/calendar; charset=utf-8",
        headers={"Content-Disposition": 'attachment; filename="opportunex.ics"'},
    )


@router.get("/applications/{app_id}")
def application(app_id: str, active: Active) -> dict[str, Any]:
    return TrackingService(active).application(app_id)


@router.post("/applications/{app_id}/status")
def transition(app_id: str, body: TransitionIn, active: Active) -> dict[str, Any]:
    return TrackingService(active).transition(
        app_id, body.status, body.note, body.submitted_on, body.submission_ref, body.outcome_note
    )


@router.post("/applications/{app_id}/events", status_code=201)
def add_event(app_id: str, body: EventIn, active: Active) -> dict[str, Any]:
    return TrackingService(active).add_event(app_id, body.model_dump())


@router.patch("/applications/{app_id}/events/{event_id}")
def patch_event(app_id: str, event_id: str, body: EventPatch, active: Active) -> dict[str, Any]:
    return TrackingService(active).update_event(app_id, event_id, body.model_dump(exclude_unset=True))


@router.delete("/applications/{app_id}/events/{event_id}")
def delete_event(app_id: str, event_id: str, active: Active) -> dict[str, Any]:
    return TrackingService(active).delete_event(app_id, event_id)


# --------------------------------------------------------------- documents
@router.get("/saved/{saved_id}/generated")
def list_generated(saved_id: str, active: Active) -> dict[str, Any]:
    return {"items": DocumentService(active).list_items(saved_id)}


@router.post("/saved/{saved_id}/generated", status_code=201)
async def generate(saved_id: str, body: GenerateIn, active: Active, state: StateDep) -> dict[str, Any]:
    svc = DocumentService(active)
    draft = None
    if body.use_ai:
        opp = await asyncio.to_thread(svc._saved_opp, saved_id)
        profile = await asyncio.to_thread(ProfileService(active).get)
        draft = await ai_tasks.draft_body(active, state, body.doc_type, profile, opp, body.language)
    doc = await asyncio.to_thread(svc.generate, saved_id, body.doc_type, body.language, draft)
    return doc | {"ai_used": draft is not None}


@router.get("/generated/{doc_id}")
def get_generated(doc_id: str, active: Active) -> dict[str, Any]:
    return DocumentService(active).get(doc_id)


@router.post("/generated/{doc_id}/versions", status_code=201)
def new_version(doc_id: str, body: VersionIn, active: Active) -> dict[str, Any]:
    return DocumentService(active).save_version(doc_id, body.content)


@router.delete("/generated/{doc_id}", status_code=204)
def delete_generated(doc_id: str, active: Active) -> None:
    DocumentService(active).delete(doc_id)


@router.get("/generated/{doc_id}/export")
def export_generated(doc_id: str, active: Active, format: Literal["docx", "pdf", "md"] = "docx") -> Response:
    name, mime, data = DocumentService(active).export(doc_id, format)
    return Response(content=data, media_type=mime, headers=attachment(name))
