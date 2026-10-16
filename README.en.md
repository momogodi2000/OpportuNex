# Opportunex

**Find · Analyse · Achieve** — *[version française](README.md)*

Opportunex is a **free, local-first** desktop application to find, analyse and track opportunities: scholarships,
jobs, internships, grants, tenders, competitions… It is aimed first at students, young graduates, entrepreneurs and
associations in Central Africa, in French and English.

- **Publisher**: ETS Monthe Network · **Lead author**: Momo Godi Yvan
- **Licence**: [GNU AGPL v3](LICENSE) (code) · CC BY-SA 4.0 (documentation) · Apache 2.0 (source connectors)
- **Platforms**: Windows 10/11 (x64) and Linux (Debian/Ubuntu, .deb). macOS: untested.

## What it does

| | |
| --- | --- |
| **Search** | Natural-language queries (FR/EN) turned into editable filters; a catalogue of 74 real sources (20 verified feeds and APIs; portals without a feed are offered as official links); deduplication. |
| **Analysis** | 13-section opportunity sheet showing the source excerpt behind each value; explainable relevance score (0–100); eligibility is never asserted without published criteria. |
| **Tracking** | Applications (11 statuses, Kanban board, calendar with .ics export), notes, encrypted attachments, letter drafts checked against your profile, reminders at D-14/7/3/1. |
| **Monitoring** | Scheduled searches, native notifications, keeps running in the notification area. |
| **Profile** | Onboarding wizard, CV import (PDF, DOCX, TXT) validated item by item. |
| **Exports** | CSV, XLSX, PDF, JSON; full export of your data (portability). |
| **AI (optional)** | Off by default. Your choice of provider (Mistral, Gemini, Anthropic, Groq, OpenRouter, OpenAI-compatible, Ollama, LM Studio); consent before any send; anonymised profile; values checked against the source. |
| **Sync (optional)** | End-to-end encrypted between your devices and within organisations, through a [self-hostable server](sync-server/README.md). |

## Privacy and security

- Data stays on your computer in an **encrypted** database (SQLCipher, 256-bit key protected with Argon2id); 12-word
  recovery phrase; automatic lock; daily encrypted backups (7 kept).
- No telemetry. The local engine only listens on 127.0.0.1, with a fresh token at every start.
- API keys in the operating-system keychain. See [SECURITY.md](SECURITY.md).

## Install

**Windows** — download `Opportunex-Setup-<version>-x64.exe` (per-user install, no administrator rights) or the
**portable** `.zip`. Binaries are **not signed yet**: SmartScreen may warn ("More info" > "Run anyway"). Check the
SHA-256 in `SHA256SUMS.txt`.

**Linux (Debian/Ubuntu)** — `sudo apt install ./opportunex_<version>_amd64.deb`, then start *Opportunex* from the
applications menu. The desktop keychain (GNOME Keyring or KWallet) stores API keys.

Data: Windows `%APPDATA%\PIO`, Linux `~/.local/share/pio`. Uninstalling never deletes your data without asking.

## Development

Requirements: Python 3.12 or newer, Flutter 3.41 (Dart 3.11), Git. On Windows:

```powershell
.\launch-dev.ps1 -Setup     # engine Python environment + Flutter dependencies
.\launch-dev.ps1 -Checks    # ruff, mypy, pytest, flutter analyze, flutter test
.\launch-dev.ps1            # starts the app (the app starts the engine)
```

Packages: `packaging/windows/build.ps1` (Windows) and `packaging/linux/build-deb.sh` in the
`packaging/linux/Dockerfile` image (Linux). Contributing: [CONTRIBUTING.md](CONTRIBUTING.md).

## Licence and trademarks

Opportunex is free software under the GNU AGPL v3. If you offer a modified version to users over a network, you must
provide them with its source code. The Opportunex names and logo are reserved: see [TRADEMARKS.md](TRADEMARKS.md) and
[NOTICE](NOTICE). Third-party components: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

© 2026 Momo Godi Yvan / ETS Monthe Network and contributors.
