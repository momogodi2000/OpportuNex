import os
import re
import uuid
from pathlib import Path
try:
    import nacl.secret
    import nacl.utils
except ImportError:
    pass

class Vault:
    def __init__(self, key: bytes, base_dir: str = "~/.opportunex/vault/"):
        self.key = key
        self.base_dir = Path(base_dir).expanduser()
        self.base_dir.mkdir(parents=True, exist_ok=True)
        self.box = nacl.secret.SecretBox(self.key)

    def is_initialized(self) -> bool:
        return len(self.key) == nacl.secret.SecretBox.KEY_SIZE

    def _get_path(self, user_id: str, document_id: str) -> Path:
        if not re.match(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', document_id, re.IGNORECASE):
            raise ValueError("Invalid document ID")
        user_dir = (self.base_dir / user_id).resolve()
        if not str(user_dir).startswith(str(self.base_dir.resolve())):
            raise ValueError("Path traversal attempt")
        user_dir.mkdir(parents=True, exist_ok=True)
        doc_path = (user_dir / document_id).resolve()
        if not str(doc_path).startswith(str(user_dir)):
            raise ValueError("Path traversal attempt")
        return doc_path

    def store(self, data: bytes, user_id: str) -> str:
        nonce = nacl.utils.random(nacl.secret.SecretBox.NONCE_SIZE)
        encrypted = self.box.encrypt(data, nonce)
        document_id = str(uuid.uuid4())
        doc_path = self._get_path(user_id, document_id)
        doc_path.write_bytes(encrypted)
        return document_id

    def retrieve(self, document_id: str, user_id: str) -> bytes:
        doc_path = self._get_path(user_id, document_id)
        encrypted = doc_path.read_bytes()
        return self.box.decrypt(encrypted)

    def delete(self, document_id: str, user_id: str) -> None:
        doc_path = self._get_path(user_id, document_id)
        if doc_path.exists():
            size = doc_path.stat().st_size
            with open(doc_path, "ba+") as f:
                f.write(os.urandom(size))
                f.flush()
                os.fsync(f.fileno())
            doc_path.unlink()
