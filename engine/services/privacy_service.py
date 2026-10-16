"""Privacy dashboard, consents, selective erasure and network settings (module M18)."""

from __future__ import annotations

import json
from typing import Any

from sqlalchemy import delete, desc, func, insert, select, update

from core.errors import ValidationFailed
from core.ids import uuid7
from core.timeutil import now_iso
from services.state import ActiveProfile

ERASABLE = ("search_history", "documents", "unsaved_opportunities", "notifications", "profile_details", "logs")
NETWORK_KEYS = {
    "network.proxy_url": ("string", ""),
    "network.data_saver": ("boolean", "false"),
    "network.max_mb_per_search": ("integer", "50"),
}


class PrivacyService:
    def __init__(self, active: ActiveProfile) -> None:
        self.active = active
        self.T = active.tables
        self.uid = active.user_id

    def dashboard(self) -> dict[str, Any]:
        T, uid = self.T, self.uid

        def count(conn: Any, table: Any, *where: Any) -> int:
            return int(conn.execute(select(func.count()).select_from(table).where(*where)).scalar() or 0)

        with self.active.db.read() as conn:
            stored = {
                "profile": {
                    "education": count(conn, T.education_records, T.education_records.c.user_id == uid),
                    "experiences": count(conn, T.work_experiences, T.work_experiences.c.user_id == uid),
                    "skills": count(conn, T.user_skills, T.user_skills.c.user_id == uid),
                    "languages": count(conn, T.user_languages, T.user_languages.c.user_id == uid),
                    "projects": count(conn, T.project_profiles, T.project_profiles.c.user_id == uid),
                },
                "search_history": count(conn, T.search_queries, T.search_queries.c.user_id == uid),
                "opportunities": count(conn, T.opportunities),
                "saved": count(conn, T.saved_opportunities, T.saved_opportunities.c.user_id == uid),
                "notes": count(conn, T.application_notes),
                "documents": count(conn, T.application_documents, T.application_documents.c.user_id == uid),
                "generated_documents": count(conn, T.generated_documents, T.generated_documents.c.user_id == uid),
                "cv_imports": count(conn, T.cv_imports, T.cv_imports.c.user_id == uid),
                "notifications": count(conn, T.notification_records, T.notification_records.c.user_id == uid),
            }
            disclosures = [
                dict(r)
                for r in conn.execute(
                    select(T.data_disclosures)
                    .where(T.data_disclosures.c.user_id == uid)
                    .order_by(desc(T.data_disclosures.c.disclosed_at))
                    .limit(200)
                ).mappings()
            ]
            consents = [
                dict(r) | {"granted": bool(r["granted"])}
                for r in conn.execute(
                    select(T.consents).where(T.consents.c.user_id == uid).order_by(desc(T.consents.c.granted_at))
                ).mappings()
            ]
        return {
            "stored": stored,
            "vault_bytes": self.active.vault.size_bytes(),
            "disclosures": disclosures,
            "consents": consents,
            "telemetry": False,
            "third_parties": sorted({d["recipient"] for d in disclosures}),
        }

    def revoke_consent(self, consent_id: str) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            row = (
                conn.execute(select(T.consents).where(T.consents.c.id == consent_id, T.consents.c.user_id == self.uid))
                .mappings()
                .first()
            )
            if row is None:
                raise ValidationFailed("unknown consent", code="consent_not_found")
            if row["purpose"] in ("terms", "privacy_policy"):
                raise ValidationFailed(
                    "required to use the application; delete the account instead", code="consent_required"
                )
            conn.execute(
                update(T.consents).where(T.consents.c.id == consent_id).values(granted=0, revoked_at=now_iso())
            )
        return self.dashboard()

    def grant_consent(self, purpose: str, target: str | None) -> str:
        T = self.T
        consent_id = uuid7()
        with self.active.db.tx() as conn:
            conn.execute(
                insert(T.consents).values(
                    id=consent_id, user_id=self.uid, purpose=purpose, target=target, policy_version="1.0", granted=1
                )
            )
        return consent_id

    def erase(self, kinds: list[str]) -> dict[str, int]:
        """EF-18.08: selective erasure. Each kind is independent."""
        unknown = [k for k in kinds if k not in ERASABLE]
        if unknown or not kinds:
            raise ValidationFailed("unknown data category", code="erase_kind_invalid", extra={"kinds": unknown})
        T, uid = self.T, self.uid
        result: dict[str, int] = {}
        vault_paths: list[str] = []
        with self.active.db.tx() as conn:
            if "search_history" in kinds:
                result["search_history"] = conn.execute(
                    delete(T.search_queries).where(T.search_queries.c.user_id == uid, T.search_queries.c.is_saved == 0)
                ).rowcount
            if "documents" in kinds:
                vault_paths += (
                    conn.execute(
                        select(T.application_documents.c.vault_path).where(T.application_documents.c.user_id == uid)
                    )
                    .scalars()
                    .all()
                )
                vault_paths += [
                    p
                    for p in conn.execute(select(T.cv_imports.c.vault_path).where(T.cv_imports.c.user_id == uid))
                    .scalars()
                    .all()
                    if p
                ]
                result["documents"] = conn.execute(
                    delete(T.application_documents).where(T.application_documents.c.user_id == uid)
                ).rowcount
                result["generated_documents"] = conn.execute(
                    delete(T.generated_documents).where(T.generated_documents.c.user_id == uid)
                ).rowcount
                conn.execute(update(T.cv_imports).where(T.cv_imports.c.user_id == uid).values(vault_path=None))
            if "unsaved_opportunities" in kinds:
                keep = select(T.saved_opportunities.c.opportunity_id)
                result["unsaved_opportunities"] = conn.execute(
                    delete(T.opportunities).where(
                        T.opportunities.c.id.not_in(keep),
                        T.opportunities.c.id.not_in(select(T.workspace_opportunities.c.opportunity_id)),
                    )
                ).rowcount
                conn.execute(
                    delete(T.raw_documents).where(
                        T.raw_documents.c.id.not_in(select(T.opportunity_sources.c.raw_document_id))
                    )
                )
                conn.execute(delete(T.http_cache))
            if "notifications" in kinds:
                result["notifications"] = conn.execute(
                    delete(T.notification_records).where(T.notification_records.c.user_id == uid)
                ).rowcount
            if "profile_details" in kinds:
                n = 0
                for tbl in (
                    T.education_records,
                    T.work_experiences,
                    T.certifications,
                    T.user_skills,
                    T.user_languages,
                    T.profile_links,
                    T.user_objectives,
                    T.user_custom_objectives,
                    T.project_profiles,
                    T.profile_preferred_locations,
                    T.cv_imports,
                ):
                    n += conn.execute(delete(tbl).where(tbl.c.user_id == uid)).rowcount
                conn.execute(
                    update(T.user_profiles)
                    .where(T.user_profiles.c.user_id == uid)
                    .values(
                        country_code=None,
                        city=None,
                        professional_status=None,
                        current_occupation=None,
                        experience_years=None,
                        highest_education=None,
                        work_mode_pref=None,
                        willing_to_relocate=None,
                        contact_phone=None,
                        bio=None,
                        summary_text=None,
                        summary_approved=0,
                        completeness_pct=0,
                    )
                )
                conn.execute(delete(T.match_scores).where(T.match_scores.c.user_id == uid))
                result["profile_details"] = n
            conn.execute(
                insert(T.audit_logs).values(
                    user_id=uid, action="privacy.erase", detail=json.dumps({"kinds": sorted(kinds)})
                )
            )
        for p in vault_paths:
            self.active.vault.delete(p)
        return result

    # -------------------------------------------------------------- network
    def network(self) -> dict[str, Any]:
        T = self.T
        with self.active.db.read() as conn:
            rows = dict(
                conn.execute(
                    select(T.application_settings.c.key, T.application_settings.c.value).where(
                        T.application_settings.c.key.like("network.%")
                    )
                ).all()
            )
        values = {k: rows.get(k, default) for k, (_t, default) in NETWORK_KEYS.items()}
        return {
            "proxy_url": values["network.proxy_url"] or None,
            "data_saver": values["network.data_saver"] == "true",
            "max_mb_per_search": int(values["network.max_mb_per_search"]),
        }

    def set_network(self, proxy_url: str | None, data_saver: bool, max_mb: int) -> dict[str, Any]:
        if proxy_url and not proxy_url.startswith(("http://", "https://", "socks5://")):
            raise ValidationFailed("proxy must be http(s):// or socks5://", code="proxy_invalid")
        if not 5 <= max_mb <= 1000:
            raise ValidationFailed("limit between 5 and 1000 MB", code="bandwidth_invalid")
        T = self.T
        values = {
            "network.proxy_url": proxy_url or "",
            "network.data_saver": "true" if data_saver else "false",
            "network.max_mb_per_search": str(max_mb),
        }
        with self.active.db.tx() as conn:
            for key, value in values.items():
                conn.execute(delete(T.application_settings).where(T.application_settings.c.key == key))
                conn.execute(
                    insert(T.application_settings).values(key=key, value=value, value_type=NETWORK_KEYS[key][0])
                )
        return self.network()
