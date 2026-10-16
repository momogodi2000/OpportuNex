"""Profile (M02): general information, history, skills, languages, objectives, organisation."""

from __future__ import annotations

from datetime import date
from typing import Annotated, Any, Literal

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field, field_validator, model_validator

from api.deps import Active
from core.errors import ValidationFailed
from services.profile_service import ProfileService
from services.state import ActiveProfile

router = APIRouter(prefix="/profile", tags=["Profile"])

Country = Annotated[str, Field(pattern=r"^[A-Z]{2}$")]
IsoDate = Annotated[str, Field(pattern=r"^\d{4}-\d{2}(-\d{2})?$")]


def get_service(active: Active) -> ProfileService:
    return ProfileService(active)


Svc = Annotated[ProfileService, Depends(get_service)]


class GeneralIn(BaseModel):
    full_name: str | None = Field(default=None, max_length=160)
    country_code: Country | None = None
    city: str | None = Field(default=None, max_length=120)
    professional_status: (
        Literal[
            "student",
            "job_seeker",
            "employed",
            "self_employed",
            "freelancer",
            "entrepreneur",
            "researcher",
            "unemployed",
            "retired",
            "other",
        ]
        | None
    ) = None
    current_occupation: str | None = Field(default=None, max_length=160)
    experience_years: float | None = Field(default=None, ge=0, le=70)
    highest_education: (
        Literal[
            "none",
            "primary",
            "secondary",
            "bac",
            "bac_plus_2",
            "bachelor",
            "master",
            "doctorate",
            "postdoc",
            "vocational",
        ]
        | None
    ) = None
    work_mode_pref: Literal["remote", "hybrid", "onsite", "any"] | None = None
    willing_to_relocate: bool | None = None
    contact_phone: str | None = Field(default=None, max_length=40)
    bio: str | None = Field(default=None, max_length=2000)


class LocationIn(BaseModel):
    country_code: Country | None = None
    region_label: str | None = Field(default=None, max_length=80)
    city: str | None = Field(default=None, max_length=120)


def _check_period(start: str | None, end: str | None) -> None:
    if start and end and end < start:
        raise ValueError("end_date must not be before start_date")
    for d in (start, end):
        if d and len(d) == 10:
            date.fromisoformat(d)


class EducationIn(BaseModel):
    level: str = Field(min_length=1, max_length=60)
    field_of_study: str = Field(min_length=1, max_length=160)
    institution: str = Field(min_length=1, max_length=200)
    country_code: Country | None = None
    start_date: IsoDate | None = None
    end_date: IsoDate | None = None
    is_ongoing: bool = False
    grade: str | None = Field(default=None, max_length=60)
    achievements: str | None = Field(default=None, max_length=2000)

    @model_validator(mode="after")
    def _period(self) -> EducationIn:
        _check_period(self.start_date, self.end_date)
        return self


class ExperienceIn(BaseModel):
    job_title: str = Field(min_length=1, max_length=160)
    employer: str = Field(min_length=1, max_length=200)
    employment_type: (
        Literal["full_time", "part_time", "internship", "freelance", "volunteer", "consulting", "other"] | None
    ) = None
    country_code: Country | None = None
    city: str | None = Field(default=None, max_length=120)
    start_date: IsoDate
    end_date: IsoDate | None = None
    is_current: bool = False
    description: str | None = Field(default=None, max_length=4000)

    @model_validator(mode="after")
    def _period(self) -> ExperienceIn:
        _check_period(self.start_date, self.end_date)
        if self.is_current and self.end_date:
            raise ValueError("a current position has no end_date")
        return self


class CertificationIn(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    issuer: str | None = Field(default=None, max_length=200)
    obtained_on: IsoDate | None = None
    expires_on: IsoDate | None = None
    credential_url: str | None = Field(default=None, max_length=500)


class ProjectIn(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    category_id: int | None = None
    description: str | None = Field(default=None, max_length=4000)
    stage: Literal["idea", "prototype", "early", "growth", "scale", "established"] | None = None
    funding_need_minor: int | None = Field(default=None, ge=0)
    funding_min_minor: int | None = Field(default=None, ge=0)
    funding_max_minor: int | None = Field(default=None, ge=0)
    currency_code: str | None = Field(default=None, pattern=r"^[A-Z]{3}$")
    operating_country: Country | None = None
    beneficiaries: str | None = Field(default=None, max_length=1000)
    legal_status: str | None = Field(default=None, max_length=120)
    existing_resources: str | None = Field(default=None, max_length=2000)
    timeline_months: int | None = Field(default=None, gt=0, le=240)

    @model_validator(mode="after")
    def _range(self) -> ProjectIn:
        if (
            self.funding_min_minor is not None
            and self.funding_max_minor is not None
            and self.funding_max_minor < self.funding_min_minor
        ):
            raise ValueError("funding_max must be >= funding_min")
        return self


class SkillIn(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    level: int | None = Field(default=None, ge=1, le=5)
    years: float | None = Field(default=None, ge=0, le=60)
    is_primary: bool = False


class LanguageIn(BaseModel):
    language_code: str = Field(min_length=2, max_length=3)
    cefr_level: Literal["A1", "A2", "B1", "B2", "C1", "C2", "native"]


class LinkIn(BaseModel):
    kind: Literal["portfolio", "linkedin", "github", "website", "gitlab", "orcid", "other"]
    url: str = Field(min_length=8, max_length=500)

    @field_validator("url")
    @classmethod
    def _scheme(cls, v: str) -> str:
        if not v.startswith(("https://", "http://")):
            raise ValueError("url must start with http:// or https://")
        return v


class ObjectivesIn(BaseModel):
    objective_ids: list[int] = Field(default_factory=list, max_length=16)
    custom: list[str] = Field(default_factory=list, max_length=10)


class OrganizationIn(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    org_type: Literal["association", "ngo", "sme", "startup", "cooperative", "public", "academic", "other"]
    legal_status: str | None = Field(default=None, max_length=120)
    registration_no: str | None = Field(default=None, max_length=80)
    country_code: Country | None = None
    sector: str | None = Field(default=None, max_length=120)
    description: str | None = Field(default=None, max_length=4000)
    annual_budget_band: Literal["lt_10m_xaf", "10m_50m_xaf", "50m_250m_xaf", "gt_250m_xaf"] | None = None
    website: str | None = Field(default=None, max_length=300)


class SummaryIn(BaseModel):
    text: str = Field(max_length=3000)
    approved: bool


def _bool_to_int(values: dict[str, Any]) -> dict[str, Any]:
    return {k: (int(v) if isinstance(v, bool) else v) for k, v in values.items()}


@router.get("")
def get_profile(svc: Svc) -> dict[str, Any]:
    return svc.get()


@router.put("/general")
def update_general(body: GeneralIn, svc: Svc) -> dict[str, Any]:
    return svc.update_general(_bool_to_int(body.model_dump(exclude_unset=True)))


@router.put("/locations")
def set_locations(body: list[LocationIn], svc: Svc) -> dict[str, Any]:
    if len(body) > 10:
        raise ValidationFailed("at most 10 locations", code="too_many_locations")
    return svc.set_locations([b.model_dump() for b in body])


_MODELS: dict[str, type[BaseModel]] = {
    "education": EducationIn,
    "experiences": ExperienceIn,
    "certifications": CertificationIn,
    "projects": ProjectIn,
}


def _collection_routes(name: str, model: type[BaseModel]) -> None:
    def create(body: BaseModel, active: ActiveProfile) -> dict[str, Any]:
        return ProfileService(active).upsert_item(name, None, _bool_to_int(body.model_dump()))

    def replace(item_id: str, body: BaseModel, active: ActiveProfile) -> dict[str, Any]:
        return ProfileService(active).upsert_item(name, item_id, _bool_to_int(body.model_dump()))

    def remove(item_id: str, active: ActiveProfile) -> None:
        ProfileService(active).delete_item(name, item_id)

    # `from __future__ import annotations` turns annotations into strings that FastAPI
    # cannot resolve inside this closure, so bind the real types explicitly.
    for fn in (create, replace):
        fn.__annotations__ = {**fn.__annotations__, "body": model, "active": Active}
    remove.__annotations__ = {**remove.__annotations__, "active": Active}

    router.add_api_route(f"/{name}", create, methods=["POST"], status_code=201, name=f"create_{name}")
    router.add_api_route(f"/{name}/{{item_id}}", replace, methods=["PUT"], name=f"update_{name}")
    router.add_api_route(f"/{name}/{{item_id}}", remove, methods=["DELETE"], status_code=204, name=f"delete_{name}")


for _name, _model in _MODELS.items():
    _collection_routes(_name, _model)


@router.put("/skills")
def set_skills(body: list[SkillIn], svc: Svc) -> dict[str, Any]:
    if len(body) > 100:
        raise ValidationFailed("at most 100 skills", code="too_many_skills")
    return svc.set_skills([b.model_dump() for b in body])


@router.put("/languages")
def set_languages(body: list[LanguageIn], svc: Svc) -> dict[str, Any]:
    return svc.set_languages([b.model_dump() for b in body])


@router.put("/links")
def set_links(body: list[LinkIn], svc: Svc) -> dict[str, Any]:
    return svc.set_links([b.model_dump() for b in body])


@router.put("/objectives")
def set_objectives(body: ObjectivesIn, svc: Svc) -> dict[str, Any]:
    return svc.set_objectives(body.objective_ids, body.custom)


@router.put("/organization")
def set_organization(body: OrganizationIn, svc: Svc) -> dict[str, Any]:
    return svc.set_organization(body.model_dump())


@router.delete("/organization")
def delete_organization(svc: Svc) -> dict[str, Any]:
    return svc.set_organization(None)


@router.post("/summary/generate")
def generate_summary(svc: Svc, lang: Literal["fr", "en"] = "fr") -> dict[str, str]:
    return {"text": svc.generate_summary(lang), "provenance": "generated_from_profile"}


@router.put("/summary")
def save_summary(body: SummaryIn, svc: Svc) -> dict[str, Any]:
    return svc.save_summary(body.text, body.approved)


@router.post("/onboarding/complete")
def complete_onboarding(svc: Svc) -> dict[str, Any]:
    return svc.complete_onboarding()


def profile_service_for(active: ActiveProfile) -> ProfileService:
    return ProfileService(active)
