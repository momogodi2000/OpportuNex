"""Built-in source catalogue (EF-06.09, D-20).

The catalogue lives in ``connectors/catalog.json`` (declarative data, Apache-2.0 per D-07).
On each sign-in it is synchronised into the profile database: new entries are added, adapter
specs are upgraded when their version changes, and user choices (enabled flag, frequency)
are preserved.
"""

from __future__ import annotations

import hashlib
import json
from functools import lru_cache
from typing import Any
from urllib.parse import urlsplit

from sqlalchemy import Connection, insert, select, update

from collection.adapters import validate_spec
from core.config import resource_dir
from core.ids import uuid7
from persistence.database import Tables

CATALOG_FILE = "catalog.json"


@lru_cache(maxsize=1)
def load_catalog() -> dict[str, Any]:
    path = resource_dir() / "connectors" / CATALOG_FILE
    data = json.loads(path.read_text(encoding="utf-8"))
    for entry in data["sources"]:
        if entry.get("adapter"):
            validate_spec(entry["adapter"])
    return data


def _category_ids(conn: Connection, T: Tables, codes: list[str]) -> list[int]:
    if not codes:
        return []
    rows = conn.execute(
        select(T.opportunity_categories.c.id, T.opportunity_categories.c.code).where(
            T.opportunity_categories.c.code.in_(codes)
        )
    ).all()
    return [r[0] for r in rows]


def sync_catalog(conn: Connection, T: Tables) -> dict[str, int]:
    catalog = load_catalog()
    added = upgraded = 0
    for entry in catalog["sources"]:
        registry_id = entry["registry_id"]
        row = conn.execute(select(T.sources.c.id).where(T.sources.c.registry_id == registry_id)).first()
        adapter = entry.get("adapter")
        if row is None:
            source_id = uuid7()
            conn.execute(
                insert(T.sources).values(
                    id=source_id,
                    owner_user_id=None,
                    registry_id=registry_id,
                    name=entry["name"],
                    base_url=entry["base_url"],
                    domain=(urlsplit(entry["base_url"]).hostname or "").lower(),
                    publisher_name=entry.get("publisher_name"),
                    publisher_type=entry.get("publisher_type"),
                    is_official=1 if entry.get("is_official") else 0,
                    access_method=entry["access_method"],
                    country_code=entry.get("country_code"),
                    language_code=entry.get("language_code"),
                    enabled=1 if entry.get("enabled_by_default") else 0,
                    allowed_status=entry.get("allowed_status", "unknown"),
                    min_interval_minutes=int(entry.get("min_interval_minutes", 1440)),
                    crawl_delay_seconds=float(entry.get("crawl_delay_seconds", 2.0)),
                    terms_url=entry.get("terms_url"),
                    official_search_url=entry.get("official_search_url"),
                    reliability_score=float(entry.get("reliability_score", 0.5)),
                )
            )
            for cid in _category_ids(conn, T, entry.get("categories", [])):
                conn.execute(insert(T.source_categories).values(source_id=source_id, category_id=cid))
            added += 1
        else:
            source_id = row[0]
            conn.execute(
                update(T.sources)
                .where(T.sources.c.id == source_id)
                .values(
                    name=entry["name"],
                    official_search_url=entry.get("official_search_url"),
                    terms_url=entry.get("terms_url"),
                    access_method=entry["access_method"],
                    allowed_status=entry.get("allowed_status", "unknown"),
                )
            )
        if adapter:
            spec = json.dumps(adapter, sort_keys=True)
            digest = hashlib.sha256(spec.encode()).hexdigest()
            current = conn.execute(
                select(T.source_adapters.c.spec_sha256).where(
                    T.source_adapters.c.source_id == source_id, T.source_adapters.c.is_active == 1
                )
            ).first()
            if current is None or current[0] != digest:
                conn.execute(
                    update(T.source_adapters).where(T.source_adapters.c.source_id == source_id).values(is_active=0)
                )
                version = str(adapter.get("version", "1.0.0"))
                exists = conn.execute(
                    select(T.source_adapters.c.id).where(
                        T.source_adapters.c.source_id == source_id, T.source_adapters.c.version == version
                    )
                ).first()
                if exists:
                    conn.execute(
                        update(T.source_adapters)
                        .where(T.source_adapters.c.id == exists[0])
                        .values(spec=spec, spec_sha256=digest, is_active=1)
                    )
                else:
                    conn.execute(
                        insert(T.source_adapters).values(
                            id=uuid7(),
                            source_id=source_id,
                            version=version,
                            spec=spec,
                            spec_sha256=digest,
                            origin="builtin",
                            is_active=1,
                        )
                    )
                if current is not None:
                    upgraded += 1
    return {"added": added, "upgraded": upgraded}
