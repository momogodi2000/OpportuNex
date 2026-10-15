"""Alembic environment: always runs on the connection handed over by persistence.database.

Migrations are executed programmatically against an already-unlocked SQLCipher connection;
there is no ``alembic.ini`` and no URL (the encryption key must never appear in config).
"""

from alembic import context

connection = context.config.attributes.get("connection")
if connection is None:
    raise RuntimeError("migrations must be run through persistence.database.migrate()")

context.configure(connection=connection, render_as_batch=True, transaction_per_migration=False)
with context.begin_transaction():
    context.run_migrations()
