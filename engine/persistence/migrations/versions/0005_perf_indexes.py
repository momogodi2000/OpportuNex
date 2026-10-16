"""Index for the dashboard recommendations (arch §8.6: list queries under 100 ms at 100 000 opportunities).

The recommendations read the most recently checked open opportunities. Without an index on
``last_checked_at`` SQLite sorted the whole table, decrypting every page: 2.8 s at 100 000 opportunities.
With it, the scan walks the index in order and stops once enough candidates are found.

Revision ID: 0005_perf_indexes
Revises: 0004_sync
"""

from __future__ import annotations

from alembic import op

revision = "0005_perf_indexes"
down_revision = "0004_sync"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("CREATE INDEX IF NOT EXISTS ix_opp_last_checked ON opportunities(last_checked_at)")
    op.execute("UPDATE application_settings SET value = '1.0.3' WHERE key = 'schema.version'")
    op.execute("PRAGMA user_version = 103")


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_opp_last_checked")
    op.execute("UPDATE application_settings SET value = '1.0.2' WHERE key = 'schema.version'")
    op.execute("PRAGMA user_version = 102")
