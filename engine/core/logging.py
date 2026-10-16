"""Structured JSON logging with automatic redaction (spec ENF-SEC: logs expurgés).

Logs go to ``<data_dir>/logs/engine.log`` (rotated) and to stderr. Every event passes
through :func:`security.redaction.redact` so e-mails, tokens, keys and phone numbers never
reach disk.
"""

from __future__ import annotations

import logging
import logging.handlers
import sys
from collections.abc import MutableMapping
from pathlib import Path
from typing import Any

import structlog

from security.redaction import redact


def _redact_processor(_logger: Any, _name: str, event: MutableMapping[str, Any]) -> MutableMapping[str, Any]:
    for key, value in list(event.items()):
        if isinstance(value, str):
            event[key] = redact(value)
    return event


def configure_logging(log_dir: Path | None, level: str = "INFO") -> None:
    handlers: list[logging.Handler] = [logging.StreamHandler(sys.stderr)]
    if log_dir is not None:
        log_dir.mkdir(parents=True, exist_ok=True)
        handlers.append(
            logging.handlers.RotatingFileHandler(
                log_dir / "engine.log", maxBytes=5 * 1024 * 1024, backupCount=5, encoding="utf-8"
            )
        )
    root = logging.getLogger()
    for h in list(root.handlers):
        root.removeHandler(h)
    for h in handlers:
        h.setFormatter(logging.Formatter("%(message)s"))
        root.addHandler(h)
    root.setLevel(level)
    # Third-party loggers can echo request data; keep them quiet.
    for noisy in ("uvicorn.access", "httpx", "httpcore", "apscheduler"):
        logging.getLogger(noisy).setLevel(logging.WARNING)

    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso", utc=True),
            _redact_processor,
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.make_filtering_bound_logger(logging.getLevelName(level)),
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=False,
    )
