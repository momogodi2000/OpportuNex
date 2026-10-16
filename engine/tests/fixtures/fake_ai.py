"""Scriptable local stand-in for AI providers (tests only, nothing leaves the machine).

Implements the wire formats of the OpenAI-compatible family, Anthropic, Gemini and Ollama.
Tests queue answers with :meth:`FakeAI.answer` (model text) or :meth:`FakeAI.fail` (HTTP status),
then inspect :attr:`FakeAI.requests` to assert on what was actually sent.
"""

from __future__ import annotations

import json
import threading
from collections import deque
from dataclasses import dataclass
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any


@dataclass
class Seen:
    method: str
    path: str
    headers: dict[str, str]
    body: dict[str, Any] | None

    @property
    def text(self) -> str:
        return json.dumps(self.body, ensure_ascii=False) if self.body else ""


class _Handler(BaseHTTPRequestHandler):
    server: _Server

    def log_message(self, *args: object) -> None:
        pass

    def _send(self, status: int, payload: Any, headers: dict[str, str] | None = None) -> None:
        data = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        for k, v in (headers or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self) -> None:
        self.server.owner.requests.append(Seen("GET", self.path, dict(self.headers.items()), None))
        models = self.server.owner.models
        if self.path.endswith("/api/tags"):
            self._send(200, {"models": [{"name": m} for m in models]})
        elif "/v1beta/models" in self.path:
            self._send(200, {"models": [{"name": f"models/{m}"} for m in models]})
        elif self.path.endswith("/models"):
            self._send(200, {"data": [{"id": m} for m in models]})
        else:
            self._send(404, {"error": "not found"})

    def do_POST(self) -> None:
        length = int(self.headers.get("Content-Length") or 0)
        body = json.loads(self.rfile.read(length) or b"{}")
        owner = self.server.owner
        owner.requests.append(Seen("POST", self.path, dict(self.headers.items()), body))
        step = owner.queue.popleft() if owner.queue else ("text", "{}")
        if step[0] == "status":
            status, headers = step[1], step[2]
            self._send(status, {"error": {"message": "scripted failure"}}, headers)
            return
        text = step[1]
        if self.path.endswith("/chat/completions"):
            self._send(
                200,
                {"choices": [{"message": {"content": text}}], "usage": {"prompt_tokens": 120, "completion_tokens": 30}},
            )
        elif self.path.endswith("/messages"):
            self._send(
                200, {"content": [{"type": "text", "text": text}], "usage": {"input_tokens": 100, "output_tokens": 20}}
            )
        elif ":generateContent" in self.path:
            self._send(
                200,
                {
                    "candidates": [{"content": {"parts": [{"text": text}]}}],
                    "usageMetadata": {"promptTokenCount": 90, "candidatesTokenCount": 10},
                },
            )
        elif self.path.endswith("/api/chat"):
            self._send(200, {"message": {"content": text}, "prompt_eval_count": 80, "eval_count": 15})
        else:
            self._send(404, {"error": "not found"})


class _Server(ThreadingHTTPServer):
    owner: FakeAI


class FakeAI:
    def __init__(self) -> None:
        self.server = _Server(("127.0.0.1", 0), _Handler)
        self.server.owner = self
        self.port = self.server.server_address[1]
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.queue: deque[tuple[Any, ...]] = deque()
        self.requests: list[Seen] = []
        self.models = ["fake-small", "fake-large"]

    def __enter__(self) -> FakeAI:
        self.thread.start()
        return self

    def __exit__(self, *exc: object) -> None:
        self.server.shutdown()
        self.server.server_close()

    def url(self, path: str = "/v1") -> str:
        return f"http://127.0.0.1:{self.port}{path}"

    def answer(self, payload: dict[str, Any] | str) -> None:
        self.queue.append(("text", payload if isinstance(payload, str) else json.dumps(payload, ensure_ascii=False)))

    def fail(self, status: int, headers: dict[str, str] | None = None) -> None:
        self.queue.append(("status", status, headers or {}))

    @property
    def posts(self) -> list[Seen]:
        return [r for r in self.requests if r.method == "POST"]
