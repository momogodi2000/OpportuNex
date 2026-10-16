"""Strict output contracts (arch §7.2-4): anything that does not validate is rejected, never repaired silently."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class _Strict(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


Short = Field(default=None, max_length=300)


class QueryOut(_Strict):
    """Task ``query_interpretation``: the same editable filters as the rule-based interpreter."""

    categories: list[str] = Field(default_factory=list, max_length=5)
    countries: list[str] = Field(default_factory=list, max_length=15)
    languages: list[str] = Field(default_factory=list, max_length=5)
    keywords: list[str] = Field(default_factory=list, max_length=12)
    work_mode: Literal["remote", "hybrid", "onsite"] | None = None
    amount_min: int | None = Field(default=None, ge=0)
    amount_currency: str | None = Field(default=None, min_length=3, max_length=3)
    deadline_before: str | None = Field(default=None, pattern=r"^\d{4}-\d{2}-\d{2}$")
    experience_max_years: int | None = Field(default=None, ge=0, le=60)


class Evidenced(_Strict):
    """A value with the source excerpt that justifies it (EF-07.02/03)."""

    value: str | None = Field(default=None, max_length=500)
    evidence: str | None = Field(default=None, max_length=600)
    inferred: bool = False


class ExtractionOut(_Strict):
    """Task ``extraction`` (EF-07.01): structured fields, verbatim clauses and a ≤ 5-line summary."""

    organization: Evidenced = Field(default_factory=Evidenced)
    deadline: Evidenced = Field(default_factory=Evidenced)
    amount: Evidenced = Field(default_factory=Evidenced)
    currency: Evidenced = Field(default_factory=Evidenced)
    country: Evidenced = Field(default_factory=Evidenced)
    work_mode: Evidenced = Field(default_factory=Evidenced)
    category: Evidenced = Field(default_factory=Evidenced)
    target_audience: Evidenced = Field(default_factory=Evidenced)
    application_url: Evidenced = Field(default_factory=Evidenced)
    eligibility: list[str] = Field(default_factory=list, max_length=15)
    required_documents: list[str] = Field(default_factory=list, max_length=20)
    summary: list[str] = Field(default_factory=list, max_length=5)


class TranslationOut(_Strict):
    title: str = Field(max_length=400)
    summary: list[str] = Field(default_factory=list, max_length=5)
    description: str = Field(default="", max_length=12000)


class CvEducation(_Strict):
    degree: str = Field(max_length=200)
    field_of_study: str | None = Short
    institution: str | None = Short
    start_date: str | None = Field(default=None, pattern=r"^\d{4}(-\d{2})?$")
    end_date: str | None = Field(default=None, pattern=r"^\d{4}(-\d{2})?$")
    ongoing: bool = False


class CvExperience(_Strict):
    job_title: str = Field(max_length=200)
    employer: str | None = Short
    start_date: str = Field(pattern=r"^\d{4}(-\d{2})?$")
    end_date: str | None = Field(default=None, pattern=r"^\d{4}(-\d{2})?$")
    current: bool = False
    description: str | None = Field(default=None, max_length=2000)


class CvLanguage(_Strict):
    code: str = Field(min_length=2, max_length=3)
    level: Literal["A1", "A2", "B1", "B2", "C1", "C2", "native"] | None = None


class CvCertification(_Strict):
    name: str = Field(max_length=200)
    obtained_on: str | None = Field(default=None, pattern=r"^\d{4}(-\d{2})?$")


class CvOut(_Strict):
    """Task ``cv_parsing`` (EF-03.03)."""

    education: list[CvEducation] = Field(default_factory=list, max_length=20)
    experience: list[CvExperience] = Field(default_factory=list, max_length=30)
    skills: list[str] = Field(default_factory=list, max_length=80)
    languages: list[CvLanguage] = Field(default_factory=list, max_length=10)
    certifications: list[CvCertification] = Field(default_factory=list, max_length=30)


class DraftOut(_Strict):
    """Task ``document_drafting`` (EF-10.06): Markdown body only; the header is filled in locally."""

    body: str = Field(min_length=20, max_length=12000)
