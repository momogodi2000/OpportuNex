"""Declarative adapters, HTTP politeness and source reliability (EF-05.01/03/07/13, EF-06.08)."""

from __future__ import annotations

import json
from typing import Any

import pytest

from collection.adapters import AdapterError, parse_list, validate_spec
from collection.http import FetchResult, PoliteClient
from core.version import USER_AGENT
from services.source_service import SourceService
from tests.fixtures.site import FixtureSite

API_SPEC: dict[str, Any] = {
    "kind": "json_api",
    "url": "https://api.example.org/search?q={query}",
    "items_path": "data.results",
    "url_template": "https://example.org/opp/{value}",
    "fields": {"id": "ref", "url": "ref", "title": "name", "deadline": "dates.close", "organization": "agency.name"},
}

LIST_SPEC: dict[str, Any] = {
    "kind": "html_list",
    "url": "https://portal.example.org/avis",
    "item_selector": "li.avis",
    "fields": {"title": "a", "deadline": {"selector": ".limite"}, "organization": ".org"},
}


def test_json_api_adapter_maps_declared_fields() -> None:
    validate_spec(API_SPEC)
    body = json.dumps(
        {
            "data": {
                "results": [
                    {"ref": "A-1", "name": "Grant <b>A</b>", "dates": {"close": "2099-12-01"}, "agency": {"name": "X"}},
                    {"ref": "A-1", "name": "duplicate is dropped"},
                    {"ref": None, "name": "no url is dropped"},
                ]
            }
        }
    ).encode()
    items = parse_list(API_SPEC, body, "https://api.example.org/")
    assert len(items) == 1
    it = items[0]
    assert (it.url, it.title, it.external_id) == ("https://example.org/opp/A-1", "Grant A", "A-1")
    assert it.fields == {"deadline": "2099-12-01", "organization": "X"}
    with pytest.raises(AdapterError):
        parse_list(API_SPEC, b"{not json", "https://api.example.org/")


def test_html_list_adapter_uses_selectors_and_resolves_links() -> None:
    validate_spec(LIST_SPEC)
    html = b"""<ul>
      <li class="avis"><a href="/avis/12">Appel d'offres 12</a><span class="limite">01/12/2099</span>
          <span class="org">Minist\xc3\xa8re</span></li>
      <li class="avis"><a href="https://autre.example.org/x">Avis X</a></li>
      <li class="other"><a href="/ignored">Ignored</a></li></ul>"""
    items = parse_list(LIST_SPEC, html, "https://portal.example.org/avis")
    assert [i.url for i in items] == ["https://portal.example.org/avis/12", "https://autre.example.org/x"]
    assert items[0].fields == {"deadline": "01/12/2099", "organization": "Ministère"}


@pytest.mark.parametrize(
    "spec",
    [
        {"kind": "scraper", "url": "https://x.org"},
        {"kind": "rss", "url": "file:///etc/passwd"},
        {"kind": "json_api", "url": "https://x.org"},
        {"kind": "html_list", "url": "https://x.org"},
    ],
)
def test_invalid_adapter_specs_are_rejected(spec: dict[str, Any]) -> None:
    with pytest.raises(AdapterError):
        validate_spec(spec)


async def test_explicit_user_agent_and_conditional_requests(site: FixtureSite) -> None:
    store: dict[str, dict[str, Any]] = {}

    def put(url: str, r: FetchResult) -> None:
        store[url] = {"etag": r.etag, "last_modified": r.last_modified, "body": r.body, "content_type": r.content_type}

    async with PoliteClient(allow_private=True, cache_get=store.get, cache_put=put) as client:
        first = await client.get(site.url("/etag.xml"))
        second = await client.get(site.url("/etag.xml"))
    assert not first.from_cache and second.from_cache and second.body == first.body
    requests = [h for path, h in site.seen if path == "/etag.xml"]
    assert requests[1].get("If-None-Match") == '"v1"'
    # Every request, robots.txt included, names the project (EF-05.07).
    assert all(h.get("User-Agent") == USER_AGENT for _p, h in site.seen)
    assert "opportunex" in USER_AGENT.lower() and "http" in USER_AGENT


def test_reliability_score_rewards_success_and_official_origin() -> None:
    ok = SourceService._reliability({"is_official": 1, "last_status": "ok", "consecutive_failures": 0})
    failing = SourceService._reliability({"is_official": 0, "last_status": "failed", "consecutive_failures": 3})
    link = SourceService._reliability({"is_official": 1, "access_method": "manual_link", "consecutive_failures": 9})
    assert ok == pytest.approx(0.9) and failing == pytest.approx(0.2) and link == pytest.approx(0.7)
