from fastapi import APIRouter
import sys
import time
import os
import signal
from typing import Dict, Any

router = APIRouter(tags=["system"])
START_TIME = time.time()

@router.get("/health")
async def health_check() -> Dict[str, Any]:
    return {
        "status": "healthy",
        "version": "0.1.0",
        "uptime_seconds": time.time() - START_TIME
    }

@router.get("/version")
async def get_version() -> Dict[str, Any]:
    return {
        "version": "0.1.0",
        "python": sys.version,
        "build_date": "2026-10-02T11:54:06+01:00"
    }

@router.post("/shutdown")
async def shutdown() -> Dict[str, str]:
    os.kill(os.getpid(), signal.SIGTERM)
    return {"detail": "Shutdown signal sent"}
