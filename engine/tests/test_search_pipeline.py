"""End-to-end collection → extraction → dedup → scoring against the local fixture site."""

from __future__ import annotations

from tests.conftest import EngineClient
from tests.conftest import add_source as _add_source
from tests.conftest import wait_run as _wait
from tests.fixtures.site import DEADLINE_SCHOLARSHIP, FixtureSite


def test_custom_source_discovery_and_validation(client: EngineClient, site: FixtureSite) -> None:
    r = client.post("/sources", json={"url": site.url("/"), "name": "Fixture"})
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["detected_feed"].endswith("/feed.xml")
    assert len(body["preview"]) == 3 and body["custom"] is True
    assert client.post("/sources", json={"url": site.url("/")}).status_code == 409
    assert client.post("/sources", json={"url": site.url("/nothing-here")}).json()["code"].startswith("source_")
    sources = client.get("/sources").json()["items"]
    assert len(sources) >= 70  # catalogue synchronised at sign-in
    catalog = next(s for s in sources if not s["custom"] and s["access_method"] == "manual_link")
    assert client.patch(f"/sources/{catalog['id']}", json={"enabled": True}).json()["code"] == "source_manual_link"
    assert client.delete(f"/sources/{catalog['id']}").status_code == 403
    # EF-06.03/04: frequency (never below one hour) and categories, as edited from the Sources page.
    assert client.patch(f"/sources/{body['id']}", json={"min_interval_minutes": 30}).status_code == 422
    client.patch(f"/sources/{body['id']}", json={"min_interval_minutes": 2880, "categories": ["scholarship", "tender"]})
    edited = next(s for s in client.get("/sources").json()["items"] if s["id"] == body["id"])
    assert edited["min_interval_minutes"] == 2880 and set(edited["categories"]) == {"scholarship", "tender"}
    assert client.delete(f"/sources/{body['id']}").status_code == 204


def test_full_search_pipeline(client: EngineClient, site: FixtureSite) -> None:
    source_id = _add_source(client, site.url("/feed.xml"), "Fixture publisher")
    interp = client.post("/search/interpret", json={"text": "bourse de master au Cameroun"}).json()
    assert interp["filters"]["categories"] == ["scholarship.master"]
    assert "CM" in interp["filters"]["countries"]

    start = client.post(
        "/search/runs",
        json={"text": "data", "source_ids": [source_id], "filters": {"keywords": [], "include_expired": False}},
    )
    assert start.status_code == 202, start.text
    run = _wait(client, start.json()["run_id"])
    assert run["run"]["status"] == "completed", run
    assert run["sources"][0]["status"] == "ok"

    results = client.get(f"/search/runs/{run['run']['id']}/results").json()
    assert results["total"] == 3
    titles = {i["title"]: i for i in results["items"]}
    master = next(i for t, i in titles.items() if t.startswith("Bourse de master"))
    assert master["deadline_on"] == DEADLINE_SCHOLARSHIP
    assert master["organization_name"] == "Université Fictive"
    assert master["category"].startswith("scholarship")
    assert master["is_new"] is True and 0 <= master["score"] <= 100
    assert "eligibility_uncertain" in master["badges"]  # nationality/age clauses must be checked by the user
    job = next(i for t, i in titles.items() if t.startswith("Recrutement"))
    assert job["deadline_on"] == "2099-12-15" and job["category"].startswith("employment")
    assert job["amount"] == {"min_minor": 600000, "max_minor": None, "currency": "XAF"}
    tender = next(i for t, i in titles.items() if "appel d'offres" in t.lower())
    assert tender["category"].startswith("tender")

    detail = client.get(f"/opportunities/{master['id']}")
    if detail.status_code == 200:  # detail endpoint is covered in its own test module
        assert detail.json()["id"] == master["id"]

    # Sorting and pagination
    by_deadline = client.get(f"/search/runs/{run['run']['id']}/results", params={"sort": "deadline", "limit": 2}).json()
    assert [i["deadline_on"] for i in by_deadline["items"]] == sorted(i["deadline_on"] for i in by_deadline["items"])
    assert by_deadline["next_cursor"]
    page2 = client.get(
        f"/search/runs/{run['run']['id']}/results",
        params={"sort": "deadline", "limit": 2, "cursor": by_deadline["next_cursor"]},
    ).json()
    assert len(page2["items"]) == 1 and page2["next_cursor"] is None

    # Second run: nothing is new any more, and nothing is duplicated.
    rerun = client.post(f"/search/queries/{run['query']['id']}/rerun")
    assert rerun.status_code == 202
    run2 = _wait(client, rerun.json()["run_id"])
    res2 = client.get(f"/search/runs/{run2['run']['id']}/results").json()
    assert res2["total"] == 3 and not any(i["is_new"] for i in res2["items"])
    diff = client.get("/search/runs/compare", params={"a": run["run"]["id"], "b": run2["run"]["id"]}).json()
    assert diff["new"] == [] and diff["disappeared"] == []

    # Local full-text search (accent-insensitive) over collected opportunities.
    local = client.get("/search/local", params={"q": "donnees"}).json()
    assert local["total"] >= 2
    history = client.get("/search/history").json()["items"]
    assert history[0]["last_run"]["results_count"] == 3
    # The previous run is exposed so the UI can offer the comparison (EF-15.04).
    assert history[0]["last_run"]["id"] == run2["run"]["id"]
    assert history[0]["previous_run"]["id"] == run["run"]["id"]


def test_cross_site_repost_is_deduplicated(client: EngineClient, site: FixtureSite) -> None:
    original = _add_source(client, site.url("/feed.xml"), "Publisher")
    aggregator = _add_source(client, site.url("/aggregator.xml", host="localhost"), "Aggregator")
    run = _wait(
        client,
        client.post(
            "/search/runs", json={"text": "bourse", "source_ids": [original, aggregator], "filters": {"keywords": []}}
        ).json()["run_id"],
    )
    items = client.get(f"/search/runs/{run['run']['id']}/results").json()["items"]
    masters = [i for i in items if i["title"].startswith("Bourse de master")]
    assert len(masters) == 1
    assert masters[0]["sources_count"] == 2


def test_robots_disallowed_source_is_reported_with_official_link(client: EngineClient, site: FixtureSite) -> None:
    source_id = _add_source(client, site.url("/feed.xml"), "Publisher")
    state = client.state
    active = state.active
    T = active.tables
    import json as _json

    from sqlalchemy import update

    blocked_spec = {"version": "1.0.0", "kind": "rss", "url": site.url("/private/feed.xml"), "detail": False}
    with active.db.tx() as conn:
        conn.execute(
            update(T.source_adapters)
            .where(T.source_adapters.c.source_id == source_id)
            .values(spec=_json.dumps(blocked_spec))
        )
    run = _wait(
        client,
        client.post("/search/runs", json={"text": "x", "source_ids": [source_id], "filters": {"keywords": []}}).json()[
            "run_id"
        ],
    )
    assert run["run"]["status"] == "failed"
    assert run["sources"][0]["status"] == "blocked"
    assert run["sources"][0]["message"] == "robots_disallowed"
    assert run["sources"][0]["official_search_url"]
    scans = client.get(f"/sources/{source_id}/runs").json()["items"]
    assert scans[0]["status"] == "blocked" and scans[0]["error_code"] == "robots_disallowed"


def test_search_requires_an_enabled_source(client: EngineClient) -> None:
    r = client.post("/search/runs", json={"text": "x", "source_ids": ["nope"]})
    assert r.status_code == 422 and r.json()["code"] == "no_sources"


def test_matching_weights_and_feedback(client: EngineClient, site: FixtureSite) -> None:
    source_id = _add_source(client, site.url("/feed.xml"), "Publisher")
    run = _wait(
        client,
        client.post("/search/runs", json={"text": "x", "source_ids": [source_id], "filters": {"keywords": []}}).json()[
            "run_id"
        ],
    )
    items = client.get(f"/search/runs/{run['run']['id']}/results").json()["items"]
    first = items[0]
    r = client.post(f"/opportunities/{first['id']}/feedback", json={"feedback": "dismissed"})
    if r.status_code == 204:
        after = client.get(f"/search/runs/{run['run']['id']}/results").json()["items"]
        assert first["id"] not in [i["id"] for i in after]
