"""
WebSocket event bus for the OpportuNex engine.
Provides real-time progress updates to the Flutter UI.
"""

from __future__ import annotations

import asyncio
import json
from dataclasses import asdict, dataclass
from datetime import datetime
from enum import StrEnum
from typing import Any, Optional
from uuid import UUID

import structlog
from fastapi import WebSocket, WebSocketDisconnect

log = structlog.get_logger(__name__)


class EventType(StrEnum):
    # Search and collection
    SEARCH_STARTED = "search.started"
    SEARCH_PROGRESS = "search.progress"
    SEARCH_COMPLETED = "search.completed"
    SEARCH_FAILED = "search.failed"
    SEARCH_CANCELLED = "search.cancelled"

    # Source scanning
    SOURCE_SCAN_STARTED = "source.scan.started"
    SOURCE_SCAN_PROGRESS = "source.scan.progress"
    SOURCE_SCAN_COMPLETED = "source.scan.completed"
    SOURCE_SCAN_FAILED = "source.scan.failed"

    # AI analysis
    AI_ANALYSIS_STARTED = "ai.analysis.started"
    AI_ANALYSIS_PROGRESS = "ai.analysis.progress"
    AI_ANALYSIS_COMPLETED = "ai.analysis.completed"
    AI_ANALYSIS_FAILED = "ai.analysis.failed"

    # Exports
    EXPORT_STARTED = "export.started"
    EXPORT_COMPLETED = "export.completed"
    EXPORT_FAILED = "export.failed"

    # Backup
    BACKUP_STARTED = "backup.started"
    BACKUP_COMPLETED = "backup.completed"
    BACKUP_FAILED = "backup.failed"

    # Monitor alerts
    MONITOR_NEW_RESULTS = "monitor.new_results"
    DEADLINE_REMINDER = "deadline.reminder"

    # Sync
    SYNC_STARTED = "sync.started"
    SYNC_PROGRESS = "sync.progress"
    SYNC_COMPLETED = "sync.completed"
    SYNC_CONFLICT = "sync.conflict"


@dataclass
class ProgressEvent:
    type: str
    job_id: Optional[str]
    current: int
    total: int
    message: str
    data: Optional[dict] = None
    timestamp: str = ""

    def __post_init__(self) -> None:
        if not self.timestamp:
            self.timestamp = datetime.utcnow().isoformat() + "Z"

    def to_json(self) -> str:
        return json.dumps({
            "type": self.type,
            "job_id": self.job_id,
            "current": self.current,
            "total": self.total,
            "message": self.message,
            "data": self.data or {},
            "timestamp": self.timestamp,
        })


class EventBus:
    """
    In-process pub/sub event bus.
    Single subscriber per session (the Flutter WebSocket connection).
    """

    def __init__(self) -> None:
        self._queue: asyncio.Queue[str] = asyncio.Queue(maxsize=1000)
        self._connected: bool = False

    async def publish(self, event: ProgressEvent) -> None:
        """Publish an event. Drops oldest if queue is full."""
        try:
            self._queue.put_nowait(event.to_json())
        except asyncio.QueueFull:
            # Drop oldest item and retry
            try:
                self._queue.get_nowait()
                self._queue.put_nowait(event.to_json())
            except (asyncio.QueueEmpty, asyncio.QueueFull):
                pass

    async def emit(
        self,
        event_type: EventType,
        job_id: Optional[str] = None,
        current: int = 0,
        total: int = 0,
        message: str = "",
        data: Optional[dict] = None,
    ) -> None:
        """Convenience method to create and publish an event."""
        await self.publish(ProgressEvent(
            type=event_type,
            job_id=job_id,
            current=current,
            total=total,
            message=message,
            data=data,
        ))

    async def websocket_handler(self, websocket: WebSocket) -> None:
        """
        Handle the WebSocket connection from the Flutter UI.
        Streams events from the queue to the client.
        """
        await websocket.accept()
        self._connected = True
        log.info("websocket_connected")

        # Send ping immediately to confirm connection
        await websocket.send_text(json.dumps({"type": "connected", "timestamp": datetime.utcnow().isoformat() + "Z"}))

        try:
            while True:
                # Wait for either a new event or a ping from client
                try:
                    message = await asyncio.wait_for(
                        self._queue.get(), timeout=25.0
                    )
                    await websocket.send_text(message)
                except asyncio.TimeoutError:
                    # Send keepalive ping
                    await websocket.send_text(json.dumps({"type": "ping"}))

        except WebSocketDisconnect:
            log.info("websocket_disconnected")
        except Exception as e:
            log.error("websocket_error", exc=str(e))
        finally:
            self._connected = False


# Global event bus instance (one per engine process)
event_bus = EventBus()
