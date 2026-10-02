"""
SQLAlchemy ORM models — core tables from pio_schema.sql baseline.
All models use UUID primary keys and STRICT typing for SQLite.
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    event,
)
from sqlalchemy.dialects.sqlite import BLOB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from persistence.models.base import Base


def _now() -> datetime:
    return datetime.utcnow()


def _uuid() -> str:
    return str(uuid.uuid4())


# ═══════════════════════════════════════════════════════════════════════════
#  Application settings
# ═══════════════════════════════════════════════════════════════════════════

class ApplicationSettings(Base):
    __tablename__ = "application_settings"

    key: Mapped[str] = mapped_column(String(100), primary_key=True)
    value: Mapped[str] = mapped_column(Text, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=_now, onupdate=_now, nullable=False
    )


# ═══════════════════════════════════════════════════════════════════════════
#  Reference data
# ═══════════════════════════════════════════════════════════════════════════

class Country(Base):
    __tablename__ = "countries"

    code: Mapped[str] = mapped_column(String(2), primary_key=True)   # ISO 3166-1 alpha-2
    name_fr: Mapped[str] = mapped_column(String(100), nullable=False)
    name_en: Mapped[str] = mapped_column(String(100), nullable=False)
    region: Mapped[Optional[str]] = mapped_column(String(50))


class Currency(Base):
    __tablename__ = "currencies"

    code: Mapped[str] = mapped_column(String(3), primary_key=True)   # ISO 4217
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    symbol: Mapped[str] = mapped_column(String(10), nullable=False)
    minor_unit: Mapped[int] = mapped_column(Integer, default=2)       # XAF = 0


class Language(Base):
    __tablename__ = "languages"

    code: Mapped[str] = mapped_column(String(5), primary_key=True)   # ISO 639-1
    name_fr: Mapped[str] = mapped_column(String(50), nullable=False)
    name_en: Mapped[str] = mapped_column(String(50), nullable=False)


class OpportunityCategory(Base):
    __tablename__ = "opportunity_categories"

    id: Mapped[str] = mapped_column(String(50), primary_key=True)
    parent_id: Mapped[Optional[str]] = mapped_column(
        String(50), ForeignKey("opportunity_categories.id")
    )
    label_fr: Mapped[str] = mapped_column(String(100), nullable=False)
    label_en: Mapped[str] = mapped_column(String(100), nullable=False)


class Skill(Base):
    __tablename__ = "skills"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    name: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    category: Mapped[Optional[str]] = mapped_column(String(50))


# ═══════════════════════════════════════════════════════════════════════════
#  Identity
# ═══════════════════════════════════════════════════════════════════════════

class UserModel(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    email: Mapped[str] = mapped_column(String(255), nullable=False, unique=True)
    display_name: Mapped[str] = mapped_column(String(100), nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    recovery_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    is_locked: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    failed_login_attempts: Mapped[int] = mapped_column(Integer, default=0)
    lock_until: Mapped[Optional[datetime]] = mapped_column(DateTime)
    sync_mode: Mapped[str] = mapped_column(
        String(10), default="local", nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=_now, onupdate=_now, nullable=False
    )

    __table_args__ = (
        CheckConstraint("sync_mode IN ('local', 'synced')", name="ck_users_sync_mode"),
    )

    # Relationships
    profile: Mapped["UserProfile"] = relationship(back_populates="user", uselist=False)
    sessions: Mapped[list["UserSession"]] = relationship(back_populates="user")
    consents: Mapped[list["Consent"]] = relationship(back_populates="user")
    workspaces: Mapped[list["ResearchWorkspace"]] = relationship(back_populates="user")
    saved_opportunities: Mapped[list["SavedOpportunity"]] = relationship(
        back_populates="user"
    )
    monitors: Mapped[list["Monitor"]] = relationship(back_populates="user")
    ai_providers: Mapped[list["AIProvider"]] = relationship(back_populates="user")


class UserSession(Base):
    __tablename__ = "user_sessions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    token_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    expires_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    last_seen_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    user: Mapped[UserModel] = relationship(back_populates="sessions")


class Consent(Base):
    __tablename__ = "consents"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    purpose: Mapped[str] = mapped_column(String(100), nullable=False)
    granted: Mapped[bool] = mapped_column(Boolean, nullable=False)
    granted_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    revoked_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    provider_id: Mapped[Optional[str]] = mapped_column(String(36))

    user: Mapped[UserModel] = relationship(back_populates="consents")

    __table_args__ = (
        UniqueConstraint("user_id", "purpose", name="uq_consents_user_purpose"),
    )


# ═══════════════════════════════════════════════════════════════════════════
#  Profile
# ═══════════════════════════════════════════════════════════════════════════

class UserProfile(Base):
    __tablename__ = "user_profiles"

    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    country_code: Mapped[Optional[str]] = mapped_column(
        String(2), ForeignKey("countries.code")
    )
    city: Mapped[Optional[str]] = mapped_column(String(100))
    status: Mapped[Optional[str]] = mapped_column(String(50))
    work_mode: Mapped[Optional[str]] = mapped_column(String(20))
    mobility: Mapped[Optional[str]] = mapped_column(String(20))
    summary: Mapped[Optional[str]] = mapped_column(Text)
    summary_validated: Mapped[bool] = mapped_column(Boolean, default=False)
    completeness_score: Mapped[int] = mapped_column(Integer, default=0)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=_now, onupdate=_now, nullable=False
    )

    __table_args__ = (
        CheckConstraint(
            "work_mode IN ('remote', 'hybrid', 'onsite', NULL)",
            name="ck_profile_work_mode",
        ),
        CheckConstraint(
            "completeness_score BETWEEN 0 AND 100",
            name="ck_profile_completeness",
        ),
    )

    user: Mapped[UserModel] = relationship(back_populates="profile")
    education_records: Mapped[list["EducationRecord"]] = relationship(
        back_populates="profile"
    )
    work_experiences: Mapped[list["WorkExperience"]] = relationship(
        back_populates="profile"
    )
    skills: Mapped[list["UserSkill"]] = relationship(back_populates="profile")
    languages: Mapped[list["UserLanguage"]] = relationship(back_populates="profile")
    objectives: Mapped[list["UserObjective"]] = relationship(back_populates="profile")


class EducationRecord(Base):
    __tablename__ = "education_records"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("user_profiles.user_id", ondelete="CASCADE")
    )
    degree_level: Mapped[Optional[str]] = mapped_column(String(50))
    field_of_study: Mapped[Optional[str]] = mapped_column(String(100))
    institution: Mapped[Optional[str]] = mapped_column(String(200))
    graduation_year: Mapped[Optional[int]] = mapped_column(Integer)
    country_code: Mapped[Optional[str]] = mapped_column(
        String(2), ForeignKey("countries.code")
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    profile: Mapped[UserProfile] = relationship(back_populates="education_records")


class WorkExperience(Base):
    __tablename__ = "work_experiences"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("user_profiles.user_id", ondelete="CASCADE")
    )
    job_title: Mapped[str] = mapped_column(String(200), nullable=False)
    employer: Mapped[Optional[str]] = mapped_column(String(200))
    start_date: Mapped[Optional[str]] = mapped_column(String(10))    # YYYY-MM
    end_date: Mapped[Optional[str]] = mapped_column(String(10))
    is_current: Mapped[bool] = mapped_column(Boolean, default=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    country_code: Mapped[Optional[str]] = mapped_column(
        String(2), ForeignKey("countries.code")
    )

    profile: Mapped[UserProfile] = relationship(back_populates="work_experiences")


class UserSkill(Base):
    __tablename__ = "user_skills"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("user_profiles.user_id", ondelete="CASCADE")
    )
    skill_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("skills.id"), nullable=False
    )
    level: Mapped[Optional[str]] = mapped_column(String(20))    # beginner/intermediate/advanced/expert

    profile: Mapped[UserProfile] = relationship(back_populates="skills")


class UserLanguage(Base):
    __tablename__ = "user_languages"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("user_profiles.user_id", ondelete="CASCADE")
    )
    language_code: Mapped[str] = mapped_column(
        String(5), ForeignKey("languages.code"), nullable=False
    )
    cefr_level: Mapped[Optional[str]] = mapped_column(String(2))    # A1-C2

    __table_args__ = (
        CheckConstraint(
            "cefr_level IN ('A1','A2','B1','B2','C1','C2', NULL)",
            name="ck_user_lang_cefr",
        ),
    )

    profile: Mapped[UserProfile] = relationship(back_populates="languages")


class UserObjective(Base):
    __tablename__ = "user_objectives"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("user_profiles.user_id", ondelete="CASCADE")
    )
    objective_code: Mapped[str] = mapped_column(String(50), nullable=False)
    priority: Mapped[int] = mapped_column(Integer, default=5)

    profile: Mapped[UserProfile] = relationship(back_populates="objectives")


# ═══════════════════════════════════════════════════════════════════════════
#  Sources
# ═══════════════════════════════════════════════════════════════════════════

class Source(Base):
    __tablename__ = "sources"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    base_url: Mapped[str] = mapped_column(String(500), nullable=False)
    country_code: Mapped[Optional[str]] = mapped_column(
        String(2), ForeignKey("countries.code")
    )
    language_code: Mapped[Optional[str]] = mapped_column(
        String(5), ForeignKey("languages.code")
    )
    status: Mapped[str] = mapped_column(String(20), default="active", nullable=False)
    is_official: Mapped[bool] = mapped_column(Boolean, default=False)
    requires_headless: Mapped[bool] = mapped_column(Boolean, default=False)
    reliability_score: Mapped[float] = mapped_column(Float, default=0.5)
    last_success_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    last_error_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    consecutive_failures: Mapped[int] = mapped_column(Integer, default=0)
    min_crawl_interval_minutes: Mapped[int] = mapped_column(Integer, default=60)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=_now, onupdate=_now, nullable=False
    )

    __table_args__ = (
        CheckConstraint(
            "status IN ('active', 'inactive', 'error', 'excluded')",
            name="ck_source_status",
        ),
        CheckConstraint(
            "min_crawl_interval_minutes >= 60",
            name="ck_source_min_interval",
        ),
        CheckConstraint(
            "reliability_score BETWEEN 0.0 AND 1.0",
            name="ck_source_reliability",
        ),
    )

    scan_runs: Mapped[list["SourceScanRun"]] = relationship(back_populates="source")
    adapters: Mapped[list["SourceAdapter"]] = relationship(back_populates="source")


class SourceAdapter(Base):
    __tablename__ = "source_adapters"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    source_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("sources.id", ondelete="CASCADE"), nullable=False
    )
    version: Mapped[int] = mapped_column(Integer, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    adapter_json: Mapped[str] = mapped_column(Text, nullable=False)   # Declarative JSON
    signature: Mapped[Optional[str]] = mapped_column(String(500))     # Sigstore/minisign
    access_method: Mapped[str] = mapped_column(String(20), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    __table_args__ = (
        CheckConstraint(
            "access_method IN ('api','rss','html','jsonld','pdf','headless')",
            name="ck_adapter_method",
        ),
        UniqueConstraint(
            "source_id",
            "is_active",
            name="uq_adapter_active_per_source",
        ),
    )

    source: Mapped[Source] = relationship(back_populates="adapters")


class SourceScanRun(Base):
    __tablename__ = "source_scan_runs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    source_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("sources.id", ondelete="CASCADE"), nullable=False
    )
    started_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    finished_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    status: Mapped[str] = mapped_column(String(20), default="running")
    items_found: Mapped[int] = mapped_column(Integer, default=0)
    items_new: Mapped[int] = mapped_column(Integer, default=0)
    error_message: Mapped[Optional[str]] = mapped_column(Text)

    source: Mapped[Source] = relationship(back_populates="scan_runs")


# ═══════════════════════════════════════════════════════════════════════════
#  Opportunities
# ═══════════════════════════════════════════════════════════════════════════

class OpportunityModel(Base):
    __tablename__ = "opportunities"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    canonical_url: Mapped[str] = mapped_column(String(2000), nullable=False, unique=True)
    status: Mapped[str] = mapped_column(String(20), default="collected", nullable=False)
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    organization: Mapped[Optional[str]] = mapped_column(String(200))
    category_id: Mapped[Optional[str]] = mapped_column(
        String(50), ForeignKey("opportunity_categories.id")
    )
    deadline_raw: Mapped[Optional[str]] = mapped_column(String(100))
    deadline_iso: Mapped[Optional[str]] = mapped_column(String(20))
    location: Mapped[Optional[str]] = mapped_column(String(300))
    country_code: Mapped[Optional[str]] = mapped_column(
        String(2), ForeignKey("countries.code")
    )
    language_code: Mapped[Optional[str]] = mapped_column(
        String(5), ForeignKey("languages.code")
    )
    amount_min: Mapped[Optional[int]] = mapped_column(Integer)
    amount_max: Mapped[Optional[int]] = mapped_column(Integer)
    currency_code: Mapped[Optional[str]] = mapped_column(
        String(3), ForeignKey("currencies.code")
    )
    summary: Mapped[Optional[str]] = mapped_column(Text)
    eligibility_verbatim: Mapped[Optional[str]] = mapped_column(Text)
    content_fingerprint: Mapped[Optional[str]] = mapped_column(String(64))  # SHA-256
    simhash: Mapped[Optional[int]] = mapped_column(Integer)
    is_ai_analysed: Mapped[bool] = mapped_column(Boolean, default=False)
    collected_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    analysed_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    verified_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=_now, onupdate=_now, nullable=False
    )

    __table_args__ = (
        CheckConstraint(
            "status IN ('collected','analysed','error','modified','expired','withdrawn')",
            name="ck_opp_status",
        ),
        CheckConstraint(
            "(amount_max IS NULL) OR (amount_max >= amount_min)",
            name="ck_opp_amount_range",
        ),
    )

    fields: Mapped[list["OpportunityField"]] = relationship(back_populates="opportunity")
    sources: Mapped[list["OpportunitySource"]] = relationship(back_populates="opportunity")
    match_scores: Mapped[list["MatchScoreModel"]] = relationship(back_populates="opportunity")


class OpportunityField(Base):
    """Individual provenanced fields for an opportunity."""
    __tablename__ = "opportunity_fields"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    opportunity_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("opportunities.id", ondelete="CASCADE"), nullable=False
    )
    field_name: Mapped[str] = mapped_column(String(100), nullable=False)
    value: Mapped[Optional[str]] = mapped_column(Text)
    provenance: Mapped[str] = mapped_column(String(20), nullable=False)
    excerpt: Mapped[Optional[str]] = mapped_column(Text)
    confidence: Mapped[float] = mapped_column(Float, default=1.0)
    prompt_version: Mapped[Optional[str]] = mapped_column(String(20))

    __table_args__ = (
        CheckConstraint(
            "provenance IN ('explicit','inferred','generated','not_specified','unverifiable')",
            name="ck_field_provenance",
        ),
    )

    opportunity: Mapped[OpportunityModel] = relationship(back_populates="fields")


class OpportunitySource(Base):
    __tablename__ = "opportunity_sources"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    opportunity_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("opportunities.id", ondelete="CASCADE"), nullable=False
    )
    source_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("sources.id"), nullable=False
    )
    source_url: Mapped[str] = mapped_column(String(2000), nullable=False)
    external_id: Mapped[Optional[str]] = mapped_column(String(500))
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False)
    collected_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    opportunity: Mapped[OpportunityModel] = relationship(back_populates="sources")


# ═══════════════════════════════════════════════════════════════════════════
#  Matching
# ═══════════════════════════════════════════════════════════════════════════

class MatchScoreModel(Base):
    __tablename__ = "match_scores"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    opportunity_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("opportunities.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    total_score: Mapped[int] = mapped_column(Integer, nullable=False)
    eligibility: Mapped[str] = mapped_column(String(20), nullable=False)
    criteria_json: Mapped[str] = mapped_column(Text, nullable=False)   # JSON
    strengths_json: Mapped[str] = mapped_column(Text, default="[]")
    gaps_json: Mapped[str] = mapped_column(Text, default="[]")
    conditions_json: Mapped[str] = mapped_column(Text, default="[]")
    profile_fingerprint: Mapped[str] = mapped_column(String(64), nullable=False)
    opportunity_fingerprint: Mapped[str] = mapped_column(String(64), nullable=False)
    calculated_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    __table_args__ = (
        CheckConstraint(
            "total_score BETWEEN 0 AND 100",
            name="ck_score_range",
        ),
        CheckConstraint(
            "eligibility IN ('probable','uncertain','unlikely')",
            name="ck_score_eligibility",
        ),
        UniqueConstraint("opportunity_id", "user_id", name="uq_score_opp_user"),
    )

    opportunity: Mapped[OpportunityModel] = relationship(back_populates="match_scores")


# ═══════════════════════════════════════════════════════════════════════════
#  Saved opportunities & Applications
# ═══════════════════════════════════════════════════════════════════════════

class SavedOpportunity(Base):
    __tablename__ = "saved_opportunities"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    opportunity_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("opportunities.id"), nullable=False
    )
    priority: Mapped[str] = mapped_column(String(10), default="medium")
    notes: Mapped[Optional[str]] = mapped_column(Text)
    personal_deadline: Mapped[Optional[str]] = mapped_column(String(20))
    saved_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=_now, onupdate=_now, nullable=False
    )

    __table_args__ = (
        CheckConstraint(
            "priority IN ('high','medium','low')",
            name="ck_saved_priority",
        ),
        UniqueConstraint("user_id", "opportunity_id", name="uq_saved_user_opp"),
    )

    user: Mapped[UserModel] = relationship(back_populates="saved_opportunities")
    application: Mapped[Optional["ApplicationModel"]] = relationship(
        back_populates="saved_opportunity", uselist=False
    )
    reminders: Mapped[list["ReminderModel"]] = relationship(
        back_populates="saved_opportunity"
    )


class ApplicationModel(Base):
    __tablename__ = "applications"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    saved_opportunity_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("saved_opportunities.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    status: Mapped[str] = mapped_column(String(30), default="discovered", nullable=False)
    submitted_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=_now, onupdate=_now, nullable=False
    )

    __table_args__ = (
        CheckConstraint(
            "status IN ('discovered','to_review','in_preparation','ready',"
            "'submitted','interview_evaluation','accepted','rejected',"
            "'withdrawn','expired','archived')",
            name="ck_app_status",
        ),
        # A submitted application MUST have a submission date
        CheckConstraint(
            "(status != 'submitted') OR (submitted_at IS NOT NULL)",
            name="ck_app_submitted_requires_date",
        ),
    )

    saved_opportunity: Mapped[SavedOpportunity] = relationship(
        back_populates="application"
    )
    status_history: Mapped[list["ApplicationStatusHistory"]] = relationship(
        back_populates="application", order_by="ApplicationStatusHistory.changed_at"
    )


class ApplicationStatusHistory(Base):
    __tablename__ = "application_status_history"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    application_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("applications.id", ondelete="CASCADE"), nullable=False
    )
    old_status: Mapped[Optional[str]] = mapped_column(String(30))
    new_status: Mapped[str] = mapped_column(String(30), nullable=False)
    changed_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    note: Mapped[Optional[str]] = mapped_column(Text)

    application: Mapped[ApplicationModel] = relationship(back_populates="status_history")


# ═══════════════════════════════════════════════════════════════════════════
#  Research workspaces
# ═══════════════════════════════════════════════════════════════════════════

class ResearchWorkspace(Base):
    __tablename__ = "research_workspaces"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    template: Mapped[Optional[str]] = mapped_column(String(50))
    is_archived: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=_now, onupdate=_now, nullable=False
    )

    user: Mapped[UserModel] = relationship(back_populates="workspaces")
    search_queries: Mapped[list["SearchQuery"]] = relationship(back_populates="workspace")


class SearchQuery(Base):
    __tablename__ = "search_queries"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    workspace_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("research_workspaces.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    raw_query: Mapped[str] = mapped_column(Text, nullable=False)
    interpreted_filters: Mapped[Optional[str]] = mapped_column(Text)   # JSON
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    workspace: Mapped[ResearchWorkspace] = relationship(back_populates="search_queries")
    runs: Mapped[list["SearchRun"]] = relationship(back_populates="query")


class SearchRun(Base):
    __tablename__ = "search_runs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    query_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("search_queries.id", ondelete="CASCADE"), nullable=False
    )
    started_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    finished_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    status: Mapped[str] = mapped_column(String(20), default="running")
    total_results: Mapped[int] = mapped_column(Integer, default=0)
    new_results: Mapped[int] = mapped_column(Integer, default=0)
    error_message: Mapped[Optional[str]] = mapped_column(Text)

    query: Mapped[SearchQuery] = relationship(back_populates="runs")


# ═══════════════════════════════════════════════════════════════════════════
#  Monitors (scheduled watches)
# ═══════════════════════════════════════════════════════════════════════════

class Monitor(Base):
    __tablename__ = "monitors"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    filters_json: Mapped[str] = mapped_column(Text, nullable=False)     # JSON
    frequency: Mapped[str] = mapped_column(String(20), default="daily")
    min_score: Mapped[int] = mapped_column(Integer, default=50)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    next_run_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    last_run_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    __table_args__ = (
        CheckConstraint(
            "min_score BETWEEN 0 AND 100",
            name="ck_monitor_min_score",
        ),
        CheckConstraint(
            "frequency IN ('daily','weekly','custom')",
            name="ck_monitor_frequency",
        ),
    )

    user: Mapped[UserModel] = relationship(back_populates="monitors")


# ═══════════════════════════════════════════════════════════════════════════
#  AI providers
# ═══════════════════════════════════════════════════════════════════════════

class AIProvider(Base):
    __tablename__ = "ai_providers"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    provider_type: Mapped[str] = mapped_column(String(30), nullable=False)
    model_name: Mapped[str] = mapped_column(String(100), nullable=False)
    # API key is stored in the OS keychain; only a reference ID is stored here
    keychain_ref: Mapped[Optional[str]] = mapped_column(String(200))
    base_url: Mapped[Optional[str]] = mapped_column(String(500))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_local: Mapped[bool] = mapped_column(Boolean, default=False)
    daily_token_limit: Mapped[Optional[int]] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    __table_args__ = (
        CheckConstraint(
            "provider_type IN ('openai_compat','gemini','anthropic','ollama','lmstudio')",
            name="ck_provider_type",
        ),
    )

    user: Mapped[UserModel] = relationship(back_populates="ai_providers")


# ═══════════════════════════════════════════════════════════════════════════
#  Background jobs
# ═══════════════════════════════════════════════════════════════════════════

class BackgroundJob(Base):
    __tablename__ = "background_jobs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[Optional[str]] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="SET NULL")
    )
    job_type: Mapped[str] = mapped_column(String(50), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="pending", nullable=False)
    progress: Mapped[int] = mapped_column(Integer, default=0)
    total: Mapped[int] = mapped_column(Integer, default=0)
    checkpoint_json: Mapped[Optional[str]] = mapped_column(Text)   # For resume
    error_message: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    finished_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    cancel_requested: Mapped[bool] = mapped_column(Boolean, default=False)

    __table_args__ = (
        CheckConstraint(
            "status IN ('pending','running','completed','failed','cancelled')",
            name="ck_job_status",
        ),
    )


# ═══════════════════════════════════════════════════════════════════════════
#  Backup records
# ═══════════════════════════════════════════════════════════════════════════

class BackupRecord(Base):
    __tablename__ = "backup_records"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    backup_type: Mapped[str] = mapped_column(String(20), default="full")
    status: Mapped[str] = mapped_column(String(20), default="pending", nullable=False)
    file_path: Mapped[Optional[str]] = mapped_column(String(1000))
    file_size_bytes: Mapped[Optional[int]] = mapped_column(Integer)
    compressed_size_bytes: Mapped[Optional[int]] = mapped_column(Integer)
    checksum_sha256: Mapped[Optional[str]] = mapped_column(String(64))
    triggered_by: Mapped[str] = mapped_column(String(20), default="scheduler")
    started_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    finished_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    error_message: Mapped[Optional[str]] = mapped_column(Text)

    __table_args__ = (
        CheckConstraint(
            "status IN ('pending','in_progress','success','failed','corrupted','deleted')",
            name="ck_backup_status",
        ),
        CheckConstraint(
            "triggered_by IN ('scheduler','manual')",
            name="ck_backup_trigger",
        ),
    )


# ═══════════════════════════════════════════════════════════════════════════
#  Reminders & Notifications
# ═══════════════════════════════════════════════════════════════════════════

class ReminderModel(Base):
    __tablename__ = "reminders"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    saved_opportunity_id: Mapped[Optional[str]] = mapped_column(
        String(36), ForeignKey("saved_opportunities.id", ondelete="CASCADE")
    )
    due_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    body: Mapped[Optional[str]] = mapped_column(Text)
    is_sent: Mapped[bool] = mapped_column(Boolean, default=False)
    sent_at: Mapped[Optional[datetime]] = mapped_column(DateTime)

    saved_opportunity: Mapped[Optional[SavedOpportunity]] = relationship(
        back_populates="reminders"
    )


class NotificationRecord(Base):
    __tablename__ = "notification_records"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    notification_type: Mapped[str] = mapped_column(String(50), nullable=False)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    body: Mapped[Optional[str]] = mapped_column(Text)
    is_read: Mapped[bool] = mapped_column(Boolean, default=False)
    related_id: Mapped[Optional[str]] = mapped_column(String(36))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    read_at: Mapped[Optional[datetime]] = mapped_column(DateTime)


# ═══════════════════════════════════════════════════════════════════════════
#  Security events
# ═══════════════════════════════════════════════════════════════════════════

class SecurityEvent(Base):
    __tablename__ = "security_events"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    event_type: Mapped[str] = mapped_column(String(50), nullable=False)
    user_id: Mapped[Optional[str]] = mapped_column(String(36))
    details_json: Mapped[Optional[str]] = mapped_column(Text)
    occurred_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
