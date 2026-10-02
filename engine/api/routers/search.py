import structlog
from typing import Optional, Dict, Any
from fastapi import APIRouter, Depends, Query, Path, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

logger = structlog.get_logger(__name__)
router = APIRouter(prefix="/search", tags=["Search"])

class InterpretQueryRequest(BaseModel):
    query: str
    profile_summary: dict

class SearchFilters(BaseModel):
    keywords: list[str] = []
    category: Optional[str] = None
    country: Optional[str] = None
    language: Optional[str] = None

@router.post("/interpret")
async def interpret_search_query(req: InterpretQueryRequest):
    """Calls ai.gateway.interpret_query()."""
    logger.info("Interpreting search query", query=req.query)
    # TODO: call ai.gateway.interpret_query()
    return {
        "keywords": [],
        "filters": {},
        "confidence": 0.95
    }

@router.post("/run")
async def run_search(filters: SearchFilters):
    """Creates a background job (type='search'), triggers collection pipeline."""
    logger.info("Running search", filters=filters.model_dump())
    # TODO: enqueue background job, trigger pipeline
    import uuid
    job_id = str(uuid.uuid4())
    return {
        "job_id": job_id,
        "estimated_sources": 5
    }

@router.get("/run/{run_id}/results")
async def get_search_results(
    run_id: str = Path(...),
    cursor: Optional[str] = Query(None),
    limit: int = Query(50, le=200)
):
    """Streams results as they come in with cursor pagination."""
    logger.info("Fetching search results", run_id=run_id, cursor=cursor)
    return {
        "items": [],
        "next_cursor": None,
        "has_more": False
    }

@router.get("/suggest")
async def search_suggest(q: str = Query(...), limit: int = Query(5, le=20)):
    """Autocomplete from opportunity titles + organization names."""
    logger.info("Search suggestions", q=q, limit=limit)
    return {"suggestions": []}

@router.delete("/run/{run_id}")
async def cancel_search(run_id: str = Path(...)):
    """Cancel a running search."""
    logger.info("Canceling search run", run_id=run_id)
    return {"status": "canceled"}

@router.websocket("/run/{run_id}/progress")
async def search_progress_ws(websocket: WebSocket, run_id: str):
    """Streams progress events (source_name, current, total, found)."""
    await websocket.accept()
    logger.info("WebSocket connected for search progress", run_id=run_id)
    try:
        # TODO: Subscribe to event bus or redis pub/sub for this run_id
        while True:
            # dummy receive to keep open, real implementation reads from bus
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        logger.info("WebSocket disconnected", run_id=run_id)
