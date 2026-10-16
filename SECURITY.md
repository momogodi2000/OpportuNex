# Sécurité / Security policy

## Signaler une vulnérabilité / Reporting a vulnerability
Ne publiez pas de ticket public. Utilisez le **signalement privé de vulnérabilité de GitHub**
(onglet *Security* > *Report a vulnerability*) du dépôt https://github.com/momogodi2000/OpportuNex.
*Do not open a public issue; use GitHub's private vulnerability reporting.*

Indiquez la version, le système, les étapes de reproduction et l'impact. Accusé de réception visé :
7 jours ; correctif ou plan d'action : 30 jours selon la gravité.
*(Une adresse dédiée sera ouverte par l'éditeur : voir `documentation/LEGAL_DECISIONS_NEEDED.md`.)*

## Versions prises en charge / Supported versions
| Version | Correctifs de sécurité |
| --- | --- |
| 1.0.x | oui / yes |

## Ce que protège Opportunex / What Opportunex protects
- Base locale chiffrée (SQLCipher, clé 256 bits enveloppée par Argon2id) et documents chiffrés.
- Moteur accessible uniquement en local (127.0.0.1), avec jeton par lancement ; toute requête d'origine web est refusée.
- Clés d'API d'IA dans le trousseau du système ; consentement avant tout envoi ; profil anonymisé.
- Synchronisation chiffrée de bout en bout (XChaCha20-Poly1305) : le serveur ne lit pas les données.
- Collecte : protection SSRF, respect de robots.txt, contenus externes traités comme non fiables.

## Hors périmètre / Out of scope
- Un ordinateur déjà compromis (logiciel espion, accès administrateur d'un tiers) pendant que le profil est déverrouillé.
- Les sites des éditeurs d'opportunités et les fournisseurs d'IA choisis par l'utilisateur.
- Les binaires ne sont pas encore signés (décision D-12) : vérifiez les empreintes SHA-256 publiées avec chaque version.
