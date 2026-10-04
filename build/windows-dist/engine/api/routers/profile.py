"""
Profile API Router.
"""

from typing import Dict, Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from api.dependencies import get_current_user
from domain.entities.entities import User
from persistence.database import get_db_session
from persistence.repositories.profile_repo import ProfileRepo
from services.profile_service import ProfileService

log = structlog.get_logger(__name__)

router = APIRouter(prefix="/profile", tags=["profile"])

async def get_profile_service(session: AsyncSession = Depends(get_db_session)) -> ProfileService:
    repo = ProfileRepo(session)
    return ProfileService(repo)


class GeneralInfoRequest(BaseModel):
    full_name: Optional[str] = None
    country_code: Optional[str] = None
    city: Optional[str] = None
    professional_status: Optional[str] = None
    work_mode_pref: Optional[str] = None


class EducationRequest(BaseModel):
    degree_level: str
    field_of_study: str
    institution: str
    graduation_year: Optional[int] = None
    country_code: Optional[str] = None


class ExperienceRequest(BaseModel):
    job_title: str
    employer: str
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    is_current: bool = False
    description: Optional[str] = None
    country_code: Optional[str] = None


class SkillRequest(BaseModel):
    skill_id: str
    level: Optional[str] = None


class LanguageRequest(BaseModel):
    language_code: str
    cefr_level: str


class ObjectivesRequest(BaseModel):
    objective_ids: List[str]


@router.get("")
async def get_summary(
    current_user: User = Depends(get_current_user),
    service: ProfileService = Depends(get_profile_service)
) -> Dict[str, Any]:
    return await service.get_profile_summary(str(current_user.id))


@router.put("")
async def update_general(
    req: GeneralInfoRequest,
    current_user: User = Depends(get_current_user),
    service: ProfileService = Depends(get_profile_service)
) -> Dict[str, Any]:
    return await service.update_general_info(str(current_user.id), req.model_dump(exclude_unset=True))


@router.get("/completeness")
async def get_completeness(
    current_user: User = Depends(get_current_user),
    service: ProfileService = Depends(get_profile_service)
) -> Dict[str, Any]:
    summary = await service.get_profile_summary(str(current_user.id))
    return {
        "score": summary["completeness_score"],
        "missing_sections": summary["suggestions"]
    }


@router.post("/education")
async def add_education(
    req: EducationRequest,
    current_user: User = Depends(get_current_user),
    service: ProfileService = Depends(get_profile_service)
) -> Dict[str, Any]:
    return await service.add_education(str(current_user.id), req.model_dump())


@router.post("/experience")
async def add_experience(
    req: ExperienceRequest,
    current_user: User = Depends(get_current_user),
    service: ProfileService = Depends(get_profile_service)
) -> Dict[str, Any]:
    return await service.add_experience(str(current_user.id), req.model_dump())


@router.post("/skills")
async def add_skill(
    req: SkillRequest,
    current_user: User = Depends(get_current_user),
    service: ProfileService = Depends(get_profile_service)
) -> Dict[str, Any]:
    return await service.add_skill(str(current_user.id), req.model_dump())


@router.post("/languages")
async def add_language(
    req: LanguageRequest,
    current_user: User = Depends(get_current_user),
    service: ProfileService = Depends(get_profile_service)
) -> Dict[str, Any]:
    return await service.add_language(str(current_user.id), req.model_dump())


@router.put("/objectives")
async def update_objectives(
    req: ObjectivesRequest,
    current_user: User = Depends(get_current_user),
    service: ProfileService = Depends(get_profile_service)
) -> Dict[str, str]:
    await service.update_objectives(str(current_user.id), req.objective_ids)
    return {"detail": "Objectives updated"}


@router.post("/cv-extract")
async def extract_cv(
    file: UploadFile = File(...),
    use_ai: bool = Form(False),
    current_user: User = Depends(get_current_user),
    service: ProfileService = Depends(get_profile_service)
) -> Dict[str, Any]:
    if file.size and file.size > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large (max 10MB)")
        
    content = await file.read()
    return await service.extract_cv(content, file.filename or "cv.pdf", use_ai)
