import io
from datetime import datetime
from typing import Any

from fastapi import APIRouter
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

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
    return ExportResponse(job_id="job_123", status="pending", created_at=datetime.utcnow())

@router.get("", response_model=list[ExportResponse])
async def list_recent_exports():
    return []

@router.get("/{job_id}/status", response_model=dict[str, Any])
async def get_export_status(job_id: str):
    return {"job_id": job_id, "status": "completed"}

@router.get("/{job_id}/download")
async def download_export(job_id: str):
    file_stream = io.BytesIO(b"dummy export content")
    return StreamingResponse(file_stream, media_type="application/octet-stream", headers={"Content-Disposition": f"attachment; filename=export_{job_id}.bin"})
