# Journal des modifications / Changelog

Format : [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Versions : [SemVer](https://semver.org/lang/fr/).

## [1.0.0] — non publiée / unreleased

Première version complète, reconstruite sur une base auditée (`documentation/audit/AUDIT_REPORT.md`).

### Ajouté
- **Moteur local** (Python, FastAPI) : base SQLCipher par profil, migrations Alembic, comptes locaux avec
  phrase de récupération, verrouillage automatique, sauvegardes chiffrées et restauration vérifiée.
- **Profil** et assistant de démarrage, **import de CV** (PDF, DOCX, TXT) avec validation élément par élément.
- **Recherche** en langage naturel (FR/EN), collecte polie (robots.txt, délais, cache), catalogue de
  74 sources réelles, dédoublonnage, score de pertinence explicable, fiche d'opportunité en 13 rubriques.
- **Suivi des candidatures** : statuts, tableau, calendrier (.ics), pièces chiffrées, brouillons de documents
  avec contrôle d'intégrité, rappels.
- **Veilles**, notifications natives, zone de notification, lancement à l'ouverture de session (option).
- **Espaces de travail**, comparaison d'opportunités, exports CSV, XLSX, PDF et JSON, portabilité des données.
- **IA facultative** (désactivée par défaut) : fournisseurs multiples, consentement, anonymisation,
  validation par schéma, valeurs vérifiées dans la source.
- **Synchronisation chiffrée de bout en bout** et **organisations**, avec un serveur auto-hébergeable (Docker).
- Interface FR/EN, thèmes clair et sombre (contrastes AA), palette de commandes (Ctrl+K), accessibilité.
- Installateur Windows (Inno Setup, par utilisateur, FR/EN) et version portable ZIP, avec empreintes SHA-256 ;
  moteur empaqueté avec PyInstaller et auto-test (`--self-test`) à l'installation.
- Scripts de paquet Debian (`packaging/linux/`) et intégration continue (`.github/workflows/`) ; le paquet
  `.deb` n'a pas encore été construit ni testé (Docker indisponible sur le poste de construction).
- Licence GNU AGPL v3 complète, `NOTICE`, `AUTHORS`, `TRADEMARKS.md`, `SECURITY.md`, `CONTRIBUTING.md`,
  `CODE_OF_CONDUCT.md` et inventaire des 179 composants tiers avec leurs licences (`THIRD_PARTY_NOTICES.md`).

- Guide utilisateur Word (`documentation/user-guide/`), illustré de captures réelles de la version 1.0.0.

### Corrigé
- Les mots-clés de recherche gardent leurs accents (« données » au lieu de « donnees »).
- Les pays s'affichent par leur nom (« Cameroun ») et non par leur code dans les résultats et la fiche.
- L'option « Inclure les expirées » est alignée sur son libellé et annoncée par les lecteurs d'écran.
- Tableau de bord 50 fois plus rapide sur un profil volumineux (3,6 s → 68 ms à 100 000 opportunités) grâce à un
  nouvel index (migration `0005_perf_indexes`).
- Recherche plein texte locale sous 300 ms même quand la plupart des opportunités correspondent (classement limité
  aux 5 000 plus récentes).
- Le moteur restait actif quand l'application était fermée de force ou plantait, et bloquait le lancement
  suivant (« déjà en cours d'exécution ») : il s'arrête désormais avec l'application (`--parent-pid`).

### Sécurité
- Le moteur n'écoute que sur 127.0.0.1 avec un jeton par lancement ; les requêtes d'origine web sont refusées.
- Clés d'API dans le trousseau du système ; aucune télémétrie.
