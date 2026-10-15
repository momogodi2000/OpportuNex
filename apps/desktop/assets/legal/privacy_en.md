# Opportunex privacy policy

Version 1.0 — 15 October 2026

## 1. Principle: your data stays with you
Opportunex works locally. Your profile, searches, saved opportunities, applications and documents are stored on your computer in an encrypted database (SQLCipher, AES-256). The database key is protected by your password. The publisher has no access to any of this data.

## 2. Data stored locally
- Account: display name, e-mail address, password hash (Argon2id).
- Profile: education, experience, skills, languages, goals and preferences that you enter.
- Activity: searches, results, saved items, application statuses, notes, reminders.
- Attached documents: kept encrypted in a local vault.
- Technical logs: redacted automatically (no e-mails, tokens or keys).

## 3. What leaves your computer
- Fetching sources: Opportunex downloads public pages from the websites of opportunity publishers. These requests contain no data from your profile.
- Artificial intelligence (off by default): if you set up a remote AI provider, Opportunex first asks for your explicit consent. It then sends only an anonymised profile (no name, contact or identifier) and records every transfer in your privacy dashboard. API keys are kept in your operating system's keychain, never in the database.
- Synchronisation (optional): if you turn it on, your data is end-to-end encrypted before it is uploaded; the server cannot read it.

## 4. No telemetry
Opportunex collects no usage statistics and sends no error reports automatically.

## 5. Your rights and controls
From the application you can at any time:
- review the data stored and the transfers made;
- withdraw a consent;
- export all your data;
- selectively erase history, documents or opportunities;
- permanently delete your account.

## 6. Backups
Backups are encrypted with the same key as your database. Keep them somewhere safe: they can only be restored with your password.

## 7. Contact
For questions and requests: https://github.com/momogodi2000/OpportuNex/issues
