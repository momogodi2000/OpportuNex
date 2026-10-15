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

*(Filled in at the end of each phase.)*

## C. Test results

*(Filled in at the end of each phase.)*

## D. Deliverables

*(Filled in during phases 7–8.)*

## E. Remaining limitations

*(Filled in during phase 9.)*

## F. Final assessment

*(Filled in during phase 9.)*
