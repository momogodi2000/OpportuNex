"""Verify the built-in source catalogue against the live web with the production fetcher.

For each feed/API connector: fetch the list (robots.txt and rate limits honoured), parse it
with the declarative adapter and record the outcome. Official-link entries get a single
reachability check of their official URL.

Writes ``connectors/verification.json`` and prints a summary. With ``--apply`` the catalogue
is updated: connectors that returned items are enabled by default, the others are disabled
(and keep their official link), and ``verified_on`` is set.

Usage (from engine/):  .venv\\Scripts\\python tools\\verify_sources.py [--apply]
"""

from __future__ import annotations

import argparse
import asyncio
import json
import sys
import time
from pathlib import Path
from typing import Any

ENGINE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ENGINE))

from collection.adapters import AdapterError
from collection.fetching import fetch_list
from collection.http import FetchError, PoliteClient

CATALOG = ENGINE / "connectors" / "catalog.json"
REPORT = ENGINE / "connectors" / "verification.json"


async def check(client: PoliteClient, entry: dict[str, Any]) -> dict[str, Any]:
    started = time.monotonic()
    rid = entry["registry_id"]
    adapter = entry.get("adapter")
    if not adapter:
        url = str(entry.get("official_search_url") or entry["base_url"])
        try:
            res = await client.get(url, use_cache=False)
            return {"registry_id": rid, "kind": "link", "status": "ok", "http": res.status}
        except FetchError as exc:
            return {
                "registry_id": rid,
                "kind": "link",
                "status": "unreachable" if exc.code != "robots_disallowed" else "robots_disallowed",
                "error": exc.code,
            }
    query = "scholarship" if adapter.get("supports_query") else ""  # type: ignore[union-attr]
    try:
        listing = await fetch_list(client, adapter, query)  # type: ignore[arg-type]
        items = listing.items
        complete = [i for i in items if i.title and i.url.startswith("http")]
        return {
            "registry_id": rid,
            "kind": adapter["kind"],
            "status": "ok" if complete else "empty",  # type: ignore[index]
            "items": len(items),
            "sample": [i.title[:90] for i in complete[:3]],
            "with_deadline": sum(1 for i in items if i.fields.get("deadline")),
            "seconds": round(time.monotonic() - started, 1),
        }
    except FetchError as exc:
        return {"registry_id": rid, "kind": adapter["kind"], "status": exc.code, "error": exc.detail[:160]}  # type: ignore[index]
    except AdapterError as exc:
        return {"registry_id": rid, "kind": adapter["kind"], "status": exc.code, "error": str(exc)[:160]}  # type: ignore[index]


async def main(apply: bool, only: set[str]) -> None:
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    entries = [e for e in catalog["sources"] if not only or e["registry_id"] in only]
    async with PoliteClient() as client:
        results = await asyncio.gather(*(check(client, e) for e in entries))
    previous = json.loads(REPORT.read_text(encoding="utf-8")) if REPORT.exists() and only else {"results": []}
    merged = {r["registry_id"]: r for r in previous["results"]}
    merged.update({r["registry_id"]: r for r in results})
    report = {
        "checked_on": time.strftime("%Y-%m-%d"),
        "results": sorted(merged.values(), key=lambda r: str(r["registry_id"])),
    }
    REPORT.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    for r in results:
        print(f"{r['status']:<20} {r['registry_id']:<28} {r.get('items', '')} {r.get('error', '')}")
    ok_feeds = [r for r in merged.values() if r["kind"] != "link" and r["status"] == "ok"]
    print(
        f"\nfeeds/APIs OK: {len(ok_feeds)} / {sum(1 for e in catalog['sources'] if e.get('adapter'))};"
        f" catalogue size: {len(catalog['sources'])}"
    )
    if apply:
        status = {r["registry_id"]: r for r in merged.values()}
        for e in catalog["sources"]:
            outcome = status.get(e["registry_id"])
            if e.get("adapter") and outcome:
                e["enabled_by_default"] = outcome["status"] == "ok"
                e["verified_on"] = report["checked_on"]
                e["verification_status"] = outcome["status"]
        CATALOG.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print("catalogue updated")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--only", nargs="*", default=[])
    args = parser.parse_args()
    asyncio.run(main(args.apply, set(args.only)))
