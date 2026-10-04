# DECISIONS

— treat as decided unless the owner overrides



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
