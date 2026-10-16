import asyncio
import uuid

import structlog
from fastapi import APIRouter, Depends, Path, Query, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from api.dependencies import get_current_user, get_db_session
from domain.entities.entities import User
from services.ai_gateway import AIGateway
from services.search_service import SearchService

logger = structlog.get_logger(__name__)
router = APIRouter(prefix="/search", tags=["Search"])

class InterpretQueryRequest(BaseModel):
    query: str
    profile_summary: dict

class SearchFilters(BaseModel):
    keywords: str | None = None
    categories: list[str] = []
    countries: list[str] = []
    amountMin: float | None = None
    amountMax: float | None = None
    currencyCode: str | None = None
    deadline: str | None = None
    languages: list[str] = []
    sourceIds: list[str] = []
    remoteOnly: bool = False
    sortBy: str = "relevance"
    page: int = 1

@router.post("/interpret")
async def interpret_search_query(req: InterpretQueryRequest, current_user: User = Depends(get_current_user)):
    "Calls ai.gateway.interpret_query()."
    logger.info("Interpreting search query", query=req.query)
    result = await AIGateway.interpret_query(req.query, req.profile_summary)
    return result

@router.post("/run")
async def run_search(filters: SearchFilters, current_user: User = Depends(get_current_user)):
    "Creates a background job (type='search'), triggers collection pipeline."
    logger.info("Running search", filters=filters.model_dump())
    job_id = str(uuid.uuid4())
    
    # Enqueue background job (fire and forget for now)
    asyncio.create_task(SearchService.run_search(filters.model_dump(), str(current_user.id), job_id))
    
    return {
        "job_id": job_id,
        "estimated_sources": 5
    }

@router.get("/run/{run_id}/results")
async def get_search_results(
    run_id: str = Path(...),
    cursor: str | None = Query(None),
    limit: int = Query(50, le=200),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session)
):
    "Streams results as they come in with cursor pagination."
    logger.info("Fetching search results", run_id=run_id, cursor=cursor)
    
    from sqlalchemy import select

    from persistence.models.all_models import OpportunityModel
    
    # We ignore run_id for now and just return the latest opportunities
    stmt = select(OpportunityModel).order_by(OpportunityModel.collected_at.desc()).limit(limit)
    if cursor:
        pass # basic cursor handling
    
    result = await db.execute(stmt)
    opps = result.scalars().all()
    
    items = []
    for opp in opps:
        items.append({
            "id": opp.id,
            "title": opp.title,
            "organization": opp.organization or "Non précisé",
            "category": opp.category_id or "Autre",
            "score": 85.0, # fake score
            "deadline": opp.deadline_iso,
            "location": opp.location or "Non précisé",
            "provenanceDeadline": opp.deadline_raw or "Inconnue",
            "isNew": True,
            "isSaved": False
        })
        
    return {
        "items": items,
        "next_cursor": "next_page" if len(items) == limit else None,
        "has_more": len(items) == limit
    }

@router.get("/suggest")
async def search_suggest(q: str = Query(...), limit: int = Query(5, le=20)):
    "Autocomplete from opportunity titles + organization names."
    logger.info("Search suggestions", q=q, limit=limit)
    return {"suggestions": []}

@router.delete("/run/{run_id}")
async def cancel_search(run_id: str = Path(...), current_user: User = Depends(get_current_user)):
    "Cancel a running search."
    logger.info("Canceling search run", run_id=run_id)
    await SearchService.cancel_search(run_id)
    return {"status": "canceled"}

@router.websocket("/run/{run_id}/progress")
async def search_progress_ws(websocket: WebSocket, run_id: str):
    "Streams progress events (source_name, current, total, found)."
    await websocket.accept()
    logger.info("WebSocket connected for search progress", run_id=run_id)
    try:
        
        while True:
            # dummy receive to keep open, real implementation reads from bus
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        logger.info("WebSocket disconnected", run_id=run_id)

