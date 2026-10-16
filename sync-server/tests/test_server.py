"""Sync server: accounts (EF-01.09/10), devices, opaque records (EF-17.04-06), organisations (EF-17.01/02/11/12)."""

from __future__ import annotations

import base64
import secrets
import time
import uuid

from opx_sync.security import totp_now, totp_verify
from tests.conftest import PASSWORD, Server, key


def record(n: int = 64) -> dict[str, object]:
    return {"op_id": str(uuid.uuid4()), "key_version": 1, "nonce": base64.b64encode(secrets.token_bytes(24)).decode(),
            "ciphertext": base64.b64encode(secrets.token_bytes(n)).decode()}  # fmt: skip


def test_health_and_metrics(server: Server) -> None:
    assert server.client.get("/v1/health").json()["status"] == "ok"
    assert "opx_sync_accounts 0" in server.client.get("/metrics").text


def test_registration_requires_verified_email(server: Server) -> None:
    c = server.client
    assert c.post("/v1/accounts", json={"email": "awa@example.com", "password": "short"}).status_code == 422
    assert c.post("/v1/accounts", json={"email": "Awa@Example.com", "password": PASSWORD}).status_code == 201
    assert (
        c.post("/v1/accounts", json={"email": "awa@example.com", "password": PASSWORD}).json()["code"] == "email_taken"
    )
    login = {
        "email": "awa@example.com",
        "password": PASSWORD,
        "device": {"name": "PC", "platform": "windows", "public_key": key()},
    }
    assert c.post("/v1/sessions", json=login).json()["code"] == "email_not_verified"
    assert c.post("/v1/accounts/verify", json={"token": "x" * 20}).json()["code"] == "token_invalid"
    token = server.code("awa@example.com")
    assert "verify?token=" in server.mail[-1].body
    assert c.post("/v1/accounts/verify", json={"token": token}).status_code == 200
    assert c.post("/v1/accounts/verify", json={"token": token}).json()["code"] == "token_invalid"  # single use
    r = c.post("/v1/sessions", json=login).json()
    assert r["device_status"] == "active"  # first device of the account


def test_wrong_passwords_lock_progressively(server: Server) -> None:
    server.account("awa@example.com")
    bad = {
        "email": "awa@example.com",
        "password": "wrong-password!",
        "device": {"name": "PC", "platform": "linux", "public_key": key()},
    }
    codes = [server.client.post("/v1/sessions", json=bad).json()["code"] for _ in range(6)]
    assert codes[:5] == ["invalid_credentials"] * 5 and codes[5] == "account_locked"


def test_totp_and_password_reset(server: Server) -> None:
    a = server.account("awa@example.com")
    c = server.client
    setup = c.post("/v1/account/totp/setup", headers=a["h"]).json()
    assert setup["uri"].startswith("otpauth://totp/Opportunex:")
    assert c.post("/v1/account/totp/enable", json={"code": "000000"}, headers=a["h"]).json()["code"] == "totp_invalid"
    c.post("/v1/account/totp/enable", json={"code": totp_now(setup["secret"])}, headers=a["h"])
    assert c.get("/v1/account", headers=a["h"]).json()["totp_enabled"] is True
    login = {
        "email": "awa@example.com",
        "password": PASSWORD,
        "device": {"name": "PC2", "platform": "linux", "public_key": key()},
    }
    assert c.post("/v1/sessions", json=login).json()["code"] == "totp_required"
    assert c.post("/v1/sessions", json=login | {"totp": "123456"}).json()["code"] in (
        "totp_invalid",
        "invalid_credentials",
    )
    assert c.post("/v1/sessions", json=login | {"totp": totp_now(setup["secret"])}).status_code == 201
    # RFC 6238 test vector (SHA-1, T = 59 s): 94287082 → last 6 digits.
    assert totp_verify("GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ", "287082", at=59)

    assert c.post("/v1/password-reset/request", json={"email": "nobody@example.com"}).status_code == 202
    c.post("/v1/password-reset/request", json={"email": "awa@example.com"})
    assert "seul un appareil" in server.mail[-1].body  # the e-mail says data cannot be recovered this way
    new = "Nouveau-Mot-De-Passe-2026!"
    assert (
        c.post("/v1/password-reset", json={"token": server.code("awa@example.com"), "password": new}).status_code == 200
    )
    assert c.get("/v1/account", headers=a["h"]).status_code == 401  # sessions closed


def test_second_device_waits_for_pairing_then_gets_its_envelope(server: Server) -> None:
    a = server.account("awa@example.com", "Bureau")
    b = server.login("awa@example.com", "Portable")
    c = server.client
    assert b["device_status"] == "pending"
    assert (
        c.post("/v1/sync/push", json={"scope": "user", "items": [record()]}, headers=b["h"]).json()["code"]
        == "device_not_paired"
    )
    devices = c.get("/v1/devices", headers=a["h"]).json()["items"]
    pending = next(d for d in devices if d["status"] == "pending")
    assert (
        c.post(f"/v1/devices/{pending['id']}/approve", json={"envelope": "E" * 60}, headers=b["h"]).status_code == 403
    )
    assert (
        c.post(f"/v1/devices/{pending['id']}/approve", json={"envelope": "E" * 60}, headers=a["h"]).status_code == 200
    )
    assert c.get("/v1/devices/me/envelope", headers=b["h"]).json() == {"status": "active", "envelope": "E" * 60}
    c.post(f"/v1/devices/{pending['id']}/revoke", headers=a["h"])
    assert c.get("/v1/account", headers=b["h"]).status_code == 401


def test_push_pull_is_idempotent_ordered_and_quota_bound(server: Server) -> None:
    a = server.account("awa@example.com")
    c = server.client
    batch = [record() for _ in range(3)]
    assert c.post("/v1/sync/push", json={"scope": "user", "items": batch}, headers=a["h"]).json()["accepted"] == 3
    again = c.post("/v1/sync/push", json={"scope": "user", "items": batch}, headers=a["h"]).json()
    assert again["accepted"] == 0 and again["duplicates"] == 3  # replay after a network cut
    page = c.get("/v1/sync/pull", params={"after": 0, "limit": 2}, headers=a["h"]).json()
    assert len(page["items"]) == 2 and page["has_more"] is True
    rest = c.get("/v1/sync/pull", params={"after": page["cursor"]}, headers=a["h"]).json()
    assert [i["op_id"] for i in page["items"] + rest["items"]] == [r["op_id"] for r in batch]
    other = server.account("bob@example.com")
    assert c.get("/v1/sync/pull", headers=other["h"]).json()["items"] == []  # scopes are isolated
    big = [record(400 * 1024) for _ in range(3)]
    assert (
        c.post("/v1/sync/push", json={"scope": "user", "items": big}, headers=a["h"]).json()["code"] == "quota_exceeded"
    )


def test_organisation_roles_invites_keys_and_audit(server: Server) -> None:
    c = server.client
    owner = server.account("awa@example.com")
    member = server.account("bob@example.com")
    stranger = server.account("eve@example.com")
    org = c.post("/v1/orgs", headers=owner["h"]).json()["id"]
    c.put(
        f"/v1/orgs/{org}/keys",
        json={"key_version": 1, "envelopes": {owner["account_id"]: "K" * 60}},
        headers=owner["h"],
    )

    inv = c.post(
        f"/v1/orgs/{org}/invites", json={"email": "bob@example.com", "role": "viewer"}, headers=owner["h"]
    ).json()
    assert server.mail[-1].to == "bob@example.com"
    assert (
        c.post("/v1/invites/accept", json={"token": inv["token"]}, headers=stranger["h"]).json()["code"]
        == "invite_other_email"
    )
    assert c.post("/v1/invites/accept", json={"token": inv["token"]}, headers=member["h"]).json()["role"] == "viewer"
    assert (
        c.post("/v1/invites/accept", json={"token": inv["token"]}, headers=member["h"]).json()["code"]
        == "invite_invalid"
    )

    scope = f"org:{org}"
    assert (
        c.post("/v1/sync/push", json={"scope": scope, "items": [record()]}, headers=member["h"]).json()["code"]
        == "read_only_role"
    )
    assert (
        c.post("/v1/sync/push", json={"scope": scope, "items": [record()]}, headers=owner["h"]).json()["accepted"] == 1
    )
    assert len(c.get("/v1/sync/pull", params={"scope": scope}, headers=member["h"]).json()["items"]) == 1
    assert c.get("/v1/sync/pull", params={"scope": scope}, headers=stranger["h"]).json()["code"] == "not_a_member"
    assert (
        c.patch(
            f"/v1/orgs/{org}/members/{member['account_id']}", json={"role": "editor"}, headers=member["h"]
        ).status_code
        == 403
    )
    c.patch(f"/v1/orgs/{org}/members/{member['account_id']}", json={"role": "editor"}, headers=owner["h"])
    assert (
        c.post("/v1/sync/push", json={"scope": scope, "items": [record()]}, headers=member["h"]).json()["accepted"] == 1
    )

    # Last owner cannot leave; a member can, and the key must then be rotated.
    assert c.delete(f"/v1/orgs/{org}/members/{owner['account_id']}", headers=owner["h"]).json()["code"] == "last_owner"
    assert c.delete(f"/v1/orgs/{org}/members/{member['account_id']}", headers=member["h"]).status_code == 204
    mine = c.get("/v1/orgs", headers=owner["h"]).json()["items"][0]
    assert mine["rotation_needed"] is True and mine["envelopes"] == {"1": "K" * 60}
    assert (
        c.put(f"/v1/orgs/{org}/keys", json={"key_version": 3, "envelopes": {}}, headers=owner["h"]).json()["code"]
        == "key_version_conflict"
    )
    c.put(
        f"/v1/orgs/{org}/keys",
        json={"key_version": 2, "envelopes": {owner["account_id"]: "N" * 60}},
        headers=owner["h"],
    )
    assert c.get("/v1/orgs", headers=owner["h"]).json()["items"][0]["key_version"] == 2
    actions = [e["action"] for e in c.get(f"/v1/orgs/{org}/audit", headers=owner["h"]).json()["items"]]
    assert (
        actions[0] == "key.rotate"
        and "member.leave" in actions
        and "member.join" in actions
        and "org.create" in actions
    )


def test_account_deletion_erases_server_data(server: Server) -> None:
    a = server.account("awa@example.com")
    c = server.client
    c.post("/v1/sync/push", json={"scope": "user", "items": [record()]}, headers=a["h"])
    assert c.post("/v1/account/delete", json={"password": "wrong"}, headers=a["h"]).status_code == 401
    assert c.post("/v1/account/delete", json={"password": PASSWORD}, headers=a["h"]).status_code == 204
    assert "opx_sync_records 0" in c.get("/metrics").text and "opx_sync_accounts 0" in c.get("/metrics").text
    _ = time
