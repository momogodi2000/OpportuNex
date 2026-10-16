from datetime import datetime

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from api.dependencies import get_current_user
from domain.entities.entities import User
from persistence.database import get_db_session
from persistence.repositories.saved_repo import SavedRepo

logger = structlog.get_logger(__name__)
router = APIRouter(prefix="/saved", tags=["Saved Opportunities"])

class SaveOpportunityRequest(BaseModel):
    opportunity_id: str
    priority: int | None = 3
    notes: str | None = None
    personal_deadline: datetime | None = None

class UpdateSavedRequest(BaseModel):
    priority: int | None = None
    notes: str | None = None
    personal_deadline: datetime | None = None

class ReminderRequest(BaseModel):
    due_at: datetime
    title: str
    body: str

@router.get("")
async def list_saved(
    cursor: str | None = Query(None),
    limit: int = Query(50, le=200),
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Paginated list of user's saved opportunities (with match score, application status)."""
    logger.info("Listing saved opportunities", user_id=current_user.id)
    repo = SavedRepo(db)
    items = await repo.list_for_user(
        user_id=str(current_user.id),
        priority_filter=None,
        sort_by='default',
        cursor=cursor,
        limit=limit
    )
    return {"items": [
        {
            "id": str(i.id),
            "opportunity_id": i.opportunity_id,
            "priority": i.priority,
            "notes": i.notes,
            "personal_deadline": i.personal_deadline,
            "created_at": i.created_at
        } for i in items
    ], "next_cursor": None}

@router.post("")
async def save_opportunity(
    req: SaveOpportunityRequest,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Save an opportunity."""
    logger.info("Saving opportunity", user_id=current_user.id, opportunity_id=req.opportunity_id)
    repo = SavedRepo(db)
    existing = await repo.get_by_opportunity_and_user(req.opportunity_id, str(current_user.id))
    if existing:
        return {"status": "already_saved", "id": existing.id}
        
    saved_id = await repo.create(
        user_id=str(current_user.id),
        opportunity_id=req.opportunity_id,
        priority=req.priority or 3,
        notes=req.notes or "",
        personal_deadline=req.personal_deadline
    )
    return {"status": "saved", "id": saved_id}

@router.get("/{id}")
async def get_saved_detail(
    id: str,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Detail with full opportunity + application state + reminders."""
    repo = SavedRepo(db)
    saved = await repo.get_by_id(id)
    if not saved or saved.user_id != str(current_user.id):
        raise HTTPException(status_code=404, detail="Not found")
        
    return {
        "id": saved.id,
        "opportunity_id": saved.opportunity_id,
        "notes": saved.notes,
        "priority": saved.priority,
        "personal_deadline": saved.personal_deadline
    }

@router.patch("/{id}")
async def update_saved(
    id: str, 
    req: UpdateSavedRequest,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Update priority, notes, personal_deadline."""
    repo = SavedRepo(db)
    saved = await repo.get_by_id(id)
    if not saved or saved.user_id != str(current_user.id):
        raise HTTPException(status_code=404, detail="Not found")
        
    priority = req.priority if req.priority is not None else saved.priority
    notes = req.notes if req.notes is not None else saved.notes
    personal_deadline = req.personal_deadline if req.personal_deadline is not None else saved.personal_deadline
    
    await repo.update(id, priority, notes, personal_deadline)
    return {"id": id, "status": "updated"}

@router.delete("/{id}")
async def unsave_opportunity(
    id: str,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Unsave (does NOT delete the opportunity or application)."""
    repo = SavedRepo(db)
    saved = await repo.get_by_id(id)
    if not saved or saved.user_id != str(current_user.id):
        raise HTTPException(status_code=404, detail="Not found")
        
    await repo.delete(id)
    return {"status": "unsaved"}

@router.post("/{id}/remind")
async def create_reminder(
    id: str, 
    req: ReminderRequest,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Create a reminder."""
    repo = SavedRepo(db)
    saved = await repo.get_by_id(id)
    if not saved or saved.user_id != str(current_user.id):
        raise HTTPException(status_code=404, detail="Not found")
        
    reminder_id = await repo.create_reminder(
        saved_opportunity_id=id,
        user_id=str(current_user.id),
        due_at=req.due_at,
        title=req.title,
        body=req.body
    )
    return {"id": reminder_id, "status": "created"}

@router.get("/{id}/reminders")
async def list_reminders(
    id: str,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """List reminders for this saved opportunity."""
    repo = SavedRepo(db)
    saved = await repo.get_by_id(id)
    if not saved or saved.user_id != str(current_user.id):
        raise HTTPException(status_code=404, detail="Not found")
        
    reminders = await repo.list_reminders(id)
    return {"items": [
        {"id": str(r.id), "due_at": r.due_at, "title": r.title, "body": r.body, "is_sent": r.is_sent} 
        for r in reminders
    ]}
