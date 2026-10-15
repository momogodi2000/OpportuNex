"""Generated documents with versions and exports (EF-10.06..10.11)."""

from __future__ import annotations

import json
from typing import Any

from sqlalchemy import desc, func, insert, select, update

from core.errors import NotFound, ValidationFailed
from core.ids import uuid7
from core.timeutil import now_iso
from documents import generator
from services.profile_service import ProfileService
from services.state import ActiveProfile


class DocumentService:
    def __init__(self, active: ActiveProfile) -> None:
        self.active = active
        self.T = active.tables
        self.uid = active.user_id

    def _saved_opp(self, saved_id: str) -> dict[str, Any]:
        T = self.T
        with self.active.db.read() as conn:
            row = (
                conn.execute(
                    select(T.opportunities, T.saved_opportunities.c.id.label("saved_id"))
                    .join(T.saved_opportunities, T.saved_opportunities.c.opportunity_id == T.opportunities.c.id)
                    .where(T.saved_opportunities.c.id == saved_id, T.saved_opportunities.c.user_id == self.uid)
                )
                .mappings()
                .first()
            )
            if row is None:
                raise NotFound("saved opportunity not found", code="saved_not_found")
            opp = dict(row)
            opp["required_skills"] = (
                conn.execute(
                    select(T.opportunity_requirements.c.label).where(
                        T.opportunity_requirements.c.opportunity_id == opp["id"],
                        T.opportunity_requirements.c.req_type == "skill",
                    )
                )
                .scalars()
                .all()
            )
        return opp

    def generate(self, saved_id: str, doc_type: str, lang: str) -> dict[str, Any]:
        if doc_type not in generator.DOC_TYPES or doc_type == "checklist":
            raise ValidationFailed("unknown document type", code="doc_type_invalid")
        opp = self._saved_opp(saved_id)
        profile = ProfileService(self.active).get()
        title, content = generator.build(doc_type, profile, opp, lang)
        flags = generator.integrity_flags(content, profile)
        T = self.T
        doc_id = uuid7()
        with self.active.db.tx() as conn:
            conn.execute(
                insert(T.generated_documents).values(
                    id=doc_id,
                    saved_id=saved_id,
                    user_id=self.uid,
                    doc_type=doc_type,
                    title=title[:200],
                    language_code=lang,
                    current_version=1,
                )
            )
            # origin "ai" is the schema's label for machine-generated text; analysis_method stays deterministic.
            conn.execute(
                insert(T.generated_document_versions).values(
                    document_id=doc_id,
                    version=1,
                    content=content,
                    origin="ai",
                    integrity_flags=json.dumps(flags) if flags else None,
                )
            )
        return self.get(doc_id)

    def _doc(self, doc_id: str) -> dict[str, Any]:
        T = self.T
        with self.active.db.read() as conn:
            row = (
                conn.execute(
                    select(T.generated_documents).where(
                        T.generated_documents.c.id == doc_id, T.generated_documents.c.user_id == self.uid
                    )
                )
                .mappings()
                .first()
            )
        if row is None:
            raise NotFound("document not found", code="document_not_found")
        return dict(row)

    def get(self, doc_id: str) -> dict[str, Any]:
        doc = self._doc(doc_id)
        T = self.T
        with self.active.db.read() as conn:
            versions = [
                dict(r)
                | {
                    "integrity_flags": json.loads(r["integrity_flags"]) if r["integrity_flags"] else [],
                    "generated": r["origin"] == "ai",
                }
                for r in conn.execute(
                    select(T.generated_document_versions)
                    .where(T.generated_document_versions.c.document_id == doc_id)
                    .order_by(desc(T.generated_document_versions.c.version))
                ).mappings()
            ]
        return doc | {"versions": versions, "content": versions[0]["content"] if versions else ""}

    def list_items(self, saved_id: str) -> list[dict[str, Any]]:
        self._saved_opp(saved_id)
        T = self.T
        with self.active.db.read() as conn:
            return [
                dict(r)
                for r in conn.execute(
                    select(T.generated_documents)
                    .where(T.generated_documents.c.saved_id == saved_id)
                    .order_by(desc(T.generated_documents.c.updated_at))
                ).mappings()
            ]

    def save_version(self, doc_id: str, content: str) -> dict[str, Any]:
        """EF-10.11 versioning; EF-10.10 integrity flags on every edit."""
        doc = self._doc(doc_id)
        flags = generator.integrity_flags(content, ProfileService(self.active).get())
        T = self.T
        with self.active.db.tx() as conn:
            version = (
                int(
                    conn.execute(
                        select(func.max(T.generated_document_versions.c.version)).where(
                            T.generated_document_versions.c.document_id == doc_id
                        )
                    ).scalar()
                    or 0
                )
                + 1
            )
            conn.execute(
                insert(T.generated_document_versions).values(
                    document_id=doc_id,
                    version=version,
                    content=content,
                    origin="user_edit",
                    integrity_flags=json.dumps(flags) if flags else None,
                )
            )
            conn.execute(
                update(T.generated_documents)
                .where(T.generated_documents.c.id == doc_id)
                .values(current_version=version, updated_at=now_iso())
            )
            if flags:
                conn.execute(
                    insert(T.security_events).values(
                        user_id=self.uid,
                        event_type="integrity_flag",
                        severity="low",
                        detail=f"{len(flags)} unsupported claim(s)",
                        related_ref=doc["id"],
                    )
                )
        return self.get(doc_id)

    def delete(self, doc_id: str) -> None:
        self._doc(doc_id)
        from sqlalchemy import delete as sa_delete

        with self.active.db.tx() as conn:
            conn.execute(sa_delete(self.T.generated_documents).where(self.T.generated_documents.c.id == doc_id))

    def export(self, doc_id: str, fmt: str) -> tuple[str, str, bytes]:
        doc = self.get(doc_id)
        safe = "".join(c if c.isalnum() or c in "-_ " else "_" for c in doc["title"])[:80].strip() or "document"
        if fmt == "docx":
            return (
                f"{safe}.docx",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                generator.to_docx(doc["title"], doc["content"]),
            )
        if fmt == "pdf":
            return f"{safe}.pdf", "application/pdf", generator.to_pdf(doc["title"], doc["content"])
        if fmt == "md":
            return f"{safe}.md", "text/markdown; charset=utf-8", doc["content"].encode("utf-8")
        raise ValidationFailed("unknown format", code="format_invalid")
