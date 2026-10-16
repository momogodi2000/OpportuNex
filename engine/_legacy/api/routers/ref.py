from typing import Any

from fastapi import APIRouter

router = APIRouter(prefix="/ref", tags=["reference_data"])

@router.get("/countries", response_model=list[dict[str, str]])
async def list_countries():
    return [{"code": "US", "name": "United States"}, {"code": "GB", "name": "United Kingdom"}]

@router.get("/currencies", response_model=list[dict[str, str]])
async def list_currencies():
    return [{"code": "USD", "symbol": "$"}, {"code": "EUR", "symbol": "€"}]

@router.get("/languages", response_model=list[dict[str, str]])
async def list_languages():
    return [{"code": "en", "name": "English"}, {"code": "es", "name": "Spanish"}]

@router.get("/categories", response_model=list[dict[str, Any]])
async def list_categories():
    return [{"id": "cat_1", "name": "Technology", "children": [{"id": "cat_1_1", "name": "Software Development"}]}]

@router.get("/skills", response_model=list[dict[str, str]])
async def list_skills(q: str | None = None):
    skills = [{"id": "sk_1", "name": "Python"}, {"id": "sk_2", "name": "JavaScript"}]
    if q:
        return [s for s in skills if q.lower() in s["name"].lower()]
    return skills

@router.get("/degree-levels", response_model=list[dict[str, str]])
async def list_degree_levels():
    return [{"id": "dl_1", "name": "Bachelor's"}, {"id": "dl_2", "name": "Master's"}]
