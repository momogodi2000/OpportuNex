"""UUID v7 identifiers (ADR-004): time-ordered, sortable, sync-friendly.

Within one process, identifiers are strictly increasing even when several are generated
in the same millisecond: the 12-bit ``rand_a`` field is used as a counter (RFC 9562 §6.2,
method 1).
"""

from __future__ import annotations

import os
import threading
import time
import uuid

_lock = threading.Lock()
_last_ms = 0
_counter = 0


def uuid7() -> str:
    global _last_ms, _counter
    with _lock:
        ms = time.time_ns() // 1_000_000
        if ms > _last_ms:
            _last_ms = ms
            _counter = int.from_bytes(os.urandom(2), "big") & 0x3FF  # leave headroom
        else:
            _counter += 1
            if _counter > 0xFFF:
                _last_ms += 1
                _counter = 0
        ms, counter = _last_ms, _counter
    rand_b = int.from_bytes(os.urandom(8), "big") & 0x3FFFFFFFFFFFFFFF
    value = (ms & 0xFFFFFFFFFFFF) << 80
    value |= 0x7 << 76
    value |= counter << 64
    value |= 0b10 << 62
    value |= rand_b
    return str(uuid.UUID(int=value))
