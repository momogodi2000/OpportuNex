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

Platform: Windows 11 Pro 10.0.26200, Python 3.14.2, SQLCipher 4.12.0 (SQLite 3.51.1), Flutter 3.41.2.

## D. Deliverables

*(Filled in during phases 7–8.)*

## E. Remaining limitations

*(Filled in during phase 9.)*

## F. Final assessment

*(Filled in during phase 9.)*
