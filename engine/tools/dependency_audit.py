"""Check every shipped dependency against public vulnerability databases (read-only HTTPS GET requests).

Usage (from the repository root, network access required):
    engine/.venv/Scripts/python engine/tools/dependency_audit.py

* Python: the runtime dependency tree of engine/requirements.txt (as installed) plus sync-server/requirements.txt,
  each looked up at https://pypi.org/pypi/<name>/<version>/json, whose "vulnerabilities" field comes from OSV.
* Dart: the runtime packages of apps/desktop/pubspec.lock, matched against the GitHub advisory database for the
  pub ecosystem (https://api.github.com/advisories?ecosystem=pub).
Only package names and versions leave the machine. Exit code 1 when a known vulnerability affects a version in use.
"""

from __future__ import annotations

import json
import sys
import time
import urllib.request
from importlib import metadata
from pathlib import Path
from typing import Any

from packaging.specifiers import InvalidSpecifier, SpecifierSet
from packaging.version import InvalidVersion, Version

sys.path.insert(0, str(Path(__file__).resolve().parent))
from third_party_notices import ROOT, dart_packages, python_tree, requirement_names

HEADERS = {"User-Agent": "opportunex-dependency-audit", "Accept": "application/json"}


UNCHECKED: list[str] = []


def _get(url: str, attempts: int = 4) -> Any:
    for i in range(attempts):
        try:
            req = urllib.request.Request(url, headers=HEADERS)  # noqa: S310 - fixed https hosts
            with urllib.request.urlopen(req, timeout=45) as r:  # noqa: S310
                return json.loads(r.read())
        except (OSError, ValueError):
            if i == attempts - 1:
                raise
            time.sleep(2 * (i + 1))
    raise AssertionError("unreachable")


def python_packages() -> dict[str, str]:
    out = {dist.metadata["Name"]: dist.version for dist in python_tree().values()}
    for name in requirement_names(ROOT / "sync-server" / "requirements.txt"):
        try:
            out[metadata.distribution(name).metadata["Name"]] = metadata.version(name)
        except metadata.PackageNotFoundError:
            print(f"(sync-server dependency not installed in this environment, not checked: {name})")
    return dict(sorted(out.items()))


def audit_python() -> list[str]:
    found = []
    pkgs = python_packages()
    for name, version in pkgs.items():
        try:
            data = _get(f"https://pypi.org/pypi/{name}/{version}/json")
        except (OSError, ValueError) as exc:
            UNCHECKED.append(f"PyPI {name} {version} ({type(exc).__name__})")
            continue
        for v in data.get("vulnerabilities") or []:
            if v.get("withdrawn"):
                continue
            ids = ", ".join([v["id"], *v.get("aliases", [])])
            fixed = ", ".join(v.get("fixed_in") or []) or "no fixed version listed"
            summary = (v.get("summary") or v.get("details") or "").strip().replace("\n", " ")[:110]
            found.append(f"PyPI {name} {version}: {ids} — {summary} — fixed in {fixed}")
    print(f"Python: {len(pkgs)} packages checked")
    return found


def _affected(version: str, vulnerable_range: str) -> bool:
    try:
        # GitHub ranges look like ">= 1.0, < 1.5" or "= 2.3.3" (an exact version, "==" in PEP 440).
        parts = [p.strip() for p in vulnerable_range.split(",") if p.strip()]
        exact = [("==" + p[1:].strip()) if p.startswith("=") and not p.startswith("==") else p for p in parts]
        spec = SpecifierSet(",".join(p.replace(" ", "") for p in exact))
        return Version(version) in spec
    except (InvalidSpecifier, InvalidVersion):
        return True  # cannot decide: report it for a manual look


def audit_dart() -> list[str]:
    advisories: list[dict[str, Any]] = []
    page = 1
    while True:
        batch = _get(f"https://api.github.com/advisories?ecosystem=pub&per_page=100&page={page}")
        advisories += batch
        if len(batch) < 100:
            break
        page += 1
    used = {name: version for name, version, _path, source in dart_packages() if source == "hosted"}
    found = []
    for adv in advisories:
        if adv.get("withdrawn_at"):
            continue
        for vuln in adv.get("vulnerabilities") or []:
            pkg = (vuln.get("package") or {}).get("name")
            if pkg in used and _affected(used[pkg], vuln.get("vulnerable_version_range") or ""):
                fixed = vuln.get("first_patched_version") or "no fixed version listed"
                found.append(
                    f"Pub {pkg} {used[pkg]}: {adv['ghsa_id']} ({adv.get('cve_id') or 'no CVE'}) — "
                    f"{adv.get('summary', '')} — fixed in {fixed}"
                )
    print(f"Dart: {len(used)} packages checked against {len(advisories)} pub advisories")
    return found


def main() -> int:
    found = audit_python() + audit_dart()
    for line in found:
        print(line)
    for line in UNCHECKED:
        print(f"NOT CHECKED (network): {line}")
    print(f"{len(found)} known vulnerabilities affecting the versions in use; {len(UNCHECKED)} not checked")
    return 1 if found or UNCHECKED else 0


if __name__ == "__main__":
    sys.exit(main())
