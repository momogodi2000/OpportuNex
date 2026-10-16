"""Declarative source adapters (ADR-006, ADR-007): RSS/Atom, JSON API, HTML list, JSON-LD.

An adapter spec is pure data (JSON); no code from a connector is ever executed. Each adapter
turns a fetched list document into :class:`RawItem` objects; detail pages can then be
fetched to extract the main text and schema.org structured data.
"""

from __future__ import annotations

import html as htmllib
import json
import re
from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Any
from urllib.parse import quote_plus, urljoin

import feedparser
import structlog
from selectolax.parser import HTMLParser

ALLOWED_KINDS = ("rss", "json_api", "html_list")
_TAGS = re.compile(r"<[^>]+>")
_WS = re.compile(r"\s+")

log = structlog.get_logger("collection")


class AdapterError(Exception):
    def __init__(self, code: str, detail: str = "") -> None:
        super().__init__(f"{code}: {detail}")
        self.code = code


@dataclass
class RawItem:
    url: str
    title: str
    summary: str = ""
    published: str | None = None
    external_id: str | None = None
    fields: dict[str, Any] = field(default_factory=dict)  # explicit structured values from the source


def clean_html(text: str | None) -> str:
    if not text:
        return ""
    text = re.sub(r"(?is)<(script|style|noscript)[^>]*>.*?</\1>", " ", text)
    text = re.sub(r"(?i)<br\s*/?>|</p>|</li>|</h\d>", "\n", text)
    text = htmllib.unescape(_TAGS.sub(" ", text))
    lines = [_WS.sub(" ", ln).strip() for ln in text.split("\n")]
    return "\n".join(ln for ln in lines if ln)


def _dig(obj: Any, path: str | None) -> Any:
    if not path:
        return None
    cur = obj
    for part in path.split("."):
        if isinstance(cur, list):
            if part.isdigit() and int(part) < len(cur):
                cur = cur[int(part)]
                continue
            cur = cur[0] if cur else None
        if not isinstance(cur, dict):
            return None
        cur = cur.get(part)
    return cur


def validate_spec(spec: dict[str, Any]) -> None:
    kind = spec.get("kind")
    if kind not in ALLOWED_KINDS:
        raise AdapterError("adapter_kind_invalid", str(kind))
    url = spec.get("url", "")
    if not isinstance(url, str) or not url.startswith(("https://", "http://")):
        raise AdapterError("adapter_url_invalid", str(url))
    if kind == "json_api" and not isinstance(spec.get("fields"), dict):
        raise AdapterError("adapter_fields_missing")
    if kind == "html_list" and not spec.get("item_selector"):
        raise AdapterError("adapter_selector_missing")


def build_url(spec: dict[str, Any], query: str) -> str:
    url = str(spec["url"])
    return url.replace("{query}", quote_plus(query)) if "{query}" in url else url


def build_body(spec: dict[str, Any], query: str) -> dict[str, Any] | None:
    body = spec.get("body")
    if body is None:
        return None
    raw = json.dumps(body).replace("{query}", query.replace('"', ""))
    return dict(json.loads(raw))


def parse_list(spec: dict[str, Any], body: bytes, base_url: str) -> list[RawItem]:
    kind = spec["kind"]
    limit = int(spec.get("max_items", 50))
    if kind == "rss":
        items = _parse_rss(body, base_url)
    elif kind == "json_api":
        items = _parse_json(spec, body, base_url)
    else:
        items = _parse_html_list(spec, body, base_url)
    seen: set[str] = set()
    unique = []
    for it in items:
        if it.url and it.title and it.url not in seen:
            seen.add(it.url)
            unique.append(it)
    return unique[:limit]


def _parse_rss(body: bytes, base_url: str) -> list[RawItem]:
    feed = feedparser.parse(body)
    if feed.bozo and not feed.entries:
        raise AdapterError("feed_malformed", str(feed.get("bozo_exception", ""))[:120])
    out = []
    for e in feed.entries:
        published = None
        stamp = e.get("published_parsed") or e.get("updated_parsed")
        if stamp:
            published = datetime(*tuple(stamp)[:6]).replace(tzinfo=UTC).strftime("%Y-%m-%d")
        content = ""
        if e.get("content"):
            content = e["content"][0].get("value", "")
        out.append(
            RawItem(
                url=urljoin(base_url, e.get("link", "")),
                title=clean_html(e.get("title", "")),
                summary=clean_html(content or e.get("summary", "")),
                published=published,
                external_id=e.get("id"),
                fields={
                    k: v
                    for k, v in {"categories": [t.get("term") for t in e.get("tags", []) if t.get("term")]}.items()
                    if v
                },
            )
        )
    return out


def _parse_json(spec: dict[str, Any], body: bytes, base_url: str) -> list[RawItem]:
    try:
        data = json.loads(body)
    except json.JSONDecodeError as exc:
        raise AdapterError("json_malformed") from exc
    rows = _dig(data, spec.get("items_path")) if spec.get("items_path") else data
    if not isinstance(rows, list):
        raise AdapterError("json_items_missing", str(spec.get("items_path")))
    f: dict[str, str] = spec["fields"]
    out = []
    for row in rows:
        url = _dig(row, f.get("url"))
        title = _dig(row, f.get("title"))
        if not url or not title:
            continue
        template = spec.get("url_template")
        if template and "{" in template:
            url = template.replace("{value}", str(url))
        published = _dig(row, f.get("published"))
        extra = {}
        for key in (
            "organization",
            "deadline",
            "location",
            "country",
            "category",
            "amount",
            "work_mode",
            "language",
            "description",
        ):
            if f.get(key):
                value = _dig(row, f[key])
                if value not in (None, "", []):
                    extra[key] = value
        out.append(
            RawItem(
                url=urljoin(base_url, str(url)),
                title=clean_html(str(title)),
                summary=clean_html(str(_dig(row, f.get("summary")) or extra.get("description") or "")),
                published=str(published)[:10] if published else None,
                external_id=str(_dig(row, f.get("id"))) if f.get("id") and _dig(row, f.get("id")) else None,
                fields=extra,
            )
        )
    return out


def _select_value(node: Any, rule: dict[str, Any] | str | None) -> str:
    if rule is None:
        return ""
    if isinstance(rule, str):
        rule = {"selector": rule}
    target = node.css_first(rule["selector"]) if rule.get("selector") else node
    if target is None:
        return ""
    attr = rule.get("attr", "text")
    if attr == "text":
        return _WS.sub(" ", target.text(separator=" ")).strip()
    return str(target.attributes.get(attr) or "").strip()


def _parse_html_list(spec: dict[str, Any], body: bytes, base_url: str) -> list[RawItem]:
    tree = HTMLParser(body.decode("utf-8", errors="replace"))
    fields: dict[str, Any] = spec.get("fields", {})
    out = []
    for node in tree.css(spec["item_selector"]):
        link_rule = fields.get("url", {"selector": "a", "attr": "href"})
        url = _select_value(node, link_rule)
        title = _select_value(node, fields.get("title", "a"))
        extra = {
            k: _select_value(node, fields[k])
            for k in ("deadline", "organization", "location", "published")
            if k in fields
        }
        out.append(
            RawItem(
                url=urljoin(base_url, url),
                title=title,
                summary=_select_value(node, fields.get("summary")),
                published=extra.pop("published", None) or None,
                fields={k: v for k, v in extra.items() if v},
            )
        )
    return out


# ------------------------------------------------------------------ detail page
STRUCTURED_TYPES = {
    "JobPosting",
    "Grant",
    "Event",
    "EducationalOccupationalProgram",
    "Scholarship",
    "MonetaryGrant",
    "Course",
}


def extract_detail(html_bytes: bytes, url: str) -> tuple[str, dict[str, Any] | None]:
    """Main text (trafilatura, scripts never executed) and the first relevant JSON-LD object."""
    import trafilatura

    html_text = html_bytes.decode("utf-8", errors="replace")
    text = trafilatura.extract(html_text, url=url, include_comments=False, include_tables=True, favor_recall=True) or ""
    structured = None
    try:
        import extruct

        data = extruct.extract(html_text, base_url=url, syntaxes=["json-ld", "microdata"], uniform=True)
        for syntax in ("json-ld", "microdata"):
            for obj in data.get(syntax, []):
                for candidate in obj.get("@graph", [obj]) if isinstance(obj, dict) else []:
                    types = candidate.get("@type")
                    types = types if isinstance(types, list) else [types]
                    if any(t in STRUCTURED_TYPES for t in types):
                        structured = candidate
                        break
                if structured:
                    break
            if structured:
                break
    except Exception as exc:  # noqa: BLE001 - structured data is optional; malformed markup is common
        log.debug("structured_data_skipped", error=type(exc).__name__)
        structured = None
    return text[:200_000], structured


def structured_fields(obj: dict[str, Any]) -> dict[str, Any]:
    """Map schema.org JobPosting/Grant/Event properties to our explicit fields."""

    def first(v: Any) -> Any:
        return v[0] if isinstance(v, list) and v else v

    org = first(obj.get("hiringOrganization") or obj.get("funder") or obj.get("organizer") or obj.get("provider"))
    location = first(obj.get("jobLocation") or obj.get("location"))
    address = first(location.get("address")) if isinstance(location, dict) else None
    country = None
    if isinstance(address, dict):
        country = address.get("addressCountry")
        country = country.get("name") if isinstance(country, dict) else country
    salary = obj.get("baseSalary") or obj.get("amount")
    amount = None
    if isinstance(salary, dict):
        value = salary.get("value")
        amount = {
            "currency": salary.get("currency"),
            "min": value.get("minValue") if isinstance(value, dict) else value,
            "max": value.get("maxValue") if isinstance(value, dict) else None,
            "unit": value.get("unitText") if isinstance(value, dict) else None,
        }
    out = {
        "title": obj.get("title") or obj.get("name"),
        "description": clean_html(obj.get("description")),
        "organization": org.get("name") if isinstance(org, dict) else org,
        "published": obj.get("datePosted") or obj.get("startDate"),
        "deadline": obj.get("validThrough") or obj.get("endDate") or obj.get("applicationDeadline"),
        "country": country,
        "location": (address.get("addressLocality") if isinstance(address, dict) else None),
        "work_mode": "remote" if obj.get("jobLocationType") == "TELECOMMUTE" else None,
        "employment_type": first(obj.get("employmentType")),
        "amount": amount,
        "education_required": first(obj.get("educationRequirements")),
        "experience_required": first(obj.get("experienceRequirements")),
    }
    return {k: v for k, v in out.items() if v not in (None, "", [])}
