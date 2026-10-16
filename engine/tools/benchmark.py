"""Performance and transport checks quoted in the audit report. Everything runs in throw-away data folders.

Usage (from the repository root):
    engine/.venv/Scripts/python engine/tools/benchmark.py [--rows 100000]

1. Engine start: the packaged engine (dist/windows/Opportunex/engine) when it exists, else ``python main.py``:
   time to ``PORT:`` and to a healthy ``/api/v1/health``, five cold starts; then the transport guard is probed
   live (no token, wrong token, browser Origin, foreign Host) and the listening address is read from netstat.
2. Full-text search: a fresh encrypted profile filled with ``--rows`` synthetic opportunities (test data only,
   never a user profile); insert time with the FTS triggers, MATCH latency, dashboard API latency, file size.
"""

from __future__ import annotations

import argparse
import os
import random
import secrets
import statistics
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

ENGINE = Path(__file__).resolve().parents[1]
ROOT = ENGINE.parent
sys.path.insert(0, str(ENGINE))

PACKAGED = (
    ROOT
    / "dist"
    / "windows"
    / "Opportunex"
    / "engine"
    / ("opportunex-engine.exe" if os.name == "nt" else "opportunex-engine")
)


def _http(port: int, path: str, headers: dict[str, str]) -> int:
    req = urllib.request.Request(f"http://127.0.0.1:{port}{path}", headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=5) as r:  # noqa: S310
            return r.status
    except urllib.error.HTTPError as e:
        return e.code


def engine_start(runs: int = 5) -> None:
    cmd = [str(PACKAGED)] if PACKAGED.exists() else [sys.executable, str(ENGINE / "main.py")]
    print(f"## Engine start ({'packaged' if PACKAGED.exists() else 'source'}: {cmd[-1]})")
    port_times, ready_times = [], []
    for i in range(runs):
        with tempfile.TemporaryDirectory(prefix="opx-bench-") as tmp:
            token = secrets.token_urlsafe(32)
            env = {**os.environ, "OPX_DATA_DIR": tmp, "PYTHONUNBUFFERED": "1"}
            t0 = time.perf_counter()
            proc = subprocess.Popen(  # noqa: S603 - fixed argv
                cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, env=env
            )
            assert proc.stdin and proc.stdout
            proc.stdin.write(token.encode() + b"\n")
            proc.stdin.close()
            line = proc.stdout.readline().decode().strip()
            port = int(line.split(":")[1])
            port_times.append(time.perf_counter() - t0)
            while True:
                try:
                    if _http(port, "/api/v1/health", {}) == 200:
                        break
                except OSError:
                    pass
                time.sleep(0.05)
            ready_times.append(time.perf_counter() - t0)
            if i == runs - 1:
                ok = {"X-Engine-Token": token}
                probes = {
                    "health, no token": _http(port, "/api/v1/health", {}),
                    "version, no token": _http(port, "/api/v1/version", {}),
                    "version, wrong token": _http(port, "/api/v1/version", {"X-Engine-Token": "x" * 43}),
                    "version, token": _http(port, "/api/v1/version", ok),
                    "version, token + browser Origin": _http(
                        port, "/api/v1/version", {**ok, "Origin": "https://evil.example"}
                    ),
                    "version, token + foreign Host": _http(port, "/api/v1/version", {**ok, "Host": "evil.example"}),
                }
                for k, v in probes.items():
                    print(f"- {k}: HTTP {v}")
                if os.name == "nt":
                    out = subprocess.run(
                        ["netstat", "-ano", "-p", "TCP"],  # noqa: S607
                        capture_output=True,
                        text=True,
                        check=False,
                    ).stdout
                    listening = [
                        ln.split()[1]
                        for ln in out.splitlines()
                        if ln.strip().endswith(str(proc.pid)) and "LISTENING" in ln
                    ]
                    print(f"- listening on: {', '.join(listening)}")
            proc.terminate()
            proc.wait(timeout=20)
    print(
        f"- PORT printed after: median {statistics.median(port_times):.2f} s (runs: "
        + ", ".join(f"{t:.2f}" for t in port_times)
        + ")"
    )
    print(
        f"- healthy after: median {statistics.median(ready_times):.2f} s (runs: "
        + ", ".join(f"{t:.2f}" for t in ready_times)
        + ")"
    )


WORDS = [
    "bourse",
    "master",
    "doctorat",
    "emploi",
    "stage",
    "subvention",
    "appel",
    "offres",
    "concours",
    "formation",
    "volontariat",
    "recherche",
    "données",
    "santé",
    "agriculture",
    "énergie",
    "numérique",
    "éducation",
    "environnement",
    "finance",
    "ingénierie",
    "marketing",
    "juriste",
    "comptable",
    "développeur",
    "analyste",
    "chercheur",
    "enseignant",
    "infirmier",
    "logistique",
    "Douala",
    "Yaoundé",
    "Dakar",
    "Abidjan",
    "Libreville",
    "Kinshasa",
    "Brazzaville",
    "Cameroun",
    "Sénégal",
    "Gabon",
]


def fts(rows: int) -> None:
    os.environ["OPX_KDF_MEMORY_KIB"] = "8192"
    os.environ["OPX_KDF_ITERATIONS"] = "1"
    from fastapi.testclient import TestClient
    from sqlalchemy import text

    from api.app import create_app
    from core.config import Settings
    from services.search_service import SearchService

    print(f"## Full-text search on {rows:,} synthetic opportunities".replace(",", " "))
    with tempfile.TemporaryDirectory(prefix="opx-bench-") as tmp:
        os.environ["OPX_DATA_DIR"] = tmp
        token = secrets.token_urlsafe(32)
        app = create_app(Settings(), token)
        with TestClient(app, base_url="http://127.0.0.1") as client:
            h = {"X-Engine-Token": token}
            pw = "Bench-Baobab-Lumiere-2026!"
            r = client.post(
                "/api/v1/auth/register",
                headers=h,
                json={
                    "display_name": "Bench",
                    "email": "bench@example.org",
                    "password": pw,
                    "confirm_password": pw,
                    "locale": "fr",
                    "accept_terms": True,
                },
            )
            assert r.status_code == 201, r.text
            h["Authorization"] = f"Bearer {r.json()['session_token']}"
            state = app.state.engine
            rnd = random.Random(42)  # noqa: S311 - synthetic data
            batch = 5000
            t0 = time.perf_counter()
            for start in range(0, rows, batch):
                params = []
                for i in range(start, min(rows, start + batch)):
                    title = " ".join(rnd.choice(WORDS) for _ in range(6)).capitalize()
                    body = " ".join(rnd.choice(WORDS) for _ in range(60))
                    params.append(
                        {
                            "id": f"bench-{i:07d}",
                            "url": f"https://example.org/o/{i}",
                            "fp": f"fp-{i}",
                            "title": title,
                            "org": f"Organisme {i % 500}",
                            "summary": body[:200],
                            "desc": body,
                            "deadline": f"2027-{1 + i % 12:02d}-{1 + i % 28:02d}",
                        }
                    )
                with state.active.db.tx() as conn:
                    conn.execute(
                        text(
                            "INSERT INTO opportunities (id, canonical_url, normalized_url, dedup_fingerprint, title, "
                            "organization_name, summary, description_text, deadline_on) VALUES "
                            "(:id, :url, :url, :fp, :title, :org, :summary, :desc, :deadline)"
                        ),
                        params,
                    )
            insert_s = time.perf_counter() - t0
            print(f"- insert with FTS triggers: {insert_s:.1f} s ({rows / insert_s:,.0f} rows/s)".replace(",", " "))
            svc = SearchService(state.active, state)
            for terms in (["bourse"], ["données", "Douala"], ["ingénierie", "Gabon", "subvention"]):
                times, n = [], 0
                for _ in range(20):
                    q0 = time.perf_counter()
                    with state.active.db.read() as conn:
                        n = len(svc._fts_ids(conn, {"keywords": terms}))
                    times.append((time.perf_counter() - q0) * 1000)
                print(
                    f"- FTS {terms}: median {statistics.median(times):.1f} ms, max {max(times):.1f} ms "
                    f"({n} ids, limit 200)"
                )
            dash = []
            for _ in range(5):
                q0 = time.perf_counter()
                assert client.get("/api/v1/dashboard", headers=h).status_code == 200
                dash.append((time.perf_counter() - q0) * 1000)
            print(f"- GET /dashboard: median {statistics.median(dash):.0f} ms")
            db_files = list(Path(tmp).rglob("*.db"))
            size = sum(f.stat().st_size for f in db_files)
            print(f"- encrypted database size: {size / 1e6:.0f} MB")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rows", type=int, default=100_000)
    parser.add_argument("--skip-start", action="store_true")
    args = parser.parse_args()
    if not args.skip_start:
        engine_start()
    fts(args.rows)


if __name__ == "__main__":
    main()
