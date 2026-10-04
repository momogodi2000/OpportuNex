from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any, Optional
from pydantic import BaseModel
from datetime import datetime

router = APIRouter(prefix="/sources", tags=["sources"])

class SourceCreate(BaseModel):
    name: str
    base_url: str
    country_code: Optional[str] = None
    language_code: Optional[str] = None
    adapter_json: Dict[str, Any]

class SourceUpdate(BaseModel):
    name: Optional[str] = None
    base_url: Optional[str] = None
    country_code: Optional[str] = None
    language_code: Optional[str] = None
    adapter_json: Optional[Dict[str, Any]] = None

class SourceStatusUpdate(BaseModel):
    status: str

class SourceResponse(BaseModel):
    id: str
    name: str
    base_url: str
    status: str
    country_code: Optional[str]
    language_code: Optional[str]
    reliability: float
    last_run_at: Optional[datetime]
    adapter_json: Optional[Dict[str, Any]]

@router.get("", response_model=List[SourceResponse])
async def list_sources():
    return []

@router.get("/catalog", response_model=List[Dict[str, Any]])
async def list_source_catalog():
    return []

@router.get("/{source_id}", response_model=SourceResponse)
async def get_source(source_id: str):
    raise HTTPException(status_code=404, detail="Source not found")

@router.post("", response_model=SourceResponse)
async def create_source(source: SourceCreate):
    return SourceResponse(
        id="new_id",
        name=source.name,
        base_url=source.base_url,
        status="enabled",
        country_code=source.country_code,
        language_code=source.language_code,
        reliability=1.0,
        last_run_at=None,
        adapter_json=source.adapter_json
    )

@router.put("/{source_id}", response_model=SourceResponse)
async def update_source(source_id: str, source: SourceUpdate):
    raise HTTPException(status_code=404, detail="Source not found")

@router.patch("/{source_id}/status")
async def update_source_status(source_id: str, update: SourceStatusUpdate):
    return {"status": "updated"}

@router.delete("/{source_id}")
async def delete_source(source_id: str):
    return {"status": "deleted"}

@router.post("/{source_id}/scan-now")
async def scan_source_now(source_id: str):
    return {"status": "scan_started"}

@router.post("/catalog/{name}/activate")
async def activate_catalog_source(name: str):
    return {"status": "activated", "name": name}
