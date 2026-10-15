"""Fetch and parse one source's list for a query (shared by searches, monitors and the
catalogue verification tool)."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from collection.adapters import RawItem, build_body, build_url, parse_list
from collection.http import PoliteClient
from core.text import fold


@dataclass
class ListFetch:
    url: str
    items: list[RawItem]
    from_cache: bool


async def fetch_list(client: PoliteClient, spec: dict[str, Any], query: str) -> ListFetch:
    url = build_url(spec, query)
    if str(spec.get("method", "GET")).upper() == "POST":
        result = await client.post_json(url, build_body(spec, query) or {})
    else:
        result = await client.get(url)
    return ListFetch(url=url, items=parse_list(spec, result.body, url), from_cache=result.from_cache)


def keyword_filter(items: list[RawItem], keywords: list[str], spec: dict[str, Any]) -> list[RawItem]:
    """Sources that cannot search server-side are filtered locally on title + summary.

    An item is kept when it contains at least one keyword (accent/case-insensitive).
    """
    if not keywords or spec.get("supports_query"):
        return items
    folded = [fold(k) for k in keywords if k.strip()]
    kept = []
    for it in items:
        hay = fold(f"{it.title} {it.summary} {' '.join(map(str, it.fields.values()))}")
        if any(k in hay for k in folded):
            kept.append(it)
    return kept
