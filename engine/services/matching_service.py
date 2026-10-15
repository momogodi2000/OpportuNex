"""Compute and cache relevance scores (EF-08.01..06) against the current profile."""

from __future__ import annotations

import json
from typing import Any

from sqlalchemy import Connection, delete, insert, select, update

from core.errors import ValidationFailed
from core.timeutil import now_iso, parse_date
from matching.scorer import ALGORITHM_VERSION, DEFAULT_WEIGHTS, OpportunityFacts, ProfileFacts, score
from persistence.database import Tables
from services.profile_service import ProfileService, profile_fingerprint
from services.state import ActiveProfile

WEIGHT_COLUMNS = {k: f"w_{k}" for k in DEFAULT_WEIGHTS}


class MatchingService:
    def __init__(self, active: ActiveProfile) -> None:
        self.active = active
        self.T = active.tables
        self.uid = active.user_id
        self._profile: dict[str, Any] | None = None

    # ------------------------------------------------------------- inputs
    @property
    def profile(self) -> dict[str, Any]:
        if self._profile is None:
            self._profile = ProfileService(self.active).get()
        return self._profile

    def profile_facts(self) -> ProfileFacts:
        p = self.profile
        g = p["general"]
        T = self.T
        with self.active.db.read() as conn:
            cat_codes = set()
            for o in p["objectives"]["items"]:
                code = conn.execute(
                    select(T.opportunity_categories.c.code)
                    .join(T.objectives, T.objectives.c.default_category_id == T.opportunity_categories.c.id)
                    .where(T.objectives.c.id == o["objective_id"])
                ).scalar()
                if code:
                    cat_codes.add(code)
        return ProfileFacts(
            skills=[s["name"] for s in p["skills"]],
            education=g.get("highest_education"),
            experience_years=g.get("experience_years"),
            country_code=g.get("country_code"),
            preferred_countries=[x["country_code"] for x in p["preferred_locations"] if x.get("country_code")],
            preferred_regions=[x["region_label"] for x in p["preferred_locations"] if x.get("region_label")],
            work_mode_pref=g.get("work_mode_pref"),
            willing_to_relocate=bool(g.get("willing_to_relocate")),
            languages={x["language_code"]: x["cefr_level"] for x in p["languages"]},
            objective_categories=cat_codes,
        )

    def weights(self) -> dict[str, float]:
        T = self.T
        with self.active.db.read() as conn:
            row = (
                conn.execute(select(T.matching_weights).where(T.matching_weights.c.user_id == self.uid))
                .mappings()
                .first()
            )
        if row is None:
            return dict(DEFAULT_WEIGHTS)
        return {k: float(row[col]) for k, col in WEIGHT_COLUMNS.items()}

    def set_weights(self, weights: dict[str, float]) -> dict[str, float]:
        unknown = set(weights) - set(DEFAULT_WEIGHTS)
        if unknown:
            raise ValidationFailed("unknown criterion", code="weight_unknown", extra={"criteria": sorted(unknown)})
        if any(not 0 <= v <= 1 for v in weights.values()):
            raise ValidationFailed("weights must be between 0 and 1", code="weight_range")
        merged = {**self.weights(), **weights}
        if sum(merged.values()) <= 0:
            raise ValidationFailed("at least one weight must be positive", code="weight_all_zero")
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(
                update(T.matching_weights)
                .where(T.matching_weights.c.user_id == self.uid)
                .values(**{WEIGHT_COLUMNS[k]: v for k, v in merged.items()}, updated_at=now_iso())
            )
            conn.execute(delete(T.match_scores).where(T.match_scores.c.user_id == self.uid))
        return merged

    def opportunity_facts(self, conn: Connection, opp: dict[str, Any]) -> OpportunityFacts:
        T = self.T
        reqs = conn.execute(
            select(
                T.opportunity_requirements.c.req_type,
                T.opportunity_requirements.c.label,
                T.opportunity_requirements.c.language_code,
            ).where(T.opportunity_requirements.c.opportunity_id == opp["id"])
        ).all()
        category = (
            conn.execute(
                select(T.opportunity_categories.c.code).where(T.opportunity_categories.c.id == opp["category_id"])
            ).scalar()
            if opp.get("category_id")
            else None
        )
        return OpportunityFacts(
            category_code=category,
            country_code=opp.get("country_code"),
            work_mode=opp.get("work_mode"),
            language_code=opp.get("language_code"),
            deadline=parse_date(opp.get("deadline_on")),
            education_required=opp.get("education_required"),
            experience_min_years=opp.get("experience_min_years"),
            eligibility_raw=opp.get("eligibility_raw"),
            text=" ".join(filter(None, [opp.get("title"), opp.get("summary"), opp.get("description_text")])),
            required_skills=[r.label for r in reqs if r.req_type == "skill"],
            required_languages=[r.language_code for r in reqs if r.req_type == "language" and r.language_code],
        )

    # ------------------------------------------------------------ compute
    def score_many(self, opportunity_ids: list[str], *, force: bool = False) -> dict[str, dict[str, Any]]:
        if not opportunity_ids:
            return {}
        version = profile_fingerprint(self.profile)
        facts = self.profile_facts()
        weights = self.weights()
        T = self.T
        out: dict[str, dict[str, Any]] = {}
        with self.active.db.tx() as conn:
            cached = {
                r["opportunity_id"]: dict(r)
                for r in conn.execute(
                    select(T.match_scores).where(
                        T.match_scores.c.user_id == self.uid, T.match_scores.c.opportunity_id.in_(opportunity_ids)
                    )
                ).mappings()
            }
            opps = {
                r["id"]: dict(r)
                for r in conn.execute(
                    select(T.opportunities).where(T.opportunities.c.id.in_(opportunity_ids))
                ).mappings()
            }
            for oid in opportunity_ids:
                c = cached.get(oid)
                if (
                    c
                    and not force
                    and c["profile_version"] == version
                    and c["algorithm_version"] == ALGORITHM_VERSION
                    and c["computed_at"][:10] == now_iso()[:10]
                ):
                    out[oid] = present_score(c)
                    continue
                opp = opps.get(oid)
                if opp is None:
                    continue
                result = score(self.opportunity_facts(conn, opp), facts, weights)
                row = {
                    "user_id": self.uid,
                    "opportunity_id": oid,
                    "score": result.score,
                    "breakdown": json.dumps(result.breakdown),
                    "strengths": json.dumps(result.strengths),
                    "gaps": json.dumps(result.gaps),
                    "eligibility": result.eligibility,
                    "to_verify": json.dumps(result.to_verify),
                    "profile_version": version,
                    "algorithm_version": ALGORITHM_VERSION,
                    "computed_at": now_iso(),
                }
                conn.execute(
                    delete(T.match_scores).where(
                        T.match_scores.c.user_id == self.uid, T.match_scores.c.opportunity_id == oid
                    )
                )
                conn.execute(insert(T.match_scores).values(**row))
                out[oid] = present_score(row)
        return out

    def feedback(self, opportunity_id: str, feedback: str, reason: str | None) -> None:
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(
                delete(T.match_feedback).where(
                    T.match_feedback.c.user_id == self.uid,
                    T.match_feedback.c.opportunity_id == opportunity_id,
                    T.match_feedback.c.feedback == feedback,
                )
            )
            conn.execute(
                insert(T.match_feedback).values(
                    user_id=self.uid, opportunity_id=opportunity_id, feedback=feedback, reason=reason
                )
            )

    def feedback_adjustments(self, conn: Connection) -> dict[str, int]:
        """Local adaptation (EF-08.06): categories marked not relevant are ranked lower,
        relevant ones higher. Returns category_id -> rank bonus."""
        T = self.T
        rows = conn.execute(
            select(T.opportunities.c.category_id, T.match_feedback.c.feedback)
            .join(T.opportunities, T.opportunities.c.id == T.match_feedback.c.opportunity_id)
            .where(T.match_feedback.c.user_id == self.uid)
        ).all()
        bonus: dict[str, int] = {}
        for cat, fb in rows:
            key = str(cat)
            bonus[key] = bonus.get(key, 0) + (
                3 if fb == "relevant" else -5 if fb in ("not_relevant", "dismissed") else 0
            )
        return {k: max(-15, min(10, v)) for k, v in bonus.items()}


def present_score(row: dict[str, Any]) -> dict[str, Any]:
    def j(v: Any) -> Any:
        return json.loads(v) if isinstance(v, str) else v

    return {
        "score": row["score"],
        "breakdown": j(row["breakdown"]),
        "strengths": j(row["strengths"]) or [],
        "gaps": j(row["gaps"]) or [],
        "eligibility": row["eligibility"],
        "to_verify": j(row["to_verify"]) or [],
        "algorithm_version": row["algorithm_version"],
    }


def tables_of(active: ActiveProfile) -> Tables:
    return active.tables
