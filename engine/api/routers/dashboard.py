import structlog
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any

logger = structlog.get_logger(__name__)
router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

@router.get("/counters")
async def get_counters():
    """Queries v_dashboard_counters view and returns aggregated stats."""
    logger.info("Fetching dashboard counters")
    # TODO: query v_dashboard_counters view
    return {
        "total_opportunities": 0,
        "new_this_week": 0,
        "saved_count": 0,
        "pending_applications": 0,
        "upcoming_deadlines_7d": 0,
        "monitors_active": 0,
        "average_score": 0.0
    }

@router.get("/upcoming-deadlines")
async def get_upcoming_deadlines(limit: int = Query(10, le=50)):
    """Queries v_upcoming_deadlines view."""
    logger.info("Fetching upcoming deadlines", limit=limit)
    # TODO: query v_upcoming_deadlines view
    return {"items": []}

@router.get("/recent-activity")
async def get_recent_activity(limit: int = Query(20, le=100)):
    """Returns recent search runs, saved opportunities, application status changes."""
    logger.info("Fetching recent activity", limit=limit)
    # TODO: Union query across searches, saves, applications
    return {"items": []}

@router.get("/source-health")
async def get_source_health():
    """Queries v_source_health view + recent scan run data."""
    logger.info("Fetching source health")
    # TODO: query v_source_health
    return {"items": []}
