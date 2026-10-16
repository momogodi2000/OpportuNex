"""Provider adapters (arch §7.1, EF-14.01): one per API family; each only returns model text.

* ``openai_compatible`` family: OpenAI-style ``/chat/completions`` — also Mistral, Groq, OpenRouter, LM Studio.
* ``gemini``: Google Generative Language ``generateContent``.
* ``anthropic``: Messages API.
* ``ollama``: local ``/api/chat``.

No adapter exposes tools or functions to the model (arch §7.2-3): it can only answer with text.
"""

from __future__ import annotations

import ipaddress
import re
from dataclasses import dataclass
from typing import Any
from urllib.parse import urlsplit

import httpx

from core.version import PROJECT_URL

KINDS = ("openai_compatible", "mistral", "groq", "openrouter", "gemini", "anthropic", "ollama", "lmstudio")
LOCAL_KINDS = frozenset({"ollama", "lmstudio"})
KEY_REQUIRED = frozenset({"mistral", "groq", "openrouter", "gemini", "anthropic"})
DEFAULT_BASE = {
    "mistral": "https://api.mistral.ai/v1",
    "groq": "https://api.groq.com/openai/v1",
    "openrouter": "https://openrouter.ai/api/v1",
    "gemini": "https://generativelanguage.googleapis.com/v1beta",
    "anthropic": "https://api.anthropic.com/v1",
    "ollama": "http://127.0.0.1:11434",
    "lmstudio": "http://127.0.0.1:1234/v1",
}
OPENAI_FAMILY = frozenset({"openai_compatible", "mistral", "groq", "openrouter", "lmstudio"})
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
_LOOPBACK_NAMES = {"localhost"}


class ProviderError(Exception):
    """``code``: rate_limited, timeout, auth, server, network, bad_response or http_<status>."""

    def __init__(self, code: str, detail: str = "", retry_after: float | None = None) -> None:
        super().__init__(code)
        self.code = code
        self.detail = detail[:300]
        self.retry_after = retry_after

    @property
    def retryable(self) -> bool:
        return self.code in ("timeout", "server", "network")


@dataclass(frozen=True)
class ProviderConfig:
    kind: str
    model: str
    base_url: str
    api_key: str | None = None
    timeout: float = 60.0


@dataclass(frozen=True)
class Completion:
    text: str
    prompt_tokens: int | None = None
    completion_tokens: int | None = None


def is_loopback(url: str) -> bool:
    host = (urlsplit(url).hostname or "").lower()
    if host in _LOOPBACK_NAMES:
        return True
    try:
        return ipaddress.ip_address(host).is_loopback
    except ValueError:
        return False


def resolve_base_url(kind: str, base_url: str | None) -> str:
    """Remote endpoints must use HTTPS; plain HTTP is accepted only on this computer (Ollama, LM Studio...)."""
    url = (base_url or DEFAULT_BASE.get(kind) or "").strip().rstrip("/")
    if not url:
        raise ValueError("base_url_required")
    parts = urlsplit(url)
    if parts.scheme not in ("http", "https") or not parts.hostname or parts.username or parts.password:
        raise ValueError("base_url_invalid")
    if parts.scheme == "http" and not is_loopback(url):
        raise ValueError("base_url_insecure")
    return url


def is_local(kind: str, base_url: str) -> bool:
    """Local models never send data off the computer, so they need no consent (EF-14.09)."""
    return kind in LOCAL_KINDS or (kind == "openai_compatible" and is_loopback(base_url))


def _headers(cfg: ProviderConfig) -> dict[str, str]:
    h = {"Content-Type": "application/json", "Accept": "application/json"}
    if cfg.kind == "anthropic":
        h["anthropic-version"] = "2023-06-01"
        if cfg.api_key:
            h["x-api-key"] = cfg.api_key
    elif cfg.kind == "gemini":
        if cfg.api_key:
            h["x-goog-api-key"] = cfg.api_key
    elif cfg.api_key:
        h["Authorization"] = f"Bearer {cfg.api_key}"
    if cfg.kind == "openrouter":
        h["HTTP-Referer"] = PROJECT_URL
        h["X-Title"] = "Opportunex"
    return h


def _retry_after(resp: httpx.Response) -> float | None:
    raw = resp.headers.get("retry-after")
    try:
        return max(0.0, float(raw)) if raw else None
    except ValueError:
        return None


async def _request(client: httpx.AsyncClient, method: str, url: str, cfg: ProviderConfig, body: Any = None) -> Any:
    try:
        resp = await client.request(method, url, headers=_headers(cfg), json=body, timeout=cfg.timeout)
    except httpx.TimeoutException as exc:
        raise ProviderError("timeout", type(exc).__name__) from exc
    except httpx.HTTPError as exc:
        raise ProviderError("network", type(exc).__name__) from exc
    if resp.status_code == 429:
        raise ProviderError("rate_limited", "429", _retry_after(resp))
    if resp.status_code in (401, 403):
        raise ProviderError("auth", str(resp.status_code))
    if resp.status_code >= 500:
        raise ProviderError("server", str(resp.status_code))
    if resp.status_code >= 400:
        raise ProviderError(f"http_{resp.status_code}", resp.text[:200])
    if len(resp.content) > MAX_RESPONSE_BYTES:
        raise ProviderError("bad_response", "oversize")
    try:
        return resp.json()
    except ValueError as exc:
        raise ProviderError("bad_response", "not json") from exc


def _int(v: Any) -> int | None:
    return v if isinstance(v, int) else None


async def complete(client: httpx.AsyncClient, cfg: ProviderConfig, system: str, user: str) -> Completion:
    """One deterministic (temperature 0) JSON-oriented completion."""
    base = cfg.base_url
    try:
        if cfg.kind in OPENAI_FAMILY:
            body: dict[str, Any] = {
                "model": cfg.model,
                "temperature": 0,
                "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
            }
            if cfg.kind != "lmstudio":  # LM Studio rejects json_object; the prompt still demands JSON
                body["response_format"] = {"type": "json_object"}
            data = await _request(client, "POST", f"{base}/chat/completions", cfg, body)
            usage = data.get("usage") or {}
            return Completion(
                data["choices"][0]["message"]["content"] or "",
                _int(usage.get("prompt_tokens")),
                _int(usage.get("completion_tokens")),
            )
        if cfg.kind == "anthropic":
            body = {
                "model": cfg.model,
                "max_tokens": 4096,
                "temperature": 0,
                "system": system,
                "messages": [{"role": "user", "content": user}],
            }
            data = await _request(client, "POST", f"{base}/messages", cfg, body)
            usage = data.get("usage") or {}
            text = "".join(p.get("text", "") for p in data.get("content", []) if p.get("type") == "text")
            return Completion(text, _int(usage.get("input_tokens")), _int(usage.get("output_tokens")))
        if cfg.kind == "gemini":
            body = {
                "systemInstruction": {"parts": [{"text": system}]},
                "contents": [{"role": "user", "parts": [{"text": user}]}],
                "generationConfig": {"temperature": 0, "responseMimeType": "application/json"},
            }
            model = cfg.model.removeprefix("models/")
            data = await _request(client, "POST", f"{base}/models/{model}:generateContent", cfg, body)
            usage = data.get("usageMetadata") or {}
            parts = data["candidates"][0]["content"]["parts"]
            return Completion(
                "".join(p.get("text", "") for p in parts),
                _int(usage.get("promptTokenCount")),
                _int(usage.get("candidatesTokenCount")),
            )
        if cfg.kind == "ollama":
            body = {
                "model": cfg.model,
                "stream": False,
                "format": "json",
                "options": {"temperature": 0},
                "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
            }
            data = await _request(client, "POST", f"{base}/api/chat", cfg, body)
            return Completion(
                data["message"]["content"] or "", _int(data.get("prompt_eval_count")), _int(data.get("eval_count"))
            )
    except (KeyError, IndexError, TypeError) as exc:
        raise ProviderError("bad_response", type(exc).__name__) from exc
    raise ProviderError("bad_response", f"unsupported kind {cfg.kind}")


async def list_models(client: httpx.AsyncClient, cfg: ProviderConfig) -> list[str]:
    """EF-14.03: also serves as the connection test (no personal data is sent)."""
    base = cfg.base_url
    try:
        if cfg.kind in OPENAI_FAMILY or cfg.kind == "anthropic":
            data = await _request(client, "GET", f"{base}/models", cfg)
            names = [m["id"] for m in data.get("data", [])]
        elif cfg.kind == "gemini":
            data = await _request(client, "GET", f"{base}/models", cfg)
            names = [m["name"].removeprefix("models/") for m in data.get("models", [])]
        elif cfg.kind == "ollama":
            data = await _request(client, "GET", f"{base}/api/tags", cfg)
            names = [m["name"] for m in data.get("models", [])]
        else:
            raise ProviderError("bad_response", f"unsupported kind {cfg.kind}")
    except (KeyError, TypeError, AttributeError) as exc:
        raise ProviderError("bad_response", type(exc).__name__) from exc
    return sorted({str(n) for n in names})[:500]


_FENCE = re.compile(r"^\s*```(?:json)?\s*|\s*```\s*$", re.IGNORECASE)


def strip_fences(text: str) -> str:
    """Some models wrap JSON in Markdown fences even when asked not to."""
    return _FENCE.sub("", text.strip())
