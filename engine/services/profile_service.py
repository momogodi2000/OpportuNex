"""User profile (module M02): aggregate read, section updates, completeness, summary.

All writes are scoped by ``user_id``; child records are verified to belong to the user
before update or deletion (no IDOR across local profiles).
"""

from __future__ import annotations

import hashlib
import json
from typing import Any

from sqlalchemy import Connection, delete, insert, select, update

from core.errors import NotFound, ValidationFailed
from core.ids import uuid7
from core.text import fold
from core.timeutil import now_iso
from persistence.database import Tables
from services.state import ActiveProfile

GENERAL_FIELDS = (
    "full_name",
    "country_code",
    "city",
    "professional_status",
    "current_occupation",
    "experience_years",
    "highest_education",
    "work_mode_pref",
    "willing_to_relocate",
    "contact_phone",
    "bio",
)

# Child collections: table name -> (owner column, editable columns)
COLLECTIONS: dict[str, tuple[str, tuple[str, ...]]] = {
    "education": (
        "education_records",
        (
            "level",
            "field_of_study",
            "institution",
            "country_code",
            "start_date",
            "end_date",
            "is_ongoing",
            "grade",
            "achievements",
        ),
    ),
    "experiences": (
        "work_experiences",
        (
            "job_title",
            "employer",
            "employment_type",
            "country_code",
            "city",
            "start_date",
            "end_date",
            "is_current",
            "description",
        ),
    ),
    "certifications": ("certifications", ("name", "issuer", "obtained_on", "expires_on", "credential_url")),
    "projects": (
        "project_profiles",
        (
            "title",
            "category_id",
            "description",
            "stage",
            "funding_need_minor",
            "funding_min_minor",
            "funding_max_minor",
            "currency_code",
            "operating_country",
            "beneficiaries",
            "legal_status",
            "existing_resources",
            "timeline_months",
        ),
    ),
}

COMPLETENESS_WEIGHTS = {
    "identity": 15,
    "status": 10,
    "education": 15,
    "experience": 15,
    "skills": 15,
    "languages": 10,
    "objectives": 10,
    "preferences": 10,
}


def _rows(conn: Connection, stmt: Any) -> list[dict[str, Any]]:
    return [dict(r) for r in conn.execute(stmt).mappings().all()]


def resolve_skill(conn: Connection, T: Tables, name: str) -> int:
    """Find a skill by name or alias (accent/case-insensitive), creating it if unknown."""
    norm = fold(name)
    if not norm:
        raise ValidationFailed("empty skill name", code="skill_name_required")
    found = conn.execute(select(T.skill_aliases.c.skill_id).where(T.skill_aliases.c.alias == norm)).scalar()
    if found is not None:
        return int(found)
    found = conn.execute(select(T.skills.c.id).where(T.skills.c.normalized == norm)).scalar()
    if found is not None:
        return int(found)
    skill_id = conn.execute(
        insert(T.skills).values(name=name.strip(), normalized=norm, kind="technical")
    ).inserted_primary_key[0]  # type: ignore[index]
    conn.execute(insert(T.skill_aliases).values(alias=norm, skill_id=skill_id))
    return int(skill_id)


class ProfileService:
    def __init__(self, active: ActiveProfile) -> None:
        self.active = active
        self.T = active.tables
        self.uid = active.user_id

    # ------------------------------------------------------------------ read
    def get(self) -> dict[str, Any]:
        T, uid = self.T, self.uid
        with self.active.db.read() as conn:
            general = dict(
                conn.execute(select(T.user_profiles).where(T.user_profiles.c.user_id == uid)).mappings().one()
            )
            data: dict[str, Any] = {"general": general}
            data["preferred_locations"] = _rows(
                conn,
                select(T.profile_preferred_locations)
                .where(T.profile_preferred_locations.c.user_id == uid)
                .order_by(T.profile_preferred_locations.c.priority),
            )
            for key, (table, _cols) in COLLECTIONS.items():
                tbl = T.metadata.tables[table]
                order = tbl.c.start_date.desc() if "start_date" in tbl.c else tbl.c.id
                data[key] = _rows(conn, select(tbl).where(tbl.c.user_id == uid).order_by(order))
            data["skills"] = _rows(
                conn,
                select(
                    T.user_skills.c.skill_id,
                    T.skills.c.name,
                    T.skills.c.kind,
                    T.user_skills.c.level,
                    T.user_skills.c.years,
                    T.user_skills.c.is_primary,
                )
                .join(T.skills, T.skills.c.id == T.user_skills.c.skill_id)
                .where(T.user_skills.c.user_id == uid)
                .order_by(T.skills.c.name),
            )
            data["languages"] = _rows(
                conn,
                select(T.user_languages.c.language_code, T.user_languages.c.cefr_level).where(
                    T.user_languages.c.user_id == uid
                ),
            )
            data["links"] = _rows(conn, select(T.profile_links).where(T.profile_links.c.user_id == uid))
            data["objectives"] = {
                "items": _rows(
                    conn,
                    select(T.user_objectives.c.objective_id, T.user_objectives.c.priority, T.objectives.c.code)
                    .join(T.objectives, T.objectives.c.id == T.user_objectives.c.objective_id)
                    .where(T.user_objectives.c.user_id == uid),
                ),
                "custom": _rows(
                    conn,
                    select(T.user_custom_objectives.c.id, T.user_custom_objectives.c.label).where(
                        T.user_custom_objectives.c.user_id == uid
                    ),
                ),
            }
            data["organization"] = self._organization(conn)
            onboarded = conn.execute(select(T.users.c.onboarding_completed).where(T.users.c.id == uid)).scalar()
        data["completeness"] = compute_completeness(data)
        data["onboarding_completed"] = bool(onboarded)
        return data

    def _organization(self, conn: Connection) -> dict[str, Any] | None:
        T = self.T
        row = (
            conn.execute(
                select(T.organizations)
                .join(T.organization_members, T.organization_members.c.organization_id == T.organizations.c.id)
                .where(
                    T.organization_members.c.user_id == self.uid,
                    T.organization_members.c.role == "owner",
                    T.organizations.c.created_by == self.uid,
                    T.organizations.c.remote_id.is_(None),
                )
                .order_by(T.organizations.c.created_at)
                .limit(1)
            )
            .mappings()
            .first()
        )
        return dict(row) if row else None

    # ----------------------------------------------------------------- write
    def _audit(self, conn: Connection, action: str, entity: str | None = None, entity_id: str | None = None) -> None:
        conn.execute(
            insert(self.T.audit_logs).values(user_id=self.uid, action=action, entity_table=entity, entity_id=entity_id)
        )

    def update_general(self, values: dict[str, Any]) -> dict[str, Any]:
        clean = {k: v for k, v in values.items() if k in GENERAL_FIELDS}
        T = self.T
        with self.active.db.tx() as conn:
            if clean:
                conn.execute(
                    update(T.user_profiles)
                    .where(T.user_profiles.c.user_id == self.uid)
                    .values(**clean, updated_at=now_iso(), summary_approved=0)
                )
                self._audit(conn, "profile.update", "user_profiles", self.uid)
        return self._finish()

    def set_locations(self, items: list[dict[str, Any]]) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(
                delete(T.profile_preferred_locations).where(T.profile_preferred_locations.c.user_id == self.uid)
            )
            for i, item in enumerate(items, start=1):
                if not item.get("country_code") and not item.get("region_label"):
                    raise ValidationFailed("country or region required", code="location_incomplete")
                conn.execute(
                    insert(T.profile_preferred_locations).values(
                        user_id=self.uid,
                        country_code=item.get("country_code"),
                        region_label=item.get("region_label"),
                        city=item.get("city"),
                        priority=i,
                    )
                )
        return self._finish()

    def upsert_item(self, collection: str, item_id: str | None, values: dict[str, Any]) -> dict[str, Any]:
        table_name, cols = COLLECTIONS[collection]
        tbl = self.T.metadata.tables[table_name]
        clean = {k: v for k, v in values.items() if k in cols}
        with self.active.db.tx() as conn:
            if item_id is None:
                item_id = uuid7()
                conn.execute(insert(tbl).values(id=item_id, user_id=self.uid, **clean))
            else:
                self._owned(conn, tbl, item_id)
                if clean:
                    extra = {"updated_at": now_iso()} if "updated_at" in tbl.c else {}
                    conn.execute(update(tbl).where(tbl.c.id == item_id).values(**clean, **extra))
            conn.execute(
                update(self.T.user_profiles)
                .where(self.T.user_profiles.c.user_id == self.uid)
                .values(summary_approved=0)
            )
        self._finish()
        with self.active.db.read() as conn:
            return dict(conn.execute(select(tbl).where(tbl.c.id == item_id)).mappings().one())

    def delete_item(self, collection: str, item_id: str) -> None:
        tbl = self.T.metadata.tables[COLLECTIONS[collection][0]]
        with self.active.db.tx() as conn:
            self._owned(conn, tbl, item_id)
            conn.execute(delete(tbl).where(tbl.c.id == item_id))
        self._finish()

    def _owned(self, conn: Connection, tbl: Any, item_id: str) -> None:
        found = conn.execute(select(tbl.c.id).where(tbl.c.id == item_id, tbl.c.user_id == self.uid)).first()
        if found is None:
            raise NotFound("item not found", code="profile_item_not_found")

    def set_skills(self, items: list[dict[str, Any]]) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(delete(T.user_skills).where(T.user_skills.c.user_id == self.uid))
            seen: set[int] = set()
            for item in items:
                skill_id = resolve_skill(conn, T, str(item["name"]))
                if skill_id in seen:
                    continue
                seen.add(skill_id)
                conn.execute(
                    insert(T.user_skills).values(
                        user_id=self.uid,
                        skill_id=skill_id,
                        level=item.get("level"),
                        years=item.get("years"),
                        is_primary=1 if item.get("is_primary") else 0,
                    )
                )
            conn.execute(
                update(T.user_profiles).where(T.user_profiles.c.user_id == self.uid).values(summary_approved=0)
            )
        return self._finish()

    def set_languages(self, items: list[dict[str, Any]]) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(delete(T.user_languages).where(T.user_languages.c.user_id == self.uid))
            known = set(conn.execute(select(T.languages.c.code)).scalars())
            for item in {i["language_code"]: i for i in items}.values():
                if item["language_code"] not in known:
                    raise ValidationFailed("unknown language", code="language_unknown")
                conn.execute(
                    insert(T.user_languages).values(
                        user_id=self.uid, language_code=item["language_code"], cefr_level=item["cefr_level"]
                    )
                )
        return self._finish()

    def set_links(self, items: list[dict[str, Any]]) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(delete(T.profile_links).where(T.profile_links.c.user_id == self.uid))
            for item in {(i["kind"], i["url"]): i for i in items}.values():
                url = str(item["url"]).strip()
                if not url.startswith(("https://", "http://")):
                    raise ValidationFailed("link must start with http(s)://", code="link_invalid")
                conn.execute(insert(T.profile_links).values(user_id=self.uid, kind=item["kind"], url=url))
        return self._finish()

    def set_objectives(self, objective_ids: list[int], custom: list[str]) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            known = set(conn.execute(select(T.objectives.c.id)).scalars())
            unknown = [o for o in objective_ids if o not in known]
            if unknown:
                raise ValidationFailed("unknown objective", code="objective_unknown", extra={"ids": unknown})
            conn.execute(delete(T.user_objectives).where(T.user_objectives.c.user_id == self.uid))
            for rank, oid in enumerate(dict.fromkeys(objective_ids), start=1):
                conn.execute(
                    insert(T.user_objectives).values(user_id=self.uid, objective_id=oid, priority=min(rank, 5))
                )
            conn.execute(delete(T.user_custom_objectives).where(T.user_custom_objectives.c.user_id == self.uid))
            for label in dict.fromkeys(c.strip() for c in custom if c.strip()):
                conn.execute(insert(T.user_custom_objectives).values(user_id=self.uid, label=label[:200]))
        return self._finish()

    def set_organization(self, values: dict[str, Any] | None) -> dict[str, Any]:
        """Create, update or remove the user's own organisation profile (EF-02.12)."""
        T = self.T
        cols = (
            "name",
            "org_type",
            "legal_status",
            "registration_no",
            "country_code",
            "sector",
            "description",
            "annual_budget_band",
            "website",
        )
        with self.active.db.tx() as conn:
            current = self._organization(conn)
            if values is None:
                if current:
                    conn.execute(delete(T.organizations).where(T.organizations.c.id == current["id"]))
            elif current:
                conn.execute(
                    update(T.organizations)
                    .where(T.organizations.c.id == current["id"])
                    .values(**{k: values.get(k) for k in cols if k in values}, updated_at=now_iso())
                )
            else:
                org_id = uuid7()
                conn.execute(
                    insert(T.organizations).values(id=org_id, created_by=self.uid, **{k: values.get(k) for k in cols})
                )
                conn.execute(
                    insert(T.organization_members).values(organization_id=org_id, user_id=self.uid, role="owner")
                )
            self._audit(conn, "profile.organization", "organizations")
        return self._finish()

    # --------------------------------------------------------------- summary
    def generate_summary(self, lang: str = "fr") -> str:
        """Summary built only from data the user entered (EF-02.11) — no invention."""
        return build_summary(self.get(), lang)

    def save_summary(self, text: str, approved: bool) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(
                update(T.user_profiles)
                .where(T.user_profiles.c.user_id == self.uid)
                .values(summary_text=text.strip() or None, summary_approved=1 if approved else 0, updated_at=now_iso())
            )
        return self._finish()

    def complete_onboarding(self) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(update(T.users).where(T.users.c.id == self.uid).values(onboarding_completed=1))
            self._audit(conn, "profile.onboarding_completed", "users", self.uid)
        return self.get()

    def _finish(self) -> dict[str, Any]:
        data = self.get()
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(
                update(T.user_profiles)
                .where(T.user_profiles.c.user_id == self.uid)
                .values(completeness_pct=data["completeness"]["percent"])
            )
        data["general"]["completeness_pct"] = data["completeness"]["percent"]
        return data


def compute_completeness(p: dict[str, Any]) -> dict[str, Any]:
    g = p["general"]
    checks = {
        "identity": bool(g.get("full_name") and g.get("country_code") and g.get("city")),
        "status": bool(g.get("professional_status") and g.get("highest_education")),
        "education": bool(p["education"]),
        "experience": bool(p["experiences"]) or g.get("professional_status") == "student",
        "skills": len(p["skills"]) >= 3,
        "languages": bool(p["languages"]),
        "objectives": bool(p["objectives"]["items"] or p["objectives"]["custom"]),
        "preferences": bool(p["preferred_locations"] or g.get("work_mode_pref")),
    }
    percent = sum(COMPLETENESS_WEIGHTS[k] for k, ok in checks.items() if ok)
    suggestions = [k for k, ok in sorted(checks.items(), key=lambda kv: -COMPLETENESS_WEIGHTS[kv[0]]) if not ok]
    return {"percent": percent, "missing": suggestions, "checks": checks}


def profile_fingerprint(p: dict[str, Any]) -> str:
    """Stable hash of the matching-relevant profile content (stored with each match score)."""
    relevant = {
        "g": {
            k: p["general"].get(k)
            for k in (
                "country_code",
                "city",
                "highest_education",
                "experience_years",
                "work_mode_pref",
                "willing_to_relocate",
                "professional_status",
            )
        },
        "loc": [(x.get("country_code"), x.get("region_label")) for x in p["preferred_locations"]],
        "edu": sorted((e["level"], e["field_of_study"]) for e in p["education"]),
        "exp": sorted((e["job_title"], e["start_date"], e.get("end_date") or "") for e in p["experiences"]),
        "skills": sorted(s["name"] for s in p["skills"]),
        "lang": sorted((x["language_code"], x["cefr_level"]) for x in p["languages"]),
        "obj": sorted(o["code"] for o in p["objectives"]["items"]),
    }
    return hashlib.sha256(json.dumps(relevant, sort_keys=True, default=str).encode()).hexdigest()[:16]


_EDU_FR = {
    "none": "sans diplôme",
    "primary": "niveau primaire",
    "secondary": "niveau secondaire",
    "bac": "baccalauréat",
    "bac_plus_2": "Bac+2",
    "bachelor": "licence",
    "master": "master",
    "doctorate": "doctorat",
    "postdoc": "post-doctorat",
    "vocational": "formation professionnelle",
}
_EDU_EN = {
    "none": "no degree",
    "primary": "primary level",
    "secondary": "secondary level",
    "bac": "high-school diploma",
    "bac_plus_2": "two-year degree",
    "bachelor": "bachelor's degree",
    "master": "master's degree",
    "doctorate": "doctorate",
    "postdoc": "postdoctoral experience",
    "vocational": "vocational training",
}


def build_summary(p: dict[str, Any], lang: str) -> str:
    g = p["general"]
    fr = lang != "en"
    parts: list[str] = []
    occupation = g.get("current_occupation")
    edu = (_EDU_FR if fr else _EDU_EN).get(g.get("highest_education") or "")
    if occupation:
        parts.append(occupation)
    if edu:
        parts.append(
            (f"titulaire d'un {edu}" if fr else f"holding a {edu}")
            if g.get("highest_education") not in ("none", "primary", "secondary")
            else edu
        )
    lead = ", ".join(parts)
    sentences = []
    if lead:
        sentences.append(lead[0].upper() + lead[1:] + ".")
    if p["education"]:
        latest = p["education"][0]
        sentences.append(
            f"Formation : {latest['field_of_study']} ({latest['institution']})."
            if fr
            else f"Education: {latest['field_of_study']} ({latest['institution']})."
        )
    years = g.get("experience_years")
    if years:
        sentences.append(
            f"{years:g} an(s) d'expérience professionnelle." if fr else f"{years:g} year(s) of professional experience."
        )
    if p["experiences"]:
        last = p["experiences"][0]
        sentences.append(
            f"Dernier poste : {last['job_title']} chez {last['employer']}."
            if fr
            else f"Most recent role: {last['job_title']} at {last['employer']}."
        )
    if p["skills"]:
        names = ", ".join(s["name"] for s in p["skills"][:8])
        sentences.append(f"Compétences : {names}." if fr else f"Skills: {names}.")
    if p["languages"]:
        langs = ", ".join(f"{x['language_code'].upper()} ({x['cefr_level']})" for x in p["languages"])
        sentences.append(f"Langues : {langs}." if fr else f"Languages: {langs}.")
    return " ".join(sentences)
