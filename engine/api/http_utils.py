"""HTTP helpers shared by routers."""

from __future__ import annotations

import unicodedata
from urllib.parse import quote


def attachment(filename: str) -> dict[str, str]:
    """Content-Disposition with an ASCII fallback and the RFC 5987 UTF-8 name."""
    ascii_name = unicodedata.normalize("NFKD", filename).encode("ascii", "ignore").decode("ascii")
    ascii_name = "".join(c for c in ascii_name if c.isalnum() or c in "._- ").strip() or "download"
    return {"Content-Disposition": f"attachment; filename=\"{ascii_name}\"; filename*=UTF-8''{quote(filename)}"}
