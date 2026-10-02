# OpportuNex

**Votre assistant intelligent pour les opportunités publiques et privées**

*Trouvez · Analysez · Réalisez*

---

## À propos

**OpportuNex** (PIO — Plateforme Open Source d'Intelligence des Opportunités) est une application de bureau locale-first pour la découverte, l'analyse et le suivi d'opportunités (bourses, emplois, appels d'offres, subventions) principalement dans le contexte francophone africain.

- **Concepteur** : ING Momo Godi Yvan
- **Financé par** : Association PROTEGE QV (Cameroun)
- **Licence** : GNU AGPL v3
- **Langues** : Français, English

---

## Architecture

```
Flutter Desktop App (Windows/Linux/macOS)
    ↕  HTTP + WebSocket (127.0.0.1, port aléatoire, jeton 256 bits)
Python FastAPI Engine (local)
    ↕
SQLite + SQLCipher (AES-256, FTS5, WAL)
```

## Pré-requis

| Composant | Version |
|-----------|---------|
| Flutter SDK | ≥ 3.24 |
| Dart SDK | ≥ 3.5 |
| Python | ≥ 3.12 |

## Installation développement

### 1. Engine Python

```bash
cd engine
pip install -r requirements.txt
python main.py
```

### 2. Application Flutter

```bash
cd apps/desktop
flutter pub get
flutter run -d windows
```

## Structure du projet

```
opportunex/
├── apps/desktop/          # Flutter desktop app
│   └── lib/
│       ├── core/          # Design system, router, engine supervisor
│       ├── features/      # 18 modules (M01-M18)
│       └── shared/        # Widgets partagés
├── engine/                # Python FastAPI engine
│   ├── api/               # Routes REST + WebSocket
│   ├── domain/            # Entités métier pures
│   ├── services/          # Logique applicative
│   ├── collection/        # Pipeline de collecte
│   ├── extraction/        # Normalisation des données
│   ├── dedup/             # Déduplication 4 niveaux
│   ├── ai/                # Passerelle IA multi-fournisseur
│   ├── matching/          # Moteur de score déterministe
│   ├── tracking/          # Suivi des candidatures
│   ├── documents/         # Génération de documents
│   ├── monitoring/        # Veilles planifiées
│   ├── exports/           # CSV/XLSX/PDF/JSON
│   ├── security/          # Chiffrement, coffre-fort
│   ├── sync/              # Synchronisation E2EE
│   └── persistence/       # SQLAlchemy + Alembic
└── cahier_de_charge/      # Documentation technique
```

## Fonctionnalités (v1.0)

- 🔍 **Recherche** en langage naturel (NLP)
- 🤖 **Analyse IA** multi-fournisseur avec fallback déterministe
- 📊 **Score de correspondance** 7 critères (0-100, expliqué)
- 📁 **Suivi des candidatures** (Kanban + calendrier)
- 🔔 **Veilles planifiées** avec alertes de délai
- 🔒 **Sécurité locale** (SQLCipher, chiffrement OS, zéro cloud obligatoire)
- 💾 **Sauvegarde automatique** hebdomadaire, 6 semaines de rétention
- 🌍 **60+ sources** Afrique + organisations internationales

## Sécurité

- Base de données chiffrée AES-256 (SQLCipher)
- Dérivation de clé Argon2id (64 Mo, 3 itérations)
- Clés API stockées dans le trousseau OS (Windows Credential Manager / macOS Keychain / Linux Secret Service)
- Protection SSRF (refus des plages RFC-1918, métadonnées cloud)
- Injection SQL impossible (ORM uniquement, requêtes paramétrées)
- Contenu collecté sanitisé avant affichage

## License

GNU Affero General Public License v3.0 — voir [LICENSE](LICENSE)
