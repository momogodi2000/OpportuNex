"""Shared fixtures: isolated data directory, fast KDF, an engine app and signed-in clients."""

from __future__ import annotations

import os
import secrets
import sys
from collections.abc import Iterator
from pathlib import Path
from typing import Any

import pytest

ENGINE_DIR = Path(__file__).resolve().parent.parent
if str(ENGINE_DIR) not in sys.path:
    sys.path.insert(0, str(ENGINE_DIR))

from fastapi.testclient import TestClient  # noqa: E402

from api.app import create_app  # noqa: E402
from core.config import Settings  # noqa: E402

STRONG_PASSWORD = "Baobab-Lumiere-Kribi-2026!"
OTHER_PASSWORD = "Mangrove-Sanaga-Ebolowa-77?"


@pytest.fixture
def data_dir(tmp_path: Path) -> Path:
    return tmp_path / "PIO"


@pytest.fixture
def settings(data_dir: Path) -> Settings:
    # Low Argon2 cost keeps the suite fast; production keeps 64 MiB / 3 iterations.
    return Settings(data_dir=data_dir, kdf_memory_kib=1024, kdf_iterations=1)


class EngineClient:
    """Test client that always sends the engine token and the current session bearer."""

    def __init__(self, client: TestClient, token: str) -> None:
        self.client = client
        self.engine_token = token
        self.session: str | None = None

    def headers(self, extra: dict[str, str] | None = None) -> dict[str, str]:
        h = {"X-Engine-Token": self.engine_token}
        if self.session:
            h["Authorization"] = f"Bearer {self.session}"
        return h | (extra or {})

    def request(self, method: str, path: str, **kwargs: Any) -> Any:
        headers = self.headers(kwargs.pop("headers", None))
        return self.client.request(method, f"/api/v1{path}", headers=headers, **kwargs)

    def get(self, path: str, **kw: Any) -> Any:
        return self.request("GET", path, **kw)

    def post(self, path: str, **kw: Any) -> Any:
        return self.request("POST", path, **kw)

    def put(self, path: str, **kw: Any) -> Any:
        return self.request("PUT", path, **kw)

    def patch(self, path: str, **kw: Any) -> Any:
        return self.request("PATCH", path, **kw)

    def delete(self, path: str, **kw: Any) -> Any:
        return self.request("DELETE", path, **kw)

    def register(self, email: str = "awa@example.com", password: str = STRONG_PASSWORD,
                 name: str = "Awa Ndjock", locale: str = "fr") -> dict[str, Any]:
        r = self.post("/auth/register", json={
            "display_name": name, "email": email, "password": password,
            "confirm_password": password, "locale": locale, "accept_terms": True})
        assert r.status_code == 201, r.text
        body = r.json()
        self.session = body["session_token"]
        return body

    @property
    def state(self) -> Any:
        return self.client.app.state.engine  # type: ignore[attr-defined]


@pytest.fixture
def engine_client(settings: Settings) -> Iterator[EngineClient]:
    token = secrets.token_urlsafe(32)
    app = create_app(settings, token)
    with TestClient(app, base_url="http://127.0.0.1", raise_server_exceptions=False) as client:
        yield EngineClient(client, token)


@pytest.fixture
def signed_in(engine_client: EngineClient) -> EngineClient:
    engine_client.register()
    return engine_client


@pytest.fixture(autouse=True)
def _no_env_leak(monkeypatch: pytest.MonkeyPatch) -> None:
    for key in list(os.environ):
        if key.startswith("OPX_"):
            monkeypatch.delenv(key, raising=False)
