
import structlog
from fastapi import APIRouter, Depends, Query
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from api.dependencies import get_current_user
from domain.entities.entities import User
from persistence.database import get_db_session

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
            'totalOpportunities': row.discovered,
            'newThisWeek': row.relevant,
            'savedCount': row.saved,
            'pendingApplications': row.in_progress + row.submitted,
            'upcomingDeadlines': row.deadlines_14d,
            'monitorsActive': 0,
            'averageScore': 0.0
        }
    else:
        return {
            'totalOpportunities': 0,
            'newThisWeek': 0,
            'savedCount': 0,
            'pendingApplications': 0,
            'upcomingDeadlines': 0,
            'monitorsActive': 0,
            'averageScore': 0.0
        }

@router.get("/upcoming-deadlines")
async def get_upcoming_deadlines(
    limit: int = Query(10, le=50),
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
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
            'opportunityId': row.opportunity_id,
            'title': row.title,
            'deadline': row.effective_deadline,
            'daysLeft': row.days_left,
            'applicationStatus': row.application_status
        })
    return {"items": items}

@router.get("/recent-activity")
async def get_recent_activity(
    limit: int = Query(10, le=50),
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    logger.info("Fetching recent activity")
    query = text('''
        SELECT event_type, entity_id, details, created_at
        FROM security_events 
        WHERE user_id = :user_id 
        ORDER BY created_at DESC 
        LIMIT :limit
    ''')
    result = await db.execute(query, {"user_id": str(current_user.id), "limit": limit})
    
    items = []
    for row in result:
        items.append({
            'type': 'system',
            'description': f"Action {row.event_type}",
            'occurredAt': row.created_at.isoformat(),
            'opportunityId': None
        })
    return {"items": items}

@router.get("/source-health")
async def get_source_health(
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    logger.info("Fetching source health")
    query = text('''
        SELECT id, name, last_status, reliability_score, last_success_at, consecutive_failures
        FROM opportunity_sources
        ORDER BY reliability_score DESC
        LIMIT 10
    ''')
    result = await db.execute(query)
    
    items = []
    for row in result:
        items.append({
            'sourceId': row.id,
            'name': row.name,
            'status': row.last_status or 'unknown',
            'reliability': float(row.reliability_score) if row.reliability_score else 0.0,
            'lastSuccess': row.last_success_at.isoformat() if row.last_success_at else None,
            'consecutiveFailures': row.consecutive_failures or 0
        })
    return {"items": items}




