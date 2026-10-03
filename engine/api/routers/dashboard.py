import structlog
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from typing import Dict, Any, List

from persistence.database import get_db_session
from api.dependencies import get_current_user
from domain.entities.entities import User

logger = structlog.get_logger(__name__)
router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

@router.get("/counters")
async def get_counters(
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Queries v_dashboard_counters view and returns aggregated stats."""
    logger.info("Fetching dashboard counters", user_id=current_user.id)
    
    query = text("SELECT * FROM v_dashboard_counters WHERE user_id = :user_id")
    result = await db.execute(query, {"user_id": str(current_user.id)})
    row = result.fetchone()
    
    if row:
        return {
            "discovered": row.discovered,
            "relevant": row.relevant,
            "saved": row.saved,
            "in_progress": row.in_progress,
            "submitted": row.submitted,
            "deadlines_14d": row.deadlines_14d,
            "unread_notifications": row.unread_notifications
        }
    else:
        return {
            "discovered": 0,
            "relevant": 0,
            "saved": 0,
            "in_progress": 0,
            "submitted": 0,
            "deadlines_14d": 0,
            "unread_notifications": 0
        }

@router.get("/upcoming-deadlines")
async def get_upcoming_deadlines(
    limit: int = Query(10, le=50),
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Queries v_upcoming_deadlines view."""
    logger.info("Fetching upcoming deadlines", limit=limit, user_id=current_user.id)
    
    query = text('''
        SELECT saved_id, opportunity_id, title, organization_name, effective_deadline, days_left, application_status, priority
        FROM v_upcoming_deadlines 
        WHERE user_id = :user_id 
        ORDER BY days_left ASC 
        LIMIT :limit
    ''')
    result = await db.execute(query, {"user_id": str(current_user.id), "limit": limit})
    
    items = []
    for row in result:
        items.append({
            "saved_id": row.saved_id,
            "opportunity_id": row.opportunity_id,
            "title": row.title,
            "organization_name": row.organization_name,
            "effective_deadline": row.effective_deadline,
            "days_left": row.days_left,
            "application_status": row.application_status,
            "priority": row.priority
        })
        
    return {"items": items}

@router.get("/recent-activity")
async def get_recent_activity(
    limit: int = Query(20, le=100),
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Returns recent search runs, saved opportunities, application status changes."""
    logger.info("Fetching recent activity", limit=limit, user_id=current_user.id)
    # Simple mockup for now. A real union requires querying search runs, saves, applications.
    return {"items": []}

@router.get("/source-health")
async def get_source_health(
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    """Queries v_source_health view + recent scan run data."""
    logger.info("Fetching source health", user_id=current_user.id)
    
    query = text('SELECT * FROM v_source_health ORDER BY reliability_score DESC LIMIT 20')
    result = await db.execute(query)
    
    items = []
    for row in result:
        items.append({
            "id": row.id,
            "name": row.name,
            "domain": row.domain,
            "access_method": row.access_method,
            "enabled": row.enabled,
            "allowed_status": row.allowed_status,
            "last_status": row.last_status,
            "last_success_at": row.last_success_at,
            "consecutive_failures": row.consecutive_failures,
            "reliability_score": row.reliability_score,
            "opportunities_count": row.opportunities_count
        })
        
    return {"items": items}
