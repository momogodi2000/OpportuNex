from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel
from typing import Optional, List

router = APIRouter(prefix="/profile", tags=["Profile"])

def require_user(x_user_id: Optional[str] = Header(None)) -> str:
    if not x_user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"type": "about:blank", "title": "Unauthorized", "status": 401, "detail": "Missing X-User-Id"}
        )
    return x_user_id

class ProfileUpdate(BaseModel):
    display_name: Optional[str] = None

class EducationRecordModel(BaseModel):
    institution: str
    degree: str

class ExperienceRecordModel(BaseModel):
    company: str
    role: str

class SkillsModel(BaseModel):
    skills: List[str]

class LanguagesModel(BaseModel):
    languages: List[str]

class ObjectivesModel(BaseModel):
    objectives: List[str]

@router.get("")
async def get_profile(x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"id": user_id}

@router.put("")
async def update_profile(req: ProfileUpdate, x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"status": "updated"}

@router.get("/completeness")
async def get_completeness(x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"score": 0, "missing_sections": ["education", "experience"]}

@router.post("/education")
async def add_education(req: EducationRecordModel, x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"status": "added", "id": "new_id"}

@router.put("/education/{id}")
async def update_education(id: str, req: EducationRecordModel, x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"status": "updated"}

@router.delete("/education/{id}")
async def delete_education(id: str, x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"status": "deleted"}

@router.post("/experience")
async def add_experience(req: ExperienceRecordModel, x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"status": "added", "id": "new_id"}

@router.put("/experience/{id}")
async def update_experience(id: str, req: ExperienceRecordModel, x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"status": "updated"}

@router.delete("/experience/{id}")
async def delete_experience(id: str, x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"status": "deleted"}

@router.post("/skills")
async def update_skills(req: SkillsModel, x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"status": "updated"}

@router.post("/languages")
async def update_languages(req: LanguagesModel, x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"status": "updated"}

@router.put("/objectives")
async def update_objectives(req: ObjectivesModel, x_user_id: str = Header(None)):
    user_id = require_user(x_user_id)
    return {"status": "updated"}
