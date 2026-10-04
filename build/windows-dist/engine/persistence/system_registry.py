"""
System Registry — Manages the unencrypted basic user profile data (profiles.json)
necessary for bootstrapping the application before the SQLCipher database is unlocked.
"""

import json
import os
import asyncio
from pathlib import Path
from typing import Dict, List, Optional
import structlog
from pydantic import BaseModel

log = structlog.get_logger(__name__)

class ProfileEntry(BaseModel):
    user_id: str
    email: str
    display_name: str
    password_hash: str
    recovery_hash: str
    password_salt_hex: str
    wrapped_key_hex: str
    recovery_wrapped_key_hex: Optional[str] = None
    created_at: str
    failed_login_attempts: int = 0
    is_locked: bool = False
    lock_until: Optional[str] = None

class SystemRegistry:
    def __init__(self, data_dir: Optional[Path] = None):
        if data_dir is None:
            self._data_dir = Path(os.environ.get("OPX_DATA_DIR", Path.home() / ".opportunex"))
        else:
            self._data_dir = data_dir
        self._data_dir.mkdir(parents=True, exist_ok=True)
        self._registry_file = self._data_dir / "profiles.json"
        self._lock = asyncio.Lock()
        
    async def _read_all(self) -> Dict[str, dict]:
        """Reads the entire registry into a dictionary."""
        if not self._registry_file.exists():
            return {}
        try:
            # For a small file, synchronous read is fine.
            with open(self._registry_file, "r", encoding="utf-8") as f:
                data = json.load(f)
                return data.get("profiles", {})
        except json.JSONDecodeError:
            log.error("profiles_json_corrupted", path=str(self._registry_file))
            return {}
            
    async def _write_all(self, profiles: Dict[str, dict]) -> None:
        """Writes the entire registry to disk."""
        data = {"profiles": profiles}
        # Write to temp file then rename for atomic update
        temp_file = self._registry_file.with_suffix(".json.tmp")
        with open(temp_file, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        temp_file.replace(self._registry_file)

    async def get_all_profiles(self) -> List[ProfileEntry]:
        async with self._lock:
            data = await self._read_all()
            return [ProfileEntry(**v) for v in data.values()]

    async def get_profile_by_email(self, email: str) -> Optional[ProfileEntry]:
        email_lower = email.strip().lower()
        async with self._lock:
            data = await self._read_all()
            for v in data.values():
                if v["email"] == email_lower:
                    return ProfileEntry(**v)
        return None

    async def get_profile_by_id(self, user_id: str) -> Optional[ProfileEntry]:
        async with self._lock:
            data = await self._read_all()
            if user_id in data:
                return ProfileEntry(**data[user_id])
        return None

    async def upsert_profile(self, profile: ProfileEntry) -> None:
        async with self._lock:
            data = await self._read_all()
            data[profile.user_id] = profile.model_dump()
            await self._write_all(data)

    async def delete_profile(self, user_id: str) -> None:
        async with self._lock:
            data = await self._read_all()
            if user_id in data:
                del data[user_id]
                await self._write_all(data)

# Singleton instance
registry = SystemRegistry()
