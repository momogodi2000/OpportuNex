"""Product identity: declare the Opportunex User-Agent and schema version 1.0.1.

The baseline seeded a User-Agent pointing at the former project URL. Sources must see an
explicit, truthful identity (EF-05.07), so it is updated here.

Revision ID: 0002_product_identity
Revises: 0001_baseline
"""

from alembic import op

revision = "0002_product_identity"
down_revision = "0001_baseline"
branch_labels = None
depends_on = None

_NEW_UA = "Opportunex/1.0 (+https://github.com/momogodi2000/OpportuNex)"
_OLD_UA = "PIO/1.0 (+https://github.com/protegeqv/pio)"


def upgrade() -> None:
    op.execute(f"UPDATE application_settings SET value = '{_NEW_UA}' WHERE key = 'http.user_agent'")
    op.execute("UPDATE application_settings SET value = '1.0.1' WHERE key = 'schema.version'")
    op.execute("PRAGMA user_version = 101")


def downgrade() -> None:
    op.execute(f"UPDATE application_settings SET value = '{_OLD_UA}' WHERE key = 'http.user_agent'")
    op.execute("UPDATE application_settings SET value = '1.0.0' WHERE key = 'schema.version'")
    op.execute("PRAGMA user_version = 100")
