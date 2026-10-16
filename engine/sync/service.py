"""Sync service (M17): online account, pairing, encrypted push/pull, merge, conflicts, organisations.

Everything sent to the server is encrypted here with XChaCha20-Poly1305 (D-29); the server only
relays opaque records. Local writes are captured by triggers (migration 0004); remote changes are
merged field by field against the last synchronised version (D-31).
"""

from __future__ import annotations

import asyncio
import json
import platform
import uuid
from collections import defaultdict
from contextlib import contextmanager
from typing import Any

import structlog
from sqlalchemy import Connection, delete, func, insert, select, update

from core.errors import Conflict, NotFound, ValidationFailed
from core.ids import uuid7
from core.timeutil import now_iso
from services.state import ActiveProfile, EngineState
from sync import crypto, entities
from sync.client import SyncClient, SyncError, check_server_url

log = structlog.get_logger("sync")
NAMESPACE = uuid.UUID("6f1c3a4e-6a43-4d7f-9a7b-2f0e1c9d8b11")
PUSH_CHUNK = 200
WRITERS = {"owner", "admin", "editor"}
MANAGERS = {"owner", "admin"}


def _empty(value: Any) -> bool:
    return value is None or value == "" or value == [] or value == {}


def _platform() -> str:
    s = platform.system().lower()
    return "windows" if s.startswith("win") else ("macos" if s == "darwin" else "linux")


class SyncService:
    def __init__(self, active: ActiveProfile, state: EngineState) -> None:
        self.active = active
        self.state = state
        self.T = active.tables
        self.uid = active.user_id

    # ------------------------------------------------------------ local state
    @property
    def _token_ref(self) -> str:
        return f"sync-session:{self.uid}"

    def _state_row(self) -> dict[str, Any] | None:
        with self.active.db.read() as conn:
            r = (
                conn.execute(select(self.T.sync_state).where(self.T.sync_state.c.user_id == self.uid))
                .mappings()
                .first()
            )
        return dict(r) if r else None

    def _key(self, conn: Connection, kind: str, ref: str, version: int = 1) -> bytes | None:
        T = self.T
        v = conn.execute(
            select(T.sync_keys.c.secret).where(
                T.sync_keys.c.kind == kind, T.sync_keys.c.ref == ref, T.sync_keys.c.version == version
            )
        ).scalar()
        return bytes(v) if v is not None else None

    def _put_key(self, conn: Connection, kind: str, ref: str, secret: bytes, version: int = 1) -> None:
        T = self.T
        conn.execute(
            delete(T.sync_keys).where(
                T.sync_keys.c.kind == kind, T.sync_keys.c.ref == ref, T.sync_keys.c.version == version
            )
        )
        conn.execute(insert(T.sync_keys).values(kind=kind, ref=ref, version=version, secret=secret))

    def _client(self, server: str | None = None, token: bool = True) -> SyncClient:
        from services.privacy_service import PrivacyService

        st = self._state_row()
        base = server or (st["server_url"] if st else None)
        if not base:
            raise Conflict("sync is not linked", code="sync_not_linked")
        tok = self.state.secrets.get(self._token_ref) if token else None
        return SyncClient(base, tok, PrivacyService(self.active).network()["proxy_url"])

    @contextmanager
    def _guard(self, conn: Connection) -> Any:
        """Remote changes are written without being captured again (trigger condition, migration 0004)."""
        conn.execute(insert(self.T.sync_guard).values(applying=1))
        try:
            yield
        finally:
            conn.execute(delete(self.T.sync_guard))

    # ------------------------------------------------------------ status
    def status(self) -> dict[str, Any]:
        T = self.T
        st = self._state_row()
        with self.active.db.read() as conn:
            device_private = self._key(conn, "device", "device")
            pending = conn.execute(
                select(func.count()).select_from(T.sync_outbox).where(T.sync_outbox.c.pushed_at.is_(None))
            ).scalar()
            conflicts = conn.execute(
                select(func.count()).select_from(T.sync_conflicts).where(T.sync_conflicts.c.resolved_at.is_(None))
            ).scalar()
            account_key = self._key(conn, "account", "account")
            email = conn.execute(
                select(T.application_settings.c.value).where(T.application_settings.c.key == "sync.email")
            ).scalar()
        linked = st is not None
        return {
            "mode": "synced" if linked else "local",
            "linked": linked,
            "server_url": st["server_url"] if st else None,
            "email": email,
            "paired": account_key is not None,
            "device_code": crypto.pairing_code(crypto.public_of(device_private)) if device_private else None,
            "last_push_at": st["last_push_at"] if st else None,
            "last_pull_at": st["last_pull_at"] if st else None,
            "pending_changes": int(pending or 0),
            "conflicts": int(conflicts or 0),
        }

    # ------------------------------------------------------------ account
    async def register(self, server: str, email: str, password: str) -> dict[str, Any]:
        async with SyncClient(check_server_url(server)) as c:
            return dict(await c.call("POST", "/accounts", {"email": email, "password": password}))

    async def verify(self, server: str, code: str) -> dict[str, Any]:
        async with SyncClient(check_server_url(server)) as c:
            return dict(await c.call("POST", "/accounts/verify", {"token": code.strip()}))

    async def resend(self, server: str, email: str) -> None:
        async with SyncClient(check_server_url(server)) as c:
            await c.call("POST", "/accounts/verification", {"email": email})

    async def reset_request(self, server: str, email: str) -> None:
        async with SyncClient(check_server_url(server)) as c:
            await c.call("POST", "/password-reset/request", {"email": email})

    async def reset(self, server: str, code: str, password: str) -> None:
        async with SyncClient(check_server_url(server)) as c:
            await c.call("POST", "/password-reset", {"token": code.strip(), "password": password})

    async def link(
        self, server: str, email: str, password: str, totp: str | None, device_name: str | None
    ) -> dict[str, Any]:
        """EF-01.09: sign in to the online account; the first device creates the account keys (D-29/30)."""
        server = check_server_url(server)
        if self._state_row() is not None:
            raise Conflict("already linked", code="sync_already_linked")
        with self.active.db.tx() as conn:
            device_private = self._key(conn, "device", "device")
            if device_private is None:
                device_private, _pub = crypto.new_device_key()
                self._put_key(conn, "device", "device", device_private)
        body = {
            "email": email,
            "password": password,
            "totp": totp or None,
            "device": {
                "name": (device_name or platform.node() or "Opportunex")[:120],
                "platform": _platform(),
                "public_key": crypto.public_of(device_private),
            },
        }
        async with SyncClient(server) as c:
            login = await c.call("POST", "/sessions", body)
            c.token = login["token"]
            account = await c.call("GET", "/account")
            if login["device_status"] == "active" and not account.get("identity_public_key"):
                # First device of the account: create the sync key and the identity key pair.
                sync_key = crypto.new_key()
                identity_private, identity_public = crypto.new_device_key()
                nonce, ct = crypto.encrypt(sync_key, identity_private, "identity")
                await c.call(
                    "PUT", "/account/identity", {"public_key": identity_public, "private_sealed": f"{nonce}.{ct}"}
                )
                with self.active.db.tx() as conn:
                    self._put_key(conn, "account", "account", sync_key)
                    self._put_key(conn, "identity", "identity", identity_private)
            elif login["device_status"] == "active":
                with self.active.db.read() as conn:
                    have = self._key(conn, "account", "account")
                if have is None:
                    raise SyncError(
                        "this device was paired before but its keys are gone", code="sync_keys_missing", status=409
                    )
        self.state.secrets.set(self._token_ref, login["token"])
        with self.active.db.tx() as conn:
            T = self.T
            conn.execute(delete(T.sync_state).where(T.sync_state.c.user_id == self.uid))
            conn.execute(insert(T.sync_state).values(user_id=self.uid, server_url=server, lamport_clock=0))
            conn.execute(delete(T.application_settings).where(T.application_settings.c.key == "sync.email"))
            conn.execute(
                insert(T.application_settings).values(key="sync.email", value=email.lower(), value_type="string")
            )
            conn.execute(update(T.users).where(T.users.c.id == self.uid).values(account_mode="synced"))
            if login["device_status"] == "active":
                self._enqueue_snapshot(conn)
        return self.status()

    def _enqueue_snapshot(self, conn: Connection) -> None:
        T = self.T
        clock = int(
            conn.execute(select(T.sync_state.c.lamport_clock).where(T.sync_state.c.user_id == self.uid)).scalar() or 0
        )
        for kind, ident in entities.all_records(conn, T, self.uid):
            clock += 1
            conn.execute(
                insert(T.sync_outbox).values(
                    user_id=self.uid, entity_table=kind, entity_id=ident, operation="upsert", lamport=clock
                )
            )
        orgs = [
            r[0]
            for r in conn.execute(select(T.organizations.c.remote_id).where(T.organizations.c.remote_id.is_not(None)))
        ]
        for remote in orgs:
            clock += 1
            conn.execute(
                insert(T.sync_outbox).values(
                    user_id=self.uid, entity_table="org", entity_id=remote, operation="upsert", lamport=clock
                )
            )
        conn.execute(update(T.sync_state).where(T.sync_state.c.user_id == self.uid).values(lamport_clock=clock))

    async def unlink(self) -> dict[str, Any]:
        """Stop syncing on this device: local data stays; keys and server session are forgotten."""
        try:
            async with self._client() as c:
                await c.call("DELETE", "/sessions")
        except SyncError:
            pass  # offline: the session simply expires on the server
        T = self.T
        with self.active.db.tx() as conn:
            for table in (T.sync_state, T.sync_outbox, T.sync_shadow, T.sync_cursors, T.sync_keys, T.sync_conflicts):
                conn.execute(delete(table))
            conn.execute(delete(T.application_settings).where(T.application_settings.c.key == "sync.email"))
            conn.execute(update(T.users).where(T.users.c.id == self.uid).values(account_mode="local"))
        self.state.secrets.delete(self._token_ref)
        return self.status()

    async def account(self) -> dict[str, Any]:
        async with self._client() as c:
            a = dict(await c.call("GET", "/account"))
        a.pop("identity_private_sealed", None)
        return a

    async def totp(self, action: str, code: str | None = None) -> dict[str, Any]:
        async with self._client() as c:
            if action == "setup":
                return dict(await c.call("POST", "/account/totp/setup"))
            return dict(await c.call("POST", f"/account/totp/{action}", {"code": code or ""}))

    async def delete_remote(self, password: str) -> dict[str, Any]:
        """EF-01.11 (remote part): erase the online account and every record on the server."""
        async with self._client() as c:
            await c.call("POST", "/account/delete", {"password": password})
        return await self.unlink()

    # ------------------------------------------------------------ devices
    async def devices(self) -> list[dict[str, Any]]:
        async with self._client() as c:
            items = (await c.call("GET", "/devices"))["items"]
        return [d | {"pairing_code": crypto.pairing_code(d["public_key"])} for d in items]

    async def approve(self, device_id: str, code: str) -> dict[str, Any]:
        """Seal the sync key to a new device, only if the code typed matches its key (D-30)."""
        devices = {d["id"]: d for d in await self.devices()}
        target = devices.get(device_id)
        if target is None or target["status"] != "pending":
            raise NotFound("no device waiting with this id", code="sync_device_not_pending")
        if not crypto.same_code(code, target["pairing_code"]):
            raise ValidationFailed("the pairing code does not match", code="sync_pairing_code_mismatch")
        with self.active.db.read() as conn:
            sync_key = self._key(conn, "account", "account")
        if sync_key is None:
            raise Conflict("this device is not paired itself", code="sync_not_paired")
        async with self._client() as c:
            await c.call(
                "POST", f"/devices/{device_id}/approve", {"envelope": crypto.seal(target["public_key"], sync_key)}
            )
        return {"status": "active"}

    async def revoke(self, device_id: str) -> None:
        async with self._client() as c:
            await c.call("POST", f"/devices/{device_id}/revoke")

    async def _complete_pairing(self, c: SyncClient) -> bool:
        with self.active.db.read() as conn:
            if self._key(conn, "account", "account") is not None:
                return True
            device_private = self._key(conn, "device", "device")
        mine = await c.call("GET", "/devices/me/envelope")
        if mine["status"] != "active" or not mine["envelope"] or device_private is None:
            return False
        sync_key = crypto.unseal(device_private, mine["envelope"])
        account = await c.call("GET", "/account")
        nonce, ct = str(account["identity_private_sealed"]).split(".", 1)
        identity = crypto.decrypt(sync_key, nonce, ct, "identity")
        with self.active.db.tx() as conn:
            self._put_key(conn, "account", "account", sync_key)
            self._put_key(conn, "identity", "identity", identity)
            self._enqueue_snapshot(conn)
        return True

    # ------------------------------------------------------------ run
    async def run(self) -> dict[str, Any]:
        """One sync round: pairing, organisation keys, pull and merge every scope, then push (EF-17.04/06)."""
        report: dict[str, Any] = {"pulled": 0, "applied": 0, "pushed": 0, "conflicts": 0, "skipped": 0, "paired": True}
        async with self._client() as c:
            if not await self._complete_pairing(c):
                report["paired"] = False
                return report | {"status": self.status()}
            orgs = await self._sync_org_keys(c)
            scopes = ["user"] + [f"org:{o['id']}" for o in orgs]
            for scope in scopes:
                pulled = await self._pull(c, scope, report)
                report["pulled"] += pulled
            report["pushed"] = await self._push(c, {o["id"]: o for o in orgs})
        now = now_iso()
        with self.active.db.tx() as conn:
            conn.execute(
                update(self.T.sync_state)
                .where(self.T.sync_state.c.user_id == self.uid)
                .values(last_pull_at=now, last_push_at=now)
            )
        return report | {"status": self.status()}

    def _scope_key(self, conn: Connection, scope: str, version: int | None = None) -> tuple[bytes | None, int]:
        if scope == "user":
            return self._key(conn, "account", "account"), 1
        org = scope[4:]
        if version is None:
            version = int(
                conn.execute(
                    select(func.max(self.T.sync_keys.c.version)).where(
                        self.T.sync_keys.c.kind == "org", self.T.sync_keys.c.ref == org
                    )
                ).scalar()
                or 0
            )
        return self._key(conn, "org", org, version), version

    async def _pull(self, c: SyncClient, scope: str, report: dict[str, Any]) -> int:
        """Pull a scope page by page; the cursor only moves past records that were handled."""
        T = self.T
        with self.active.db.read() as conn:
            cursor = int(
                conn.execute(select(T.sync_cursors.c.cursor).where(T.sync_cursors.c.scope == scope)).scalar() or 0
            )
        total = 0
        while True:
            page = await c.call("GET", "/sync/pull", params={"scope": scope, "after": cursor, "limit": 500})
            blocked = False
            with self.active.db.tx() as conn:
                me = self._device_id(conn)
                deferred: list[dict[str, Any]] = []
                for it in page["items"]:
                    key, _v = self._scope_key(conn, scope, int(it["key_version"]))
                    if key is None:
                        blocked = True  # organisation key not received yet: resume from here later
                        break
                    cursor = int(it["seq"])
                    try:
                        rec = json.loads(crypto.decrypt(key, it["nonce"], it["ciphertext"], f"{scope}|{it['op_id']}"))
                    except crypto.DecryptError:
                        log.warning("sync_record_undecryptable", scope=scope, seq=it["seq"])
                        report["skipped"] += 1
                        continue
                    total += 1
                    if rec.get("device") != me:  # our own records come back too
                        self._apply_record(conn, scope, rec, report, deferred)
                for rec in deferred:  # children that arrived before their parent in the same page
                    self._apply_record(conn, scope, rec, report, None)
                conn.execute(delete(T.sync_cursors).where(T.sync_cursors.c.scope == scope))
                conn.execute(insert(T.sync_cursors).values(scope=scope, cursor=cursor))
            if blocked or not page["has_more"]:
                break
        return total

    def _device_id(self, conn: Connection) -> str:
        priv = self._key(conn, "device", "device")
        return crypto.public_of(priv) if priv else ""

    def _apply_record(
        self,
        conn: Connection,
        scope: str,
        rec: dict[str, Any],
        report: dict[str, Any],
        deferred: list[dict[str, Any]] | None,
    ) -> bool:
        T = self.T
        kind, ident, op = rec["kind"], rec["id"], rec["op"]
        remote_lamport = int(rec["lamport"])
        clock = int(
            conn.execute(select(T.sync_state.c.lamport_clock).where(T.sync_state.c.user_id == self.uid)).scalar() or 0
        )
        conn.execute(
            update(T.sync_state)
            .where(T.sync_state.c.user_id == self.uid)
            .values(lamport_clock=max(clock, remote_lamport) + 1)
        )
        pending = conn.execute(
            select(func.max(T.sync_outbox.c.lamport)).where(
                T.sync_outbox.c.entity_table == kind,
                T.sync_outbox.c.entity_id == ident,
                T.sync_outbox.c.pushed_at.is_(None),
            )
        ).scalar()
        shadow_row = (
            conn.execute(select(T.sync_shadow).where(T.sync_shadow.c.kind == kind, T.sync_shadow.c.entity_id == ident))
            .mappings()
            .first()
        )
        base = json.loads(shadow_row["payload"]) if shadow_row else {}
        newer = self._remote_wins(remote_lamport, rec.get("device", ""), pending or 0, self._device_id(conn))
        try:
            with self._guard(conn):
                if op == "delete":
                    if pending is None or newer:
                        entities.remove(conn, T, self.uid, kind, ident)
                        self._drop_pending(conn, kind, ident)
                    conn.execute(
                        delete(T.sync_shadow).where(T.sync_shadow.c.kind == kind, T.sync_shadow.c.entity_id == ident)
                    )
                    report["applied"] += 1
                    return True
                remote = rec["data"]
                if pending is None:
                    merged = remote
                else:
                    local = entities.serialize(conn, T, self.uid, kind, ident)
                    if local is None:  # deleted here, edited there
                        if not newer:
                            return True
                        self._drop_pending(conn, kind, ident)
                        merged = remote
                    else:
                        merged, clashes = self._merge(kind, base, local, remote, newer)
                        for field in clashes:
                            conn.execute(
                                insert(T.sync_conflicts).values(
                                    user_id=self.uid,
                                    entity_table=kind,
                                    entity_id=ident,
                                    local_payload=json.dumps(
                                        {"field": field, "value": local.get(field), "scope": scope}
                                    ),
                                    remote_payload=json.dumps({"field": field, "value": remote.get(field)}),
                                )
                            )
                            report["conflicts"] += 1
                with conn.begin_nested():
                    entities.apply(conn, T, self.uid, kind, ident, merged)
        except entities.SkipRecord as exc:
            if exc.code == "parent_missing" and deferred is not None:
                deferred.append(rec)
                return False
            conn.execute(
                insert(T.sync_conflicts).values(
                    user_id=self.uid,
                    entity_table=kind,
                    entity_id=ident,
                    local_payload=json.dumps({"field": "*", "reason": exc.code, "scope": scope}),
                    remote_payload=json.dumps({"field": "*", "value": rec.get("data")}),
                )
            )
            report["skipped"] += 1
            return False
        conn.execute(delete(T.sync_shadow).where(T.sync_shadow.c.kind == kind, T.sync_shadow.c.entity_id == ident))
        conn.execute(
            insert(T.sync_shadow).values(
                kind=kind, entity_id=ident, scope=scope, payload=json.dumps(rec["data"]), lamport=remote_lamport
            )
        )
        report["applied"] += 1
        return True

    @staticmethod
    def _remote_wins(remote_lamport: int, remote_device: str, local_lamport: int, local_device: str) -> bool:
        return (remote_lamport, remote_device) > (local_lamport, local_device)

    def _drop_pending(self, conn: Connection, kind: str, ident: str) -> None:
        T = self.T
        conn.execute(
            update(T.sync_outbox)
            .where(
                T.sync_outbox.c.entity_table == kind,
                T.sync_outbox.c.entity_id == ident,
                T.sync_outbox.c.pushed_at.is_(None),
            )
            .values(pushed_at=now_iso())
        )

    @staticmethod
    def _merge(
        kind: str, base: dict[str, Any], local: dict[str, Any], remote: dict[str, Any], remote_newer: bool
    ) -> tuple[dict[str, Any], list[str]]:
        """Three-way, field by field (D-31). Returns the merged record and the text fields left to the user."""
        merged: dict[str, Any] = {}
        clashes: list[str] = []
        unions = entities.UNION_FIELDS.get(kind, {})
        for field in set(local) | set(remote):
            lv, rv, bv = local.get(field), remote.get(field), base.get(field)
            if lv == rv:
                merged[field] = lv
            elif field in unions:
                keyf = unions[field]
                seen: dict[Any, Any] = {keyf(x): x for x in (lv or [])}
                for x in rv or []:
                    seen.setdefault(keyf(x), x)
                merged[field] = list(seen.values())
            elif lv == bv or (not base and _empty(lv)):
                # Without a common version yet (a device joining the account), an empty value counts as unset.
                merged[field] = rv
            elif rv == bv or (not base and _empty(rv)):
                merged[field] = lv
            elif field in entities.TEXT_FIELDS.get(kind, set()):
                merged[field] = lv  # kept until the user chooses
                clashes.append(field)
            else:
                merged[field] = rv if remote_newer else lv
        return merged, clashes

    async def _push(self, c: SyncClient, orgs: dict[str, dict[str, Any]]) -> int:
        T = self.T
        with self.active.db.read() as conn:
            rows = [
                dict(r)
                for r in conn.execute(
                    select(T.sync_outbox).where(T.sync_outbox.c.pushed_at.is_(None)).order_by(T.sync_outbox.c.lamport)
                ).mappings()
            ]
        if not rows:
            return 0
        latest: dict[tuple[str, str], dict[str, Any]] = {}
        ids: dict[tuple[str, str], list[int]] = defaultdict(list)
        for r in rows:
            k = (r["entity_table"], r["entity_id"])
            latest[k] = r
            ids[k].append(r["id"])
        by_scope: dict[str, list[tuple[tuple[str, str], dict[str, Any], dict[str, Any] | None]]] = defaultdict(list)
        with self.active.db.read() as conn:
            device = self._device_id(conn)
            for k, r in sorted(latest.items(), key=lambda kv: kv[1]["lamport"]):
                kind, ident = k
                data = None if r["operation"] == "delete" else entities.serialize(conn, T, self.uid, kind, ident)
                op = "delete" if data is None else "upsert"
                shadow = conn.execute(
                    select(T.sync_shadow.c.scope).where(
                        T.sync_shadow.c.kind == kind, T.sync_shadow.c.entity_id == ident
                    )
                ).scalar()
                scope = entities.scope_of(conn, T, kind, ident, data) if data is not None else (shadow or "user")
                rec = {
                    "v": 1,
                    "kind": kind,
                    "id": ident,
                    "op": op,
                    "lamport": r["lamport"],
                    "device": device,
                    "data": data,
                }
                by_scope[scope].append((k, rec, None))
                if shadow and shadow != scope:  # moved between personal and organisation space
                    old = {
                        "v": 1,
                        "kind": kind,
                        "id": ident,
                        "op": "delete",
                        "lamport": r["lamport"],
                        "device": device,
                        "data": None,
                    }
                    by_scope[shadow].append((k, old, {"moved": True}))
        pushed = 0
        for scope, recs in by_scope.items():
            if scope.startswith("org:"):
                role = orgs.get(scope[4:], {}).get("role")
                if role not in WRITERS:
                    self._revert(recs, ids)  # viewers cannot change shared records (EF-17.02)
                    continue
            with self.active.db.read() as conn:
                key, version = self._scope_key(conn, scope)
            if key is None:
                continue  # organisation key not available yet: retried next round
            for i in range(0, len(recs), PUSH_CHUNK):
                chunk = recs[i : i + PUSH_CHUNK]
                items = []
                for k, rec, _flag in chunk:
                    op_id = str(uuid.uuid5(NAMESPACE, f"{self.uid}:{scope}:{max(ids[k])}:{rec['op']}"))
                    nonce, ct = crypto.encrypt(key, json.dumps(rec, default=str).encode(), f"{scope}|{op_id}")
                    items.append({"op_id": op_id, "key_version": version, "nonce": nonce, "ciphertext": ct})
                try:
                    await c.call("POST", "/sync/push", {"scope": "user" if scope == "user" else scope, "items": items})
                except SyncError as exc:
                    if exc.code == "sync_read_only_role":
                        self._revert(chunk, ids)
                        continue
                    raise
                now = now_iso()
                with self.active.db.tx() as conn:
                    for k, rec, flag in chunk:
                        if flag:
                            continue
                        conn.execute(update(T.sync_outbox).where(T.sync_outbox.c.id.in_(ids[k])).values(pushed_at=now))
                        conn.execute(
                            delete(T.sync_shadow).where(T.sync_shadow.c.kind == k[0], T.sync_shadow.c.entity_id == k[1])
                        )
                        if rec["op"] == "upsert":
                            conn.execute(
                                insert(T.sync_shadow).values(
                                    kind=k[0],
                                    entity_id=k[1],
                                    scope=scope,
                                    payload=json.dumps(rec["data"], default=str),
                                    lamport=rec["lamport"],
                                )
                            )
                pushed += sum(1 for _k, _r, f in chunk if not f)
        return pushed

    def _revert(self, recs: list[Any], ids: dict[tuple[str, str], list[int]]) -> None:
        """Undo local edits the server refuses (read-only role): restore the last synchronised version."""
        T = self.T
        with self.active.db.tx() as conn, self._guard(conn):
            for k, _rec, _flag in recs:
                shadow = conn.execute(
                    select(T.sync_shadow.c.payload).where(
                        T.sync_shadow.c.kind == k[0], T.sync_shadow.c.entity_id == k[1]
                    )
                ).scalar()
                if shadow:
                    entities.apply(conn, T, self.uid, k[0], k[1], json.loads(shadow))
                else:
                    entities.remove(conn, T, self.uid, k[0], k[1])
                conn.execute(update(T.sync_outbox).where(T.sync_outbox.c.id.in_(ids[k])).values(pushed_at=now_iso()))

    # ------------------------------------------------------------ conflicts
    def conflicts(self) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.read() as conn:
            rows = (
                conn.execute(
                    select(T.sync_conflicts)
                    .where(T.sync_conflicts.c.resolved_at.is_(None))
                    .order_by(T.sync_conflicts.c.id)
                )
                .mappings()
                .all()
            )
        return [
            {
                "id": r["id"],
                "kind": r["entity_table"],
                "entity_id": r["entity_id"],
                "detected_at": r["detected_at"],
                "local": json.loads(r["local_payload"]),
                "remote": json.loads(r["remote_payload"]),
            }
            for r in rows
        ]

    def resolve(self, conflict_id: int, choice: str) -> dict[str, Any]:
        """Keep this device's text or the other one; the choice is then sent to every device."""
        if choice not in ("local", "remote"):
            raise ValidationFailed("choose local or remote", code="sync_choice_invalid")
        T = self.T
        with self.active.db.tx() as conn:
            row = conn.execute(select(T.sync_conflicts).where(T.sync_conflicts.c.id == conflict_id)).mappings().first()
            if row is None or row["resolved_at"]:
                raise NotFound("conflict not found", code="sync_conflict_not_found")
            local, remote = json.loads(row["local_payload"]), json.loads(row["remote_payload"])
            kind, ident, field = row["entity_table"], row["entity_id"], local.get("field")
            if field != "*":
                current = entities.serialize(conn, T, self.uid, kind, ident)
                if current is not None:
                    if choice == "remote":
                        current[field] = remote.get("value")
                    entities.apply(conn, T, self.uid, kind, ident, current)  # captured: sent to the other devices
                    clock = int(conn.execute(select(T.sync_state.c.lamport_clock)).scalar() or 0) + 1
                    conn.execute(update(T.sync_state).values(lamport_clock=clock))
                    conn.execute(
                        insert(T.sync_outbox).values(
                            user_id=self.uid, entity_table=kind, entity_id=ident, operation="upsert", lamport=clock
                        )
                    )
            conn.execute(
                update(T.sync_conflicts)
                .where(T.sync_conflicts.c.id == conflict_id)
                .values(resolution=choice, resolved_at=now_iso())
            )
        return {"id": conflict_id, "resolution": choice}

    # ------------------------------------------------------------ organisations
    async def _sync_org_keys(self, c: SyncClient) -> list[dict[str, Any]]:
        """Receive organisation keys, rotate after a departure, hand the key to new members (D-33)."""
        orgs = (await c.call("GET", "/orgs"))["items"]
        with self.active.db.read() as conn:
            identity = self._key(conn, "identity", "identity")
        if identity is None:
            return []
        for o in orgs:
            with self.active.db.tx() as conn:
                for version, envelope in o["envelopes"].items():
                    if self._key(conn, "org", o["id"], int(version)) is None:
                        self._put_key(conn, "org", o["id"], crypto.unseal(identity, envelope), int(version))
                self._ensure_local_org(conn, o["id"])
            if o["role"] in MANAGERS:
                members = await c.call("GET", f"/orgs/{o['id']}/members")
                if o["rotation_needed"]:
                    new = crypto.new_key()
                    envs = {
                        m["account_id"]: crypto.seal(m["identity_public_key"], new)
                        for m in members["items"]
                        if m["identity_public_key"]
                    }
                    if len(envs) == len(members["items"]):
                        await c.call(
                            "PUT", f"/orgs/{o['id']}/keys", {"key_version": o["key_version"] + 1, "envelopes": envs}
                        )
                        with self.active.db.tx() as conn:
                            self._put_key(conn, "org", o["id"], new, o["key_version"] + 1)
                        o["key_version"] += 1
                else:
                    with self.active.db.read() as conn:
                        current = self._key(conn, "org", o["id"], o["key_version"])
                    missing = (
                        {
                            m["account_id"]: crypto.seal(m["identity_public_key"], current)
                            for m in members["items"]
                            if not m["has_current_key"] and m["identity_public_key"]
                        }
                        if current
                        else {}
                    )
                    if missing:
                        await c.call(
                            "PUT", f"/orgs/{o['id']}/keys", {"key_version": o["key_version"], "envelopes": missing}
                        )
        return list(orgs)

    def _ensure_local_org(self, conn: Connection, remote_id: str) -> None:
        T = self.T
        if conn.execute(select(T.organizations.c.id).where(T.organizations.c.remote_id == remote_id)).first() is None:
            with self._guard(conn):
                # Placeholder until the organisation card arrives in the organisation scope.
                conn.execute(
                    insert(T.organizations).values(
                        id=uuid7(), remote_id=remote_id, created_by=self.uid, name="…", org_type="other"
                    )
                )

    async def create_org(self, fields: dict[str, Any]) -> dict[str, Any]:
        """EF-17.01: the creator is owner and gets the first organisation key."""
        async with self._client() as c:
            org = await c.call("POST", "/orgs")
            account = await c.call("GET", "/account")
            key = crypto.new_key()
            await c.call(
                "PUT",
                f"/orgs/{org['id']}/keys",
                {"key_version": 1, "envelopes": {account["id"]: crypto.seal(account["identity_public_key"], key)}},
            )
        T = self.T
        with self.active.db.tx() as conn:
            self._put_key(conn, "org", org["id"], key, 1)
            local = uuid7()
            conn.execute(
                insert(T.organizations).values(
                    id=local,
                    remote_id=org["id"],
                    created_by=self.uid,
                    **{k: fields.get(k) for k in entities.ORG_FIELDS if k in fields},
                )
            )
            clock = int(conn.execute(select(T.sync_state.c.lamport_clock)).scalar() or 0) + 1
            conn.execute(update(T.sync_state).values(lamport_clock=clock))
            conn.execute(
                insert(T.sync_outbox).values(
                    user_id=self.uid, entity_table="org", entity_id=org["id"], operation="upsert", lamport=clock
                )
            )
        return {"id": local, "remote_id": org["id"], "role": "owner"}

    def local_orgs(self) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.read() as conn:
            return [
                dict(r)
                for r in conn.execute(
                    select(T.organizations)
                    .where(T.organizations.c.remote_id.is_not(None))
                    .order_by(T.organizations.c.name)
                ).mappings()
            ]

    def _remote_of(self, org_id: str) -> str:
        with self.active.db.read() as conn:
            remote = conn.execute(
                select(self.T.organizations.c.remote_id).where(self.T.organizations.c.id == org_id)
            ).scalar()
        if not remote:
            raise NotFound("organisation not found", code="org_not_found")
        return str(remote)

    async def orgs(self) -> list[dict[str, Any]]:
        async with self._client() as c:
            remote = {o["id"]: o for o in (await c.call("GET", "/orgs"))["items"]}
        out = []
        for o in self.local_orgs():
            r = remote.get(o["remote_id"])
            if r:
                out.append(
                    {k: o[k] for k in ("id", "remote_id", *entities.ORG_FIELDS)}
                    | {"role": r["role"], "key_version": r["key_version"]}
                )
        return out

    async def invite(self, org_id: str, email: str | None, role: str) -> dict[str, Any]:
        async with self._client() as c:
            return dict(
                await c.call("POST", f"/orgs/{self._remote_of(org_id)}/invites", {"email": email, "role": role})
            )

    async def join(self, token: str) -> dict[str, Any]:
        async with self._client() as c:
            joined = await c.call("POST", "/invites/accept", {"token": token.strip()})
        with self.active.db.tx() as conn:
            self._ensure_local_org(conn, joined["org_id"])
        return dict(joined)

    async def members(self, org_id: str) -> dict[str, Any]:
        async with self._client() as c:
            data = await c.call("GET", f"/orgs/{self._remote_of(org_id)}/members")
        for m in data["items"]:
            m["key_fingerprint"] = (
                crypto.pairing_code(m["identity_public_key"]) if m.get("identity_public_key") else None
            )
        return dict(data)

    async def set_role(self, org_id: str, account_id: str, role: str) -> dict[str, Any]:
        async with self._client() as c:
            return dict(await c.call("PATCH", f"/orgs/{self._remote_of(org_id)}/members/{account_id}", {"role": role}))

    async def remove_member(self, org_id: str, account_id: str) -> None:
        async with self._client() as c:
            await c.call("DELETE", f"/orgs/{self._remote_of(org_id)}/members/{account_id}")

    async def leave(self, org_id: str) -> dict[str, Any]:
        """EF-17.12: leave and keep a personal copy of the shared workspaces and saved opportunities."""
        remote = self._remote_of(org_id)
        async with self._client() as c:
            account = await c.call("GET", "/account")
            await c.call("DELETE", f"/orgs/{remote}/members/{account['id']}")
        T = self.T
        with self.active.db.tx() as conn:
            kept = 0
            for table in (T.research_workspaces, T.saved_opportunities):
                kept += (
                    conn.execute(
                        update(table).where(table.c.organization_id == org_id).values(organization_id=None)
                    ).rowcount
                    or 0
                )
            conn.execute(delete(T.sync_keys).where(T.sync_keys.c.kind == "org", T.sync_keys.c.ref == remote))
            conn.execute(delete(T.sync_cursors).where(T.sync_cursors.c.scope == f"org:{remote}"))
            conn.execute(delete(T.sync_shadow).where(T.sync_shadow.c.scope == f"org:{remote}"))
            with self._guard(conn):
                conn.execute(delete(T.organizations).where(T.organizations.c.id == org_id))
        return {"left": True, "kept_items": kept}

    async def audit(self, org_id: str) -> list[dict[str, Any]]:
        async with self._client() as c:
            return list((await c.call("GET", f"/orgs/{self._remote_of(org_id)}/audit"))["items"])

    def share(self, kind: str, ident: str, org_id: str | None) -> dict[str, Any]:
        """Move a workspace or saved opportunity into an organisation (or back to personal)."""
        T = self.T
        table = {"workspace": T.research_workspaces, "saved": T.saved_opportunities}.get(kind)
        if table is None:
            raise ValidationFailed(
                "only workspaces and saved opportunities can be shared", code="sync_share_kind_invalid"
            )
        with self.active.db.tx() as conn:
            if (
                org_id is not None
                and conn.execute(
                    select(T.organizations.c.id).where(
                        T.organizations.c.id == org_id, T.organizations.c.remote_id.is_not(None)
                    )
                ).first()
                is None
            ):
                raise NotFound("organisation not found", code="org_not_found")
            r = conn.execute(
                update(table).where(table.c.id == ident, table.c.user_id == self.uid).values(organization_id=org_id)
            )
            if not r.rowcount:
                raise NotFound("item not found", code="sync_share_item_not_found")
            if kind == "saved":  # children follow their parent's scope
                clock = int(conn.execute(select(T.sync_state.c.lamport_clock)).scalar() or 0)
                for child_kind, child_table in (
                    ("application", T.applications),
                    ("note", T.application_notes),
                    ("document", T.generated_documents),
                ):
                    for (cid,) in conn.execute(select(child_table.c.id).where(child_table.c.saved_id == ident)):
                        clock += 1
                        conn.execute(
                            insert(T.sync_outbox).values(
                                user_id=self.uid,
                                entity_table=child_kind,
                                entity_id=cid,
                                operation="upsert",
                                lamport=clock,
                            )
                        )
                conn.execute(update(T.sync_state).values(lamport_clock=clock))
        return {"kind": kind, "id": ident, "organization_id": org_id}


async def run_if_linked(active: ActiveProfile, state: EngineState) -> dict[str, Any] | None:
    """Background round used by the scheduler; silent when sync is not linked or offline."""
    svc = SyncService(active, state)
    if svc._state_row() is None:
        return None
    try:
        return await svc.run()
    except SyncError as exc:
        log.info("sync_round_skipped", code=exc.code)
        return None
    except asyncio.CancelledError:
        raise
