"""AI provider configuration (M14): providers, keys in the keychain, routing, consent, usage."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
from sqlalchemy import delete, func, insert, select, update

from ai.gateway import POLICY_VERSION, setting_enabled
from ai.providers import (
    KEY_REQUIRED,
    KINDS,
    ProviderConfig,
    ProviderError,
    is_local,
    list_models,
    resolve_base_url,
)
from ai.secrets import SecretStoreError, provider_ref
from core.errors import NotFound, ValidationFailed
from core.ids import uuid7
from core.timeutil import now_iso
from services.state import ActiveProfile, EngineState

TASKS = (
    "query_interpretation",
    "extraction",
    "classification",
    "summarization",
    "matching_explanation",
    "cv_parsing",
    "document_drafting",
    "translation",
)
AI_PURPOSES = ("ai_remote_processing", "profile_to_ai", "cv_parsing_ai")
_PUBLIC = (
    "id",
    "kind",
    "display_name",
    "base_url",
    "model",
    "is_local",
    "enabled",
    "fallback_order",
    "timeout_seconds",
    "max_retries",
    "daily_call_cap",
    "last_test_at",
    "last_test_ok",
)


class AIService:
    def __init__(self, active: ActiveProfile, state: EngineState) -> None:
        self.active = active
        self.state = state
        self.T = active.tables
        self.uid = active.user_id

    # -------------------------------------------------------------- settings
    def settings(self) -> dict[str, Any]:
        T = self.T
        with self.active.db.read() as conn:
            enabled = setting_enabled(conn, T)
            routing = dict(
                conn.execute(
                    select(T.ai_task_routing.c.task, T.ai_task_routing.c.provider_id).where(
                        T.ai_task_routing.c.user_id == self.uid
                    )
                ).all()
            )
        return {"enabled": enabled, "routing": routing, "tasks": list(TASKS), "kinds": list(KINDS)}

    def set_enabled(self, enabled: bool) -> dict[str, Any]:
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(delete(T.application_settings).where(T.application_settings.c.key == "ai.enabled"))
            conn.execute(
                insert(T.application_settings).values(
                    key="ai.enabled",
                    value="true" if enabled else "false",
                    value_type="boolean",
                    description="AI features (off by default)",
                )
            )
        return self.settings()

    def set_routing(self, task: str, provider_id: str | None) -> dict[str, Any]:
        if task not in TASKS:
            raise ValidationFailed("unknown AI task", code="ai_task_invalid")
        T = self.T
        with self.active.db.tx() as conn:
            conn.execute(
                delete(T.ai_task_routing).where(
                    T.ai_task_routing.c.user_id == self.uid, T.ai_task_routing.c.task == task
                )
            )
            if provider_id:
                self._row(conn, provider_id)
                conn.execute(insert(T.ai_task_routing).values(user_id=self.uid, task=task, provider_id=provider_id))
        return self.settings()

    # ------------------------------------------------------------- providers
    def _row(self, conn: Any, provider_id: str) -> dict[str, Any]:
        T = self.T
        row = (
            conn.execute(
                select(T.ai_providers).where(T.ai_providers.c.id == provider_id, T.ai_providers.c.user_id == self.uid)
            )
            .mappings()
            .first()
        )
        if row is None:
            raise NotFound("AI provider not found", code="ai_provider_not_found")
        return dict(row)

    def _public(self, row: dict[str, Any], consents: set[str]) -> dict[str, Any]:
        out = {k: row[k] for k in _PUBLIC}
        for k in ("is_local", "enabled"):
            out[k] = bool(out[k])
        out["last_test_ok"] = None if row["last_test_ok"] is None else bool(row["last_test_ok"])
        has_key = False
        if row["keychain_ref"]:
            try:
                has_key = bool(self.state.secrets.get(row["keychain_ref"]))
            except SecretStoreError:
                has_key = False
        out["has_key"] = has_key
        out["key_required"] = row["kind"] in KEY_REQUIRED
        out["consents"] = sorted(consents)
        return out

    def list_items(self) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.read() as conn:
            rows = [
                dict(r)
                for r in conn.execute(
                    select(T.ai_providers)
                    .where(T.ai_providers.c.user_id == self.uid)
                    .order_by(T.ai_providers.c.fallback_order)
                ).mappings()
            ]
            consents: dict[str, set[str]] = {}
            for target, purpose in conn.execute(
                select(T.consents.c.target, T.consents.c.purpose).where(
                    T.consents.c.user_id == self.uid,
                    T.consents.c.granted == 1,
                    T.consents.c.revoked_at.is_(None),
                    T.consents.c.purpose.in_(AI_PURPOSES),
                )
            ):
                consents.setdefault(target, set()).add(purpose)
        return [self._public(r, consents.get(r["id"], set())) for r in rows]

    def get(self, provider_id: str) -> dict[str, Any]:
        with self.active.db.read() as conn:
            self._row(conn, provider_id)
        return next(p for p in self.list_items() if p["id"] == provider_id)

    def create(
        self,
        *,
        kind: str,
        display_name: str,
        model: str,
        base_url: str | None,
        api_key: str | None,
        timeout_seconds: int,
        max_retries: int,
        daily_call_cap: int | None,
    ) -> dict[str, Any]:
        if kind not in KINDS:
            raise ValidationFailed("unsupported AI provider", code="ai_kind_invalid")
        try:
            url = resolve_base_url(kind, base_url)
        except ValueError as exc:
            raise ValidationFailed("invalid provider address", code=f"ai_{exc}") from exc
        if kind in KEY_REQUIRED and not api_key:
            raise ValidationFailed("this provider needs an API key", code="ai_api_key_required")
        pid = uuid7()
        ref = provider_ref(self.uid, pid) if api_key else None
        local = is_local(kind, url)
        T = self.T
        if ref and api_key:
            self._store_key(ref, api_key)
        try:
            with self.active.db.tx() as conn:
                order = int(
                    conn.execute(
                        select(func.coalesce(func.max(T.ai_providers.c.fallback_order), 0)).where(
                            T.ai_providers.c.user_id == self.uid
                        )
                    ).scalar()
                    or 0
                )
                conn.execute(
                    insert(T.ai_providers).values(
                        id=pid,
                        user_id=self.uid,
                        kind=kind,
                        display_name=display_name.strip()[:80] or kind,
                        base_url=url,
                        model=model.strip(),
                        keychain_ref=ref,
                        is_local=1 if local else 0,
                        fallback_order=order + 1,
                        timeout_seconds=timeout_seconds,
                        max_retries=max_retries,
                        daily_call_cap=daily_call_cap,
                    )
                )
        except BaseException:
            if ref:
                self._drop_key(ref)
            raise
        return self.get(pid)

    def update(self, provider_id: str, values: dict[str, Any]) -> dict[str, Any]:
        T = self.T
        api_key = values.pop("api_key", None)
        with self.active.db.read() as conn:
            row = self._row(conn, provider_id)
        changes: dict[str, Any] = {}
        for k in ("display_name", "model", "timeout_seconds", "max_retries", "daily_call_cap"):
            if k in values and values[k] is not None:
                changes[k] = values[k]
        if "enabled" in values and values["enabled"] is not None:
            changes["enabled"] = 1 if values["enabled"] else 0
        if values.get("base_url") is not None:
            try:
                changes["base_url"] = resolve_base_url(row["kind"], values["base_url"])
            except ValueError as exc:
                raise ValidationFailed("invalid provider address", code=f"ai_{exc}") from exc
            changes["is_local"] = 1 if is_local(row["kind"], changes["base_url"]) else 0
        if api_key:
            ref = row["keychain_ref"] or provider_ref(self.uid, provider_id)
            self._store_key(ref, api_key)
            changes["keychain_ref"] = ref
        if changes:
            with self.active.db.tx() as conn:
                conn.execute(
                    update(T.ai_providers)
                    .where(T.ai_providers.c.id == provider_id)
                    .values(**changes, updated_at=now_iso())
                )
        return self.get(provider_id)

    def reorder(self, ids: list[str]) -> list[dict[str, Any]]:
        """EF-14.04: the fallback chain follows the given order."""
        T = self.T
        with self.active.db.tx() as conn:
            existing = [
                r[0]
                for r in conn.execute(
                    select(T.ai_providers.c.id)
                    .where(T.ai_providers.c.user_id == self.uid)
                    .order_by(T.ai_providers.c.fallback_order)
                )
            ]
            if sorted(ids) != sorted(existing):
                raise ValidationFailed("the order must list every provider once", code="ai_order_invalid")
            # Two passes keep UNIQUE(user_id, fallback_order) satisfied at every step.
            for i, pid in enumerate(ids, start=1):
                conn.execute(update(T.ai_providers).where(T.ai_providers.c.id == pid).values(fallback_order=1000 + i))
            for i, pid in enumerate(ids, start=1):
                conn.execute(update(T.ai_providers).where(T.ai_providers.c.id == pid).values(fallback_order=i))
        return self.list_items()

    def delete(self, provider_id: str) -> None:
        T = self.T
        with self.active.db.tx() as conn:
            row = self._row(conn, provider_id)
            conn.execute(delete(T.ai_providers).where(T.ai_providers.c.id == provider_id))
        if row["keychain_ref"]:
            self._drop_key(row["keychain_ref"])

    def forget_all_keys(self) -> None:
        """Called before an account is deleted: keys live outside the encrypted database."""
        T = self.T
        with self.active.db.read() as conn:
            refs = [
                r[0]
                for r in conn.execute(select(T.ai_providers.c.keychain_ref).where(T.ai_providers.c.user_id == self.uid))
                if r[0]
            ]
        for ref in refs:
            self._drop_key(ref)

    def _store_key(self, ref: str, key: str) -> None:
        key = key.strip()
        if len(key) < 8 or len(key) > 400 or any(c.isspace() for c in key):
            raise ValidationFailed("the API key looks malformed", code="ai_api_key_invalid")
        try:
            self.state.secrets.set(ref, key)
        except SecretStoreError as exc:
            raise ValidationFailed("the system keychain is unavailable", code="keychain_unavailable") from exc

    def _drop_key(self, ref: str) -> None:
        try:
            self.state.secrets.delete(ref)
        except SecretStoreError:
            return

    async def test(self, provider_id: str) -> dict[str, Any]:
        """EF-14.03: list the models; nothing personal is sent."""
        with self.active.db.read() as conn:
            row = self._row(conn, provider_id)
        try:
            key = self.state.secrets.get(row["keychain_ref"]) if row["keychain_ref"] else None
        except SecretStoreError as exc:
            raise ValidationFailed("the system keychain is unavailable", code="keychain_unavailable") from exc
        cfg = ProviderConfig(row["kind"], row["model"], row["base_url"], key, float(row["timeout_seconds"]))
        models: list[str] = []
        error: str | None = None
        try:
            async with httpx.AsyncClient(follow_redirects=False, trust_env=False) as client:
                models = await list_models(client, cfg)
        except ProviderError as exc:
            error = exc.code
        ok = error is None
        with self.active.db.tx() as conn:
            conn.execute(
                update(self.T.ai_providers)
                .where(self.T.ai_providers.c.id == provider_id)
                .values(last_test_at=now_iso(), last_test_ok=1 if ok else 0)
            )
        return {"ok": ok, "error": error, "models": models, "model_listed": row["model"] in models}

    # -------------------------------------------------------------- consent
    def grant(self, provider_id: str, purposes: list[str]) -> dict[str, Any]:
        """EF-14.09: explicit, per-provider consent, recorded with the policy version."""
        if not purposes or any(p not in AI_PURPOSES for p in purposes):
            raise ValidationFailed("unknown consent purpose", code="consent_purpose_invalid")
        T = self.T
        with self.active.db.tx() as conn:
            self._row(conn, provider_id)
            for purpose in dict.fromkeys(purposes):
                active = conn.execute(
                    select(T.consents.c.id).where(
                        T.consents.c.user_id == self.uid,
                        T.consents.c.purpose == purpose,
                        T.consents.c.target == provider_id,
                        T.consents.c.granted == 1,
                        T.consents.c.revoked_at.is_(None),
                    )
                ).first()
                if active is None:
                    conn.execute(
                        insert(T.consents).values(
                            id=uuid7(),
                            user_id=self.uid,
                            purpose=purpose,
                            target=provider_id,
                            policy_version=POLICY_VERSION,
                            granted=1,
                        )
                    )
        return self.get(provider_id)

    # ---------------------------------------------------------------- usage
    def usage(self, days: int = 30) -> dict[str, Any]:
        """EF-14.07: calls, estimated tokens, errors and cache hits per provider and day."""
        T = self.T
        since = (datetime.now(UTC) - timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%SZ")
        day = func.substr(T.ai_usage_logs.c.created_at, 1, 10)
        with self.active.db.read() as conn:
            rows = conn.execute(
                select(
                    day.label("day"),
                    T.ai_usage_logs.c.provider_id,
                    T.ai_usage_logs.c.outcome,
                    func.count().label("calls"),
                    func.coalesce(func.sum(T.ai_usage_logs.c.prompt_tokens), 0).label("prompt_tokens"),
                    func.coalesce(func.sum(T.ai_usage_logs.c.completion_tokens), 0).label("completion_tokens"),
                )
                .where(T.ai_usage_logs.c.user_id == self.uid, T.ai_usage_logs.c.created_at >= since)
                .group_by(day, T.ai_usage_logs.c.provider_id, T.ai_usage_logs.c.outcome)
                .order_by(day.desc())
            ).mappings()
            items = [dict(r) for r in rows]
        summary: dict[tuple[str, str | None], dict[str, Any]] = {}
        for r in items:
            key = (r["day"], r["provider_id"])
            s = summary.setdefault(
                key,
                {"day": r["day"], "provider_id": r["provider_id"], "calls": 0, "errors": 0, "cache_hits": 0,
                 "fallbacks": 0, "prompt_tokens": 0, "completion_tokens": 0},
            )  # fmt: skip
            if r["outcome"] == "cache_hit":
                s["cache_hits"] += r["calls"]
            elif r["outcome"] == "fallback":
                s["fallbacks"] += r["calls"]
            else:
                s["calls"] += r["calls"]
                if r["outcome"] != "ok":
                    s["errors"] += r["calls"]
            s["prompt_tokens"] += int(r["prompt_tokens"] or 0)
            s["completion_tokens"] += int(r["completion_tokens"] or 0)
        return {"days": days, "items": list(summary.values())}
