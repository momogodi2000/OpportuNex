"""Source management (M06): catalogue, health, reliability, custom sources with discovery."""

from __future__ import annotations

import hashlib
import json
from typing import Any
from urllib.parse import urljoin, urlsplit

from selectolax.parser import HTMLParser
from sqlalchemy import and_, delete, func, insert, or_, select, update

from collection.adapters import AdapterError, parse_list
from collection.catalog import sync_catalog
from collection.http import FetchError, PoliteClient
from core.errors import Conflict, Forbidden, NotFound, ValidationFailed
from core.ids import uuid7
from core.timeutil import now_iso
from services.state import ActiveProfile, EngineState

FEED_TYPES = ("application/rss+xml", "application/atom+xml", "application/feed+json")
COMMON_FEED_PATHS = ("/feed/", "/rss.xml", "/feed.xml", "/atom.xml", "/rss", "/index.xml")


class SourceService:
    def __init__(self, active: ActiveProfile, state: EngineState) -> None:
        self.active = active
        self.state = state
        self.T = active.tables
        self.uid = active.user_id

    def sync(self) -> dict[str, int]:
        with self.active.db.tx() as conn:
            return sync_catalog(conn, self.T)

    def list_items(self, *, category: str | None = None, q: str | None = None) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.read() as conn:
            stmt = (
                select(T.sources, func.count(T.opportunity_sources.c.opportunity_id).label("opportunities_count"))
                .join(T.opportunity_sources, T.opportunity_sources.c.source_id == T.sources.c.id, isouter=True)
                .where(or_(T.sources.c.owner_user_id.is_(None), T.sources.c.owner_user_id == self.uid))
                .group_by(T.sources.c.id)
                .order_by(T.sources.c.enabled.desc(), T.sources.c.name)
            )
            rows = [dict(r) for r in conn.execute(stmt).mappings()]
            cats: dict[str, list[str]] = {}
            for sid, code in conn.execute(
                select(T.source_categories.c.source_id, T.opportunity_categories.c.code).join(
                    T.opportunity_categories, T.opportunity_categories.c.id == T.source_categories.c.category_id
                )
            ):
                cats.setdefault(sid, []).append(code)
        out = []
        for r in rows:
            r["categories"] = cats.get(r["id"], [])
            r["custom"] = r["owner_user_id"] is not None
            r["reliability_score"] = round(self._reliability(r), 2)
            for k in ("enabled", "is_official"):
                r[k] = bool(r[k])
            r.pop("owner_user_id", None)
            if category and not any(c.split(".")[0] == category for c in r["categories"]):
                continue
            if q and q.lower() not in f"{r['name']} {r['domain']}".lower():
                continue
            out.append(r)
        return out

    @staticmethod
    def _reliability(r: dict[str, Any]) -> float:
        """EF-06.08: success history, freshness and official origin."""
        base = 0.5
        if r.get("is_official"):
            base += 0.2
        if r.get("last_status") == "ok":
            base += 0.2
        failures = int(r.get("consecutive_failures") or 0)
        base -= min(0.4, 0.1 * failures)
        if r.get("access_method") == "manual_link":
            base = 0.5 + (0.2 if r.get("is_official") else 0)
        return max(0.0, min(1.0, base))

    def _own_or_catalog(self, source_id: str) -> dict[str, Any]:
        T = self.T
        with self.active.db.read() as conn:
            row = (
                conn.execute(
                    select(T.sources).where(
                        T.sources.c.id == source_id,
                        or_(T.sources.c.owner_user_id.is_(None), T.sources.c.owner_user_id == self.uid),
                    )
                )
                .mappings()
                .first()
            )
        if row is None:
            raise NotFound("source not found", code="source_not_found")
        return dict(row)

    def update(
        self,
        source_id: str,
        *,
        enabled: bool | None,
        min_interval_minutes: int | None,
        category_codes: list[str] | None,
    ) -> dict[str, Any]:
        src = self._own_or_catalog(source_id)
        T = self.T
        values: dict[str, Any] = {}
        if enabled is not None:
            if enabled and src["access_method"] == "manual_link":
                raise ValidationFailed("official links cannot be scanned", code="source_manual_link")
            if enabled and src["allowed_status"] in ("disallowed", "excluded_by_publisher"):
                raise Forbidden("the publisher does not allow automated access", code="source_disallowed")
            values["enabled"] = 1 if enabled else 0
        if min_interval_minutes is not None:
            catalog_min = 1440 if src["owner_user_id"] is None else 60
            if min_interval_minutes < catalog_min:
                raise ValidationFailed(
                    "frequency above what the source allows",
                    code="source_frequency_too_high",
                    extra={"minimum_minutes": catalog_min},
                )
            values["min_interval_minutes"] = min_interval_minutes
        with self.active.db.tx() as conn:
            if values:
                conn.execute(update(T.sources).where(T.sources.c.id == source_id).values(**values))
            if category_codes is not None:
                if src["owner_user_id"] is None:
                    raise Forbidden("catalogue categories are fixed", code="source_catalog_readonly")
                conn.execute(delete(T.source_categories).where(T.source_categories.c.source_id == source_id))
                ids = (
                    conn.execute(
                        select(T.opportunity_categories.c.id).where(T.opportunity_categories.c.code.in_(category_codes))
                    )
                    .scalars()
                    .all()
                )
                for cid in ids:
                    conn.execute(insert(T.source_categories).values(source_id=source_id, category_id=cid))
        return next(s for s in self.list_items() if s["id"] == source_id)

    def delete(self, source_id: str) -> None:
        src = self._own_or_catalog(source_id)
        if src["owner_user_id"] is None:
            raise Forbidden("catalogue sources can be disabled, not deleted", code="source_catalog_readonly")
        with self.active.db.tx() as conn:
            conn.execute(delete(self.T.sources).where(self.T.sources.c.id == source_id))

    def runs(self, source_id: str, limit: int = 20) -> list[dict[str, Any]]:
        self._own_or_catalog(source_id)
        T = self.T
        with self.active.db.read() as conn:
            return [
                dict(r)
                for r in conn.execute(
                    select(T.source_scan_runs)
                    .where(T.source_scan_runs.c.source_id == source_id)
                    .order_by(T.source_scan_runs.c.started_at.desc())
                    .limit(limit)
                ).mappings()
            ]

    async def discover_and_add(self, url: str, name: str | None, categories: list[str]) -> dict[str, Any]:
        """EF-06.02: detect an RSS/Atom feed or schema.org data behind a public URL."""
        parts = urlsplit(url)
        if parts.scheme not in ("http", "https") or not parts.hostname:
            raise ValidationFailed("a public http(s) URL is required", code="source_url_invalid")
        async with PoliteClient(allow_private=self.state.settings.allow_private_network) as client:
            try:
                page = await client.get(url, use_cache=False)
            except FetchError as exc:
                raise ValidationFailed("the address cannot be reached", code=f"source_{exc.code}") from exc
            feed_url, items = None, []
            body = page.body.lstrip()
            if any(t in page.content_type for t in ("xml", "rss", "atom")) or body.startswith(
                (b"<?xml", b"<rss", b"<feed")
            ):
                feed_url = url
            else:
                tree = HTMLParser(page.text)
                for link in tree.css("link[rel=alternate]"):
                    if (link.attributes.get("type") or "") in FEED_TYPES and link.attributes.get("href"):
                        feed_url = urljoin(url, str(link.attributes["href"]))
                        break
                if feed_url is None:
                    for path in COMMON_FEED_PATHS:
                        candidate = urljoin(url, path)
                        try:
                            res = await client.get(candidate, use_cache=False)
                        except FetchError:
                            continue
                        if res.body.lstrip().startswith((b"<?xml", b"<rss", b"<feed")):
                            feed_url = candidate
                            break
            if feed_url is None:
                raise ValidationFailed(
                    "no RSS/Atom feed found at this address; add the feed URL directly", code="source_no_feed"
                )
            try:
                res = await client.get(feed_url, use_cache=False)
                items = parse_list({"kind": "rss", "url": feed_url}, res.body, feed_url)
            except (FetchError, AdapterError) as exc:
                raise ValidationFailed("the feed could not be read", code="source_feed_unreadable") from exc
        host = (urlsplit(feed_url).hostname or "").lower()
        source_id = uuid7()
        base_url = f"{parts.scheme}://{parts.hostname}"
        spec = {"version": "1.0.0", "kind": "rss", "url": feed_url, "detail": True, "max_items": 30}
        T = self.T
        with self.active.db.tx() as conn:
            if conn.execute(
                select(T.sources.c.id).where(T.sources.c.owner_user_id == self.uid, T.sources.c.base_url == base_url)
            ).first():
                raise Conflict("this site is already in your sources", code="source_exists")
            excluded = conn.execute(
                select(T.domain_exclusions.c.domain).where(T.domain_exclusions.c.domain == host)
            ).first()
            if excluded:
                raise Forbidden("the publisher asked to be excluded", code="source_excluded")
            conn.execute(
                insert(T.sources).values(
                    id=source_id,
                    owner_user_id=self.uid,
                    name=(name or host)[:120],
                    base_url=base_url,
                    domain=host,
                    publisher_type="other",
                    access_method="rss",
                    enabled=1,
                    allowed_status="unknown",
                    min_interval_minutes=1440,
                    official_search_url=url,
                )
            )
            conn.execute(
                insert(T.source_adapters).values(
                    id=uuid7(),
                    source_id=source_id,
                    version="1.0.0",
                    spec=json.dumps(spec),
                    spec_sha256=hashlib.sha256(json.dumps(spec).encode()).hexdigest(),
                    origin="user",
                    is_active=1,
                )
            )
            for cid in conn.execute(
                select(T.opportunity_categories.c.id).where(T.opportunity_categories.c.code.in_(categories))
            ).scalars():
                conn.execute(insert(T.source_categories).values(source_id=source_id, category_id=cid))
        result = next(s for s in self.list_items() if s["id"] == source_id)
        return result | {"detected_feed": feed_url, "preview": [{"title": i.title, "url": i.url} for i in items[:5]]}


def health_summary(active: ActiveProfile) -> dict[str, Any]:
    """EF-11.06 / EF-13.06: source health for the dashboard."""
    T = active.tables
    with active.db.read() as conn:
        rows = conn.execute(
            select(
                T.sources.c.enabled,
                T.sources.c.last_status,
                T.sources.c.consecutive_failures,
                T.sources.c.access_method,
            ).where(or_(T.sources.c.owner_user_id.is_(None), T.sources.c.owner_user_id == active.user_id))
        ).all()
        failing = [
            dict(r)
            for r in conn.execute(
                select(
                    T.sources.c.id,
                    T.sources.c.name,
                    T.sources.c.last_error,
                    T.sources.c.consecutive_failures,
                    T.sources.c.official_search_url,
                ).where(and_(T.sources.c.enabled == 1, T.sources.c.consecutive_failures >= 3))
            ).mappings()
        ]
    active_sources = [r for r in rows if r.enabled and r.access_method != "manual_link"]
    return {
        "total": len(rows),
        "active": len(active_sources),
        "healthy": sum(1 for r in active_sources if r.last_status == "ok"),
        "failing": failing,
        "never_scanned": sum(1 for r in active_sources if r.last_status is None),
        "checked_at": now_iso(),
    }
