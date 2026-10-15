"""Searches as background jobs (M04/M05/M09): collect → extract → dedupe → score → rank.

* Per-source progress over the event bus, cancellation and resume (EF-04.06).
* Sources that are unreachable, blocked by robots.txt or disabled by policy are reported with
  their official search link instead of a false success (EF-05.12).
* Every source run is logged in ``source_scan_runs`` (EF-05.11).
"""

from __future__ import annotations

import asyncio
import base64
import json
from datetime import date
from typing import Any

import structlog
from sqlalchemy import Connection, and_, delete, desc, func, insert, or_, select, text, update

from collection.adapters import AdapterError, RawItem, extract_detail, structured_fields
from collection.catalog import sync_catalog
from collection.fetching import fetch_list, keyword_filter
from collection.http import FetchError, FetchResult, PoliteClient, url_hash
from collection.normalize import CountryIndex, normalize
from collection.store import store_item
from core.errors import Conflict, NotFound, ValidationFailed
from core.ids import uuid7
from core.text import fold
from core.timeutil import in_iso, now_iso, today_iso
from search.interpreter import interpret, query_string
from services.jobs import JobContext
from services.matching_service import MatchingService
from services.opportunity_view import card
from services.state import ActiveProfile, EngineState

log = structlog.get_logger(__name__)

DETAIL_PER_SOURCE = 12
SORTS = ("relevance", "deadline", "published", "amount", "recent")


def _encode_cursor(offset: int) -> str:
    return base64.urlsafe_b64encode(str(offset).encode()).decode()


def _decode_cursor(cursor: str | None) -> int:
    if not cursor:
        return 0
    try:
        return max(0, int(base64.urlsafe_b64decode(cursor.encode()).decode()))
    except (ValueError, UnicodeDecodeError) as exc:
        raise ValidationFailed("invalid cursor", code="cursor_invalid") from exc


class SearchService:
    def __init__(self, active: ActiveProfile, state: EngineState) -> None:
        self.active = active
        self.state = state
        self.T = active.tables
        self.uid = active.user_id

    # ------------------------------------------------------------ interpret
    def _country_index(self, conn: Connection) -> CountryIndex:
        return CountryIndex.from_rows([dict(r) for r in conn.execute(select(self.T.countries)).mappings()])

    def interpret(self, raw_text: str) -> dict[str, Any]:
        with self.active.db.read() as conn:
            index = self._country_index(conn)
        filters = interpret(raw_text, index.names)
        return {"filters": filters, "interpreter": "rules"}

    # ---------------------------------------------------------------- start
    def prepare_run(
        self,
        raw_text: str,
        filters: dict[str, Any],
        *,
        workspace_id: str | None,
        source_ids: list[str] | None,
        trigger: str = "manual",
        query_id: str | None = None,
    ) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            sync_catalog(conn, T)
            self.expire_overdue(conn)
            if (
                workspace_id
                and conn.execute(
                    select(T.research_workspaces.c.id).where(
                        T.research_workspaces.c.id == workspace_id, T.research_workspaces.c.user_id == self.uid
                    )
                ).first()
                is None
            ):
                raise NotFound("workspace not found", code="workspace_not_found")
            if query_id is None:
                query_id = uuid7()
                conn.execute(
                    insert(T.search_queries).values(
                        id=query_id,
                        user_id=self.uid,
                        workspace_id=workspace_id,
                        raw_text=raw_text[:1000],
                        interpreted_filters=json.dumps(self.interpret_with(conn, raw_text)),
                        final_filters=json.dumps(filters | ({"source_ids": source_ids} if source_ids else {})),
                        interpreter="rules",
                    )
                )
            if source_ids is None:
                source_ids = filters.get("source_ids")  # a rerun keeps the original selection
            sources = self._select_sources(conn, filters, source_ids)
            run_id = uuid7()
            conn.execute(
                insert(T.search_runs).values(
                    id=run_id,
                    query_id=query_id,
                    user_id=self.uid,
                    trigger=trigger,
                    status="queued",
                    sources_total=len(sources),
                )
            )
            for s in sources:
                conn.execute(
                    insert(T.search_run_sources).values(search_run_id=run_id, source_id=s["id"], status="queued")
                )
        return {"run_id": run_id, "query_id": query_id, "sources": len(sources)}

    def interpret_with(self, conn: Connection, raw_text: str) -> dict[str, Any]:
        return interpret(raw_text, self._country_index(conn).names)

    def _select_sources(
        self, conn: Connection, filters: dict[str, Any], source_ids: list[str] | None
    ) -> list[dict[str, Any]]:
        T = self.T
        stmt = (
            select(T.sources, T.source_adapters.c.spec)
            .join(
                T.source_adapters,
                and_(T.source_adapters.c.source_id == T.sources.c.id, T.source_adapters.c.is_active == 1),
            )
            .where(
                T.sources.c.enabled == 1,
                T.sources.c.access_method != "manual_link",
                or_(T.sources.c.owner_user_id.is_(None), T.sources.c.owner_user_id == self.uid),
            )
        )
        if source_ids:
            stmt = stmt.where(T.sources.c.id.in_(source_ids))
        rows = [dict(r) for r in conn.execute(stmt).mappings()]
        cats = [c.split(".")[0] for c in filters.get("categories") or []]
        if cats and not source_ids:
            by_source: dict[str, set[str]] = {}
            for sid, code in conn.execute(
                select(T.source_categories.c.source_id, T.opportunity_categories.c.code).join(
                    T.opportunity_categories, T.opportunity_categories.c.id == T.source_categories.c.category_id
                )
            ):
                by_source.setdefault(sid, set()).add(code.split(".")[0])
            rows = [r for r in rows if not by_source.get(r["id"]) or by_source[r["id"]] & set(cats)]
        return rows

    def runner(self, run_id: str) -> Any:
        async def run(ctx: JobContext) -> dict[str, Any]:
            try:
                return await self._collect(ctx, run_id)
            except BaseException as exc:
                status = "cancelled" if isinstance(exc, (asyncio.CancelledError,)) or ctx.cancelled else "failed"
                await asyncio.to_thread(self._mark_run, run_id, status, type(exc).__name__)
                self.state.events.publish("search.completed", {"run_id": run_id, "status": status, "results": 0})
                raise

        return run

    def _mark_run(self, run_id: str, status: str, error: str) -> None:
        try:
            with self.active.db.tx() as conn:
                conn.execute(
                    update(self.T.search_runs)
                    .where(self.T.search_runs.c.id == run_id)
                    .values(status=status, finished_at=now_iso(), error_summary=error[:200])
                )
        except Exception:  # noqa: BLE001 - the profile may be locked; the run stays resumable
            log.warning("search_run_status_not_saved")

    # -------------------------------------------------------------- collect
    def _db(self, fn: Any, *args: Any) -> Any:
        return asyncio.to_thread(fn, *args)

    def _tx(self, stmt: Any) -> None:
        with self.active.db.tx() as conn:
            conn.execute(stmt)

    def _cache_get(self, url: str) -> dict[str, Any] | None:
        T = self.T
        with self.active.db.read() as conn:
            row = conn.execute(select(T.http_cache).where(T.http_cache.c.url_hash == url_hash(url))).mappings().first()
        return dict(row) if row else None

    def _cache_put(self, url: str, res: FetchResult) -> None:
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(delete(T.http_cache).where(T.http_cache.c.url_hash == url_hash(url)))
            conn.execute(
                insert(T.http_cache).values(
                    url_hash=url_hash(url),
                    url=url[:2000],
                    etag=res.etag,
                    last_modified=res.last_modified,
                    status_code=res.status,
                    content_type=res.content_type[:200],
                    body=res.body,
                    fetched_at=now_iso(),
                    expires_at=in_iso(days=7),
                )
            )

    async def _collect(self, ctx: JobContext, run_id: str) -> dict[str, Any]:
        T = self.T
        run, filters, sources = await self._db(self._load_run, run_id)
        done_sources: set[str] = set((ctx.checkpoint_data or {}).get("done", []))
        await self._db(
            self._tx,
            update(T.search_runs)
            .where(T.search_runs.c.id == run_id)
            .values(status="running", started_at=run.get("started_at") or now_iso(), job_id=ctx.job_id),
        )
        query = query_string(filters)
        keywords = list(filters.get("keywords") or [])
        with self.active.db.read() as conn:
            countries = self._country_index(conn)
            skill_aliases = dict(
                conn.execute(
                    select(T.skill_aliases.c.alias, T.skills.c.name).join(
                        T.skills, T.skills.c.id == T.skill_aliases.c.skill_id
                    )
                ).all()
            )
        found: dict[str, bool] = dict((ctx.checkpoint_data or {}).get("found", {}))
        failed = 0
        lock = asyncio.Lock()
        from services.privacy_service import PrivacyService

        net = await self._db(PrivacyService(self.active).network)
        self._data_saver = bool(net["data_saver"])
        client = PoliteClient(
            allow_private=self.state.settings.allow_private_network,
            cache_get=self._cache_get,
            cache_put=self._cache_put,
            proxy=net["proxy_url"],
            byte_budget=int(net["max_mb_per_search"]) * 1024 * 1024,
        )
        pending = [s for s in sources if s["id"] not in done_sources]
        total = len(sources)

        async def one(source: dict[str, Any]) -> None:
            nonlocal failed
            ctx.raise_if_cancelled()
            outcome = await self._scan_source(ctx, run_id, source, client, query, keywords, countries, skill_aliases)
            async with lock:
                done_sources.add(source["id"])
                if outcome["status"] in ("failed", "blocked"):
                    failed += 1
                for oid, created in outcome["opportunities"].items():
                    found[oid] = found.get(oid, False) or created
                await ctx.checkpoint({"done": sorted(done_sources), "found": found})
                await ctx.progress(
                    int(100 * len(done_sources) / max(1, total)),
                    source["name"],
                    run_id=run_id,
                    source_id=source["id"],
                    source_status=outcome["status"],
                    found=len(found),
                )
                await self._db(
                    self._tx,
                    update(T.search_runs)
                    .where(T.search_runs.c.id == run_id)
                    .values(sources_done=len(done_sources), sources_failed=failed),
                )

        try:
            await asyncio.gather(*(one(s) for s in pending))
        finally:
            await client.close()
        ranked = await self._db(self._finalize, run_id, filters, found, failed, total)
        return {"run_id": run_id, "results": ranked, "sources_failed": failed}

    def _load_run(self, run_id: str) -> tuple[dict[str, Any], dict[str, Any], list[dict[str, Any]]]:
        T = self.T
        with self.active.db.read() as conn:
            run = (
                conn.execute(
                    select(T.search_runs).where(T.search_runs.c.id == run_id, T.search_runs.c.user_id == self.uid)
                )
                .mappings()
                .first()
            )
            if run is None:
                raise NotFound("run not found", code="run_not_found")
            filters = json.loads(
                conn.execute(
                    select(T.search_queries.c.final_filters).where(T.search_queries.c.id == run["query_id"])
                ).scalar_one()
            )
            sources = [
                dict(r)
                for r in conn.execute(
                    select(T.sources, T.source_adapters.c.spec)
                    .join(T.search_run_sources, T.search_run_sources.c.source_id == T.sources.c.id)
                    .join(
                        T.source_adapters,
                        and_(T.source_adapters.c.source_id == T.sources.c.id, T.source_adapters.c.is_active == 1),
                    )
                    .where(T.search_run_sources.c.search_run_id == run_id)
                ).mappings()
            ]
        return dict(run), filters, sources

    async def _scan_source(
        self,
        ctx: JobContext,
        run_id: str,
        source: dict[str, Any],
        client: PoliteClient,
        query: str,
        keywords: list[str],
        countries: CountryIndex,
        skill_aliases: dict[str, str],
    ) -> dict[str, Any]:
        T = self.T
        spec = json.loads(source["spec"])
        scan_id = uuid7()
        await self._db(
            self._tx,
            insert(T.source_scan_runs).values(
                id=scan_id,
                source_id=source["id"],
                job_id=ctx.job_id,
                trigger="search",
                adapter_version=str(spec.get("version")),
                status="running",
            ),
        )
        await self._db(
            self._tx,
            update(T.search_run_sources)
            .where(T.search_run_sources.c.search_run_id == run_id, T.search_run_sources.c.source_id == source["id"])
            .values(status="running", scan_run_id=scan_id),
        )
        opportunities: dict[str, bool] = {}
        status, error_code, message = "ok", None, None
        before = client.requests_made, client.bytes_received
        found_items = new = updated = 0
        try:
            listing = await fetch_list(client, spec, query)
            items = keyword_filter(listing.items, keywords, spec)
            found_items = len(items)
            for i, item in enumerate(items[: int(spec.get("max_items", 30))]):
                ctx.raise_if_cancelled()
                detail_text, structured = "", None
                if spec.get("detail") and i < DETAIL_PER_SOURCE and not getattr(self, "_data_saver", False):
                    detail_text, structured = await self._detail(client, item)
                outcome = await self._db(
                    self._store_one, source, scan_id, item, detail_text, structured, countries, skill_aliases
                )
                if outcome is not None:
                    oid, created, changed = outcome
                    opportunities[oid] = created
                    new += int(created)
                    updated += int(bool(changed))
        except FetchError as exc:
            status = "blocked" if exc.code in ("robots_disallowed", "ssrf_blocked") else "failed"
            error_code, message = exc.code, exc.detail[:300]
        except AdapterError as exc:
            status, error_code, message = "failed", exc.code, str(exc)[:300]
        final_status = status if status != "ok" else ("ok" if found_items else "partial" if opportunities else "ok")
        await self._db(
            self._tx,
            update(T.source_scan_runs)
            .where(T.source_scan_runs.c.id == scan_id)
            .values(
                status=final_status,
                http_requests=client.requests_made - before[0],
                bytes_received=client.bytes_received - before[1],
                items_found=found_items,
                items_new=new,
                items_updated=updated,
                error_code=error_code,
                error_detail=message,
                finished_at=now_iso(),
            ),
        )
        await self._db(
            self._tx,
            update(T.search_run_sources)
            .where(T.search_run_sources.c.search_run_id == run_id, T.search_run_sources.c.source_id == source["id"])
            .values(status=final_status, message=error_code),
        )
        return {"status": final_status, "opportunities": opportunities}

    async def _detail(self, client: PoliteClient, item: RawItem) -> tuple[str, dict[str, Any] | None]:
        try:
            res = await client.get(item.url)
        except FetchError:
            return "", None
        if "html" not in res.content_type and not res.body.lstrip().startswith(b"<"):
            return "", None
        text_, obj = await asyncio.to_thread(extract_detail, res.body, item.url)
        return text_, structured_fields(obj) if obj else None

    def _store_one(
        self,
        source: dict[str, Any],
        scan_id: str,
        item: RawItem,
        detail_text: str,
        structured: dict[str, Any] | None,
        countries: CountryIndex,
        skill_aliases: dict[str, str],
    ) -> tuple[str, bool, list[str]] | None:
        normalized = normalize(
            item.title,
            item.summary,
            item.fields,
            detail_text,
            structured,
            countries,
            skill_aliases,
            source.get("country_code"),
            source.get("language_code"),
        )
        if not normalized.title:
            return None
        with self.active.db.tx() as conn:
            out = store_item(
                conn,
                self.T,
                source=source,
                scan_run_id=scan_id,
                item=item,
                normalized=normalized,
                detail_text=detail_text,
                structured=structured,
            )
        return out.opportunity_id, out.created, out.changed_fields

    # ------------------------------------------------------------- finalize
    def _matches_filters(self, opp: dict[str, Any], category_code: str | None, f: dict[str, Any]) -> bool:
        cats = f.get("categories") or []
        if cats and category_code and not any(
            category_code == c or category_code.split(".")[0] == c.split(".")[0] for c in cats
        ):
            return False
        countries = f.get("countries") or []
        if (
            countries
            and opp.get("country_code")
            and opp["country_code"] not in countries
            and opp.get("work_mode") != "remote"
        ):
            regions = json.loads(opp["eligible_regions"]) if opp.get("eligible_regions") else []
            if not set(regions) & set(countries):
                return False
        if f.get("work_mode") and opp.get("work_mode") not in (None, "unspecified", f["work_mode"]):
            return False
        if not f.get("include_expired") and opp.get("deadline_on") and opp["deadline_on"] < today_iso():
            return False
        if f.get("deadline_before") and opp.get("deadline_on") and opp["deadline_on"] > f["deadline_before"]:
            return False
        if f.get("amount_min") and opp.get("amount_currency") == f.get("amount_currency"):
            factor = 1 if opp["amount_currency"] in ("XAF", "XOF") else 100
            top = opp.get("amount_max_minor") or opp.get("amount_min_minor") or 0
            if top and top < int(f["amount_min"]) * factor:
                return False
        return True

    def _finalize(self, run_id: str, filters: dict[str, Any], found: dict[str, bool], failed: int, total: int) -> int:
        T = self.T
        ids = list(found)
        with self.active.db.read() as conn:
            ids += [i for i in self._fts_ids(conn, filters) if i not in found]
            rows = {
                r["id"]: dict(r)
                for r in conn.execute(select(T.opportunities).where(T.opportunities.c.id.in_(ids))).mappings()
            }
            codes = dict(conn.execute(select(T.opportunity_categories.c.id, T.opportunity_categories.c.code)).all())
            previously = set(
                conn.execute(
                    select(T.search_results.c.opportunity_id)
                    .join(T.search_runs, T.search_runs.c.id == T.search_results.c.search_run_id)
                    .where(T.search_runs.c.user_id == self.uid, T.search_runs.c.id != run_id)
                ).scalars()
            )
        kept = [
            oid
            for oid in ids
            if oid in rows and self._matches_filters(rows[oid], codes.get(rows[oid].get("category_id")), filters)
        ]
        scores = MatchingService(self.active).score_many(kept)
        ranked = sorted(
            kept, key=lambda o: (-(scores.get(o, {}).get("score") or 0), rows[o].get("deadline_on") or "9999")
        )
        status = "completed" if failed == 0 else ("failed" if failed >= total and total else "partial")
        with self.active.db.tx() as conn:
            conn.execute(delete(T.search_results).where(T.search_results.c.search_run_id == run_id))
            for rank, oid in enumerate(ranked, start=1):
                conn.execute(
                    insert(T.search_results).values(
                        search_run_id=run_id, opportunity_id=oid, rank=rank, is_new=0 if oid in previously else 1
                    )
                )
            conn.execute(
                update(T.search_runs)
                .where(T.search_runs.c.id == run_id)
                .values(
                    status=status,
                    results_count=len(ranked),
                    finished_at=now_iso(),
                    new_count=sum(1 for o in ranked if o not in previously),
                    error_summary=f"{failed} source(s) unavailable" if failed else None,
                )
            )
        self.state.events.publish("search.completed", {"run_id": run_id, "status": status, "results": len(ranked)})
        return len(ranked)

    def _fts_ids(self, conn: Connection, filters: dict[str, Any], limit: int = 200) -> list[str]:
        """Local full-text matches among already-collected opportunities (EF-04.08)."""
        words = [w for w in (filters.get("keywords") or []) if len(w) > 2][:8]
        if not words:
            return []
        expr = " OR ".join(f'"{w.replace(chr(34), "")}"*' for w in words)
        return list(
            conn.execute(
                text(
                    "SELECT o.id FROM opportunities_fts f JOIN opportunities o ON o.rowid = f.rowid "
                    "WHERE opportunities_fts MATCH :q ORDER BY rank LIMIT :n"
                ),
                {"q": expr, "n": limit},
            ).scalars()
        )

    def expire_overdue(self, conn: Connection) -> int:
        """EF-09.07: mark opportunities whose deadline has passed as expired."""
        T = self.T
        result = conn.execute(
            update(T.opportunities)
            .where(
                T.opportunities.c.deadline_on < today_iso(),
                T.opportunities.c.verification_status.in_(("unverified", "verified", "modified")),
            )
            .values(verification_status="expired")
        )
        return int(result.rowcount or 0)

    # ------------------------------------------------------- run management
    def get_run(self, run_id: str) -> dict[str, Any]:
        T = self.T
        with self.active.db.read() as conn:
            run = (
                conn.execute(
                    select(T.search_runs).where(T.search_runs.c.id == run_id, T.search_runs.c.user_id == self.uid)
                )
                .mappings()
                .first()
            )
            if run is None:
                raise NotFound("run not found", code="run_not_found")
            query = (
                conn.execute(select(T.search_queries).where(T.search_queries.c.id == run["query_id"])).mappings().one()
            )
            per_source = [
                dict(r)
                for r in conn.execute(
                    select(
                        T.search_run_sources.c.source_id,
                        T.search_run_sources.c.status,
                        T.search_run_sources.c.message,
                        T.sources.c.name,
                        T.sources.c.official_search_url,
                        T.sources.c.base_url,
                    )
                    .join(T.sources, T.sources.c.id == T.search_run_sources.c.source_id)
                    .where(T.search_run_sources.c.search_run_id == run_id)
                ).mappings()
            ]
            manual = [
                dict(r)
                for r in conn.execute(
                    select(
                        T.sources.c.id, T.sources.c.name, T.sources.c.official_search_url, T.sources.c.base_url
                    ).where(
                        or_(T.sources.c.access_method == "manual_link", T.sources.c.enabled == 0),
                        T.sources.c.official_search_url.is_not(None),
                    )
                ).mappings()
            ]
        cats = [c.split(".")[0] for c in json.loads(query["final_filters"]).get("categories") or []]
        return {
            "run": dict(run),
            "query": {"id": query["id"], "raw_text": query["raw_text"], "filters": json.loads(query["final_filters"])},
            "sources": per_source,
            "official_links": self._relevant_links(manual, cats),
        }

    def _relevant_links(self, manual: list[dict[str, Any]], cats: list[str]) -> list[dict[str, Any]]:
        T = self.T
        if not cats:
            return manual[:12]
        with self.active.db.read() as conn:
            by_source: dict[str, set[str]] = {}
            for sid, code in conn.execute(
                select(T.source_categories.c.source_id, T.opportunity_categories.c.code).join(
                    T.opportunity_categories, T.opportunity_categories.c.id == T.source_categories.c.category_id
                )
            ):
                by_source.setdefault(sid, set()).add(code.split(".")[0])
        return [m for m in manual if by_source.get(m["id"], set()) & set(cats)][:12]

    def cancel(self, run_id: str) -> None:
        run = self.get_run(run_id)["run"]
        if run["status"] not in ("queued", "running"):
            raise Conflict("run already finished", code="run_finished")
        if run.get("job_id") and self.state.jobs:
            self.state.jobs.cancel(self.active, run["job_id"])
        with self.active.db.tx() as conn:
            conn.execute(
                update(self.T.search_runs)
                .where(self.T.search_runs.c.id == run_id)
                .values(status="cancelled", finished_at=now_iso())
            )

    def resumable(self, run_id: str) -> tuple[str, dict[str, Any] | None]:
        T = self.T
        with self.active.db.read() as conn:
            run = (
                conn.execute(
                    select(T.search_runs).where(T.search_runs.c.id == run_id, T.search_runs.c.user_id == self.uid)
                )
                .mappings()
                .first()
            )
            if run is None:
                raise NotFound("run not found", code="run_not_found")
            if run["status"] not in ("cancelled", "running", "queued") or not run["job_id"]:
                raise Conflict("run cannot be resumed", code="run_not_resumable")
            job = (
                conn.execute(select(T.background_jobs).where(T.background_jobs.c.id == run["job_id"]))
                .mappings()
                .first()
            )
        checkpoint = json.loads(job["checkpoint"]) if job and job["checkpoint"] else None
        return run["job_id"], checkpoint

    # -------------------------------------------------------------- results
    def results(
        self,
        run_id: str,
        *,
        sort: str = "relevance",
        cursor: str | None = None,
        limit: int = 30,
        min_score: int | None = None,
        badge: str | None = None,
    ) -> dict[str, Any]:
        if sort not in SORTS:
            raise ValidationFailed("unknown sort", code="sort_invalid")
        T = self.T
        offset = _decode_cursor(cursor)
        with self.active.db.read() as conn:
            if (
                conn.execute(
                    select(T.search_runs.c.id).where(T.search_runs.c.id == run_id, T.search_runs.c.user_id == self.uid)
                ).first()
                is None
            ):
                raise NotFound("run not found", code="run_not_found")
            rows = [
                dict(r)
                for r in conn.execute(
                    select(T.opportunities, T.search_results.c.rank, T.search_results.c.is_new)
                    .join(T.search_results, T.search_results.c.opportunity_id == T.opportunities.c.id)
                    .where(T.search_results.c.search_run_id == run_id)
                ).mappings()
            ]
            saved = set(
                conn.execute(
                    select(T.saved_opportunities.c.opportunity_id).where(T.saved_opportunities.c.user_id == self.uid)
                ).scalars()
            )
            dismissed = set(
                conn.execute(
                    select(T.match_feedback.c.opportunity_id).where(
                        T.match_feedback.c.user_id == self.uid, T.match_feedback.c.feedback == "dismissed"
                    )
                ).scalars()
            )
            bonus = MatchingService(self.active).feedback_adjustments(conn)
        rows = [r for r in rows if r["id"] not in dismissed]
        scores = MatchingService(self.active).score_many([r["id"] for r in rows])
        if min_score is not None:
            rows = [r for r in rows if (scores.get(r["id"], {}).get("score") or 0) >= min_score]
        keyfuncs = {
            "relevance": lambda r: (
                -((scores.get(r["id"], {}).get("score") or 0) + bonus.get(str(r["category_id"]), 0)),
                r["rank"],
            ),
            "deadline": lambda r: (r["deadline_on"] or "9999-12-31", r["rank"]),
            "published": lambda r: (-(int((r["published_on"] or "0000-00-00").replace("-", ""))), r["rank"]),
            "amount": lambda r: (-(r["amount_max_minor"] or r["amount_min_minor"] or 0), r["rank"]),
            "recent": lambda r: (r["first_seen_at"], r["rank"]),
        }
        rows.sort(key=keyfuncs[sort])
        if sort == "recent":
            rows.reverse()
        with self.active.db.read() as conn:
            cards = [card(conn, T, r, scores.get(r["id"]), saved) | {"is_new": bool(r["is_new"])} for r in rows]
        if badge:
            cards = [c for c in cards if badge in c["badges"]]
        page = cards[offset : offset + limit]
        next_offset = offset + limit
        return {
            "items": page,
            "total": len(cards),
            "next_cursor": _encode_cursor(next_offset) if next_offset < len(cards) else None,
        }

    # -------------------------------------------------------- local search
    def local_search(self, q: str, *, limit: int = 30, cursor: str | None = None) -> dict[str, Any]:
        T = self.T
        offset = _decode_cursor(cursor)
        words = [w for w in fold(q).replace('"', " ").split() if len(w) > 1][:10]
        if not words:
            return {"items": [], "total": 0, "next_cursor": None}
        expr = " AND ".join(f'"{w}"*' for w in words)
        with self.active.db.read() as conn:
            total = conn.execute(
                text("SELECT count(*) FROM opportunities_fts WHERE opportunities_fts MATCH :q"), {"q": expr}
            ).scalar()
            ids = list(
                conn.execute(
                    text(
                        "SELECT o.id FROM opportunities_fts f JOIN opportunities o ON o.rowid = f.rowid "
                        "WHERE opportunities_fts MATCH :q ORDER BY rank LIMIT :n OFFSET :o"
                    ),
                    {"q": expr, "n": limit, "o": offset},
                ).scalars()
            )
            rows = {
                r["id"]: dict(r)
                for r in conn.execute(select(T.opportunities).where(T.opportunities.c.id.in_(ids))).mappings()
            }
            saved = set(
                conn.execute(
                    select(T.saved_opportunities.c.opportunity_id).where(T.saved_opportunities.c.user_id == self.uid)
                ).scalars()
            )
        scores = MatchingService(self.active).score_many(ids)
        with self.active.db.read() as conn:
            items = [card(conn, T, rows[i], scores.get(i), saved) for i in ids if i in rows]
        nxt = offset + limit
        return {
            "items": items,
            "total": int(total or 0),
            "next_cursor": _encode_cursor(nxt) if nxt < (total or 0) else None,
        }

    # --------------------------------------------- history & saved queries
    def history(self, limit: int = 50, saved_only: bool = False) -> list[dict[str, Any]]:
        T = self.T
        stmt = (
            select(
                T.search_queries.c.id,
                T.search_queries.c.raw_text,
                T.search_queries.c.is_saved,
                T.search_queries.c.saved_name,
                T.search_queries.c.created_at,
                T.search_queries.c.workspace_id,
                func.max(T.search_runs.c.created_at).label("last_run_at"),
                func.count(T.search_runs.c.id).label("runs"),
            )
            .join(T.search_runs, T.search_runs.c.query_id == T.search_queries.c.id, isouter=True)
            .where(T.search_queries.c.user_id == self.uid)
            .group_by(T.search_queries.c.id)
            .order_by(desc("last_run_at"))
            .limit(limit)
        )
        if saved_only:
            stmt = stmt.where(T.search_queries.c.is_saved == 1)
        with self.active.db.read() as conn:
            rows = [dict(r) for r in conn.execute(stmt).mappings()]
            for r in rows:
                last = (
                    conn.execute(
                        select(T.search_runs.c.id, T.search_runs.c.status, T.search_runs.c.results_count)
                        .where(T.search_runs.c.query_id == r["id"])
                        .order_by(desc(T.search_runs.c.created_at))
                        .limit(1)
                    )
                    .mappings()
                    .first()
                )
                r["last_run"] = dict(last) if last else None
                r["is_saved"] = bool(r["is_saved"])
        return rows

    def save_query(self, query_id: str, name: str | None) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            res = conn.execute(
                update(T.search_queries)
                .where(T.search_queries.c.id == query_id, T.search_queries.c.user_id == self.uid)
                .values(is_saved=1 if name else 0, saved_name=name)
            )
            if not res.rowcount:
                raise NotFound("query not found", code="query_not_found")
        return {"id": query_id, "is_saved": bool(name), "saved_name": name}

    def query_filters(self, query_id: str) -> tuple[str, dict[str, Any], str | None]:
        T = self.T
        with self.active.db.read() as conn:
            row = (
                conn.execute(
                    select(T.search_queries).where(
                        T.search_queries.c.id == query_id, T.search_queries.c.user_id == self.uid
                    )
                )
                .mappings()
                .first()
            )
        if row is None:
            raise NotFound("query not found", code="query_not_found")
        return row["raw_text"], json.loads(row["final_filters"]), row["workspace_id"]

    def clear_history(self, keep_saved: bool = True) -> int:
        T = self.T
        with self.active.db.tx() as conn:
            stmt = delete(T.search_queries).where(T.search_queries.c.user_id == self.uid)
            if keep_saved:
                stmt = stmt.where(T.search_queries.c.is_saved == 0)
            return int(conn.execute(stmt).rowcount or 0)

    def compare(self, run_a: str, run_b: str) -> dict[str, Any]:
        """EF-15.04: new / disappeared / modified between two runs of the same query."""
        T = self.T
        with self.active.db.read() as conn:

            def ids(run_id: str) -> set[str]:
                if (
                    conn.execute(
                        select(T.search_runs.c.id).where(
                            T.search_runs.c.id == run_id, T.search_runs.c.user_id == self.uid
                        )
                    ).first()
                    is None
                ):
                    raise NotFound("run not found", code="run_not_found")
                return set(
                    conn.execute(
                        select(T.search_results.c.opportunity_id).where(T.search_results.c.search_run_id == run_id)
                    ).scalars()
                )

            a, b = ids(run_a), ids(run_b)
            b_started = conn.execute(select(T.search_runs.c.created_at).where(T.search_runs.c.id == run_a)).scalar()
            modified = set(
                conn.execute(
                    select(T.opportunity_versions.c.opportunity_id).where(
                        T.opportunity_versions.c.opportunity_id.in_(a & b),
                        T.opportunity_versions.c.detected_at >= b_started,
                    )
                ).scalars()
            )
            titles = dict(
                conn.execute(
                    select(T.opportunities.c.id, T.opportunities.c.title).where(T.opportunities.c.id.in_(a | b))
                ).all()
            )

        def lst(s: set[str]) -> list[dict[str, str]]:
            return [{"id": i, "title": titles.get(i, "")} for i in sorted(s)]

        return {"new": lst(b - a), "disappeared": lst(a - b), "modified": lst(modified)}

    def suggestions(self) -> list[str]:
        """EF-04.07: suggestions from profile objectives and past queries."""
        T = self.T
        with self.active.db.read() as conn:
            objectives = conn.execute(
                select(T.objectives.c.name_fr, T.objectives.c.name_en)
                .join(T.user_objectives, T.user_objectives.c.objective_id == T.objectives.c.id)
                .where(T.user_objectives.c.user_id == self.uid)
            ).all()
            country = conn.execute(
                select(T.countries.c.name_fr)
                .join(T.user_profiles, T.user_profiles.c.country_code == T.countries.c.code)
                .where(T.user_profiles.c.user_id == self.uid)
            ).scalar()
            recent = (
                conn.execute(
                    select(T.search_queries.c.raw_text)
                    .where(T.search_queries.c.user_id == self.uid)
                    .order_by(desc(T.search_queries.c.created_at))
                    .limit(5)
                )
                .scalars()
                .all()
            )
            skills = (
                conn.execute(
                    select(T.skills.c.name)
                    .join(T.user_skills, T.user_skills.c.skill_id == T.skills.c.id)
                    .where(T.user_skills.c.user_id == self.uid, T.user_skills.c.is_primary == 1)
                )
                .scalars()
                .all()
            )
        out: list[str] = []
        for fr, _en in objectives:
            label = fr.replace("Trouver ", "").replace("Financer ", "financement ")
            out.append(f"{label} {('au ' + country) if country else ''}".strip())
        for s in skills[:2]:
            out.append(f"emploi {s}")
        for r in recent:
            if r not in out:
                out.append(r)
        return list(dict.fromkeys(out))[:8]


def today() -> date:
    return date.today()
