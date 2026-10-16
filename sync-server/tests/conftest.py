from __future__ import annotations

import base64
import re
import secrets
from collections.abc import Iterator
from pathlib import Path
from typing import Any

import pytest
from fastapi.testclient import TestClient

from opx_sync.app import create_app
from opx_sync.config import Settings

PASSWORD = "Baobab-Lumiere-Kribi-2026!"


def key() -> str:
    return base64.b64encode(secrets.token_bytes(32)).decode()


class Server:
    def __init__(self, client: TestClient) -> None:
        self.client = client

    @property
    def mail(self) -> list[Any]:
        return self.client.app.state.mailer.sent  # type: ignore[attr-defined]

    def code(self, to: str) -> str:
        body = next(m.body for m in reversed(self.mail) if m.to == to)
        return re.search(r"Code : (\S+)", body).group(1)  # type: ignore[union-attr]

    def account(self, email: str, device: str = "PC") -> dict[str, Any]:
        """Registered, verified and signed-in account with one device."""
        assert self.client.post("/v1/accounts", json={"email": email, "password": PASSWORD}).status_code == 201
        assert self.client.post("/v1/accounts/verify", json={"token": self.code(email)}).status_code == 200
        return self.login(email, device)

    def login(self, email: str, device: str = "PC", public_key: str | None = None, **extra: Any) -> dict[str, Any]:
        r = self.client.post(
            "/v1/sessions",
            json={"email": email, "password": PASSWORD,
                  "device": {"name": device, "platform": "windows", "public_key": public_key or key()}, **extra},
        )  # fmt: skip
        assert r.status_code == 201, r.text
        body = r.json()
        body["h"] = {"Authorization": f"Bearer {body['token']}"}
        return dict(body)


@pytest.fixture
def server(tmp_path: Path) -> Iterator[Server]:
    s = Settings(
        database_url=f"sqlite:///{tmp_path / 'sync.db'}", argon2_memory_kib=1024, argon2_iterations=1, quota_mb=1
    )
    with TestClient(create_app(s)) as c:
        yield Server(c)
