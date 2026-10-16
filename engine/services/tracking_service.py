"""Saved opportunities and application tracking (module M12)."""

from __future__ import annotations

import hashlib
import json
from datetime import UTC, date, datetime, timedelta
from typing import Any

from sqlalchemy import Connection, and_, delete, desc, func, insert, or_, select, update

from core.errors import Conflict, NotFound, ValidationFailed
from core.ids import uuid7
from core.text import fold
from core.timeutil import now_iso, parse_date, today_iso
from services.opportunity_view import card
from services.state import ActiveProfile

STATUSES = (
    "discovered",
    "to_review",
    "preparing",
    "ready",
    "submitted",
    "interview",
    "accepted",
    "rejected",
    "withdrawn",
    "expired",
    "archived",
)
CLOSED = {"accepted", "rejected", "withdrawn", "expired", "archived"}
TRANSITIONS: dict[str, set[str]] = {
    "discovered": {"to_review", "preparing", "withdrawn", "archived", "expired"},
    "to_review": {"discovered", "preparing", "withdrawn", "archived", "expired"},
    "preparing": {"to_review", "ready", "submitted", "withdrawn", "archived", "expired"},
    "ready": {"preparing", "submitted", "withdrawn", "archived", "expired"},
    "submitted": {"interview", "accepted", "rejected", "withdrawn", "archived"},
    "interview": {"submitted", "accepted", "rejected", "withdrawn", "archived"},
    "accepted": {"archived"},
    "rejected": {"archived"},
    "withdrawn": {"archived", "to_review"},
    "expired": {"archived", "to_review"},
    "archived": {"to_review"},
}
MAX_ATTACHMENT = 25 * 1024 * 1024


class TrackingService:
    def __init__(self, active: ActiveProfile) -> None:
        self.active = active
        self.T = active.tables
        self.uid = active.user_id

    # ------------------------------------------------------------- helpers
    def _saved(self, conn: Connection, saved_id: str) -> dict[str, Any]:
        row = (
            conn.execute(
                select(self.T.saved_opportunities).where(
                    self.T.saved_opportunities.c.id == saved_id, self.T.saved_opportunities.c.user_id == self.uid
                )
            )
            .mappings()
            .first()
        )
        if row is None:
            raise NotFound("saved opportunity not found", code="saved_not_found")
        return dict(row)

    def _application(self, conn: Connection, app_id: str) -> dict[str, Any]:
        row = (
            conn.execute(
                select(self.T.applications).where(
                    self.T.applications.c.id == app_id, self.T.applications.c.user_id == self.uid
                )
            )
            .mappings()
            .first()
        )
        if row is None:
            raise NotFound("application not found", code="application_not_found")
        return dict(row)

    def _offsets(self, conn: Connection) -> list[int]:
        raw = conn.execute(
            select(self.T.application_settings.c.value).where(
                self.T.application_settings.c.key == "reminders.default_offsets"
            )
        ).scalar()
        try:
            return [int(x) for x in json.loads(raw or "[14,7,3,1]")]
        except (ValueError, TypeError):
            return [14, 7, 3, 1]

    def _deadline_reminders(
        self, conn: Connection, saved_id: str, title: str, deadline: str | None, kind: str = "deadline"
    ) -> None:
        T = self.T
        conn.execute(
            delete(T.reminders).where(
                T.reminders.c.saved_id == saved_id, T.reminders.c.kind == kind, T.reminders.c.status == "pending"
            )
        )
        d = parse_date(deadline)
        if d is None:
            return
        for offset in self._offsets(conn):
            when = d - timedelta(days=offset)
            if when < date.today():
                continue
            conn.execute(
                insert(T.reminders).values(
                    id=uuid7(),
                    user_id=self.uid,
                    saved_id=saved_id,
                    kind=kind,
                    title=title[:200],
                    remind_at=f"{when.isoformat()}T08:00:00Z",
                    offset_days=offset,
                )
            )

    # ---------------------------------------------------------------- saved
    def save(self, opportunity_id: str, priority: str = "medium", workspace_id: str | None = None) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            opp = conn.execute(select(T.opportunities).where(T.opportunities.c.id == opportunity_id)).mappings().first()
            if opp is None:
                raise NotFound("opportunity not found", code="opportunity_not_found")
            existing = conn.execute(
                select(T.saved_opportunities.c.id).where(
                    T.saved_opportunities.c.user_id == self.uid,
                    T.saved_opportunities.c.opportunity_id == opportunity_id,
                )
            ).scalar()
            if existing:
                raise Conflict("already saved", code="already_saved", extra={"saved_id": existing})
            saved_id = uuid7()
            conn.execute(
                insert(T.saved_opportunities).values(
                    id=saved_id,
                    user_id=self.uid,
                    opportunity_id=opportunity_id,
                    workspace_id=workspace_id,
                    priority=priority,
                )
            )
            conn.execute(
                insert(T.applications).values(id=uuid7(), saved_id=saved_id, user_id=self.uid, status="discovered")
            )
            reqs = conn.execute(
                select(
                    T.opportunity_requirements.c.id,
                    T.opportunity_requirements.c.label,
                    T.opportunity_requirements.c.req_type,
                ).where(
                    T.opportunity_requirements.c.opportunity_id == opportunity_id,
                    T.opportunity_requirements.c.req_type == "document",
                )
            ).all()
            for i, r in enumerate(reqs):
                conn.execute(
                    insert(T.checklist_items).values(
                        saved_id=saved_id, label=r.label, requirement_id=r.id, origin="requirement", sort_order=i
                    )
                )
            self._deadline_reminders(conn, saved_id, opp["title"], opp["deadline_on"])
            conn.execute(
                insert(T.audit_logs).values(
                    user_id=self.uid, action="saved.create", entity_table="saved_opportunities", entity_id=saved_id
                )
            )
        return self.get_saved(saved_id)

    def get_saved(self, saved_id: str) -> dict[str, Any]:
        T = self.T
        with self.active.db.read() as conn:
            s = self._saved(conn, saved_id)
            opp = dict(
                conn.execute(select(T.opportunities).where(T.opportunities.c.id == s["opportunity_id"]))
                .mappings()
                .one()
            )
            app = conn.execute(select(T.applications).where(T.applications.c.saved_id == saved_id)).mappings().first()
            tags = (
                conn.execute(
                    select(T.tags.c.name)
                    .join(T.saved_opportunity_tags, T.saved_opportunity_tags.c.tag_id == T.tags.c.id)
                    .where(T.saved_opportunity_tags.c.saved_id == saved_id)
                )
                .scalars()
                .all()
            )
            score = (
                conn.execute(
                    select(T.match_scores.c.score, T.match_scores.c.eligibility).where(
                        T.match_scores.c.user_id == self.uid, T.match_scores.c.opportunity_id == opp["id"]
                    )
                )
                .mappings()
                .first()
            )
            done, total = conn.execute(
                select(func.sum(T.checklist_items.c.is_done), func.count()).where(
                    T.checklist_items.c.saved_id == saved_id
                )
            ).one()
            c = card(conn, T, opp, dict(score) if score else None, {opp["id"]})
        return s | {
            "archived": bool(s["archived"]),
            "opportunity": c,
            "tags": list(tags),
            "application": dict(app) if app else None,
            "checklist_progress": {"done": int(done or 0), "total": int(total or 0)},
        }

    def list_saved(
        self,
        *,
        q: str | None = None,
        status: str | None = None,
        priority: str | None = None,
        tag: str | None = None,
        archived: bool = False,
        workspace_id: str | None = None,
        sort: str = "deadline",
    ) -> list[dict[str, Any]]:
        T = self.T
        stmt = (
            select(T.saved_opportunities.c.id)
            .join(T.opportunities, T.opportunities.c.id == T.saved_opportunities.c.opportunity_id)
            .join(T.applications, T.applications.c.saved_id == T.saved_opportunities.c.id, isouter=True)
            .where(
                T.saved_opportunities.c.user_id == self.uid, T.saved_opportunities.c.archived == (1 if archived else 0)
            )
        )
        if status:
            stmt = stmt.where(T.applications.c.status == status)
        if priority:
            stmt = stmt.where(T.saved_opportunities.c.priority == priority)
        if workspace_id:
            stmt = stmt.where(T.saved_opportunities.c.workspace_id == workspace_id)
        if tag:
            stmt = stmt.where(
                T.saved_opportunities.c.id.in_(
                    select(T.saved_opportunity_tags.c.saved_id)
                    .join(T.tags, T.tags.c.id == T.saved_opportunity_tags.c.tag_id)
                    .where(T.tags.c.name == tag, T.tags.c.user_id == self.uid)
                )
            )
        order = {
            "deadline": func.coalesce(
                T.saved_opportunities.c.personal_deadline, T.opportunities.c.deadline_on, "9999-12-31"
            ),
            "saved": desc(T.saved_opportunities.c.saved_at),
            "priority": func.instr("high,medium,low", T.saved_opportunities.c.priority),
        }.get(sort)
        if order is None:
            raise ValidationFailed("unknown sort", code="sort_invalid")
        with self.active.db.read() as conn:
            ids = conn.execute(stmt.order_by(order)).scalars().all()
        items = [self.get_saved(i) for i in ids]
        if q:
            needle = fold(q)
            items = [
                i
                for i in items
                if needle
                in fold(
                    f"{i['opportunity']['title']} {i['opportunity']['organization_name'] or ''} {' '.join(i['tags'])}"
                )
            ]
        return items

    def update_saved(self, saved_id: str, values: dict[str, Any]) -> dict[str, Any]:
        T = self.T
        allowed = {"priority", "interest", "ineligible_reason", "personal_deadline", "archived", "workspace_id"}
        clean = {k: v for k, v in values.items() if k in allowed}
        if clean.get("interest") == "ineligible" and not (clean.get("ineligible_reason") or "").strip():
            raise ValidationFailed("a reason is required when marking as ineligible", code="ineligible_reason_required")
        if "archived" in clean:
            clean["archived"] = 1 if clean["archived"] else 0
        with self.active.db.tx() as conn:
            s = self._saved(conn, saved_id)
            if clean:
                conn.execute(
                    update(T.saved_opportunities).where(T.saved_opportunities.c.id == saved_id).values(**clean)
                )
            if "personal_deadline" in clean:
                title = conn.execute(
                    select(T.opportunities.c.title).where(T.opportunities.c.id == s["opportunity_id"])
                ).scalar_one()
                self._deadline_reminders(conn, saved_id, title, clean["personal_deadline"], kind="personal_deadline")
        return self.get_saved(saved_id)

    def unsave(self, saved_id: str) -> None:
        T = self.T
        with self.active.db.tx() as conn:
            self._saved(conn, saved_id)
            paths = (
                conn.execute(
                    select(T.application_documents.c.vault_path).where(T.application_documents.c.saved_id == saved_id)
                )
                .scalars()
                .all()
            )
            conn.execute(delete(T.saved_opportunities).where(T.saved_opportunities.c.id == saved_id))
        for p in paths:
            self.active.vault.delete(p)

    def set_tags(self, saved_id: str, names: list[str]) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            self._saved(conn, saved_id)
            conn.execute(delete(T.saved_opportunity_tags).where(T.saved_opportunity_tags.c.saved_id == saved_id))
            for name in dict.fromkeys(n.strip()[:40] for n in names if n.strip()):
                tag_id = conn.execute(
                    select(T.tags.c.id).where(T.tags.c.user_id == self.uid, T.tags.c.name == name)
                ).scalar()
                if tag_id is None:
                    tag_id = conn.execute(insert(T.tags).values(user_id=self.uid, name=name)).inserted_primary_key[0]  # type: ignore[index]
                conn.execute(insert(T.saved_opportunity_tags).values(saved_id=saved_id, tag_id=tag_id))
            conn.execute(
                delete(T.tags).where(
                    T.tags.c.user_id == self.uid, T.tags.c.id.not_in(select(T.saved_opportunity_tags.c.tag_id))
                )
            )
        return self.get_saved(saved_id)

    def tags(self) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.read() as conn:
            return [
                dict(r)
                for r in conn.execute(
                    select(T.tags.c.id, T.tags.c.name, func.count(T.saved_opportunity_tags.c.saved_id).label("count"))
                    .join(T.saved_opportunity_tags, T.saved_opportunity_tags.c.tag_id == T.tags.c.id, isouter=True)
                    .where(T.tags.c.user_id == self.uid)
                    .group_by(T.tags.c.id)
                    .order_by(T.tags.c.name)
                ).mappings()
            ]

    # ---------------------------------------------------------------- notes
    def notes(self, saved_id: str) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.read() as conn:
            self._saved(conn, saved_id)
            return [
                dict(r)
                for r in conn.execute(
                    select(T.application_notes)
                    .where(T.application_notes.c.saved_id == saved_id)
                    .order_by(desc(T.application_notes.c.created_at))
                ).mappings()
            ]

    def add_note(self, saved_id: str, body: str) -> list[dict[str, Any]]:
        with self.active.db.tx() as conn:
            self._saved(conn, saved_id)
            conn.execute(
                insert(self.T.application_notes).values(
                    id=uuid7(), saved_id=saved_id, author_id=self.uid, body=body.strip()
                )
            )
        return self.notes(saved_id)

    def edit_note(self, saved_id: str, note_id: str, body: str) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.tx() as conn:
            self._saved(conn, saved_id)
            res = conn.execute(
                update(T.application_notes)
                .where(T.application_notes.c.id == note_id, T.application_notes.c.saved_id == saved_id)
                .values(body=body.strip(), updated_at=now_iso())
            )
            if not res.rowcount:
                raise NotFound("note not found", code="note_not_found")
        return self.notes(saved_id)

    def delete_note(self, saved_id: str, note_id: str) -> None:
        T = self.T
        with self.active.db.tx() as conn:
            self._saved(conn, saved_id)
            conn.execute(
                delete(T.application_notes).where(
                    T.application_notes.c.id == note_id, T.application_notes.c.saved_id == saved_id
                )
            )

    # ------------------------------------------------------------ checklist
    def checklist(self, saved_id: str) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.read() as conn:
            self._saved(conn, saved_id)
            return [
                dict(r) | {"is_done": bool(r["is_done"])}
                for r in conn.execute(
                    select(T.checklist_items)
                    .where(T.checklist_items.c.saved_id == saved_id)
                    .order_by(T.checklist_items.c.sort_order, T.checklist_items.c.id)
                ).mappings()
            ]

    def add_check(self, saved_id: str, label: str) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.tx() as conn:
            self._saved(conn, saved_id)
            order = conn.execute(
                select(func.coalesce(func.max(T.checklist_items.c.sort_order), -1)).where(
                    T.checklist_items.c.saved_id == saved_id
                )
            ).scalar_one()
            conn.execute(
                insert(T.checklist_items).values(
                    saved_id=saved_id, label=label.strip()[:300], origin="user", sort_order=int(order) + 1
                )
            )
        return self.checklist(saved_id)

    def update_check(self, saved_id: str, item_id: int, values: dict[str, Any]) -> list[dict[str, Any]]:
        T = self.T
        clean: dict[str, Any] = {}
        if "is_done" in values:
            clean["is_done"] = 1 if values["is_done"] else 0
            clean["done_at"] = now_iso() if values["is_done"] else None
        if values.get("label"):
            clean["label"] = str(values["label"]).strip()[:300]
        if "sort_order" in values:
            clean["sort_order"] = int(values["sort_order"])
        with self.active.db.tx() as conn:
            self._saved(conn, saved_id)
            res = conn.execute(
                update(T.checklist_items)
                .where(T.checklist_items.c.id == item_id, T.checklist_items.c.saved_id == saved_id)
                .values(**clean)
            )
            if not res.rowcount:
                raise NotFound("item not found", code="checklist_item_not_found")
        return self.checklist(saved_id)

    def delete_check(self, saved_id: str, item_id: int) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.tx() as conn:
            self._saved(conn, saved_id)
            conn.execute(
                delete(T.checklist_items).where(
                    T.checklist_items.c.id == item_id, T.checklist_items.c.saved_id == saved_id
                )
            )
        return self.checklist(saved_id)

    # ---------------------------------------------------------- applications
    def application(self, app_id: str) -> dict[str, Any]:
        T = self.T
        with self.active.db.read() as conn:
            app = self._application(conn, app_id)
            history = [
                dict(r)
                for r in conn.execute(
                    select(T.application_status_history)
                    .where(T.application_status_history.c.application_id == app_id)
                    .order_by(T.application_status_history.c.changed_at, T.application_status_history.c.id)
                ).mappings()
            ]
            events = [
                dict(r) | {"done": bool(r["done"])}
                for r in conn.execute(
                    select(T.application_events)
                    .where(T.application_events.c.application_id == app_id)
                    .order_by(T.application_events.c.scheduled_at)
                ).mappings()
            ]
            docs = [
                dict(r)
                for r in conn.execute(
                    select(
                        T.application_documents.c.id,
                        T.application_documents.c.label,
                        T.application_documents.c.file_name,
                        T.application_documents.c.mime_type,
                        T.application_documents.c.file_size,
                        T.application_documents.c.checklist_item_id,
                        T.application_documents.c.uploaded_at,
                    ).where(T.application_documents.c.saved_id == app["saved_id"])
                ).mappings()
            ]
            reminders = [
                dict(r)
                for r in conn.execute(
                    select(T.reminders)
                    .where(T.reminders.c.saved_id == app["saved_id"])
                    .order_by(T.reminders.c.remind_at)
                ).mappings()
            ]
        return app | {
            "history": history,
            "events": events,
            "documents": docs,
            "reminders": reminders,
            "allowed_transitions": sorted(TRANSITIONS.get(app["status"], set())),
            "saved": self.get_saved(app["saved_id"]),
            "checklist": self.checklist(app["saved_id"]),
        }

    def transition(
        self,
        app_id: str,
        new_status: str,
        note: str | None,
        submitted_on: str | None,
        submission_ref: str | None,
        outcome_note: str | None = None,
    ) -> dict[str, Any]:
        """EF-12.04/05. 'submitted' is only ever set by the user, with the date (EF-10.12)."""
        if new_status not in STATUSES:
            raise ValidationFailed("unknown status", code="status_invalid")
        T = self.T
        with self.active.db.tx() as conn:
            app = self._application(conn, app_id)
            if new_status not in TRANSITIONS.get(app["status"], set()):
                raise Conflict(
                    "transition not allowed", code="transition_invalid", extra={"from": app["status"], "to": new_status}
                )
            values: dict[str, Any] = {"status": new_status}
            if new_status == "submitted":
                if not submitted_on:
                    raise ValidationFailed("submission date required", code="submitted_on_required")
                values |= {"submitted_on": submitted_on, "submission_ref": submission_ref}
            if new_status in ("accepted", "rejected"):
                values |= {"outcome_on": today_iso(), "outcome_note": outcome_note}
            conn.execute(update(T.applications).where(T.applications.c.id == app_id).values(**values))
            if note:
                last = conn.execute(
                    select(T.application_status_history.c.id)
                    .where(T.application_status_history.c.application_id == app_id)
                    .order_by(desc(T.application_status_history.c.id))
                    .limit(1)
                ).scalar()
                conn.execute(
                    update(T.application_status_history)
                    .where(T.application_status_history.c.id == last)
                    .values(note=note[:1000])
                )
            if new_status in CLOSED:
                conn.execute(
                    update(T.reminders)
                    .where(T.reminders.c.saved_id == app["saved_id"], T.reminders.c.status == "pending")
                    .values(status="cancelled")
                )
            conn.execute(
                insert(T.audit_logs).values(
                    user_id=self.uid,
                    action="application.status_change",
                    entity_table="applications",
                    entity_id=app_id,
                    detail=json.dumps({"from": app["status"], "to": new_status}),
                )
            )
        return self.application(app_id)

    def add_event(self, app_id: str, values: dict[str, Any]) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            app = self._application(conn, app_id)
            event_id = uuid7()
            conn.execute(insert(T.application_events).values(id=event_id, application_id=app_id, **values))
            if values.get("scheduled_at"):
                when = datetime.fromisoformat(values["scheduled_at"].replace("Z", "+00:00"))
                conn.execute(
                    insert(T.reminders).values(
                        id=uuid7(),
                        user_id=self.uid,
                        saved_id=app["saved_id"],
                        application_event_id=event_id,
                        kind="event",
                        title=values["title"][:200],
                        remind_at=(when - timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%SZ"),
                        offset_days=1,
                    )
                )
        return self.application(app_id)

    def update_event(self, app_id: str, event_id: str, values: dict[str, Any]) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            self._application(conn, app_id)
            if "done" in values:
                values["done"] = 1 if values["done"] else 0
            res = conn.execute(
                update(T.application_events)
                .where(T.application_events.c.id == event_id, T.application_events.c.application_id == app_id)
                .values(**values)
            )
            if not res.rowcount:
                raise NotFound("event not found", code="event_not_found")
        return self.application(app_id)

    def delete_event(self, app_id: str, event_id: str) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            self._application(conn, app_id)
            conn.execute(
                delete(T.application_events).where(
                    T.application_events.c.id == event_id, T.application_events.c.application_id == app_id
                )
            )
        return self.application(app_id)

    # ----------------------------------------------------------- documents
    def attach(
        self, saved_id: str, label: str, file_name: str, mime: str, data: bytes, checklist_item_id: int | None
    ) -> dict[str, Any]:
        if not data:
            raise ValidationFailed("empty file", code="file_empty")
        if len(data) > MAX_ATTACHMENT:
            raise ValidationFailed("file larger than 25 MB", code="file_too_large")
        T = self.T
        with self.active.db.read() as conn:
            self._saved(conn, saved_id)
        rel = self.active.vault.put(data)
        with self.active.db.tx() as conn:
            doc_id = uuid7()
            conn.execute(
                insert(T.application_documents).values(
                    id=doc_id,
                    saved_id=saved_id,
                    user_id=self.uid,
                    label=label[:200],
                    file_name=file_name[:200],
                    mime_type=mime[:100],
                    file_size=len(data),
                    sha256=hashlib.sha256(data).hexdigest(),
                    vault_path=rel,
                    checklist_item_id=checklist_item_id,
                )
            )
            if checklist_item_id:
                conn.execute(
                    update(T.checklist_items)
                    .where(T.checklist_items.c.id == checklist_item_id, T.checklist_items.c.saved_id == saved_id)
                    .values(is_done=1, done_at=now_iso())
                )
        return {"id": doc_id, "label": label, "file_name": file_name, "file_size": len(data)}

    def document(self, saved_id: str, doc_id: str) -> tuple[str, str, bytes]:
        T = self.T
        with self.active.db.read() as conn:
            self._saved(conn, saved_id)
            row = (
                conn.execute(
                    select(T.application_documents).where(
                        T.application_documents.c.id == doc_id, T.application_documents.c.saved_id == saved_id
                    )
                )
                .mappings()
                .first()
            )
        if row is None:
            raise NotFound("document not found", code="document_not_found")
        return row["file_name"], row["mime_type"], self.active.vault.get(row["vault_path"])

    def delete_document(self, saved_id: str, doc_id: str) -> None:
        T = self.T
        with self.active.db.tx() as conn:
            self._saved(conn, saved_id)
            path = conn.execute(
                select(T.application_documents.c.vault_path).where(
                    T.application_documents.c.id == doc_id, T.application_documents.c.saved_id == saved_id
                )
            ).scalar()
            if path is None:
                raise NotFound("document not found", code="document_not_found")
            conn.execute(delete(T.application_documents).where(T.application_documents.c.id == doc_id))
        self.active.vault.delete(path)

    # -------------------------------------------------------- board/calendar
    def board(self) -> dict[str, Any]:
        T = self.T
        with self.active.db.read() as conn:
            rows = conn.execute(
                select(T.applications.c.id, T.applications.c.status, T.applications.c.saved_id)
                .join(T.saved_opportunities, T.saved_opportunities.c.id == T.applications.c.saved_id)
                .where(T.applications.c.user_id == self.uid, T.saved_opportunities.c.archived == 0)
            ).all()
        columns: dict[str, list[dict[str, Any]]] = {s: [] for s in STATUSES if s != "archived"}
        for app_id, status, saved_id in rows:
            if status in columns:
                columns[status].append({"application_id": app_id} | self.get_saved(saved_id))
        return {
            "columns": [{"status": s, "items": items} for s, items in columns.items()],
            "transitions": {k: sorted(v) for k, v in TRANSITIONS.items()},
        }

    def calendar(self, start: str, end: str) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.read() as conn:
            deadlines = conn.execute(
                select(
                    T.saved_opportunities.c.id,
                    T.opportunities.c.title,
                    T.opportunities.c.deadline_on,
                    T.saved_opportunities.c.personal_deadline,
                )
                .join(T.opportunities, T.opportunities.c.id == T.saved_opportunities.c.opportunity_id)
                .where(T.saved_opportunities.c.user_id == self.uid, T.saved_opportunities.c.archived == 0)
            ).all()
            events = (
                conn.execute(
                    select(T.application_events, T.applications.c.saved_id)
                    .join(T.applications, T.applications.c.id == T.application_events.c.application_id)
                    .where(
                        T.applications.c.user_id == self.uid,
                        T.application_events.c.scheduled_at.is_not(None),
                        and_(
                            T.application_events.c.scheduled_at >= start,
                            T.application_events.c.scheduled_at <= end + "T23:59:59Z",
                        ),
                    )
                )
                .mappings()
                .all()
            )
        out: list[dict[str, Any]] = []
        for saved_id, title, deadline, personal in deadlines:
            if deadline and start <= deadline <= end:
                out.append({"type": "deadline", "date": deadline, "title": title, "saved_id": saved_id})
            if personal and start <= personal <= end:
                out.append({"type": "personal_deadline", "date": personal, "title": title, "saved_id": saved_id})
        for e in events:
            out.append(
                {
                    "type": e["event_type"],
                    "date": e["scheduled_at"],
                    "title": e["title"],
                    "saved_id": e["saved_id"],
                    "event_id": e["id"],
                    "location": e["location"],
                }
            )
        return sorted(out, key=lambda x: x["date"])

    def ics(self) -> str:
        """EF-12.10: iCalendar export of deadlines and events."""
        items = self.calendar("1970-01-01", "2999-12-31")
        stamp = datetime.now(UTC).strftime("%Y%m%dT%H%M%SZ")

        def esc(t: str) -> str:
            return t.replace("\\", "\\\\").replace(";", "\\;").replace(",", "\\,").replace("\n", "\\n")

        lines = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//ETS Monthe Network//Opportunex//FR", "CALSCALE:GREGORIAN"]
        for i, it in enumerate(items):
            uid = f"{it.get('event_id') or it['saved_id']}-{it['type']}-{i}@opportunex"
            lines += ["BEGIN:VEVENT", f"UID:{uid}", f"DTSTAMP:{stamp}"]
            if len(it["date"]) == 10:
                lines.append(f"DTSTART;VALUE=DATE:{it['date'].replace('-', '')}")
            else:
                lines.append(f"DTSTART:{it['date'].replace('-', '').replace(':', '')}")
            prefix = {"deadline": "Date limite", "personal_deadline": "Échéance personnelle"}.get(
                it["type"], it["type"]
            )
            lines += [f"SUMMARY:{esc(prefix + ' — ' + it['title'])}", "END:VEVENT"]
        lines.append("END:VCALENDAR")
        return "\r\n".join(lines) + "\r\n"

    def auto_archive(self, after_days: int = 60) -> int:
        """EF-12.12: archive closed applications after a delay."""
        T = self.T
        limit = (date.today() - timedelta(days=after_days)).isoformat()
        with self.active.db.tx() as conn:
            ids = (
                conn.execute(
                    select(T.applications.c.saved_id).where(
                        T.applications.c.user_id == self.uid,
                        T.applications.c.status.in_(CLOSED - {"archived"}),
                        T.applications.c.updated_at < limit,
                    )
                )
                .scalars()
                .all()
            )
            if ids:
                conn.execute(
                    update(T.saved_opportunities).where(T.saved_opportunities.c.id.in_(ids)).values(archived=1)
                )
        return len(ids)

    def mark_expired(self) -> int:
        """Applications still open whose opportunity is expired move to 'expired'."""
        T = self.T
        with self.active.db.tx() as conn:
            ids = (
                conn.execute(
                    select(T.applications.c.id)
                    .join(T.saved_opportunities, T.saved_opportunities.c.id == T.applications.c.saved_id)
                    .join(T.opportunities, T.opportunities.c.id == T.saved_opportunities.c.opportunity_id)
                    .where(
                        T.applications.c.user_id == self.uid,
                        T.applications.c.status.in_(("discovered", "to_review", "preparing", "ready")),
                        or_(
                            T.opportunities.c.verification_status == "expired",
                            T.opportunities.c.deadline_on < today_iso(),
                        ),
                    )
                )
                .scalars()
                .all()
            )
            if ids:
                conn.execute(update(T.applications).where(T.applications.c.id.in_(ids)).values(status="expired"))
        return len(ids)
