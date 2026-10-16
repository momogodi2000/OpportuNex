# Opportunex

**Trouvez · Analysez · Réalisez** — *[English version](README.en.md)*

Opportunex est une application de bureau **libre et locale d'abord** pour trouver, analyser et suivre des
opportunités : bourses, emplois, stages, subventions, appels d'offres, concours… Elle s'adresse en priorité aux
étudiants, jeunes diplômés, entrepreneurs et associations d'Afrique centrale, en français et en anglais.

- **Éditeur** : ETS Monthe Network · **Auteur principal** : Momo Godi Yvan
- **Licence** : [GNU AGPL v3](LICENSE) (code) · CC BY-SA 4.0 (documentation) · Apache 2.0 (connecteurs de sources)
- **Plateformes** : Windows 10/11 (x64) et Linux (Debian/Ubuntu, .deb). macOS : non testé.

## Ce que fait Opportunex

| | |
| --- | --- |
| **Recherche** | Requête en langage naturel (FR/EN) transformée en filtres modifiables ; recherche dans un catalogue de 74 sources réelles (20 flux et API vérifiés, les portails sans flux proposés en lien officiel) ; dédoublonnage. |
| **Analyse** | Fiche en 13 rubriques avec l'extrait source de chaque information ; score de pertinence explicable (0–100) ; l'éligibilité n'est jamais affirmée sans critères publiés. |
| **Suivi** | Candidatures (11 statuts, tableau Kanban, calendrier .ics), notes, pièces jointes chiffrées, brouillons de lettres contrôlés contre votre profil, rappels J-14/7/3/1. |
| **Veille** | Recherches planifiées, notifications natives, fonctionnement réduit dans la zone de notification. |
| **Profil** | Assistant de démarrage, import de CV (PDF, DOCX, TXT) validé élément par élément. |
| **Exports** | CSV, XLSX, PDF, JSON ; export complet de vos données (portabilité). |
| **IA (facultative)** | Désactivée par défaut. Fournisseurs au choix (Mistral, Gemini, Anthropic, Groq, OpenRouter, compatible OpenAI, Ollama, LM Studio), consentement avant tout envoi, profil anonymisé, valeurs vérifiées dans la source. |
| **Synchronisation (facultative)** | Chiffrée de bout en bout entre vos appareils et au sein d'organisations, via un [serveur auto-hébergeable](sync-server/README.md). |

## Vie privée et sécurité

- Données sur votre ordinateur, dans une base **chiffrée** (SQLCipher, clé 256 bits protégée par Argon2id) ;
  phrase de récupération de 12 mots ; verrouillage automatique ; sauvegardes chiffrées quotidiennes (7 conservées).
- Aucune télémétrie. Le moteur local n'écoute que sur 127.0.0.1 avec un jeton propre à chaque lancement.
- Clés d'API dans le trousseau du système. Voir [SECURITY.md](SECURITY.md).

## Installation

**Windows** — téléchargez `Opportunex-Setup-<version>-x64.exe` (installation pour l'utilisateur courant, sans droits
administrateur) ou la version **portable** `.zip` à décompresser. Les binaires ne sont **pas encore signés** : Windows
SmartScreen peut afficher un avertissement (« Informations complémentaires » > « Exécuter quand même »). Vérifiez
l'empreinte SHA-256 publiée dans `SHA256SUMS.txt`.

**Linux (Debian/Ubuntu)** — `sudo apt install ./opportunex_<version>_amd64.deb`, puis lancez *Opportunex* depuis le
menu des applications. Le trousseau du bureau (GNOME Keyring ou KWallet) est utilisé pour les clés d'API.

Données : Windows `%APPDATA%\PIO`, Linux `~/.local/share/pio`. Désinstaller ne supprime pas vos données sans votre accord.

Le guide utilisateur est dans `documentation/user-guide/`.

## Développement

Prérequis : Python 3.12 ou plus récent, Flutter 3.41 (Dart 3.11), Git. Sous Windows :

```powershell
.\launch-dev.ps1 -Setup     # environnement Python du moteur + dépendances Flutter
.\launch-dev.ps1 -Checks    # ruff, mypy, pytest, flutter analyze, flutter test
.\launch-dev.ps1            # lance l'application (le moteur est démarré par l'application)
```

| Dossier | Contenu |
| --- | --- |
| `apps/desktop/` | Application Flutter (Riverpod, go_router, ARB FR/EN) |
| `engine/` | Moteur local Python (FastAPI, SQLAlchemy, SQLCipher, Alembic) |
| `sync-server/` | Serveur de synchronisation auto-hébergeable (FastAPI, PostgreSQL, Docker) |
| `packaging/` | Moteur PyInstaller, installateur Windows (Inno Setup), paquet Debian, icônes, licences tierces |
| `documentation/` | Cahier des charges, architecture, décisions (`DECISIONS.md`), audit et traçabilité |

Paquets : `packaging/windows/build.ps1` (Windows) et `packaging/linux/build-deb.sh` dans l'image
`packaging/linux/Dockerfile` (Linux). Contribuer : [CONTRIBUTING.md](CONTRIBUTING.md).

## Dépannage

| Symptôme | Que faire |
| --- | --- |
| « Le moteur n'a pas démarré » | L'écran de diagnostic affiche la cause et la fin du journal ; « Réessayer ». Journaux : `%APPDATA%\PIO\logs`. |
| « Une autre instance est déjà ouverte » | Une seule instance par utilisateur : fermez l'autre (icône de la zone de notification > Quitter). |
| Mot de passe oublié | Écran de connexion > « Mot de passe oublié » avec la phrase de récupération de 12 mots. |
| Aucune source ne répond | Vérifiez la connexion et le proxy (Paramètres > Préférences > Réseau) ; les portails sans flux s'ouvrent en lien officiel. |

## Licence et marques

Opportunex est un logiciel libre sous GNU AGPL v3 : vous pouvez l'utiliser, l'étudier, le modifier et le
redistribuer. Si vous proposez une version modifiée à des utilisateurs à travers un réseau, vous devez leur en fournir
le code source. Les noms et le logo Opportunex sont réservés : voir [TRADEMARKS.md](TRADEMARKS.md) et [NOTICE](NOTICE).
Composants tiers : [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

© 2026 Momo Godi Yvan / ETS Monthe Network et contributeurs.
