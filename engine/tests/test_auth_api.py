from __future__ import annotations

import json
from datetime import timedelta

import pytest

from core.timeutil import iso, utcnow
from services.auth_service import lockout_minutes
from tests.conftest import OTHER_PASSWORD, STRONG_PASSWORD, EngineClient


# --------------------------------------------------------------- transport guard
def test_health_is_public_but_everything_else_needs_engine_token(engine_client: EngineClient) -> None:
    raw = engine_client.client
    assert raw.get("/api/v1/health").status_code == 200  # regression B-02
    r = raw.get("/api/v1/version")
    assert r.status_code == 401
    assert r.headers["content-type"].startswith("application/problem+json")
    assert r.json()["code"] == "invalid_engine_token"
    assert raw.get("/api/v1/version", headers={"X-Engine-Token": "wrong"}).status_code == 401
    assert engine_client.get("/version").status_code == 200


def test_browser_origin_and_foreign_host_are_rejected(engine_client: EngineClient) -> None:
    assert engine_client.get("/version", headers={"Origin": "https://evil.example"}).status_code == 403
    r = engine_client.client.get(
        "/api/v1/version", headers={"X-Engine-Token": engine_client.engine_token, "Host": "evil.example"}
    )
    assert r.status_code == 421


def test_user_identity_header_is_ignored(signed_in: EngineClient) -> None:
    """Regression B-09: identity comes from the session bearer, never X-User-Id."""
    me = signed_in.get("/auth/me").json()
    signed_in.session = None
    r = signed_in.get("/auth/me", headers={"X-User-Id": me["id"]})
    assert r.status_code == 401


# ----------------------------------------------------------------- registration
def test_register_returns_session_and_recovery_phrase(engine_client: EngineClient) -> None:
    body = engine_client.register()
    assert len(body["recovery_phrase"].split()) == 12
    assert body["user"]["display_name"] == "Awa Ndjock"
    assert body["user"]["account_mode"] == "local"
    me = engine_client.get("/auth/me")
    assert me.status_code == 200 and me.json()["email"] == "awa@example.com"
    profiles = engine_client.get("/auth/profiles").json()["items"]
    assert [p["display_name"] for p in profiles] == ["Awa Ndjock"]
    registry = json.loads((engine_client.state.paths.registry_file).read_text())
    raw = json.dumps(registry)
    assert "awa@example.com" not in raw and STRONG_PASSWORD not in raw
    assert body["recovery_phrase"].split()[0] not in raw.split('"')


@pytest.mark.parametrize(
    "change,code",
    [
        ({"password": "short", "confirm_password": "short"}, "password_policy"),
        ({"confirm_password": "Different-Password-2026!"}, "password_mismatch"),
        ({"accept_terms": False}, "terms_not_accepted"),
    ],
)
def test_register_validation(engine_client: EngineClient, change: dict[str, object], code: str) -> None:
    payload = {
        "display_name": "Awa",
        "email": "awa@example.com",
        "password": STRONG_PASSWORD,
        "confirm_password": STRONG_PASSWORD,
        "locale": "fr",
        "accept_terms": True,
    } | change
    r = engine_client.post("/auth/register", json=payload)
    assert r.status_code == 422
    assert r.json()["code"] == code


def test_register_rejects_duplicate_email(signed_in: EngineClient) -> None:
    r = signed_in.post(
        "/auth/register",
        json={
            "display_name": "Dup",
            "email": "AWA@example.com",
            "password": OTHER_PASSWORD,
            "confirm_password": OTHER_PASSWORD,
            "locale": "en",
            "accept_terms": True,
        },
    )
    assert r.status_code == 409 and r.json()["code"] == "email_taken"


# ---------------------------------------------------------- sign in / lockout
def test_login_wrong_password_then_success(signed_in: EngineClient) -> None:
    signed_in.post("/auth/logout")
    signed_in.session = None
    bad = signed_in.post("/auth/login", json={"email": "awa@example.com", "password": "nope"})
    assert bad.status_code == 401 and bad.json()["code"] == "invalid_credentials"
    unknown = signed_in.post("/auth/login", json={"email": "who@example.com", "password": "x"})
    assert unknown.status_code == 401 and unknown.json()["code"] == "invalid_credentials"
    ok = signed_in.post("/auth/login", json={"email": "awa@example.com", "password": STRONG_PASSWORD})
    assert ok.status_code == 200
    signed_in.session = ok.json()["session_token"]
    assert signed_in.get("/auth/me").status_code == 200


def test_progressive_lockout_after_five_failures(signed_in: EngineClient) -> None:
    assert [lockout_minutes(n) for n in (4, 5, 6, 7, 20)] == [0, 1, 2, 4, 60]
    signed_in.post("/auth/logout")
    codes = [
        signed_in.post("/auth/login", json={"email": "awa@example.com", "password": "bad"}).status_code
        for _ in range(5)
    ]
    assert codes == [401, 401, 401, 401, 423]
    locked = signed_in.post("/auth/login", json={"email": "awa@example.com", "password": STRONG_PASSWORD})
    assert locked.status_code == 423 and locked.json()["retry_after_seconds"] > 0
    # Once the delay elapses the correct password works and the counter resets.
    reg = signed_in.state.registry
    rec = reg.all()[0]
    rec.locked_until = iso(utcnow() - timedelta(seconds=1))
    reg.update(rec)
    ok = signed_in.post("/auth/login", json={"email": "awa@example.com", "password": STRONG_PASSWORD})
    assert ok.status_code == 200
    assert reg.all()[0].failed_count == 0


# -------------------------------------------------------------- lock / unlock
def test_lock_closes_database_and_unlock_reopens(signed_in: EngineClient) -> None:
    profile_id = signed_in.get("/auth/me").json()["id"]
    assert signed_in.post("/auth/lock").status_code == 204
    assert signed_in.state.active is None
    r = signed_in.get("/auth/me")
    assert r.status_code == 401 and r.json()["code"] == "session_locked"
    assert r.json()["profile_id"] == profile_id
    status = signed_in.get("/auth/status").json()
    assert status == {"state": "locked", "profile_id": profile_id, "reason": "manual"}
    bad = signed_in.post("/auth/unlock", json={"profile_id": profile_id, "password": "wrong"})
    assert bad.status_code == 401
    ok = signed_in.post("/auth/unlock", json={"profile_id": profile_id, "password": STRONG_PASSWORD})
    assert ok.status_code == 200
    signed_in.session = ok.json()["session_token"]
    assert signed_in.get("/auth/me").status_code == 200


def test_auto_lock_after_inactivity(signed_in: EngineClient) -> None:
    state = signed_in.state
    state.active.auto_lock_minutes = 1
    state.active.last_activity -= 61
    assert state.auto_lock_tick() is not None
    r = signed_in.get("/auth/me")
    assert r.json()["code"] == "session_locked" and r.json()["reason"] == "inactivity"


def test_old_session_token_is_useless_after_relogin(signed_in: EngineClient) -> None:
    old = signed_in.session
    signed_in.post("/auth/lock")
    signed_in.session = signed_in.post(
        "/auth/login", json={"email": "awa@example.com", "password": STRONG_PASSWORD}
    ).json()["session_token"]
    assert signed_in.get("/auth/me", headers={"Authorization": f"Bearer {old}"}).status_code == 401


# ------------------------------------------------------- recovery / password
def test_recover_with_phrase_sets_new_password(engine_client: EngineClient) -> None:
    phrase = engine_client.register()["recovery_phrase"]
    engine_client.post("/auth/logout")
    bad = engine_client.post(
        "/auth/recover",
        json={
            "email": "awa@example.com",
            "recovery_phrase": "abandon " * 12,
            "new_password": OTHER_PASSWORD,
            "confirm_password": OTHER_PASSWORD,
        },
    )
    assert bad.status_code == 401
    r = engine_client.post(
        "/auth/recover",
        json={
            "email": "awa@example.com",
            "recovery_phrase": phrase.upper(),
            "new_password": OTHER_PASSWORD,
            "confirm_password": OTHER_PASSWORD,
        },
    )
    assert r.status_code == 200, r.text
    engine_client.post("/auth/logout")
    assert (
        engine_client.post("/auth/login", json={"email": "awa@example.com", "password": STRONG_PASSWORD}).status_code
        == 401
    )
    assert (
        engine_client.post("/auth/login", json={"email": "awa@example.com", "password": OTHER_PASSWORD}).status_code
        == 200
    )


def test_change_password_rewraps_key_without_losing_data(signed_in: EngineClient) -> None:
    r = signed_in.put(
        "/auth/password",
        json={"current_password": "wrong", "new_password": OTHER_PASSWORD, "confirm_password": OTHER_PASSWORD},
    )
    assert r.status_code == 401
    r = signed_in.put(
        "/auth/password",
        json={"current_password": STRONG_PASSWORD, "new_password": OTHER_PASSWORD, "confirm_password": OTHER_PASSWORD},
    )
    assert r.status_code == 204
    signed_in.patch("/auth/me", json={"theme": "dark"})
    signed_in.post("/auth/logout")
    ok = signed_in.post("/auth/login", json={"email": "awa@example.com", "password": OTHER_PASSWORD})
    assert ok.status_code == 200
    assert ok.json()["user"]["theme"] == "dark"


def test_preferences_update(signed_in: EngineClient) -> None:
    r = signed_in.patch("/auth/me", json={"preferred_locale": "en", "auto_lock_minutes": 30, "display_name": "Awa N."})
    assert r.status_code == 200
    body = r.json()
    assert body["preferred_locale"] == "en" and body["auto_lock_minutes"] == 30
    assert signed_in.get("/auth/profiles").json()["items"][0]["display_name"] == "Awa N."
    assert signed_in.patch("/auth/me", json={"auto_lock_minutes": 0}).status_code == 422


def test_delete_account_removes_all_local_data(signed_in: EngineClient) -> None:
    paths = signed_in.state.paths
    profile_id = signed_in.get("/auth/me").json()["id"]
    assert paths.profile_dir(profile_id).exists()
    bad = signed_in.post("/auth/account/delete", json={"password": "nope", "confirmation": "DELETE"})
    assert bad.status_code == 401
    r = signed_in.post("/auth/account/delete", json={"password": STRONG_PASSWORD, "confirmation": "DELETE"})
    assert r.status_code == 204
    assert not paths.profile_dir(profile_id).exists()
    assert signed_in.get("/auth/profiles").json()["items"] == []
    assert signed_in.get("/auth/status").json()["state"] == "signed_out"


def test_multiple_isolated_profiles(engine_client: EngineClient) -> None:
    engine_client.register(email="a@example.com", name="A")
    a_id = engine_client.get("/auth/me").json()["id"]
    engine_client.register(email="b@example.com", name="B", password=OTHER_PASSWORD)
    b_me = engine_client.get("/auth/me").json()
    assert b_me["id"] != a_id
    assert len(engine_client.get("/auth/profiles").json()["items"]) == 2
    assert engine_client.state.paths.profile_db(a_id) != engine_client.state.paths.profile_db(b_me["id"])


def test_password_strength_endpoint(engine_client: EngineClient) -> None:
    weak = engine_client.post("/auth/password-strength", json={"password": "azerty"}).json()
    assert not weak["acceptable"]
    strong = engine_client.post("/auth/password-strength", json={"password": STRONG_PASSWORD}).json()
    assert strong["acceptable"]


# ----------------------------------------------------------------- events
def test_events_websocket_requires_token_and_streams_auth_events(engine_client: EngineClient) -> None:
    from starlette.websockets import WebSocketDisconnect

    with (
        pytest.raises(WebSocketDisconnect),
        engine_client.client.websocket_connect("ws://127.0.0.1/api/v1/events") as ws,
    ):
        ws.receive_text()
    with engine_client.client.websocket_connect(
        "ws://127.0.0.1/api/v1/events", headers={"X-Engine-Token": engine_client.engine_token}
    ) as ws:
        assert json.loads(ws.receive_text())["type"] == "connected"
        engine_client.register()
        assert json.loads(ws.receive_text())["type"] == "auth.signed_in"


def test_websocket_from_foreign_host_is_rejected(engine_client: EngineClient) -> None:
    from starlette.websockets import WebSocketDisconnect

    with (
        pytest.raises(WebSocketDisconnect),
        engine_client.client.websocket_connect(
            "ws://evil.example/api/v1/events", headers={"X-Engine-Token": engine_client.engine_token}
        ) as ws,
    ):
        ws.receive_text()
