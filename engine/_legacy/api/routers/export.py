import io
import csv
import json
from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from persistence.database import get_db_session
from persistence.models.all_models import OpportunityModel, SavedOpportunity, ApplicationModel
from domain.entities.entities import User
from api.dependencies import get_current_user

router = APIRouter(prefix="/exports", tags=["exports"])

class ExportRequest(BaseModel):
    format: str
    entity_type: str
    date_from: datetime | None = None
    date_to: datetime | None = None
    opportunity_ids: list[str] | None = None

class ExportResponse(BaseModel):
    job_id: str
    status: str
    created_at: datetime

@router.post("", response_model=ExportResponse)
async def create_export(request: ExportRequest):
    return ExportResponse(job_id="job_123", status="pending", created_at=datetime.now(timezone.utc))

@router.get("", response_model=list[ExportResponse])
async def list_recent_exports():
    return []

@router.get("/download")
async def download_export_direct(
    format: str = "CSV",
    type: str = "saved",
    db: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user)
):
    \"\"\"Direct synchronous download for simple entities.\"\"\"
    
    data_list = []
    
    if type == "saved":
        stmt = select(SavedOpportunity, OpportunityModel).join(OpportunityModel, SavedOpportunity.opportunity_id == OpportunityModel.id).where(SavedOpportunity.user_id == str(current_user.id))
        result = await db.execute(stmt)
        for saved, opp in result.all():
            data_list.append({
                "saved_id": str(saved.id),
                "title": opp.title,
                "url": opp.url,
                "priority": saved.priority,
                "deadline": opp.deadline_raw,
                "saved_at": saved.created_at.isoformat() if saved.created_at else None
            })
    elif type == "applications":
        stmt = select(ApplicationModel).where(ApplicationModel.user_id == str(current_user.id))
        result = await db.execute(stmt)
        for app in result.scalars().all():
            data_list.append({
                "id": str(app.id),
                "opportunity_id": app.opportunity_id,
                "status": app.status,
                "applied_at": app.applied_at.isoformat() if app.applied_at else None
            })
    else:
        # Dummy
        data_list = [{"info": "No data for this type"}]

    if format.upper() == "JSON":
        content = json.dumps(data_list, indent=2, ensure_ascii=False)
        stream = io.BytesIO(content.encode('utf-8'))
        media_type = "application/json"
        ext = "json"
    else:
        # Default CSV
        output = io.StringIO()
        if data_list:
            writer = csv.DictWriter(output, fieldnames=data_list[0].keys())
            writer.writeheader()
            writer.writerows(data_list)
        content = output.getvalue()
        # Add UTF-8 BOM for Excel
        stream = io.BytesIO(b'\xef\xbb\xbf' + content.encode('utf-8'))
        media_type = "text/csv"
        ext = "csv"
        
    filename = f"export_{type}_{datetime.now().strftime('%Y%m%d')}.{ext}"
    return StreamingResponse(stream, media_type=media_type, headers={"Content-Disposition": f'attachment; filename="{filename}"'})
