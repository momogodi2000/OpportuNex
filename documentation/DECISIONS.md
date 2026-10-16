# Decision register — Opportunex (PIO)

Treat each decision below as settled unless the owner overrides it. Each line can be confirmed or changed in a single pass.

**Order of authority** when sources conflict:
1. Cahier des charges
2. Document technique d'architecture
3. `pio_schema.sql`
4. This register
5. Agent rules in `documentation/Ai-agents-rule/`

| # | Question | Decision | Why |
| --- | --- | --- | --- |
| D-01 | Product name | **Opportunex** is the product name. **PIO** is the technical name (data folder `PIO`). | Already used in the visual identity. A trademark search is still needed (owner action). |
| D-02 | Code licence | **GNU AGPL v3** (spec ADR-014). The copyright holders may also grant a separate commercial licence. | Confirmed by the owner on 2026-10-15. |
| D-03 | Contribution terms | DCO sign-off plus an inbound licence grant that allows relicensing (text in `CONTRIBUTING.md`). No copyright assignment. | A DCO alone would not allow a later dual licence. |
| D-04 | Copyright line | `Copyright © 2026 Momo Godi Yvan / ETS Monthe Network and Opportunex contributors` | **Amended 2026-10-15 by the owner.** |
| D-05 | Organisation | **ETS Monthe Network** develops and maintains the software and publishes it (About screen, installer, `.deb`, README, user guide). **Momo Godi Yvan** is the lead developer and author. Association PROTEGE QV is no longer credited. | **Amended 2026-10-15 by the owner.** Replaces "co-builder and co-funder". |
| D-06 | Brand | The name and logo are reserved (`TRADEMARKS.md`). The code licence grants no brand rights, so forks must rename. | Spec §11.1 |
| D-07 | Licences for docs and connectors | Docs under CC BY-SA 4.0. Declarative connectors under Apache 2.0. | Spec |
| D-08 | Product Owner | Until a PO is named, the spec's acceptance criteria (US-xxx, §13.3 scenario) act as acceptance. | No PO designated yet. |
| D-09 | Release scope | Desktop 1.0 = M01–M16 and M18, Must and Should. M17 is limited to: E2EE, device pairing, outbox/pull sync, organisation roles, leave-with-data, and a minimal Docker sync server. | Covers 100 % of Must requirements. |
| D-10 | Platforms | Windows 10/11 x64 first (installer and portable ZIP). Linux x86_64 second (.deb). macOS: build configured but untested. | Spec §1 |
| D-11 | Windows installer | **Inno Setup**, installed per user by default (no admin rights needed); per-machine install is optional. | Fits low-privilege office PCs |
| D-12 | Code signing | Apply to SignPath Foundation. Until approved, ship unsigned and say so in the user guide (with SmartScreen steps). | Free route for open-source projects |
| D-13 | Engine bundling | **PyInstaller `--onedir`**. Playwright's Chromium is not bundled. | ENF-PERF-01 / -08 |
| D-14 | SQLCipher binding | `sqlcipher3-wheels` (a cp314 win_amd64 wheel was confirmed available on 2026-10-15). | Removes a packaging risk |
| D-15 | AI | **AI off by default.** Offered choices: none / local (Ollama, LM Studio) / cloud with the user's own key. | Privacy and quota limits |
| D-16 | Theme and language | Theme follows the system. Language follows the OS (FR or EN), falling back to French. | Francophone target audience |
| D-17 | Regional settings | Currency **XAF**; dates shown as `dd/MM/yyyy`; times stored in UTC. | Spec §6.8 |
| D-18 | Slogan | FR « Trouvez · Analysez · Réalisez » / EN "Find · Analyse · Achieve", as printed on the brand sheet `opportunex.png`. | Brand sheet takes precedence over the earlier proposal. |
| D-19 | Palette and typeface | Taken from `opportunex.png`: navy ink #0B1F4D, royal blue #1E5BC6 (primary), green #1E9E4A (success/brand accent), amber #F2A900 (deadlines/warnings). Typeface: Inter (SIL OFL). All pairs checked for WCAG AA contrast in light and dark themes. | Palette derived from the actual logo, as D-19 required. |
| D-20 | Source catalogue | At least 60 sources, each with its terms of use reviewed. A source without clear permission ships **disabled** and links to the official site. | Legal risk R04 |
| D-21 | Sync server | Docker Compose plus documentation. The default URL is a placeholder (`https://sync.example.invalid`) until an official instance exists. | Avoids inventing infrastructure |
| D-22 | Telemetry | **None.** Crash reports only with explicit opt-in, as a local export. | Spec §6.3 |
| D-23 | Updates | Signed manifest on GitHub Releases. Update checks stay **disabled** until a release channel and signing keys exist. | Spec §12.4 |
| D-24 | State, navigation, i18n | Riverpod + go_router + ARB. The engine returns stable error codes; the UI translates them. | ADR-013, §6.8 |
| D-25 | Demo data | **No fake data in production.** A test-only local fixture server provides deterministic pages for CI. | Definition of done |
| D-26 | Single instance | One instance per OS user (lock file). | Prevents two engines on the same encrypted database |
| D-27 | Data location | Windows `%APPDATA%\PIO`; Linux `~/.local/share/pio`; macOS `~/Library/Application Support/PIO`. Subfolders: `profiles/<id>/{db,vault}`, `backups/`, `logs/`, `cache/`, `connectors/`. | Spec §12.3 |
| D-28 | Exchange rates | Indicative rates, dated, always labelled "indicatif". | Spec §6.8 |
| D-29 | Sync cryptography | PyNaCl (libsodium): **XChaCha20-Poly1305** for every synchronised record (ENF-SEC-11), **X25519 sealed boxes** to hand keys to a device or to an organisation member. One random 256-bit sync key per online account; one 256-bit key per organisation and key version. The server stores only ciphertext, sizes, scopes and sequence numbers. | Arch §10.1 |
| D-30 | Device pairing | A new device signs in, publishes its X25519 public key and waits. An already paired device shows a pairing code (fingerprint of that public key), which the new device also shows. The user approves on the existing device **only if both codes match**; it then seals the sync key to the new device. A server that swapped the key would show a different code. | Arch §10.1-1 says "code displayed on the existing device"; the comparison makes it resistant to a malicious server. |
| D-31 | Change capture and merge | SQLite triggers (migration `0004_sync`) add a line to `sync_outbox` with a Lamport time for every write on a synchronised table, but only once sync is set up, and never while remote changes are applied. Merging is three-way and **field by field** against the last synchronised version (`sync_shadow`): fields changed on one side win; the same non-text field changed on both sides goes to the higher Lamport time (device id breaks ties); the same **text** field changed on both sides goes to `sync_conflicts` for a manual choice. | Arch §10.1-2/4 |
| D-32 | What is synchronised (1.0) | The profile and its sub-tables, saved opportunities with a minimal opportunity reference (title, publisher, deadline, canonical URL — the opportunity is collected again locally if needed), applications and their history, notes, checklist, events, tags, workspaces and their notes, monitors, matching weights. Vault files, raw pages and collected content are **not** synchronised in 1.0. | Arch §10.2 lists more entities; D-09 limits 1.0 to a minimal sync. |
| D-33 | Organisations | The server knows organisation membership and roles (needed to refuse a write from a viewer) and member e-mails (used for invitations). Shared items (workspaces, saved opportunities with an `organization_id`) are encrypted with the organisation key. When a member leaves or is removed, the server asks an owner or admin device to **rotate** the key; new records use the new version. Leaving keeps personal copies of the shared items the member had (EF-17.12). | Arch §10.3 |
| D-34 | Online account | E-mail verified by a link sent over SMTP. Without SMTP configuration the server writes the link to its log (self-hosting and tests only; stated in the server README). Password reset by e-mail **does not** give access to data: only a paired device holds the keys. Optional TOTP (RFC 6238, 6 digits, 30 s). | Arch §10.3, EF-01.09/10 |
| D-35 | Official instance | No official instance exists yet; the app offers only "self-hosted" with an address the user enters (D-21). | PROTEGE QV is no longer credited (D-05) |

## Conflicts between agent rules and the spec

| # | Conflict | Ruling |
| --- | --- | --- |
| C-01 | `ai-agents-backend.md` requires a `{data, meta, errors}` envelope; the spec (§5.1) requires RFC 9457 Problem Details. | **Spec wins:** errors use `application/problem+json` with a stable `code`; successful responses return the resource directly, and lists use `{items, next_cursor}`. |
| C-02 | The storage/backup master prompt asks for weekly backups kept 6 weeks; arch §13.2 asks for daily backups, keeping 7, plus pre-migration and pre-restore backups. | **Spec wins:** daily, keep 7, plus `pre_migration` / `pre_restore` / `manual`. |
| C-03 | The storage master prompt describes a cloud chain (Cloudinary → UploadThing → R2) and a Super Admin dashboard. | **Not applicable** to a local-first desktop app. Only its integrity, encryption, metadata, retention, restore and audit rules apply. |
| C-04 | `ai-agents-flutter.md` organises code as data/domain/presentation; the spec uses presentation/application/data. | Keep the existing `features/<x>/{data,domain,presentation}` layout, which is compatible. No reorganisation churn. |
| C-05 | The third-party skill packs in `Ai-agents-rule/*-main` were written for web or other ecosystems. | Kept as reference documentation. Not applied to Flutter or Python code. |
