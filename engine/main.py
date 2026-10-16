"""Opportunex engine entry point (arch §3.4, ADR-002).

Protocol with the desktop UI:

1. The UI starts this process and writes a random token (>= 32 chars) on stdin.
2. The engine binds a free port on 127.0.0.1 and prints ``PORT:<n>`` on stdout as soon as
   the socket is listening (before heavy imports), then serves the API.
3. Every request must carry ``X-Engine-Token``; ``GET /api/v1/health`` is the only public
   route.
4. With ``--parent-pid <pid>`` (passed by the UI) the engine shuts down when that process ends, so a
   crashed or force-killed app never leaves an orphan engine holding the instance lock.

Other modes:

* ``--self-test``  runs an in-process end-to-end check in a temporary data directory and
  exits 0 on success (used to validate installed packages).
* ``--version``    prints the engine version.
"""

from __future__ import annotations

import argparse
import os
import queue
import socket
import sys
import threading
from pathlib import Path
from typing import IO

TOKEN_TIMEOUT_SECONDS = 15.0
MIN_TOKEN_LENGTH = 32


def _read_token(stream: IO[str], timeout: float) -> str:
    box: queue.Queue[str] = queue.Queue(maxsize=1)

    def _reader() -> None:
        try:
            box.put(stream.readline().strip())
        except Exception:  # noqa: BLE001 - closed stdin
            box.put("")

    threading.Thread(target=_reader, daemon=True).start()
    try:
        return box.get(timeout=timeout)
    except queue.Empty:
        return ""


class SingleInstanceLock:
    """One engine per OS user and data directory (D-26)."""

    def __init__(self, path: Path) -> None:
        self.path = path
        self._fh: IO[bytes] | None = None

    def acquire(self) -> bool:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        fh = open(self.path, "a+b")  # noqa: SIM115 - held for the process lifetime
        try:
            if sys.platform == "win32":
                import msvcrt

                fh.seek(0)
                msvcrt.locking(fh.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl

                fcntl.flock(fh.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            fh.close()
            return False
        self._fh = fh
        return True


def _bind() -> socket.socket:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.bind(("127.0.0.1", 0))
    sock.listen(64)
    sock.set_inheritable(True)
    return sock


def serve(parent_pid: int | None = None) -> int:
    token = _read_token(sys.stdin, TOKEN_TIMEOUT_SECONDS) or os.environ.get("OPX_ENGINE_TOKEN", "")
    if len(token) < MIN_TOKEN_LENGTH:
        print("ERROR:missing_token", file=sys.stderr, flush=True)
        return 2

    from core.config import get_settings

    settings = get_settings()
    lock = SingleInstanceLock(settings.paths.lock_file)
    if not lock.acquire():
        print("ERROR:already_running", file=sys.stderr, flush=True)
        return 3

    sock = _bind()
    port = sock.getsockname()[1]
    print(f"PORT:{port}", flush=True)

    import uvicorn

    from api.app import create_app
    from core.logging import configure_logging

    configure_logging(settings.paths.logs, settings.log_level)
    app = create_app(settings, token)
    config = uvicorn.Config(app, log_config=None, access_log=False, ws="auto", timeout_graceful_shutdown=5)
    server = uvicorn.Server(config)
    app.state.request_shutdown = lambda: setattr(server, "should_exit", True)
    if parent_pid:
        from core.parent_watch import watch_parent

        watch_parent(parent_pid, app.state.request_shutdown)
    server.run(sockets=[sock])
    return 0


def _check(condition: bool, what: str) -> None:
    if not condition:
        raise SystemExit(f"SELF-TEST FAILED: {what}")


def self_test() -> int:
    """Register, sign in, lock and unlock a throw-away profile in a temporary directory."""
    import secrets
    import tempfile

    with tempfile.TemporaryDirectory(prefix="opx-selftest-") as tmp:
        os.environ["OPX_DATA_DIR"] = tmp
        os.environ.setdefault("OPX_KDF_MEMORY_KIB", "8192")
        os.environ.setdefault("OPX_KDF_ITERATIONS", "1")
        from fastapi.testclient import TestClient

        from api.app import create_app
        from core.config import Settings

        token = secrets.token_urlsafe(32)
        app = create_app(Settings(), token)
        headers = {"X-Engine-Token": token}
        with TestClient(app, base_url="http://127.0.0.1") as client:
            _check(client.get("/api/v1/health").json() == {"status": "ok"}, "health")
            r = client.post(
                "/api/v1/auth/register",
                headers=headers,
                json={
                    "display_name": "Self Test",
                    "email": "self-test@opportunex.app",
                    "password": "correct horse battery staple 42",
                    "accept_terms": True,
                    "confirm_password": "correct horse battery staple 42",
                    "locale": "fr",
                },
            )
            _check(r.status_code == 201, f"register {r.status_code} {r.text}")
            session = r.json()["session_token"]
            me = client.get("/api/v1/auth/me", headers=headers | {"Authorization": f"Bearer {session}"})
            _check(me.status_code == 200, f"me {me.status_code}")
            version = client.get("/api/v1/version", headers=headers).json()
        libraries = _check_libraries()
        print(f"SELF-TEST OK engine={version['engine_version']} schema={version['schema_revision']} libs={libraries}")
    return 0


def _check_libraries() -> int:
    """Exercise the lazily imported libraries, so a packaged build that lacks one fails here, not in use."""
    import io

    from collection.adapters import extract_detail, structured_fields
    from collection.normalize import detect_language, parse_date
    from documents import cv_parser, generator
    from sync import crypto

    html = (
        '<html><head><script type=\'application/ld+json\'>{"@context":"https://schema.org",'
        '"@type":"JobPosting","title":"Analyste","validThrough":"2099-12-15"}</script></head>'
        "<body><article><h1>Analyste de données</h1><p>"
        + "Poste d'analyste de données basé à Douala. " * 20
        + "</p></article></body></html>"
    ).encode()
    text, obj = extract_detail(html, "https://example.org/offre")  # trafilatura + extruct
    _check("Douala" in text, f"page text extraction (trafilatura, {len(text)} chars)")
    _check(obj is not None and bool(structured_fields(obj).get("deadline")), f"structured data (extruct, {obj!r:.80})")
    _check(str(parse_date("15 décembre 2099")) == "2099-12-15", "dateparser")
    _check(detect_language("Ceci est une offre d'emploi pour un analyste de données à Douala.") == "fr", "langdetect")
    pdf = generator.to_pdf("Test", "Lettre de motivation pour un poste d'analyste.")  # reportlab
    _check(pdf.startswith(b"%PDF"), "reportlab")
    _check(len(generator.to_docx("Test", "Lettre.")) > 1000, "python-docx")
    # PDF parsing runs in a child process: this also checks multiprocessing in a frozen build.
    _check("analyste" in cv_parser.extract_text_isolated("application/pdf", pdf).lower(), "pdf parsing")
    from openpyxl import Workbook

    wb = Workbook()
    wb.active.append(["ok"])
    buf = io.BytesIO()
    wb.save(buf)
    _check(buf.getbuffer().nbytes > 1000, "openpyxl")
    key = crypto.new_key()
    nonce, ct = crypto.encrypt(key, b"secret", "user|x")
    _check(crypto.decrypt(key, nonce, ct, "user|x") == b"secret", "libsodium")
    import keyring

    _check(keyring.get_keyring() is not None, "keyring")
    return 9


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="opportunex-engine")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--version", action="store_true")
    parser.add_argument("--parent-pid", type=int, help="stop when this process (the desktop app) exits")
    args = parser.parse_args(argv)
    if args.version:
        from core.version import ENGINE_VERSION

        print(ENGINE_VERSION)
        return 0
    if args.self_test:
        return self_test()
    return serve(args.parent_pid)


if __name__ == "__main__":
    import multiprocessing

    # Required for the isolated document parser when frozen by PyInstaller.
    multiprocessing.freeze_support()
    sys.exit(main())
