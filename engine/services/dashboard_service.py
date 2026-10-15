"""Dashboard (M11): indicators from real data only (EF-11.01..08)."""

from __future__ import annotations

from datetime import date, timedelta
from typing import Any

from sqlalchemy import desc, func, select, text

from core.timeutil import parse_date, today_iso
from services.matching_service import MatchingService
from services.opportunity_view import card
from services.source_service import health_summary
from services.state import ActiveProfile

FOLLOW_UP_AFTER_DAYS = 21


class DashboardService:
    def __init__(self, active: ActiveProfile) -> None:
        self.active = active
        self.T = active.tables
        self.uid = active.user_id

    def summary(self) -> dict[str, Any]:
        T, uid = self.T, self.uid
        today = date.today()
        with self.active.db.read() as conn:
            counters = (
                conn.execute(text("SELECT * FROM v_dashboard_counters WHERE user_id = :u"), {"u": uid})
                .mappings()
                .first()
            )
            last_run = (
                conn.execute(
                    select(T.search_runs)
                    .where(T.search_runs.c.user_id == uid, T.search_runs.c.status.in_(("completed", "partial")))
                    .order_by(desc(T.search_runs.c.created_at))
                    .limit(1)
                )
                .mappings()
                .first()
            )
            deadlines = [
                dict(r)
                for r in conn.execute(
                    text(
                        "SELECT * FROM v_upcoming_deadlines WHERE user_id = :u AND days_left <= 30 "
                        "ORDER BY effective_deadline"
                    ),
                    {"u": uid},
                ).mappings()
            ]
            by_status: dict[str, int] = dict(
                conn.execute(
                    select(T.applications.c.status, func.count())
                    .join(T.saved_opportunities, T.saved_opportunities.c.id == T.applications.c.saved_id)
                    .where(T.applications.c.user_id == uid, T.saved_opportunities.c.archived == 0)
                    .group_by(T.applications.c.status)
                ).all()
            )
            follow_ups = [
                dict(r)
                for r in conn.execute(
                    select(
                        T.applications.c.id,
                        T.applications.c.submitted_on,
                        T.opportunities.c.title,
                        T.saved_opportunities.c.id.label("saved_id"),
                    )
                    .join(T.saved_opportunities, T.saved_opportunities.c.id == T.applications.c.saved_id)
                    .join(T.opportunities, T.opportunities.c.id == T.saved_opportunities.c.opportunity_id)
                    .where(
                        T.applications.c.user_id == uid,
                        T.applications.c.status == "submitted",
                        T.applications.c.submitted_on <= (today - timedelta(days=FOLLOW_UP_AFTER_DAYS)).isoformat(),
                    )
                ).mappings()
            ]
            upcoming_events = [
                dict(r)
                for r in conn.execute(
                    select(
                        T.application_events.c.id,
                        T.application_events.c.title,
                        T.application_events.c.event_type,
                        T.application_events.c.scheduled_at,
                        T.applications.c.id.label("application_id"),
                    )
                    .join(T.applications, T.applications.c.id == T.application_events.c.application_id)
                    .where(
                        T.applications.c.user_id == uid,
                        T.application_events.c.done == 0,
                        T.application_events.c.scheduled_at >= today_iso(),
                    )
                    .order_by(T.application_events.c.scheduled_at)
                    .limit(5)
                ).mappings()
            ]
            activity = [
                dict(r)
                for r in conn.execute(
                    select(
                        T.search_runs.c.id,
                        T.search_runs.c.status,
                        T.search_runs.c.results_count,
                        T.search_runs.c.new_count,
                        T.search_runs.c.created_at,
                        T.search_runs.c.trigger,
                        T.search_queries.c.raw_text,
                    )
                    .join(T.search_queries, T.search_queries.c.id == T.search_runs.c.query_id)
                    .where(T.search_runs.c.user_id == uid)
                    .order_by(desc(T.search_runs.c.created_at))
                    .limit(8)
                ).mappings()
            ]
            unread = conn.execute(
                select(func.count())
                .select_from(T.notification_records)
                .where(T.notification_records.c.user_id == uid, T.notification_records.c.read_at.is_(None))
            ).scalar()
            profile_pct = conn.execute(
                select(T.user_profiles.c.completeness_pct).where(T.user_profiles.c.user_id == uid)
            ).scalar()
            total_opps = conn.execute(select(func.count()).select_from(T.opportunities)).scalar()
        windows = {f"days_{n}": sum(1 for d in deadlines if d["days_left"] <= n) for n in (7, 14, 30)}
        return {
            "counters": {
                "discovered": int(counters["discovered"]) if counters else 0,
                "relevant": int(counters["relevant"]) if counters else 0,
                "saved": int(counters["saved"]) if counters else 0,
                "in_progress": int(counters["in_progress"]) if counters else 0,
                "submitted": int(counters["submitted"]) if counters else 0,
                "new_since_last_search": int(last_run["new_count"]) if last_run else 0,
                "unread_notifications": int(unread or 0),
                "opportunities_in_database": int(total_opps or 0),
            },
            "deadlines": {"windows": windows, "items": deadlines[:10]},
            "applications": {"by_status": by_status, "follow_ups": follow_ups, "upcoming_events": upcoming_events},
            "activity": activity,
            "recommendations": self.recommendations(),
            "sources": health_summary(self.active),
            "stats": self.stats(),
            "profile_completeness": int(profile_pct or 0),
            "is_new_user": not activity and not counters["saved"] if counters else True,
        }

    def recommendations(self, limit: int = 6) -> list[dict[str, Any]]:
        """EF-11.05: best-scored, unsaved, open opportunities not dismissed."""
        T, uid = self.T, self.uid
        with self.active.db.read() as conn:
            candidates = (
                conn.execute(
                    select(T.opportunities.c.id)
                    .where(
                        (T.opportunities.c.deadline_on.is_(None)) | (T.opportunities.c.deadline_on >= today_iso()),
                        T.opportunities.c.verification_status.not_in(("expired", "withdrawn")),
                        T.opportunities.c.id.not_in(
                            select(T.saved_opportunities.c.opportunity_id).where(T.saved_opportunities.c.user_id == uid)
                        ),
                        T.opportunities.c.id.not_in(
                            select(T.match_feedback.c.opportunity_id).where(
                                T.match_feedback.c.user_id == uid,
                                T.match_feedback.c.feedback.in_(("dismissed", "not_relevant")),
                            )
                        ),
                    )
                    .order_by(desc(T.opportunities.c.last_checked_at))
                    .limit(200)
                )
                .scalars()
                .all()
            )
        if not candidates:
            return []
        scores = MatchingService(self.active).score_many(list(candidates))
        best = sorted(
            (o for o in candidates if (scores.get(o, {}).get("score") or 0) >= 50), key=lambda o: -scores[o]["score"]
        )[:limit]
        with self.active.db.read() as conn:
            rows = {
                r["id"]: dict(r)
                for r in conn.execute(select(T.opportunities).where(T.opportunities.c.id.in_(best))).mappings()
            }
            return [card(conn, T, rows[o], scores.get(o)) for o in best if o in rows]

    def stats(self) -> dict[str, Any]:
        """EF-11.08: response rate, average response delay, most successful categories."""
        T, uid = self.T, self.uid
        with self.active.db.read() as conn:
            rows = conn.execute(
                select(
                    T.applications.c.status,
                    T.applications.c.submitted_on,
                    T.applications.c.outcome_on,
                    T.opportunity_categories.c.code,
                )
                .join(T.saved_opportunities, T.saved_opportunities.c.id == T.applications.c.saved_id)
                .join(T.opportunities, T.opportunities.c.id == T.saved_opportunities.c.opportunity_id)
                .join(
                    T.opportunity_categories,
                    T.opportunity_categories.c.id == T.opportunities.c.category_id,
                    isouter=True,
                )
                .where(T.applications.c.user_id == uid)
            ).all()
        submitted = [r for r in rows if r.submitted_on]
        answered = [r for r in submitted if r.status in ("interview", "accepted", "rejected")]
        delays = [
            (parse_date(r.outcome_on) - parse_date(r.submitted_on)).days  # type: ignore[operator]
            for r in answered
            if r.outcome_on and r.submitted_on
        ]
        by_cat: dict[str, dict[str, int]] = {}
        for r in submitted:
            key = (r.code or "other").split(".")[0]
            entry = by_cat.setdefault(key, {"submitted": 0, "accepted": 0})
            entry["submitted"] += 1
            entry["accepted"] += int(r.status == "accepted")
        return {
            "submitted": len(submitted),
            "response_rate": round(len(answered) / len(submitted), 2) if submitted else None,
            "average_response_days": round(sum(delays) / len(delays), 1) if delays else None,
            "accepted": sum(1 for r in rows if r.status == "accepted"),
            "categories": sorted(
                ({"category": k} | v for k, v in by_cat.items()), key=lambda x: (-x["accepted"], -x["submitted"])
            ),
        }
