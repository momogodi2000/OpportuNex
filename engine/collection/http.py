"""Polite, SSRF-guarded HTTP client for public sources (EF-05.06..08, EF-05.13, arch §9.3).

* Only http/https; every hop (including redirects, max 5) is resolved and checked: private,
  loopback, link-local, multicast, reserved, unspecified (0.0.0.0/::) and cloud-metadata
  addresses are refused. The connection is pinned to the vetted IP (no DNS rebinding).
* robots.txt is honoured (Protego) and cached; Crawl-delay is respected.
* At most one request at a time per domain, with >= 2 s between requests to a domain,
  and a global concurrency cap (8).
* Responses are capped (10 MB) and cached with ETag / Last-Modified validators.
* Transient failures (timeouts, 429, 5xx) are retried at most twice with exponential back-off.
"""

from __future__ import annotations

import asyncio
import hashlib
import ipaddress
import socket
import time
from collections.abc import Callable
from dataclasses import dataclass
from typing import Any
from urllib.parse import urljoin, urlsplit

import httpx
import structlog
from protego import Protego

from core.version import USER_AGENT

log = structlog.get_logger(__name__)

MAX_BYTES = 10 * 1024 * 1024
MAX_REDIRECTS = 5
TIMEOUT = 30.0
MIN_DELAY = 2.0
MAX_CONCURRENCY = 8
RETRIES = 2
METADATA_HOSTS = {"169.254.169.254", "100.100.100.200", "fd00:ec2::254", "metadata.google.internal"}


class FetchError(Exception):
    def __init__(self, code: str, detail: str = "") -> None:
        super().__init__(f"{code}: {detail}")
        self.code = code
        self.detail = detail


@dataclass
class FetchResult:
    url: str
    status: int
    content_type: str
    body: bytes
    from_cache: bool = False
    etag: str | None = None
    last_modified: str | None = None

    @property
    def text(self) -> str:
        charset = "utf-8"
        if "charset=" in self.content_type:
            charset = self.content_type.split("charset=")[-1].split(";")[0].strip() or "utf-8"
        try:
            return self.body.decode(charset, errors="replace")
        except LookupError:
            return self.body.decode("utf-8", errors="replace")


CacheGet = Callable[[str], dict[str, Any] | None]
CachePut = Callable[[str, FetchResult], None]


def url_hash(url: str) -> str:
    return hashlib.sha256(url.encode("utf-8")).hexdigest()


def _ip_allowed(ip: ipaddress.IPv4Address | ipaddress.IPv6Address) -> bool:
    if isinstance(ip, ipaddress.IPv6Address) and ip.ipv4_mapped:
        ip = ip.ipv4_mapped
    return not (
        ip.is_private
        or ip.is_loopback
        or ip.is_link_local
        or ip.is_multicast
        or ip.is_reserved
        or ip.is_unspecified
        or str(ip) in METADATA_HOSTS
    )


async def resolve_public(host: str, port: int, *, allow_private: bool = False) -> str:
    """Resolve ``host`` and return one vetted IP address (all answers must be public)."""
    if host.lower() in METADATA_HOSTS:
        raise FetchError("ssrf_blocked", host)
    try:
        infos = await asyncio.get_running_loop().getaddrinfo(host, port, type=socket.SOCK_STREAM)
    except socket.gaierror as exc:
        raise FetchError("dns_failed", host) from exc
    addresses = [ipaddress.ip_address(info[4][0]) for info in infos]
    if not addresses:
        raise FetchError("dns_failed", host)
    if not allow_private and not all(_ip_allowed(a) for a in addresses):
        raise FetchError("ssrf_blocked", host)
    ipv4 = [a for a in addresses if a.version == 4]
    return str((ipv4 or addresses)[0])


class PinnedTransport(httpx.AsyncHTTPTransport):
    """Connects to the IP vetted by :func:`resolve_public` while keeping SNI/Host intact."""

    def __init__(self, pins: dict[str, str], **kwargs: Any) -> None:
        super().__init__(**kwargs)
        self._pins = pins

    async def handle_async_request(self, request: httpx.Request) -> httpx.Response:
        host = request.url.host
        pinned = self._pins.get(host)
        if pinned is None:
            raise FetchError("ssrf_blocked", f"unvetted host {host}")
        request.extensions = {**request.extensions, "sni_hostname": host}
        request.url = request.url.copy_with(host=pinned)
        return await super().handle_async_request(request)


class PoliteClient:
    def __init__(
        self,
        *,
        allow_private: bool = False,
        cache_get: CacheGet | None = None,
        cache_put: CachePut | None = None,
        user_agent: str = USER_AGENT,
        min_delay: float = MIN_DELAY,
        proxy: str | None = None,
        byte_budget: int | None = None,
    ) -> None:
        self.allow_private = allow_private
        self.user_agent = user_agent
        self.min_delay = min_delay
        self._cache_get = cache_get
        self._cache_put = cache_put
        self._global = asyncio.Semaphore(MAX_CONCURRENCY)
        self._domain_locks: dict[str, asyncio.Lock] = {}
        self._last_hit: dict[str, float] = {}
        self._robots: dict[str, tuple[Protego | None, float]] = {}
        self._pins: dict[str, str] = {}
        self.byte_budget = byte_budget
        # Behind a user-configured proxy the proxy resolves names; hosts are still vetted
        # (resolve_public) before each request, but the connection cannot be pinned.
        transport: httpx.AsyncBaseTransport = (
            httpx.AsyncHTTPTransport(proxy=proxy, retries=0) if proxy else PinnedTransport(self._pins, retries=0)
        )
        self._client = httpx.AsyncClient(
            transport=transport,
            timeout=httpx.Timeout(TIMEOUT, connect=10.0),
            follow_redirects=False,
            headers={"User-Agent": user_agent, "Accept-Language": "fr,en;q=0.8"},
        )
        self.requests_made = 0
        self.bytes_received = 0

    async def close(self) -> None:
        await self._client.aclose()

    async def __aenter__(self) -> PoliteClient:
        return self

    async def __aexit__(self, *exc: object) -> None:
        await self.close()

    # ---------------------------------------------------------------- robots
    async def _robots_for(self, scheme: str, host: str, port: int | None) -> Protego | None:
        key = f"{scheme}://{host}{'' if port in (None, 80, 443) else f':{port}'}"
        cached = self._robots.get(key)
        if cached and time.monotonic() - cached[1] < 6 * 3600:
            return cached[0]
        parser: Protego | None
        try:
            res = await self._get_raw(f"{key}/robots.txt", check_robots=False, use_cache=False)
            parser = Protego.parse(res.text) if res.status == 200 else None
            if res.status in (401, 403):
                parser = Protego.parse("User-agent: *\nDisallow: /")
        except FetchError:
            parser = None
        self._robots[key] = (parser, time.monotonic())
        return parser

    async def allowed(self, url: str) -> bool:
        parts = urlsplit(url)
        robots = await self._robots_for(parts.scheme, parts.hostname or "", parts.port)
        return robots is None or bool(robots.can_fetch(url, self.user_agent))

    # ------------------------------------------------------------------- get
    async def get(self, url: str, *, use_cache: bool = True, headers: dict[str, str] | None = None) -> FetchResult:
        return await self._get_raw(url, check_robots=True, use_cache=use_cache, headers=headers)

    async def post_json(self, url: str, payload: dict[str, Any]) -> FetchResult:
        return await self._get_raw(url, check_robots=True, use_cache=False, method="POST", json_body=payload)

    async def _get_raw(
        self,
        url: str,
        *,
        check_robots: bool,
        use_cache: bool,
        method: str = "GET",
        json_body: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
    ) -> FetchResult:
        if self.byte_budget is not None and self.bytes_received >= self.byte_budget:
            raise FetchError("bandwidth_limit", url)
        current = url
        for _hop in range(MAX_REDIRECTS + 1):
            parts = urlsplit(current)
            if parts.scheme not in ("http", "https") or not parts.hostname:
                raise FetchError("invalid_url", current)
            if check_robots and not await self.allowed(current):
                raise FetchError("robots_disallowed", current)
            host = parts.hostname
            if host not in self._pins:
                self._pins[host] = await resolve_public(
                    host, parts.port or (443 if parts.scheme == "https" else 80), allow_private=self.allow_private
                )
            response = await self._throttled(current, method, json_body, use_cache, headers)
            if response.status in (301, 302, 303, 307, 308):
                location = response.content_type  # set by _throttled for redirects
                current = urljoin(current, location)
                if response.status == 303:
                    method, json_body = "GET", None
                continue
            return response
        raise FetchError("too_many_redirects", url)

    async def _throttled(
        self,
        url: str,
        method: str,
        json_body: dict[str, Any] | None,
        use_cache: bool,
        extra_headers: dict[str, str] | None,
    ) -> FetchResult:
        host = urlsplit(url).hostname or ""
        lock = self._domain_locks.setdefault(host, asyncio.Lock())
        cached = self._cache_get(url) if (use_cache and method == "GET" and self._cache_get) else None
        headers: dict[str, str] = dict(extra_headers or {})
        if cached:
            if cached.get("etag"):
                headers["If-None-Match"] = cached["etag"]
            if cached.get("last_modified"):
                headers["If-Modified-Since"] = cached["last_modified"]
        async with self._global, lock:
            # Politeness delays protect remote publishers; the test-only loopback fixture
            # server (allow_private) does not need them.
            delay = 0.0 if self.allow_private and host in ("127.0.0.1", "localhost", "::1") else self.min_delay
            robots = self._robots.get(f"{urlsplit(url).scheme}://{host}")
            if robots and robots[0] is not None:
                crawl_delay = robots[0].crawl_delay(self.user_agent)
                if crawl_delay:
                    delay = max(delay, float(crawl_delay))
            wait = self._last_hit.get(host, 0.0) + delay - time.monotonic()
            if wait > 0:
                await asyncio.sleep(wait)
            try:
                return await self._send(url, method, json_body, headers, cached)
            finally:
                self._last_hit[host] = time.monotonic()

    async def _send(
        self,
        url: str,
        method: str,
        json_body: dict[str, Any] | None,
        headers: dict[str, str],
        cached: dict[str, Any] | None,
    ) -> FetchResult:
        attempt = 0
        while True:
            try:
                self.requests_made += 1
                async with self._client.stream(method, url, headers=headers, json=json_body) as r:
                    if r.status_code in (301, 302, 303, 307, 308):
                        return FetchResult(url, r.status_code, r.headers.get("location", ""), b"")
                    if r.status_code == 304 and cached:
                        return FetchResult(
                            url,
                            200,
                            cached.get("content_type") or "",
                            cached["body"],
                            from_cache=True,
                            etag=cached.get("etag"),
                            last_modified=cached.get("last_modified"),
                        )
                    if r.status_code == 429 or r.status_code >= 500:
                        raise FetchError("http_retryable", str(r.status_code))
                    declared = int(r.headers.get("content-length") or 0)
                    if declared > MAX_BYTES:
                        raise FetchError("oversize_response", str(declared))
                    chunks: list[bytes] = []
                    size = 0
                    async for chunk in r.aiter_bytes():
                        size += len(chunk)
                        if size > MAX_BYTES:
                            raise FetchError("oversize_response", str(size))
                        chunks.append(chunk)
                    self.bytes_received += size
                    result = FetchResult(
                        url,
                        r.status_code,
                        r.headers.get("content-type", ""),
                        b"".join(chunks),
                        etag=r.headers.get("etag"),
                        last_modified=r.headers.get("last-modified"),
                    )
                    if r.status_code >= 400:
                        raise FetchError(f"http_{r.status_code}", url)
                    if self._cache_put and method == "GET" and (result.etag or result.last_modified):
                        self._cache_put(url, result)
                    return result
            except (httpx.TimeoutException, httpx.TransportError) as exc:
                if attempt >= RETRIES:
                    raise FetchError("network_error", type(exc).__name__) from exc
            except FetchError as exc:
                if exc.code != "http_retryable" or attempt >= RETRIES:
                    if exc.code == "http_retryable":
                        raise FetchError(f"http_{exc.detail}", url) from exc
                    raise
            attempt += 1
            await asyncio.sleep(2**attempt)
