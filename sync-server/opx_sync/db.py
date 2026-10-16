"""Server schema: account metadata and opaque ciphertext only (arch §10.3). SQLite or PostgreSQL."""

from __future__ import annotations

from pathlib import Path

from sqlalchemy import (
    Boolean,
    Column,
    Engine,
    ForeignKey,
    Integer,
    LargeBinary,
    MetaData,
    String,
    Table,
    Text,
    UniqueConstraint,
    create_engine,
    event,
)

metadata = MetaData()

accounts = Table(
    "accounts",
    metadata,
    Column("id", String(36), primary_key=True),
    Column("email", String(254), nullable=False, unique=True),
    Column("email_verified", Boolean, nullable=False, default=False),
    Column("password_hash", Text, nullable=False),
    Column("totp_secret", String(64)),
    Column("totp_enabled", Boolean, nullable=False, default=False),
    # X25519 identity key: public half in clear (to receive organisation keys), private half sealed
    # with the account sync key by the client — opaque to the server.
    Column("identity_public_key", String(64)),
    Column("identity_private_sealed", Text),
    Column("bytes_used", Integer, nullable=False, default=0),
    Column("failed_logins", Integer, nullable=False, default=0),
    Column("locked_until", String(32)),
    Column("created_at", String(32), nullable=False),
)

email_tokens = Table(
    "email_tokens",
    metadata,
    Column("token_hash", String(64), primary_key=True),
    Column("account_id", String(36), ForeignKey("accounts.id", ondelete="CASCADE"), nullable=False),
    Column("purpose", String(16), nullable=False),  # verify | reset
    Column("expires_at", String(32), nullable=False),
    Column("used_at", String(32)),
)

devices = Table(
    "devices",
    metadata,
    Column("id", String(36), primary_key=True),
    Column("account_id", String(36), ForeignKey("accounts.id", ondelete="CASCADE"), nullable=False, index=True),
    Column("name", String(120), nullable=False),
    Column("platform", String(16), nullable=False),
    Column("public_key", String(64), nullable=False),
    Column("status", String(16), nullable=False),  # pending | active | revoked
    Column("envelope", Text),  # sync key sealed to this device's public key by an approving device
    Column("created_at", String(32), nullable=False),
    Column("last_seen_at", String(32)),
)

sessions = Table(
    "sessions",
    metadata,
    Column("token_hash", String(64), primary_key=True),
    Column("account_id", String(36), ForeignKey("accounts.id", ondelete="CASCADE"), nullable=False),
    Column("device_id", String(36), ForeignKey("devices.id", ondelete="CASCADE"), nullable=False),
    Column("expires_at", String(32), nullable=False),
)

changes = Table(
    "changes",
    metadata,
    Column("seq", Integer, primary_key=True, autoincrement=True),
    Column("scope", String(48), nullable=False, index=True),  # user:<account> | org:<org>
    Column("op_id", String(36), nullable=False),
    Column("device_id", String(36), nullable=False),
    Column("key_version", Integer, nullable=False),
    Column("nonce", String(48), nullable=False),
    Column("ciphertext", LargeBinary, nullable=False),
    Column("size", Integer, nullable=False),
    Column("created_at", String(32), nullable=False),
    UniqueConstraint("scope", "op_id", name="uq_changes_scope_op"),
)

orgs = Table(
    "orgs",
    metadata,
    Column("id", String(36), primary_key=True),
    Column("created_by", String(36), nullable=False),
    Column("key_version", Integer, nullable=False, default=1),
    Column("rotation_needed", Boolean, nullable=False, default=False),
    Column("created_at", String(32), nullable=False),
)

org_members = Table(
    "org_members",
    metadata,
    Column("org_id", String(36), ForeignKey("orgs.id", ondelete="CASCADE"), primary_key=True),
    Column("account_id", String(36), ForeignKey("accounts.id", ondelete="CASCADE"), primary_key=True),
    Column("role", String(16), nullable=False),  # owner | admin | editor | viewer
    Column("joined_at", String(32), nullable=False),
)

org_keys = Table(
    "org_keys",
    metadata,
    Column("org_id", String(36), ForeignKey("orgs.id", ondelete="CASCADE"), primary_key=True),
    Column("account_id", String(36), ForeignKey("accounts.id", ondelete="CASCADE"), primary_key=True),
    Column("key_version", Integer, primary_key=True),
    Column("envelope", Text, nullable=False),  # organisation key sealed to the member's identity key
)

org_invites = Table(
    "org_invites",
    metadata,
    Column("id", String(36), primary_key=True),
    Column("org_id", String(36), ForeignKey("orgs.id", ondelete="CASCADE"), nullable=False),
    Column("email", String(254)),
    Column("role", String(16), nullable=False),
    Column("token_hash", String(64), nullable=False, unique=True),
    Column("created_by", String(36), nullable=False),
    Column("expires_at", String(32), nullable=False),
    Column("accepted_by", String(36)),
    Column("accepted_at", String(32)),
    Column("revoked_at", String(32)),
)

org_audit = Table(
    "org_audit",
    metadata,
    Column("id", Integer, primary_key=True, autoincrement=True),
    Column("org_id", String(36), ForeignKey("orgs.id", ondelete="CASCADE"), nullable=False, index=True),
    Column("account_id", String(36)),
    Column("action", String(48), nullable=False),
    Column("target", String(254)),
    Column("created_at", String(32), nullable=False),
)


def make_engine(url: str) -> Engine:
    if url.startswith("sqlite:///"):
        path = url.removeprefix("sqlite:///")
        if path and path != ":memory:":
            Path(path).parent.mkdir(parents=True, exist_ok=True)
        engine = create_engine(url, connect_args={"check_same_thread": False})

        @event.listens_for(engine, "connect")
        def _pragmas(dbapi_conn, _record) -> None:  # type: ignore[no-untyped-def]
            cur = dbapi_conn.cursor()
            cur.execute("PRAGMA foreign_keys = ON")
            cur.execute("PRAGMA journal_mode = WAL")
            cur.execute("PRAGMA busy_timeout = 10000")
            cur.close()
    else:
        engine = create_engine(url, pool_pre_ping=True)
    metadata.create_all(engine)
    return engine
