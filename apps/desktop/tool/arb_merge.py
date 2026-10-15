"""Merge new localisation keys into lib/l10n/app_fr.arb and app_en.arb.

Usage: python tool/arb_merge.py <file.json>
where the JSON file holds [ {fr keys...}, {en keys...} ]. Existing keys are overwritten,
key order is preserved, so ARB diffs stay readable.
"""

from __future__ import annotations

import json
import sys
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def merge(path: Path, entries: dict[str, object]) -> None:
    data = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=OrderedDict)
    data.update(entries)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    fr, en = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    missing = sorted(set(fr) ^ set(en))
    if missing:
        raise SystemExit(f"FR/EN key mismatch: {missing}")
    merge(ROOT / "lib" / "l10n" / "app_fr.arb", fr)
    merge(ROOT / "lib" / "l10n" / "app_en.arb", en)
    print(f"merged {len(fr)} keys")


if __name__ == "__main__":
    main()
