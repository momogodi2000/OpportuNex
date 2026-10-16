"""End-to-end encrypted sync (M17): real sync server on a local port, several engine instances as devices.

Covers EF-01.09/10 (online account, TOTP), EF-17.01-07 and 11-12, D-29..D-34.
"""

from __future__ import annotations

import re
import secrets
import sys
import threading
import time
from collections.abc import Iterator
from pathlib import Path
from typing import Any

import pytest
import uvicorn
from fastapi.testclient import TestClient
from sqlalchemy import select, update

from api.app import create_app as create_engine_app
from core.config import Settings
from tests.conftest import STRONG_PASSWORD, EngineClient, collect, wait_run
from tests.fixtures.site import FixtureSite

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "sync-server"))
from opx_sync.app import create_app as create_server_app
from opx_sync.config import Settings as ServerSettings
from opx_sync.security import totp_now

ONLINE_PASSWORD = "Mot-De-Passe-En-Ligne-2026!"


class SyncServer:
    def __init__(self, tmp: Path) -> None:
        self.app = create_server_app(
            ServerSettings(database_url=f"sqlite:///{tmp / 'sync.db'}", argon2_memory_kib=1024, argon2_iterations=1)
        )
        self.server = uvicorn.Server(uvicorn.Config(self.app, host="127.0.0.1", port=0, log_level="warning"))
        self.thread = threading.Thread(target=self.server.run, daemon=True)
        self.thread.start()
        while not self.server.started:
            time.sleep(0.02)
        self.url = f"http://127.0.0.1:{self.server.servers[0].sockets[0].getsockname()[1]}"

    def code(self, to: str) -> str:
        body = next(m.body for m in reversed(self.app.state.mailer.sent) if m.to == to)
        return re.search(r"Code : (\S+)", body).group(1)  # type: ignore[union-attr]

    def stored_bytes(self) -> bytes:
        from opx_sync.db import changes

        with self.app.state.engine.begin() as conn:
            return b"".join(bytes(r[0]) for r in conn.execute(select(changes.c.ciphertext)))

    def record_count(self) -> int:
        from opx_sync.db import changes

        with self.app.state.engine.begin() as conn:
            return len(conn.execute(select(changes.c.seq)).all())

    def stop(self) -> None:
        self.server.should_exit = True
        self.thread.join(timeout=5)


@pytest.fixture
def server(tmp_path: Path) -> Iterator[SyncServer]:
    s = SyncServer(tmp_path)
    yield s
    s.stop()


@pytest.fixture
def device(tmp_path: Path) -> Iterator[Any]:
    """Factory of independent desktop engines (one local profile each)."""
    opened: list[TestClient] = []

    def make(name: str, local_name: str = "Awa Ndjock") -> EngineClient:
        settings = Settings(data_dir=tmp_path / name, kdf_memory_kib=1024, kdf_iterations=1,
                            allow_private_network=True, secret_store="memory")  # fmt: skip
        token = secrets.token_urlsafe(32)
        tc = TestClient(create_engine_app(settings, token), base_url="http://127.0.0.1", raise_server_exceptions=False)
        tc.__enter__()
        opened.append(tc)
        c = EngineClient(tc, token)
        c.register(email=f"{name}@example.org", name=local_name)
        return c

    yield make
    for tc in opened:
        tc.__exit__(None, None, None)


def online(server: SyncServer, c: EngineClient, email: str, *, register: bool = True) -> dict[str, Any]:
    if register:
        r = c.post(
            "/sync/account/register", json={"server_url": server.url, "email": email, "password": ONLINE_PASSWORD}
        )
        assert r.status_code == 201, r.text
        assert (
            c.post("/sync/account/verify", json={"server_url": server.url, "code": server.code(email)}).status_code
            == 200
        )
    r = c.post("/sync/account/link", json={"server_url": server.url, "email": email, "password": ONLINE_PASSWORD,
                                           "device_name": "test"})  # fmt: skip
    assert r.status_code == 200, r.text
    return dict(r.json())


def pair(a: EngineClient, b: EngineClient) -> None:
    code = b.get("/sync/status").json()["device_code"]
    pending = next(d for d in a.get("/sync/devices").json()["items"] if d["status"] == "pending")
    assert pending["pairing_code"] == code  # both screens show the same code
    assert a.post(f"/sync/devices/{pending['id']}/approve", json={"code": code}).status_code == 200


def run(c: EngineClient) -> dict[str, Any]:
    r = c.post("/sync/run")
    assert r.status_code == 200, r.text
    return dict(r.json())


def fill_profile(c: EngineClient) -> None:
    c.put(
        "/profile/general", json={"country_code": "CM", "city": "Douala", "bio": "Analyste passionnée de statistique."}
    )
    c.put("/profile/skills", json=[{"name": "Python"}, {"name": "Power BI"}])
    c.put("/profile/languages", json=[{"language_code": "fr", "cefr_level": "native"}])
    c.post(
        "/profile/education",
        json={"level": "Master", "field_of_study": "Statistique", "institution": "Université de Yaoundé II"},
    )


# --------------------------------------------------------------------------- tests
def test_two_devices_pair_and_share_everything_encrypted(server: SyncServer, device: Any) -> None:
    a, b = device("bureau"), device("portable", local_name="Awa")
    fill_profile(a)
    ws = a.post("/workspaces", json={"name": "Master 2027"}).json()
    a.post(f"/workspaces/{ws['id']}/notes", json={"body": "Comparer les bourses CEMAC."})

    status = online(server, a, "awa@example.com")
    assert status["mode"] == "synced" and status["paired"] is True and status["pending_changes"] > 0
    assert a.get("/auth/me").json()["account_mode"] == "synced"  # EF-01.12
    assert run(a)["pushed"] >= 4

    linked = online(server, b, "awa@example.com", register=False)
    assert linked["paired"] is False and linked["device_code"]
    assert run(b)["paired"] is False  # waits for approval
    assert b.post("/sync/devices/x/approve", json={"code": "0000 0000 0000"}).status_code in (403, 404)
    wrong = next(d for d in a.get("/sync/devices").json()["items"] if d["status"] == "pending")
    assert (
        a.post(f"/sync/devices/{wrong['id']}/approve", json={"code": "1234 5678 9012"}).json()["code"]
        == "sync_pairing_code_mismatch"
    )
    pair(a, b)
    report = run(b)
    assert report["paired"] is True and report["applied"] >= 4

    general = b.get("/profile").json()["general"]
    assert general["city"] == "Douala" and general["bio"] == "Analyste passionnée de statistique."
    assert {s["name"] for s in b.get("/profile").json()["skills"]} == {"Python", "Power BI"}
    assert b.get("/profile").json()["education"][0]["institution"] == "Université de Yaoundé II"
    ws_b = b.get(f"/workspaces/{ws['id']}").json()
    assert ws_b["name"] == "Master 2027" and ws_b["notes"][0]["body"] == "Comparer les bourses CEMAC."

    # The server holds ciphertext only (EF-17.05).
    blob = server.stored_bytes()
    for clear in (b"Douala", b"Python", b"Master 2027", b"CEMAC", "Yaoundé".encode()):
        assert clear not in blob


def test_concurrent_edits_merge_by_field_and_text_conflicts_are_manual(server: SyncServer, device: Any) -> None:
    a, b = device("a"), device("b")
    fill_profile(a)
    online(server, a, "awa@example.com")
    run(a)
    online(server, b, "awa@example.com", register=False)
    pair(a, b)
    run(b)
    run(a)

    a.put("/profile/general", json={"city": "Yaoundé", "bio": "Version du bureau."})
    b.put("/profile/general", json={"current_occupation": "Analyste de données", "bio": "Version du portable."})
    run(a)
    report = run(b)
    assert report["conflicts"] == 1
    g = b.get("/profile").json()["general"]
    assert g["city"] == "Yaoundé" and g["current_occupation"] == "Analyste de données"  # both edits kept
    assert g["bio"] == "Version du portable."  # text kept locally until the user chooses
    conflict = b.get("/sync/conflicts").json()["items"][0]
    assert conflict["local"]["field"] == "bio" and conflict["remote"]["value"] == "Version du bureau."
    b.post(f"/sync/conflicts/{conflict['id']}/resolve", json={"choice": "remote"})
    assert b.get("/profile").json()["general"]["bio"] == "Version du bureau."
    run(b)
    run(a)
    g = a.get("/profile").json()["general"]
    assert g["bio"] == "Version du bureau." and g["current_occupation"] == "Analyste de données"
    assert a.get("/sync/status").json()["conflicts"] == 0


def test_deletions_and_network_failures(server: SyncServer, device: Any) -> None:
    a, b = device("a"), device("b")
    edu = a.post(
        "/profile/education", json={"level": "Licence", "field_of_study": "Maths", "institution": "UY1"}
    ).json()
    online(server, a, "awa@example.com")
    run(a)
    online(server, b, "awa@example.com", register=False)
    pair(a, b)
    run(b)
    assert len(b.get("/profile").json()["education"]) == 1

    # Offline: the round fails cleanly and nothing is lost (EF-17.06).
    item_id = edu["education"][0]["id"] if "education" in edu else a.get("/profile").json()["education"][0]["id"]
    a.delete(f"/profile/education/{item_id}")
    active = a.state.active
    with active.db.tx() as conn:
        conn.execute(update(active.tables.sync_state).values(server_url="http://127.0.0.1:9"))
    r = a.post("/sync/run")
    assert r.status_code == 503 and r.json()["code"] == "sync_unreachable"
    assert a.get("/sync/status").json()["pending_changes"] >= 1
    with active.db.tx() as conn:
        conn.execute(update(active.tables.sync_state).values(server_url=server.url))
    run(a)

    # A lost acknowledgement makes the device send again: the server keeps one copy.
    count = server.record_count()
    with active.db.tx() as conn:
        conn.execute(update(active.tables.sync_outbox).values(pushed_at=None))
    run(a)
    assert server.record_count() == count

    run(b)
    assert b.get("/profile").json()["education"] == []


def test_online_account_totp_reset_and_remote_deletion(server: SyncServer, device: Any) -> None:
    a = device("a")
    online(server, a, "awa@example.com")
    setup = a.post("/sync/account/totp/setup").json()
    assert setup["uri"].startswith("otpauth://")
    assert a.post("/sync/account/totp/enable", json={"code": totp_now(setup["secret"])}).status_code == 200
    assert (
        a.get("/sync/account").json()["totp_enabled"] is True
        and "identity_private_sealed" not in a.get("/sync/account").json()
    )

    b = device("b")
    r = b.post(
        "/sync/account/link", json={"server_url": server.url, "email": "awa@example.com", "password": ONLINE_PASSWORD}
    )
    assert r.json()["code"] == "sync_totp_required"
    r = b.post("/sync/account/link", json={"server_url": server.url, "email": "awa@example.com", "password": ONLINE_PASSWORD,
                                           "totp": totp_now(setup["secret"])})  # fmt: skip
    assert r.status_code == 200 and r.json()["paired"] is False

    assert (
        b.post(
            "/sync/account/password-reset/request", json={"server_url": server.url, "email": "awa@example.com"}
        ).status_code
        == 202
    )
    assert "seul un appareil" in server.app.state.mailer.sent[-1].body

    assert a.post("/sync/account/register", json={"server_url": "http://example.com", "email": "x@example.com",
                                                  "password": ONLINE_PASSWORD}).json()["code"] == "sync_url_insecure"  # fmt: skip
    assert a.post("/sync/account/delete", json={"password": ONLINE_PASSWORD}).status_code == 200
    assert a.get("/sync/status").json()["mode"] == "local"
    assert server.record_count() == 0


def test_organisation_sharing_roles_rotation_and_leaving(server: SyncServer, device: Any) -> None:
    alice, bob = device("alice", "Alice"), device("bob", "Bob")
    online(server, alice, "alice@example.com")
    online(server, bob, "bob@example.com")
    org = alice.post("/orgs", json={"name": "Association Jeunesse Numérique", "org_type": "association"}).json()
    ws = alice.post("/workspaces", json={"name": "Subventions 2027"}).json()
    alice.post(f"/workspaces/{ws['id']}/notes", json={"body": "Appel de la fondation à suivre."})
    assert (
        alice.post("/orgs/share", json={"kind": "workspace", "id": ws["id"], "organization_id": org["id"]}).status_code
        == 200
    )
    invite = alice.post(f"/orgs/{org['id']}/invites", json={"email": "bob@example.com", "role": "viewer"}).json()
    run(alice)

    joined = bob.post("/orgs/join", json={"token": invite["token"]}).json()
    assert joined["role"] == "viewer"
    run(alice)  # hands the organisation key to Bob
    run(bob)
    bob_org = next(o for o in bob.get("/orgs").json()["items"])
    assert bob_org["name"] == "Association Jeunesse Numérique" and bob_org["role"] == "viewer"
    shared = bob.get(f"/workspaces/{ws['id']}").json()
    assert shared["name"] == "Subventions 2027" and shared["notes"][0]["body"] == "Appel de la fondation à suivre."
    members = alice.get(f"/orgs/{org['id']}/members").json()["items"]
    assert {m["email"] for m in members} == {"alice@example.com", "bob@example.com"} and all(
        m["key_fingerprint"] for m in members
    )

    # A viewer's local edit is refused by the server and undone (EF-17.02).
    bob.patch(f"/workspaces/{ws['id']}", json={"name": "Renommé par Bob"})
    run(bob)
    assert bob.get(f"/workspaces/{ws['id']}").json()["name"] == "Subventions 2027"

    bob_id = next(m["account_id"] for m in members if m["email"] == "bob@example.com")
    alice.patch(f"/orgs/{org['id']}/members/{bob_id}", json={"role": "editor"})
    bob.post(f"/workspaces/{ws['id']}/notes", json={"body": "Dossier envoyé à la fondation."})
    run(bob)
    run(alice)
    assert {n["body"] for n in alice.get(f"/workspaces/{ws['id']}").json()["notes"]} >= {
        "Dossier envoyé à la fondation."
    }

    # Leaving keeps a personal copy (EF-17.12); the remaining owner rotates the key (D-33).
    left = bob.post(f"/orgs/{bob_org['id']}/leave").json()
    assert left["kept_items"] == 1
    assert bob.get(f"/workspaces/{ws['id']}").json()["name"] == "Subventions 2027"
    assert bob.get("/orgs").json()["items"] == []
    run(alice)
    assert alice.get("/orgs").json()["items"][0]["key_version"] == 2
    actions = [e["action"] for e in alice.get(f"/orgs/{org['id']}/audit").json()["items"]]
    assert {"org.create", "invite.create", "member.join", "member.role", "member.leave", "key.rotate"} <= set(actions)
    # Shared content is encrypted with the organisation key too.
    assert b"Subventions 2027" not in server.stored_bytes()
    _ = STRONG_PASSWORD


def test_applications_documents_searches_and_monitors_follow_the_user(
    server: SyncServer, device: Any, site: FixtureSite
) -> None:
    a, b = device("a"), device("b")
    opp = next(i for i in collect(a, site) if i["title"].startswith("Bourse de master"))
    saved = a.post("/saved", json={"opportunity_id": opp["id"], "priority": "high"}).json()
    app_id = saved["application"]["id"]
    a.post(f"/applications/{app_id}/status", json={"status": "preparing"})
    a.post(
        f"/applications/{app_id}/events",
        json={"event_type": "interview", "title": "Entretien", "scheduled_at": "2099-11-20T10:00:00Z"},
    )
    a.post(f"/saved/{saved['id']}/notes", json={"body": "Demander deux lettres."})
    a.put(f"/saved/{saved['id']}/tags", json={"names": ["prioritaire"]})
    doc = a.post(f"/saved/{saved['id']}/generated", json={"doc_type": "cover_letter"}).json()
    a.post(f"/generated/{doc['id']}/versions", json={"content": "Version retouchée de la lettre."})
    source = next(s["id"] for s in a.get("/sources").json()["items"] if s["custom"])
    run_id = a.post(
        "/search/runs", json={"text": "bourse", "source_ids": [source], "filters": {"keywords": []}}
    ).json()["run_id"]
    query_id = wait_run(a, run_id)["query"]["id"]
    a.put(f"/search/queries/{query_id}/save", json={"name": "Bourses suivies"})
    a.post(
        "/monitors",
        json={
            "name": "Veille bourses",
            "filters": {"keywords": []},
            "schedule_kind": "daily",
            "schedule_expr": "08:00",
            "min_score": 0,
            "source_ids": [source],
        },
    )

    online(server, a, "awa@example.com")
    run(a)
    online(server, b, "awa@example.com", register=False)
    pair(a, b)
    report = run(b)
    assert report["skipped"] == 0, b.get("/sync/conflicts").json()

    copy = b.get(f"/saved/{saved['id']}").json()
    assert copy["priority"] == "high" and copy["tags"] == ["prioritaire"]
    # The opportunity itself is referenced by its URL and recreated on the other device (arch §10.1-5).
    assert b.get(f"/opportunities/{copy['opportunity_id']}").json()["overview"]["title"] == opp["title"]
    app_b = b.get(f"/applications/{app_id}").json()
    assert app_b["status"] == "preparing" and [h["to_status"] for h in app_b["history"]] == ["discovered", "preparing"]
    assert app_b["events"][0]["title"] == "Entretien"
    assert [n["body"] for n in b.get(f"/saved/{saved['id']}/notes").json()["items"]] == ["Demander deux lettres."]
    doc_b = b.get(f"/generated/{doc['id']}").json()
    assert doc_b["current_version"] == 2 and doc_b["content"] == "Version retouchée de la lettre."
    assert [q["saved_name"] for q in b.get("/search/history", params={"saved": True}).json()["items"]] == [
        "Bourses suivies"
    ]
    monitors = b.get("/monitors").json()["items"]
    assert [m["name"] for m in monitors] == ["Veille bourses"]

    # Version histories merge by union: both devices add a version, nobody's text is lost.
    a.post(f"/generated/{doc['id']}/versions", json={"content": "Troisième version (bureau)."})
    run(a)
    run(b)
    assert b.get(f"/generated/{doc['id']}").json()["current_version"] == 3

    # Removing a tracked opportunity on one device removes it on the other.
    a.delete(f"/saved/{saved['id']}")
    run(a)
    run(b)
    assert b.get(f"/saved/{saved['id']}").status_code == 404
