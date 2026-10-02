import structlog
from typing import Optional
from fastapi import APIRouter, Depends, Query, Path
from pydantic import BaseModel
from datetime import datetime

logger = structlog.get_logger(__name__)
router = APIRouter(prefix="/saved", tags=["Saved Opportunities"])

class SaveOpportunityRequest(BaseModel):
    opportunity_id: str
    priority: Optional[str] = "medium"
    notes: Optional[str] = None
    personal_deadline: Optional[datetime] = None

class UpdateSavedRequest(BaseModel):
    priority: Optional[str] = None
    notes: Optional[str] = None
    personal_deadline: Optional[datetime] = None

class ReminderRequest(BaseModel):
    due_at: datetime
    title: str
    body: str

@router.get("")
async def list_saved(
    cursor: Optional[str] = Query(None),
    limit: int = Query(50, le=200)
):
    """Paginated list of user's saved opportunities (with match score, application status)."""
    return {"items": [], "next_cursor": None}

@router.post("")
async def save_opportunity(req: SaveOpportunityRequest):
    """Save an opportunity."""
    return {"status": "saved", "id": "saved_id"}

@router.get("/{id}")
async def get_saved_detail(id: str):
    """Detail with full opportunity + application state + reminders."""
    return {"id": id, "opportunity": {}, "application_state": {}, "reminders": []}

@router.patch("/{id}")
async def update_saved(id: str, req: UpdateSavedRequest):
    """Update priority, notes, personal_deadline."""
    return {"id": id, "status": "updated"}

@router.delete("/{id}")
async def unsave_opportunity(id: str):
    """Unsave (does NOT delete the opportunity or application)."""
    return {"status": "unsaved"}

@router.post("/{id}/remind")
async def create_reminder(id: str, req: ReminderRequest):
    """Create a reminder."""
    return {"id": "reminder_id", "status": "created"}

@router.get("/{id}/reminders")
async def list_reminders(id: str):
    """List reminders for this saved opportunity."""
    return {"items": []}
