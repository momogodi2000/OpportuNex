"""AI gateway (arch §7.1-7.2, ADR-008, M14).

Order of operations for one task:

1. AI must be switched on (``ai.enabled``, off by default — D-15) and at least one provider enabled.
2. Providers are tried in order: the one routed to the task (EF-14.05), then the fallback chain (EF-14.04).
3. A remote provider is used only with the user's recorded consent for it (EF-14.09); local models need none.
4. Daily caps and temporary suspension after HTTP 429 are honoured (EF-14.06).
5. A cached validated answer for the same task, template version, model and content is reused (EF-14.08).
6. The answer must validate against a strict schema; one corrective retry, then the next provider,
   and finally ``None`` so the caller uses the deterministic path (EF-07.07).
7. Every attempt is logged in ``ai_usage_logs`` (EF-14.07); every send to a third party in
   ``data_disclosures`` (EF-18.07); suspected injections in ``security_events`` (arch §7.2-6).
"""

from __future__ import annotations

import asyncio
import hashlib
import json
import time
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
import structlog
from pydantic import BaseModel, ValidationError
from sqlalchemy import and_, func, insert, select

from ai.prompts import TEMPLATES, build, detect_injection
from ai.providers import KEY_REQUIRED, ProviderConfig, ProviderError, complete, strip_fences
from ai.secrets import SecretStoreError
from core.errors import Conflict
from services.state import ActiveProfile, EngineState

log = structlog.get_logger("ai")

CACHE_DAYS = 30
SUSPEND_DEFAULT_S = 60.0
POLICY_VERSION = "1.0"


class ConsentRequired(Conflict):
    """Raised to an interactive caller so the UI can ask before the first send (EF-14.09)."""


@dataclass(frozen=True)
class AIResult[M: BaseModel]:
    data: M
    provider_id: str
    provider_kind: str
    model: str
    prompt_version: str
    from_cache: bool


def setting_enabled(conn: Any, T: Any) -> bool:
    value = conn.execute(
        select(T.application_settings.c.value).where(T.application_settings.c.key == "ai.enabled")
    ).scalar()
    return value == "true"


class AIGateway:
    backoff_base = 0.5

    def __init__(self, active: ActiveProfile, state: EngineState) -> None:
        self.active = active
        self.state = state
        self.T = active.tables
        self.uid = active.user_id

    # ----------------------------------------------------------------- state
    def enabled(self) -> bool:
        with self.active.db.read() as conn:
            return setting_enabled(conn, self.T)

    def chain(self, task: str) -> list[dict[str, Any]]:
        T = self.T
        with self.active.db.read() as conn:
            rows = [
                dict(r)
                for r in conn.execute(
                    select(T.ai_providers)
                    .where(T.ai_providers.c.user_id == self.uid, T.ai_providers.c.enabled == 1)
                    .order_by(T.ai_providers.c.fallback_order)
                ).mappings()
            ]
            routed = conn.execute(
                select(T.ai_task_routing.c.provider_id).where(
                    T.ai_task_routing.c.user_id == self.uid, T.ai_task_routing.c.task == task
                )
            ).scalar()
        if routed:
            rows.sort(key=lambda r: 0 if r["id"] == routed else 1)
        return rows

    def missing_consents(self, provider_id: str, purposes: tuple[str, ...]) -> list[str]:
        T = self.T
        with self.active.db.read() as conn:
            granted = {
                r[0]
                for r in conn.execute(
                    select(T.consents.c.purpose).where(
                        T.consents.c.user_id == self.uid,
                        T.consents.c.target == provider_id,
                        T.consents.c.granted == 1,
                        T.consents.c.revoked_at.is_(None),
                    )
                )
            }
        return [p for p in purposes if p not in granted]

    def _consent_id(self, provider_id: str) -> str | None:
        T = self.T
        with self.active.db.read() as conn:
            return conn.execute(
                select(T.consents.c.id).where(
                    T.consents.c.user_id == self.uid,
                    T.consents.c.target == provider_id,
                    T.consents.c.purpose == "ai_remote_processing",
                    T.consents.c.granted == 1,
                    T.consents.c.revoked_at.is_(None),
                )
            ).scalar()

    def _calls_today(self, provider_id: str) -> int:
        T = self.T
        start = datetime.now(UTC).strftime("%Y-%m-%dT00:00:00Z")
        with self.active.db.read() as conn:
            return int(
                conn.execute(
                    select(func.count()).where(
                        and_(
                            T.ai_usage_logs.c.provider_id == provider_id,
                            T.ai_usage_logs.c.created_at >= start,
                            T.ai_usage_logs.c.outcome.notin_(("cache_hit", "fallback")),
                        )
                    )
                ).scalar()
                or 0
            )

    def _suspended(self, provider_id: str) -> bool:
        until = self.state.ai_suspended.get(provider_id, 0.0)
        return time.monotonic() < until

    # ----------------------------------------------------------------- writes
    def _log(self, provider: dict[str, Any] | None, task: str, outcome: str, **kw: Any) -> None:
        with self.active.db.tx() as conn:
            conn.execute(
                insert(self.T.ai_usage_logs).values(
                    user_id=self.uid,
                    provider_id=provider["id"] if provider else None,
                    task=task,
                    model=provider["model"] if provider else "deterministic",
                    outcome=outcome,
                    **kw,
                )
            )

    def _disclose(self, provider: dict[str, Any], category: str, size: int) -> None:
        consent_id = self._consent_id(provider["id"])
        with self.active.db.tx() as conn:
            conn.execute(
                insert(self.T.data_disclosures).values(
                    user_id=self.uid,
                    recipient=f"ai:{provider['kind']}:{provider['display_name']}"[:200],
                    data_category=category,
                    consent_id=consent_id,
                    byte_count=size,
                )
            )

    def _security(self, patterns: list[str], task: str) -> None:
        with self.active.db.tx() as conn:
            conn.execute(
                insert(self.T.security_events).values(
                    user_id=self.uid,
                    event_type="prompt_injection_suspected",
                    severity="medium",
                    detail=",".join(patterns)[:200],
                    related_ref=task,
                )
            )

    def _cache_get(self, key: str) -> str | None:
        T = self.T
        now = datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
        with self.active.db.read() as conn:
            return conn.execute(
                select(T.ai_cache.c.response).where(
                    T.ai_cache.c.cache_key == key, (T.ai_cache.c.expires_at.is_(None)) | (T.ai_cache.c.expires_at > now)
                )
            ).scalar()

    def _cache_put(self, key: str, task: str, version: str, model: str, response: str) -> None:
        T = self.T
        expires = (datetime.now(UTC) + timedelta(days=CACHE_DAYS)).strftime("%Y-%m-%dT%H:%M:%SZ")
        with self.active.db.tx() as conn:
            conn.execute(T.ai_cache.delete().where(T.ai_cache.c.cache_key == key))
            conn.execute(
                insert(T.ai_cache).values(
                    cache_key=key, task=task, prompt_version=version, model=model, response=response, expires_at=expires
                )
            )

    # ------------------------------------------------------------------- run
    def _client(self, local: bool) -> httpx.AsyncClient:
        from services.privacy_service import PrivacyService

        proxy = None if local else PrivacyService(self.active).network()["proxy_url"]
        return httpx.AsyncClient(proxy=proxy, follow_redirects=False, trust_env=False)

    async def run[M: BaseModel](
        self,
        task: str,
        *,
        data: str,
        schema: type[M],
        data_category: str,
        purposes: tuple[str, ...] = ("ai_remote_processing",),
        interactive: bool = False,
        params: dict[str, str] | None = None,
    ) -> AIResult[M] | None:
        """Return a validated answer, or ``None`` when the caller must use its deterministic path."""
        if not await asyncio.to_thread(self.enabled):
            return None
        providers = await asyncio.to_thread(self.chain, task)
        if not providers:
            return None
        template = TEMPLATES[task]
        system, user = build(template, data, schema, **(params or {}))
        patterns = detect_injection(data)
        if patterns:
            log.warning("prompt_injection_suspected", task=task, patterns=patterns)
            await asyncio.to_thread(self._security, patterns, task)
        content_hash = hashlib.sha256(
            json.dumps([data[: template.max_chars], params or {}], sort_keys=True, ensure_ascii=False).encode()
        ).hexdigest()

        for p in providers:
            local = bool(p["is_local"])
            if self._suspended(p["id"]):
                continue
            if p["daily_call_cap"] and await asyncio.to_thread(self._calls_today, p["id"]) >= p["daily_call_cap"]:
                continue
            if not local:
                missing = await asyncio.to_thread(self.missing_consents, p["id"], purposes)
                if missing:
                    if interactive:
                        raise ConsentRequired(
                            "consent required before sending data to this AI provider",
                            code="ai_consent_required",
                            extra={"provider_id": p["id"], "provider_name": p["display_name"], "purposes": missing},
                        )
                    continue
            key = hashlib.sha256(f"{task}|{template.version}|{p['model']}|{content_hash}".encode()).hexdigest()
            cached = await asyncio.to_thread(self._cache_get, key)
            if cached is not None:
                try:
                    obj = schema.model_validate_json(cached)
                except ValidationError:
                    obj = None
                if obj is not None:
                    await asyncio.to_thread(self._log, p, task, "cache_hit")
                    return AIResult(obj, p["id"], p["kind"], p["model"], template.version, True)
            try:
                api_key = self.state.secrets.get(p["keychain_ref"]) if p["keychain_ref"] else None
            except SecretStoreError as exc:
                await asyncio.to_thread(self._log, p, task, "error", error_code="keychain_unavailable")
                log.warning("ai_keychain_unavailable", error=str(exc))
                continue
            if p["kind"] in KEY_REQUIRED and not api_key:
                await asyncio.to_thread(self._log, p, task, "error", error_code="api_key_missing")
                continue
            cfg = ProviderConfig(p["kind"], p["model"], p["base_url"], api_key, float(p["timeout_seconds"]))
            if not local:
                await asyncio.to_thread(self._disclose, p, data_category, len(system) + len(user))
            obj = await self._call(p, cfg, task, system, user, schema, local)
            if obj is not None:
                await asyncio.to_thread(self._cache_put, key, task, template.version, p["model"], obj.model_dump_json())
                return AIResult(obj, p["id"], p["kind"], p["model"], template.version, False)
        await asyncio.to_thread(self._log, None, task, "fallback")
        return None

    async def _call[M: BaseModel](
        self,
        p: dict[str, Any],
        cfg: ProviderConfig,
        task: str,
        system: str,
        user: str,
        schema: type[M],
        local: bool,
    ) -> M | None:
        retries_left = int(p["max_retries"])
        corrected = False
        prompt = user
        async with self._client(local) as client:
            while True:
                t0 = time.monotonic()
                try:
                    comp = await complete(client, cfg, system, prompt)
                except ProviderError as exc:
                    latency = int((time.monotonic() - t0) * 1000)
                    outcome = {"rate_limited": "rate_limited", "timeout": "timeout"}.get(exc.code, "error")
                    await asyncio.to_thread(self._log, p, task, outcome, error_code=exc.code, latency_ms=latency)
                    if exc.code == "rate_limited":
                        self.state.ai_suspended[p["id"]] = time.monotonic() + (exc.retry_after or SUSPEND_DEFAULT_S)
                        return None
                    if exc.retryable and retries_left > 0:
                        retries_left -= 1
                        await asyncio.sleep(self.backoff_base * (2 ** (int(p["max_retries"]) - retries_left - 1)))
                        continue
                    return None
                latency = int((time.monotonic() - t0) * 1000)
                usage = {
                    "prompt_tokens": comp.prompt_tokens,
                    "completion_tokens": comp.completion_tokens,
                    "latency_ms": latency,
                }
                try:
                    obj = schema.model_validate_json(strip_fences(comp.text))
                except ValidationError as exc:
                    await asyncio.to_thread(self._log, p, task, "schema_invalid", error_code="schema", **usage)
                    if corrected:
                        return None
                    corrected = True
                    problems = "; ".join(
                        f"{'.'.join(str(x) for x in e['loc']) or 'racine'}: {e['msg']}" for e in exc.errors()[:8]
                    )
                    prompt = (
                        f"{user}\n\nTa réponse précédente ne respecte pas le schéma ({problems}). "
                        "Renvoie uniquement l'objet JSON corrigé."
                    )
                    continue
                await asyncio.to_thread(self._log, p, task, "ok", **usage)
                return obj
