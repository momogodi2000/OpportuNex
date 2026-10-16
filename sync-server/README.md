# Opportunex — serveur de synchronisation / sync server

Serveur **auto-hébergeable** qui relaie les données chiffrées de bout en bout entre les appareils
d'un utilisateur et au sein des organisations. Il ne voit jamais le contenu : profils, notes,
candidatures et espaces partagés lui arrivent chiffrés (XChaCha20-Poly1305), avec des clés qu'il ne
possède pas.

*A **self-hostable** server that relays end-to-end encrypted data between a user's devices and within
organisations. It never sees content: it only stores ciphertext encrypted with keys it does not hold.*

Licence : GNU AGPL v3 — © 2026 Momo Godi Yvan / ETS Monthe Network.

## Ce que le serveur connaît / What the server knows

| Donnée | Stockée | Lisible par le serveur |
| --- | --- | --- |
| Adresse e-mail, mot de passe (haché Argon2id), secret TOTP | oui | e-mail oui, mot de passe non |
| Clés publiques X25519 des appareils et du compte | oui | oui (publiques) |
| Clés de synchronisation et d'organisation | scellées pour chaque appareil / membre | **non** |
| Enregistrements (profil, candidatures, notes…) | chiffrés | **non** — seulement taille, portée, ordre |
| Organisations : membres, rôles, invitations, journal d'audit | oui | oui (métadonnées, sans contenu) |

La réinitialisation du mot de passe par e-mail rend l'accès au compte, **pas aux données** : seuls les
appareils déjà couplés détiennent les clés.

## Démarrage rapide (Docker) / Quick start

Prérequis : un serveur Linux avec Docker, un nom de domaine pointant vers lui (ports 80 et 443 ouverts).

```bash
cp .env.example .env      # renseigner OPX_SYNC_DOMAIN, OPX_SYNC_PUBLIC_URL, POSTGRES_PASSWORD, SMTP
docker compose up -d
curl https://sync.example.org/v1/health
```

Services lancés : `api` (FastAPI/Uvicorn), `db` (PostgreSQL 16), `caddy` (HTTPS automatique, TLS 1.3),
`backup` (sauvegarde PostgreSQL quotidienne conservée 7 jours dans `./backups`).

Dans Opportunex : **Paramètres > Synchronisation**, saisir `https://sync.example.org`, créer le compte,
confirmer l'e-mail, puis coupler les autres appareils avec le code affiché.

## Variables d'environnement / Environment

| Variable | Défaut | Rôle |
| --- | --- | --- |
| `OPX_SYNC_DATABASE_URL` | `sqlite:///./data/sync.db` | Base (PostgreSQL en production : `postgresql+psycopg://…`) |
| `OPX_SYNC_PUBLIC_URL` | `http://127.0.0.1:8080` | Adresse publique utilisée dans les e-mails |
| `OPX_SYNC_ALLOW_REGISTRATION` | `true` | Ouvrir ou fermer les inscriptions |
| `OPX_SYNC_QUOTA_MB` | `200` | Espace par compte |
| `OPX_SYNC_SESSION_DAYS` | `30` | Durée des sessions |
| `OPX_SYNC_MAX_BATCH`, `OPX_SYNC_MAX_RECORD_KB` | `500`, `512` | Limites d'envoi |
| `OPX_SYNC_SMTP_*` | — | Envoi des e-mails ; sans SMTP, les messages vont dans le journal (instance personnelle uniquement) |

## Exploitation / Operations

- **Santé** : `GET /v1/health`. **Métriques** Prometheus : `GET /metrics` (bloqué par Caddy côté Internet).
- **Journaux** : sans contenu utilisateur (le serveur n'en voit pas).
- **Sauvegarde** : `./backups/sync-AAAA-MM-JJ.dump`. Restauration :
  `docker compose exec -T db pg_restore -U opportunex -d opportunex_sync --clean < backups/sync-2026-10-16.dump`
- **Mise à jour** : `git pull && docker compose build api && docker compose up -d`.
  Le schéma est créé au démarrage s'il n'existe pas.

## Développement / Development

```bash
python -m venv .venv && .venv/bin/pip install -r requirements.txt pytest httpx
.venv/bin/pytest -q
uvicorn opx_sync.app:get_app --factory --port 8080
```

## API (résumé)

`POST /v1/accounts` · `POST /v1/accounts/verify` · `POST /v1/sessions` (connexion + appareil) ·
`GET|PUT /v1/account…` (identité, TOTP, suppression) · `GET /v1/devices` · `POST /v1/devices/{id}/approve|revoke` ·
`POST /v1/sync/push` · `GET /v1/sync/pull` · `POST|GET /v1/orgs` · `…/members` · `…/invites` · `…/keys` · `…/audit`.
Erreurs au format RFC 9457 avec un `code` stable.

## Limites connues / Known limits

- Aucune instance officielle n'existe à ce jour (décision D-35) : chaque organisation déploie la sienne.
- Pas de veille déportée (EF-13.10) ni de lien public de partage (EF-17.10) dans cette version.
- Le limiteur de tentatives est en mémoire : avec plusieurs réplicas, placer un limiteur devant (Caddy, pare-feu).
