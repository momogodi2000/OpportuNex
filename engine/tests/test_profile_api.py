from __future__ import annotations

from tests.conftest import EngineClient


def test_reference_data(signed_in: EngineClient) -> None:
    countries = signed_in.get("/ref/countries").json()["items"]
    assert any(c["code"] == "CM" and c["is_cemac"] for c in countries)
    cats = signed_in.get("/ref/categories").json()["items"]
    assert len(cats) == 15
    scholarship = next(c for c in cats if c["code"] == "scholarship")
    assert {c["code"] for c in scholarship["children"]} >= {"scholarship.master", "scholarship.phd"}
    assert len(signed_in.get("/ref/objectives").json()["items"]) == 16
    skills = signed_in.get("/ref/skills", params={"q": "machine"}).json()["items"]
    assert [s["name"] for s in skills] == ["Apprentissage automatique"]
    assert signed_in.get("/ref/skills", params={"q": "securite"}).json()["items"][0]["name"] == "Cybersécurité"


def test_new_profile_is_empty_with_guidance(signed_in: EngineClient) -> None:
    p = signed_in.get("/profile").json()
    assert p["general"]["full_name"] == "Awa Ndjock"
    assert p["completeness"]["percent"] == 0
    assert p["completeness"]["missing"][0] in ("identity", "education", "experience", "skills")
    assert p["onboarding_completed"] is False


def test_full_onboarding_flow_updates_completeness(signed_in: EngineClient) -> None:
    r = signed_in.put(
        "/profile/general",
        json={
            "full_name": "Awa Ndjock",
            "country_code": "CM",
            "city": "Douala",
            "professional_status": "job_seeker",
            "highest_education": "master",
            "experience_years": 3,
            "work_mode_pref": "hybrid",
            "willing_to_relocate": True,
            "current_occupation": "Analyste de données",
        },
    )
    assert r.status_code == 200, r.text
    edu = signed_in.post(
        "/profile/education",
        json={
            "level": "Master",
            "field_of_study": "Statistique appliquée",
            "institution": "Université de Yaoundé II",
            "country_code": "CM",
            "start_date": "2019-10",
            "end_date": "2021-07",
        },
    )
    assert edu.status_code == 201
    exp = signed_in.post(
        "/profile/experiences",
        json={
            "job_title": "Analyste de données",
            "employer": "ONG Santé Plus",
            "employment_type": "full_time",
            "start_date": "2021-09-01",
            "is_current": True,
        },
    )
    assert exp.status_code == 201
    signed_in.put(
        "/profile/skills",
        json=[
            {"name": "python", "level": 4, "is_primary": True},
            {"name": "SQL", "level": 4},
            {"name": "Data science"},
            {"name": "Suivi évaluation"},
            {"name": "Kobotoolbox"},
        ],
    )
    signed_in.put(
        "/profile/languages",
        json=[{"language_code": "fr", "cefr_level": "native"}, {"language_code": "en", "cefr_level": "B2"}],
    )
    signed_in.put("/profile/objectives", json={"objective_ids": [1, 4], "custom": ["Travailler dans l'humanitaire"]})
    signed_in.put("/profile/locations", json=[{"country_code": "CM"}, {"region_label": "Afrique centrale"}])
    signed_in.put("/profile/links", json=[{"kind": "github", "url": "https://github.com/awa"}])
    p = signed_in.get("/profile").json()
    assert p["completeness"]["percent"] == 100
    names = [s["name"] for s in p["skills"]]
    assert "Python" in names and "Science des données" in names and "Suivi-évaluation" in names
    assert "Kobotoolbox" in names  # unknown skills are created, never dropped
    assert {o["code"] for o in p["objectives"]["items"]} == {"find_job", "find_scholarship"}
    assert p["objectives"]["custom"][0]["label"] == "Travailler dans l'humanitaire"

    summary = signed_in.post("/profile/summary/generate", params={"lang": "fr"}).json()
    assert summary["provenance"] == "generated_from_profile"
    assert "Université de Yaoundé II" in summary["text"] and "Python" in summary["text"]
    saved = signed_in.put("/profile/summary", json={"text": summary["text"], "approved": True}).json()
    assert saved["general"]["summary_approved"] == 1
    done = signed_in.post("/profile/onboarding/complete").json()
    assert done["onboarding_completed"] is True
    assert signed_in.get("/auth/me").json()["onboarding_completed"] is True


def test_profile_edits_invalidate_summary_approval(signed_in: EngineClient) -> None:
    signed_in.put("/profile/summary", json={"text": "Résumé", "approved": True})
    signed_in.put("/profile/general", json={"city": "Yaoundé"})
    assert signed_in.get("/profile").json()["general"]["summary_approved"] == 0


def test_validation_and_ownership(signed_in: EngineClient) -> None:
    assert signed_in.put("/profile/general", json={"country_code": "Cameroun"}).status_code == 422
    assert signed_in.put("/profile/general", json={"professional_status": "astronaut"}).status_code == 422
    bad_period = signed_in.post(
        "/profile/experiences",
        json={"job_title": "x", "employer": "y", "start_date": "2022-01-01", "end_date": "2021-01-01"},
    )
    assert bad_period.status_code == 422
    assert signed_in.put("/profile/links", json=[{"kind": "website", "url": "javascript:alert(1)"}]).status_code == 422
    assert signed_in.put("/profile/languages", json=[{"language_code": "xx", "cefr_level": "B2"}]).status_code == 422
    assert signed_in.put("/profile/objectives", json={"objective_ids": [999]}).status_code == 422
    assert (
        signed_in.put(
            "/profile/education/not-mine", json={"level": "x", "field_of_study": "y", "institution": "z"}
        ).status_code
        == 404
    )
    assert signed_in.delete("/profile/certifications/not-mine").status_code == 404


def test_update_and_delete_items(signed_in: EngineClient) -> None:
    cert = signed_in.post("/profile/certifications", json={"name": "PMP", "issuer": "PMI"}).json()
    upd = signed_in.put(
        f"/profile/certifications/{cert['id']}", json={"name": "PMP", "issuer": "PMI", "obtained_on": "2024-05-01"}
    )
    assert upd.json()["obtained_on"] == "2024-05-01"
    assert signed_in.delete(f"/profile/certifications/{cert['id']}").status_code == 204
    assert signed_in.get("/profile").json()["certifications"] == []


def test_organization_profile(signed_in: EngineClient) -> None:
    r = signed_in.put(
        "/profile/organization",
        json={
            "name": "Association Jeunesse Active",
            "org_type": "association",
            "country_code": "CM",
            "sector": "Éducation",
            "annual_budget_band": "10m_50m_xaf",
        },
    )
    assert r.status_code == 200
    assert r.json()["organization"]["name"] == "Association Jeunesse Active"
    r2 = signed_in.put("/profile/organization", json={"name": "AJA", "org_type": "ngo"})
    assert r2.json()["organization"]["name"] == "AJA"
    assert signed_in.delete("/profile/organization").json()["organization"] is None


def test_project_profile_funding_range(signed_in: EngineClient) -> None:
    bad = signed_in.post("/profile/projects", json={"title": "Ferme", "funding_min_minor": 10, "funding_max_minor": 5})
    assert bad.status_code == 422
    ok = signed_in.post(
        "/profile/projects",
        json={
            "title": "Ferme avicole",
            "stage": "prototype",
            "funding_min_minor": 5_000_000,
            "funding_max_minor": 15_000_000,
            "currency_code": "XAF",
            "operating_country": "CM",
        },
    )
    assert ok.status_code == 201
