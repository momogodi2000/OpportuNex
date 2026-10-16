"""Generate THIRD_PARTY_NOTICES.md and the bundled licence texts (Python engine + Flutter desktop).

Usage (from the repository root):
    engine/.venv/Scripts/python engine/tools/third_party_notices.py

* Python: the runtime dependency tree of engine/requirements.txt (dev tools excluded), with the licence
  declared in the package metadata and the licence files shipped in each distribution.
* Dart/Flutter: every package of apps/desktop/pubspec.lock that is a runtime dependency, with the LICENSE
  file from the pub cache. (Flutter also shows these at run time: About > Third-party licences.)
* Each licence is checked against GNU AGPL v3 compatibility; anything unknown or incompatible is flagged.
"""

from __future__ import annotations

import os
import re
import sys
from importlib import metadata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "THIRD_PARTY_NOTICES.md"
TEXTS = ROOT / "packaging" / "licenses"

COMPATIBLE = {
    "MIT", "BSD-2-Clause", "BSD-3-Clause", "Apache-2.0", "ISC", "PSF-2.0", "MPL-2.0", "Zlib", "Unlicense",
    "LGPL-2.1-or-later", "LGPL-3.0-or-later", "GPL-3.0-or-later", "AGPL-3.0-or-later", "Public Domain", "OFL-1.1",
    "CC0-1.0", "0BSD", "HPND", "Python-2.0", "BSD-3-Clause AND MIT",
}  # fmt: skip
# Manually reviewed multi-licence or unusual cases: (identifier shown, compatible?, rationale).
REVIEWED = {
    "certifi": ("MPL-2.0", True, "Mozilla Public License 2.0: file-level copyleft, compatible with AGPL v3."),
    "tld": (
        "LGPL-2.1-or-later",
        True,
        "Triple licence MPL-1.1 OR GPL-2.0-only OR LGPL-2.1-or-later; the "
        "LGPL-2.1-or-later option is used, which is compatible with AGPL v3.",
    ),
    "regex": (
        "Apache-2.0 AND CNRI-Python",
        True,
        "Apache-2.0 plus the CNRI licence of the Python 1.6.1 code it "
        "reuses, listed by the FSF as GPL-compatible. Included in the owner's legal review list.",
    ),
}
# Licence texts / classifiers → SPDX-like identifier (first match wins).
PATTERNS = [
    (r"GNU AFFERO GENERAL PUBLIC LICENSE", "AGPL-3.0-or-later"),
    (r"GNU LESSER GENERAL PUBLIC LICENSE\s+Version 3", "LGPL-3.0-or-later"),
    (r"GNU LESSER GENERAL PUBLIC LICENSE\s+Version 2\.1", "LGPL-2.1-or-later"),
    (r"GNU GENERAL PUBLIC LICENSE\s+Version 3", "GPL-3.0-or-later"),
    (r"GNU GENERAL PUBLIC LICENSE\s+Version 2", "GPL-2.0"),
    (r"Mozilla Public License,? (version|Version) 2\.0", "MPL-2.0"),
    (r"Apache License,?\s+Version 2\.0|Apache-2\.0|Apache 2\.0|Apache Software License", "Apache-2.0"),
    (r"Python Software Foundation License|PSF-2\.0|PSF License", "PSF-2.0"),
    (r"Permission to use, copy, modify, and/or distribute this software for any", "ISC"),
    (r"\bISC\b", "ISC"),
    (r"Redistribution and use in source and binary forms.*?Neither the name", "BSD-3-Clause"),
    (r"BSD-3-Clause|BSD 3-Clause|New BSD|Modified BSD", "BSD-3-Clause"),
    (r"Redistribution and use in source and binary forms", "BSD-2-Clause"),
    (r"BSD-2-Clause|Simplified BSD", "BSD-2-Clause"),
    (r"\bBSD\b", "BSD-3-Clause"),
    (r"Permission is hereby granted, free of charge|\bMIT\b", "MIT"),
    (r"This is free and unencumbered software released into the public domain", "Unlicense"),
    (r"public domain", "Public Domain"),
    (r"zlib", "Zlib"),
    (r"SIL OPEN FONT LICENSE", "OFL-1.1"),
]


def classify(text: str) -> str:
    for pattern, spdx in PATTERNS:
        if re.search(pattern, text, re.IGNORECASE | re.DOTALL):
            return spdx
    return "UNKNOWN"


def requirement_names(path: Path) -> list[str]:
    names = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            names.append(re.split(r"[\[<>=!~ ;]", line, maxsplit=1)[0])
    return names


def python_tree() -> dict[str, metadata.Distribution]:
    seen: dict[str, metadata.Distribution] = {}
    todo = requirement_names(ROOT / "engine" / "requirements.txt")
    while todo:
        name = todo.pop()
        key = re.sub(r"[-_.]+", "-", name).lower()
        if key in seen:
            continue
        try:
            dist = metadata.distribution(name)
        except metadata.PackageNotFoundError:
            continue
        seen[key] = dist
        for req in dist.requires or []:
            if "extra ==" in req:
                continue
            marker_ok = True
            if ";" in req:
                marker = req.split(";", 1)[1]
                if "sys_platform" in marker and ("win32" in marker) != (sys.platform == "win32") and "!=" not in marker:
                    marker_ok = False
                if "python_version <" in marker:
                    marker_ok = False
            if marker_ok:
                todo.append(re.split(r"[\[<>=!~ ;(]", req, maxsplit=1)[0])
    return seen


def python_licence(dist: metadata.Distribution) -> tuple[str, list[tuple[str, str]]]:
    meta = dist.metadata
    texts: list[tuple[str, str]] = []
    for f in dist.files or []:
        name = f.name.lower()
        if any(x in name for x in ("license", "licence", "copying", "notice")) and not name.endswith((".py", ".pyc")):
            try:
                texts.append((f.name, Path(str(f.locate())).read_text(encoding="utf-8", errors="replace")))
            except OSError:
                continue
    declared = meta.get("License-Expression") or ""
    if not declared:
        lic = (meta.get("License") or "").strip()
        declared = lic if lic and len(lic) < 80 and lic.upper() != "UNKNOWN" else ""
    classifiers = " ".join(v for v in meta.get_all("Classifier") or [] if v.startswith("License ::"))
    spdx = classify(declared) if declared else "UNKNOWN"
    if spdx == "UNKNOWN" and classifiers:
        spdx = classify(classifiers)
    if spdx == "UNKNOWN" and texts:
        spdx = classify(texts[0][1])
    if declared and " AND " in declared:
        spdx = declared
    return spdx, texts


def dart_packages() -> list[tuple[str, str, Path | None, str]]:
    lock = (ROOT / "apps" / "desktop" / "pubspec.lock").read_text(encoding="utf-8")
    cache = Path(os.environ.get("PUB_CACHE") or Path(os.environ.get("LOCALAPPDATA", "")) / "Pub" / "Cache")
    out = []
    for m in re.finditer(
        r"\n  (\S+):\n    dependency: \"?([^\"\n]+)\"?\n    description:(.*?)\n"
        r"    source: (\w+)\n    version: \"([^\"]+)\"",
        lock,
        re.S,
    ):
        name, dep, _desc, source, version = m.groups()
        if "dev" in dep:
            continue
        path = cache / "hosted" / "pub.dev" / f"{name}-{version}" / "LICENSE" if source == "hosted" else None
        out.append((name, version, path if path and path.exists() else None, source))
    return out


def main() -> None:
    TEXTS.mkdir(parents=True, exist_ok=True)
    rows: list[tuple[str, str, str, str, str]] = []
    flagged: list[str] = []
    reviewed: list[str] = []
    for key, dist in sorted(python_tree().items()):
        spdx, texts = python_licence(dist)
        ok = spdx in COMPATIBLE or all(part.strip("() ") in COMPATIBLE for part in re.split(r" AND | OR ", spdx))
        if key in REVIEWED:
            spdx, ok, why = REVIEWED[key]
            reviewed.append(f"{dist.metadata['Name']} {dist.version}: {why}")
        if not ok:
            flagged.append(f"Python {dist.metadata['Name']} {dist.version}: {spdx}")
        rows.append(("Python (engine)", dist.metadata["Name"], dist.version, spdx, "yes" if ok else "**check**"))
        body = "\n\n".join(f"----- {n} -----\n{t}" for n, t in texts) or f"Licence declared in metadata: {spdx}\n"
        (TEXTS / "python").mkdir(exist_ok=True)
        (TEXTS / "python" / f"{key}.txt").write_text(
            f"{dist.metadata['Name']} {dist.version}\n\n{body}", encoding="utf-8"
        )
    for name, version, path, source in dart_packages():
        if source == "sdk":
            spdx, text = (
                "BSD-3-Clause",
                "Part of the Flutter SDK, BSD 3-Clause licence (https://github.com/flutter/flutter/blob/master/LICENSE).",
            )
        elif path is None:
            spdx, text = "UNKNOWN", "Licence file not found in the local pub cache."
        else:
            text = path.read_text(encoding="utf-8", errors="replace")
            spdx = classify(text)
        ok = spdx in COMPATIBLE
        if not ok:
            flagged.append(f"Dart {name} {version}: {spdx}")
        rows.append(("Dart (desktop)", name, version, spdx, "yes" if ok else "**check**"))
        (TEXTS / "dart").mkdir(exist_ok=True)
        (TEXTS / "dart" / f"{name}.txt").write_text(f"{name} {version}\n\n{text}", encoding="utf-8")

    native = [
        ("Native", "SQLCipher (via sqlcipher3-wheels)", "4.x", "BSD-3-Clause", "yes"),
        ("Native", "SQLite", "3.x", "Public Domain", "yes"),
        ("Native", "libsodium (via PyNaCl)", "1.x", "ISC", "yes"),
        ("Native", "OpenSSL (via cryptography)", "3.x", "Apache-2.0", "yes"),
        ("Native", "Flutter engine and Skia/Impeller", "3.41", "BSD-3-Clause", "yes"),
        ("Native", "CPython runtime (bundled by PyInstaller)", "3.14", "PSF-2.0", "yes"),
        ("Font", "Inter", "4.1", "OFL-1.1", "yes"),
    ]
    rows += native
    lines = [
        "# Third-party notices",
        "",
        "Opportunex is distributed under the GNU AGPL v3 (see `LICENSE`). It includes the components below, each under",
        "its own licence. Full licence texts are in `packaging/licenses/` and are installed with the application;",
        "the desktop app also lists them under **About > Third-party licences**.",
        "",
        "Generated by `engine/tools/third_party_notices.py` from the installed engine environment and",
        "`apps/desktop/pubspec.lock`. Column *AGPL-compatible*: licence known to be compatible with distribution under",
        "AGPL v3; **check** means unknown or needing review.",
        "",
        f"Components: {len(rows)} · flagged: {len(flagged)}",
        "",
        "| Origin | Component | Version | Licence | AGPL-compatible |",
        "| --- | --- | --- | --- | --- |",
        *[f"| {a} | {b} | {c} | {d} | {e} |" for a, b, c, d, e in rows],
        "",
    ]
    if reviewed:
        lines += ["## Reviewed by hand", "", *[f"- {r}" for r in reviewed], ""]
    if flagged:
        lines += ["## To review", "", *[f"- {f}" for f in flagged], ""]
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"{len(rows)} components, {len(flagged)} flagged")
    for f in flagged:
        print("  -", f)


if __name__ == "__main__":
    main()
