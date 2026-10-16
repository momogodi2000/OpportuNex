"""
Profile Service — business logic for profile management, completeness scoring, and CV extraction.
"""

from typing import Any

import structlog

from persistence.repositories.profile_repo import ProfileRepo

log = structlog.get_logger(__name__)


class ProfileService:
    def __init__(self, repo: ProfileRepo) -> None:
        self._repo = repo

    async def get_profile_summary(self, user_id: str) -> dict[str, Any]:
        """
        Calculates the completeness score and returns the profile summary.
        EF-02.10: Indicateur de complétude et suggestions des champs.
        """
        profile = await self._repo.get_user_profile(user_id)
        if not profile:
            return {
                "completeness_score": 0,
                "suggestions": ["Renseigner les informations générales (pays, ville, statut)"],
                "profile": None
            }

        score = 0
        suggestions = []

        # 1. Basic Info (25%)
        if profile.country_code and profile.city:
            score += 15
        else:
            suggestions.append("Ajouter votre pays et ville de résidence")
            
        if profile.professional_status:
            score += 10
        else:
            suggestions.append("Préciser votre statut actuel (étudiant, salarié, etc.)")

        # 2. Education (20%)
        education = await self._repo.get_education_records(user_id)
        if education:
            score += 20
        else:
            suggestions.append("Ajouter au moins une formation")

        # 3. Experience (20%)
        experience = await self._repo.get_work_experiences(user_id)
        if experience:
            score += 20
        else:
            suggestions.append("Ajouter au moins une expérience professionnelle")

        # 4. Skills & Languages (20%)
        skills = await self._repo.get_user_skills(user_id)
        languages = await self._repo.get_user_languages(user_id)
        if skills:
            score += 10
        else:
            suggestions.append("Ajouter vos compétences techniques")
            
        if languages:
            score += 10
        else:
            suggestions.append("Ajouter vos langues maîtrisées")

        # 5. Objectives (15%)
        objectives = await self._repo.get_user_objectives(user_id)
        if objectives:
            score += 15
        else:
            suggestions.append("Définir vos objectifs de recherche (emploi, bourse, etc.)")
            
        # Update completeness in DB
        profile.completeness_pct = score
        await self._repo.upsert_user_profile(user_id, {"completeness_pct": score})

        return {
            "completeness_score": score,
            "suggestions": suggestions,
            "profile": {
                "full_name": profile.full_name,
                "country_code": profile.country_code,
                "city": profile.city,
                "professional_status": profile.professional_status,
                "work_mode_pref": profile.work_mode_pref
            }
        }

    async def update_general_info(self, user_id: str, data: dict) -> dict[str, Any]:
        """Update general info. Missing fields are preserved."""
        await self._repo.upsert_user_profile(user_id, data)
        return await self.get_profile_summary(user_id)

    async def add_education(self, user_id: str, data: dict) -> dict:
        record = await self._repo.add_education_record(user_id, data)
        return {"id": record.id}

    async def add_experience(self, user_id: str, data: dict) -> dict:
        record = await self._repo.add_work_experience(user_id, data)
        return {"id": record.id}

    async def add_skill(self, user_id: str, data: dict) -> dict:
        record = await self._repo.add_user_skill(user_id, data)
        return {"id": record.id}

    async def add_language(self, user_id: str, data: dict) -> dict:
        record = await self._repo.add_user_language(user_id, data)
        return {"id": record.id}

    async def update_objectives(self, user_id: str, objective_ids: list[str]) -> None:
        await self._repo.update_user_objectives(user_id, objective_ids)

    # EF-03.01: CV Import (Placeholder for now until M03 is fully integrated)
    async def extract_cv(self, file_content: bytes, file_name: str, use_ai: bool = False) -> dict[str, Any]:
        """
        Analyzes the file in an isolated process.
        """
        # Minimal extraction fallback
        log.info("cv_extraction_started", file_name=file_name, use_ai=use_ai)
        return {
            "education": [],
            "experience": [],
            "skills": []
        }
