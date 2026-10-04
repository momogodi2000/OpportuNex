<USER_REQUEST>
# OPPORTUNEX / PIO — MASTER EXECUTION PROMPT v3
## Deliver an operational, tested, installable desktop application — with every open question already decided

**Project:** OpportuNex — Plateforme Open Source d'Intelligence des Opportunités (PIO)
**Directory:** `D:\IT Project\opportunex`  **Agent:** Google Antigravity
**Authority order:** (1) the three specification files, (2) the Decision Register in §1, (3) this prompt. If the specification contradicts a decision, follow the specification and note the conflict in one line of `PROGRESS.md`.

---

## 0. THE PRODUCT IN ONE PAGE

PIO is a **free, open-source, local-first desktop application** that finds, verifies, analyses and recommends *real, publicly published* opportunities (jobs, internships, scholarships, grants, tenders, funding, competitions) for Africa-focused users, mainly francophone. It keeps personal data on the user's machine, always cites the original source, and works with or without AI.

**Architecture (ADR-001…014):**

| Part | Technology | Rules |
| --- | --- | --- |
| Desktop UI | Flutter 3.24+/Dart 3.5+, Riverpod 2, go_router, dio, web_socket_channel, freezed, json_serializable, ARB l10n, flutter_secure_storage, fl_chart, window_manager, tray_manager, local_notifier, url_launcher, flutter_markdown | Per-feature `presentation / application / data`; no business rules in widgets. |
| Local engine | Python 3.12, FastAPI, Uvicorn, Pydantic v2, SQLAlchemy 2 async, Alembic, HTTPX, selectolax/lxml, trafilatura, feedparser, extruct, Protego, pypdf/pdfplumber/python-docx, dateparser, rapidfuzz, APScheduler, argon2-cffi, cryptography, PyNaCl, keyring, structlog, openpyxl, WeasyPrint/ReportLab | Hexagonal packages: `api, domain, services, collection, extraction, dedup, ai, matching, tracking, documents, monitoring, exports, security, sync, persistence`. |
| Storage | SQLite WAL + SQLCipher 4 + FTS5, UUID v7, encrypted document vault | Baseline = `pio_schema.sql` (85 tables, 72 indexes, 12 triggers, 3 views, revision `0001_baseline`). |
| Optional sync server | FastAPI + PostgreSQL 16 + Caddy (Docker Compose), E2EE | Server never sees plaintext. |

There is **no separate web product, no Node/Prisma/Neon stack**. If such code exists in the repo, treat it as the project website or leftovers; do not build product features in it.

**Process model:** the Flutter app starts and supervises the PyInstaller engine. The engine binds `127.0.0.1` on a random free port; a 256-bit session token is passed over stdin; the engine prints its port on stdout; the UI polls `/api/v1/health` (≤10 s), then opens WebSocket `/api/v1/events`. Unexpected exit → up to 3 restarts with exponential backoff → diagnostic screen with redacted log export. Quit → clean shutdown request → engine persists job checkpoints.

**Principles:** truthfulness (no invented dates/amounts/conditions; "Non précisé" / "Non vérifiable"); local first; responsible collection (robots.txt, ≥2 s/domain, no login/CAPTCHA/paywall bypass, no IP rotation or browser spoofing); AI optional; provenance on every field (`explicit | inferred | generated | not_specified | unverifiable`); deterministic explainable score; African context (FR/EN, XAF, intermittent connectivity).

---

## 1. DECISION REGISTER — treat as decided unless the owner overrides

Every question the specification leaves open is resolved below. Implement these; list them in `documentation\DECISIONS.md` (one line each) so the owner can confirm or change any in one pass. Do not stop to ask about them.

| # | Open question | Decision (best option) | Why |
| --- | --- | --- | --- |
| D-01 | Final commercial name | **OpportuNex** (product) · **PIO** (technical/project name, repo, engine package `pio_engine`, data folder `PIO`) | Already used in the identity image; short, memorable. Run a trademark search before public launch (owner action). |
| D-02 | Licence for code | **GNU AGPL v3** (spec ADR-014) + **dual-licence option**: the copyright holder may grant commercial licences to organisations that cannot comply with AGPL | Keeps the product free for everyone, gives the "professional licence" protection the owner wants without closing the code. |
| D-03 | Contribution terms | **DCO sign-off + inbound licence grant that allows relicensing by the project owner** (lightweight CLA text in `CONTRIBUTING`), no copyright assignment | DCO alone does not allow later dual licensing; this does and still leaves authors their copyright (spec §11.2). |
| D-04 | Copyright holder line | `Copyright © 2026 ING Momo Godi Yvan and PIO contributors` in SPDX headers/NOTICE; **funders credited, not named as holders**, until a funding agreement states otherwise | Safest default; spec names the author as maintainer and PROTEGE QV as funder. |
| D-05 | ETS MONTHE NETWORK role | Credited as **co-builder and co-funder** in About screen, installer metadata, README, user guide ("Developed by ING Momo Godi Yvan — funded by Association PROTEGE QV and ETS MONTHE NETWORK") | Reflects the owner's statement; flag in `LEGAL_DECISIONS_NEEDED.md` so the funding agreement matches. |
| D-06 | Logo/brand | Name and logo reserved via `TRADEMARKS.md`; code licence does not grant brand rights; forks must rename | Matches spec §11.1. |
| D-07 | Documentation / connectors licences | Docs **CC BY-SA 4.0**; declarative connectors **Apache 2.0** (spec) | Spec. |
| D-08 | Product Owner | Spec acceptance criteria (US-xxx Given/When/Then, §13.3 scenario) act as the PO's acceptance for this build; a human PO designated by PROTEGE QV signs the final PV | PO not yet designated. |
| D-09 | Release scope of this build | **Desktop 1.0 = M01–M16 and M18 in full for Must + Should; M17 limited to: E2EE crypto layer, device pairing, outbox/pull sync, organisation roles, leave-with-data (EF-17.05, 17.12 Must) and a minimal Docker sync server.** Could items only after the gate. | Meets 100% Must; avoids a half-built collaboration suite. |
| D-10 | Platform priority | **Windows 10/11 x64 first (installer + portable ZIP), Linux x86_64 second (.deb primary, AppImage secondary), macOS = pipeline configured, marked untested.** | Spec §1 priority; only what can be verified is claimed. |
| D-11 | Windows installer | **Inno Setup**, per-user install by default (no admin needed), optional per-machine | Common on low-privilege African office PCs; simple, scriptable. |
| D-12 | Code signing | **SignPath Foundation** application for OSS; until approved, ship unsigned and state it on the download page and in the guide (SmartScreen workaround steps) | Free path for open source (spec R10). |
| D-13 | Engine bundling | **PyInstaller `--onedir` for the engine** (faster start and fewer antivirus false positives than `--onefile`), placed in the app folder; Chromium for Playwright **not** bundled | Meets ENF-PERF-01 (≤4 s start) and ENF-PERF-08 (≤150 MB). |
| D-14 | SQLCipher binding | Use a maintained prebuilt binding (e.g. `sqlcipher3-wheels`); verify wheels for Windows/Linux x64 in sprint-zero spike; if missing, build from source in CI and cache the wheel | Removes the biggest packaging risk early. |
| D-15 | Default AI posture | **AI OFF by default.** Onboarding offers three choices: *No AI*, *Local model (Ollama/LM Studio)*, *Cloud provider with my own key*. Recommended order in UI: local → Gemini/Mistral free tiers → others. | Privacy and quota reality (R02). |
| D-16 | Default theme / language | Theme **System**; language follows the OS (FR or EN), fallback **French** | Francophone target. |
| D-17 | Default currency / region | **XAF**, ISO date format `dd/MM/yyyy` displayed, UTC stored | Spec §6.8. |
| D-18 | Slogan | FR **« Découvrez. Comprenez. Candidatez. »** · EN **"Discover. Understand. Apply."** | Short, mirrors the product's three promises. |
| D-19 | Identity palette and type | Derive the palette from `opportunex.png`; if it lacks one, use deep navy (#0B2545), African-sun amber (#F2A900), teal (#13A89E) accents, neutral greys; typeface **Inter** (UI) with system fallback, bundled under OFL | Professional, accessible contrast, free font. |
| D-20 | Initial source catalog policy | Ship **≥60 sources**, each with a recorded terms-of-use review date; prefer official APIs/RSS; sources lacking clear permission ship **disabled** with the official link only | Legal safety (R04). See §6.3 for candidate list. |
| D-21 | Sync server hosting | Provide Docker Compose + docs; the official PROTEGE QV instance URL is a **configurable default placeholder** (`https://sync.example.invalid`) until the association provides the real one | Do not invent infrastructure. |
| D-22 | Telemetry | **None.** Crash reports only by explicit opt-in, local file export | Spec §6.3. |
| D-23 | Update channel | Signed manifest on GitHub Releases, stable and beta channels, check ≤1×/day, user can disable | Spec §12.4. |
| D-24 | State/nav/i18n | Riverpod + go_router + ARB (Flutter); gettext/Babel catalog for engine strings but **engine returns stable error codes**, UI localises | Spec ADR-013 and §6.8. |
| D-25 | Demo data | **No fake opportunities anywhere in production.** First launch shows guided empty states; "Run my first search" performs a real search. A *test-only* local fixture web server supplies deterministic pages for CI. | DoD: "aucune donnée fictive dans le parcours de production". |
| D-26 | Single instance | Only one app instance per OS user (named mutex / lock file); second launch focuses the first window | Prevents two engines on one encrypted DB. |
| D-27 | Data location | Windows `%APPDATA%\PIO`; Linux `~/.local/share/pio`; macOS `~/Library/Application Support/PIO`; subfolders `db/ vault/ backups/ logs/ cache/ connectors/` | Spec §12.3. |
| D-28 | Currency conversion rates | Indicative rates from a free public source, refreshed weekly, stored with date; conversions always labelled "indicatif" | Spec §6.8. |

---

## 2. AUTHORITATIVE INPUTS — READ IN FULL BEFORE CODING

- `documentation\cahier_de_charge\Cahier des charges — Plateforme Open Source d'Intelligence des Opportunités (PIO).md` — 18 modules, **176 requirements (113 Must / 51 Should / 12 Could)**, ENF-PERF/SEC, US-001…US-048, acceptance criteria, reference E2E scenario §13.3, DoR/DoD.
- `documentation\cahier_de_charge\Document technique d'architecture — PIO.md` — ADRs, API contract, pipeline, dedup, AI gateway, matching, security, tests, packaging.
- `documentation\cahier_de_charge\pio_schema.sql` — verified: loads on SQLite 3.45, integrity ok, foreign_key_check empty.
- `documentation\cahier_de_charge\opportunex.png` — identity reference.
- `documentation\Ai-agents-rule\` — read the real files: `ai-agents.md`, `ai-agents-backend.md`, `ai-agents-frontend.md`, `ai-agents-flutter.md`, `UNIVERSAL MASTER PROMPT redesign.md`, `Master Prompt — Unified Storage, Media Management & Automated Database Backup-Restore Module.md`, and skill folders (`acquire-codebase-knowledge`, `agentic-workflows`, `ai-team-orchestration`, `developer`, `devops-rollout-plan`, `error-messages`, `ui-ux-pro-max-skill-main`, `awesome-*`). They are constraints, not code to copy; skip rules for stacks this product does not use. The storage/backup prompt governs the vault, backups and restore.
- Repo: README, manifests and lockfiles (`pubspec.yaml`, `pyproject.toml`), Alembic history, CI, scripts, `.gitignore`, Git log/branches/working tree.

**Safety:** work on a branch, commit in small steps; never reset, force-push, discard uncommitted work, or drop a populated database.

---

## 3. MISSION AND PRIORITY

Audit fast, then **implement, integrate, test and fix until the application is operational, verified and delivered** (§12). Preserve working code. Replace a component only if demonstrably unusable.

Priority order (never reverse):
1. All 113 Must requirements with real, tested behaviour.
2. Remove every mock/placeholder from production paths.
3. All Should requirements; Could only after the gate.
4. Security, privacy, legal controls.
5. Flutter redesign, FR/EN, light/dark/system, accessibility.
6. Automated tests and quality gates.
7. Launcher and a full local run.
8. Windows installer, Linux package, delivery bundle.
9. Screenshots, recordings, Word guide — only after the app is stable.

Spend time on code and tests, not reports.

---

## 4. AUDIT (SHORT), THEN CODE

Create `documentation\PROGRESS.md` with a **requirement matrix**, one row per EF-xx.xx: `COMPLETE | PARTIAL | MOCK | PLACEHOLDER | BROKEN | POOR | MISSING | DEFERRED`, evidence (file, test), next action. Update only on status change; it is the single source of truth for completion %.

Check specifically: schema drift (models/migrations vs `pio_schema.sql`, STRICT tables, CHECKs, partial unique index for one active adapter per source, triggers, views, seed data for countries, currencies, languages, categories, 16 objectives, settings); API drift vs architecture §5.2 (`/api/v1`, RFC 9457 errors with codes like `AUTH_LOCKED`, `SOURCE_DISALLOWED`, `AI_QUOTA_EXHAUSTED`, `SCHEMA_INVALID`, cursor pagination 50/200, `Idempotency-Key`, 202 + job id, WebSocket events of §5.3); every Flutter screen vs the module list and §3.3 navigation; mock sweep (`mock`, `fake`, `dummy`, `sample`, `lorem`, `TODO`, `FIXME`, `Coming soon`, `Not implemented`, empty `onPressed`, hardcoded stats, static charts, fixtures reachable from production code, `except: pass`).

---

## 5. THE DESKTOP APPLICATION — DETAILED BEHAVIOUR

### 5.1 Application shell and lifecycle
- **Startup screen** with logo and status steps: starting engine → opening database → ready. Cold start to dashboard ≤4 s on the reference PC.
- **Single-instance** lock (D-26); second launch focuses the existing window and passes any `pio://` deep link.
- **Window:** remembers size, position, maximised state, sidebar state per user; minimum size 1100×680; Esc closes panels; Alt+Left/Right navigate history.
- **System tray:** icon with menu (Open, Run monitors now, Pause monitors, Quit). Close button = minimise to tray only if the user enabled "run in background" (default off); otherwise quits cleanly. Tray state shows monitor status.
- **Optional launch at login** (EF-13.09), off by default, starts minimised.
- **Auto-lock:** configurable inactivity timer (default 10 min); lock screen requires password; engine erases data key and closes DB (EF-01.04). Lock also on OS session lock if available.
- **Crash resilience:** engine restart policy (3 tries), job checkpoint resume, `PRAGMA integrity_check` at start with automatic offer to restore the latest backup if corrupted.
- **Notifications:** native, grouped; click opens the relevant opportunity or monitor run; quiet hours setting; deadline reminders D-14/-7/-3/-1.
- **Offline:** banner when no network; browsing, notes, tracking, exports keep working; searches queue or fail with a clear message.
- **Update flow:** check daily, show release notes, download after consent, verify signature, auto-backup, install, migrate on first launch, roll back on failure.

### 5.2 Screens (all required; each must have loading, empty, error, success states, FR and EN, light and dark)
1. **Splash / engine status / diagnostic fallback.**
2. **Account gate:** profile picker (multiple local profiles), login, sign-up (strength meter, compromised-password check), recovery by 12 words, mode badge local/synced.
3. **First-launch wizard:** language and theme → privacy summary → AI posture (D-15) → 7-step profile (skippable) → CV import option → guided tour.
4. **Dashboard:** counters from `v_dashboard_counters`, deadlines 7/14/30 days from `v_upcoming_deadlines`, applications by status, recent searches, daily recommendations, source health from `v_source_health`, quick search box; guided empty state for new users.
5. **Search:** natural-language box, interpretation shown as editable chips (category, keywords/synonyms, country, work mode, audience, amount, dates, experience, languages, organisation type, eligibility), manual filter drawer, saved queries, per-source progress, cancel/resume.
6. **Results:** virtualised list/table with cursor pagination, sort (relevance, recency, deadline, publication, amount, location, type), badges, duplicate-group indicator, multi-select to compare 2–4, bulk save/dismiss/export.
7. **Opportunity sheet:** 13 sections, field provenance badges with source excerpt on hover/side panel, score gauge with per-criterion breakdown, strengths/gaps/to-verify list, official link (shows destination domain before opening), re-check button, Ctrl+S save.
8. **Application assistant:** checklist, document generator (cover letter, scholarship letter, project summary, application email, grant proposal outline, CV tips, interview prep), integrity flags highlighted, version history, DOCX/PDF export.
9. **Saved & Applications:** list, Kanban with drag-and-drop, calendar with iCalendar export, status history, events, notes, tags, attachments, personal deadlines.
10. **Monitors:** create/edit/pause/delete, schedule, min score, run history, honest "runs only while app is open or in tray" notice.
11. **Workspaces:** templates (job, master's scholarship, association funding, startup, IT consulting, tenders, internships), run diff (new/gone/changed), notes.
12. **Sources:** health table, add-by-URL discovery, adapter visual selector editor with live preview, registry browser and signed install, per-source frequency within allowed limit, reliability score, exclusion list.
13. **Organisations:** create, invite, roles (owner/admin/editor/reader), shared spaces, audit log, leave with my data.
14. **Settings:** Account & security · Profile · AI (providers, test, routing, fallback chain, usage) · Privacy dashboard (stored data, disclosures, consents, selective erase) · Notifications · Appearance & language · Network (proxy, bandwidth, data-saver) · Backups (schedule, manual, restore) · Sync · Diagnostic · About (author, funders, licence, version, third-party licences).
15. **Command palette (Ctrl+K), notification centre, global NL search in top bar.**

### 5.3 Keyboard shortcuts (configurable)
Ctrl+K palette/search · Ctrl+S save opportunity · Ctrl+N new search · Ctrl+F filter results · Ctrl+, settings · Ctrl+L lock · F5 re-run search · Esc close panel · Alt+1…9 sidebar sections.

### 5.4 Data and limits
Page size 50 (max 200). Raw docs and HTTP cache purged after 90 days unless attached to a saved item. Vault file names are UUIDs; paths canonicalised and confined. Export CSV is UTF-8 with BOM.

---

## 6. ENGINE IMPLEMENTATION REQUIREMENTS

### 6.1 Accounts and keys (M01)
Argon2id password hash; ≥12 characters; local compromised-password list; progressive lockout after 5 failures; 12-word recovery phrase; multiple isolated profiles; deletion erases local data. Key model: 256-bit data key wrapped by a password-derived key (Argon2id 64 MB, 3 iterations) and by a recovery-phrase-derived key; password change re-wraps only; auth hash salt ≠ KDF salt; lock erases key from memory.

### 6.2 Profile, CV import, NL search (M02–M04)
7-step wizard, completeness score with suggestions, organisation profile. CV import (PDF/DOCX/TXT ≤10 MB) in an isolated process with size/time/memory caps, magic-byte validation, no macros; each extracted item validated by the user. Rule-based query interpreter with FR/EN dictionaries must work without AI; AI interpretation optional. FTS5 with accent folding. Search runs as a background job with per-source progress, cancel, resume.

### 6.3 Collection and sources (M05–M06)
Access order: API → RSS/Atom → JSON-LD (JobPosting, Grant, Event, EducationalOccupationalProgram) → static HTML adapters → headless browser last resort and only if the adapter declares it. Safe HTTP client: http/https only; SSRF guard (reject loopback, private, link-local, ULA, multicast, reserved, cloud metadata; pin connection to validated IP; re-validate every redirect, max 5); 30 s timeout; 10 MB cap; ETag/Last-Modified; retry 429/502/503/504 with backoff and `Retry-After`; 8 concurrent total, 1 per domain, ≥2 s per domain or Crawl-delay; robots.txt cached 24 h; explicit User-Agent pointing to the project page; exclusion list and publisher opt-out. Declarative signed JSON adapters, no executable code, with frozen HTML captures and expected results as regression fixtures. Blocked/unreachable source → marked inaccessible with the official link, never a fake success.

**Candidate source families for the ≥60 catalog (verify terms before enabling; each entry records review date):** ReliefWeb API; World Bank procurement and projects data; African Development Bank procurement notices; EU Funding & Tenders portal; UN agency vacancy feeds with RSS; Campus France and Études en France scholarship pages; DAAD scholarship database; Chevening, Commonwealth, Fulbright, Erasmus+/Mundus pages; Mastercard Foundation Scholars; AUF calls; African Union and CEMAC/ECCAS notices; Cameroon public procurement (ARMP/COLEPS publications), Cameroon ministry and university announcements (MINESUP, MINEFOP, universities); RSS from Opportunity Desk and similar scholarship/grant aggregators (as secondary sources only); incubator and innovation-programme pages; foundation grant pages (Ford, Gates, Open Society, Mozilla, Digital Impact where public); remote-work boards that offer public APIs. Aggregators are secondary; always seek the publisher's original page.

### 6.4 Pipeline (architecture §6)
Select sources → access policy → safe fetch → read → normalise (dateparser, ISO 4217 with dated indicative XAF conversion, ISO 3166, language detection, sanitised text; deadline and eligibility wording kept verbatim) → **dedup before any AI call** (L1 normalised URL; L2 source external_id; L3 SHA-256 of title+org+deadline; L4 simhash 64-bit Hamming ≤3 with title similarity ≥0.90 and compatible organisation) → analyse only new/changed items. Official publisher becomes primary source. Re-check compares content hash; changes versioned; two 404/410 at 24 h → Withdrawn; daily sweep → Expired and updates unsubmitted applications.

### 6.5 AI gateway (M07, M14)
Provider-agnostic adapters (OpenAI-compatible, Gemini, Anthropic, Ollama, LM Studio); per-task routing; fallback chain ending in the deterministic path; quota and 429 handling; cache keyed by content+template+model hash; usage logs; keys only in the OS keychain (DB stores `keychain_ref`); explicit consent before first remote transfer; anonymised profile; versioned prompt templates; collected text in a delimited untrusted block; JSON-only output, no tools; strict Pydantic validation, one retry then deterministic fallback; post-checks that deadline, amount and URL appear in the source or are downgraded to "Non vérifiable"; injection attempts logged in `security_events`. Local providers use a separate client that is the only exception to the SSRF guard and must be user-declared.

### 6.6 Matching (M08)
Deterministic weighted score: skills 30, education 15, experience 15, location 15, languages 10, objectives 10, deadline 5 (editable in `matching_weights`). Unspecified criteria are neutralised and weight redistributed; blocking unmet requirement caps score at 30 with eligibility "unlikely"; "probable" only if every published requirement is confronted with profile data and satisfied; feedback adjusts ±5 points per category/source and never eligibility; recompute on profile fingerprint change. AI writes only the explanation text.

### 6.7 Opportunities, applications, documents (M09, M10, M12)
15 categories + subcategories; badges (Verified, Inferred, AI-generated, Not specified, Expired, Deadline soon, Eligibility uncertain) with icon + label. Generated documents use only validated profile data; `integrity_flags` highlight any claim missing from the profile; the app never claims a submission — "Submitted" requires a user-entered date (domain rule and DB trigger). Application state machine exactly as the spec diagram. Attachments in the encrypted vault.

### 6.8 Dashboard, monitors, workspaces, exports (M11, M13, M15, M16)
Dashboard from DB views only. Monitors bounded by source limits; reminders; run history. Exports: CSV, XLSX with filters, PDF report (cover, summary, table, sheets), versioned JSON, iCalendar, portability archive with re-import.

### 6.9 Settings, privacy, maintenance (M18)
SQLCipher; scheduled encrypted backups (7 rotated, SQLite online-backup API), `pre_migration`/`pre_restore` backups; restore with checksum, version and integrity checks and atomic swap; selective erase; offline privacy policy and terms; proxy and bandwidth; signed updates; redacted log export (14-day rotation, 50 MB cap, DEBUG auto-off after 24 h); background jobs with checkpoints, heartbeat resume, cooperative cancel; weekly ANALYZE and FTS5 optimise.

### 6.10 Sync and organisations (M17, per D-09)
X25519 device keys, pairing code, Lamport clock, encrypted outbox (XChaCha20-Poly1305), pull with cursor, conflict records and user resolution, group key rotation on member departure, audit log, minimal Docker sync server with TLS via Caddy. Anything beyond D-09 is `DEFERRED`, never mocked.

---

## 7. FLUTTER DESIGN AND UX

Central design tokens (colour, type, spacing, radius, elevation, motion) in one place; light, dark, system themes applied to every widget including charts and dialogs; WCAG 2.2 AA contrast; Inter font; shared components (opportunity card, score gauge, virtualised table, filter panel, empty/loading/error states, task banner, semantic badges). Runtime language switch FR/EN via ARB with plural rules; no hardcoded strings; engine error codes mapped to localised messages with a retry/corrective action. Responsive from 1280×720 to 3840×2160, 100–200% scaling, no overflow at narrow widths. Full keyboard navigation, visible focus, Narrator/NVDA semantics, tooltips, hover/focus/press states. Short purposeful motion; skeletons only where useful; confirm destructive actions. A common task takes ≤3 actions; any wait >1 s shows progress; raw exceptions never reach the user.

---

## 8. SECURITY, PRIVACY, LEGAL FILES

Implement and test ENF-SEC-01…13: loopback-only engine with session token and refusal of browser Origin headers; SQLCipher AES-256 with Argon2id-derived key never written to disk; secrets in OS keychain; SSRF guard; sanitised external content; isolated parsing; parameterised SQL only; log redaction (emails, phones, keys, tokens, personal paths); signed updates and connectors (minisign/Sigstore, embedded public keys); no executable community connectors; SAST/SCA/secret scanning in CI; `SECURITY.md` with 72 h response.

**Config policy:** secrets never in `.env` or the database. Provide `.env.example` (fictitious values, non-secret developer settings only) and validate config at startup with actionable errors. `.gitignore` excludes `.env`, databases, keys, vault, backups, build outputs.

**Legal files:** `LICENSE` (AGPL v3), `NOTICE`, `AUTHORS`, `CONTRIBUTING` (DCO + relicensing grant, D-03), `CODE_OF_CONDUCT`, `SECURITY`, `GOVERNANCE`, `SOURCES_POLICY`, `TRADEMARKS.md`, bilingual README, third-party licence report, SPDX headers, CI licence check. `documentation\LEGAL_DECISIONS_NEEDED.md` lists only what needs a human: trademark search, funding-agreement wording for ETS MONTHE NETWORK, counsel review of the dual-licence text, SignPath approval.

Compliance targets: Cameroon law n° 2024/017, GDPR for EU users, Malabo Convention.

---

## 9. TESTING AND THE "OPERATIONAL" DEFINITION

### 9.1 Test layers (mocks only in tests)
- **Python:** Ruff, mypy strict, pytest, pytest-asyncio, respx, hypothesis. Coverage ≥80% engine, ≥95% domain. Cover domain rules, normalisation, each dedup level, scoring, state machine, SSRF guard (private IPs, redirects, DNS rebinding), log redaction, key wrap/unwrap, migrations up and down on a populated DB, every endpoint with RFC 9457 errors, job checkpoint/resume/cancel, adapter regression for 100% of the catalog, AI contract tests (schema failure, quota, injection, unjustified value downgraded, 0 invented values).
- **Flutter:** strict analysis, `dart format`, flutter_test + mocktail, ≥70% coverage on logic, widget tests for forms and every state, **golden tests of key screens in light/dark × FR/EN**, localisation completeness test, navigation and theme/language persistence tests, accessibility guideline tests.
- **Integration/E2E:** real engine, real temporary encrypted DB, local fixture web server. **Reference scenario (spec §13.3) passes with AI configured (recorded provider) and with AI disabled:** account → profile with CV import → "bourses de master en cybersécurité pour étudiants camerounais" → correct interpretation → real sourced de-duplicated results → sheet and explained score → save → checklist and letter draft → reminder → "Submitted" after user action → PDF export.
- **Performance** (reference PC: i3 8th gen, 8 GB, SSD, Windows 10, 5 Mbit/s): cold start ≤4 s; FTS on 100,000 rows ≤300 ms; idle RAM ≤400 MB; no frame blocked >100 ms during collection; Windows installer ≤150 MB. Record measured values and the hardware used.
- **Security:** CodeQL, pip-audit, OSV-Scanner, Gitleaks, schemathesis on the API, fuzzing of PDF/HTML parsers.
- Never delete, skip or weaken legitimate tests. Never report a check that did not run as passed.

### 9.2 Operational acceptance checklist (all must be demonstrated on the installed build, not only in dev)
1. Install on a clean Windows 10/11 VM with no Python, Flutter or dev tools; app starts; engine auto-starts on a random port.
2. Create account, save recovery phrase, lock/unlock, forgot-password via phrase.
3. Complete onboarding; import a real sample CV; validate items.
4. Run a **real** search against live catalog sources; see progress, cancel, resume; results are sourced and de-duplicated; unreachable sources show official links.
5. Open sheet; verify provenance badges, excerpt, score breakdown, official link.
6. Save, checklist, generate letter (with AI and without), integrity flags work, export DOCX/PDF.
7. Application status workflow; Kanban; calendar; iCalendar export; reminder notification fires.
8. Create a monitor; run it; receive native notification; tray behaviour.
9. Add a custom source by URL; use the selector editor on a captured page.
10. Switch FR↔EN and light/dark/system live; settings persist after restart.
11. Backup, corrupt the DB copy, restore successfully; export portability archive and re-import.
12. Kill the engine process; UI recovers; kill during a job; job resumes.
13. Upgrade from previous build keeps data (automatic `pre_migration` backup).
14. Uninstall preserves user data unless the user chooses removal.
15. Repeat key steps on Linux (.deb on Ubuntu LTS VM).

---

## 10. LOCAL LAUNCHER

`launch-dev.ps1` (+ `.bat` wrapper) at repo root; resolves root dynamically; works from any directory. Sequence: check tools (Python 3.12, Flutter, Git) → create/reuse `engine\.venv`, install only when the lockfile hash changed → `flutter pub get` if needed → validate config → engine ruff, mypy, pytest → **stop non-zero on any mandatory failure** → Flutter analyze and test → start engine in dev mode (fixed-port override allowed in dev only) → wait on `/api/v1/health` → launch Flutter desktop against it → print PIDs, URLs, log paths → run until Ctrl+C → stop only processes it started. Separate logs for tests, engine, Flutter. Detect port conflicts, avoid duplicate launches, never reset the DB, never print "tests passed" for a skipped step. `-SkipTests` allowed but prints a visible warning and is never used in the final verification run.

---

## 11. COMPLETION GATE (measured)

Completion % comes from `PROGRESS.md`: Must weight 3, Should 2, Could 1; only `COMPLETE` items count (implemented, integrated, tested, bilingual, themed, accessible); `DEFERRED` counts as incomplete. **Gate: ≥95% weighted AND 113/113 Must**, plus: all suites green with measured coverage; no mock/placeholder in production paths; no open critical/high defect; schema equals baseline with a valid Alembic chain; reference scenario passes with and without AI; FR/EN and all three themes verified on every major screen; the §9.2 checklist passed on the installed Windows build; Linux package built and tested on Linux (or honestly marked "configured, not tested"). Keep working past 95% while capacity remains. For an external blocker (credentials, certificate, hardware, service), finish all independent work and name the blocker.

---

## 12. PACKAGING AND DELIVERY BUNDLE

`desktop-production\` with `windows\`, `linux\`, `macos\`, `engine-bundle\`, `icons\`, `scripts\`, `release\` (artifacts git-ignored). Build scripts: `build-engine.ps1/.sh`, `build-windows.ps1`, `build-linux.sh`, `make-installer.ps1`, `verify-install.ps1` (silent install in a VM, launch, health check, uninstall). CI workflow for three OSs producing SBOM (CycloneDX) and SHA-256 checksums.

**Windows x64:** Flutter release + PyInstaller onedir engine; Inno Setup installer and portable ZIP; per-user install default; Start Menu shortcut; icon and version metadata with author/funder strings; Visual C++ runtime handled by the installer if required; uninstall keeps `%APPDATA%\PIO` unless chosen; upgrade preserves DB.
**Linux x86_64:** `.deb` (primary) and AppImage; `.desktop` file; icon set; Secret Service keyring; data in `~/.local/share/pio`; tested on Ubuntu LTS.
**macOS:** DMG pipeline configured only; marked untested.

**Brand assets** derived from `opportunex.png` (never modify the source): logo (light/dark SVG + PNG), app icon (`.ico` multi-size 16–256, Linux PNG 16–512), favicon for docs, splash, installer banner, slogan (D-18). Integrate them into Flutter, installers, executable metadata and About screen.

**Delivery bundle** (`release\OpportuNex-1.0.0\`): installer `.exe`, portable `.zip`, `.deb`, AppImage if built, `checksums.txt`, `SBOM.json`, `RELEASE_NOTES.md` (FR/EN), `LICENSE`, `THIRD_PARTY_LICENSES`, `VERIFICATION_REPORT.md` (one page: what was tested, on which OS/hardware, with which results, what is unsigned or untested), sync-server `docker-compose.yml` and README, `documentation\User Guide\OpportuNex_User_Guide.docx`.

---

## 13. DOCUMENTATION — ONLY AFTER THE GATE

Order: finish → test → run → capture → write → verify.
1. `documentation\Screenshots\` by module with names like `dashboard-light-fr.png`, real captures from the final build covering FR/EN × light/dark for key screens.
2. `documentation\Screen Recordings\` — real recordings of install, first launch, onboarding, search to save, monitor, language/theme switch, backup/restore. If recording is impossible in the environment, state the limitation; never create placeholder videos.
3. `documentation\User Guide\OpportuNex_User_Guide.docx` (use the docx skill): cover with logo/version; introduction and personas; requirements; installation (Windows, Linux, SmartScreen note if unsigned); first launch and recovery phrase; interface tour; every module (purpose, who can use it, access, controls, fields, filters, results, errors, notes); collection and sources; search, score and provenance badges explained; applications and documents; monitoring and notifications; dashboard; exports and portability; privacy, consent, AI settings; backup/restore; sync and organisations (as implemented); settings, language, theme; troubleshooting; FAQ; reporting problems; licence, credits, funders. Annotated real screenshots. Document only what exists; mark deferred features.

---

## 14. WORKING RULES

1. Work directly in the repo; read before modifying; follow existing architecture.
2. Fix root causes; do not hide exceptions or relabel failures.
3. No fabricated results, credentials, scraped data, screenshots, recordings or test outcomes.
4. Preserve user data and uncommitted work; migrations are non-destructive.
5. Short status messages; update only `PROGRESS.md`, `DECISIONS.md`, `LEGAL_DECISIONS_NEEDED.md` while working.
6. Do not ask about anything in the Decision Register; ask only for an irreversible action or a requirement that is genuinely ambiguous *after* applying it.
7. Always distinguish: implemented / tested / built / installed / verified live.

---

## 15. FINAL HANDOFF (verified facts only)

Weighted completion % with formula; Must x/113, Should x/51, Could x/12; deferred items with reasons; test results and measured coverage (engine, domain, Flutter); reference scenario result with and without AI; §9.2 checklist results per item; performance numbers with hardware; schema/migration status; launcher path and how to run; locations of installer, ZIP, `.deb`, AppImage and their validation status; documentation locations; Decision Register items the owner may wish to change; remaining blockers.

---

## START NOW

Inspect the repo and Git state, read the three specification files and the agent rules, build the requirement matrix and `DECISIONS.md`, then resume coding from the first incomplete **Must** requirement. Do not stop at analysis, plans or reports; stop only when the application is installed, running, tested and delivered, or a named external blocker prevents it. /goal /schedule 
</USER_REQUEST>
<ADDITIONAL_METADATA>
The current local time is: 2026-10-04T11:11:45+01:00.

The user has mentioned some items in the form @[ITEM]. Here is extra information about the items that were mentioned by the user, in the order that they appear:

/goal is a [Slash Command]:
The user has marked this task with /goal, indicating that this task is intended to run for a long time without user input, e.g. overnight. You should be extra thorough and only stop when you are confident the goal has been completely fulfilled. The system will force you to continue execution, prompting you to audit your work until completion. Once complete, include <!-- GOAL_COMPLETE --> in your response. If the user explicitly asked to stop or cancel this goal, include <!-- GOAL_CANCELLED --> in your response to cancel the goal.
/schedule is a [Slash Command]:
Please use the schedule tool to create a schedule as specified by the user
</ADDITIONAL_METADATA>
<USER_SETTINGS_CHANGE>
The user changed setting `Model Selection` from None to Claude Opus 5.5 (Medium). No need to comment on this change if the user doesn't ask about it. If reporting what model you are, please use a human readable name instead of the exact string.
</USER_SETTINGS_CHANGE>