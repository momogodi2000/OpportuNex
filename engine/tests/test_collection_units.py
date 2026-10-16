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


class _Loopback:
    """Tiny HTTP servers on 127.0.0.1-3 that record how many requests are in flight (ENF-PERF-06/07)."""

    def __init__(self, hosts: int = 3) -> None:
        import threading
        from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

        self.guard = threading.Lock()
        self.now = 0
        self.peak = 0
        self.per_host_peak: dict[str, int] = {}
        self._per_host: dict[str, int] = {}
        recorder = self

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *args: object) -> None:
                pass

            def do_GET(self) -> None:
                import time

                host = self.server.server_address[0]
                if self.path.startswith("/slow"):
                    with recorder.guard:
                        recorder.now += 1
                        recorder._per_host[host] = recorder._per_host.get(host, 0) + 1
                        recorder.peak = max(recorder.peak, recorder.now)
                        recorder.per_host_peak[host] = max(
                            recorder.per_host_peak.get(host, 0), recorder._per_host[host]
                        )
                    time.sleep(0.3)
                    with recorder.guard:
                        recorder.now -= 1
                        recorder._per_host[host] -= 1
                    body = b"ok"
                    self.send_response(200)
                    self.send_header("Content-Length", str(len(body)))
                    self.end_headers()
                    self.wfile.write(body)
                elif self.path == "/big":  # no Content-Length: the size is only known while streaming
                    self.send_response(200)
                    self.send_header("Connection", "close")
                    self.end_headers()
                    chunk = b"x" * 65536
                    try:
                        for _ in range(10 * 16 + 2):  # 10 MB + 128 KB
                            self.wfile.write(chunk)
                    except OSError:
                        pass
                elif self.path == "/declared":
                    self.send_response(200)
                    self.send_header("Content-Length", str(10 * 1024 * 1024 + 1))
                    self.end_headers()
                else:
                    self.send_response(404)
                    self.send_header("Content-Length", "0")
                    self.end_headers()

        self.servers = [ThreadingHTTPServer((f"127.0.0.{i}", 0), Handler) for i in range(1, hosts + 1)]
        for s in self.servers:
            threading.Thread(target=s.serve_forever, daemon=True).start()

    def url(self, i: int, path: str) -> str:
        host, port = self.servers[i].server_address[:2]
        return f"http://{host}:{port}{path}"

    def close(self) -> None:
        for s in self.servers:
            s.shutdown()
            s.server_close()


async def test_one_request_at_a_time_per_domain() -> None:
    import asyncio

    srv = _Loopback(hosts=1)
    try:
        async with PoliteClient(allow_private=True, min_delay=0) as client:
            await asyncio.gather(*(client.get(srv.url(0, f"/slow?{i}"), use_cache=False) for i in range(3)))
    finally:
        srv.close()
    assert srv.per_host_peak == {"127.0.0.1": 1}


async def test_global_concurrency_cap(monkeypatch: pytest.MonkeyPatch) -> None:
    import asyncio

    import collection.http as http_mod

    monkeypatch.setattr(http_mod, "MAX_CONCURRENCY", 2)
    srv = _Loopback(hosts=3)
    try:
        async with PoliteClient(allow_private=True, min_delay=0) as client:
            await asyncio.gather(*(client.get(srv.url(i, "/slow"), use_cache=False) for i in range(3)))
    finally:
        srv.close()
    assert srv.peak == 2  # three domains in parallel, but never more than the cap


async def test_responses_over_10_mb_are_refused() -> None:
    from collection.http import FetchError

    srv = _Loopback(hosts=1)
    try:
        async with PoliteClient(allow_private=True, min_delay=0) as client:
            for path in ("/big", "/declared"):
                with pytest.raises(FetchError) as err:
                    await client.get(srv.url(0, path), use_cache=False)
                assert err.value.code == "oversize_response"
    finally:
        srv.close()
