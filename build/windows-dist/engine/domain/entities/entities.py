"""
Domain entities for OpportuNex.
These are pure Python classes with no external dependencies.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from enum import StrEnum
from typing import Optional
from uuid import UUID


# ═══════════════════════════════════════════════════════════════════════════
#  User
# ═══════════════════════════════════════════════════════════════════════════

@dataclass(frozen=True)
class User:
    id: UUID
    email: str
    display_name: str
    password_hash: str          # Argon2id hash
    recovery_hash: str          # Hash of the 12-word recovery phrase
    is_locked: bool
    failed_login_attempts: int
    lock_until: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    sync_mode: str              # "local" | "synced"

    def can_login(self, now: datetime) -> bool:
        """Returns False if account is in lockout period."""
        if not self.is_locked:
            return True
        if self.lock_until is None:
            return False
        return now >= self.lock_until


# ═══════════════════════════════════════════════════════════════════════════
#  Opportunity
# ═══════════════════════════════════════════════════════════════════════════

class OpportunityStatus(StrEnum):
    COLLECTED = "collected"
    ANALYSED = "analysed"
    ERROR = "error"
    MODIFIED = "modified"
    EXPIRED = "expired"
    WITHDRAWN = "withdrawn"


class ProvenanceTag(StrEnum):
    EXPLICIT = "explicit"
    INFERRED = "inferred"
    GENERATED = "generated"
    NOT_SPECIFIED = "not_specified"
    UNVERIFIABLE = "unverifiable"


@dataclass(frozen=True)
class ProvenancedField:
    """A field value with its source excerpt and provenance tag."""
    value: Optional[str]
    provenance: ProvenanceTag
    excerpt: Optional[str] = None          # Original text from source
    confidence: float = 1.0


@dataclass(frozen=True)
class Opportunity:
    id: UUID
    canonical_url: str
    status: OpportunityStatus
    # Core fields — all provenanced
    title: ProvenancedField
    organization: ProvenancedField
    category: str
    subcategory: Optional[str]
    deadline: ProvenancedField
    location: ProvenancedField
    amount_min: Optional[int]              # In minor currency units
    amount_max: Optional[int]
    currency_code: Optional[str]           # ISO 4217
    language: str                          # ISO 639-1
    summary: Optional[str]                 # AI-generated ≤ 5 lines
    eligibility_text: Optional[str]        # Verbatim from source
    # Metadata
    collected_at: datetime
    analysed_at: Optional[datetime]
    verified_at: Optional[datetime]
    is_ai_generated: bool
    source_ids: list[UUID] = field(default_factory=list)

    def is_expired(self, now: datetime) -> bool:
        if self.deadline.value is None:
            return False
        try:
            dl = datetime.fromisoformat(self.deadline.value)
            return now > dl
        except ValueError:
            return False

    def deadline_days_remaining(self, now: datetime) -> Optional[int]:
        if self.deadline.value is None:
            return None
        try:
            dl = datetime.fromisoformat(self.deadline.value)
            return max(0, (dl - now).days)
        except ValueError:
            return None


# ═══════════════════════════════════════════════════════════════════════════
#  Match Score
# ═══════════════════════════════════════════════════════════════════════════

@dataclass(frozen=True)
class CriterionScore:
    name: str
    score: float          # 0.0 – 1.0
    weight: float
    explanation: Optional[str]
    not_evaluated: bool = False   # True when criterion has no data


@dataclass(frozen=True)
class MatchScore:
    opportunity_id: UUID
    user_id: UUID
    total_score: int              # 0 – 100
    eligibility: str              # "probable" | "uncertain" | "unlikely"
    criteria: list[CriterionScore]
    strengths: list[str]
    gaps: list[str]
    conditions_to_verify: list[str]
    calculated_at: datetime
    profile_fingerprint: str      # SHA-256 of profile state
    opportunity_fingerprint: str  # SHA-256 of opportunity state


# ═══════════════════════════════════════════════════════════════════════════
#  Application (candidature)
# ═══════════════════════════════════════════════════════════════════════════

class ApplicationStatus(StrEnum):
    DISCOVERED = "discovered"
    TO_REVIEW = "to_review"
    IN_PREPARATION = "in_preparation"
    READY = "ready"
    SUBMITTED = "submitted"
    INTERVIEW = "interview_evaluation"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    WITHDRAWN = "withdrawn"
    EXPIRED = "expired"
    ARCHIVED = "archived"


# Valid transitions for the application state machine
APPLICATION_TRANSITIONS: dict[ApplicationStatus, set[ApplicationStatus]] = {
    ApplicationStatus.DISCOVERED:      {ApplicationStatus.TO_REVIEW},
    ApplicationStatus.TO_REVIEW:       {
        ApplicationStatus.IN_PREPARATION,
        ApplicationStatus.ARCHIVED,
        ApplicationStatus.EXPIRED,
    },
    ApplicationStatus.IN_PREPARATION:  {
        ApplicationStatus.READY,
        ApplicationStatus.WITHDRAWN,
        ApplicationStatus.EXPIRED,
    },
    ApplicationStatus.READY:           {
        ApplicationStatus.SUBMITTED,
        ApplicationStatus.EXPIRED,
    },
    ApplicationStatus.SUBMITTED:       {
        ApplicationStatus.INTERVIEW,
        ApplicationStatus.REJECTED,
        ApplicationStatus.WITHDRAWN,
    },
    ApplicationStatus.INTERVIEW:       {
        ApplicationStatus.ACCEPTED,
        ApplicationStatus.REJECTED,
    },
    ApplicationStatus.ACCEPTED:        {ApplicationStatus.ARCHIVED},
    ApplicationStatus.REJECTED:        {ApplicationStatus.ARCHIVED},
    ApplicationStatus.EXPIRED:         {ApplicationStatus.ARCHIVED},
    ApplicationStatus.WITHDRAWN:       {ApplicationStatus.ARCHIVED},
    ApplicationStatus.ARCHIVED:        set(),
}


@dataclass(frozen=True)
class Application:
    id: UUID
    saved_opportunity_id: UUID
    user_id: UUID
    status: ApplicationStatus
    submitted_at: Optional[datetime]
    priority: str          # "high" | "medium" | "low"
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime

    def can_transition_to(self, new_status: ApplicationStatus) -> bool:
        return new_status in APPLICATION_TRANSITIONS.get(self.status, set())

    def validate_submission(self) -> None:
        """A submitted application MUST have a submission date."""
        if self.status == ApplicationStatus.SUBMITTED and self.submitted_at is None:
            raise ValueError(
                "An application cannot be marked as submitted without a submission date. "
                "This must be confirmed by the user explicitly."
            )


# ═══════════════════════════════════════════════════════════════════════════
#  Source
# ═══════════════════════════════════════════════════════════════════════════

class SourceStatus(StrEnum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    ERROR = "error"
    EXCLUDED = "excluded"    # Excluded at publisher's request — cannot be re-enabled


@dataclass(frozen=True)
class Source:
    id: UUID
    name: str
    base_url: str
    country_code: Optional[str]
    language_code: Optional[str]
    status: SourceStatus
    is_official: bool
    reliability_score: float    # 0.0 – 1.0
    last_success_at: Optional[datetime]
    consecutive_failures: int
    min_crawl_interval_minutes: int   # ≥ 60 as per database constraint

    def is_crawlable(self) -> bool:
        return self.status == SourceStatus.ACTIVE and self.consecutive_failures < 5

    def should_notify_failure(self) -> bool:
        return self.consecutive_failures >= 3


# ═══════════════════════════════════════════════════════════════════════════
#  Dedup key
# ═══════════════════════════════════════════════════════════════════════════

@dataclass(frozen=True)
class DedupKey:
    """Composite deduplication key for an opportunity."""
    normalized_url: Optional[str]
    external_id: Optional[str]
    source_id: Optional[UUID]
    title_org_deadline_hash: Optional[str]   # SHA-256
    simhash: Optional[int]                   # 64-bit simhash
