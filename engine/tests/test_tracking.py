from __future__ import annotations

from typing import Any

from tests.conftest import EngineClient, collect
from tests.fixtures.site import DEADLINE_SCHOLARSHIP, DETAIL_1, FixtureSite


def _master(items: list[dict[str, Any]]) -> dict[str, Any]:
    return next(i for i in items if i["title"].startswith("Bourse de master"))


def test_opportunity_sheet_has_13_sections_with_provenance(client: EngineClient, site: FixtureSite) -> None:
    opp = _master(collect(client, site))
    d = client.get(f"/opportunities/{opp['id']}").json()
    for section in (
        "overview",
        "publisher",
        "eligibility",
        "qualifications",
        "documents_required",
        "deadline",
        "financial",
        "procedure",
        "official_link",
        "verification",
        "relevance",
        "eligibility_gaps",
        "checklist",
    ):
        assert section in d, section
    assert d["deadline"]["raw"] == "2099-11-30"
    assert d["fields"]["deadline_on"]["provenance"] == "explicit"
    assert d["fields"]["deadline_on"]["extracted_by"] == "structured_data"
    assert any("ressortissant" in c for c in d["eligibility"]["clauses"])  # verbatim clause kept
    assert any("ressortissant" in t for t in d["eligibility_gaps"]["to_verify"])
    labels = [x["label"].lower() for x in d["documents_required"]]
    assert any("cv" in lab for lab in labels) and any("lettre de motivation" in lab for lab in labels)
    assert {r["label"] for r in d["qualifications"]["skill"]} >= {"Python", "SQL"}
    assert d["relevance"]["breakdown"]["skills"]["score"] > 0.5
    assert d["financial"]["currency"] == "XAF"
    assert d["publisher"]["sources"][0]["url"].endswith("/opp/1.html?utm_source=rss")
    assert d["submission_notice"] == "official_channel_only"
    assert client.get("/opportunities/does-not-exist").status_code == 404


def test_recheck_marks_verified(client: EngineClient, site: FixtureSite) -> None:
    opp = _master(collect(client, site))
    r = client.post(f"/opportunities/{opp['id']}/recheck").json()
    assert r["status"] in ("verified", "modified")
    assert "verified" in client.get(f"/opportunities/{opp['id']}").json()["badges"] or r["status"] == "modified"


def test_change_on_tracked_opportunity_notifies_per_preferences(client: EngineClient, site: FixtureSite) -> None:
    opp = _master(collect(client, site))
    saved = client.post("/saved", json={"opportunity_id": opp["id"]}).json()

    site.overrides["/opp/1.html"] = DETAIL_1.replace(DEADLINE_SCHOLARSHIP, "2099-12-31").replace(
        "30 novembre 2099", "31 décembre 2099"
    )
    assert client.post(f"/opportunities/{opp['id']}/recheck").json()["status"] == "modified"
    notes = [n for n in client.get("/notifications").json()["items"] if n["kind"] == "opportunity_changed"]
    # Regression: the notice used to bypass preferences and carry no deep link to the saved item.
    assert len(notes) == 1 and notes[0]["title"]
    assert notes[0]["payload"]["saved_id"] == saved["id"]

    assert client.put("/notifications/preferences/opportunity_changed", json={"enabled": False}).status_code == 204
    site.overrides["/opp/1.html"] = DETAIL_1.replace(DEADLINE_SCHOLARSHIP, "2099-10-31").replace(
        "30 novembre 2099", "31 octobre 2099"
    )
    assert client.post(f"/opportunities/{opp['id']}/recheck").json()["status"] == "modified"
    notes = [n for n in client.get("/notifications").json()["items"] if n["kind"] == "opportunity_changed"]
    assert len(notes) == 1


def test_save_creates_application_checklist_and_reminders(client: EngineClient, site: FixtureSite) -> None:
    opp = _master(collect(client, site))
    saved = client.post("/saved", json={"opportunity_id": opp["id"], "priority": "high"})
    assert saved.status_code == 201, saved.text
    s = saved.json()
    assert s["application"]["status"] == "discovered"
    assert s["checklist_progress"]["total"] >= 3
    assert client.post("/saved", json={"opportunity_id": opp["id"]}).status_code == 409
    # Regression: the sheet of an already-saved opportunity lists its checklist (row mapping bug).
    sheet = client.get(f"/opportunities/{opp['id']}").json()
    assert sheet["saved_id"] == s["id"] and len(sheet["checklist"]) >= 3
    app = client.get(f"/applications/{s['application']['id']}").json()
    assert sorted(r["offset_days"] for r in app["reminders"]) == [1, 3, 7, 14]
    assert app["history"][0]["to_status"] == "discovered"

    # Ineligible requires a reason (EF-12.03)
    assert client.patch(f"/saved/{s['id']}", json={"interest": "ineligible"}).status_code == 422
    client.patch(f"/saved/{s['id']}", json={"interest": "undecided", "personal_deadline": "2099-11-20"})
    client.put(f"/saved/{s['id']}/tags", json={"names": ["prioritaire", "master"]})
    client.post(f"/saved/{s['id']}/notes", json={"body": "Demander une lettre au Pr. X"})
    lst = client.get("/saved", params={"tag": "master"}).json()["items"]
    assert [i["id"] for i in lst] == [s["id"]]
    assert client.get("/saved", params={"q": "fictive"}).json()["items"][0]["id"] == s["id"]
    assert client.get("/saved", params={"q": "inexistant"}).json()["items"] == []

    # Lifecycle with history; 'submitted' requires a date given by the user (EF-10.12)
    aid = s["application"]["id"]
    assert client.post(f"/applications/{aid}/status", json={"status": "accepted"}).status_code == 409
    client.post(f"/applications/{aid}/status", json={"status": "preparing", "note": "CV à jour"})
    assert client.post(f"/applications/{aid}/status", json={"status": "submitted"}).status_code == 422
    r = client.post(
        f"/applications/{aid}/status",
        json={"status": "submitted", "submitted_on": "2099-11-01", "submission_ref": "DOS-42"},
    )
    app = r.json()
    assert [h["to_status"] for h in app["history"]] == ["discovered", "preparing", "submitted"]
    assert app["history"][1]["note"] == "CV à jour"
    ev = client.post(
        f"/applications/{aid}/events",
        json={"event_type": "interview", "title": "Entretien", "scheduled_at": "2099-11-10T09:00:00Z"},
    ).json()
    assert ev["events"][0]["title"] == "Entretien"
    board = client.get("/applications/board").json()
    submitted = next(c for c in board["columns"] if c["status"] == "submitted")
    assert submitted["items"][0]["id"] == s["id"]
    cal = client.get("/applications/calendar", params={"start": "2099-11-01", "end": "2099-11-30"}).json()["items"]
    assert {c["type"] for c in cal} >= {"deadline", "personal_deadline", "interview"}
    ics = client.get("/applications/calendar.ics")
    assert ics.text.startswith("BEGIN:VCALENDAR") and "Entretien" in ics.text


def test_encrypted_attachments_tick_checklist(client: EngineClient, site: FixtureSite) -> None:
    opp = _master(collect(client, site))
    s = client.post("/saved", json={"opportunity_id": opp["id"]}).json()
    item = client.get(f"/saved/{s['id']}/checklist").json()["items"][0]
    up = client.post(
        f"/saved/{s['id']}/documents",
        files={"file": ("cv.pdf", b"%PDF-1.4 my cv")},
        data={"label": "CV", "checklist_item_id": str(item["id"])},
    )
    assert up.status_code == 201, up.text
    doc_id = up.json()["id"]
    assert client.get(f"/saved/{s['id']}/checklist").json()["items"][0]["is_done"] is True
    dl = client.get(f"/saved/{s['id']}/documents/{doc_id}")
    assert dl.content == b"%PDF-1.4 my cv"
    vault_files = list(client.state.paths.profile_vault(client.state.active.user_id).rglob("*.bin"))
    assert vault_files and b"my cv" not in vault_files[0].read_bytes()
    assert client.delete(f"/saved/{s['id']}/documents/{doc_id}").status_code == 204
    assert client.delete(f"/saved/{s['id']}").status_code == 204


def test_generated_documents_use_profile_only_and_flag_inventions(client: EngineClient, site: FixtureSite) -> None:
    client.post(
        "/profile/education",
        json={"level": "Master", "field_of_study": "Statistique", "institution": "Université de Douala"},
    )
    client.post(
        "/profile/experiences",
        json={"job_title": "Analyste", "employer": "ONG Santé Plus", "start_date": "2021-01-01", "is_current": True},
    )
    opp = _master(collect(client, site))
    s = client.post("/saved", json={"opportunity_id": opp["id"]}).json()
    doc = client.post(f"/saved/{s['id']}/generated", json={"doc_type": "cover_letter", "language": "fr"}).json()
    assert "ONG Santé Plus" in doc["content"] and "Statistique" in doc["content"]
    assert doc["versions"][0]["integrity_flags"] == []
    edited = client.post(
        f"/generated/{doc['id']}/versions",
        json={"content": doc["content"] + "\nJe suis titulaire d'un doctorat en physique."},
    ).json()
    assert edited["current_version"] == 2
    assert any(f.startswith("degree_not_in_profile") for f in edited["versions"][0]["integrity_flags"])
    for fmt, magic in (("docx", b"PK"), ("pdf", b"%PDF")):
        r = client.get(f"/generated/{doc['id']}/export", params={"format": fmt})
        assert r.status_code == 200 and r.content.startswith(magic)
    for t in (
        "scholarship_statement",
        "grant_proposal",
        "project_summary",
        "application_email",
        "cv_suggestions",
        "interview_prep",
    ):
        assert client.post(f"/saved/{s['id']}/generated", json={"doc_type": t}).status_code == 201


def test_feedback_dismiss_and_weights(client: EngineClient, site: FixtureSite) -> None:
    items = collect(client, site)
    assert client.put("/matching/weights", json={"skills": 2}).status_code == 422
    w = client.put("/matching/weights", json={"skills": 0.5, "deadline": 0}).json()
    assert w["skills"] == 0.5 and w["deadline"] == 0
    assert client.post(f"/opportunities/{items[0]['id']}/feedback", json={"feedback": "dismissed"}).status_code == 204
