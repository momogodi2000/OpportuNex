# Matrice de traçabilité des exigences

Statuts : **OPÉRATIONNEL** (vérifié de bout en bout par test) · **PARTIEL** · **SIMULÉ** · **ABSENT** · **NON VÉRIFIABLE** (dépend d'une ressource externe).

Colonne « Déclaré » = ancien `PROGRESS.md` (HEAD a985077). Colonne « Mesuré initial » = audit du 2026-10-15. Colonnes « Implémentation », « Tests » et « Statut actuel » mises à jour à chaque phase.

| Exigence | Module | Prio | Libellé | Déclaré | Mesuré initial | Implémentation | Tests | Statut actuel |
|---|---|---|---|---|---|---|---|---|
| EF-01.01 | M01 Comptes | M | Créer un compte local avec nom, courriel, mot de passe et confirmation | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-01.02 | M01 Comptes | M | Exiger un mot de passe d'au moins 12 caractères avec indicateur de robustesse et contrôle contre les mots de passe compromis connus (liste locale) | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-01.03 | M01 Comptes | M | Hacher les mots de passe avec Argon2id | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-01.04 | M01 Comptes | M | Se connecter, se déconnecter, verrouiller automatiquement après une inactivité paramétrable | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-01.05 | M01 Comptes | M | Limiter les tentatives (5 échecs = temporisation progressive) | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-01.06 | M01 Comptes | M | Générer une phrase de récupération de 12 mots à la création pour récupérer un compte local hors ligne | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-01.07 | M01 Comptes | M | Changer le mot de passe et régénérer la clé de chiffrement locale | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-01.08 | M01 Comptes | S | Gérer plusieurs profils utilisateurs isolés sur un même poste | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-01.09 | M01 Comptes | S | Créer ou lier un compte en ligne sur le service de synchronisation (courriel vérifié, réinitialisation par courriel) | MISSING | ABSENT | | | ABSENT |
| EF-01.10 | M01 Comptes | S | Activer une double authentification TOTP pour le compte en ligne | MISSING | ABSENT | | | ABSENT |
| EF-01.11 | M01 Comptes | M | Supprimer définitivement son compte et toutes ses données locales et distantes | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-01.12 | M01 Comptes | M | Afficher clairement le mode actif : local seul ou synchronisé | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-02.01 | M02 Profil | M | Assistant en 7 étapes : informations générales, formation, expérience, compétences, objectifs, préférences projet/financement, récapitulatif | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-02.02 | M02 Profil | M | Informations générales : nom, pays, ville, langue, statut, localisations souhaitées, mobilité, mode télétravail/hybride/présentiel | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-02.03 | M02 Profil | M | Formation : niveau, domaine, établissement, année d'obtention, certifications, distinctions | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-02.04 | M02 Profil | M | Expériences professionnelles multiples avec dates, poste, employeur, missions | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-02.05 | M02 Profil | M | Compétences techniques et transversales avec niveau, langues avec niveau CECRL | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-02.06 | M02 Profil | S | Liens professionnels : portfolio, LinkedIn, GitHub, site web | PARTIAL | NON OPÉRATIONNEL | | | NON OPÉRATIONNEL |
| EF-02.07 | M02 Profil | M | Sélection multiple des 16 objectifs proposés plus objectifs libres | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-02.08 | M02 Profil | S | Préférences projet : catégorie, description, stade, besoin et fourchette de financement, pays, bénéficiaires, statut juridique, calendrier | PARTIAL | NON OPÉRATIONNEL | | | NON OPÉRATIONNEL |
| EF-02.09 | M02 Profil | M | Passer toute question facultative et y revenir plus tard | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-02.10 | M02 Profil | M | Indicateur de complétude et suggestions des champs qui amélioreraient la pertinence | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-02.11 | M02 Profil | S | Résumé de profil généré à partir des seules données saisies, modifiable et validé par l'utilisateur | PARTIAL | NON OPÉRATIONNEL | | | NON OPÉRATIONNEL |
| EF-02.12 | M02 Profil | S | Profil d'organisation distinct pour associations et PME (secteur, statut, pays d'activité, budget annuel indicatif) | PARTIAL | NON OPÉRATIONNEL | | | NON OPÉRATIONNEL |
| EF-03.01 | M03 Import CV | S | Importer un CV au format PDF, DOCX ou TXT (taille maximale 10 Mo) | MOCK | SIMULÉ | | | SIMULÉ |
| EF-03.02 | M03 Import CV | M | Analyser le fichier dans un processus isolé, sans exécution de macros ni de contenu actif | MOCK | SIMULÉ | | | SIMULÉ |
| EF-03.03 | M03 Import CV | S | Extraire formations, expériences, compétences et langues, en local ou via IA selon le choix de l'utilisateur | MOCK | SIMULÉ | | | SIMULÉ |
| EF-03.04 | M03 Import CV | M | Présenter chaque élément extrait pour validation individuelle avant enregistrement | MOCK | SIMULÉ | | | SIMULÉ |
| EF-03.05 | M03 Import CV | M | Conserver ou supprimer le fichier source selon la préférence de l'utilisateur | MOCK | SIMULÉ | | | SIMULÉ |
| EF-04.01 | M04 Recherche | M | Saisir une requête libre en français ou en anglais | MISSING | ABSENT | | | ABSENT |
| EF-04.02 | M04 Recherche | M | Extraire les paramètres : catégorie, mots-clés, synonymes, pays, mode de travail, public, montant, dates, expérience, langues, type d'organisation, éligibilité | MISSING | ABSENT | | | ABSENT |
| EF-04.03 | M04 Recherche | M | Afficher l'interprétation sous forme de filtres éditables avant lancement | MISSING | ABSENT | | | ABSENT |
| EF-04.04 | M04 Recherche | M | Interprétation par règles et dictionnaires lorsque aucune IA n'est configurée | MISSING | ABSENT | | | ABSENT |
| EF-04.05 | M04 Recherche | M | Filtres manuels : date, pays, catégorie, date limite, éligibilité, source, niveau d'expérience, fourchette de montant | MISSING | ABSENT | | | ABSENT |
| EF-04.06 | M04 Recherche | M | Exécuter la recherche en tâche de fond avec progression par source, annulation et reprise | PARTIAL | NON OPÉRATIONNEL | | | NON OPÉRATIONNEL |
| EF-04.07 | M04 Recherche | C | Suggestions de requêtes basées sur le profil et l'historique | MISSING | ABSENT | | | ABSENT |
| EF-04.08 | M04 Recherche | M | Recherche plein texte locale sur les opportunités déjà collectées (FTS5) | MISSING | ABSENT | | | ABSENT |
| EF-05.01 | M05 Collecte | M | Interroger les API de recherche autorisées et les API officielles des sources | MISSING | ABSENT | | | ABSENT |
| EF-05.02 | M05 Collecte | M | Lire les flux RSS et Atom et les données structurées schema.org (JobPosting, Grant, Event) | PARTIAL | NON OPÉRATIONNEL | | | NON OPÉRATIONNEL |
| EF-05.03 | M05 Collecte | M | Extraire le contenu des pages HTML statiques via adaptateurs déclaratifs (sélecteurs) | MISSING | ABSENT | | | ABSENT |
| EF-05.04 | M05 Collecte | S | Utiliser un navigateur sans tête uniquement pour les sources marquées comme le nécessitant et l'autorisant | MISSING | ABSENT | | | ABSENT |
| EF-05.05 | M05 Collecte | S | Extraire et convertir les annonces publiées en PDF | MISSING | ABSENT | | | ABSENT |
| EF-05.06 | M05 Collecte | M | Vérifier robots.txt et les conditions déclarées avant tout accès, et respecter les délais entre requêtes | MISSING | ABSENT | | | ABSENT |
| EF-05.07 | M05 Collecte | M | S'identifier par un User-Agent explicite renvoyant vers la page du projet | MISSING | ABSENT | | | ABSENT |
| EF-05.08 | M05 Collecte | M | Gérer pagination, champs manquants, pages malformées, délais d'expiration, nouvelles tentatives bornées avec recul exponentiel | MISSING | ABSENT | | | ABSENT |
| EF-05.09 | M05 Collecte | M | Normaliser dates, devises (dont XAF), pays (ISO 3166) et langues (ISO 639) | MISSING | ABSENT | | | ABSENT |
| EF-05.10 | M05 Collecte | M | Conserver mot pour mot les clauses critiques (éligibilité, date limite) avec horodatage de collecte | MISSING | ABSENT | | | ABSENT |
| EF-05.11 | M05 Collecte | M | Journaliser chaque exécution par source : statut, durée, nombre d'éléments, erreurs | MISSING | ABSENT | | | ABSENT |
| EF-05.12 | M05 Collecte | M | Signaler les sources inaccessibles et proposer le lien officiel de recherche au lieu d'un faux succès | MISSING | ABSENT | | | ABSENT |
| EF-05.13 | M05 Collecte | S | Mettre en cache les réponses HTTP selon les en-têtes de validation (ETag, Last-Modified) | MISSING | ABSENT | | | ABSENT |
| EF-06.01 | M06 Sources | M | Lister les sources : catégorie, pays, type d'accès, statut, dernier succès, dernière erreur | MISSING | ABSENT | | | ABSENT |
| EF-06.02 | M06 Sources | M | Ajouter une URL publique ; l'application détecte flux, sitemap et données structurées | MISSING | ABSENT | | | ABSENT |
| EF-06.03 | M06 Sources | M | Activer, désactiver, catégoriser, supprimer une source personnalisée | MISSING | ABSENT | | | ABSENT |
| EF-06.04 | M06 Sources | M | Régler la fréquence d'analyse dans la limite autorisée par la source | MISSING | ABSENT | | | ABSENT |
| EF-06.05 | M06 Sources | S | Créer un adaptateur via un éditeur visuel de sélecteurs avec aperçu en direct | MISSING | ABSENT | | | ABSENT |
| EF-06.06 | M06 Sources | S | Installer et mettre à jour des connecteurs depuis le registre communautaire signé | MISSING | ABSENT | | | ABSENT |
| EF-06.07 | M06 Sources | C | Proposer un connecteur au registre ; validation par un mainteneur | MISSING | ABSENT | | | ABSENT |
| EF-06.08 | M06 Sources | S | Calculer un score de fiabilité par source (taux de succès, fraîcheur, origine officielle) | MISSING | ABSENT | | | ABSENT |
| EF-06.09 | M06 Sources | M | Catalogue initial d'au moins 60 sources (Cameroun, Afrique centrale, organisations internationales, bourses, marchés publics) | MISSING | ABSENT | | | ABSENT |
| EF-07.01 | M07 Analyse IA | M | Extraire en sortie structurée validée par schéma : titre, catégorie, organisme, dates, lieu, public, formation, expérience, compétences, éligibilité, pièces, procédure, canal, montant, avantages, restrictions, contact public | MISSING | ABSENT | | | ABSENT |
| EF-07.02 | M07 Analyse IA | M | Étiqueter chaque champ selon sa provenance : explicite, déduit, généré | MISSING | ABSENT | | | ABSENT |
| EF-07.03 | M07 Analyse IA | S | Rattacher chaque champ extrait à l'extrait source qui le justifie | MISSING | ABSENT | | | ABSENT |
| EF-07.04 | M07 Analyse IA | M | Afficher « Non précisé » ou « Non vérifiable » plutôt qu'une valeur inventée | MISSING | ABSENT | | | ABSENT |
| EF-07.05 | M07 Analyse IA | M | Résumer les annonces longues en 5 lignes maximum | MISSING | ABSENT | | | ABSENT |
| EF-07.06 | M07 Analyse IA | M | Traiter le contenu collecté comme non fiable : isoler les instructions qu'il contient du prompt système | MISSING | ABSENT | | | ABSENT |
| EF-07.07 | M07 Analyse IA | M | Rejeter et rejouer une fois toute réponse non conforme au schéma, sinon basculer sur l'extraction déterministe | MISSING | ABSENT | | | ABSENT |
| EF-07.08 | M07 Analyse IA | C | Traduire une annonce dans la langue de l'utilisateur sur demande | MISSING | ABSENT | | | ABSENT |
| EF-08.01 | M08 Correspondance | M | Calculer un score de pertinence de 0 à 100 à partir de critères pondérés : compétences, formation, expérience, localisation, langues, objectifs, date limite | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-08.02 | M08 Correspondance | M | Afficher la décomposition du score par critère | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-08.03 | M08 Correspondance | M | Lister les atouts, les qualifications manquantes et les points d'éligibilité à vérifier | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-08.04 | M08 Correspondance | M | Ne jamais affirmer l'éligibilité sans critères publiés et données de profil concordants | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-08.05 | M08 Correspondance | S | Ajuster les pondérations dans les paramètres | MISSING | ABSENT | | | ABSENT |
| EF-08.06 | M08 Correspondance | S | Recueillir le retour (pertinent, non pertinent, écarter) et adapter les recommandations localement | MISSING | ABSENT | | | ABSENT |
| EF-08.07 | M08 Correspondance | C | Correspondance sémantique par embeddings calculés localement lorsque possible | MISSING | ABSENT | | | ABSENT |
| EF-09.01 | M09 Classement | M | Classer selon 15 catégories et leurs sous-catégories | MISSING | ABSENT | | | ABSENT |
| EF-09.02 | M09 Classement | M | Dédoublonner par URL normalisée, identifiant source, empreinte titre + organisme + date limite, puis similarité approximative | MISSING | ABSENT | | | ABSENT |
| EF-09.03 | M09 Classement | M | Regrouper les doublons multi-sites et privilégier l'annonce de l'éditeur d'origine | MISSING | ABSENT | | | ABSENT |
| EF-09.04 | M09 Classement | M | Trier par pertinence, récence, date limite, publication, montant, lieu, type | MISSING | ABSENT | | | ABSENT |
| EF-09.05 | M09 Classement | M | Pagination incrémentale des résultats | MISSING | ABSENT | | | ABSENT |
| EF-09.06 | M09 Classement | M | Signaler visuellement : vérifié, généré par IA, expiré, échéance proche, éligibilité incertaine | MISSING | ABSENT | | | ABSENT |
| EF-09.07 | M09 Classement | M | Marquer automatiquement comme expirée toute opportunité dont la date limite est dépassée | MISSING | ABSENT | | | ABSENT |
| EF-10.01 | M10 Fiche | M | Fiche en 13 rubriques : aperçu, éditeur et source, éligibilité, qualifications, pièces, date limite, avantages financiers, procédure, lien officiel, statut de vérification, explication de pertinence, écarts d'éligibilité, liste de préparation | MISSING | ABSENT | | | ABSENT |
| EF-10.02 | M10 Fiche | S | Afficher l'extrait original à côté de chaque donnée structurée | MISSING | ABSENT | | | ABSENT |
| EF-10.03 | M10 Fiche | M | Ouvrir le lien officiel dans le navigateur par défaut | MISSING | ABSENT | | | ABSENT |
| EF-10.04 | M10 Fiche | S | Revérifier une opportunité à la demande (nouvelle collecte, détection de modification ou de retrait) | MISSING | ABSENT | | | ABSENT |
| EF-10.05 | M10 Fiche | M | Générer une liste de pièces cochable à partir des exigences publiées | MISSING | ABSENT | | | ABSENT |
| EF-10.06 | M10 Fiche | S | Rédiger, à partir du seul profil validé, une lettre de motivation, une lettre de bourse, un résumé de projet, un courriel de candidature | MISSING | ABSENT | | | ABSENT |
| EF-10.07 | M10 Fiche | S | Structurer une proposition de subvention selon le canevas du bailleur lorsqu'il est publié | MISSING | ABSENT | | | ABSENT |
| EF-10.08 | M10 Fiche | S | Suggérer des améliorations de CV ciblées sur l'opportunité | MISSING | ABSENT | | | ABSENT |
| EF-10.09 | M10 Fiche | C | Préparer des questions d'entretien probables et des pistes de réponse | MISSING | ABSENT | | | ABSENT |
| EF-10.10 | M10 Fiche | M | Interdire l'ajout de diplômes, expériences ou distinctions absents du profil ; signaler toute tentative | MISSING | ABSENT | | | ABSENT |
| EF-10.11 | M10 Fiche | S | Éditer, versionner et exporter les documents générés (DOCX, PDF) | MISSING | ABSENT | | | ABSENT |
| EF-10.12 | M10 Fiche | M | Rappeler que la soumission se fait sur le canal officiel ; ne jamais déclarer une candidature soumise sans action de l'utilisateur | MISSING | ABSENT | | | ABSENT |
| EF-11.01 | M11 Tableau de bord | M | Indicateurs issus des données réelles : opportunités découvertes, nouvelles depuis la dernière recherche, pertinentes, sauvegardées | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-11.02 | M11 Tableau de bord | M | Échéances à venir sur 7, 14 et 30 jours | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-11.03 | M11 Tableau de bord | M | Candidatures par statut et actions de relance à mener | MISSING | ABSENT | | | ABSENT |
| EF-11.04 | M11 Tableau de bord | M | Activité de recherche récente | MISSING | ABSENT | | | ABSENT |
| EF-11.05 | M11 Tableau de bord | S | Recommandations personnalisées du jour | MISSING | ABSENT | | | ABSENT |
| EF-11.06 | M11 Tableau de bord | S | État de la veille et santé des sources | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-11.07 | M11 Tableau de bord | M | États vides guidés pour un nouvel utilisateur | MISSING | ABSENT | | | ABSENT |
| EF-11.08 | M11 Tableau de bord | C | Statistiques personnelles : taux de réponse, délais moyens, catégories les plus fructueuses | MISSING | ABSENT | | | ABSENT |
| EF-12.01 | M12 Suivi | M | Sauvegarder et retirer une opportunité | PARTIAL | NON OPÉRATIONNEL | | | NON OPÉRATIONNEL |
| EF-12.02 | M12 Suivi | M | Ajouter des notes, une priorité (haute, moyenne, basse) et des étiquettes | PARTIAL | NON OPÉRATIONNEL | | | NON OPÉRATIONNEL |
| EF-12.03 | M12 Suivi | M | Marquer comme intéressante ou inéligible avec motif | MISSING | ABSENT | | | ABSENT |
| EF-12.04 | M12 Suivi | M | Suivre le statut selon le cycle : découverte, à examiner, en préparation, prête, soumise, entretien ou évaluation, acceptée, refusée, retirée, expirée, archivée | MISSING | ABSENT | | | ABSENT |
| EF-12.05 | M12 Suivi | M | Historiser chaque changement de statut avec date | MISSING | ABSENT | | | ABSENT |
| EF-12.06 | M12 Suivi | M | Enregistrer date de soumission, entretiens, relances et contacts | MISSING | ABSENT | | | ABSENT |
| EF-12.07 | M12 Suivi | M | Joindre des documents stockés localement et chiffrés | MISSING | ABSENT | | | ABSENT |
| EF-12.08 | M12 Suivi | S | Définir des échéances personnelles distinctes de la date limite officielle | MISSING | ABSENT | | | ABSENT |
| EF-12.09 | M12 Suivi | S | Vue tableau Kanban par statut avec glisser-déposer | MISSING | ABSENT | | | ABSENT |
| EF-12.10 | M12 Suivi | S | Vue calendrier des échéances et entretiens, export iCalendar | MISSING | ABSENT | | | ABSENT |
| EF-12.11 | M12 Suivi | M | Rechercher et filtrer dans ses dossiers personnels | MISSING | ABSENT | | | ABSENT |
| EF-12.12 | M12 Suivi | C | Archiver automatiquement les dossiers clos après un délai paramétrable | MISSING | ABSENT | | | ABSENT |
| EF-13.01 | M13 Veille | M | Créer un profil de veille : catégories, mots-clés, sources, zone géographique, score minimal | MISSING | ABSENT | | | ABSENT |
| EF-13.02 | M13 Veille | M | Planifier une fréquence (quotidienne, hebdomadaire, personnalisée) bornée par les limites des sources | MISSING | ABSENT | | | ABSENT |
| EF-13.03 | M13 Veille | M | Activer, suspendre, supprimer une veille | MISSING | ABSENT | | | ABSENT |
| EF-13.04 | M13 Veille | M | Notifier les nouvelles opportunités et les modifications d'annonces suivies | MISSING | ABSENT | | | ABSENT |
| EF-13.05 | M13 Veille | M | Rappels d'échéance à J-14, J-7, J-3 et J-1, paramétrables | MISSING | ABSENT | | | ABSENT |
| EF-13.06 | M13 Veille | S | Alerter sur les sources en échec répété | MISSING | ABSENT | | | ABSENT |
| EF-13.07 | M13 Veille | M | Historique consultable des exécutions de veille | MISSING | ABSENT | | | ABSENT |
| EF-13.08 | M13 Veille | M | Indiquer clairement que la veille locale ne tourne que si l'application est ouverte ou réduite dans la zone de notification | MISSING | ABSENT | | | ABSENT |
| EF-13.09 | M13 Veille | S | Lancement au démarrage du système et exécution en arrière-plan réduite, sur option | MISSING | ABSENT | | | ABSENT |
| EF-13.10 | M13 Veille | C | Veille continue déportée sur le service auto-hébergé, avec notifications chiffrées | MISSING | ABSENT | | | ABSENT |
| EF-14.01 | M14 Fournisseurs IA | M | Choisir un fournisseur et un modèle parmi les connecteurs disponibles (API compatibles OpenAI, Gemini, Mistral, Groq, OpenRouter, Anthropic, Ollama, LM Studio) | MISSING | ABSENT | | | ABSENT |
| EF-14.02 | M14 Fournisseurs IA | M | Saisir une clé d'API stockée dans le trousseau du système, jamais en clair en base ni dans les journaux | MISSING | ABSENT | | | ABSENT |
| EF-14.03 | M14 Fournisseurs IA | M | Tester la connexion et afficher les modèles disponibles | MISSING | ABSENT | | | ABSENT |
| EF-14.04 | M14 Fournisseurs IA | S | Définir une chaîne de repli ordonnée entre fournisseurs | MISSING | ABSENT | | | ABSENT |
| EF-14.05 | M14 Fournisseurs IA | C | Affecter un modèle par tâche (extraction, classification, rédaction) | MISSING | ABSENT | | | ABSENT |
| EF-14.06 | M14 Fournisseurs IA | M | Gérer délais, quotas, erreurs 429 et nouvelles tentatives bornées | MISSING | ABSENT | | | ABSENT |
| EF-14.07 | M14 Fournisseurs IA | S | Suivre la consommation : appels, jetons estimés, erreurs, par fournisseur et par jour | MISSING | ABSENT | | | ABSENT |
| EF-14.08 | M14 Fournisseurs IA | M | Mettre en cache les résultats d'analyse par empreinte de contenu | MISSING | ABSENT | | | ABSENT |
| EF-14.09 | M14 Fournisseurs IA | M | Demander le consentement explicite avant le premier envoi de données de profil à un fournisseur distant | MISSING | ABSENT | | | ABSENT |
| EF-14.10 | M14 Fournisseurs IA | M | Anonymiser le profil envoyé (sans nom, contact ni identifiant) | MISSING | ABSENT | | | ABSENT |
| EF-14.11 | M14 Fournisseurs IA | M | Mode « IA désactivée » pleinement fonctionnel | MISSING | ABSENT | | | ABSENT |
| EF-15.01 | M15 Espaces | M | Créer, renommer, archiver, supprimer un espace de recherche | PARTIAL | NON OPÉRATIONNEL | | | NON OPÉRATIONNEL |
| EF-15.02 | M15 Espaces | M | Associer à chaque espace ses requêtes, filtres, résultats, notes et veilles | PARTIAL | NON OPÉRATIONNEL | | | NON OPÉRATIONNEL |
| EF-15.03 | M15 Espaces | M | Sauvegarder une requête et la relancer | MISSING | ABSENT | | | ABSENT |
| EF-15.04 | M15 Espaces | S | Comparer les résultats de deux exécutions (nouveaux, disparus, modifiés) | MISSING | ABSENT | | | ABSENT |
| EF-15.05 | M15 Espaces | M | Consulter et effacer l'historique de recherche | MISSING | ABSENT | | | ABSENT |
| EF-15.06 | M15 Espaces | S | Modèles d'espaces : emploi, bourse de master, financement associatif, startup, conseil IT, marchés publics, stages | MISSING | ABSENT | | | ABSENT |
| EF-15.07 | M15 Espaces | C | Comparer deux à quatre opportunités côte à côte | MISSING | ABSENT | | | ABSENT |
| EF-15.08 | M15 Espaces | C | Partager un espace avec les membres d'une organisation | MISSING | ABSENT | | | ABSENT |
| EF-16.01 | M16 Exports | M | Exporter en CSV (UTF-8 avec BOM pour Excel) | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-16.02 | M16 Exports | S | Exporter en XLSX avec mise en forme et filtres | MISSING | ABSENT | | | ABSENT |
| EF-16.03 | M16 Exports | S | Générer un rapport PDF : couverture, synthèse, tableau, fiches | MISSING | ABSENT | | | ABSENT |
| EF-16.04 | M16 Exports | M | Exporter en JSON selon un schéma documenté et versionné | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-16.05 | M16 Exports | M | Exporter la sélection courante ou tous les résultats filtrés | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-16.06 | M16 Exports | M | Exclure par défaut toute donnée personnelle non nécessaire | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-16.07 | M16 Exports | M | Exporter l'intégralité de ses données personnelles (portabilité) | MISSING | ABSENT | | | ABSENT |
| EF-16.08 | M16 Exports | S | Importer un export JSON pour restaurer ou migrer des dossiers | MISSING | ABSENT | | | ABSENT |
| EF-17.01 | M17 Organisations/Sync | S | Créer une organisation et inviter des membres par lien ou courriel | MISSING | ABSENT | | | ABSENT |
| EF-17.02 | M17 Organisations/Sync | S | Rôles d'organisation : propriétaire, administrateur, éditeur, lecteur | MISSING | ABSENT | | | ABSENT |
| EF-17.03 | M17 Organisations/Sync | S | Partager espaces, opportunités sauvegardées et dossiers de candidature d'organisation | MISSING | ABSENT | | | ABSENT |
| EF-17.04 | M17 Organisations/Sync | S | Synchroniser plusieurs postes d'un même utilisateur | MISSING | ABSENT | | | ABSENT |
| EF-17.05 | M17 Organisations/Sync | M | Chiffrer de bout en bout les données synchronisées ; le serveur ne lit jamais le contenu | MISSING | ABSENT | | | ABSENT |
| EF-17.06 | M17 Organisations/Sync | S | Synchronisation différentielle tolérante aux coupures réseau | MISSING | ABSENT | | | ABSENT |
| EF-17.07 | M17 Organisations/Sync | S | Résoudre les conflits par horodatage logique avec choix manuel en cas de doute | MISSING | ABSENT | | | ABSENT |
| EF-17.08 | M17 Organisations/Sync | S | Choisir l'instance de synchronisation (officielle PROTEGE QV ou auto-hébergée) | MISSING | ABSENT | | | ABSENT |
| EF-17.09 | M17 Organisations/Sync | S | Fournir le serveur sous forme d'image Docker documentée | MISSING | ABSENT | | | ABSENT |
| EF-17.10 | M17 Organisations/Sync | C | Partager une opportunité par lien public anonyme sans donnée de profil | MISSING | ABSENT | | | ABSENT |
| EF-17.11 | M17 Organisations/Sync | S | Journal d'audit des actions dans une organisation | MISSING | ABSENT | | | ABSENT |
| EF-17.12 | M17 Organisations/Sync | M | Quitter une organisation et emporter ses données personnelles | MISSING | ABSENT | | | ABSENT |
| EF-18.01 | M18 Paramètres | M | Thèmes clair, sombre et système | MISSING | ABSENT | | | ABSENT |
| EF-18.02 | M18 Paramètres | M | Langue de l'interface français ou anglais, extensible par fichiers de traduction | MISSING | ABSENT | | | ABSENT |
| EF-18.03 | M18 Paramètres | M | Formats régionaux : dates, nombres, devise par défaut (XAF) | MISSING | ABSENT | | | ABSENT |
| EF-18.04 | M18 Paramètres | M | Chiffrer la base locale (SQLCipher) avec clé dérivée du mot de passe | COMPLETE | NON OPÉRATIONNEL (moteur ne démarre pas) | | | NON OPÉRATIONNEL |
| EF-18.05 | M18 Paramètres | M | Sauvegarde manuelle et automatique planifiée, chiffrée, avec rotation | MISSING | ABSENT | | | ABSENT |
| EF-18.06 | M18 Paramètres | M | Restauration depuis une sauvegarde avec contrôle d'intégrité | MISSING | ABSENT | | | ABSENT |
| EF-18.07 | M18 Paramètres | M | Tableau de bord confidentialité : données stockées, envois vers des tiers, consentements | MISSING | ABSENT | | | ABSENT |
| EF-18.08 | M18 Paramètres | M | Effacer sélectivement historique, documents, opportunités ou tout le profil | MISSING | ABSENT | | | ABSENT |
| EF-18.09 | M18 Paramètres | M | Politique de confidentialité et conditions d'utilisation consultables hors ligne | MISSING | ABSENT | | | ABSENT |
| EF-18.10 | M18 Paramètres | S | Configuration réseau : proxy, limite de bande passante, mode économie de données | MISSING | ABSENT | | | ABSENT |
| EF-18.11 | M18 Paramètres | M | Vérifier les mises à jour et installer les versions signées | MISSING | ABSENT | | | ABSENT |
| EF-18.12 | M18 Paramètres | S | Consulter et exporter les journaux techniques expurgés pour le support | MISSING | ABSENT | | | ABSENT |
| EF-18.13 | M18 Paramètres | S | Raccourcis clavier configurables et palette de commandes | MISSING | ABSENT | | | ABSENT |
| EF-18.14 | M18 Paramètres | S | Assistant de premier lancement et visite guidée | MISSING | ABSENT | | | ABSENT |
