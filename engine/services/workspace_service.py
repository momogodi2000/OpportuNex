"""Research workspaces (module M15)."""

from __future__ import annotations

from typing import Any

from sqlalchemy import delete, desc, func, insert, select, update

from core.errors import Conflict, NotFound, ValidationFailed
from core.ids import uuid7
from core.timeutil import now_iso
from services.opportunity_view import card
from services.state import ActiveProfile

TEMPLATES: dict[str, dict[str, Any]] = {
    "job": {
        "name_fr": "Recherche d'emploi",
        "name_en": "Job search",
        "filters": {"categories": ["employment"], "keywords": []},
    },
    "master_scholarship": {
        "name_fr": "Bourse de master",
        "name_en": "Master scholarship",
        "filters": {"categories": ["scholarship.master"], "keywords": []},
    },
    "association_funding": {
        "name_fr": "Financement associatif",
        "name_en": "Association funding",
        "filters": {"categories": ["grant.association"], "keywords": []},
    },
    "startup_funding": {
        "name_fr": "Financement de startup",
        "name_en": "Startup funding",
        "filters": {"categories": ["grant.startup"], "keywords": []},
    },
    "it_consulting": {
        "name_fr": "Conseil informatique",
        "name_en": "IT consulting",
        "filters": {"categories": ["employment.consultancy"], "keywords": ["informatique", "it"]},
    },
    "public_procurement": {
        "name_fr": "Marchés publics",
        "name_en": "Public procurement",
        "filters": {"categories": ["tender"], "keywords": []},
    },
    "internship": {
        "name_fr": "Stages",
        "name_en": "Internships",
        "filters": {"categories": ["internship"], "keywords": []},
    },
}


class WorkspaceService:
    def __init__(self, active: ActiveProfile) -> None:
        self.active = active
        self.T = active.tables
        self.uid = active.user_id

    def _get(self, conn: Any, ws_id: str) -> dict[str, Any]:
        row = (
            conn.execute(
                select(self.T.research_workspaces).where(
                    self.T.research_workspaces.c.id == ws_id, self.T.research_workspaces.c.user_id == self.uid
                )
            )
            .mappings()
            .first()
        )
        if row is None:
            raise NotFound("workspace not found", code="workspace_not_found")
        return dict(row)

    def templates(self) -> list[dict[str, Any]]:
        return [{"code": k} | v for k, v in TEMPLATES.items()]

    def list_items(self, include_archived: bool = False) -> list[dict[str, Any]]:
        T = self.T
        stmt = select(T.research_workspaces).where(T.research_workspaces.c.user_id == self.uid)
        if not include_archived:
            stmt = stmt.where(T.research_workspaces.c.archived == 0)
        with self.active.db.read() as conn:
            rows = [dict(r) for r in conn.execute(stmt.order_by(desc(T.research_workspaces.c.updated_at))).mappings()]
            for r in rows:
                r["archived"] = bool(r["archived"])
                r["counts"] = {
                    "queries": conn.execute(
                        select(func.count())
                        .select_from(T.search_queries)
                        .where(T.search_queries.c.workspace_id == r["id"])
                    ).scalar(),
                    "saved": conn.execute(
                        select(func.count())
                        .select_from(T.saved_opportunities)
                        .where(T.saved_opportunities.c.workspace_id == r["id"])
                    ).scalar(),
                    "opportunities": conn.execute(
                        select(func.count())
                        .select_from(T.workspace_opportunities)
                        .where(T.workspace_opportunities.c.workspace_id == r["id"])
                    ).scalar(),
                    "monitors": conn.execute(
                        select(func.count()).select_from(T.monitors).where(T.monitors.c.workspace_id == r["id"])
                    ).scalar(),
                }
        return rows

    def create(
        self, name: str, description: str | None, template_code: str | None, color: str | None
    ) -> dict[str, Any]:
        if template_code and template_code not in TEMPLATES and template_code != "custom":
            raise ValidationFailed("unknown template", code="workspace_template_invalid")
        T = self.T
        ws_id = uuid7()
        with self.active.db.tx() as conn:
            if conn.execute(
                select(T.research_workspaces.c.id).where(
                    T.research_workspaces.c.user_id == self.uid, T.research_workspaces.c.name == name
                )
            ).first():
                raise Conflict("a workspace already has this name", code="workspace_name_taken")
            conn.execute(
                insert(T.research_workspaces).values(
                    id=ws_id,
                    user_id=self.uid,
                    name=name.strip(),
                    description=description,
                    template_code=template_code,
                    color=color,
                )
            )
        return self.detail(ws_id)

    def update(self, ws_id: str, values: dict[str, Any]) -> dict[str, Any]:
        T = self.T
        clean = {k: v for k, v in values.items() if k in ("name", "description", "color", "archived") and v is not None}
        if "archived" in clean:
            clean["archived"] = 1 if clean["archived"] else 0
        with self.active.db.tx() as conn:
            self._get(conn, ws_id)
            if (
                "name" in clean
                and conn.execute(
                    select(T.research_workspaces.c.id).where(
                        T.research_workspaces.c.user_id == self.uid,
                        T.research_workspaces.c.name == clean["name"],
                        T.research_workspaces.c.id != ws_id,
                    )
                ).first()
            ):
                raise Conflict("a workspace already has this name", code="workspace_name_taken")
            conn.execute(
                update(T.research_workspaces)
                .where(T.research_workspaces.c.id == ws_id)
                .values(**clean, updated_at=now_iso())
            )
        return self.detail(ws_id)

    def delete(self, ws_id: str) -> None:
        with self.active.db.tx() as conn:
            self._get(conn, ws_id)
            conn.execute(delete(self.T.research_workspaces).where(self.T.research_workspaces.c.id == ws_id))

    def detail(self, ws_id: str) -> dict[str, Any]:
        T = self.T
        with self.active.db.read() as conn:
            ws = self._get(conn, ws_id)
            queries = [
                dict(r)
                for r in conn.execute(
                    select(
                        T.search_queries.c.id,
                        T.search_queries.c.raw_text,
                        T.search_queries.c.is_saved,
                        T.search_queries.c.saved_name,
                        T.search_queries.c.created_at,
                    )
                    .where(T.search_queries.c.workspace_id == ws_id)
                    .order_by(desc(T.search_queries.c.created_at))
                ).mappings()
            ]
            opp_rows = [
                dict(r)
                for r in conn.execute(
                    select(T.opportunities)
                    .join(T.workspace_opportunities, T.workspace_opportunities.c.opportunity_id == T.opportunities.c.id)
                    .where(T.workspace_opportunities.c.workspace_id == ws_id)
                ).mappings()
            ]
            saved = set(
                conn.execute(
                    select(T.saved_opportunities.c.opportunity_id).where(T.saved_opportunities.c.user_id == self.uid)
                ).scalars()
            )
            opportunities = [card(conn, T, o, None, saved) for o in opp_rows]
            notes = [
                dict(r)
                for r in conn.execute(
                    select(T.workspace_notes)
                    .where(T.workspace_notes.c.workspace_id == ws_id)
                    .order_by(desc(T.workspace_notes.c.created_at))
                ).mappings()
            ]
            monitors = [
                dict(r)
                for r in conn.execute(
                    select(T.monitors.c.id, T.monitors.c.name, T.monitors.c.enabled).where(
                        T.monitors.c.workspace_id == ws_id
                    )
                ).mappings()
            ]
        template = TEMPLATES.get(ws["template_code"] or "")
        return ws | {
            "archived": bool(ws["archived"]),
            "queries": queries,
            "opportunities": opportunities,
            "notes": notes,
            "monitors": monitors,
            "suggested_filters": template["filters"] if template else None,
        }

    def add_opportunity(self, ws_id: str, opportunity_id: str) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            self._get(conn, ws_id)
            if conn.execute(select(T.opportunities.c.id).where(T.opportunities.c.id == opportunity_id)).first() is None:
                raise NotFound("opportunity not found", code="opportunity_not_found")
            conn.execute(
                delete(T.workspace_opportunities).where(
                    T.workspace_opportunities.c.workspace_id == ws_id,
                    T.workspace_opportunities.c.opportunity_id == opportunity_id,
                )
            )
            conn.execute(insert(T.workspace_opportunities).values(workspace_id=ws_id, opportunity_id=opportunity_id))
        return self.detail(ws_id)

    def remove_opportunity(self, ws_id: str, opportunity_id: str) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            self._get(conn, ws_id)
            conn.execute(
                delete(T.workspace_opportunities).where(
                    T.workspace_opportunities.c.workspace_id == ws_id,
                    T.workspace_opportunities.c.opportunity_id == opportunity_id,
                )
            )
        return self.detail(ws_id)

    def add_note(self, ws_id: str, body: str) -> dict[str, Any]:
        with self.active.db.tx() as conn:
            self._get(conn, ws_id)
            conn.execute(
                insert(self.T.workspace_notes).values(
                    id=uuid7(), workspace_id=ws_id, author_id=self.uid, body=body.strip()
                )
            )
        return self.detail(ws_id)

    def delete_note(self, ws_id: str, note_id: str) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            self._get(conn, ws_id)
            conn.execute(
                delete(T.workspace_notes).where(
                    T.workspace_notes.c.id == note_id, T.workspace_notes.c.workspace_id == ws_id
                )
            )
        return self.detail(ws_id)

    def compare(self, ids: list[str]) -> list[dict[str, Any]]:
        """EF-15.07: two to four opportunities side by side."""
        if not 2 <= len(ids) <= 4:
            raise ValidationFailed("compare 2 to 4 opportunities", code="compare_count")
        from services.matching_service import MatchingService

        T = self.T
        scores = MatchingService(self.active).score_many(ids)
        with self.active.db.read() as conn:
            rows = {
                r["id"]: dict(r)
                for r in conn.execute(select(T.opportunities).where(T.opportunities.c.id.in_(ids))).mappings()
            }
            out = []
            for i in ids:
                if i not in rows:
                    raise NotFound("opportunity not found", code="opportunity_not_found")
                c = card(conn, T, rows[i], scores.get(i))
                c["education_required"] = rows[i]["education_required"]
                c["experience_min_years"] = rows[i]["experience_min_years"]
                c["eligibility_raw"] = rows[i]["eligibility_raw"]
                out.append(c)
        return out
