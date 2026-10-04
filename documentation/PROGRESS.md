# PROGRESS

| Requirement | Status |
| --- | --- |
| EF-01.01 | Créer un compte local avec nom, courriel, mot de passe et confirmation | M | | COMPLETE |
| EF-01.02 | Exiger un mot de passe d'au moins 12 caractères avec indicateur de robustesse et contrôle contre les mots de passe compromis connus (liste locale) | M | | COMPLETE |
| EF-01.03 | Hacher les mots de passe avec Argon2id | M | | COMPLETE |
| EF-01.04 | Se connecter, se déconnecter, verrouiller automatiquement après une inactivité paramétrable | M | | COMPLETE |
| EF-01.05 | Limiter les tentatives (5 échecs = temporisation progressive) | M | | COMPLETE |
| EF-01.06 | Générer une phrase de récupération de 12 mots à la création pour récupérer un compte local hors ligne | M | | COMPLETE |
| EF-01.07 | Changer le mot de passe et régénérer la clé de chiffrement locale | M | | COMPLETE |
| EF-01.08 | Gérer plusieurs profils utilisateurs isolés sur un même poste | S | | COMPLETE |
| EF-01.09 | Créer ou lier un compte en ligne sur le service de synchronisation (courriel vérifié, réinitialisation par courriel) | S | | MISSING |
| EF-01.10 | Activer une double authentification TOTP pour le compte en ligne | S | | MISSING |
| EF-01.11 | Supprimer définitivement son compte et toutes ses données locales et distantes | M | | COMPLETE |
| EF-01.12 | Afficher clairement le mode actif : local seul ou synchronisé | M | | COMPLETE |
| EF-02.01 | Assistant en 7 étapes : informations générales, formation, expérience, compétences, objectifs, préférences projet/financement, récapitulatif | M | | COMPLETE |
| EF-02.02 | Informations générales : nom, pays, ville, langue, statut, localisations souhaitées, mobilité, mode télétravail/hybride/présentiel | M | | COMPLETE |
| EF-02.03 | Formation : niveau, domaine, établissement, année d'obtention, certifications, distinctions | M | | COMPLETE |
| EF-02.04 | Expériences professionnelles multiples avec dates, poste, employeur, missions | M | | COMPLETE |
| EF-02.05 | Compétences techniques et transversales avec niveau, langues avec niveau CECRL | M | | COMPLETE |
| EF-02.06 | Liens professionnels : portfolio, LinkedIn, GitHub, site web | S | | PARTIAL |
| EF-02.07 | Sélection multiple des 16 objectifs proposés plus objectifs libres | M | | COMPLETE |
| EF-02.08 | Préférences projet : catégorie, description, stade, besoin et fourchette de financement, pays, bénéficiaires, statut juridique, calendrier | S | | PARTIAL |
| EF-02.09 | Passer toute question facultative et y revenir plus tard | M | | COMPLETE |
| EF-02.10 | Indicateur de complétude et suggestions des champs qui amélioreraient la pertinence | M | | COMPLETE |
| EF-02.11 | Résumé de profil généré à partir des seules données saisies, modifiable et validé par l'utilisateur | S | | PARTIAL |
| EF-02.12 | Profil d'organisation distinct pour associations et PME (secteur, statut, pays d'activité, budget annuel indicatif) | S | | PARTIAL |
| EF-03.01 | Importer un CV au format PDF, DOCX ou TXT (taille maximale 10 Mo) | S | | MOCK |
| EF-03.02 | Analyser le fichier dans un processus isolé, sans exécution de macros ni de contenu actif | M | | MOCK |
| EF-03.03 | Extraire formations, expériences, compétences et langues, en local ou via IA selon le choix de l'utilisateur | S | | MOCK |
| EF-03.04 | Présenter chaque élément extrait pour validation individuelle avant enregistrement | M | | MOCK |
| EF-03.05 | Conserver ou supprimer le fichier source selon la préférence de l'utilisateur | M | | MOCK |
| EF-04.01 | Saisir une requête libre en français ou en anglais | M | | MISSING |
| EF-04.02 | Extraire les paramètres : catégorie, mots-clés, synonymes, pays, mode de travail, public, montant, dates, expérience, langues, type d'organisation, éligibilité | M | | MISSING |
| EF-04.03 | Afficher l'interprétation sous forme de filtres éditables avant lancement | M | | MISSING |
| EF-04.04 | Interprétation par règles et dictionnaires lorsque aucune IA n'est configurée | M | | MISSING |
| EF-04.05 | Filtres manuels : date, pays, catégorie, date limite, éligibilité, source, niveau d'expérience, fourchette de montant | M | | MISSING |
| EF-04.06 | Exécuter la recherche en tâche de fond avec progression par source, annulation et reprise | M | | PARTIAL |
| EF-04.07 | Suggestions de requêtes basées sur le profil et l'historique | C | | MISSING |
| EF-04.08 | Recherche plein texte locale sur les opportunités déjà collectées (FTS5) | M | | MISSING |
| EF-05.01 | Interroger les API de recherche autorisées et les API officielles des sources | M | | MISSING |
| EF-05.02 | Lire les flux RSS et Atom et les données structurées schema.org (JobPosting, Grant, Event) | M | | PARTIAL |
| EF-05.03 | Extraire le contenu des pages HTML statiques via adaptateurs déclaratifs (sélecteurs) | M | | MISSING |
| EF-05.04 | Utiliser un navigateur sans tête uniquement pour les sources marquées comme le nécessitant et l'autorisant | S | | MISSING |
| EF-05.05 | Extraire et convertir les annonces publiées en PDF | S | | MISSING |
| EF-05.06 | Vérifier robots.txt et les conditions déclarées avant tout accès, et respecter les délais entre requêtes | M | | MISSING |
| EF-05.07 | S'identifier par un User-Agent explicite renvoyant vers la page du projet | M | | MISSING |
| EF-05.08 | Gérer pagination, champs manquants, pages malformées, délais d'expiration, nouvelles tentatives bornées avec recul exponentiel | M | | MISSING |
| EF-05.09 | Normaliser dates, devises (dont XAF), pays (ISO 3166) et langues (ISO 639) | M | | MISSING |
| EF-05.10 | Conserver mot pour mot les clauses critiques (éligibilité, date limite) avec horodatage de collecte | M | | MISSING |
| EF-05.11 | Journaliser chaque exécution par source : statut, durée, nombre d'éléments, erreurs | M | | MISSING |
| EF-05.12 | Signaler les sources inaccessibles et proposer le lien officiel de recherche au lieu d'un faux succès | M | | MISSING |
| EF-05.13 | Mettre en cache les réponses HTTP selon les en-têtes de validation (ETag, Last-Modified) | S | | MISSING |
| EF-06.01 | Lister les sources : catégorie, pays, type d'accès, statut, dernier succès, dernière erreur | M | | MISSING |
| EF-06.02 | Ajouter une URL publique ; l'application détecte flux, sitemap et données structurées | M | | MISSING |
| EF-06.03 | Activer, désactiver, catégoriser, supprimer une source personnalisée | M | | MISSING |
| EF-06.04 | Régler la fréquence d'analyse dans la limite autorisée par la source | M | | MISSING |
| EF-06.05 | Créer un adaptateur via un éditeur visuel de sélecteurs avec aperçu en direct | S | | MISSING |
| EF-06.06 | Installer et mettre à jour des connecteurs depuis le registre communautaire signé | S | | MISSING |
| EF-06.07 | Proposer un connecteur au registre ; validation par un mainteneur | C | | MISSING |
| EF-06.08 | Calculer un score de fiabilité par source (taux de succès, fraîcheur, origine officielle) | S | | MISSING |
| EF-06.09 | Catalogue initial d'au moins 60 sources (Cameroun, Afrique centrale, organisations internationales, bourses, marchés publics) | M | | MISSING |
| EF-07.01 | Extraire en sortie structurée validée par schéma : titre, catégorie, organisme, dates, lieu, public, formation, expérience, compétences, éligibilité, pièces, procédure, canal, montant, avantages, restrictions, contact public | M | | MISSING |
| EF-07.02 | Étiqueter chaque champ selon sa provenance : explicite, déduit, généré | M | | MISSING |
| EF-07.03 | Rattacher chaque champ extrait à l'extrait source qui le justifie | S | | MISSING |
| EF-07.04 | Afficher « Non précisé » ou « Non vérifiable » plutôt qu'une valeur inventée | M | | MISSING |
| EF-07.05 | Résumer les annonces longues en 5 lignes maximum | M | | MISSING |
| EF-07.06 | Traiter le contenu collecté comme non fiable : isoler les instructions qu'il contient du prompt système | M | | MISSING |
| EF-07.07 | Rejeter et rejouer une fois toute réponse non conforme au schéma, sinon basculer sur l'extraction déterministe | M | | MISSING |
| EF-07.08 | Traduire une annonce dans la langue de l'utilisateur sur demande | C | | MISSING |
| EF-08.01 | Calculer un score de pertinence de 0 à 100 à partir de critères pondérés : compétences, formation, expérience, localisation, langues, objectifs, date limite | M | | COMPLETE |
| EF-08.02 | Afficher la décomposition du score par critère | M | | COMPLETE |
| EF-08.03 | Lister les atouts, les qualifications manquantes et les points d'éligibilité à vérifier | M | | COMPLETE |
| EF-08.04 | Ne jamais affirmer l'éligibilité sans critères publiés et données de profil concordants | M | | COMPLETE |
| EF-08.05 | Ajuster les pondérations dans les paramètres | S | | MISSING |
| EF-08.06 | Recueillir le retour (pertinent, non pertinent, écarter) et adapter les recommandations localement | S | | MISSING |
| EF-08.07 | Correspondance sémantique par embeddings calculés localement lorsque possible | C | | MISSING |
| EF-09.01 | Classer selon 15 catégories et leurs sous-catégories | M | | MISSING |
| EF-09.02 | Dédoublonner par URL normalisée, identifiant source, empreinte titre + organisme + date limite, puis similarité approximative | M | | MISSING |
| EF-09.03 | Regrouper les doublons multi-sites et privilégier l'annonce de l'éditeur d'origine | M | | MISSING |
| EF-09.04 | Trier par pertinence, récence, date limite, publication, montant, lieu, type | M | | MISSING |
| EF-09.05 | Pagination incrémentale des résultats | M | | MISSING |
| EF-09.06 | Signaler visuellement : vérifié, généré par IA, expiré, échéance proche, éligibilité incertaine | M | | MISSING |
| EF-09.07 | Marquer automatiquement comme expirée toute opportunité dont la date limite est dépassée | M | | MISSING |
| EF-10.01 | Fiche en 13 rubriques : aperçu, éditeur et source, éligibilité, qualifications, pièces, date limite, avantages financiers, procédure, lien officiel, statut de vérification, explication de pertinence, écarts d'éligibilité, liste de préparation | M | | MISSING |
| EF-10.02 | Afficher l'extrait original à côté de chaque donnée structurée | S | | MISSING |
| EF-10.03 | Ouvrir le lien officiel dans le navigateur par défaut | M | | MISSING |
| EF-10.04 | Revérifier une opportunité à la demande (nouvelle collecte, détection de modification ou de retrait) | S | | MISSING |
| EF-10.05 | Générer une liste de pièces cochable à partir des exigences publiées | M | | MISSING |
| EF-10.06 | Rédiger, à partir du seul profil validé, une lettre de motivation, une lettre de bourse, un résumé de projet, un courriel de candidature | S | | MISSING |
| EF-10.07 | Structurer une proposition de subvention selon le canevas du bailleur lorsqu'il est publié | S | | MISSING |
| EF-10.08 | Suggérer des améliorations de CV ciblées sur l'opportunité | S | | MISSING |
| EF-10.09 | Préparer des questions d'entretien probables et des pistes de réponse | C | | MISSING |
| EF-10.10 | Interdire l'ajout de diplômes, expériences ou distinctions absents du profil ; signaler toute tentative | M | | MISSING |
| EF-10.11 | Éditer, versionner et exporter les documents générés (DOCX, PDF) | S | | MISSING |
| EF-10.12 | Rappeler que la soumission se fait sur le canal officiel ; ne jamais déclarer une candidature soumise sans action de l'utilisateur | M | | MISSING |
| EF-11.01 | Indicateurs issus des données réelles : opportunités découvertes, nouvelles depuis la dernière recherche, pertinentes, sauvegardées | M | | COMPLETE |
| EF-11.02 | Échéances à venir sur 7, 14 et 30 jours | M | | COMPLETE |
| EF-11.03 | Candidatures par statut et actions de relance à mener | M | | MISSING |
| EF-11.04 | Activité de recherche récente | M | | MISSING |
| EF-11.05 | Recommandations personnalisées du jour | S | | MISSING |
| EF-11.06 | État de la veille et santé des sources | S | | COMPLETE |
| EF-11.07 | États vides guidés pour un nouvel utilisateur | M | | MISSING |
| EF-11.08 | Statistiques personnelles : taux de réponse, délais moyens, catégories les plus fructueuses | C | | MISSING |
| EF-12.01 | Sauvegarder et retirer une opportunité | M | | PARTIAL |
| EF-12.02 | Ajouter des notes, une priorité (haute, moyenne, basse) et des étiquettes | M | | PARTIAL |
| EF-12.03 | Marquer comme intéressante ou inéligible avec motif | M | | MISSING |
| EF-12.04 | Suivre le statut selon le cycle : découverte, à examiner, en préparation, prête, soumise, entretien ou évaluation, acceptée, refusée, retirée, expirée, archivée | M | | MISSING |
| EF-12.05 | Historiser chaque changement de statut avec date | M | | MISSING |
| EF-12.06 | Enregistrer date de soumission, entretiens, relances et contacts | M | | MISSING |
| EF-12.07 | Joindre des documents stockés localement et chiffrés | M | | MISSING |
| EF-12.08 | Définir des échéances personnelles distinctes de la date limite officielle | S | | MISSING |
| EF-12.09 | Vue tableau Kanban par statut avec glisser-déposer | S | | MISSING |
| EF-12.10 | Vue calendrier des échéances et entretiens, export iCalendar | S | | MISSING |
| EF-12.11 | Rechercher et filtrer dans ses dossiers personnels | M | | MISSING |
| EF-12.12 | Archiver automatiquement les dossiers clos après un délai paramétrable | C | | MISSING |
| EF-13.01 | Créer un profil de veille : catégories, mots-clés, sources, zone géographique, score minimal | M | | MISSING |
| EF-13.02 | Planifier une fréquence (quotidienne, hebdomadaire, personnalisée) bornée par les limites des sources | M | | MISSING |
| EF-13.03 | Activer, suspendre, supprimer une veille | M | | MISSING |
| EF-13.04 | Notifier les nouvelles opportunités et les modifications d'annonces suivies | M | | MISSING |
| EF-13.05 | Rappels d'échéance à J-14, J-7, J-3 et J-1, paramétrables | M | | MISSING |
| EF-13.06 | Alerter sur les sources en échec répété | S | | MISSING |
| EF-13.07 | Historique consultable des exécutions de veille | M | | MISSING |
| EF-13.08 | Indiquer clairement que la veille locale ne tourne que si l'application est ouverte ou réduite dans la zone de notification | M | | MISSING |
| EF-13.09 | Lancement au démarrage du système et exécution en arrière-plan réduite, sur option | S | | MISSING |
| EF-13.10 | Veille continue déportée sur le service auto-hébergé, avec notifications chiffrées | C | | MISSING |
| EF-14.01 | Choisir un fournisseur et un modèle parmi les connecteurs disponibles (API compatibles OpenAI, Gemini, Mistral, Groq, OpenRouter, Anthropic, Ollama, LM Studio) | M | | MISSING |
| EF-14.02 | Saisir une clé d'API stockée dans le trousseau du système, jamais en clair en base ni dans les journaux | M | | MISSING |
| EF-14.03 | Tester la connexion et afficher les modèles disponibles | M | | MISSING |
| EF-14.04 | Définir une chaîne de repli ordonnée entre fournisseurs | S | | MISSING |
| EF-14.05 | Affecter un modèle par tâche (extraction, classification, rédaction) | C | | MISSING |
| EF-14.06 | Gérer délais, quotas, erreurs 429 et nouvelles tentatives bornées | M | | MISSING |
| EF-14.07 | Suivre la consommation : appels, jetons estimés, erreurs, par fournisseur et par jour | S | | MISSING |
| EF-14.08 | Mettre en cache les résultats d'analyse par empreinte de contenu | M | | MISSING |
| EF-14.09 | Demander le consentement explicite avant le premier envoi de données de profil à un fournisseur distant | M | | MISSING |
| EF-14.10 | Anonymiser le profil envoyé (sans nom, contact ni identifiant) | M | | MISSING |
| EF-14.11 | Mode « IA désactivée » pleinement fonctionnel | M | | MISSING |
| EF-15.01 | Créer, renommer, archiver, supprimer un espace de recherche | M | | PARTIAL |
| EF-15.02 | Associer à chaque espace ses requêtes, filtres, résultats, notes et veilles | M | | PARTIAL |
| EF-15.03 | Sauvegarder une requête et la relancer | M | | MISSING |
| EF-15.04 | Comparer les résultats de deux exécutions (nouveaux, disparus, modifiés) | S | | MISSING |
| EF-15.05 | Consulter et effacer l'historique de recherche | M | | MISSING |
| EF-15.06 | Modèles d'espaces : emploi, bourse de master, financement associatif, startup, conseil IT, marchés publics, stages | S | | MISSING |
| EF-15.07 | Comparer deux à quatre opportunités côte à côte | C | | MISSING |
| EF-15.08 | Partager un espace avec les membres d'une organisation | C | | MISSING |
| EF-16.01 | Exporter en CSV (UTF-8 avec BOM pour Excel) | M | | COMPLETE |
| EF-16.02 | Exporter en XLSX avec mise en forme et filtres | S | | MISSING |
| EF-16.03 | Générer un rapport PDF : couverture, synthèse, tableau, fiches | S | | MISSING |
| EF-16.04 | Exporter en JSON selon un schéma documenté et versionné | M | | COMPLETE |
| EF-16.05 | Exporter la sélection courante ou tous les résultats filtrés | M | | COMPLETE |
| EF-16.06 | Exclure par défaut toute donnée personnelle non nécessaire | M | | COMPLETE |
| EF-16.07 | Exporter l'intégralité de ses données personnelles (portabilité) | M | | MISSING |
| EF-16.08 | Importer un export JSON pour restaurer ou migrer des dossiers | S | | MISSING |
| EF-17.01 | Créer une organisation et inviter des membres par lien ou courriel | S | | MISSING |
| EF-17.02 | Rôles d'organisation : propriétaire, administrateur, éditeur, lecteur | S | | MISSING |
| EF-17.03 | Partager espaces, opportunités sauvegardées et dossiers de candidature d'organisation | S | | MISSING |
| EF-17.04 | Synchroniser plusieurs postes d'un même utilisateur | S | | MISSING |
| EF-17.05 | Chiffrer de bout en bout les données synchronisées ; le serveur ne lit jamais le contenu | M | | MISSING |
| EF-17.06 | Synchronisation différentielle tolérante aux coupures réseau | S | | MISSING |
| EF-17.07 | Résoudre les conflits par horodatage logique avec choix manuel en cas de doute | S | | MISSING |
| EF-17.08 | Choisir l'instance de synchronisation (officielle PROTEGE QV ou auto-hébergée) | S | | MISSING |
| EF-17.09 | Fournir le serveur sous forme d'image Docker documentée | S | | MISSING |
| EF-17.10 | Partager une opportunité par lien public anonyme sans donnée de profil | C | | MISSING |
| EF-17.11 | Journal d'audit des actions dans une organisation | S | | MISSING |
| EF-17.12 | Quitter une organisation et emporter ses données personnelles | M | | MISSING |
| EF-18.01 | Thèmes clair, sombre et système | M | | MISSING |
| EF-18.02 | Langue de l'interface français ou anglais, extensible par fichiers de traduction | M | | MISSING |
| EF-18.03 | Formats régionaux : dates, nombres, devise par défaut (XAF) | M | | MISSING |
| EF-18.04 | Chiffrer la base locale (SQLCipher) avec clé dérivée du mot de passe | M | | COMPLETE |
| EF-18.05 | Sauvegarde manuelle et automatique planifiée, chiffrée, avec rotation | M | | MISSING |
| EF-18.06 | Restauration depuis une sauvegarde avec contrôle d'intégrité | M | | MISSING |
| EF-18.07 | Tableau de bord confidentialité : données stockées, envois vers des tiers, consentements | M | | MISSING |
| EF-18.08 | Effacer sélectivement historique, documents, opportunités ou tout le profil | M | | MISSING |
| EF-18.09 | Politique de confidentialité et conditions d'utilisation consultables hors ligne | M | | MISSING |
| EF-18.10 | Configuration réseau : proxy, limite de bande passante, mode économie de données | S | | MISSING |
| EF-18.11 | Vérifier les mises à jour et installer les versions signées | M | | MISSING |
| EF-18.12 | Consulter et exporter les journaux techniques expurgés pour le support | S | | MISSING |
| EF-18.13 | Raccourcis clavier configurables et palette de commandes | S | | MISSING |
| EF-18.14 | Assistant de premier lancement et visite guidée | S | | MISSING |
