import structlog
from typing import Optional
from fastapi import APIRouter, Depends, Query, Path, HTTPException
from pydantic import BaseModel
from datetime import date

logger = structlog.get_logger(__name__)
router = APIRouter(prefix="/applications", tags=["Applications"])

# This would normally be imported from engine.domain.entities.entities
APPLICATION_TRANSITIONS = {
    "draft": ["submitted", "archived"],
    "submitted": ["under_review", "rejected", "accepted"],
    "under_review": ["interview", "rejected", "accepted"],
    "interview": ["offer", "rejected"],
    "offer": ["accepted", "declined"],
    "accepted": [],
    "declined": [],
    "rejected": [],
    "archived": ["draft"]
}

class TransitionRequest(BaseModel):
    new_status: str
    note: Optional[str] = None

class DocumentRequest(BaseModel):
    document_path: str
    document_type: str

class NoteRequest(BaseModel):
    note: str

@router.get("")
async def list_applications(
    cursor: Optional[str] = Query(None),
    limit: int = Query(50, le=200),
    status: Optional[str] = None,
    deadline_before: Optional[date] = None,
    category: Optional[str] = None
):
    """Paginated list of user's applications with filters."""
    return {"items": [], "next_cursor": None}

@router.get("/calendar")
async def get_applications_calendar(
    from_date: date = Query(..., alias="from"),
    to_date: date = Query(..., alias="to")
):
    """Returns events for calendar view."""
    return {"events": []}

@router.get("/kanban")
async def get_applications_kanban():
    """Returns applications grouped by status for Kanban board."""
    return {"columns": {}}

@router.get("/{id}")
async def get_application(id: str):
    """Full application detail with status history, documents, reminders."""
    return {"id": id, "history": [], "documents": [], "reminders": []}

@router.post("/{id}/transition")
async def transition_application(id: str, req: TransitionRequest):
    """Change status - validates against state machine."""
    current_status = "draft"  # TODO: fetch from DB
    if req.new_status not in APPLICATION_TRANSITIONS.get(current_status, []):
        raise HTTPException(status_code=400, detail=f"Invalid transition from {current_status} to {req.new_status}")
    return {"id": id, "status": req.new_status}

@router.post("/{id}/documents")
async def upload_document(id: str, req: DocumentRequest):
    """Upload document reference (stores path in vault)."""
    return {"status": "document_added"}

@router.post("/{id}/notes")
async def add_note(id: str, req: NoteRequest):
    """Add note to application."""
    return {"status": "note_added"}
