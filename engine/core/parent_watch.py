"""Stop the engine when the desktop app that started it is gone (crash, forced kill).

The UI closes stdin right after sending the token, so the engine cannot rely on stdin EOF. Instead the UI
passes ``--parent-pid``; a daemon thread waits for that process and calls ``on_exit`` once it has ended,
which releases the single-instance lock for the next launch.
"""

from __future__ import annotations

import os
import sys
import threading
import time
from collections.abc import Callable

POLL_SECONDS = 2.0


def _wait_windows(pid: int) -> None:
    # The platform check lets type checkers on Linux and macOS skip these Win32-only calls (CI runs mypy there).
    if sys.platform != "win32":
        raise OSError("Win32 only")
    else:
        import ctypes
        from ctypes import wintypes

        synchronize, infinite = 0x00100000, 0xFFFFFFFF
        kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
        kernel32.OpenProcess.restype = wintypes.HANDLE
        kernel32.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
        kernel32.WaitForSingleObject.argtypes = [wintypes.HANDLE, wintypes.DWORD]
        kernel32.CloseHandle.argtypes = [wintypes.HANDLE]
        handle = kernel32.OpenProcess(synchronize, False, pid)
        if not handle:  # already gone (or not ours): nothing to wait for
            return
        try:
            kernel32.WaitForSingleObject(handle, infinite)
        finally:
            kernel32.CloseHandle(handle)


def _alive_posix(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def _wait_posix(pid: int) -> None:
    while _alive_posix(pid):
        time.sleep(POLL_SECONDS)


def wait_for_exit(pid: int) -> None:
    """Block until process ``pid`` has ended."""
    if sys.platform == "win32":
        _wait_windows(pid)
    else:
        _wait_posix(pid)


def watch_parent(pid: int, on_exit: Callable[[], None]) -> threading.Thread:
    def _run() -> None:
        wait_for_exit(pid)
        on_exit()

    thread = threading.Thread(target=_run, name="parent-watch", daemon=True)
    thread.start()
    return thread
