"""Baseline: the schema shipped in pio_schema.sql (schema version 1.0.0).

A fresh database is created by executing pio_schema.sql directly (it stamps this revision
itself), so this migration never runs its upgrade in practice. It exists so Alembic knows
the root of the revision graph.

Revision ID: 0001_baseline
Revises:
"""

revision = "0001_baseline"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    raise RuntimeError("baseline is created from pio_schema.sql, not by Alembic")


def downgrade() -> None:
    raise RuntimeError("cannot downgrade below the baseline")
