"""CV import workflow (M03): upload → isolated parsing → per-item review → apply to profile."""

from __future__ import annotations

import hashlib
import json
from typing import Any

from sqlalchemy import Connection, delete, insert, select, update

from core.errors import Conflict, NotFound, ValidationFailed
from core.ids import uuid7
from core.timeutil import now_iso
from documents import cv_parser
from services.profile_service import ProfileService, resolve_skill
from services.state import ActiveProfile

APPLICABLE = ("accepted", "edited")


class CvService:
    def __init__(self, active: ActiveProfile) -> None:
        self.active = active
        self.T = active.tables
        self.uid = active.user_id

    def _known_skills(self, conn: Connection) -> dict[str, str]:
        T = self.T
        rows = conn.execute(
            select(T.skill_aliases.c.alias, T.skills.c.name).join(T.skills, T.skills.c.id == T.skill_aliases.c.skill_id)
        ).all()
        return {alias: name for alias, name in rows}

    def upload(self, file_name: str, data: bytes, keep_file: bool) -> dict[str, Any]:
        mime = cv_parser.detect_mime(file_name, data)
        import_id = uuid7()
        vault_path = self.active.vault.put(data) if keep_file else None
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(
                insert(T.cv_imports).values(
                    id=import_id,
                    user_id=self.uid,
                    file_name=file_name[:200],
                    mime_type=mime,
                    file_size=len(data),
                    sha256=hashlib.sha256(data).hexdigest(),
                    vault_path=vault_path,
                    parser="local",
                    status="parsing",
                )
            )
        try:
            text = cv_parser.extract_text_isolated(mime, data)
        except ValidationFailed as exc:
            with self.active.db.tx() as conn:
                conn.execute(
                    update(T.cv_imports)
                    .where(T.cv_imports.c.id == import_id)
                    .values(status="failed", error_message=exc.code)
                )
                conn.execute(
                    insert(T.security_events).values(
                        user_id=self.uid,
                        event_type="malformed_file",
                        severity="low",
                        detail=exc.code,
                        related_ref=import_id,
                    )
                )
            raise
        with self.active.db.read() as conn:
            known = self._known_skills(conn)
        extraction = cv_parser.extract_items(text, known)
        with self.active.db.tx() as conn:
            for item in extraction.items:
                conn.execute(
                    insert(T.cv_extracted_items).values(
                        cv_import_id=import_id,
                        item_type=item.item_type,
                        payload=json.dumps(item.payload),
                        confidence=round(item.confidence, 2),
                    )
                )
            conn.execute(update(T.cv_imports).where(T.cv_imports.c.id == import_id).values(status="review"))
        return self.get(import_id)

    def _import_row(self, conn: Connection, import_id: str) -> dict[str, Any]:
        row = (
            conn.execute(
                select(self.T.cv_imports).where(
                    self.T.cv_imports.c.id == import_id, self.T.cv_imports.c.user_id == self.uid
                )
            )
            .mappings()
            .first()
        )
        if row is None:
            raise NotFound("CV import not found", code="cv_import_not_found")
        return dict(row)

    def get(self, import_id: str) -> dict[str, Any]:
        T = self.T
        with self.active.db.read() as conn:
            row = self._import_row(conn, import_id)
            items = [
                dict(r) | {"payload": json.loads(r["payload"])}
                for r in conn.execute(
                    select(T.cv_extracted_items)
                    .where(T.cv_extracted_items.c.cv_import_id == import_id)
                    .order_by(T.cv_extracted_items.c.item_type, T.cv_extracted_items.c.id)
                ).mappings()
            ]
        row.pop("sha256", None)
        row["file_kept"] = row.pop("vault_path") is not None
        return row | {"items": items}

    def list_items(self) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.read() as conn:
            rows = (
                conn.execute(
                    select(
                        T.cv_imports.c.id,
                        T.cv_imports.c.file_name,
                        T.cv_imports.c.status,
                        T.cv_imports.c.created_at,
                        T.cv_imports.c.vault_path,
                    )
                    .where(T.cv_imports.c.user_id == self.uid)
                    .order_by(T.cv_imports.c.created_at.desc())
                )
                .mappings()
                .all()
            )
        return [
            {k: v for k, v in r.items() if k != "vault_path"} | {"file_kept": r["vault_path"] is not None} for r in rows
        ]

    def decide(self, import_id: str, item_id: int, decision: str, payload: dict[str, Any] | None) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            row = self._import_row(conn, import_id)
            if row["status"] != "review":
                raise Conflict("import is not under review", code="cv_import_closed")
            values: dict[str, Any] = {"decision": decision, "decided_at": now_iso()}
            if payload is not None:
                values["payload"] = json.dumps(payload)
                values["decision"] = "edited" if decision != "rejected" else "rejected"
            result = conn.execute(
                update(T.cv_extracted_items)
                .where(T.cv_extracted_items.c.id == item_id, T.cv_extracted_items.c.cv_import_id == import_id)
                .values(**values)
            )
            if result.rowcount == 0:
                raise NotFound("item not found", code="cv_item_not_found")
        return self.get(import_id)

    def apply(self, import_id: str) -> dict[str, Any]:
        """Write accepted/edited items into the profile; nothing is applied without validation."""
        T = self.T
        data = self.get(import_id)
        if data["status"] != "review":
            raise Conflict("import is not under review", code="cv_import_closed")
        chosen = [i for i in data["items"] if i["decision"] in APPLICABLE]
        profile = ProfileService(self.active)
        with self.active.db.tx() as conn:
            for item in chosen:
                self._apply_item(conn, item["item_type"], item["payload"])
            conn.execute(update(T.cv_imports).where(T.cv_imports.c.id == import_id).values(status="applied"))
            conn.execute(
                insert(T.audit_logs).values(
                    user_id=self.uid, action="profile.cv_import_applied", entity_table="cv_imports", entity_id=import_id
                )
            )
        return {"applied": len(chosen), "profile": profile._finish()}

    def _apply_item(self, conn: Connection, kind: str, p: dict[str, Any]) -> None:
        T, uid = self.T, self.uid
        if kind == "education":
            conn.execute(
                insert(T.education_records).values(
                    id=uuid7(),
                    user_id=uid,
                    level=p.get("level") or "—",
                    field_of_study=p.get("field_of_study") or "—",
                    institution=p.get("institution") or "—",
                    start_date=p.get("start_date"),
                    end_date=p.get("end_date"),
                    is_ongoing=1 if p.get("is_ongoing") else 0,
                    source="cv_import",
                )
            )
        elif kind == "experience":
            if not p.get("start_date"):
                raise ValidationFailed("experience needs a start date", code="cv_item_incomplete")
            conn.execute(
                insert(T.work_experiences).values(
                    id=uuid7(),
                    user_id=uid,
                    job_title=p.get("job_title") or "—",
                    employer=p.get("employer") or "—",
                    start_date=p["start_date"],
                    end_date=p.get("end_date"),
                    is_current=1 if p.get("is_current") else 0,
                    description=p.get("description"),
                    source="cv_import",
                )
            )
        elif kind == "skill":
            skill_id = resolve_skill(conn, T, str(p["name"]))
            exists = conn.execute(
                select(T.user_skills.c.skill_id).where(
                    T.user_skills.c.user_id == uid, T.user_skills.c.skill_id == skill_id
                )
            ).first()
            if exists is None:
                conn.execute(insert(T.user_skills).values(user_id=uid, skill_id=skill_id))
        elif kind == "language":
            conn.execute(
                delete(T.user_languages).where(
                    T.user_languages.c.user_id == uid, T.user_languages.c.language_code == p["language_code"]
                )
            )
            conn.execute(
                insert(T.user_languages).values(
                    user_id=uid, language_code=p["language_code"], cefr_level=p.get("cefr_level") or "B1"
                )
            )
        elif kind == "certification":
            conn.execute(
                insert(T.certifications).values(
                    id=uuid7(), user_id=uid, name=p["name"], obtained_on=p.get("obtained_on"), source="cv_import"
                )
            )
        elif kind == "link":
            exists = conn.execute(
                select(T.profile_links.c.id).where(T.profile_links.c.user_id == uid, T.profile_links.c.url == p["url"])
            ).first()
            if exists is None:
                conn.execute(insert(T.profile_links).values(user_id=uid, kind=p["kind"], url=p["url"]))
        elif kind == "identity" and p.get("full_name"):
            conn.execute(
                update(T.user_profiles).where(T.user_profiles.c.user_id == uid).values(full_name=p["full_name"])
            )

    def discard(self, import_id: str) -> None:
        T = self.T
        with self.active.db.tx() as conn:
            row = conn.execute(
                select(T.cv_imports.c.vault_path).where(
                    T.cv_imports.c.id == import_id, T.cv_imports.c.user_id == self.uid
                )
            ).first()
            if row is None:
                raise NotFound("CV import not found", code="cv_import_not_found")
            conn.execute(delete(T.cv_imports).where(T.cv_imports.c.id == import_id))
        if row[0]:
            self.active.vault.delete(row[0])

    def delete_source_file(self, import_id: str) -> None:
        """EF-03.05: drop the stored CV while keeping the extracted data."""
        T = self.T
        with self.active.db.tx() as conn:
            row = self._import_row(conn, import_id)
            conn.execute(update(T.cv_imports).where(T.cv_imports.c.id == import_id).values(vault_path=None))
        if row["vault_path"]:
            self.active.vault.delete(row["vault_path"])
