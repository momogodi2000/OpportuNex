-- =============================================================================
--  PIO — Plateforme Open Source d'Intelligence des Opportunités
--  Schéma de base de données SQLite (local, chiffré par SQLCipher)
--  Version du schéma : 1.0.0  —  02/10/2026
--
--  Auteur      : ING Momo Godi Yvan
--  Financement : Association PROTEGE QV
--  Licence     : GNU AGPL v3
--
--  Conventions
--  - SQLite >= 3.37 (tables STRICT), extension FTS5, chiffrement SQLCipher 4.
--  - Identifiants : UUID v7 en TEXT (36 caractères), triables dans le temps,
--    compatibles avec la synchronisation multi-appareils.
--  - Dates : TEXT ISO 8601 en UTC ('2026-10-02T09:40:00Z'); dates seules 'YYYY-MM-DD'.
--  - Booléens : INTEGER 0/1 avec CHECK.
--  - Montants : INTEGER en unité mineure (centimes) + code devise ISO 4217.
--    Le franc CFA (XAF) n'a pas de subdivision : montant_minor = montant.
--  - JSON : TEXT validé par CHECK (json_valid(...)).
--  - Données partagées (sources, opportunités) vs données propres à l'utilisateur
--    (user_id NOT NULL) : toute requête métier filtre sur user_id.
--  - Aucune clé d'API, aucun mot de passe en clair : les secrets sont dans le
--    trousseau du système ; la base ne stocke qu'une référence (keychain_ref).
--  - Les migrations sont gérées par Alembic ; ce fichier correspond à la
--    révision initiale (baseline).
-- =============================================================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA busy_timeout = 5000;
PRAGMA user_version = 100;   -- 1.0.0

BEGIN TRANSACTION;

-- =============================================================================
-- 0. MÉTADONNÉES ET PARAMÈTRES
-- =============================================================================

CREATE TABLE alembic_version (
    version_num TEXT NOT NULL PRIMARY KEY
) STRICT;

CREATE TABLE application_settings (
    key         TEXT NOT NULL PRIMARY KEY,
    value       TEXT NOT NULL,
    value_type  TEXT NOT NULL DEFAULT 'string'
                CHECK (value_type IN ('string','integer','boolean','json')),
    description TEXT,
    updated_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;

-- =============================================================================
-- 1. RÉFÉRENTIELS
-- =============================================================================

CREATE TABLE countries (
    code        TEXT NOT NULL PRIMARY KEY CHECK (length(code) = 2),   -- ISO 3166-1 alpha-2
    name_fr     TEXT NOT NULL,
    name_en     TEXT NOT NULL,
    region      TEXT,                                                  -- ex. 'Afrique centrale'
    is_cemac    INTEGER NOT NULL DEFAULT 0 CHECK (is_cemac IN (0,1))
) STRICT;

CREATE TABLE currencies (
    code        TEXT NOT NULL PRIMARY KEY CHECK (length(code) = 3),   -- ISO 4217
    name        TEXT NOT NULL,
    minor_units INTEGER NOT NULL DEFAULT 2 CHECK (minor_units BETWEEN 0 AND 4)
) STRICT;

CREATE TABLE exchange_rates (
    id             INTEGER PRIMARY KEY,
    base_currency  TEXT NOT NULL REFERENCES currencies(code),
    quote_currency TEXT NOT NULL REFERENCES currencies(code),
    rate           REAL NOT NULL CHECK (rate > 0),
    rate_date      TEXT NOT NULL,
    source         TEXT NOT NULL,
    UNIQUE (base_currency, quote_currency, rate_date)
) STRICT;

CREATE TABLE languages (
    code    TEXT NOT NULL PRIMARY KEY,                                 -- ISO 639-1
    name_fr TEXT NOT NULL,
    name_en TEXT NOT NULL
) STRICT;

CREATE TABLE opportunity_categories (
    id          INTEGER PRIMARY KEY,
    code        TEXT NOT NULL UNIQUE,                                  -- ex. 'scholarship.master'
    parent_id   INTEGER REFERENCES opportunity_categories(id) ON DELETE CASCADE,
    name_fr     TEXT NOT NULL,
    name_en     TEXT NOT NULL,
    icon        TEXT,
    sort_order  INTEGER NOT NULL DEFAULT 0
) STRICT;
CREATE INDEX ix_categories_parent ON opportunity_categories(parent_id);

CREATE TABLE objectives (
    id       INTEGER PRIMARY KEY,
    code     TEXT NOT NULL UNIQUE,                                     -- ex. 'find_job'
    name_fr  TEXT NOT NULL,
    name_en  TEXT NOT NULL,
    default_category_id INTEGER REFERENCES opportunity_categories(id)
) STRICT;

CREATE TABLE skills (
    id            INTEGER PRIMARY KEY,
    name          TEXT NOT NULL,
    normalized    TEXT NOT NULL UNIQUE,                                -- minuscules, sans accents
    kind          TEXT NOT NULL DEFAULT 'technical'
                  CHECK (kind IN ('technical','soft','language','domain','tool')),
    esco_uri      TEXT                                                 -- référentiel européen ESCO
) STRICT;

CREATE TABLE skill_aliases (
    alias       TEXT NOT NULL PRIMARY KEY,                             -- normalisé
    skill_id    INTEGER NOT NULL REFERENCES skills(id) ON DELETE CASCADE
) STRICT;
CREATE INDEX ix_skill_aliases_skill ON skill_aliases(skill_id);

-- =============================================================================
-- 2. IDENTITÉ, SÉCURITÉ ET CONSENTEMENTS
-- =============================================================================

CREATE TABLE users (
    id                    TEXT NOT NULL PRIMARY KEY,
    email                 TEXT NOT NULL COLLATE NOCASE UNIQUE,
    display_name          TEXT NOT NULL,
    password_hash         TEXT NOT NULL,                     -- Argon2id (format PHC)
    recovery_key_hash     TEXT NOT NULL,                     -- hash de la phrase de récupération
    wrapped_db_key        BLOB,                              -- clé de données chiffrée par la clé dérivée
    account_mode          TEXT NOT NULL DEFAULT 'local'
                          CHECK (account_mode IN ('local','synced')),
    remote_account_id     TEXT,                              -- identifiant sur le serveur de synchro
    totp_enabled          INTEGER NOT NULL DEFAULT 0 CHECK (totp_enabled IN (0,1)),
    preferred_locale      TEXT NOT NULL DEFAULT 'fr' REFERENCES languages(code),
    theme                 TEXT NOT NULL DEFAULT 'system' CHECK (theme IN ('light','dark','system')),
    auto_lock_minutes     INTEGER NOT NULL DEFAULT 15 CHECK (auto_lock_minutes BETWEEN 1 AND 240),
    onboarding_completed  INTEGER NOT NULL DEFAULT 0 CHECK (onboarding_completed IN (0,1)),
    failed_login_count    INTEGER NOT NULL DEFAULT 0,
    locked_until          TEXT,
    last_login_at         TEXT,
    password_changed_at   TEXT,
    created_at            TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at            TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    deleted_at            TEXT
) STRICT;

CREATE TABLE user_sessions (
    id             TEXT NOT NULL PRIMARY KEY,
    user_id        TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash     TEXT NOT NULL UNIQUE,                     -- SHA-256 du jeton de session
    device_name    TEXT,
    created_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    last_seen_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    expires_at     TEXT NOT NULL,
    revoked_at     TEXT
) STRICT;
CREATE INDEX ix_sessions_user ON user_sessions(user_id);

CREATE TABLE login_attempts (
    id           INTEGER PRIMARY KEY,
    email        TEXT NOT NULL COLLATE NOCASE,
    succeeded    INTEGER NOT NULL CHECK (succeeded IN (0,1)),
    reason       TEXT,
    attempted_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_login_attempts_email_time ON login_attempts(email, attempted_at);

CREATE TABLE consents (
    id           TEXT NOT NULL PRIMARY KEY,
    user_id      TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    purpose      TEXT NOT NULL CHECK (purpose IN (
                    'ai_remote_processing','profile_to_ai','cv_parsing_ai',
                    'sync','crash_reports','terms','privacy_policy')),
    target       TEXT,                                       -- ex. fournisseur IA concerné
    policy_version TEXT NOT NULL,
    granted      INTEGER NOT NULL CHECK (granted IN (0,1)),
    granted_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    revoked_at   TEXT
) STRICT;
CREATE INDEX ix_consents_user_purpose ON consents(user_id, purpose);

CREATE TABLE data_disclosures (                            -- journal des envois vers des tiers
    id           INTEGER PRIMARY KEY,
    user_id      TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient    TEXT NOT NULL,                              -- ex. 'ai:mistral', 'sync:protegeqv'
    data_category TEXT NOT NULL,                             -- ex. 'profile_anonymized', 'opportunity_text'
    consent_id   TEXT REFERENCES consents(id) ON DELETE SET NULL,
    byte_count   INTEGER NOT NULL DEFAULT 0,
    disclosed_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_disclosures_user_time ON data_disclosures(user_id, disclosed_at);

-- =============================================================================
-- 3. PROFIL UTILISATEUR
-- =============================================================================

CREATE TABLE user_profiles (
    user_id              TEXT NOT NULL PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    full_name            TEXT,
    country_code         TEXT REFERENCES countries(code),
    city                 TEXT,
    professional_status  TEXT CHECK (professional_status IN (
                            'student','job_seeker','employed','self_employed','freelancer',
                            'entrepreneur','researcher','unemployed','retired','other')),
    current_occupation   TEXT,
    experience_years     REAL CHECK (experience_years >= 0),
    highest_education    TEXT CHECK (highest_education IN (
                            'none','primary','secondary','bac','bac_plus_2','bachelor',
                            'master','doctorate','postdoc','vocational')),
    work_mode_pref       TEXT CHECK (work_mode_pref IN ('remote','hybrid','onsite','any')),
    willing_to_relocate  INTEGER CHECK (willing_to_relocate IN (0,1)),
    contact_phone        TEXT,
    bio                  TEXT,
    summary_text         TEXT,                               -- résumé généré puis validé
    summary_approved     INTEGER NOT NULL DEFAULT 0 CHECK (summary_approved IN (0,1)),
    completeness_pct     INTEGER NOT NULL DEFAULT 0 CHECK (completeness_pct BETWEEN 0 AND 100),
    updated_at           TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;

CREATE TABLE profile_preferred_locations (
    id            INTEGER PRIMARY KEY,
    user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    country_code  TEXT REFERENCES countries(code),
    region_label  TEXT,                                      -- ex. 'Europe', 'Afrique de l'Ouest'
    city          TEXT,
    priority      INTEGER NOT NULL DEFAULT 1,
    CHECK (country_code IS NOT NULL OR region_label IS NOT NULL)
) STRICT;
CREATE INDEX ix_pref_locations_user ON profile_preferred_locations(user_id);

CREATE TABLE education_records (
    id               TEXT NOT NULL PRIMARY KEY,
    user_id          TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    level            TEXT NOT NULL,
    field_of_study   TEXT NOT NULL,
    institution      TEXT NOT NULL,
    country_code     TEXT REFERENCES countries(code),
    start_date       TEXT,
    end_date         TEXT,
    is_ongoing       INTEGER NOT NULL DEFAULT 0 CHECK (is_ongoing IN (0,1)),
    grade            TEXT,
    achievements     TEXT,
    source           TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual','cv_import','sync')),
    created_at       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_education_user ON education_records(user_id);

CREATE TABLE certifications (
    id             TEXT NOT NULL PRIMARY KEY,
    user_id        TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name           TEXT NOT NULL,
    issuer         TEXT,
    obtained_on    TEXT,
    expires_on     TEXT,
    credential_url TEXT,
    source         TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual','cv_import','sync'))
) STRICT;
CREATE INDEX ix_certifications_user ON certifications(user_id);

CREATE TABLE work_experiences (
    id             TEXT NOT NULL PRIMARY KEY,
    user_id        TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_title      TEXT NOT NULL,
    employer       TEXT NOT NULL,
    employment_type TEXT CHECK (employment_type IN (
                     'full_time','part_time','internship','freelance','volunteer','consulting','other')),
    country_code   TEXT REFERENCES countries(code),
    city           TEXT,
    start_date     TEXT NOT NULL,
    end_date       TEXT,
    is_current     INTEGER NOT NULL DEFAULT 0 CHECK (is_current IN (0,1)),
    description    TEXT,
    source         TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual','cv_import','sync')),
    created_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    CHECK (end_date IS NULL OR end_date >= start_date)
) STRICT;
CREATE INDEX ix_work_user ON work_experiences(user_id);

CREATE TABLE user_skills (
    user_id      TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skill_id     INTEGER NOT NULL REFERENCES skills(id) ON DELETE RESTRICT,
    level        INTEGER CHECK (level BETWEEN 1 AND 5),
    years        REAL CHECK (years >= 0),
    is_primary   INTEGER NOT NULL DEFAULT 0 CHECK (is_primary IN (0,1)),
    PRIMARY KEY (user_id, skill_id)
) STRICT;
CREATE INDEX ix_user_skills_skill ON user_skills(skill_id);

CREATE TABLE user_languages (
    user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    language_code TEXT NOT NULL REFERENCES languages(code),
    cefr_level    TEXT NOT NULL CHECK (cefr_level IN ('A1','A2','B1','B2','C1','C2','native')),
    PRIMARY KEY (user_id, language_code)
) STRICT;

CREATE TABLE profile_links (
    id        INTEGER PRIMARY KEY,
    user_id   TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind      TEXT NOT NULL CHECK (kind IN ('portfolio','linkedin','github','website','gitlab','orcid','other')),
    url       TEXT NOT NULL CHECK (url LIKE 'https://%' OR url LIKE 'http://%'),
    UNIQUE (user_id, kind, url)
) STRICT;

CREATE TABLE user_objectives (
    user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    objective_id  INTEGER NOT NULL REFERENCES objectives(id),
    priority      INTEGER NOT NULL DEFAULT 1 CHECK (priority BETWEEN 1 AND 5),
    PRIMARY KEY (user_id, objective_id)
) STRICT;

CREATE TABLE user_custom_objectives (
    id         INTEGER PRIMARY KEY,
    user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label      TEXT NOT NULL
) STRICT;
CREATE INDEX ix_custom_objectives_user ON user_custom_objectives(user_id);

CREATE TABLE project_profiles (                            -- préférences de financement / projet
    id                    TEXT NOT NULL PRIMARY KEY,
    user_id               TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    organization_id       TEXT REFERENCES organizations(id) ON DELETE CASCADE,
    title                 TEXT NOT NULL,
    category_id           INTEGER REFERENCES opportunity_categories(id),
    description           TEXT,
    stage                 TEXT CHECK (stage IN ('idea','prototype','early','growth','scale','established')),
    funding_need_minor    INTEGER CHECK (funding_need_minor >= 0),
    funding_min_minor     INTEGER CHECK (funding_min_minor >= 0),
    funding_max_minor     INTEGER CHECK (funding_max_minor >= 0),
    currency_code         TEXT REFERENCES currencies(code),
    operating_country     TEXT REFERENCES countries(code),
    beneficiaries         TEXT,
    legal_status          TEXT,
    existing_resources    TEXT,
    timeline_months       INTEGER CHECK (timeline_months > 0),
    created_at            TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at            TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    CHECK (funding_max_minor IS NULL OR funding_min_minor IS NULL OR funding_max_minor >= funding_min_minor)
) STRICT;
CREATE INDEX ix_project_profiles_user ON project_profiles(user_id);

CREATE TABLE cv_imports (
    id             TEXT NOT NULL PRIMARY KEY,
    user_id        TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_name      TEXT NOT NULL,
    mime_type      TEXT NOT NULL CHECK (mime_type IN (
                     'application/pdf',
                     'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                     'text/plain')),
    file_size      INTEGER NOT NULL CHECK (file_size BETWEEN 1 AND 10485760),
    sha256         TEXT NOT NULL,
    vault_path     TEXT,                                     -- NULL si le fichier n'est pas conservé
    parser         TEXT NOT NULL CHECK (parser IN ('local','ai')),
    status         TEXT NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending','parsing','review','applied','failed','discarded')),
    error_message  TEXT,
    created_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_cv_imports_user ON cv_imports(user_id);

CREATE TABLE cv_extracted_items (
    id            INTEGER PRIMARY KEY,
    cv_import_id  TEXT NOT NULL REFERENCES cv_imports(id) ON DELETE CASCADE,
    item_type     TEXT NOT NULL CHECK (item_type IN ('education','experience','skill','language','certification','link','identity')),
    payload       TEXT NOT NULL CHECK (json_valid(payload)),
    confidence    REAL CHECK (confidence BETWEEN 0 AND 1),
    decision      TEXT NOT NULL DEFAULT 'pending' CHECK (decision IN ('pending','accepted','edited','rejected')),
    decided_at    TEXT
) STRICT;
CREATE INDEX ix_cv_items_import ON cv_extracted_items(cv_import_id);

-- =============================================================================
-- 4. ORGANISATIONS (associations, PME)
-- =============================================================================

CREATE TABLE organizations (
    id               TEXT NOT NULL PRIMARY KEY,
    name             TEXT NOT NULL,
    org_type         TEXT NOT NULL CHECK (org_type IN ('association','ngo','sme','startup','cooperative','public','academic','other')),
    legal_status     TEXT,
    registration_no  TEXT,
    country_code     TEXT REFERENCES countries(code),
    sector           TEXT,
    description      TEXT,
    annual_budget_band TEXT,                                 -- tranche indicative, jamais un montant exact obligatoire
    website          TEXT,
    remote_id        TEXT,
    created_by       TEXT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;

CREATE TABLE organization_members (
    organization_id TEXT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role            TEXT NOT NULL CHECK (role IN ('owner','admin','editor','viewer')),
    joined_at       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    PRIMARY KEY (organization_id, user_id)
) STRICT;
CREATE INDEX ix_org_members_user ON organization_members(user_id);

CREATE TABLE organization_invitations (
    id              TEXT NOT NULL PRIMARY KEY,
    organization_id TEXT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    email           TEXT COLLATE NOCASE,
    role            TEXT NOT NULL CHECK (role IN ('admin','editor','viewer')),
    token_hash      TEXT NOT NULL UNIQUE,
    invited_by      TEXT NOT NULL REFERENCES users(id),
    expires_at      TEXT NOT NULL,
    accepted_at     TEXT,
    revoked_at      TEXT
) STRICT;

-- =============================================================================
-- 5. SOURCES, ADAPTATEURS ET COLLECTE
-- =============================================================================

CREATE TABLE sources (
    id                 TEXT NOT NULL PRIMARY KEY,
    owner_user_id      TEXT REFERENCES users(id) ON DELETE CASCADE,   -- NULL = source du catalogue / registre
    registry_id        TEXT,                                          -- identifiant dans le registre communautaire
    name               TEXT NOT NULL,
    base_url           TEXT NOT NULL CHECK (base_url LIKE 'https://%' OR base_url LIKE 'http://%'),
    domain             TEXT NOT NULL,
    publisher_name     TEXT,
    publisher_type     TEXT CHECK (publisher_type IN (
                         'government','university','international_org','ngo','foundation',
                         'procurement_portal','incubator','job_board','media','company','aggregator','other')),
    is_official        INTEGER NOT NULL DEFAULT 0 CHECK (is_official IN (0,1)),
    access_method      TEXT NOT NULL CHECK (access_method IN ('api','rss','atom','sitemap','structured_data','html','headless','pdf','manual_link')),
    country_code       TEXT REFERENCES countries(code),
    language_code      TEXT REFERENCES languages(code),
    enabled            INTEGER NOT NULL DEFAULT 1 CHECK (enabled IN (0,1)),
    allowed_status     TEXT NOT NULL DEFAULT 'unknown'
                       CHECK (allowed_status IN ('unknown','allowed','disallowed','terms_restricted','excluded_by_publisher')),
    min_interval_minutes INTEGER NOT NULL DEFAULT 1440 CHECK (min_interval_minutes >= 60),
    crawl_delay_seconds  REAL NOT NULL DEFAULT 2.0 CHECK (crawl_delay_seconds >= 2.0),
    terms_url          TEXT,
    official_search_url TEXT,                                         -- lien proposé si la source n'est pas accessible
    reliability_score  REAL NOT NULL DEFAULT 0.5 CHECK (reliability_score BETWEEN 0 AND 1),
    last_success_at    TEXT,
    last_attempt_at    TEXT,
    last_status        TEXT CHECK (last_status IN ('ok','partial','failed','blocked','skipped')),
    last_error         TEXT,
    consecutive_failures INTEGER NOT NULL DEFAULT 0,
    created_at         TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at         TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    UNIQUE (owner_user_id, base_url)
) STRICT;
CREATE INDEX ix_sources_domain ON sources(domain);
CREATE INDEX ix_sources_enabled ON sources(enabled, access_method);
CREATE UNIQUE INDEX ux_sources_registry ON sources(registry_id) WHERE registry_id IS NOT NULL;

CREATE TABLE source_categories (
    source_id   TEXT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES opportunity_categories(id) ON DELETE CASCADE,
    PRIMARY KEY (source_id, category_id)
) STRICT;
CREATE INDEX ix_source_categories_cat ON source_categories(category_id);

CREATE TABLE source_adapters (
    id              TEXT NOT NULL PRIMARY KEY,
    source_id       TEXT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
    version         TEXT NOT NULL,                           -- semver
    spec            TEXT NOT NULL CHECK (json_valid(spec)),  -- adaptateur déclaratif (sélecteurs, pagination, champs)
    spec_sha256     TEXT NOT NULL,
    signature       TEXT,                                    -- signature du registre (minisign / Sigstore)
    signature_valid INTEGER CHECK (signature_valid IN (0,1)),
    origin          TEXT NOT NULL CHECK (origin IN ('builtin','registry','user')),
    is_active       INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1)),
    installed_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    UNIQUE (source_id, version)
) STRICT;
CREATE UNIQUE INDEX ux_adapter_active ON source_adapters(source_id) WHERE is_active = 1;

CREATE TABLE robots_cache (
    domain        TEXT NOT NULL PRIMARY KEY,
    robots_txt    TEXT,
    http_status   INTEGER,
    crawl_delay   REAL,
    fetched_at    TEXT NOT NULL,
    expires_at    TEXT NOT NULL
) STRICT;

CREATE TABLE domain_exclusions (                           -- éditeurs ayant demandé leur retrait
    domain      TEXT NOT NULL PRIMARY KEY,
    reason      TEXT NOT NULL,
    origin      TEXT NOT NULL CHECK (origin IN ('registry','user','publisher_request')),
    created_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;

CREATE TABLE source_scan_runs (
    id              TEXT NOT NULL PRIMARY KEY,
    source_id       TEXT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
    job_id          TEXT REFERENCES background_jobs(id) ON DELETE SET NULL,
    trigger         TEXT NOT NULL CHECK (trigger IN ('search','monitor','manual','recheck')),
    adapter_version TEXT,
    status          TEXT NOT NULL DEFAULT 'running'
                    CHECK (status IN ('queued','running','ok','partial','failed','blocked','cancelled','skipped')),
    http_requests   INTEGER NOT NULL DEFAULT 0,
    bytes_received  INTEGER NOT NULL DEFAULT 0,
    items_found     INTEGER NOT NULL DEFAULT 0,
    items_new       INTEGER NOT NULL DEFAULT 0,
    items_updated   INTEGER NOT NULL DEFAULT 0,
    error_code      TEXT,
    error_detail    TEXT,
    started_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    finished_at     TEXT
) STRICT;
CREATE INDEX ix_scan_runs_source_time ON source_scan_runs(source_id, started_at DESC);
CREATE INDEX ix_scan_runs_job ON source_scan_runs(job_id);

CREATE TABLE http_cache (
    url_hash       TEXT NOT NULL PRIMARY KEY,                -- SHA-256 de l'URL normalisée
    url            TEXT NOT NULL,
    etag           TEXT,
    last_modified  TEXT,
    status_code    INTEGER NOT NULL,
    content_type   TEXT,
    body           BLOB,
    fetched_at     TEXT NOT NULL,
    expires_at     TEXT
) STRICT;
CREATE INDEX ix_http_cache_expiry ON http_cache(expires_at);

CREATE TABLE raw_documents (
    id               TEXT NOT NULL PRIMARY KEY,
    source_id        TEXT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
    scan_run_id      TEXT REFERENCES source_scan_runs(id) ON DELETE SET NULL,
    url              TEXT NOT NULL,
    normalized_url   TEXT NOT NULL,
    external_id      TEXT,                                   -- identifiant natif de la source
    content_type     TEXT NOT NULL,
    content_sha256   TEXT NOT NULL,
    extracted_text   TEXT,                                   -- texte assaini, jamais de script
    structured_data  TEXT CHECK (structured_data IS NULL OR json_valid(structured_data)),
    language_code    TEXT,
    fetched_at       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    processing_status TEXT NOT NULL DEFAULT 'new'
                     CHECK (processing_status IN ('new','duplicate','extracted','analyzed','failed','ignored')),
    processing_error TEXT,
    UNIQUE (source_id, normalized_url, content_sha256)
) STRICT;
CREATE INDEX ix_raw_docs_status ON raw_documents(processing_status);
CREATE INDEX ix_raw_docs_hash ON raw_documents(content_sha256);
CREATE INDEX ix_raw_docs_normurl ON raw_documents(normalized_url);

-- =============================================================================
-- 6. OPPORTUNITÉS (données canoniques, dédoublonnées)
-- =============================================================================

CREATE TABLE opportunities (
    id                   TEXT NOT NULL PRIMARY KEY,
    canonical_url        TEXT NOT NULL,                      -- URL de l'éditeur d'origine si connue
    normalized_url       TEXT NOT NULL UNIQUE,
    primary_source_id    TEXT REFERENCES sources(id) ON DELETE SET NULL,
    dedup_fingerprint    TEXT NOT NULL,                      -- hash(titre normalisé + organisme + date limite)
    simhash              INTEGER,                            -- similarité approximative 64 bits
    title                TEXT NOT NULL,
    category_id          INTEGER REFERENCES opportunity_categories(id),
    organization_name    TEXT,
    organization_type    TEXT,
    summary              TEXT,                               -- résumé (généré, provenance dans opportunity_fields)
    description_text     TEXT,
    language_code        TEXT REFERENCES languages(code),
    country_code         TEXT REFERENCES countries(code),
    eligible_regions     TEXT CHECK (eligible_regions IS NULL OR json_valid(eligible_regions)),
    location_text        TEXT,
    work_mode            TEXT CHECK (work_mode IN ('remote','hybrid','onsite','unspecified')),
    target_audience      TEXT,
    education_required   TEXT,
    experience_min_years REAL CHECK (experience_min_years >= 0),
    experience_max_years REAL CHECK (experience_max_years >= 0),
    amount_min_minor     INTEGER CHECK (amount_min_minor >= 0),
    amount_max_minor     INTEGER CHECK (amount_max_minor >= 0),
    amount_currency      TEXT REFERENCES currencies(code),
    amount_period        TEXT CHECK (amount_period IN ('one_time','hour','day','month','year','total','unspecified')),
    is_fully_funded      INTEGER CHECK (is_fully_funded IN (0,1)),
    published_on         TEXT,
    deadline_on          TEXT,
    deadline_timezone    TEXT,
    deadline_raw         TEXT,                               -- libellé original conservé mot pour mot
    eligibility_raw      TEXT,                               -- clauses originales conservées mot pour mot
    application_url      TEXT,
    application_channel  TEXT CHECK (application_channel IN ('online_form','email','postal','in_person','platform','unspecified')),
    contact_public       TEXT,                               -- uniquement si publié par l'éditeur
    verification_status  TEXT NOT NULL DEFAULT 'unverified'
                         CHECK (verification_status IN ('verified','unverified','modified','expired','withdrawn','error')),
    analysis_method      TEXT NOT NULL DEFAULT 'deterministic' CHECK (analysis_method IN ('deterministic','ai','mixed')),
    analysis_version     TEXT,
    first_seen_at        TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    last_checked_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    last_changed_at      TEXT,
    created_at           TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at           TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    CHECK (amount_max_minor IS NULL OR amount_min_minor IS NULL OR amount_max_minor >= amount_min_minor),
    CHECK (amount_currency IS NOT NULL OR (amount_min_minor IS NULL AND amount_max_minor IS NULL))
) STRICT;
CREATE INDEX ix_opp_deadline ON opportunities(deadline_on);
CREATE INDEX ix_opp_category_deadline ON opportunities(category_id, deadline_on);
CREATE INDEX ix_opp_country ON opportunities(country_code);
CREATE INDEX ix_opp_published ON opportunities(published_on DESC);
CREATE INDEX ix_opp_status ON opportunities(verification_status);
CREATE INDEX ix_opp_fingerprint ON opportunities(dedup_fingerprint);
CREATE INDEX ix_opp_simhash ON opportunities(simhash);

CREATE TABLE opportunity_sources (                         -- toutes les occurrences d'une même opportunité
    opportunity_id   TEXT NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    raw_document_id  TEXT NOT NULL REFERENCES raw_documents(id) ON DELETE CASCADE,
    source_id        TEXT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
    url              TEXT NOT NULL,
    is_original      INTEGER NOT NULL DEFAULT 0 CHECK (is_original IN (0,1)),
    match_method     TEXT NOT NULL CHECK (match_method IN ('url','external_id','fingerprint','simhash','manual')),
    linked_at        TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    PRIMARY KEY (opportunity_id, raw_document_id)
) STRICT;
CREATE INDEX ix_opp_sources_source ON opportunity_sources(source_id);

CREATE TABLE opportunity_fields (                          -- provenance champ par champ
    id               INTEGER PRIMARY KEY,
    opportunity_id   TEXT NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    field_name       TEXT NOT NULL,
    value_text       TEXT,                                   -- NULL = « Non précisé »
    provenance       TEXT NOT NULL CHECK (provenance IN ('explicit','inferred','generated','not_specified','unverifiable')),
    evidence_excerpt TEXT,                                   -- extrait source justificatif
    raw_document_id  TEXT REFERENCES raw_documents(id) ON DELETE SET NULL,
    confidence       REAL CHECK (confidence BETWEEN 0 AND 1),
    extracted_by     TEXT NOT NULL CHECK (extracted_by IN ('adapter','structured_data','rules','ai')),
    ai_provider_id   TEXT REFERENCES ai_providers(id) ON DELETE SET NULL,
    extracted_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    UNIQUE (opportunity_id, field_name)
) STRICT;

CREATE TABLE opportunity_requirements (
    id              INTEGER PRIMARY KEY,
    opportunity_id  TEXT NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    req_type        TEXT NOT NULL CHECK (req_type IN (
                      'education','experience','skill','language','nationality','residence',
                      'age','document','legal_status','other')),
    label           TEXT NOT NULL,
    skill_id        INTEGER REFERENCES skills(id) ON DELETE SET NULL,
    language_code   TEXT REFERENCES languages(code),
    min_level       TEXT,
    is_mandatory    INTEGER NOT NULL DEFAULT 1 CHECK (is_mandatory IN (0,1)),
    provenance      TEXT NOT NULL CHECK (provenance IN ('explicit','inferred')),
    original_text   TEXT
) STRICT;
CREATE INDEX ix_opp_req_opp ON opportunity_requirements(opportunity_id);
CREATE INDEX ix_opp_req_skill ON opportunity_requirements(skill_id);

CREATE TABLE opportunity_versions (                        -- historique des modifications détectées
    id              INTEGER PRIMARY KEY,
    opportunity_id  TEXT NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    changed_fields  TEXT NOT NULL CHECK (json_valid(changed_fields)),
    previous_values TEXT NOT NULL CHECK (json_valid(previous_values)),
    detected_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_opp_versions_opp ON opportunity_versions(opportunity_id, detected_at DESC);

CREATE TABLE opportunity_embeddings (
    opportunity_id TEXT NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    model          TEXT NOT NULL,
    dimensions     INTEGER NOT NULL CHECK (dimensions > 0),
    vector         BLOB NOT NULL,                            -- float32 little-endian
    computed_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    PRIMARY KEY (opportunity_id, model)
) STRICT;

-- Recherche plein texte (FTS5, contenu externe synchronisé par triggers)
CREATE VIRTUAL TABLE opportunities_fts USING fts5(
    title, organization_name, summary, description_text, location_text,
    content = 'opportunities',
    content_rowid = 'rowid',
    tokenize = 'unicode61 remove_diacritics 2'
);

CREATE TRIGGER trg_opp_fts_ai AFTER INSERT ON opportunities BEGIN
    INSERT INTO opportunities_fts(rowid, title, organization_name, summary, description_text, location_text)
    VALUES (new.rowid, new.title, new.organization_name, new.summary, new.description_text, new.location_text);
END;
CREATE TRIGGER trg_opp_fts_ad AFTER DELETE ON opportunities BEGIN
    INSERT INTO opportunities_fts(opportunities_fts, rowid, title, organization_name, summary, description_text, location_text)
    VALUES ('delete', old.rowid, old.title, old.organization_name, old.summary, old.description_text, old.location_text);
END;
CREATE TRIGGER trg_opp_fts_au AFTER UPDATE OF title, organization_name, summary, description_text, location_text ON opportunities BEGIN
    INSERT INTO opportunities_fts(opportunities_fts, rowid, title, organization_name, summary, description_text, location_text)
    VALUES ('delete', old.rowid, old.title, old.organization_name, old.summary, old.description_text, old.location_text);
    INSERT INTO opportunities_fts(rowid, title, organization_name, summary, description_text, location_text)
    VALUES (new.rowid, new.title, new.organization_name, new.summary, new.description_text, new.location_text);
END;

-- =============================================================================
-- 7. ESPACES DE RECHERCHE, REQUÊTES ET EXÉCUTIONS
-- =============================================================================

CREATE TABLE research_workspaces (
    id              TEXT NOT NULL PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    organization_id TEXT REFERENCES organizations(id) ON DELETE SET NULL,   -- espace partagé
    name            TEXT NOT NULL,
    description     TEXT,
    template_code   TEXT CHECK (template_code IN ('job','master_scholarship','association_funding','startup_funding','it_consulting','public_procurement','internship','custom')),
    color           TEXT,
    archived        INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0,1)),
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    UNIQUE (user_id, name)
) STRICT;
CREATE INDEX ix_workspaces_org ON research_workspaces(organization_id);

CREATE TABLE search_queries (
    id                  TEXT NOT NULL PRIMARY KEY,
    user_id             TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workspace_id        TEXT REFERENCES research_workspaces(id) ON DELETE SET NULL,
    raw_text            TEXT NOT NULL,
    language_code       TEXT REFERENCES languages(code),
    interpreted_filters TEXT CHECK (interpreted_filters IS NULL OR json_valid(interpreted_filters)),
    final_filters       TEXT NOT NULL CHECK (json_valid(final_filters)),   -- après correction utilisateur
    interpreter         TEXT NOT NULL CHECK (interpreter IN ('rules','ai')),
    is_saved            INTEGER NOT NULL DEFAULT 0 CHECK (is_saved IN (0,1)),
    saved_name          TEXT,
    created_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_queries_user_time ON search_queries(user_id, created_at DESC);
CREATE INDEX ix_queries_workspace ON search_queries(workspace_id);

CREATE TABLE search_runs (
    id               TEXT NOT NULL PRIMARY KEY,
    query_id         TEXT NOT NULL REFERENCES search_queries(id) ON DELETE CASCADE,
    user_id          TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_id           TEXT REFERENCES background_jobs(id) ON DELETE SET NULL,
    trigger          TEXT NOT NULL CHECK (trigger IN ('manual','rerun','monitor')),
    status           TEXT NOT NULL DEFAULT 'queued'
                     CHECK (status IN ('queued','running','completed','partial','failed','cancelled')),
    sources_total    INTEGER NOT NULL DEFAULT 0,
    sources_done     INTEGER NOT NULL DEFAULT 0,
    sources_failed   INTEGER NOT NULL DEFAULT 0,
    results_count    INTEGER NOT NULL DEFAULT 0,
    new_count        INTEGER NOT NULL DEFAULT 0,
    ai_used          INTEGER NOT NULL DEFAULT 0 CHECK (ai_used IN (0,1)),
    error_summary    TEXT,
    started_at       TEXT,
    finished_at      TEXT,
    created_at       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_runs_query ON search_runs(query_id, created_at DESC);
CREATE INDEX ix_runs_user_status ON search_runs(user_id, status);

CREATE TABLE search_run_sources (
    search_run_id  TEXT NOT NULL REFERENCES search_runs(id) ON DELETE CASCADE,
    source_id      TEXT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
    scan_run_id    TEXT REFERENCES source_scan_runs(id) ON DELETE SET NULL,
    status         TEXT NOT NULL DEFAULT 'queued'
                   CHECK (status IN ('queued','running','ok','partial','failed','blocked','skipped','cancelled')),
    message        TEXT,
    PRIMARY KEY (search_run_id, source_id)
) STRICT;

CREATE TABLE search_results (
    search_run_id   TEXT NOT NULL REFERENCES search_runs(id) ON DELETE CASCADE,
    opportunity_id  TEXT NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    rank            INTEGER NOT NULL,
    is_new          INTEGER NOT NULL DEFAULT 0 CHECK (is_new IN (0,1)),
    PRIMARY KEY (search_run_id, opportunity_id)
) STRICT;
CREATE INDEX ix_results_opp ON search_results(opportunity_id);

CREATE TABLE workspace_opportunities (                     -- rattachement manuel à un espace
    workspace_id    TEXT NOT NULL REFERENCES research_workspaces(id) ON DELETE CASCADE,
    opportunity_id  TEXT NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    added_at        TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    PRIMARY KEY (workspace_id, opportunity_id)
) STRICT;

CREATE TABLE workspace_notes (
    id            TEXT NOT NULL PRIMARY KEY,
    workspace_id  TEXT NOT NULL REFERENCES research_workspaces(id) ON DELETE CASCADE,
    author_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    body          TEXT NOT NULL,
    created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_ws_notes_ws ON workspace_notes(workspace_id);

-- =============================================================================
-- 8. CORRESPONDANCE ET RECOMMANDATION
-- =============================================================================

CREATE TABLE matching_weights (
    user_id         TEXT NOT NULL PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    w_skills        REAL NOT NULL DEFAULT 0.30 CHECK (w_skills BETWEEN 0 AND 1),
    w_education     REAL NOT NULL DEFAULT 0.15 CHECK (w_education BETWEEN 0 AND 1),
    w_experience    REAL NOT NULL DEFAULT 0.15 CHECK (w_experience BETWEEN 0 AND 1),
    w_location      REAL NOT NULL DEFAULT 0.15 CHECK (w_location BETWEEN 0 AND 1),
    w_language      REAL NOT NULL DEFAULT 0.10 CHECK (w_language BETWEEN 0 AND 1),
    w_objectives    REAL NOT NULL DEFAULT 0.10 CHECK (w_objectives BETWEEN 0 AND 1),
    w_deadline      REAL NOT NULL DEFAULT 0.05 CHECK (w_deadline BETWEEN 0 AND 1),
    updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;

CREATE TABLE match_scores (
    user_id           TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    opportunity_id    TEXT NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    score             INTEGER NOT NULL CHECK (score BETWEEN 0 AND 100),
    breakdown         TEXT NOT NULL CHECK (json_valid(breakdown)),        -- score par critère
    strengths         TEXT CHECK (strengths IS NULL OR json_valid(strengths)),
    gaps              TEXT CHECK (gaps IS NULL OR json_valid(gaps)),
    eligibility       TEXT NOT NULL DEFAULT 'uncertain'
                      CHECK (eligibility IN ('likely','uncertain','unlikely','not_eligible')),
    to_verify         TEXT CHECK (to_verify IS NULL OR json_valid(to_verify)),
    explanation       TEXT,                                               -- texte généré (marqué comme tel)
    profile_version   TEXT NOT NULL,                                      -- empreinte du profil au calcul
    algorithm_version TEXT NOT NULL,
    computed_at       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    PRIMARY KEY (user_id, opportunity_id)
) STRICT;
CREATE INDEX ix_scores_user_score ON match_scores(user_id, score DESC);

CREATE TABLE match_feedback (
    id              INTEGER PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    opportunity_id  TEXT NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    feedback        TEXT NOT NULL CHECK (feedback IN ('relevant','not_relevant','dismissed','wrong_category','expired_report')),
    reason          TEXT,
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    UNIQUE (user_id, opportunity_id, feedback)
) STRICT;
CREATE INDEX ix_feedback_user ON match_feedback(user_id);

-- =============================================================================
-- 9. SAUVEGARDES ET SUIVI DES CANDIDATURES
-- =============================================================================

CREATE TABLE saved_opportunities (
    id              TEXT NOT NULL PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    opportunity_id  TEXT NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    workspace_id    TEXT REFERENCES research_workspaces(id) ON DELETE SET NULL,
    organization_id TEXT REFERENCES organizations(id) ON DELETE SET NULL,
    priority        TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('high','medium','low')),
    interest        TEXT NOT NULL DEFAULT 'interested' CHECK (interest IN ('interested','ineligible','undecided')),
    ineligible_reason TEXT,
    personal_deadline TEXT,
    archived        INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0,1)),
    saved_at        TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    UNIQUE (user_id, opportunity_id)
) STRICT;
CREATE INDEX ix_saved_user_priority ON saved_opportunities(user_id, archived, priority);

CREATE TABLE tags (
    id       INTEGER PRIMARY KEY,
    user_id  TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name     TEXT NOT NULL,
    color    TEXT,
    UNIQUE (user_id, name)
) STRICT;

CREATE TABLE saved_opportunity_tags (
    saved_id  TEXT NOT NULL REFERENCES saved_opportunities(id) ON DELETE CASCADE,
    tag_id    INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (saved_id, tag_id)
) STRICT;

CREATE TABLE applications (
    id              TEXT NOT NULL PRIMARY KEY,
    saved_id        TEXT NOT NULL UNIQUE REFERENCES saved_opportunities(id) ON DELETE CASCADE,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status          TEXT NOT NULL DEFAULT 'discovered' CHECK (status IN (
                      'discovered','to_review','preparing','ready','submitted','interview',
                      'accepted','rejected','withdrawn','expired','archived')),
    submitted_on    TEXT,
    submission_ref  TEXT,                                    -- numéro de dossier fourni par l'éditeur
    outcome_on      TEXT,
    outcome_note    TEXT,
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    CHECK (status <> 'submitted' OR submitted_on IS NOT NULL)
) STRICT;
CREATE INDEX ix_applications_user_status ON applications(user_id, status);

CREATE TABLE application_status_history (
    id              INTEGER PRIMARY KEY,
    application_id  TEXT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    from_status     TEXT,
    to_status       TEXT NOT NULL,
    changed_by      TEXT REFERENCES users(id) ON DELETE SET NULL,
    note            TEXT,
    changed_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_app_history_app ON application_status_history(application_id, changed_at);

CREATE TABLE application_events (                          -- entretiens, relances, contacts
    id              TEXT NOT NULL PRIMARY KEY,
    application_id  TEXT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    event_type      TEXT NOT NULL CHECK (event_type IN ('interview','test','follow_up','call','email','meeting','other')),
    title           TEXT NOT NULL,
    scheduled_at    TEXT,
    location        TEXT,
    contact_name    TEXT,
    notes           TEXT,
    done            INTEGER NOT NULL DEFAULT 0 CHECK (done IN (0,1)),
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_app_events_app ON application_events(application_id);
CREATE INDEX ix_app_events_time ON application_events(scheduled_at);

CREATE TABLE application_notes (
    id              TEXT NOT NULL PRIMARY KEY,
    saved_id        TEXT NOT NULL REFERENCES saved_opportunities(id) ON DELETE CASCADE,
    author_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    body            TEXT NOT NULL,
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_app_notes_saved ON application_notes(saved_id);

CREATE TABLE checklist_items (
    id              INTEGER PRIMARY KEY,
    saved_id        TEXT NOT NULL REFERENCES saved_opportunities(id) ON DELETE CASCADE,
    label           TEXT NOT NULL,
    requirement_id  INTEGER REFERENCES opportunity_requirements(id) ON DELETE SET NULL,
    origin          TEXT NOT NULL CHECK (origin IN ('requirement','ai_suggestion','user')),
    is_done         INTEGER NOT NULL DEFAULT 0 CHECK (is_done IN (0,1)),
    sort_order      INTEGER NOT NULL DEFAULT 0,
    done_at         TEXT
) STRICT;
CREATE INDEX ix_checklist_saved ON checklist_items(saved_id, sort_order);

CREATE TABLE application_documents (                       -- fichiers joints par l'utilisateur
    id              TEXT NOT NULL PRIMARY KEY,
    saved_id        TEXT NOT NULL REFERENCES saved_opportunities(id) ON DELETE CASCADE,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label           TEXT NOT NULL,
    file_name       TEXT NOT NULL,
    mime_type       TEXT NOT NULL,
    file_size       INTEGER NOT NULL CHECK (file_size > 0 AND file_size <= 52428800),
    sha256          TEXT NOT NULL,
    vault_path      TEXT NOT NULL,                           -- chemin relatif dans le coffre chiffré
    checklist_item_id INTEGER REFERENCES checklist_items(id) ON DELETE SET NULL,
    uploaded_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_app_docs_saved ON application_documents(saved_id);

CREATE TABLE generated_documents (                         -- lettres, propositions, courriels générés
    id              TEXT NOT NULL PRIMARY KEY,
    saved_id        TEXT NOT NULL REFERENCES saved_opportunities(id) ON DELETE CASCADE,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    doc_type        TEXT NOT NULL CHECK (doc_type IN (
                      'cover_letter','scholarship_statement','grant_proposal','project_summary',
                      'application_email','cv_suggestions','interview_prep','checklist')),
    title           TEXT NOT NULL,
    language_code   TEXT REFERENCES languages(code),
    current_version INTEGER NOT NULL DEFAULT 1,
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_gen_docs_saved ON generated_documents(saved_id);

CREATE TABLE generated_document_versions (
    document_id     TEXT NOT NULL REFERENCES generated_documents(id) ON DELETE CASCADE,
    version         INTEGER NOT NULL CHECK (version >= 1),
    content         TEXT NOT NULL,                           -- Markdown
    origin          TEXT NOT NULL CHECK (origin IN ('ai','user_edit')),
    ai_provider_id  TEXT REFERENCES ai_providers(id) ON DELETE SET NULL,
    integrity_flags TEXT CHECK (integrity_flags IS NULL OR json_valid(integrity_flags)),  -- affirmations non présentes dans le profil
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    PRIMARY KEY (document_id, version)
) STRICT;

CREATE TABLE reminders (
    id              TEXT NOT NULL PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    saved_id        TEXT REFERENCES saved_opportunities(id) ON DELETE CASCADE,
    application_event_id TEXT REFERENCES application_events(id) ON DELETE CASCADE,
    kind            TEXT NOT NULL CHECK (kind IN ('deadline','personal_deadline','event','follow_up','custom')),
    title           TEXT NOT NULL,
    remind_at       TEXT NOT NULL,
    offset_days     INTEGER,                                 -- J-14, J-7, J-3, J-1
    status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','sent','dismissed','snoozed','cancelled')),
    sent_at         TEXT,
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_reminders_due ON reminders(status, remind_at);
CREATE INDEX ix_reminders_user ON reminders(user_id);

-- =============================================================================
-- 10. VEILLE PLANIFIÉE ET NOTIFICATIONS
-- =============================================================================

CREATE TABLE monitors (
    id              TEXT NOT NULL PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workspace_id    TEXT REFERENCES research_workspaces(id) ON DELETE CASCADE,
    query_id        TEXT REFERENCES search_queries(id) ON DELETE SET NULL,
    name            TEXT NOT NULL,
    filters         TEXT NOT NULL CHECK (json_valid(filters)),
    schedule_kind   TEXT NOT NULL CHECK (schedule_kind IN ('daily','weekly','custom_cron')),
    schedule_expr   TEXT NOT NULL,                           -- ex. '08:00' ou expression cron
    min_score       INTEGER NOT NULL DEFAULT 50 CHECK (min_score BETWEEN 0 AND 100),
    execution_site  TEXT NOT NULL DEFAULT 'local' CHECK (execution_site IN ('local','sync_server')),
    enabled         INTEGER NOT NULL DEFAULT 1 CHECK (enabled IN (0,1)),
    next_run_at     TEXT,
    last_run_at     TEXT,
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_monitors_due ON monitors(enabled, next_run_at);

CREATE TABLE monitor_sources (
    monitor_id  TEXT NOT NULL REFERENCES monitors(id) ON DELETE CASCADE,
    source_id   TEXT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
    PRIMARY KEY (monitor_id, source_id)
) STRICT;

CREATE TABLE monitor_runs (
    id              TEXT NOT NULL PRIMARY KEY,
    monitor_id      TEXT NOT NULL REFERENCES monitors(id) ON DELETE CASCADE,
    search_run_id   TEXT REFERENCES search_runs(id) ON DELETE SET NULL,
    status          TEXT NOT NULL CHECK (status IN ('running','completed','partial','failed','skipped_offline')),
    new_items       INTEGER NOT NULL DEFAULT 0,
    updated_items   INTEGER NOT NULL DEFAULT 0,
    notified        INTEGER NOT NULL DEFAULT 0 CHECK (notified IN (0,1)),
    started_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    finished_at     TEXT
) STRICT;
CREATE INDEX ix_monitor_runs_monitor ON monitor_runs(monitor_id, started_at DESC);

CREATE TABLE notification_records (
    id              TEXT NOT NULL PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind            TEXT NOT NULL CHECK (kind IN (
                      'new_opportunities','opportunity_changed','deadline','source_failure',
                      'expired','monitor_failed','sync','update_available','system')),
    title           TEXT NOT NULL,
    body            TEXT,
    payload         TEXT CHECK (payload IS NULL OR json_valid(payload)),   -- liens profonds internes
    channel         TEXT NOT NULL DEFAULT 'native' CHECK (channel IN ('native','in_app')),
    read_at         TEXT,
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_notifications_user_unread ON notification_records(user_id, read_at, created_at DESC);

CREATE TABLE notification_preferences (
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind            TEXT NOT NULL,
    enabled         INTEGER NOT NULL DEFAULT 1 CHECK (enabled IN (0,1)),
    quiet_from      TEXT,                                    -- 'HH:MM'
    quiet_to        TEXT,
    PRIMARY KEY (user_id, kind)
) STRICT;

-- =============================================================================
-- 11. FOURNISSEURS D'IA, UTILISATION ET CACHE
-- =============================================================================

CREATE TABLE ai_providers (
    id              TEXT NOT NULL PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind            TEXT NOT NULL CHECK (kind IN (
                      'openai_compatible','gemini','mistral','groq','openrouter','anthropic',
                      'ollama','lmstudio','huggingface')),
    display_name    TEXT NOT NULL,
    base_url        TEXT,
    model           TEXT NOT NULL,
    keychain_ref    TEXT,                                    -- référence dans le trousseau, jamais la clé
    is_local        INTEGER NOT NULL DEFAULT 0 CHECK (is_local IN (0,1)),
    enabled         INTEGER NOT NULL DEFAULT 1 CHECK (enabled IN (0,1)),
    fallback_order  INTEGER NOT NULL DEFAULT 1 CHECK (fallback_order >= 1),
    timeout_seconds INTEGER NOT NULL DEFAULT 60 CHECK (timeout_seconds BETWEEN 5 AND 600),
    max_retries     INTEGER NOT NULL DEFAULT 2 CHECK (max_retries BETWEEN 0 AND 5),
    daily_call_cap  INTEGER CHECK (daily_call_cap > 0),
    last_test_at    TEXT,
    last_test_ok    INTEGER CHECK (last_test_ok IN (0,1)),
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    updated_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    UNIQUE (user_id, fallback_order),
    CHECK (is_local = 1 OR keychain_ref IS NOT NULL OR kind = 'openai_compatible')
) STRICT;

CREATE TABLE ai_task_routing (
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task            TEXT NOT NULL CHECK (task IN (
                      'query_interpretation','extraction','classification','summarization',
                      'matching_explanation','cv_parsing','document_drafting','translation','embedding')),
    provider_id     TEXT NOT NULL REFERENCES ai_providers(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, task)
) STRICT;

CREATE TABLE ai_usage_logs (
    id                INTEGER PRIMARY KEY,
    user_id           TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_id       TEXT REFERENCES ai_providers(id) ON DELETE SET NULL,
    task              TEXT NOT NULL,
    model             TEXT NOT NULL,
    prompt_tokens     INTEGER,
    completion_tokens INTEGER,
    latency_ms        INTEGER,
    outcome           TEXT NOT NULL CHECK (outcome IN ('ok','schema_invalid','rate_limited','timeout','error','cache_hit','fallback')),
    error_code        TEXT,
    created_at        TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_ai_usage_user_day ON ai_usage_logs(user_id, created_at);
CREATE INDEX ix_ai_usage_provider ON ai_usage_logs(provider_id, created_at);

CREATE TABLE ai_cache (
    cache_key       TEXT NOT NULL PRIMARY KEY,               -- SHA-256(tâche + version de prompt + modèle + contenu)
    task            TEXT NOT NULL,
    prompt_version  TEXT NOT NULL,
    model           TEXT NOT NULL,
    response        TEXT NOT NULL CHECK (json_valid(response)),
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    expires_at      TEXT
) STRICT;
CREATE INDEX ix_ai_cache_expiry ON ai_cache(expires_at);

CREATE TABLE security_events (                             -- injections de prompt, URL refusées, etc.
    id            INTEGER PRIMARY KEY,
    user_id       TEXT REFERENCES users(id) ON DELETE CASCADE,
    event_type    TEXT NOT NULL CHECK (event_type IN (
                    'prompt_injection_suspected','ssrf_blocked','oversize_response','malformed_file',
                    'signature_invalid','auth_lockout','integrity_flag')),
    severity      TEXT NOT NULL CHECK (severity IN ('info','low','medium','high')),
    detail        TEXT,                                      -- expurgé
    related_ref   TEXT,
    created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_security_events_time ON security_events(created_at DESC);

-- =============================================================================
-- 12. TÂCHES DE FOND, EXPORTS, SAUVEGARDES
-- =============================================================================

CREATE TABLE background_jobs (
    id              TEXT NOT NULL PRIMARY KEY,
    user_id         TEXT REFERENCES users(id) ON DELETE CASCADE,
    job_type        TEXT NOT NULL CHECK (job_type IN (
                      'search','monitor','source_scan','recheck','ai_analysis','cv_parse',
                      'export','backup','restore','sync','registry_update','expiry_sweep')),
    status          TEXT NOT NULL DEFAULT 'queued'
                    CHECK (status IN ('queued','running','paused','completed','failed','cancelled')),
    priority        INTEGER NOT NULL DEFAULT 5 CHECK (priority BETWEEN 1 AND 9),
    progress        INTEGER NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
    params          TEXT CHECK (params IS NULL OR json_valid(params)),
    checkpoint      TEXT CHECK (checkpoint IS NULL OR json_valid(checkpoint)),   -- reprise après interruption
    attempts        INTEGER NOT NULL DEFAULT 0,
    max_attempts    INTEGER NOT NULL DEFAULT 3,
    error_message   TEXT,
    cancel_requested INTEGER NOT NULL DEFAULT 0 CHECK (cancel_requested IN (0,1)),
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    started_at      TEXT,
    finished_at     TEXT,
    heartbeat_at    TEXT
) STRICT;
CREATE INDEX ix_jobs_status_priority ON background_jobs(status, priority, created_at);
CREATE INDEX ix_jobs_user ON background_jobs(user_id, created_at DESC);

CREATE TABLE export_records (
    id              TEXT NOT NULL PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    format          TEXT NOT NULL CHECK (format IN ('csv','xlsx','pdf','json','ics','full_data_archive')),
    scope           TEXT NOT NULL CHECK (scope IN ('selection','filtered_results','workspace','saved','applications','all_personal_data')),
    filters         TEXT CHECK (filters IS NULL OR json_valid(filters)),
    item_count      INTEGER NOT NULL DEFAULT 0,
    file_path       TEXT,
    includes_personal_data INTEGER NOT NULL DEFAULT 0 CHECK (includes_personal_data IN (0,1)),
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_exports_user ON export_records(user_id, created_at DESC);

CREATE TABLE backup_records (
    id              TEXT NOT NULL PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind            TEXT NOT NULL CHECK (kind IN ('manual','scheduled','pre_migration','pre_restore')),
    file_path       TEXT NOT NULL,
    size_bytes      INTEGER NOT NULL,
    sha256          TEXT NOT NULL,
    schema_version  TEXT NOT NULL,
    encrypted       INTEGER NOT NULL DEFAULT 1 CHECK (encrypted IN (0,1)),
    status          TEXT NOT NULL CHECK (status IN ('ok','failed','restored','deleted')),
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_backups_user ON backup_records(user_id, created_at DESC);

-- =============================================================================
-- 13. SYNCHRONISATION ET AUDIT
-- =============================================================================

CREATE TABLE sync_devices (
    id              TEXT NOT NULL PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_name     TEXT NOT NULL,
    platform        TEXT NOT NULL CHECK (platform IN ('windows','linux','macos')),
    public_key      BLOB NOT NULL,                           -- X25519
    is_current      INTEGER NOT NULL DEFAULT 0 CHECK (is_current IN (0,1)),
    registered_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    last_sync_at    TEXT,
    revoked_at      TEXT
) STRICT;

CREATE TABLE sync_state (
    user_id         TEXT NOT NULL PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    server_url      TEXT NOT NULL,
    last_pull_cursor TEXT,
    last_push_at    TEXT,
    last_pull_at    TEXT,
    lamport_clock   INTEGER NOT NULL DEFAULT 0
) STRICT;

CREATE TABLE sync_outbox (                                 -- changements locaux à pousser
    id              INTEGER PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entity_table    TEXT NOT NULL,
    entity_id       TEXT NOT NULL,
    operation       TEXT NOT NULL CHECK (operation IN ('upsert','delete')),
    lamport         INTEGER NOT NULL,
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    pushed_at       TEXT
) STRICT;
CREATE INDEX ix_outbox_pending ON sync_outbox(user_id, pushed_at, id);

CREATE TABLE sync_conflicts (
    id              INTEGER PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entity_table    TEXT NOT NULL,
    entity_id       TEXT NOT NULL,
    local_payload   TEXT NOT NULL CHECK (json_valid(local_payload)),
    remote_payload  TEXT NOT NULL CHECK (json_valid(remote_payload)),
    resolution      TEXT CHECK (resolution IN ('local','remote','merged')),
    detected_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
    resolved_at     TEXT
) STRICT;

CREATE TABLE audit_logs (
    id              INTEGER PRIMARY KEY,
    user_id         TEXT REFERENCES users(id) ON DELETE SET NULL,
    organization_id TEXT REFERENCES organizations(id) ON DELETE CASCADE,
    action          TEXT NOT NULL,                           -- ex. 'profile.update', 'application.status_change'
    entity_table    TEXT,
    entity_id       TEXT,
    detail          TEXT CHECK (detail IS NULL OR json_valid(detail)),   -- expurgé
    created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
) STRICT;
CREATE INDEX ix_audit_user_time ON audit_logs(user_id, created_at DESC);
CREATE INDEX ix_audit_org_time ON audit_logs(organization_id, created_at DESC);

-- =============================================================================
-- 14. DÉCLENCHEURS MÉTIER
-- =============================================================================

-- Horodatage updated_at
CREATE TRIGGER trg_users_updated AFTER UPDATE ON users
WHEN new.updated_at = old.updated_at BEGIN
    UPDATE users SET updated_at = strftime('%Y-%m-%dT%H:%M:%SZ','now') WHERE id = new.id;
END;
CREATE TRIGGER trg_opportunities_updated AFTER UPDATE ON opportunities
WHEN new.updated_at = old.updated_at BEGIN
    UPDATE opportunities SET updated_at = strftime('%Y-%m-%dT%H:%M:%SZ','now') WHERE id = new.id;
END;
CREATE TRIGGER trg_saved_updated AFTER UPDATE ON saved_opportunities
WHEN new.updated_at = old.updated_at BEGIN
    UPDATE saved_opportunities SET updated_at = strftime('%Y-%m-%dT%H:%M:%SZ','now') WHERE id = new.id;
END;
CREATE TRIGGER trg_sources_updated AFTER UPDATE ON sources
WHEN new.updated_at = old.updated_at BEGIN
    UPDATE sources SET updated_at = strftime('%Y-%m-%dT%H:%M:%SZ','now') WHERE id = new.id;
END;

-- Historique automatique des statuts de candidature
CREATE TRIGGER trg_application_status_history AFTER UPDATE OF status ON applications
WHEN new.status <> old.status BEGIN
    INSERT INTO application_status_history(application_id, from_status, to_status, changed_by)
    VALUES (new.id, old.status, new.status, new.user_id);
    UPDATE applications SET updated_at = strftime('%Y-%m-%dT%H:%M:%SZ','now') WHERE id = new.id;
END;
CREATE TRIGGER trg_application_initial_status AFTER INSERT ON applications BEGIN
    INSERT INTO application_status_history(application_id, from_status, to_status, changed_by)
    VALUES (new.id, NULL, new.status, new.user_id);
END;

-- Cohérence user_id entre candidature et sauvegarde
CREATE TRIGGER trg_application_owner_check BEFORE INSERT ON applications
WHEN (SELECT user_id FROM saved_opportunities WHERE id = new.saved_id) <> new.user_id BEGIN
    SELECT RAISE(ABORT, 'applications.user_id doit correspondre au propriétaire de la sauvegarde');
END;

-- Une source exclue par son éditeur ne peut pas être réactivée
CREATE TRIGGER trg_source_exclusion_guard BEFORE UPDATE OF enabled ON sources
WHEN new.enabled = 1 AND EXISTS (SELECT 1 FROM domain_exclusions WHERE domain = new.domain) BEGIN
    SELECT RAISE(ABORT, 'domaine exclu à la demande de l''éditeur');
END;

-- Compteur d'échecs consécutifs des sources
CREATE TRIGGER trg_scan_run_finish AFTER UPDATE OF status ON source_scan_runs
WHEN new.status IN ('ok','partial','failed','blocked') AND old.status IN ('queued','running') BEGIN
    UPDATE sources SET
        last_attempt_at = new.finished_at,
        last_status = new.status,
        last_error = CASE WHEN new.status IN ('failed','blocked') THEN new.error_detail ELSE NULL END,
        last_success_at = CASE WHEN new.status IN ('ok','partial') THEN new.finished_at ELSE last_success_at END,
        consecutive_failures = CASE WHEN new.status IN ('failed','blocked') THEN consecutive_failures + 1 ELSE 0 END
    WHERE id = new.source_id;
END;

-- =============================================================================
-- 15. VUES
-- =============================================================================

CREATE VIEW v_upcoming_deadlines AS
SELECT s.user_id,
       s.id               AS saved_id,
       o.id               AS opportunity_id,
       o.title,
       o.organization_name,
       COALESCE(s.personal_deadline, o.deadline_on) AS effective_deadline,
       CAST(julianday(COALESCE(s.personal_deadline, o.deadline_on)) - julianday('now') AS INTEGER) AS days_left,
       a.status           AS application_status,
       s.priority
FROM saved_opportunities s
JOIN opportunities o ON o.id = s.opportunity_id
LEFT JOIN applications a ON a.saved_id = s.id
WHERE s.archived = 0
  AND COALESCE(s.personal_deadline, o.deadline_on) IS NOT NULL
  AND COALESCE(s.personal_deadline, o.deadline_on) >= date('now');

CREATE VIEW v_dashboard_counters AS
SELECT u.id AS user_id,
       (SELECT COUNT(*) FROM match_scores m WHERE m.user_id = u.id)                                   AS discovered,
       (SELECT COUNT(*) FROM match_scores m WHERE m.user_id = u.id AND m.score >= 60)                 AS relevant,
       (SELECT COUNT(*) FROM saved_opportunities s WHERE s.user_id = u.id AND s.archived = 0)         AS saved,
       (SELECT COUNT(*) FROM applications a WHERE a.user_id = u.id AND a.status IN ('preparing','ready')) AS in_progress,
       (SELECT COUNT(*) FROM applications a WHERE a.user_id = u.id AND a.status IN ('submitted','interview')) AS submitted,
       (SELECT COUNT(*) FROM v_upcoming_deadlines d WHERE d.user_id = u.id AND d.days_left <= 14)     AS deadlines_14d,
       (SELECT COUNT(*) FROM notification_records n WHERE n.user_id = u.id AND n.read_at IS NULL)     AS unread_notifications
FROM users u
WHERE u.deleted_at IS NULL;

CREATE VIEW v_source_health AS
SELECT s.id, s.name, s.domain, s.access_method, s.enabled, s.allowed_status,
       s.last_status, s.last_success_at, s.consecutive_failures, s.reliability_score,
       (SELECT COUNT(*) FROM opportunity_sources os WHERE os.source_id = s.id) AS opportunities_count
FROM sources s;

-- =============================================================================
-- 16. DONNÉES DE RÉFÉRENCE INITIALES
-- =============================================================================

INSERT INTO alembic_version(version_num) VALUES ('0001_baseline');

INSERT INTO application_settings(key, value, value_type, description) VALUES
 ('schema.version',            '1.0.0', 'string',  'Version du schéma'),
 ('http.user_agent',           'PIO/1.0 (+https://github.com/protegeqv/pio)', 'string', 'User-Agent déclaré aux sources'),
 ('http.max_concurrency',      '8',     'integer', 'Requêtes simultanées maximum'),
 ('http.per_domain_concurrency','1',    'integer', 'Requêtes simultanées par domaine'),
 ('http.min_delay_seconds',    '2',     'integer', 'Délai minimal entre deux requêtes vers un domaine'),
 ('http.timeout_seconds',      '30',    'integer', 'Délai d''expiration HTTP'),
 ('http.max_response_bytes',   '10485760', 'integer', 'Taille maximale d''une réponse'),
 ('http.max_redirects',        '5',     'integer', 'Redirections maximum'),
 ('backup.auto_enabled',       'true',  'boolean', 'Sauvegarde automatique'),
 ('backup.retention_count',    '7',     'integer', 'Nombre de sauvegardes conservées'),
 ('telemetry.enabled',         'false', 'boolean', 'Aucune télémétrie par défaut'),
 ('reminders.default_offsets', '[14,7,3,1]', 'json', 'Rappels avant date limite (jours)');

INSERT INTO languages(code, name_fr, name_en) VALUES
 ('fr','Français','French'), ('en','Anglais','English'), ('es','Espagnol','Spanish'),
 ('pt','Portugais','Portuguese'), ('de','Allemand','German'), ('ar','Arabe','Arabic'),
 ('zh','Chinois','Chinese'), ('sw','Swahili','Swahili');

INSERT INTO currencies(code, name, minor_units) VALUES
 ('XAF','Franc CFA (CEMAC)',0), ('XOF','Franc CFA (UEMOA)',0), ('EUR','Euro',2),
 ('USD','Dollar américain',2), ('GBP','Livre sterling',2), ('CAD','Dollar canadien',2),
 ('CHF','Franc suisse',2), ('NGN','Naira',2), ('ZAR','Rand',2), ('MAD','Dirham marocain',2);

INSERT INTO countries(code, name_fr, name_en, region, is_cemac) VALUES
 ('CM','Cameroun','Cameroon','Afrique centrale',1),
 ('GA','Gabon','Gabon','Afrique centrale',1),
 ('CG','Congo','Congo','Afrique centrale',1),
 ('TD','Tchad','Chad','Afrique centrale',1),
 ('CF','République centrafricaine','Central African Republic','Afrique centrale',1),
 ('GQ','Guinée équatoriale','Equatorial Guinea','Afrique centrale',1),
 ('CD','RD Congo','DR Congo','Afrique centrale',0),
 ('NG','Nigeria','Nigeria','Afrique de l''Ouest',0),
 ('SN','Sénégal','Senegal','Afrique de l''Ouest',0),
 ('CI','Côte d''Ivoire','Côte d''Ivoire','Afrique de l''Ouest',0),
 ('MA','Maroc','Morocco','Afrique du Nord',0),
 ('RW','Rwanda','Rwanda','Afrique de l''Est',0),
 ('KE','Kenya','Kenya','Afrique de l''Est',0),
 ('ZA','Afrique du Sud','South Africa','Afrique australe',0),
 ('FR','France','France','Europe',0),
 ('BE','Belgique','Belgium','Europe',0),
 ('DE','Allemagne','Germany','Europe',0),
 ('CH','Suisse','Switzerland','Europe',0),
 ('GB','Royaume-Uni','United Kingdom','Europe',0),
 ('CA','Canada','Canada','Amérique du Nord',0),
 ('US','États-Unis','United States','Amérique du Nord',0);

INSERT INTO opportunity_categories(id, code, parent_id, name_fr, name_en, sort_order) VALUES
 (1,'employment',NULL,'Emploi','Employment',1),
 (2,'internship',NULL,'Stages','Internships',2),
 (3,'freelance',NULL,'Missions freelance','Freelance missions',3),
 (4,'scholarship',NULL,'Bourses','Scholarships',4),
 (5,'grant',NULL,'Subventions et financements','Grants and funding',5),
 (6,'tender',NULL,'Appels d''offres et marchés','Tenders and procurement',6),
 (7,'entrepreneurship',NULL,'Entrepreneuriat','Entrepreneurship',7),
 (8,'acceleration',NULL,'Incubation et accélération','Startup acceleration',8),
 (9,'training',NULL,'Formations et certifications','Training and certifications',9),
 (10,'competition',NULL,'Concours et prix','Competitions and awards',10),
 (11,'research',NULL,'Recherche','Research',11),
 (12,'partnership',NULL,'Partenariats','Partnerships',12),
 (13,'volunteering',NULL,'Volontariat','Volunteering',13),
 (14,'call_for_applications',NULL,'Appels à candidatures','Calls for applications',14),
 (15,'other',NULL,'Autres opportunités','Other opportunities',15),
 (101,'scholarship.bachelor',4,'Bourse de licence','Bachelor scholarship',1),
 (102,'scholarship.master',4,'Bourse de master','Master scholarship',2),
 (103,'scholarship.phd',4,'Bourse de doctorat','PhD scholarship',3),
 (104,'scholarship.short_course',4,'Bourse de formation courte','Short course scholarship',4),
 (111,'grant.association',5,'Subvention associative','Association grant',1),
 (112,'grant.startup',5,'Financement de startup','Startup funding',2),
 (113,'grant.research',5,'Financement de recherche','Research funding',3),
 (114,'grant.individual',5,'Aide individuelle','Individual grant',4),
 (121,'tender.it_services',6,'Marché de services informatiques','IT services tender',1),
 (122,'tender.works',6,'Marché de travaux','Works tender',2),
 (123,'tender.supplies',6,'Marché de fournitures','Supplies tender',3),
 (131,'employment.full_time',1,'Emploi à temps plein','Full-time job',1),
 (132,'employment.consultancy',1,'Consultance','Consultancy',2),
 (133,'employment.international_org',1,'Organisation internationale','International organization',3);

INSERT INTO objectives(id, code, name_fr, name_en, default_category_id) VALUES
 (1,'find_job','Trouver un emploi','Find a job',1),
 (2,'find_internship','Trouver un stage','Find an internship',2),
 (3,'find_freelance','Trouver des missions freelance','Find freelance missions',3),
 (4,'find_scholarship','Trouver une bourse','Find scholarships',4),
 (5,'find_grant','Trouver une subvention ou une aide','Find grants or financial assistance',5),
 (6,'find_project_funding','Financer un projet ou une startup','Find funding for a project or startup',5),
 (7,'find_business','Trouver des opportunités d''affaires','Find business opportunities',12),
 (8,'find_tender','Trouver des appels d''offres','Find public and private tenders',6),
 (9,'find_training','Trouver des formations et certifications','Find training programs and certifications',9),
 (10,'find_competition','Trouver des concours et programmes d''innovation','Find competitions and innovation programs',10),
 (11,'find_entrepreneurship_support','Trouver un accompagnement entrepreneurial','Find entrepreneurship support',7),
 (12,'find_partnership','Trouver des partenariats','Find partnerships and collaboration',12),
 (13,'find_call','Trouver des appels à candidatures','Find calls for applications',14),
 (14,'find_research','Trouver des opportunités de recherche','Find research opportunities',11),
 (15,'find_volunteering','Trouver du volontariat','Find volunteer opportunities',13),
 (16,'find_professional_development','Trouver des programmes de développement professionnel','Find professional development programs',9);

COMMIT;

-- Vérifications post-création recommandées :
--   PRAGMA integrity_check;
--   PRAGMA foreign_key_check;
--   INSERT INTO opportunities_fts(opportunities_fts) VALUES ('integrity-check');
