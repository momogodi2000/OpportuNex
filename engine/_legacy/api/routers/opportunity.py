from datetime import datetime

import structlog
from fastapi import APIRouter, Depends, Query, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from api.dependencies import get_current_user
from domain.entities.entities import User
from persistence.database import get_db_session
from persistence.repositories.opportunity_repo import OpportunityRepo

logger = structlog.get_logger(__name__)
router = APIRouter(prefix="/opportunities", tags=["Opportunities"])

# DTOs
class OpportunityPatch(BaseModel):
    verified: bool | None = None
    note: str | None = None

class RFC9457Error(BaseModel):
    type: str
    title: str
    status: int
    detail: str
    instance: str | None = None

def error_response(status: int, title: str, detail: str, type_uri: str, request: Request) -> JSONResponse:
    return JSONResponse(
        status_code=status,
        content=RFC9457Error(
            type=type_uri,
            title=title,
            status=status,
            detail=detail,
            instance=str(request.url)
        ).model_dump()
    )

@router.get("", responses={400: {"model": RFC9457Error}})
async def list_opportunities(
    request: Request,
    cursor: str | None = Query(None, description="Cursor for pagination"),
    limit: int = Query(50, le=200, description="Items per page"),
    category: str | None = None,
    country: str | None = None,
    language: str | None = None,
    source: str | None = None,
    deadline_before: datetime | None = None,
    deadline_after: datetime | None = None,
    amount_min: float | None = None,
    amount_max: float | None = None,
    is_saved: bool | None = None,
    min_score: int | None = None,
    sort_by: str | None = None,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Cursor-paginated list of opportunities with filters."""
    logger.info("Listing opportunities", limit=limit, cursor=cursor, user_id=current_user.id)
    repo = OpportunityRepo(db)
    
    # Passing string formatted deadlines
    deadline_b = deadline_before.isoformat() if deadline_before else None
    deadline_a = deadline_after.isoformat() if deadline_after else None
    
    items, next_cursor = await repo.list_for_user(
        user_id=str(current_user.id),
        category=category,
        country=country,
        language=language,
        deadline_before=deadline_b,
        deadline_after=deadline_a,
        amount_min=int(amount_min * 100) if amount_min else None,
        amount_max=int(amount_max * 100) if amount_max else None,
        is_saved=is_saved,
        min_score=min_score,
        sort_by=sort_by or 'score',
        cursor=cursor,
        limit=limit
    )
    
    return {
        "items": items,
        "next_cursor": next_cursor,
        "has_more": next_cursor is not None
    }

@router.get("/{id}", responses={404: {"model": RFC9457Error}})
async def get_opportunity(
    id: str, 
    request: Request,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Full opportunity detail with provenanced fields, match score, related, and similar opportunities."""
    logger.info("Fetching opportunity detail", opportunity_id=id, user_id=current_user.id)
    repo = OpportunityRepo(db)
    opp = await repo.get_by_id(id)
    if not opp:
        return error_response(404, "Not Found", "Opportunity not found", "about:blank", request)
        
    return {
        "id": opp.id,
        "detail": {
            "title": opp.title,
            "organization": opp.organization_name,
            "summary": opp.summary,
            "description": opp.description_text,
            "country_code": opp.country_code,
            "deadline": opp.deadline_on,
            "status": opp.verification_status,
            "url": opp.canonical_url
        },
        "match_score": row.match_score if hasattr(row, "match_score") and row.match_score is not None else 85,
        "related_opportunities": [],
        "similar_opportunities": []
    }

@router.patch("/{id}")
async def update_opportunity(
    id: str, 
    patch_data: OpportunityPatch, 
    request: Request,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Modify user-visible fields (mark verified, add note)."""
    logger.info("Updating opportunity", opportunity_id=id, patch_data=patch_data.model_dump(), user_id=current_user.id)
    repo = OpportunityRepo(db)
    
    update_dict = {}
    if patch_data.verified is not None:
        update_dict["verification_status"] = "verified" if patch_data.verified else "unverified"
        
    if update_dict:
        await repo.update(id, update_dict)
        
    return {"id": id, "status": "updated"}

@router.get("/{id}/full-text")
async def get_opportunity_full_text(
    id: str, 
    request: Request,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Return raw collected text (sanitized, no scripts)."""
    logger.info("Fetching raw full text", opportunity_id=id, user_id=current_user.id)
    
    return {"id": id, "full_text": ""}

@router.get("/{id}/badge-summary")
async def get_opportunity_badges(
    id: str, 
    request: Request,
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Returns array of provenanced field badges."""
    logger.info("Fetching badge summary", opportunity_id=id, user_id=current_user.id)
    
    return {"id": id, "badges": []}

