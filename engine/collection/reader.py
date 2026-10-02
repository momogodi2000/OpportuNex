"""
Collection pipeline — fetches, parses, and normalizes opportunity data
from configured sources using declarative JSON adapters.

Priority order per ADR-007: API → RSS → JSON-LD → HTML → headless
"""

from __future__ import annotations

import asyncio
import json
import re
from datetime import datetime, timedelta
from typing import Any, Optional
from urllib.parse import urljoin

import feedparser
import structlog
from selectolax.parser import HTMLParser
import dateparser

from collection.safe_http import SafeHTTPClient
from domain.entities.entities import Source

log = structlog.get_logger(__name__)

# Maximum concurrent requests globally and per domain
_GLOBAL_SEMAPHORE = asyncio.Semaphore(8)
_DOMAIN_SEMAPHORE: dict[str, asyncio.Semaphore] = {}
_MIN_DELAY_SECONDS = 2.0


def _domain_from_url(url: str) -> str:
    from urllib.parse import urlparse
    return urlparse(url).netloc.lower()


async def _domain_delay(domain: str) -> None:
    """Ensure minimum 2s between requests to the same domain."""
    if domain not in _DOMAIN_SEMAPHORE:
        _DOMAIN_SEMAPHORE[domain] = asyncio.Semaphore(1)
    async with _DOMAIN_SEMAPHORE[domain]:
        await asyncio.sleep(_MIN_DELAY_SECONDS)


class RawDocument:
    """Raw data returned by a collector before normalization."""

    def __init__(
        self,
        url: str,
        title: str,
        content: Optional[str],
        organization: Optional[str],
        deadline_raw: Optional[str],
        external_id: Optional[str],
        source_id: str,
        metadata: dict,
    ) -> None:
        self.url = url
        self.title = title
        self.content = content
        self.organization = organization
        self.deadline_raw = deadline_raw
        self.external_id = external_id
        self.source_id = source_id
        self.metadata = metadata
        self.collected_at = datetime.utcnow()


class AdapterConfig:
    """Parsed declarative adapter JSON."""

    def __init__(self, data: dict) -> None:
        self.access_method: str = data["access_method"]
        self.endpoint_url: str = data.get("endpoint_url", "")
        self.list_selector: str = data.get("list_selector", "")
        self.title_selector: str = data.get("title_selector", "")
        self.deadline_selector: str = data.get("deadline_selector", "")
        self.link_selector: str = data.get("link_selector", "a[href]")
        self.org_selector: str = data.get("org_selector", "")
        self.external_id_pattern: str = data.get("external_id_pattern", "")
        self.pagination: dict = data.get("pagination", {})
        self.headers: dict = data.get("headers", {})
        self.params: dict = data.get("params", {})
        self.rss_title_field: str = data.get("rss_title_field", "title")
        self.rss_link_field: str = data.get("rss_link_field", "link")
        self.rss_date_field: str = data.get("rss_date_field", "published")


class CollectionReader:
    """
    Dispatches to the appropriate reader based on the adapter's access_method.
    """

    def __init__(self, http: SafeHTTPClient) -> None:
        self._http = http

    async def fetch(
        self, source: Source, adapter: AdapterConfig
    ) -> list[RawDocument]:
        """Fetch raw documents from a source using its adapter."""
        method = adapter.access_method
        domain = _domain_from_url(source.base_url)

        async with _GLOBAL_SEMAPHORE:
            await _domain_delay(domain)
            try:
                if method == "rss":
                    return await self._fetch_rss(source, adapter)
                elif method == "api":
                    return await self._fetch_api(source, adapter)
                elif method == "html":
                    return await self._fetch_html(source, adapter)
                elif method == "jsonld":
                    return await self._fetch_jsonld(source, adapter)
                else:
                    log.warning("unsupported_access_method", method=method, source=source.name)
                    return []
            except Exception as e:
                log.error("collection_error", source=source.name, error=str(e))
                return []

    async def _fetch_rss(
        self, source: Source, adapter: AdapterConfig
    ) -> list[RawDocument]:
        """Fetch and parse an RSS/Atom feed."""
        url = adapter.endpoint_url or source.base_url
        resp = await self._http.get(url)
        feed = feedparser.parse(resp.text)
        docs: list[RawDocument] = []

        for entry in feed.entries[:100]:  # Limit to avoid memory issues
            title = entry.get(adapter.rss_title_field, "").strip()
            link = entry.get(adapter.rss_link_field, "")
            date_raw = entry.get(adapter.rss_date_field, "")
            content = entry.get("summary", "") or entry.get("description", "")

            if not title or not link:
                continue

            docs.append(RawDocument(
                url=link,
                title=title,
                content=self._sanitize_html(content),
                organization=entry.get("author", None),
                deadline_raw=date_raw or None,
                external_id=entry.get("id", None),
                source_id=str(source.id),
                metadata={"feed_url": url},
            ))

        log.debug("rss_fetched", source=source.name, count=len(docs))
        return docs

    async def _fetch_api(
        self, source: Source, adapter: AdapterConfig
    ) -> list[RawDocument]:
        """Fetch from a JSON API endpoint."""
        url = adapter.endpoint_url
        resp = await self._http.get(url, params=adapter.params, headers=adapter.headers)

        try:
            data = resp.json()
        except Exception:
            log.warning("api_invalid_json", source=source.name, url=url)
            return []

        # Handle both list and object with 'results' key
        if isinstance(data, list):
            items = data
        elif isinstance(data, dict):
            for key in ("results", "data", "items", "opportunities", "grants"):
                if key in data and isinstance(data[key], list):
                    items = data[key]
                    break
            else:
                items = [data]
        else:
            return []

        docs: list[RawDocument] = []
        for item in items[:200]:
            if not isinstance(item, dict):
                continue

            title = self._extract_field(item, ["title", "name", "titre", "denomination"])
            link = self._extract_field(item, ["url", "link", "href", "source_url"])
            if not title or not link:
                continue

            if not link.startswith("http"):
                link = urljoin(source.base_url, link)

            docs.append(RawDocument(
                url=link,
                title=title,
                content=str(item.get("description", "") or item.get("content", "") or ""),
                organization=self._extract_field(item, ["organization", "organisation", "funder", "donor"]),
                deadline_raw=self._extract_field(item, ["deadline", "closing_date", "expiry", "date_limite"]),
                external_id=self._extract_field(item, ["id", "ref", "external_id", "slug"]),
                source_id=str(source.id),
                metadata={"api_url": url},
            ))

        log.debug("api_fetched", source=source.name, count=len(docs))
        return docs

    async def _fetch_html(
        self, source: Source, adapter: AdapterConfig
    ) -> list[RawDocument]:
        """Scrape opportunities from an HTML page using CSS selectors."""
        url = adapter.endpoint_url or source.base_url
        resp = await self._http.get(url)
        tree = HTMLParser(resp.text)

        # Respect robots.txt — check adapter metadata
        docs: list[RawDocument] = []

        list_items = tree.css(adapter.list_selector) if adapter.list_selector else [tree.root]

        for item in list_items[:100]:
            # Extract title
            title_node = item.css_first(adapter.title_selector) if adapter.title_selector else None
            title = (title_node.text(strip=True) if title_node else item.text(strip=True))[:500]

            # Extract link
            link_node = item.css_first(adapter.link_selector)
            link = link_node.attrs.get("href", "") if link_node else ""
            if not link:
                continue
            if not link.startswith("http"):
                link = urljoin(url, link)

            # Extract deadline
            deadline_node = item.css_first(adapter.deadline_selector) if adapter.deadline_selector else None
            deadline_raw = deadline_node.text(strip=True) if deadline_node else None

            # Extract organization
            org_node = item.css_first(adapter.org_selector) if adapter.org_selector else None
            org = org_node.text(strip=True) if org_node else None

            if not title or not link:
                continue

            docs.append(RawDocument(
                url=link,
                title=title,
                content=None,   # Fetch detail page separately if needed
                organization=org,
                deadline_raw=deadline_raw,
                external_id=None,
                source_id=str(source.id),
                metadata={"page_url": url},
            ))

        log.debug("html_fetched", source=source.name, count=len(docs))
        return docs

    async def _fetch_jsonld(
        self, source: Source, adapter: AdapterConfig
    ) -> list[RawDocument]:
        """Extract JSON-LD structured data from a web page."""
        import extruct

        url = adapter.endpoint_url or source.base_url
        resp = await self._http.get(url)

        data = extruct.extract(resp.text, base_url=url, syntaxes=["json-ld"])
        docs: list[RawDocument] = []

        for item in data.get("json-ld", []):
            schema_type = item.get("@type", "")
            if not isinstance(schema_type, str):
                continue
            if "JobPosting" not in schema_type and "Grant" not in schema_type:
                continue

            title = item.get("title") or item.get("name", "")
            link = item.get("url", url)
            org = (
                item.get("hiringOrganization", {}).get("name")
                or item.get("funder", {}).get("name")
                or None
            )
            deadline = item.get("validThrough") or item.get("applicationDeadline")

            if not title:
                continue

            docs.append(RawDocument(
                url=link,
                title=title,
                content=item.get("description", ""),
                organization=org,
                deadline_raw=str(deadline) if deadline else None,
                external_id=item.get("identifier"),
                source_id=str(source.id),
                metadata={"schema_type": schema_type},
            ))

        return docs

    @staticmethod
    def _sanitize_html(html: str) -> str:
        """Strip all HTML tags, returning plain text."""
        if not html:
            return ""
        tree = HTMLParser(html)
        # Remove script and style nodes
        for tag in tree.css("script, style"):
            tag.decompose()
        return tree.text(separator=" ", strip=True)[:10000]

    @staticmethod
    def _extract_field(item: dict, candidates: list[str]) -> Optional[str]:
        """Try multiple field name candidates; return first non-empty string."""
        for key in candidates:
            val = item.get(key)
            if val and isinstance(val, str) and val.strip():
                return val.strip()
        return None
