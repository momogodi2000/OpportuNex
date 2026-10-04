"""
Profile Repository — manages all profile-related database operations.
"""

from typing import List, Optional
from sqlalchemy import select, delete, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from persistence.models.all_models import (
    UserProfile, EducationRecord, WorkExperience,
    UserSkill, UserLanguage, UserObjective
)

class ProfileRepo:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_user_profile(self, user_id: str) -> Optional[UserProfile]:
        stmt = (
            select(UserProfile)
            .where(UserProfile.user_id == user_id)
        )
        result = await self.session.execute(stmt)
        return result.scalars().first()

    async def upsert_user_profile(self, user_id: str, data: dict) -> UserProfile:
        profile = await self.get_user_profile(user_id)
        if profile:
            for k, v in data.items():
                if hasattr(profile, k):
                    setattr(profile, k, v)
        else:
            profile = UserProfile(user_id=user_id, **data)
            self.session.add(profile)
        await self.session.flush()
        return profile

    async def get_education_records(self, user_id: str) -> List[EducationRecord]:
        result = await self.session.execute(select(EducationRecord).where(EducationRecord.user_id == user_id).order_by(EducationRecord.graduation_year.desc()))
        return list(result.scalars().all())

    async def add_education_record(self, user_id: str, data: dict) -> EducationRecord:
        record = EducationRecord(user_id=user_id, **data)
        self.session.add(record)
        await self.session.flush()
        return record

    async def delete_education_record(self, user_id: str, record_id: str) -> None:
        await self.session.execute(delete(EducationRecord).where(EducationRecord.id == record_id, EducationRecord.user_id == user_id))
        await self.session.flush()

    async def get_work_experiences(self, user_id: str) -> List[WorkExperience]:
        result = await self.session.execute(select(WorkExperience).where(WorkExperience.user_id == user_id).order_by(WorkExperience.start_date.desc()))
        return list(result.scalars().all())

    async def add_work_experience(self, user_id: str, data: dict) -> WorkExperience:
        record = WorkExperience(user_id=user_id, **data)
        self.session.add(record)
        await self.session.flush()
        return record

    async def delete_work_experience(self, user_id: str, record_id: str) -> None:
        await self.session.execute(delete(WorkExperience).where(WorkExperience.id == record_id, WorkExperience.user_id == user_id))
        await self.session.flush()

    async def get_user_skills(self, user_id: str) -> List[UserSkill]:
        result = await self.session.execute(select(UserSkill).where(UserSkill.user_id == user_id))
        return list(result.scalars().all())

    async def add_user_skill(self, user_id: str, data: dict) -> UserSkill:
        record = UserSkill(user_id=user_id, **data)
        self.session.add(record)
        await self.session.flush()
        return record

    async def delete_user_skill(self, user_id: str, record_id: str) -> None:
        await self.session.execute(delete(UserSkill).where(UserSkill.id == record_id, UserSkill.user_id == user_id))
        await self.session.flush()

    async def get_user_languages(self, user_id: str) -> List[UserLanguage]:
        result = await self.session.execute(select(UserLanguage).where(UserLanguage.user_id == user_id))
        return list(result.scalars().all())

    async def add_user_language(self, user_id: str, data: dict) -> UserLanguage:
        record = UserLanguage(user_id=user_id, **data)
        self.session.add(record)
        await self.session.flush()
        return record

    async def delete_user_language(self, user_id: str, record_id: str) -> None:
        await self.session.execute(delete(UserLanguage).where(UserLanguage.id == record_id, UserLanguage.user_id == user_id))
        await self.session.flush()

    async def get_user_objectives(self, user_id: str) -> List[UserObjective]:
        result = await self.session.execute(select(UserObjective).where(UserObjective.user_id == user_id))
        return list(result.scalars().all())

    async def update_user_objectives(self, user_id: str, objective_ids: List[str]) -> None:
        # Simple replace for objectives
        await self.session.execute(delete(UserObjective).where(UserObjective.user_id == user_id))
        for obj_id in objective_ids:
            self.session.add(UserObjective(user_id=user_id, objective_id=obj_id))
        await self.session.flush()
