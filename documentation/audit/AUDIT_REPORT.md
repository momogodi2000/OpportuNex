# Opportunex — Technical audit and finalisation report

> This is a living document. Each phase updates it. Every finding comes from reading the code or running commands, and cites its evidence (`file:line` or a command).

- **Audit start date:** 2026-10-15
- **Branch:** `finalisation`
- **Starting commit:** `a985077`

---

## A. Initial state (measured 2026-10-15)

### A.1 Previous sessions

- The local agent memory was empty, and there was no transcript of earlier work on this project.
- What survived is the Git history and three files deleted in the working tree but recoverable from `HEAD`:
  - `documentation/PROGRESS.md`
  - `documentation/DECISIONS.md`
  - `master_prompt.md`
- `PROGRESS.md` claimed: 30 COMPLETE, 10 PARTIAL, 5 MOCK and 131 MISSING, out of 176 requirements (113 Must). **This claim does not hold up:** several items marked "COMPLETE" fail at runtime (see A.4).
- The `*-err.log` and `*-out.log` files deleted from the working tree were committed empty (0 bytes), so they say nothing about the failures.

### A.2 Confirmed architecture and technologies

| Layer | Technology | Location |
| --- | --- | --- |
| Desktop UI | Flutter 3.41.2 / Dart 3.11, Riverpod 2.6, go_router 17, freezed 2.5, Dio + http | `apps/desktop` |
| Local engine | Python 3.14.2 (venv `engine/.venv`), FastAPI 0.142, SQLAlchemy 2.1 (async + aiosqlite), uvicorn | `engine` |
| Storage | Plain SQLite (SQLCipher is **not** active) | `~/.opportunex` (not D-27) |
| Communication | Local HTTP on 127.0.0.1, random port, token over stdin | `engine/main.py`, `engine_supervisor.dart` |
| Packaging | Copy scripts only (no PyInstaller, no Inno Setup) | `build-windows.ps1`, `build-deb.sh` |

### A.3 Blocking problems

| # | Problem | Evidence | Severity |
| --- | --- | --- | --- |
| B-01 | **The engine fails to import**: a SyntaxError (escaped docstring `\"\"\"`) breaks the whole router import chain. | `engine/api/routers/export.py:46` | Blocking |
| B-02 | The UI's `/health` check is sent without a token, so it always gets 401. The UI waits about 62 s, then restarts the engine 3 times. | `apps/desktop/lib/core/engine/engine_supervisor.dart:127`; `_PUBLIC_PATHS` is never used in `engine/api/dependencies.py:23` | Blocking |
| B-03 | The `/api/v1/events` WebSocket is never mounted. | `engine/api/app.py`, `engine/api/events.py:128` | Major |
| B-04 | The UI launches an `engine.exe` that no build step produces. | `engine_supervisor.dart:142`, `build-windows.ps1:33` | Blocking (release) |
| B-05 | `launch-dev.ps1` starts the engine without wiring stdin, so it blocks on `readline`. It also uses a hard-coded token. | `launch-dev.ps1:71-72` | Blocking (dev) |
| B-06 | `requirements.txt` is incomplete: `email-validator` and `python-multipart` are missing, and selectolax 1.0 removed `HTMLParser`. | Imports run in `dist-venv` | Blocking (build) |
| B-07 | ORM and SQL schema have diverged: 35 ORM tables against the schema's 85, with different columns. The routers are written against the schema, so most write operations return 500. | `persistence/models/all_models.py` vs `pio_schema.sql` | Blocking |
| B-08 | **SQLCipher is not used**: `PRAGMA key` does nothing on plain SQLite, so the database is stored unencrypted. | `persistence/database.py:50,71` | Critical (security) |
| B-09 | User identity comes from an unauthenticated `X-User-Id` header. | `api/dependencies.py` | Critical (security) |
| B-10 | Two Flutter repositories point to fictitious hosts. | `search_provider.dart:7-9`, `opportunity_provider.dart:38-43` | Blocking |
| B-11 | `LICENSE` contains unresolved Git conflict markers: a truncated AGPL notice on one side, the full GPL v3 on the other. | `LICENSE:1,46,721` | Critical (legal) |
| B-12 | Build output, `.pyc` files and `.env` files are committed, and there is no root `.gitignore`. | `git ls-files` | Major |

### A.4 Module status before any fixes

| Module | Measured status | Main evidence |
| --- | --- | --- |
| M01 Auth | Partial: works in the engine but not reachable | Real `auth_service`. Static recovery salt (`auth_service.py:88`), lockout broken (`:190`). Registration UI is a mock (`register_page.dart:53-76`). |
| M02 Profile/onboarding | Partial | `PUT /profile/objectives` returns 500 (`profile_repo.py:107`). The onboarding UI is a mock and its "Terminer" button does nothing. |
| M03 CV import | Mock | `cv_import.py` returns "John Doe". |
| M04 Search | Broken | `search_service.py:60` raises TypeError, `:94` calls a missing `close()`. `/interpret` uses keywords only. Progress in the UI is simulated. |
| M05 Collection | Broken | `collection/reader.py:125,157,210,263` uses `await` on a synchronous client. |
| M06 Sources | Stub | The `source` router is a stub; the catalogue is not exposed. |
| M07 AI analysis | Absent / not wired | `ai/gateway.py` is never called; `SafeHTTPClient.post` does not exist. |
| M08 Matching | Not wired | `matching/scorer.py` is never called; the score is a hard-coded 85 (`search.py:82`). |
| M09 Dedup/results | Absent | `dedup.find_duplicate` returns `None`. |
| M10 Opportunity sheet | Broken | `opportunity.py:116` uses `row`, which is undefined. The UI buttons have no action. |
| M11 Dashboard | Broken | All 4 endpoints fail with 500 (missing views and columns). |
| M12 Tracking | Mock / broken | `applications_page.dart` shows hard-coded data. POST `/saved` hits a CHECK constraint error. |
| M13 Monitors | Stub | Router has no persistence; `setup_scheduler` is never called. |
| M14 AI providers | Stub | Keys are stored by name but deleted by id. |
| M15 Workspaces | Partial | POST is broken (`workspace_repo.py:15`). |
| M16 Exports | Broken | SyntaxError, and the code references attributes that do not exist. The Flutter UI is simulated (`export_panel.dart:125`). |
| M17 Sync/organisations | Stub | — |
| M18 Settings/privacy/backup | Partial | `backup_service` works but is not connected. Some 20 settings handlers are empty. |

### A.5 Initial test results

| Command | Result |
| --- | --- |
| `pytest` (engine) | **Both test files fail at collection** (SyntaxError B-01). `.pytest_cache/lastfailed` lists both. |
| `flutter test` | Likely fails: `FlutterSecureStorage` has no mock in `widget_test.dart`. Measured in phase 2. |

---

## B. Work done

### Phase 0 — Repository hygiene (commit `0700a6f`)
- Root `.gitignore`. Untracked, but kept on disk: `build/windows-dist` (165 files), 137 `__pycache__` folders, `engine/.coverage`, the `.env` files and the 4 empty logs.
- Decision register updated with the identity (ETS Monthe Network / Momo Godi Yvan) and the rule-vs-spec rulings C-01..C-05. Traceability matrix created for the 176 requirements.

### Phase 1 — Engine boot, schema, encryption, sessions, backups
Almost all of the previous engine code was built on an ORM that no longer matched the schema, and it could not start. That code was **moved with `git mv` to `engine/_legacy/`** (nothing deleted), and a new core was written:

| Area | File(s) | What it fixes |
| --- | --- | --- |
| Validated configuration, D-27 data folder | `engine/core/config.py` | Data now lives in `%APPDATA%\PIO`; `.env` was never read before; resources work from a PyInstaller bundle |
| RFC 9457 errors with stable codes | `engine/core/errors.py`, `api/app.py` | SQL parameters no longer leak into the logs |
| Monotonic UUID v7 | `engine/core/ids.py` | ADR-004 |
| Redacted JSON logs with rotation | `engine/core/logging.py`, `security/redaction.py` | E-mails, tokens, keys and phone numbers are masked; ISO dates are kept |
| Schema is `pio_schema.sql` (bundled copy, tested identical) + Alembic | `persistence/database.py`, `persistence/migrations/` | B-07: tables are **reflected from the live database**, so ORM and schema can no longer drift. Revision `0002_product_identity` is reversible. A database from a newer version is refused. Integrity is checked on open |
| Real SQLCipher 4.12, one database per profile | `persistence/database.py`, `services/auth_service.py` | B-08: the file cannot be read without the key (tested) |
| Key management per arch §9.1 | `security/crypto.py`, `persistence/registry.py` | A 256-bit data key, wrapped by both the password and the recovery phrase (separate salts). The registry never stores the e-mail in clear |
| BIP-39 recovery phrase, FR/EN, 2048-word lists | `security/recovery.py` | Replaces the 100-word list and the static salt |
| Password policy | `security/passwords.py` | At least 12 characters, zxcvbn score ≥ 3, checked against 10,012 known-compromised passwords (SecLists, MIT) |
| Bearer sessions and auto-lock | `services/state.py`, `api/deps.py` | B-09: `X-User-Id` removed. The key is wiped from memory on lock |
| Progressive lockout | `services/auth_service.py::lockout_minutes` | 1 min after the 5th failure, then doubling, capped at 60 min |
| Transport guard for HTTP and WebSocket | `api/security.py` | B-02: `/health` is public. The engine token is required, including on WebSockets. Requests with an `Origin` header or a non-loopback `Host` are rejected |
| `/api/v1/events` channel mounted | `api/events.py` | B-03 |
| Startup | `engine/main.py` | B-05: token read from stdin with a timeout; `PORT:` printed as soon as the socket listens; single-instance lock (D-26); clean shutdown; `--self-test` mode |
| Persistent background jobs | `services/jobs.py` | Progress, cancellation, resume after interruption (`paused`) |
| Backup and restore | `services/backup_service.py`, `services/maintenance_service.py` | Consolidates the existing service: encrypted `.opxbak` archive with a SHA-256 manifest; daily and manual backups; keep 7 (ruling C-02); pre-migration and pre-restore backups; verified restore with rollback; import onto a new machine |
| Dependencies | `engine/requirements*.txt`, `pyproject.toml` | B-06: added email-validator, python-multipart, sqlcipher3-wheels and reportlab; pinned selectolax<1.0; fixed the build backend |
| Dev launcher | `launch-dev.ps1` | No hard-coded token; `-Setup`, `-Checks` and `-EngineOnly` options |

Also found: the old "60+ sources" catalogue contained **about 46 fake entries** (`www.source16.africa` … `source61.africa`). It will be rebuilt from verified sources in phase 3.

### Phase 2 — Desktop launches, supervises the engine, real auth flow
The old Flutter `lib/` and `test/` were moved with `git mv` to `apps/desktop/_legacy_lib/` (nothing deleted). Feature pages will be rebuilt against the real engine in Phase 3 instead of being patched twice. New core:

| Area | File(s) | What it fixes / adds |
| --- | --- | --- |
| Engine supervisor (arch §3.4) | `lib/core/engine/engine_supervisor.dart`, `engine_locator.dart` | Locates the packaged engine (`engine/opportunex-engine.exe`) or the dev checkout (`engine/.venv` + `main.py`) or `OPX_ENGINE_CMD`. Sends a 256-bit token on stdin, reads `PORT:`, runs an authenticated `/health` poll for up to 10 s, retries 3 times with back-off, kills the old process before a restart, writes stderr to `logs/engine-process.log`, shuts down gracefully when the window closes |
| Diagnostics screen | `lib/features/startup/startup_page.dart` | Replaces the infinite spinner: cause (not found / already running / timeout / crash), log tail, copy, open logs folder, retry |
| Single API client | `lib/core/api/api_client.dart`, `api_exception.dart` | One Dio instance with the engine token and session bearer, RFC 9457 → `ApiException`. The fictitious hosts (`api.opportunex.*`) and the duplicate `http` client are gone |
| Events | `lib/core/api/engine_events.dart` | `/api/v1/events` WebSocket with the token header and reconnect |
| Auth state machine + guarded router | `lib/features/auth/auth_controller.dart`, `lib/core/router/app_router.dart` | Unknown → signed out → locked → signed in. Redirects are pure and unit-tested. Reacts to auto-lock events and 401 `session_locked` |
| Real auth screens | `lib/features/auth/pages/*` | Profile picker, sign-in, registration with a live strength meter (engine zxcvbn), one-time recovery phrase, unlock, recovery, import from backup |
| Settings | `lib/features/settings/*` | Language, theme, auto-lock, password change, lock, account deletion (type DELETE + password), backups (create / verify / restore with type RESTORE + password / delete / auto toggle), maintenance (integrity, optimise, storage, log export), About (version, publisher, author, licence, third-party licences) |
| Offline legal texts (EF-18.09) | `assets/legal/*.md`, `lib/features/legal/legal_page.dart` | FR/EN terms of use and privacy policy describing the real behaviour |
| Design tokens + themes | `lib/core/theme/tokens.dart`, `app_theme.dart` | Palette taken from the logo (D-19 updated), AA contrast light/dark, semantic status colours, motion tokens honouring reduced motion |
| i18n | `lib/l10n/app_fr.arb`, `app_en.arb` (gen-l10n) | Replaces the hand-rolled 23-key map; every string in the new code is localised |
| Fonts and icons | `assets/fonts/Inter-*.ttf` + OFL, `packaging/branding/make_icons.py` | The "Inter" files were **6-byte placeholders**, replaced with Inter 4.1. The `.ico` and in-app icon were the whole brand sheet shrunk down; the real app tile is now cropped reproducibly (Windows `.ico` 16–256, Linux hicolor 16–512) |
| Platform metadata | `windows/runner/Runner.rc`, `main.cpp`, `linux/CMakeLists.txt`, `my_application.cc`, macOS config | ETS Monthe Network / Opportunex / AGPL instead of "com.protegeqv … All rights reserved" |

### Phase 3 — Functional modules end to end (engine commit `689a030`, desktop commit after it)
**Engine.** Each module of the specification runs on the real encrypted database:
- **Profile (M02).** 7-step onboarding data, organisation profile, completeness indicator, and a summary composed only from validated data.
- **CV import (M03).** PDF/DOCX/TXT, type checked by content, parsed in a separate process, macro-enabled DOCX refused, item-by-item review.
- **Search and collection (M04/M05/M09).**
  - Rule-based FR/EN interpreter; background jobs with per-source progress, cancel and resume.
  - `PoliteClient`: SSRF guard with DNS pinning, robots.txt, ≥ 2 s per domain, ETag cache, size and redirect caps.
  - Declarative adapters `rss`, `json_api` and `html_list`; JSON-LD detail pages.
  - Normalisation of dates, XAF minor units, ISO countries and languages; verbatim clauses.
  - Deduplication by URL, id, fingerprint and simhash/rapidfuzz, keeping the original publisher; FTS5 local search.
- **Sources (M06).** The fake catalogue was replaced by **74 real sources**:
  - 20 feeds/APIs verified live by `tools/verify_sources.py --apply`;
  - 54 official portals without a feed, shipped disabled as official links.
- **Matching (M08).** Deterministic weighted scorer with breakdown, strengths, gaps and points to verify. Eligibility is never asserted.
- **Opportunity sheet (M10).** 13 sections with provenance, recheck, and checklist from requirements. Template drafts use the validated profile only; any invented item is flagged.
- **Tracking (M12).** 11 statuses with history, notes, tags, priorities, events, encrypted attachments, board, calendar and `.ics`.
- **Dashboard (M11)**, **monitors and reminders (M13)**, **workspaces (M15)** and **exports CSV/XLSX/PDF/JSON plus personal archive and import (M16)**.
- **Privacy dashboard, selective erasure and network settings (M18).**

Bugs fixed with regression tests along the way:
- Dynamic routes returned 422 because of postponed annotations.
- `database is locked` under concurrent writes → `BEGIN IMMEDIATE` + per-database lock.
- A crashed job left its run "running".
- A rerun queried every enabled source.
- Eligibility clauses under headings were missed.
- Non-ASCII `Content-Disposition` names crashed.
- The opportunity sheet crashed for saved items (missing `.mappings()`).

**Desktop (this phase).**

| Area | File(s) | What it adds |
| --- | --- | --- |
| Navigation | `lib/core/router/app_router.dart`, `features/shell/nav_items.dart` | Dashboard (new home), search, saved items, monitors, workspaces, sources, profile and settings. Onboarding opens once after registration; it can be left and resumed from the profile |
| Dashboard | `features/dashboard/` | Real counters, deadlines at 7/14/30 days, applications by status, follow-ups, recommendations, source health, first-steps card |
| Search and sheet | `features/search/`, `features/opportunity/` | Free query → editable filters → background run with live progress, history, exports; 13-section sheet with score breakdown |
| Profile, onboarding, CV | `features/profile/` | All profile sections through a shared form spec, 7-step wizard, CV review screen |
| Tracking | `features/tracking/` | List / Kanban (drag and drop) / calendar, application page (status, events, checklist, encrypted documents, notes), document drafts with versions and integrity warnings |
| Monitors and notifications | `features/monitors/`, `features/shell/desktop_integration.dart` | Monitor CRUD and run now, notification centre with deep links, native toasts (`local_notifier`), tray icon with close-to-tray (default on, can be turned off) so monitors keep running |
| Workspaces | `features/workspaces/` | Templates, queries, opportunities, notes, comparison of 2–4 opportunities |
| Sources | `features/sources/` | Catalogue with filters, reliability, last success/error, official links, add custom source, enable/disable |
| Settings | `features/settings/settings_extra.dart` | Preferences (notification kinds, reminder offsets, score weights, proxy / data saver / bandwidth, close-to-tray), Privacy (stored data, disclosures, consents with withdrawal, full export, JSON import, selective erasure) |
| i18n | `lib/l10n/*.arb`, `tool/l10n_phase3a.json`, `tool/l10n_phase3b.json` | Every new string localised in French and English (0 missing keys) |

**Fixed during this phase:**
- The "opportunity changed" notification bypassed the notification preferences and carried no title or link → it now goes through `NotificationService.notify`, with a regression test.
- The onboarding step titles did not match their pages.
- The objectives editor mutated its own state list in place.
- "Later" in onboarding silently marked onboarding as complete.

Tests added: `tests/test_collection_units.py` covers the JSON API and HTML list adapters, invalid adapter specs, the explicit User-Agent, conditional requests (ETag/304) and the reliability score. These were previously untested.

### Phase 4 — AI gateway, consent and provenance (M07, M14)
AI is **optional and off by default** (D-15). Every feature already worked without it in phase 3. The AI layer only structures, summarises, translates and drafts; it never computes the relevance score (arch §7).

| Area | File(s) | What it does |
| --- | --- | --- |
| Provider adapters (EF-14.01) | `engine/ai/providers.py` | One adapter per API family: OpenAI-compatible (also Mistral, Groq, OpenRouter, LM Studio), Gemini, Anthropic, Ollama. Temperature 0 and JSON output. No tools are offered to the model. Remote addresses must use HTTPS; plain HTTP is accepted only on loopback. Keys travel in headers, never in URLs |
| Keys (EF-14.02) | `engine/ai/secrets.py`, `services/ai_service.py` | API keys go to the OS keychain (`keyring`). The database stores only a reference. `SecretStr` keeps keys out of validation errors and logs. Keys are removed when the provider or the account is deleted |
| Gateway (ADR-008) | `engine/ai/gateway.py` | Routed provider first, then the fallback chain (EF-14.04/05); daily cap and suspension after 429 using `Retry-After` (EF-14.06); cache keyed on task + template version + model + content (EF-14.08); strict schema validation with one corrective retry, then the next provider, then the deterministic path (EF-07.07); every attempt in `ai_usage_logs` (EF-14.07) |
| Consent (EF-14.09) | gateway + `api/routers/ai.py` + `features/ai/ai_consent.dart` | Consent is per provider and per purpose (`ai_remote_processing`, `profile_to_ai`, `cv_parsing_ai`). The engine answers 409 `ai_consent_required` **before** sending anything, and the desktop shows who receives what. Local models need no consent. Every send is written to `data_disclosures` and shown in the privacy dashboard |
| Minimisation (EF-14.10) | `engine/ai/anonymize.py` | The anonymised profile carries no name, contact, links or internal ids. Free text is scrubbed of e-mails, phones and URLs. CV text has the user's name removed. Letter headers (name, city) are filled in locally |
| Injection defence (EF-07.06) | `engine/ai/prompts.py` | Versioned templates with fixed instructions. Untrusted data sits in a delimited block with a random nonce, and look-alike tags are neutralised. Suspected injections are logged in `security_events` |
| Post-checks (arch §7.2-5, EF-07.02-04) | `engine/ai/checks.py` | A value is `explicit` only if its excerpt is found word for word in the announcement and the value is readable in it (dates in FR/EN forms, amounts by digits). Otherwise it is `inferred` or `unverifiable`. Eligibility clauses that are not verbatim are dropped. Structured data is never overwritten |
| Features using AI | `services/ai_tasks.py` | Query interpretation (merged into the rules, restricted to reference codes); opportunity analysis and ≤ 5-line summary; translation on demand; CV parsing (items absent from the CV are dropped); document drafting from the anonymised profile, with the integrity check still applied |
| Desktop | `features/ai/*`, search, opportunity sheet, CV import, generated documents | Settings > AI: master switch, providers (add, test and pick a model, enable, reorder, edit key, delete), routing per task, 30-day usage. Consent dialog. "Analyse with AI" and "Translate" on the sheet. AI fields shown with their provenance and excerpt. "Draft with AI" option and AI switch in CV import, both offered only when AI is on |

Also fixed: `pyproject.toml` packaged only part of the engine (`search`, `documents` and `matching` were missing; `ai` is now added). Coverage now measures those packages too. A `datetime.utcnow()` deprecation was replaced.

Not done in this phase, by design or for lack of a resource:
- AI analysis runs on demand, not automatically during every search.
- Embeddings (EF-08.07, Could) are not implemented.
- The real providers were not called. The adapters are tested against a local server reproducing their wire formats (`tests/fixtures/fake_ai.py`).
- The OS keychain backend is a thin `keyring` wrapper that the automated tests do not exercise, because they use an in-memory store so they never write to Windows Credential Manager.

### Phase 5 — UI/UX polish and accessibility
Method: a **screenshot tour** (`apps/desktop/integration_test/ui_tour_test.dart`). It runs the real app against the real engine and a local publisher. It fills the profile, collects 5 opportunities, tracks applications and creates a monitor, a workspace and a draft. It then saves 99 PNGs of every page: light, dark, the minimum window size (960×640), 150 % text and English. It records every layout error and runs Flutter's accessibility guidelines (labelled tap targets, measured text contrast) on each page in both themes. I reviewed the screenshots and fixed what they showed.

Defects found and fixed:
- **Monitors ran at the wrong hour (engine).** "Every day at 08:00" was computed in UTC and showed as 09:00 in Douala. Schedules now use the user's local time, daylight saving included. Regression test in `test_schedule_rules`.
- **Matching strengths were raw codes.** "master", "3", "CM", "employment" now read as sentences ("Niveau d'études atteint : Master"…). Education levels in the gaps are also readable.
- **Dashboard.** The six counters wrapped onto two rows at 1440 px; they now fill one row (3 or 2 per row on narrower windows). The deadline badge now reads "J-5" with a tooltip instead of a bare number.
- **Cards and lists.**
  - Cards no longer print "Non précisé" for an unknown organisation, or an empty score gauge outside search results.
  - The profile shows "4" instead of "4.0", and dates as "09/2017".
  - Calendar deadlines are dates, without a fake "00:00".
- **Application page.**
  - Status actions follow the lifecycle (Entretien → Acceptée → Refusée → Retirée → Archivée) instead of alphabetical order.
  - "0 sur 0 terminés" is hidden on an empty checklist.
  - The interest segment no longer wraps.
- **Navigation and search.** The Kanban board now shows a permanent horizontal scrollbar (11 columns). The 13 manual-link sources in the search summary are collapsed behind their count.
- **Accessibility.**
  - On/off switches (sources, monitors, AI providers) and the comparison checkboxes now have labels for screen readers.
  - A bare "—" value now reads "Non précisé".
  - Score-breakdown and property labels use flexible columns, so words no longer break at large text sizes.
- **Test tooling.** The tour itself was briefly wrong about the light theme (the profile theme "system" followed the dark OS); it now forces each theme.

Added (gaps from the traceability matrix):
- Command palette (Ctrl+K) with accent-insensitive search and keyboard navigation; Ctrl+F; F1 / Ctrl+/ shortcut help, also in the user menu (EF-18.13).
- Source frequency and categories dialog (EF-06.03/04).
- Monitor run history (EF-13.07).
- Comparison with the previous run of a search; the engine now returns the previous run (EF-15.04).
- Configurable auto-archive delay, engine setting `tracking.auto_archive_days` with 0 = off (EF-12.12).
- Optional launch at session start, minimised to the tray (EF-13.09). The app shows its window anyway when no tray is available.

Accessibility evidence:
- `test/core/contrast_test.dart` checks 15 text/background pairs in each theme (30 checks) against WCAG AA 4.5:1; all pass.
- In the tour, every tap target on every page is labelled, in both themes, with no layout error at 150 % text or at 960×640.
- The text-contrast guideline still reports 3 findings in light mode: the selected query in the search box, the "Soumise" chip, and the short value "CM". I checked them against the screenshots: they are sampling artifacts (selection highlight, chip border, anti-aliasing on short text), not low-contrast text.

### Phase 6 — Organisations and end-to-end encrypted sync (M17, EF-01.09-12)
Scope follows D-09; the design decisions are D-29 to D-35 in `documentation/DECISIONS.md`.

**Sync server** (`sync-server/`, new, AGPL v3). FastAPI with SQLAlchemy, on SQLite for development and tests or PostgreSQL in production. It stores account metadata, device public keys, sealed key envelopes and ciphertext records.

| Area | What it does |
| --- | --- |
| Accounts | E-mail verified by code or link, Argon2id password, optional TOTP (RFC 6238), password reset by e-mail that does **not** give access to data, lockout after 5 failures, rate limit on authentication, remote account deletion |
| Devices | First device active; later ones wait for approval; approval stores the sync key sealed to the device; revocation |
| Records | Push/pull by scope (`user` or `org:<id>`), idempotent by operation id, ordered cursor, per-account quota, size limits |
| Organisations | Roles owner/admin/editor/viewer enforced on writes, invitations by e-mail or code, key envelopes per member and version, rotation required after a departure, audit log |
| Operations | `/v1/health`, Prometheus `/metrics`, Dockerfile, Compose (API + PostgreSQL 16 + Caddy TLS 1.3 + daily dump kept 7 days), README FR/EN, `.env.example` |

**Engine** (`engine/sync/`, migration `0004_sync`):
- **Encryption.** XChaCha20-Poly1305 with scope and operation id as associated data, so the server cannot move or relabel a record. Keys are handed over in X25519 sealed boxes.
- **Pairing code.** A 12-digit code derived from the new device's key; the approving device refuses a code that does not match the key it is about to trust.
- **Change capture.** 82 triggers record every write on the synchronised tables, only while sync is linked and never while a remote change is being applied.
- **Merge.** Three-way, field by field, against the last synchronised version. When the same text field is changed on two devices, it is kept for a manual choice.
- **References.** Opportunities are referenced by URL and recreated locally; children whose integer keys differ between devices travel as lists inside their parent.
- **Organisations.** Keys are received, handed to new members and rotated; a viewer's refused edit is undone locally; leaving keeps personal copies.
- **Schedule.** A round runs every 5 minutes while linked.

**Desktop:** Settings > Synchronisation (create or link an account, confirm the e-mail, reset the password, pairing code and device approval, conflicts, TOTP, remote deletion, unlink). Organisations page (create, join, invite, roles, remove, leave, activity log). "Share with an organisation" on workspaces. Readable messages for the server's error codes.

Found and fixed while doing it:
- **Failed logins were not counted.** The failed-login counter on the server was rolled back by the very error that reported the failure, so lockout never triggered. The counter is now committed separately; caught by a test.
- **Plain error messages showed as "unknown error".** `showError` turned plain messages into "unknown error", so the AI "unavailable" message added in phase 4 was never shown.
- **Applications gained duplicate history entries.** The schema's own status-history triggers duplicated history when a synchronised application was written; the history is now rebuilt as a union.
- **The sidebar kept saying "Mode local" after linking.** The desktop now refreshes the account after any sync action.
- **The package list omitted `sync`.** The engine's `pyproject.toml` did not package the new `sync` package; added.

Not verified in this session:
- The Docker image was **not built**. Docker Desktop fails to start on this machine: its backend crashes on a stale socket at `%LOCALAPPDATA%\Docker\run\dockerInference`. So the PostgreSQL path and Caddy configuration are untested; the server was tested on SQLite.
- No official instance exists (D-35).
- SMTP delivery was not tested against a real mail server; the logged-message fallback was used.

### Phase 7 — Licensing, identity and distributable builds
**Licence and identity.**
- `LICENSE` held unresolved merge-conflict markers mixing a truncated AGPL notice with the GPL v3 text. It is now the verbatim AGPL-3.0 from gnu.org (661 lines).
- New legal and community files: `NOTICE` (copyright Momo Godi Yvan / ETS Monthe Network and contributors; docs under CC BY-SA 4.0; connectors under Apache 2.0), `AUTHORS`, `CONTRIBUTING.md` (DCO plus an inbound licence grant, listed for legal review), `CODE_OF_CONDUCT.md`, `SECURITY.md` (GitHub private reporting, no personal e-mail), `TRADEMARKS.md`, `CHANGELOG.md`.
- `README.md` (FR) and `README.en.md` rewritten. The old README credited PROTEGE QV, promised weekly backups kept 6 weeks (the code does daily, keeps 7) and "60+ sources" (the catalogue has 74, of which 20 verified feeds).
- Windows `Runner.rc`, the Linux application id and the in-app About page carry the new identity. The only remaining "PROTEGE QV" text is in `apps/desktop/_legacy_lib/`, archived code that is not compiled.

**Third-party licences.** `engine/tools/third_party_notices.py` walks the engine's runtime dependency tree and the desktop's `pubspec.lock`. It writes `THIRD_PARTY_NOTICES.md` and the full texts to `packaging/licenses/`, which ship with the app.
- 179 components; none flagged as incompatible with AGPL v3.
- Three licences were reviewed by hand: certifi (MPL-2.0), tld (LGPL-2.1-or-later option) and regex (Apache-2.0 and CNRI-Python). regex was added to `LEGAL_DECISIONS_NEEDED.md` for the owner's lawyer.

**Engine binary.** `packaging/engine/opportunex-engine.spec` builds a PyInstaller one-folder engine (D-13) with the schema, migrations, connector catalogue and word lists. It carries a version resource for ETS Monthe Network.
- `--self-test` now also exercises the libraries that only fail when frozen: text and structured-data extraction, dates, language detection, PDF and DOCX generation, the isolated CV parser (multiprocessing), XLSX, libsodium and the keychain.
- That check found that **structured-data extraction silently failed in the frozen engine**: extruct's own dependencies were missing. They are now bundled, and the error that was swallowed is logged.

**Windows.** `packaging/windows/build.ps1` builds and self-tests the engine, builds the Flutter release and assembles `dist/windows/Opportunex/` with `engine/` and `licenses/`. It then produces:
- the portable ZIP;
- the Inno Setup installer (`packaging/windows/opportunex.iss`);
- `SHA256SUMS.txt`.

The installer installs per user without administrator rights (per-machine on request), in French or English, with a licence page and an optional desktop icon. On uninstall it removes the "launch at sign-in" entry and asks before deleting user data (default: keep; silent uninstalls keep it). Binaries are unsigned (D-12).

**Linux.** `packaging/linux/Dockerfile` (Ubuntu 24.04 builder) and `build-deb.sh` build the PyInstaller engine and the Flutter bundle into `/opt/opportunex`, with a `.desktop` file, icons, the correct `Depends:` (GTK 3, appindicator, libnotify, libsecret) and postinst/postrm. `test-deb.sh` installs the package in a clean container, runs the engine self-test, starts the app under Xvfb and checks removal. **Not run**: Docker does not start on this machine.

**CI.** `.github/workflows/ci.yml` runs engine lint, types, tests and self-test on Ubuntu and Windows, plus the sync-server tests, Flutter analyze and test, and a sync-server image check against PostgreSQL. `release.yml` builds the Windows and Debian packages on a version tag. Neither has run yet: nothing has been pushed.

**Obsolete scripts.** `build-windows.ps1`, `build-linux.ps1`, `build-deb.sh` and `Dockerfile.linux-builder` were moved from the root to `packaging/legacy/` with a note. They shipped a raw Python environment instead of an engine binary. They were moved rather than deleted.

Found and fixed while doing it:
- **Orphan engine after a crash.** Testing the installed build showed that when the app is killed or crashes, the engine keeps running. It then holds the single-instance lock, so the next launch fails with "already running". The cause: the UI closes stdin after sending the token, so the engine has no way to notice. The UI now passes `--parent-pid` and the engine shuts down when that process ends (`core/parent_watch.py`, two regression tests, one of them with a real engine process).
- `ruff format` had never been applied to the engine; it is now, so the CI format check is meaningful.

## C. Test results

| Date | Command (in `engine/`) | Result |
| --- | --- | --- |
| 2026-10-15 | `.venv\Scripts\python -m pytest -q --cov` | **51 passed, 0 failed**, 90 % coverage (1,855 statements) |
| 2026-10-15 | `.venv\Scripts\python -m ruff check .` | Clean |
| 2026-10-15 | `.venv\Scripts\python -m mypy .` | Clean (35 files) |
| 2026-10-15 | `.venv\Scripts\python main.py --self-test` | `SELF-TEST OK engine=1.0.0 schema=0002_product_identity` |
| 2026-10-15 | Real subprocess launch (token on stdin) | `PORT:` after 1.1 s; `/health` ready after 3.9 s (first cold start); a second instance is refused (exit code 3); clean shutdown |

| 2026-10-15 | `flutter analyze` (apps/desktop) | No issues |
| 2026-10-15 | `flutter test` | **20 passed** (redirect rules, locator, supervisor handshake/failures, problem parsing, auth widgets) |
| 2026-10-15 | `flutter test integration_test/app_e2e_test.dart -d windows` | **1 passed (14 s)**: real Windows build + real engine — register → recovery phrase → settings → Ctrl+L lock → unlock → encrypted backup created on disk |

Phase 3 (same machine):

| Date | Command | Result |
| --- | --- | --- |
| 2026-10-15 | `engine: pytest -q --cov` | **97 passed, 0 failed**, 88 % coverage (5,893 statements) |
| 2026-10-15 | `engine: ruff check . · mypy .` | Clean · Clean (76 files) |
| 2026-10-15 | `desktop: flutter analyze` | No issues |
| 2026-10-15 | `desktop: flutter test` | **22 passed** (adds onboarding landing and notification deep-link rules) |
| 2026-10-15 | `desktop: flutter test integration_test/app_e2e_test.dart -d windows` | **1 passed (17 s)**: register → recovery phrase → onboarding → "Later" → dashboard (first steps) → sources catalogue → settings → privacy dashboard → Ctrl+L lock → unlock → encrypted backup on disk |

Phase 4 (same machine, 2026-10-16):

| Date | Command | Result |
| --- | --- | --- |
| 2026-10-16 | `engine: pytest -q --cov` | **120 passed, 0 failed, 0 warnings**, 88 % coverage (7,628 statements, now including `ai`, `search`, `documents`, `matching`) |
| 2026-10-16 | `engine: ruff check . · mypy .` | Clean · Clean (87 files) |
| 2026-10-16 | `desktop: flutter analyze · flutter test` | No issues · **24 passed** (adds the consent dialog: allow and retry, continue without AI) |
| 2026-10-16 | `desktop: flutter test integration_test/app_e2e_test.dart -d windows` | **1 passed (17 s)**; also checks that AI is off and that no provider exists on a fresh profile |

Phase 5 (2026-10-16):

| Date | Command | Result |
| --- | --- | --- |
| 2026-10-16 | `engine: pytest -q --cov` | **121 passed**, 88 % coverage; ruff and mypy clean |
| 2026-10-16 | `desktop: flutter analyze · flutter test` | No issues · **58 passed** (adds 30 contrast checks, palette, shortcut help, autostart commands) |
| 2026-10-16 | `flutter test integration_test/app_e2e_test.dart -d windows` | **1 passed (17 s)** |
| 2026-10-16 | `flutter test integration_test/ui_tour_test.dart -d windows` | **1 passed (4 min 45 s)**: 99 screenshots, 0 layout problems, 0 unlabelled tap targets, 3 contrast findings reviewed as sampling artifacts |

Phase 6 (2026-10-16):

| Date | Command | Result |
| --- | --- | --- |
| 2026-10-16 | `engine: pytest -q --cov` | **127 passed**, 89 % coverage; `sync/` 88–93 %; ruff and mypy clean |
| 2026-10-16 | `sync-server: pytest -q` | **8 passed**; ruff and mypy clean |
| 2026-10-16 | `desktop: flutter analyze · flutter test` | No issues · **58 passed** |
| 2026-10-16 | `flutter test integration_test/app_e2e_test.dart -d windows` | **1 passed (18 s)**, now also checks local mode on a fresh profile |
| 2026-10-16 | `flutter test integration_test/ui_tour_test.dart -d windows` | **1 passed (5 min 18 s)** with a real local sync server; 0 layout problems, 0 unlabelled controls, 4 contrast findings reviewed as sampling artifacts |
| — | `docker build` / `docker compose up` | **Not run**: Docker Desktop does not start on this machine |

Phase 7 (2026-10-16):

| Date | Command | Result |
| --- | --- | --- |
| 2026-10-16 | `engine: pytest -q --cov` | **129 passed**, 89 % coverage (8,798 statements); ruff check, ruff format --check and mypy clean |
| 2026-10-16 | `desktop: flutter analyze · flutter test` | No issues · **58 passed** |
| 2026-10-16 | `engine/tools/third_party_notices.py` | 179 components, 0 flagged |
| 2026-10-16 | `packaging/windows/build.ps1` | Engine self-test in the bundle `SELF-TEST OK engine=1.0.0 schema=0004_sync libs=9`; portable ZIP and installer produced with SHA-256 sums |
| 2026-10-16 | Silent install (`/VERYSILENT /CURRENTUSER /DIR=<temp>`) | Exit 0; app, `engine/`, `licenses/` and Start-menu shortcut present; installed engine self-test OK; installed app started its engine, which reported ready, and the UI connected to it (separate data folder) |
| 2026-10-16 | App killed while running (before the fix) | Engine kept running → bug fixed above |
| 2026-10-16 | Rebuilt installer, app killed twice | Engine exits within 6 s each time; relaunch starts normally (no `already_running`) |
| 2026-10-16 | Silent uninstall | Exit 0; program folder, shortcut and uninstall registry key removed; user data kept |
| — | `.deb` build and install test, sync-server image | **Not run**: Docker does not start on this machine |

Traceability after phase 6 (176 requirements):
- 15 operational end to end.
- 20 operational engine-internal features.
- 114 with the engine tested and the screen delivered.
- 9 implemented without an automated test.
- 9 partial.
- 9 absent: EF-05.04, 05.05, 06.05, 06.06, 06.07, 08.07, 13.10, 17.10, 18.11.

Traceability after phase 5 (176 requirements):
- 14 operational end to end.
- 20 operational engine-internal features.
- 102 with the engine tested and the screen delivered.
- 8 implemented without an automated test.
- 9 partial.
- 23 absent: 14 sync/organisations (phase 6) and 9 others.

Traceability after phase 4 (176 requirements):
- 13 operational end to end.
- 20 operational engine-internal features.
- 97 with the engine tested and the screen delivered but not walked by the E2E test.
- 8 implemented without an automated test.
- 15 partial.
- 23 absent: 14 sync/organisations (phase 6) and 9 others listed in the matrix.

Traceability after phase 3 (`TRACEABILITY.md`, 176 requirements):
- 13 operational end to end.
- 16 operational engine-internal features.
- 82 with the engine tested and the screen delivered but not walked by the E2E test.
- 8 implemented without an automated test.
- 19 partial.
- 38 absent: 15 AI (phase 4), 14 sync/organisations (phase 6), and 9 others listed in the matrix.

Platform: Windows 11 Pro 10.0.26200, Python 3.14.2, SQLCipher 4.12.0 (SQLite 3.51.1), Flutter 3.41.2.

## D. Deliverables

*(Filled in during phases 7–8.)*

## E. Remaining limitations

*(Filled in during phase 9.)*

## F. Final assessment

*(Filled in during phase 9.)*
