"""Event bus feeding the ``/api/v1/events`` WebSocket (arch §5.3).

Publishing is thread-safe: services running in the request thread pool or in background
jobs call :meth:`EventBus.publish`, which hands the event to the event loop.
"""

from __future__ import annotations

import asyncio
import contextlib
import json
import threading
from typing import Any

import structlog
from fastapi import WebSocket, WebSocketDisconnect

from core.timeutil import now_iso

log = structlog.get_logger(__name__)

KEEPALIVE_SECONDS = 25.0
QUEUE_SIZE = 500


class EventBus:
    def __init__(self) -> None:
        self._subscribers: set[asyncio.Queue[str]] = set()
        self._loop: asyncio.AbstractEventLoop | None = None
        self._lock = threading.Lock()

    def bind_loop(self, loop: asyncio.AbstractEventLoop) -> None:
        self._loop = loop

    def _deliver(self, payload: str) -> None:
        with self._lock:
            queues = list(self._subscribers)
        for q in queues:
            if q.full():
                with contextlib.suppress(asyncio.QueueEmpty):
                    q.get_nowait()
            q.put_nowait(payload)

    def publish(self, event_type: str, data: dict[str, Any] | None = None) -> None:
        payload = json.dumps({"type": event_type, "at": now_iso(), "data": data or {}})
        loop = self._loop
        if loop is None or loop.is_closed():
            return
        try:
            running = asyncio.get_running_loop()
        except RuntimeError:
            running = None
        if running is loop:
            self._deliver(payload)
        else:
            loop.call_soon_threadsafe(self._deliver, payload)

    @property
    def subscriber_count(self) -> int:
        return len(self._subscribers)

    async def serve(self, websocket: WebSocket) -> None:
        await websocket.accept()
        queue: asyncio.Queue[str] = asyncio.Queue(maxsize=QUEUE_SIZE)
        with self._lock:
            self._subscribers.add(queue)
        try:
            await websocket.send_text(json.dumps({"type": "connected", "at": now_iso(), "data": {}}))
            while True:
                try:
                    payload = await asyncio.wait_for(queue.get(), timeout=KEEPALIVE_SECONDS)
                except TimeoutError:
                    payload = json.dumps({"type": "ping", "at": now_iso(), "data": {}})
                await websocket.send_text(payload)
        except WebSocketDisconnect:
            pass
        except Exception as exc:  # noqa: BLE001 - a broken socket must not kill the engine
            log.warning("websocket_closed", error=type(exc).__name__)
        finally:
            with self._lock:
                self._subscribers.discard(queue)
