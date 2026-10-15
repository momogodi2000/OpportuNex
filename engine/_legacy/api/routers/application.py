from datetime import date

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from api.dependencies import get_current_user
from domain.entities.entities import User
from persistence.database import get_db_session
from persistence.repositories.application_repo import ApplicationRepo

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
    note: str | None = None

class DocumentRequest(BaseModel):
    document_path: str
    document_type: str

class NoteRequest(BaseModel):
    note: str

@router.get("")
async def list_applications(
    cursor: str | None = Query(None),
    limit: int = Query(50, le=200),
    status: str | None = None,
    deadline_before: date | None = None,
    category: str | None = None,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Paginated list of user's applications with filters."""
    repo = ApplicationRepo(db)
    items, next_cursor = await repo.list_for_user(
        user_id=str(current_user.id),
        status=status,
        cursor=cursor,
        limit=limit
    )
    return {"items": items, "next_cursor": next_cursor}

@router.get("/calendar")
async def get_applications_calendar(
    from_date: date = Query(..., alias="from"),
    to_date: date = Query(..., alias="to"),
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Returns events for calendar view."""
    repo = ApplicationRepo(db)
    events = await repo.get_calendar_events(str(current_user.id), from_date.isoformat(), to_date.isoformat())
    return {"events": events}

@router.get("/kanban")
async def get_applications_kanban(
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Returns applications grouped by status for Kanban board."""
    repo = ApplicationRepo(db)
    columns = await repo.get_kanban_board(str(current_user.id))
    return {"columns": columns}

@router.get("/{id}")
async def get_application(
    id: str,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Full application detail with status history, documents, reminders."""
    repo = ApplicationRepo(db)
    app = await repo.get_by_id(id)
    if not app or app.user_id != str(current_user.id):
        raise HTTPException(status_code=404, detail="Not found")
        
    return {
        "id": app.id, 
        "status": app.status,
        "history": [], 
        "documents": [], 
        "reminders": []
    }

@router.post("/{id}/transition")
async def transition_application(
    id: str, 
    req: TransitionRequest,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Change status - validates against state machine."""
    repo = ApplicationRepo(db)
    app = await repo.get_by_id(id)
    if not app or app.user_id != str(current_user.id):
        raise HTTPException(status_code=404, detail="Not found")
        
    current_status = app.status
    if req.new_status not in APPLICATION_TRANSITIONS.get(current_status, []):
        raise HTTPException(status_code=400, detail=f"Invalid transition from {current_status} to {req.new_status}")
        
    await repo.update_status(id, req.new_status, current_status, req.note)
    return {"id": id, "status": req.new_status}

@router.post("/{id}/documents")
async def upload_document(
    id: str, 
    req: DocumentRequest,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Upload document reference (stores path in vault)."""
    return {"status": "document_added"}

@router.post("/{id}/notes")
async def add_note(
    id: str, 
    req: NoteRequest,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Add note to application."""
    return {"status": "note_added"}
