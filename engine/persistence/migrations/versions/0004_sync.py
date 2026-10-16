"""End-to-end encrypted sync: change capture, merge bookkeeping and local key store (arch §10, D-31).

* ``sync_shadow``  — last synchronised version of each record (base of the three-way merge).
* ``sync_cursors`` — pull position per scope (``user`` or ``org:<id>``).
* ``sync_keys``    — device private key, account sync key, identity key, organisation keys
                     (protected by the SQLCipher encryption of this database).
* ``sync_guard``   — holds one row while remote changes are applied, so they are not re-sent.
* Triggers append to ``sync_outbox`` with a Lamport time, only while sync is linked (a row in
  ``sync_state``) and never under the guard. Child rows whose integer keys differ between devices
  (links, tags, checklist...) mark their parent record instead (D-32).

Revision ID: 0004_sync
Revises: 0003_skills_seed
"""

from __future__ import annotations

from alembic import op

revision = "0004_sync"
down_revision = "0003_skills_seed"
branch_labels = None
depends_on = None

# (table, kind, id expression with {r} = NEW/OLD, parent record?, columns watched on UPDATE or None = all)
CAPTURE: list[tuple[str, str, str, bool, str | None]] = [
    (
        "user_profiles",
        "profile",
        "'profile'",
        False,
        "full_name, country_code, city, professional_status, current_occupation, experience_years, highest_education, "
        "work_mode_pref, willing_to_relocate, contact_phone, bio, summary_text, summary_approved",
    ),
    ("profile_preferred_locations", "profile", "'profile'", False, None),
    ("profile_links", "profile", "'profile'", False, None),
    ("user_custom_objectives", "profile", "'profile'", False, None),
    ("user_skills", "profile", "'profile'", False, None),
    ("user_languages", "profile", "'profile'", False, None),
    ("user_objectives", "profile", "'profile'", False, None),
    (
        "matching_weights",
        "profile",
        "'profile'",
        False,
        "w_skills, w_education, w_experience, w_location, w_language, w_objectives, w_deadline",
    ),
    ("education_records", "education", "{r}.id", True, None),
    ("work_experiences", "experience", "{r}.id", True, None),
    ("certifications", "certification", "{r}.id", True, None),
    ("project_profiles", "project", "{r}.id", True, None),
    (
        "saved_opportunities",
        "saved",
        "{r}.id",
        True,
        "priority, interest, ineligible_reason, personal_deadline, archived, workspace_id, organization_id",
    ),
    ("saved_opportunity_tags", "saved", "{r}.saved_id", False, None),
    ("checklist_items", "saved", "{r}.saved_id", False, None),
    ("applications", "application", "{r}.id", True, "status, submitted_on, submission_ref, outcome_on, outcome_note"),
    ("application_status_history", "application", "{r}.application_id", False, None),
    ("application_events", "event", "{r}.id", True, None),
    ("application_notes", "note", "{r}.id", True, None),
    ("generated_documents", "document", "{r}.id", True, "title, current_version"),
    ("generated_document_versions", "document", "{r}.document_id", False, None),
    (
        "research_workspaces",
        "workspace",
        "{r}.id",
        True,
        "name, description, template_code, color, archived, organization_id",
    ),
    ("workspace_opportunities", "workspace", "{r}.workspace_id", False, None),
    ("workspace_notes", "ws_note", "{r}.id", True, None),
    (
        "monitors",
        "monitor",
        "{r}.id",
        True,
        "name, filters, schedule_kind, schedule_expr, min_score, enabled, workspace_id, query_id",
    ),
    ("monitor_sources", "monitor", "{r}.monitor_id", False, None),
]

ACTIVE = "EXISTS (SELECT 1 FROM sync_state) AND NOT EXISTS (SELECT 1 FROM sync_guard)"


def _enqueue(kind: str, id_expr: str, operation: str) -> str:
    return (
        "UPDATE sync_state SET lamport_clock = lamport_clock + 1; "
        "INSERT INTO sync_outbox(user_id, entity_table, entity_id, operation, lamport) "
        f"SELECT user_id, '{kind}', {id_expr}, '{operation}', lamport_clock FROM sync_state LIMIT 1;"
    )


def _triggers() -> list[str]:
    out: list[str] = []
    for table, kind, id_expr, parent, watched in CAPTURE:
        new, old = id_expr.format(r="NEW"), id_expr.format(r="OLD")
        of = f" OF {watched}" if watched else ""
        out += [
            f"CREATE TRIGGER trg_sync_{table}_ai AFTER INSERT ON {table} WHEN {ACTIVE} "
            f"BEGIN {_enqueue(kind, new, 'upsert')} END",
            f"CREATE TRIGGER trg_sync_{table}_au AFTER UPDATE{of} ON {table} WHEN {ACTIVE} "
            f"BEGIN {_enqueue(kind, new, 'upsert')} END",
            f"CREATE TRIGGER trg_sync_{table}_ad AFTER DELETE ON {table} WHEN {ACTIVE} "
            f"BEGIN {_enqueue(kind, old, 'delete' if parent else 'upsert')} END",
        ]
    # Saved searches only (search history stays on the device).
    out += [
        f"CREATE TRIGGER trg_sync_search_queries_ai AFTER INSERT ON search_queries WHEN {ACTIVE} AND NEW.is_saved = 1 "
        f"BEGIN {_enqueue('query', 'NEW.id', 'upsert')} END",
        f"CREATE TRIGGER trg_sync_search_queries_au AFTER UPDATE OF is_saved, saved_name, final_filters ON search_queries "
        f"WHEN {ACTIVE} AND (NEW.is_saved = 1 OR OLD.is_saved = 1) "
        f"BEGIN {_enqueue('query', 'NEW.id', 'upsert')} END",
        f"CREATE TRIGGER trg_sync_search_queries_ad AFTER DELETE ON search_queries WHEN {ACTIVE} AND OLD.is_saved = 1 "
        f"BEGIN {_enqueue('query', 'OLD.id', 'delete')} END",
    ]
    # Organisation card: only organisations linked to the server (remote_id), keyed by that id.
    watched = (
        "name, org_type, legal_status, registration_no, country_code, sector, description, annual_budget_band, website"
    )
    out += [
        f"CREATE TRIGGER trg_sync_organizations_au AFTER UPDATE OF {watched} ON organizations "
        f"WHEN {ACTIVE} AND NEW.remote_id IS NOT NULL BEGIN {_enqueue('org', 'NEW.remote_id', 'upsert')} END",
    ]
    return out


def _drop_names() -> list[str]:
    names = [f"trg_sync_{t}_{s}" for t, *_ in CAPTURE for s in ("ai", "au", "ad")]
    return [
        *names,
        "trg_sync_search_queries_ai",
        "trg_sync_search_queries_au",
        "trg_sync_search_queries_ad",
        "trg_sync_organizations_au",
    ]


def upgrade() -> None:
    op.execute(
        """CREATE TABLE sync_shadow (
            kind       TEXT NOT NULL,
            entity_id  TEXT NOT NULL,
            scope      TEXT NOT NULL,
            payload    TEXT NOT NULL CHECK (json_valid(payload)),
            lamport    INTEGER NOT NULL,
            PRIMARY KEY (kind, entity_id)
        ) STRICT"""
    )
    op.execute("CREATE TABLE sync_cursors (scope TEXT NOT NULL PRIMARY KEY, cursor INTEGER NOT NULL DEFAULT 0) STRICT")
    op.execute(
        """CREATE TABLE sync_keys (
            kind     TEXT NOT NULL CHECK (kind IN ('device','account','identity','org')),
            ref      TEXT NOT NULL,
            version  INTEGER NOT NULL DEFAULT 1,
            secret   BLOB NOT NULL,
            PRIMARY KEY (kind, ref, version)
        ) STRICT"""
    )
    op.execute("CREATE TABLE sync_guard (applying INTEGER NOT NULL) STRICT")
    op.execute("CREATE INDEX ix_sync_outbox_pending ON sync_outbox(pushed_at, entity_table, entity_id)")
    for sql in _triggers():
        op.execute(sql)
    op.execute("UPDATE application_settings SET value = '1.0.2' WHERE key = 'schema.version'")
    op.execute("PRAGMA user_version = 102")


def downgrade() -> None:
    for name in _drop_names():
        op.execute(f"DROP TRIGGER IF EXISTS {name}")
    op.execute("DROP INDEX IF EXISTS ix_sync_outbox_pending")
    for table in ("sync_guard", "sync_keys", "sync_cursors", "sync_shadow"):
        op.execute(f"DROP TABLE IF EXISTS {table}")
    op.execute("UPDATE application_settings SET value = '1.0.1' WHERE key = 'schema.version'")
    op.execute("PRAGMA user_version = 101")
