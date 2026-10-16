// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Opportunex';

  @override
  String get slogan => 'Trouvez · Analysez · Réalisez';

  @override
  String get tagline =>
      'Votre assistant pour les opportunités publiques et privées';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonCopy => 'Copier';

  @override
  String get commonCopied => 'Copié dans le presse-papiers';

  @override
  String get commonLoading => 'Chargement…';

  @override
  String get commonOptional => 'facultatif';

  @override
  String get commonShow => 'Afficher';

  @override
  String get commonHide => 'Masquer';

  @override
  String get commonYes => 'Oui';

  @override
  String get commonNo => 'Non';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonSearch => 'Rechercher';

  @override
  String get commonNotSpecified => 'Non précisé';

  @override
  String get commonUnknownError =>
      'Une erreur inattendue est survenue. Réessayez ; si le problème persiste, exportez les journaux depuis Paramètres › Maintenance.';

  @override
  String get startupStarting => 'Démarrage du moteur local…';

  @override
  String startupRestarting(int attempt) {
    return 'Le moteur s\'est arrêté. Redémarrage (tentative $attempt sur 3)…';
  }

  @override
  String get diagTitle => 'Le moteur local n\'a pas pu démarrer';

  @override
  String get diagNotFound =>
      'Le moteur Opportunex est introuvable. Réinstallez l\'application ou, en développement, exécutez « launch-dev.ps1 -Setup ».';

  @override
  String get diagAlreadyRunning =>
      'Opportunex est déjà ouvert pour cet utilisateur. Fermez l\'autre fenêtre avant de réessayer.';

  @override
  String get diagHandshake =>
      'Le moteur n\'a pas répondu à temps. Votre antivirus bloque peut-être son lancement.';

  @override
  String get diagCrashed => 'Le moteur s\'est arrêté plusieurs fois de suite.';

  @override
  String get diagHealth =>
      'Le moteur a démarré mais ne répond pas aux vérifications.';

  @override
  String get diagDetails => 'Détails techniques';

  @override
  String get diagExportLogs => 'Ouvrir le dossier des journaux';

  @override
  String get diagRetry => 'Relancer le moteur';

  @override
  String get authWelcomeTitle => 'Bienvenue';

  @override
  String get authWelcomeSubtitle =>
      'Vos données restent sur cet ordinateur, chiffrées.';

  @override
  String get authChooseProfile => 'Choisissez votre profil';

  @override
  String get authNewProfile => 'Créer un profil';

  @override
  String get authOtherAccount => 'Se connecter avec un autre courriel';

  @override
  String get authImportProfile => 'Importer un profil depuis une sauvegarde';

  @override
  String get authEmail => 'Adresse électronique';

  @override
  String get authPassword => 'Mot de passe';

  @override
  String get authConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get authDisplayName => 'Nom affiché';

  @override
  String get authLanguage => 'Langue';

  @override
  String get authSignIn => 'Se connecter';

  @override
  String get authSignInTitle => 'Connexion';

  @override
  String get authForgotPassword => 'Mot de passe oublié ?';

  @override
  String get authCreateAccount => 'Créer un compte';

  @override
  String get authRegisterTitle => 'Créer votre profil local';

  @override
  String get authRegisterSubtitle =>
      'Un profil est chiffré avec votre mot de passe. Personne d\'autre, pas même ETS Monthe Network, ne peut le lire.';

  @override
  String get authAcceptTerms =>
      'J\'accepte les conditions d\'utilisation et la politique de confidentialité';

  @override
  String get authReadTerms => 'Lire les conditions';

  @override
  String get authAlreadyHaveAccount => 'J\'ai déjà un profil';

  @override
  String get authPasswordHint =>
      '12 caractères minimum. Une phrase de plusieurs mots est idéale.';

  @override
  String get authStrength0 => 'Très faible';

  @override
  String get authStrength1 => 'Faible';

  @override
  String get authStrength2 => 'Moyen';

  @override
  String get authStrength3 => 'Bon';

  @override
  String get authStrength4 => 'Excellent';

  @override
  String get authPhraseTitle => 'Votre phrase de récupération';

  @override
  String get authPhraseBody =>
      'Notez ces 12 mots dans l\'ordre et conservez-les hors de l\'ordinateur. Ils sont le seul moyen de récupérer vos données si vous oubliez votre mot de passe. Ils ne seront plus jamais affichés.';

  @override
  String get authPhraseConfirm =>
      'J\'ai noté ma phrase de récupération en lieu sûr';

  @override
  String get authUnlockTitle => 'Profil verrouillé';

  @override
  String get authUnlockInactivity =>
      'Verrouillé après une période d\'inactivité.';

  @override
  String get authUnlockManual => 'Profil verrouillé.';

  @override
  String get authUnlockExpired => 'Votre session a expiré.';

  @override
  String get authUnlock => 'Déverrouiller';

  @override
  String get authSwitchProfile => 'Changer de profil';

  @override
  String get authRecoverTitle => 'Récupérer votre profil';

  @override
  String get authRecoverBody =>
      'Saisissez les 12 mots de votre phrase de récupération, puis choisissez un nouveau mot de passe.';

  @override
  String get authRecoveryPhrase => 'Phrase de récupération (12 mots)';

  @override
  String get authNewPassword => 'Nouveau mot de passe';

  @override
  String get authRecover => 'Récupérer et se connecter';

  @override
  String get authLock => 'Verrouiller';

  @override
  String get authSignOut => 'Se déconnecter';

  @override
  String get authModeLocal => 'Mode local';

  @override
  String get authModeSynced => 'Synchronisé';

  @override
  String authLockedFor(int seconds) {
    return 'Trop de tentatives. Réessayez dans $seconds s.';
  }

  @override
  String get validationRequired => 'Champ obligatoire';

  @override
  String get validationEmail => 'Adresse électronique invalide';

  @override
  String get validationPasswordMatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get validationPhraseWords =>
      'La phrase doit contenir exactement 12 mots';

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get navSearch => 'Recherche';

  @override
  String get navSaved => 'Sauvegardées';

  @override
  String get navApplications => 'Candidatures';

  @override
  String get navMonitors => 'Veilles';

  @override
  String get navWorkspaces => 'Espaces';

  @override
  String get navSources => 'Sources';

  @override
  String get navProfile => 'Mon profil';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get navCollapse => 'Réduire le menu';

  @override
  String get navExpand => 'Déployer le menu';

  @override
  String get errInvalidCredentials => 'Adresse ou mot de passe incorrect.';

  @override
  String get errAccountLocked =>
      'Trop de tentatives échouées. Patientez avant de réessayer.';

  @override
  String get errEmailTaken =>
      'Un profil utilise déjà cette adresse sur cet ordinateur.';

  @override
  String get errPasswordPolicy =>
      'Mot de passe trop faible : 12 caractères minimum, non présent dans la liste des mots de passe compromis.';

  @override
  String get errPasswordMismatch => 'Les mots de passe ne correspondent pas.';

  @override
  String get errTermsNotAccepted =>
      'Vous devez accepter les conditions d\'utilisation.';

  @override
  String get errInvalidRecovery => 'Phrase de récupération incorrecte.';

  @override
  String get errSessionLocked => 'Votre session est verrouillée.';

  @override
  String get errEngineUnreachable =>
      'Le moteur local ne répond pas. Il redémarre peut-être.';

  @override
  String get errValidation => 'Certains champs sont invalides.';

  @override
  String get errNotFound => 'Élément introuvable.';

  @override
  String get errProfileCorrupted =>
      'Le profil ne peut pas être déchiffré. Restaurez une sauvegarde.';

  @override
  String get errUpstream =>
      'Le service externe est indisponible pour le moment.';

  @override
  String get settingsAccount => 'Compte et sécurité';

  @override
  String get settingsBackups => 'Sauvegardes';

  @override
  String get settingsMaintenance => 'Maintenance';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsSaved => 'Modifications enregistrées';

  @override
  String get settingsProfileSection => 'Profil';

  @override
  String get settingsModeLocalHelp =>
      'Vos données restent uniquement sur cet ordinateur.';

  @override
  String get settingsModeSyncedHelp =>
      'Vos données sont chiffrées de bout en bout et synchronisées entre vos appareils.';

  @override
  String get settingsAppearance => 'Langue et apparence';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsSecurity => 'Sécurité';

  @override
  String get settingsAutoLock => 'Verrouillage automatique';

  @override
  String get settingsAutoLockHelp =>
      'Après cette durée d\'inactivité, le profil se verrouille et la clé de chiffrement est effacée de la mémoire.';

  @override
  String settingsMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get settingsChangePassword => 'Changer le mot de passe';

  @override
  String get settingsChangePasswordHelp =>
      'Vos données restent chiffrées ; seule l\'enveloppe de la clé est renouvelée.';

  @override
  String get settingsCurrentPassword => 'Mot de passe actuel';

  @override
  String get settingsPasswordChanged => 'Mot de passe modifié';

  @override
  String get settingsDangerZone => 'Zone sensible';

  @override
  String get settingsDeleteAccount => 'Supprimer le compte';

  @override
  String get settingsDeleteAccountHelp =>
      'Efface définitivement de cet ordinateur le profil, la base chiffrée, les documents et les sauvegardes.';

  @override
  String get settingsDeleteAccountConfirm =>
      'Cette action est irréversible : toutes vos données locales seront supprimées. Tapez DELETE pour confirmer.';

  @override
  String get settingsConfirmWithPassword => 'Confirmez avec votre mot de passe';

  @override
  String get backupsTitle => 'Sauvegardes';

  @override
  String get backupsHelp =>
      'Archives chiffrées de votre base et de vos documents. Les 7 dernières sauvegardes automatiques sont conservées.';

  @override
  String get backupsCreate => 'Sauvegarder maintenant';

  @override
  String get backupsCreated => 'Sauvegarde créée';

  @override
  String get backupsAuto => 'Sauvegarde automatique quotidienne';

  @override
  String get backupsAutoHelp =>
      'Effectuée quand l\'application est ouverte, au plus une fois par jour.';

  @override
  String get backupsFolder => 'Dossier des sauvegardes';

  @override
  String get backupsHistory => 'Historique';

  @override
  String get backupsEmpty => 'Aucune sauvegarde pour le moment.';

  @override
  String get backupsOkTag => 'intègre';

  @override
  String get backupsRestoredTag => 'restaurée';

  @override
  String get backupsVerify => 'Vérifier l\'intégrité';

  @override
  String get backupsVerified => 'Sauvegarde vérifiée : intègre';

  @override
  String get backupsRestore => 'Restaurer';

  @override
  String get backupsRestoreConfirm =>
      'Vos données actuelles seront remplacées par celles de la sauvegarde. Une sauvegarde de sécurité est d\'abord créée. Tapez RESTORE pour confirmer.';

  @override
  String get backupsRestored => 'Restauration terminée';

  @override
  String get backupsDelete => 'Supprimer la sauvegarde';

  @override
  String get backupsDeleteConfirm =>
      'Le fichier de sauvegarde sera supprimé définitivement.';

  @override
  String get backupsDeleted => 'Sauvegarde supprimée';

  @override
  String get backupKindManual => 'manuelle';

  @override
  String get backupKindScheduled => 'automatique';

  @override
  String get backupKindPreMigration => 'avant mise à jour';

  @override
  String get backupKindPreRestore => 'avant restauration';

  @override
  String get maintenanceStorage => 'Espace utilisé';

  @override
  String get maintenanceDatabase => 'Base de données';

  @override
  String get maintenanceVault => 'Documents chiffrés';

  @override
  String get maintenanceDataDir => 'Dossier des données';

  @override
  String get maintenanceTools => 'Outils';

  @override
  String get maintenanceRun => 'Lancer';

  @override
  String get maintenanceIntegrity => 'Contrôle d\'intégrité';

  @override
  String get maintenanceIntegrityHelp =>
      'Vérifie la base, les clés étrangères et l\'index de recherche.';

  @override
  String get maintenanceIntegrityOk => 'Aucun problème détecté';

  @override
  String get maintenanceOptimize => 'Optimiser la base';

  @override
  String get maintenanceOptimizeHelp =>
      'Compacte la base et optimise l\'index de recherche.';

  @override
  String get maintenanceOptimized => 'Base optimisée';

  @override
  String get maintenanceLogs => 'Journaux techniques';

  @override
  String get maintenanceLogsHelp =>
      'Exporte les journaux expurgés (sans courriel, jeton ni clé) pour l\'assistance.';

  @override
  String get maintenanceExport => 'Exporter';

  @override
  String get maintenanceLogsSaved => 'Journaux exportés';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutEngine => 'moteur';

  @override
  String get aboutSchema => 'schéma';

  @override
  String get aboutCredits => 'Éditeur et auteur';

  @override
  String get aboutPublisher => 'Éditeur';

  @override
  String get aboutAuthor => 'Développeur principal';

  @override
  String get aboutCopyright => 'Droit d\'auteur';

  @override
  String get aboutLicense => 'Licence';

  @override
  String get aboutLicenseBody =>
      'Opportunex est un logiciel libre et gratuit, distribué sous la licence GNU Affero General Public License v3. Vous pouvez l\'utiliser, l\'étudier, le modifier et le redistribuer selon les termes de cette licence. Le nom et le logo Opportunex restent réservés.';

  @override
  String get aboutSourceCode => 'Code source';

  @override
  String get aboutThirdParty => 'Licences des composants tiers';

  @override
  String get aboutTermsPrivacy => 'Conditions et confidentialité';

  @override
  String get legalTerms => 'Conditions d\'utilisation';

  @override
  String get legalPrivacy => 'Confidentialité';

  @override
  String get importProfileBody =>
      'Choisissez un fichier de sauvegarde Opportunex (.opxbak) et saisissez le mot de passe du profil sauvegardé.';

  @override
  String get importChooseFile => 'Choisir une sauvegarde…';

  @override
  String get importAction => 'Importer et se connecter';

  @override
  String get badgeAiGenerated => 'Généré par IA';

  @override
  String get badgeDeadlineSoon => 'Échéance proche';

  @override
  String get badgeDeadlineUnknown => 'Date limite inconnue';

  @override
  String get badgeEligibilityUncertain => 'Éligibilité incertaine';

  @override
  String get badgeExpired => 'Expirée';

  @override
  String get badgeModified => 'Modifiée';

  @override
  String get badgeNew => 'Nouvelle';

  @override
  String get badgeVerified => 'Vérifiée';

  @override
  String scoreLabel(int score) {
    return 'Pertinence $score sur 100';
  }

  @override
  String get catAcceleration => 'Incubation et accélération';

  @override
  String get catCall => 'Appels à candidatures';

  @override
  String get catCompetition => 'Concours et prix';

  @override
  String get catEmployment => 'Emploi';

  @override
  String get catEntrepreneurship => 'Entrepreneuriat';

  @override
  String get catFreelance => 'Missions freelance';

  @override
  String get catGrant => 'Subventions et financements';

  @override
  String get catInternship => 'Stages';

  @override
  String get catOther => 'Autres opportunités';

  @override
  String get catPartnership => 'Partenariats';

  @override
  String get catResearch => 'Recherche';

  @override
  String get catScholarship => 'Bourses';

  @override
  String get catTender => 'Appels d\'offres';

  @override
  String get catTraining => 'Formations';

  @override
  String get catVolunteering => 'Volontariat';

  @override
  String get critDeadline => 'Date limite';

  @override
  String get critEducation => 'Formation';

  @override
  String get critExperience => 'Expérience';

  @override
  String get critLanguage => 'Langues';

  @override
  String get critLocation => 'Localisation';

  @override
  String get critNotEvaluated => 'Critère non évalué faute d\'information';

  @override
  String get critObjectives => 'Objectifs';

  @override
  String get critSkills => 'Compétences';

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours restants',
      one: '1 jour restant',
      zero: 'dernier jour',
    );
    return '$_temp0';
  }

  @override
  String get deadlineUnknownShort => 'Date limite non précisée';

  @override
  String get eligLikely => 'Éligibilité probable (selon les critères publiés)';

  @override
  String get eligNot => 'Non éligible : date limite dépassée';

  @override
  String get eligUncertain => 'Éligibilité à vérifier';

  @override
  String get eligUnlikely => 'Éligibilité peu probable';

  @override
  String get exportAction => 'Exporter';

  @override
  String get exportDone => 'Export enregistré';

  @override
  String get filterAdd => 'Ajouter';

  @override
  String get filterAddKeyword => 'Ajouter un mot-clé';

  @override
  String get filterAmountMin => 'Montant minimal';

  @override
  String get filterAnyBadge => 'Tous les signalements';

  @override
  String get filterAnyDate => 'Toute date';

  @override
  String get filterAnyScore => 'Toute pertinence';

  @override
  String get filterBadge => 'Signalement';

  @override
  String get filterCategories => 'Catégories';

  @override
  String get filterCountries => 'Pays';

  @override
  String get filterDeadlineBefore => 'Date limite avant le';

  @override
  String get filterIncludeExpired => 'Inclure les expirées';

  @override
  String get filterKeywords => 'Mots-clés';

  @override
  String get filterMinScore => 'Pertinence minimale';

  @override
  String get filterWorkMode => 'Mode de travail';

  @override
  String get filtersSubtitle =>
      'Voici comment Opportunex a compris votre demande. Corrigez librement avant de lancer la recherche.';

  @override
  String get filtersTitle => 'Critères de recherche';

  @override
  String gapEducation(String value) {
    return 'Niveau d\'études demandé : $value';
  }

  @override
  String gapExperience(String value) {
    return 'Expérience demandée : $value an(s)';
  }

  @override
  String gapLanguage(String value) {
    return 'Langue demandée : $value';
  }

  @override
  String gapLocation(String value) {
    return 'Localisation : $value';
  }

  @override
  String gapSkills(String value) {
    return 'Compétences absentes de votre profil : $value';
  }

  @override
  String get historyClear => 'Effacer l\'historique';

  @override
  String get historyClearConfirm =>
      'Les recherches non enregistrées seront supprimées. Les recherches enregistrées sont conservées.';

  @override
  String get historyEmpty => 'Aucune recherche pour le moment.';

  @override
  String get historyHint =>
      'Enregistrez une recherche pour la relancer plus tard ou en faire une veille.';

  @override
  String get historyOpen => 'Voir les résultats';

  @override
  String get historyRerun => 'Relancer';

  @override
  String get historySave => 'Enregistrer la recherche';

  @override
  String get historyUnsave => 'Ne plus enregistrer';

  @override
  String get loadMore => 'Afficher plus';

  @override
  String get oppAddWorkspace => 'Ajouter à un espace';

  @override
  String get oppAmount => 'Montant';

  @override
  String get oppApplicationUrl => 'Lien de candidature';

  @override
  String get oppContact => 'Contact public';

  @override
  String get oppDeadline => 'Date limite';

  @override
  String get oppDismiss => 'Écarter';

  @override
  String get oppDocumentsRequired => 'Pièces à fournir';

  @override
  String get oppEligibility => 'Éligibilité';

  @override
  String get oppFeedbackThanks => 'Merci, vos recommandations seront ajustées';

  @override
  String get oppFinancial => 'Avantages financiers';

  @override
  String get oppFullText => 'Texte complet de l\'annonce';

  @override
  String get oppGaps => 'Écarts et points à vérifier';

  @override
  String get oppLastChecked => 'Dernière vérification';

  @override
  String get oppLocation => 'Lieu';

  @override
  String get oppMethod => 'Méthode d\'analyse';

  @override
  String get oppMethodRules => 'Règles déterministes (sans IA)';

  @override
  String get oppMore => 'Plus d\'actions';

  @override
  String get oppNoCriteria =>
      'L\'annonce ne publie pas de critères d\'éligibilité précis : vérifiez auprès de l\'éditeur.';

  @override
  String get oppNoGaps => 'Aucun écart détecté avec votre profil.';

  @override
  String get oppNotRelevant => 'Non pertinent';

  @override
  String get oppOfficialLink => 'Lien officiel';

  @override
  String get oppOpenTracking => 'Voir le suivi';

  @override
  String get oppOriginalPublisher => 'Éditeur d\'origine';

  @override
  String get oppOverview => 'Aperçu';

  @override
  String get oppProcedure => 'Procédure';

  @override
  String get oppPublished => 'Publiée le';

  @override
  String get oppPublisher => 'Éditeur et sources';

  @override
  String get oppQualifications => 'Qualifications demandées';

  @override
  String get oppRecheck => 'Revérifier sur le site officiel';

  @override
  String get oppRechecked => 'Vérification terminée';

  @override
  String get oppRelevance => 'Pertinence pour vous';

  @override
  String get oppRelevant => 'Pertinent';

  @override
  String get oppRepost => 'Republication';

  @override
  String get oppSave => 'Sauvegarder';

  @override
  String get oppSaved => 'Sauvegardée';

  @override
  String get oppSavedToast => 'Opportunité sauvegardée';

  @override
  String get oppStatus => 'Statut';

  @override
  String get oppStrengths => 'Vos atouts';

  @override
  String get oppSubmissionNotice =>
      'Opportunex ne soumet jamais de candidature : postulez sur le canal officiel de l\'éditeur.';

  @override
  String get oppSummary => 'Résumé';

  @override
  String get oppToVerify => 'À vérifier vous-même';

  @override
  String get oppVerbatimNote =>
      'Clauses reproduites mot pour mot depuis l\'annonce.';

  @override
  String get oppVerification => 'Vérification';

  @override
  String get provExplicit => 'Explicite';

  @override
  String get provGenerated => 'Généré';

  @override
  String get provInferred => 'Déduit';

  @override
  String get reqEducation => 'Formation';

  @override
  String get reqExperience => 'Expérience';

  @override
  String get reqLanguages => 'Langues';

  @override
  String get reqSkills => 'Compétences';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
      zero: 'Aucun résultat',
    );
    return '$_temp0';
  }

  @override
  String get resultsEmptyBody =>
      'Élargissez vos critères ou ajoutez des sources dans la section Sources.';

  @override
  String get resultsEmptyTitle => 'Aucune opportunité ne correspond';

  @override
  String get runCancelled => 'annulée';

  @override
  String get runCompleted => 'terminée';

  @override
  String get runFailed => 'échouée';

  @override
  String get runPartial => 'terminée partiellement';

  @override
  String runProgress(int done, int total) {
    return 'Recherche en cours : $done source(s) sur $total';
  }

  @override
  String get runResume => 'Reprendre';

  @override
  String runStatus(String status) {
    return 'Recherche $status';
  }

  @override
  String get runUnavailableBody =>
      'Ces sources n\'ont pas pu être consultées automatiquement ou ne le permettent pas. Consultez-les directement :';

  @override
  String get runUnavailableTitle => 'Sources à consulter manuellement';

  @override
  String get searchEmptyBody =>
      'Décrivez ce que vous cherchez en français ou en anglais, par exemple « bourse de master en France » ou « stage en informatique à Douala ».';

  @override
  String get searchEmptyTitle => 'Que recherchez-vous ?';

  @override
  String get searchHelper =>
      'Recherche en langage naturel, en français ou en anglais';

  @override
  String get searchHint => 'Ex. : bourse de master en santé publique pour 2027';

  @override
  String get searchInterpret => 'Analyser';

  @override
  String get searchLaunch => 'Lancer la recherche';

  @override
  String get searchSuggestions => 'Suggestions';

  @override
  String get searchTabHistory => 'Historique';

  @override
  String get searchTabNew => 'Recherche';

  @override
  String get sortAmount => 'Montant';

  @override
  String get sortDeadline => 'Date limite';

  @override
  String get sortPublished => 'Publication';

  @override
  String get sortRecent => 'Ajout récent';

  @override
  String get sortRelevance => 'Pertinence';

  @override
  String sourcesCount(int count) {
    return '$count sources';
  }

  @override
  String get workHybrid => 'Hybride';

  @override
  String get workOnsite => 'Présentiel';

  @override
  String get workRemote => 'À distance';

  @override
  String get wsAdded => 'Ajoutée à l\'espace';

  @override
  String get wsNoneYet => 'Créez d\'abord un espace dans la section Espaces.';

  @override
  String get calDeadline => 'Date limite officielle';

  @override
  String get calEmpty => 'Aucune échéance ce mois-ci.';

  @override
  String get calExportIcs => 'Exporter le calendrier (.ics)';

  @override
  String get calNext => 'Mois suivant';

  @override
  String get calPersonalDeadline => 'Échéance personnelle';

  @override
  String get calPrev => 'Mois précédent';

  @override
  String get cvAccept => 'Accepter';

  @override
  String cvApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments ajoutés au profil',
      one: '1 élément ajouté au profil',
      zero: 'Aucun élément ajouté au profil',
    );
    return '$_temp0';
  }

  @override
  String get cvApply => 'Ajouter au profil';

  @override
  String cvConfidence(int pct) {
    return 'Confiance de l\'extraction : $pct %';
  }

  @override
  String get cvDiscard => 'Abandonner l\'import';

  @override
  String get cvIdentity => 'Identité';

  @override
  String get cvImport => 'Importer un CV';

  @override
  String get cvKeepFile => 'Conserver le fichier du CV';

  @override
  String get cvKeepFileHelp =>
      'Le fichier est chiffré dans votre coffre local. Sinon il est supprimé après l\'analyse.';

  @override
  String get cvNothingFound => 'Rien n\'a pu être extrait';

  @override
  String get cvNothingFoundBody =>
      'Le document est peut-être scanné (image) ou protégé. Vous pouvez remplir votre profil manuellement.';

  @override
  String get cvPick => 'Choisir un fichier';

  @override
  String get cvPickBody =>
      'PDF, DOCX ou TXT, 10 Mo maximum. L\'analyse se fait sur cet ordinateur, sans envoi en ligne.';

  @override
  String get cvPickTitle => 'Importer votre CV';

  @override
  String get cvReject => 'Rejeter';

  @override
  String get cvReviewHelp =>
      'Vérifiez chaque élément détecté : acceptez, corrigez ou rejetez. Seuls les éléments acceptés seront ajoutés.';

  @override
  String get cvSubtitle =>
      'Pré-remplissez votre profil à partir d\'un CV existant';

  @override
  String get dashActivity => 'Activité récente';

  @override
  String get dashApplications => 'Candidatures par statut';

  @override
  String get dashDeadlines => 'Échéances à venir';

  @override
  String get dashDiscovered => 'Découvertes';

  @override
  String get dashFirstStepsBody =>
      'Quelques étapes pour obtenir des résultats pertinents.';

  @override
  String get dashFirstStepsTitle => 'Premiers pas';

  @override
  String dashFollowUp(String title) {
    return 'Relance conseillée : $title';
  }

  @override
  String dashHello(String name) {
    return 'Bonjour $name';
  }

  @override
  String get dashInProgress => 'En préparation';

  @override
  String get dashManage => 'Gérer';

  @override
  String get dashNew => 'Nouvelles';

  @override
  String get dashNewSearch => 'Nouvelle recherche';

  @override
  String get dashNoActivity => 'Aucune activité pour le moment.';

  @override
  String get dashNoApplications => 'Aucune candidature suivie.';

  @override
  String get dashNoDeadlines => 'Aucune échéance dans les 30 prochains jours.';

  @override
  String get dashNoRecommendations =>
      'Lancez une recherche pour obtenir des recommandations.';

  @override
  String get dashNoStats =>
      'Les statistiques apparaîtront après vos premières candidatures.';

  @override
  String get dashRecommendations => 'Recommandations';

  @override
  String get dashRecommendationsHelp =>
      'Opportunités ouvertes les mieux classées pour votre profil (score indicatif).';

  @override
  String get dashRelevant => 'Pertinentes';

  @override
  String get dashSaved => 'Sauvegardées';

  @override
  String dashSourceFailing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count échecs consécutifs',
      one: '1 échec consécutif',
    );
    return '$_temp0';
  }

  @override
  String get dashSources => 'État des sources';

  @override
  String dashSourcesSummary(int active, int healthy, int total) {
    return '$active actives, $healthy en bon état, $total au total';
  }

  @override
  String dashStatAccepted(int count) {
    return 'Acceptées : $count';
  }

  @override
  String dashStatDelay(String days) {
    return 'Délai moyen de réponse : $days jours';
  }

  @override
  String dashStatRate(String rate) {
    return 'Taux d\'acceptation : $rate';
  }

  @override
  String dashStatSubmitted(int count) {
    return 'Soumises : $count';
  }

  @override
  String get dashStats => 'Statistiques personnelles';

  @override
  String get dashStepCv => 'Importer un CV';

  @override
  String get dashStepMonitor => 'Créer une veille';

  @override
  String get dashStepProfile => 'Compléter le profil';

  @override
  String get dashStepSearch => 'Lancer une recherche';

  @override
  String get dashSubmitted => 'Soumises';

  @override
  String dashSubmittedOn(String date) {
    return 'Soumise le $date';
  }

  @override
  String get dashSubtitle =>
      'Vue d\'ensemble de vos opportunités et candidatures';

  @override
  String dashWithin(int days, int count) {
    return '$days jours : $count';
  }

  @override
  String get dayFri => 'Vendredi';

  @override
  String get dayMon => 'Lundi';

  @override
  String get daySat => 'Samedi';

  @override
  String get daySun => 'Dimanche';

  @override
  String get dayThu => 'Jeudi';

  @override
  String get dayTue => 'Mardi';

  @override
  String get dayWed => 'Mercredi';

  @override
  String get docCoverLetter => 'Lettre de motivation';

  @override
  String get docCvSuggestions => 'Suggestions d\'adaptation du CV';

  @override
  String get docEmail => 'E-mail de candidature';

  @override
  String get docGrant => 'Demande de subvention';

  @override
  String get docInterview => 'Préparation d\'entretien';

  @override
  String get docProjectSummary => 'Résumé de projet';

  @override
  String get docScholarship => 'Lettre de candidature à une bourse';

  @override
  String get edBac => 'Baccalauréat';

  @override
  String get edBac2 => 'Bac+2 (BTS, DUT, HND)';

  @override
  String get edBachelor => 'Licence / Bachelor';

  @override
  String get edDoctorate => 'Doctorat';

  @override
  String get edMaster => 'Master';

  @override
  String get edNone => 'Aucun diplôme';

  @override
  String get edPostdoc => 'Post-doctorat';

  @override
  String get edPrimary => 'Primaire';

  @override
  String get edSecondary => 'Secondaire';

  @override
  String get edVocational => 'Formation professionnelle';

  @override
  String get eraseAction => 'Effacer la sélection';

  @override
  String get eraseConfirm =>
      'Les données sélectionnées seront supprimées définitivement de cet ordinateur. Saisissez ERASE pour confirmer.';

  @override
  String get eraseDocuments => 'Documents joints aux candidatures';

  @override
  String get eraseDone => 'Données effacées';

  @override
  String get eraseHelp =>
      'Choisissez précisément ce que vous voulez supprimer. Votre compte et vos candidatures sont conservés.';

  @override
  String get eraseHistory => 'Historique des recherches non enregistrées';

  @override
  String get eraseLogs => 'Journaux techniques';

  @override
  String get eraseNotifications => 'Notifications';

  @override
  String get eraseOpportunities => 'Opportunités non sauvegardées';

  @override
  String get eraseProfile =>
      'Détails du profil (formation, expérience, compétences…)';

  @override
  String get eraseTitle => 'Effacement sélectif';

  @override
  String get etConsulting => 'Conseil';

  @override
  String get etFreelance => 'Freelance';

  @override
  String get etFullTime => 'Temps plein';

  @override
  String get etInternship => 'Stage';

  @override
  String get etPartTime => 'Temps partiel';

  @override
  String get etVolunteer => 'Bénévolat';

  @override
  String get evCall => 'Appel';

  @override
  String get evFollowUp => 'Relance';

  @override
  String get evInterview => 'Entretien';

  @override
  String get evMeeting => 'Rendez-vous';

  @override
  String get evOther => 'Autre';

  @override
  String get evTest => 'Test';

  @override
  String get genCreate => 'Créer un brouillon';

  @override
  String get genEmpty => 'Aucun brouillon pour cette opportunité.';

  @override
  String get genIntegrityTitle =>
      'À vérifier : éléments absents de votre profil validé';

  @override
  String get genNotice =>
      'Brouillon généré à partir de votre profil validé. Relisez-le et adaptez-le avant tout envoi.';

  @override
  String get genSaveVersion => 'Enregistrer une version';

  @override
  String get genSubtitle =>
      'Brouillons modifiables, avec historique des versions';

  @override
  String get genTitle => 'Documents générés';

  @override
  String get monCreate => 'Nouvelle veille';

  @override
  String monDaily(String time) {
    return 'Tous les jours à $time';
  }

  @override
  String get monDailyLabel => 'Quotidienne';

  @override
  String get monEmptyBody =>
      'Une veille relance une recherche à intervalle régulier et vous signale les nouveautés.';

  @override
  String get monEmptyTitle => 'Aucune veille';

  @override
  String get monFrequencyNote =>
      'La fréquence réelle respecte les limites de chaque source (au plus une fois par jour en général).';

  @override
  String monLastRun(String date, int count) {
    return 'Dernière exécution : $date · $count nouvelles';
  }

  @override
  String monMinScore(int score) {
    return 'Score minimal pour être notifié : $score';
  }

  @override
  String get monName => 'Nom de la veille';

  @override
  String monNextRun(String date) {
    return 'Prochaine exécution : $date';
  }

  @override
  String get monOnlyWhileOpen =>
      'Les veilles s\'exécutent uniquement lorsque Opportunex est ouvert (y compris réduit dans la zone de notification).';

  @override
  String get monQuery => 'Recherche à surveiller';

  @override
  String get monRunNow => 'Exécuter maintenant';

  @override
  String monScheduleSummary(String schedule, int score) {
    return '$schedule · score minimal $score';
  }

  @override
  String get monStarted => 'Veille lancée';

  @override
  String get monTabMonitors => 'Veilles';

  @override
  String get monTabNotifications => 'Notifications';

  @override
  String monWeekly(String when) {
    return 'Chaque semaine : $when';
  }

  @override
  String get monWeeklyLabel => 'Hebdomadaire';

  @override
  String get nkChanged => 'Opportunité suivie modifiée';

  @override
  String get nkDeadline => 'Rappels d\'échéance';

  @override
  String get nkMonitor => 'Échec d\'une veille';

  @override
  String get nkNew => 'Nouvelles opportunités';

  @override
  String get nkSource => 'Source indisponible';

  @override
  String get notifEmpty => 'Aucune notification';

  @override
  String get notifMarkAllRead => 'Tout marquer comme lu';

  @override
  String get onbDone => 'Profil enregistré. Bienvenue !';

  @override
  String get onbFinish => 'Terminer';

  @override
  String get onbLater => 'Plus tard';

  @override
  String get onbOptionalNote =>
      'Toutes les étapes sont facultatives et modifiables à tout moment depuis votre profil.';

  @override
  String get onbResume => 'Reprendre la configuration';

  @override
  String get onbSkip => 'Passer';

  @override
  String get onbStep1 => 'Informations générales et liens';

  @override
  String get onbStep2 => 'Formation';

  @override
  String get onbStep3 => 'Expérience';

  @override
  String get onbStep4 => 'Compétences et langues';

  @override
  String get onbStep5 => 'Objectifs';

  @override
  String get onbStep6 => 'Projet ou organisation';

  @override
  String get onbStep7 => 'Récapitulatif';

  @override
  String onbStepOf(int step, int total, String title) {
    return 'Étape $step sur $total — $title';
  }

  @override
  String get onbTitle => 'Configurer votre profil';

  @override
  String get orgAcademic => 'Établissement académique';

  @override
  String get orgAssociation => 'Association';

  @override
  String get orgBudget => 'Budget annuel';

  @override
  String get orgCooperative => 'Coopérative / GIC';

  @override
  String get orgHelp =>
      'Renseignez-la si vous cherchez des opportunités au nom d\'une structure.';

  @override
  String get orgName => 'Nom de l\'organisation';

  @override
  String get orgNgo => 'ONG';

  @override
  String get orgNone => 'Aucune organisation renseignée.';

  @override
  String get orgPublic => 'Organisme public';

  @override
  String get orgRegistration => 'Numéro d\'immatriculation (RCCM…)';

  @override
  String get orgSector => 'Secteur d\'activité';

  @override
  String get orgSme => 'PME';

  @override
  String get orgStartup => 'Start-up';

  @override
  String get orgTitle => 'Organisation';

  @override
  String get orgType => 'Type d\'organisation';

  @override
  String get pfAchievements => 'Réalisations';

  @override
  String get pfAdd => 'Ajouter';

  @override
  String get pfAddLanguage => 'Ajouter une langue';

  @override
  String get pfAddLink => 'Ajouter un lien';

  @override
  String get pfAddSkill => 'Ajouter une compétence';

  @override
  String get pfAnyMode => 'Indifférent';

  @override
  String get pfBeneficiaries => 'Bénéficiaires';

  @override
  String get pfBio => 'Présentation';

  @override
  String get pfCertName => 'Intitulé de la certification';

  @override
  String get pfCertifications => 'Certifications';

  @override
  String get pfCity => 'Ville';

  @override
  String pfCompleteness(int pct) {
    return 'Profil complété à $pct %';
  }

  @override
  String get pfCountry => 'Pays';

  @override
  String get pfCredentialUrl => 'Lien de vérification';

  @override
  String get pfCurrency => 'Devise';

  @override
  String get pfCurrentJob => 'Poste actuel';

  @override
  String get pfCustomObjective => 'Autre objectif…';

  @override
  String get pfDegree => 'Diplôme';

  @override
  String get pfEducation => 'Formation';

  @override
  String get pfEducationLevel => 'Niveau d\'études le plus élevé';

  @override
  String get pfEmployer => 'Employeur';

  @override
  String get pfEmploymentType => 'Type de contrat';

  @override
  String get pfEnd => 'Fin';

  @override
  String get pfExperience => 'Expérience';

  @override
  String get pfExperienceYears => 'Années d\'expérience';

  @override
  String get pfExpiresOn => 'Expire le';

  @override
  String get pfField => 'Domaine d\'études';

  @override
  String get pfFullName => 'Nom complet';

  @override
  String get pfFundingHelp =>
      'Montant entier dans la devise choisie (en centimes pour EUR et USD).';

  @override
  String get pfFundingMax => 'Financement maximal recherché';

  @override
  String get pfFundingMin => 'Financement minimal recherché';

  @override
  String get pfGeneral => 'Informations générales';

  @override
  String get pfGrade => 'Mention';

  @override
  String get pfImproveHint => 'Pour des résultats plus pertinents, complétez :';

  @override
  String get pfInstitution => 'Établissement';

  @override
  String get pfIssuer => 'Organisme émetteur';

  @override
  String get pfJobTitle => 'Intitulé du poste';

  @override
  String get pfLanguages => 'Langues';

  @override
  String get pfLegalStatus => 'Statut juridique';

  @override
  String get pfLinkKind => 'Type de lien';

  @override
  String get pfLinks => 'Liens';

  @override
  String get pfLinksLocations => 'Liens et localisations';

  @override
  String get pfMissingEducation => 'votre formation';

  @override
  String get pfMissingExperience => 'votre expérience';

  @override
  String get pfMissingIdentity => 'votre nom et votre pays';

  @override
  String get pfMissingLanguages => 'vos langues';

  @override
  String get pfMissingObjectives => 'vos objectifs';

  @override
  String get pfMissingPreferences => 'vos préférences de localisation';

  @override
  String get pfMissingSkills => 'vos compétences';

  @override
  String get pfMissingStatus => 'votre situation professionnelle';

  @override
  String get pfMissions => 'Missions principales';

  @override
  String get pfNative => 'Langue maternelle';

  @override
  String get pfNothingYet => 'Rien pour le moment.';

  @override
  String get pfObjectives => 'Objectifs';

  @override
  String get pfObjectivesHelp =>
      'Ce que vous recherchez : ils orientent les recherches et le classement.';

  @override
  String get pfObtainedOn => 'Obtenu le';

  @override
  String get pfOccupation => 'Occupation actuelle';

  @override
  String get pfOngoing => 'En cours';

  @override
  String get pfPhone => 'Téléphone';

  @override
  String get pfPhoneHelp =>
      'Utilisé uniquement dans les brouillons de documents que vous générez.';

  @override
  String get pfPortfolio => 'Portfolio';

  @override
  String get pfPreferredLocations => 'Localisations recherchées';

  @override
  String get pfProjectDescription => 'Description';

  @override
  String get pfProjectTitle => 'Nom du projet';

  @override
  String get pfProjects => 'Projets';

  @override
  String get pfRegionCentralAfrica => 'Toute l\'Afrique centrale (CEMAC)';

  @override
  String get pfRelocate => 'Prêt à déménager';

  @override
  String get pfSkillPrimaryToggle => 'Marquer comme compétence principale';

  @override
  String get pfSkills => 'Compétences';

  @override
  String get pfSkillsLanguages => 'Compétences et langues';

  @override
  String get pfStage => 'Stade du projet';

  @override
  String get pfStart => 'Début';

  @override
  String get pfStatus => 'Situation professionnelle';

  @override
  String get pfSubtitle =>
      'Ces informations restent sur cet ordinateur et servent au classement des opportunités.';

  @override
  String get pfSummary => 'Résumé du profil';

  @override
  String get pfSummaryApprove => 'Valider ce résumé';

  @override
  String get pfSummaryApproved => 'Résumé validé';

  @override
  String get pfSummaryGenerate => 'Composer à partir du profil';

  @override
  String get pfSummaryHelp =>
      'Résumé composé uniquement à partir de vos informations. Modifiez-le puis validez-le.';

  @override
  String get pfTimeline => 'Durée prévue (mois)';

  @override
  String get pfWebsite => 'Site web';

  @override
  String prefBandwidth(int mb) {
    return 'Volume maximal par recherche : $mb Mo';
  }

  @override
  String get prefDataSaver => 'Économiseur de données';

  @override
  String get prefDataSaverHelp =>
      'Ne télécharge pas les pages de détail ni les pièces jointes pendant la recherche.';

  @override
  String get prefNetwork => 'Réseau';

  @override
  String get prefNotifications => 'Notifications';

  @override
  String get prefProxy => 'Proxy (facultatif)';

  @override
  String get prefReminders => 'Rappels avant échéance';

  @override
  String get prefRemindersHelp =>
      'Nombre de jours avant la date limite, séparés par des virgules (ex. 14, 7, 3, 1).';

  @override
  String get prefWeights => 'Pondération du score';

  @override
  String get prefWeightsHelp =>
      'Ajustez l\'importance de chaque critère dans le score de pertinence.';

  @override
  String get prioHigh => 'Haute';

  @override
  String get prioLow => 'Basse';

  @override
  String get prioMedium => 'Moyenne';

  @override
  String get privConsentAi => 'Traitement par un service d\'IA';

  @override
  String get privConsentSync => 'Synchronisation';

  @override
  String get privConsents => 'Consentements';

  @override
  String get privDisclosures => 'Données envoyées à des tiers';

  @override
  String get privExportAll => 'Exporter toutes mes données';

  @override
  String get privImportJson => 'Importer un export JSON';

  @override
  String privImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import terminé : $count opportunités suivies',
      one: 'Import terminé : 1 opportunité suivie',
      zero: 'Import terminé',
    );
    return '$_temp0';
  }

  @override
  String get privNoDisclosures =>
      'Aucune donnée personnelle n\'a été envoyée à un tiers.';

  @override
  String get privNoTelemetry =>
      'Aucune télémétrie : Opportunex n\'envoie aucune statistique d\'utilisation.';

  @override
  String get privOpportunities => 'Opportunités en cache';

  @override
  String get privPortability => 'Portabilité';

  @override
  String get privPortabilityHelp =>
      'Archive ZIP lisible (JSON + fichiers) de toutes vos données, ou réimport d\'un export JSON.';

  @override
  String get privRevoke => 'Retirer';

  @override
  String privRevokedOn(String date) {
    return 'retiré le $date';
  }

  @override
  String get privSearches => 'Recherches';

  @override
  String get privStored => 'Données stockées';

  @override
  String get privStoredHelp =>
      'Tout est chiffré dans la base locale de ce profil.';

  @override
  String get psEmployed => 'Salarié(e)';

  @override
  String get psEntrepreneur => 'Entrepreneur(e)';

  @override
  String get psFreelancer => 'Freelance';

  @override
  String get psJobSeeker => 'En recherche d\'emploi';

  @override
  String get psOther => 'Autre';

  @override
  String get psResearcher => 'Chercheur(se)';

  @override
  String get psRetired => 'Retraité(e)';

  @override
  String get psSelfEmployed => 'Indépendant(e)';

  @override
  String get psStudent => 'Étudiant(e)';

  @override
  String get psUnemployed => 'Sans emploi';

  @override
  String get srcActive => 'Actives';

  @override
  String get srcAdd => 'Ajouter une source';

  @override
  String get srcAddHelp =>
      'Indiquez l\'adresse d\'une page publique. Opportunex détecte un flux RSS/Atom et respecte robots.txt.';

  @override
  String srcAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Source ajoutée : $count éléments détectés',
      one: 'Source ajoutée : 1 élément détecté',
      zero: 'Source ajoutée (aucun élément détecté pour l\'instant)',
    );
    return '$_temp0';
  }

  @override
  String get srcAll => 'Toutes';

  @override
  String srcCount(int shown, int total) {
    return '$shown sur $total';
  }

  @override
  String get srcCustom => 'Ajoutées par moi';

  @override
  String get srcDetect => 'Détecter et ajouter';

  @override
  String get srcFailing => 'En échec';

  @override
  String srcLastError(String error) {
    return 'Erreur : $error';
  }

  @override
  String srcLastSuccess(String date) {
    return 'Dernier succès : $date';
  }

  @override
  String get srcLinkOnly => 'Lien officiel uniquement';

  @override
  String get srcLinks => 'Liens officiels';

  @override
  String get srcName => 'Nom (facultatif)';

  @override
  String srcOppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opportunités',
      one: '1 opportunité',
    );
    return '$_temp0';
  }

  @override
  String get srcPolicy =>
      'Opportunex n\'interroge que des sources publiques, respecte robots.txt et les conditions d\'utilisation, et espace ses requêtes. Les portails sans flux sont proposés sous forme de lien officiel.';

  @override
  String srcReliability(int pct) {
    return 'Fiabilité $pct %';
  }

  @override
  String get srcSubtitle =>
      'Catalogue des sources publiques interrogées lors des recherches';

  @override
  String get stAccepted => 'Acceptée';

  @override
  String get stArchived => 'Archivée';

  @override
  String get stDiscovered => 'Découverte';

  @override
  String get stExpired => 'Expirée';

  @override
  String get stInterview => 'Entretien';

  @override
  String get stPreparing => 'En préparation';

  @override
  String get stReady => 'Prête à soumettre';

  @override
  String get stRejected => 'Refusée';

  @override
  String get stSubmitted => 'Soumise';

  @override
  String get stToReview => 'À examiner';

  @override
  String get stWithdrawn => 'Retirée';

  @override
  String get stgEarly => 'Démarrage';

  @override
  String get stgEstablished => 'Établi';

  @override
  String get stgGrowth => 'Croissance';

  @override
  String get stgIdea => 'Idée';

  @override
  String get stgPrototype => 'Prototype';

  @override
  String get stgScale => 'Changement d\'échelle';

  @override
  String get trackAddEvent => 'Ajouter un événement';

  @override
  String get trackAddItem => 'Ajouter un élément';

  @override
  String get trackAddNote => 'Ajouter une note';

  @override
  String get trackAddTag => 'Ajouter une étiquette';

  @override
  String get trackAllPriorities => 'Toutes priorités';

  @override
  String get trackAllStatuses => 'Tous statuts';

  @override
  String get trackAllTags => 'Toutes étiquettes';

  @override
  String get trackArchive => 'Archiver';

  @override
  String get trackArchived => 'Archivées';

  @override
  String get trackAttach => 'Joindre un fichier';

  @override
  String get trackBoard => 'Tableau';

  @override
  String get trackCalendar => 'Calendrier';

  @override
  String get trackChecklist => 'Liste de contrôle';

  @override
  String get trackChecklistEmpty =>
      'Aucun élément. Les pièces demandées par l\'annonce apparaissent ici quand elles sont connues.';

  @override
  String trackChecklistProgress(int done, int total) {
    return '$done sur $total terminés';
  }

  @override
  String get trackDocumentLabel => 'Libellé du document';

  @override
  String get trackDocuments => 'Documents joints';

  @override
  String get trackDocumentsHelp =>
      'Les fichiers sont chiffrés dans votre coffre local.';

  @override
  String get trackDownload => 'Enregistrer une copie';

  @override
  String get trackDropHere => 'Déposer ici';

  @override
  String get trackEmptyBody =>
      'Sauvegardez des opportunités depuis les résultats de recherche pour les suivre ici.';

  @override
  String get trackEmptyTitle => 'Aucune opportunité suivie';

  @override
  String get trackEventContact => 'Contact';

  @override
  String get trackEventLocation => 'Lieu';

  @override
  String get trackEventTitle => 'Intitulé';

  @override
  String get trackEventType => 'Type';

  @override
  String get trackEventWhen => 'Date et heure';

  @override
  String get trackEvents => 'Événements et contacts';

  @override
  String get trackFromListing => 'Exigé par l\'annonce';

  @override
  String get trackHistory => 'Historique';

  @override
  String get trackIneligible => 'Non éligible';

  @override
  String get trackIneligibleReason => 'Raison (facultatif)';

  @override
  String get trackInterest => 'Intérêt';

  @override
  String get trackInterested => 'Intéressé(e)';

  @override
  String get trackList => 'Liste';

  @override
  String get trackNoDocuments => 'Aucun document joint.';

  @override
  String get trackNoEvents => 'Aucun événement.';

  @override
  String get trackNoPersonalDeadline => 'Aucune échéance personnelle';

  @override
  String get trackNoteHint => 'Écrire une note…';

  @override
  String get trackNotes => 'Notes';

  @override
  String get trackOpenSheet => 'Ouvrir la fiche';

  @override
  String get trackPersonalDeadline => 'Échéance personnelle';

  @override
  String get trackPriority => 'Priorité';

  @override
  String get trackReminders => 'Rappels programmés';

  @override
  String get trackSearchHint => 'Filtrer par titre ou organisme';

  @override
  String get trackSettings => 'Suivi';

  @override
  String get trackStatus => 'Statut';

  @override
  String trackStatusChanged(String status) {
    return 'Statut mis à jour : $status';
  }

  @override
  String get trackSubmittedOn => 'Date de soumission';

  @override
  String get trackTag => 'Étiquette';

  @override
  String get trackUnarchive => 'Désarchiver';

  @override
  String get trackUndecided => 'À décider';

  @override
  String get trackUnsave => 'Ne plus suivre';

  @override
  String get trackUnsaveConfirm =>
      'Les notes, documents et l\'historique de cette candidature seront supprimés.';

  @override
  String wsCompare(int count) {
    return 'Comparer ($count)';
  }

  @override
  String wsCounts(int queries, int saved, int opportunities) {
    return '$queries recherches · $saved suivies · $opportunities opportunités';
  }

  @override
  String get wsCreate => 'Nouvel espace';

  @override
  String get wsEmptyBody =>
      'Un espace regroupe des recherches, des opportunités et des notes autour d\'un projet.';

  @override
  String get wsEmptyTitle => 'Aucun espace de travail';

  @override
  String get wsName => 'Nom de l\'espace';

  @override
  String get wsNoOpportunities => 'Aucune opportunité dans cet espace.';

  @override
  String get wsNoQueries => 'Aucune recherche enregistrée dans cet espace.';

  @override
  String get wsNoTemplate => 'Vide';

  @override
  String get wsOpportunities => 'Opportunités';

  @override
  String get wsQueries => 'Recherches';

  @override
  String get wsRemove => 'Retirer de l\'espace';

  @override
  String get wsSearchHere => 'Rechercher dans cet espace';

  @override
  String get wsSubtitle => 'Organisez vos recherches par projet';

  @override
  String get wsTemplate => 'Modèle';

  @override
  String get settingsPreferences => 'Préférences';

  @override
  String get settingsPrivacy => 'Confidentialité';

  @override
  String get genSaved => 'Version enregistrée';

  @override
  String get prefCloseToTray =>
      'Continuer dans la zone de notification à la fermeture';

  @override
  String get prefCloseToTrayHelp =>
      'Les veilles et les rappels ne fonctionnent que lorsque l\'application est ouverte ; fermer la fenêtre la réduit alors à côté de l\'horloge.';

  @override
  String get trayOpen => 'Ouvrir Opportunex';

  @override
  String get trayQuit => 'Quitter';

  @override
  String get trayStillRunning =>
      'Opportunex continue dans la zone de notification pour exécuter vos veilles. Clic droit sur l\'icône pour quitter.';

  @override
  String get aiAddProvider => 'Ajouter un fournisseur';

  @override
  String get aiAllow => 'Autoriser';

  @override
  String get aiAnalyze => 'Analyser avec l\'IA';

  @override
  String aiAnalyzed(int applied, int unverifiable) {
    return 'Analyse terminée : $applied champs vérifiés ajoutés, $unverifiable non vérifiables';
  }

  @override
  String get aiBaseUrl => 'Adresse du service (facultatif)';

  @override
  String get aiBaseUrlHelp =>
      'HTTPS obligatoire, sauf pour un serveur sur cet ordinateur.';

  @override
  String get aiBaseUrlRequired => 'Adresse du service';

  @override
  String get aiConsentGiven => 'consentement donné';

  @override
  String aiConsentIntro(String provider) {
    return 'Pour cette action, Opportunex doit envoyer des données à $provider, un service en ligne :';
  }

  @override
  String get aiConsentNever =>
      'Votre nom, vos coordonnées, vos liens et vos identifiants ne sont jamais envoyés. Chaque envoi est inscrit dans le tableau de bord de confidentialité.';

  @override
  String get aiConsentRevoke =>
      'Vous pourrez retirer ce consentement à tout moment dans Paramètres > Confidentialité.';

  @override
  String aiConsentTitle(String provider) {
    return 'Envoyer des données à $provider ?';
  }

  @override
  String get aiDeleteConfirm =>
      'Le fournisseur et sa clé (retirée du trousseau du système) seront supprimés.';

  @override
  String get aiDisplayName => 'Nom affiché';

  @override
  String get aiEnable => 'Activer les fonctions d\'IA';

  @override
  String get aiEnableHelp =>
      'Désactivées par défaut. Toutes les fonctions marchent sans IA ; l\'IA ne fait qu\'aider à structurer, résumer, traduire et rédiger.';

  @override
  String get aiErrAuth => 'Clé d\'API refusée par le fournisseur.';

  @override
  String get aiErrNetwork =>
      'Service injoignable. Vérifiez la connexion et l\'adresse.';

  @override
  String aiErrOther(String code) {
    return 'Erreur du fournisseur ($code).';
  }

  @override
  String get aiErrRateLimited =>
      'Quota atteint chez le fournisseur. Réessayez plus tard.';

  @override
  String get aiErrTimeout => 'Le fournisseur n\'a pas répondu à temps.';

  @override
  String get aiFieldAmount => 'Montant';

  @override
  String get aiFieldApplicationUrl => 'Lien de candidature';

  @override
  String get aiFieldAudience => 'Public visé';

  @override
  String get aiFieldCategory => 'Catégorie';

  @override
  String get aiFieldCountry => 'Pays';

  @override
  String get aiFieldCurrency => 'Devise';

  @override
  String get aiFieldOrganization => 'Organisme';

  @override
  String get aiFields => 'Informations extraites par l\'IA';

  @override
  String get aiKey => 'Clé d\'API';

  @override
  String get aiKeyHelp =>
      'Conservée dans le trousseau sécurisé du système, jamais dans la base ni dans les journaux.';

  @override
  String get aiKeyMissing => 'clé manquante';

  @override
  String get aiKeyReplace =>
      'Nouvelle clé d\'API (laisser vide pour garder l\'actuelle)';

  @override
  String get aiKind => 'Fournisseur';

  @override
  String get aiKindLmStudio => 'LM Studio (sur cet ordinateur)';

  @override
  String get aiKindOllama => 'Ollama (sur cet ordinateur)';

  @override
  String get aiKindOpenAi => 'Compatible OpenAI (adresse personnalisée)';

  @override
  String get aiLocal => 'sur cet ordinateur';

  @override
  String get aiLocalHelp =>
      'Modèle exécuté sur cet ordinateur : aucune donnée ne quitte la machine, aucun consentement n\'est demandé.';

  @override
  String get aiModel => 'Modèle';

  @override
  String get aiModelHelp =>
      'Nom exact du modèle ; « Tester » liste les modèles disponibles.';

  @override
  String aiModelNotListed(String model) {
    return 'Le modèle « $model » n\'apparaît pas dans la liste : choisissez-en un ci-dessous.';
  }

  @override
  String aiModelsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modèles disponibles',
      one: '1 modèle disponible',
      zero: 'Aucun modèle listé',
    );
    return '$_temp0';
  }

  @override
  String get aiMoveDown => 'Descendre dans l\'ordre de repli';

  @override
  String get aiMoveUp => 'Monter dans l\'ordre de repli';

  @override
  String get aiNoProvider => 'Aucun fournisseur configuré.';

  @override
  String get aiProviderAdded =>
      'Fournisseur ajouté. Utilisez « Tester » pour vérifier la connexion.';

  @override
  String get aiProviders => 'Fournisseurs et ordre de repli';

  @override
  String get aiProvidersHelp =>
      'Les fournisseurs sont essayés dans cet ordre ; en dernier recours, l\'application utilise ses règles sans IA.';

  @override
  String get aiPurposeContent =>
      'Le texte nécessaire à la tâche (requête ou annonce publique)';

  @override
  String get aiPurposeCv =>
      'Le texte de votre CV, sans nom, courriel, téléphone ni liens';

  @override
  String get aiPurposeProfile =>
      'Votre profil anonymisé (formations, expériences, compétences, langues)';

  @override
  String get aiRemote => 'service en ligne';

  @override
  String get aiRemoteHelp =>
      'Service en ligne : un consentement vous sera demandé avant le premier envoi, et chaque envoi sera journalisé.';

  @override
  String get aiRouting => 'Modèle par tâche';

  @override
  String get aiRoutingAuto => 'Automatique (ordre de repli)';

  @override
  String get aiRoutingHelp =>
      'Choisissez un fournisseur précis pour certaines tâches.';

  @override
  String get aiRule1 =>
      'Les valeurs extraites sont vérifiées dans le texte de l\'annonce ; sinon elles sont marquées « Non vérifiable ».';

  @override
  String get aiRule2 =>
      'Le score de pertinence reste calculé sans IA, de façon explicable.';

  @override
  String get aiRule3 =>
      'Les brouillons n\'utilisent que votre profil validé ; tout ajout inventé est signalé.';

  @override
  String get aiRule4 =>
      'Les modèles locaux (Ollama, LM Studio) ne font sortir aucune donnée de l\'ordinateur.';

  @override
  String get aiSummary => 'Résumé généré par l\'IA';

  @override
  String get aiTaskCv => 'Analyse de CV';

  @override
  String get aiTaskDrafting => 'Rédaction de documents';

  @override
  String get aiTaskExtraction => 'Analyse des annonces';

  @override
  String get aiTaskQuery => 'Interprétation des recherches';

  @override
  String get aiTaskTranslation => 'Traduction';

  @override
  String get aiTest => 'Tester';

  @override
  String get aiTestFailed => 'échec du test';

  @override
  String aiTestOk(String date) {
    return 'testé le $date';
  }

  @override
  String get aiTestSuccess => 'Connexion réussie';

  @override
  String get aiTitle => 'Intelligence artificielle';

  @override
  String get aiTranslate => 'Traduire';

  @override
  String get aiUnavailable =>
      'L\'IA n\'a pas pu traiter la demande ; les informations sans IA restent affichées.';

  @override
  String get aiUsage => 'Consommation';

  @override
  String get aiUsageCache => 'Cache';

  @override
  String get aiUsageCalls => 'Appels';

  @override
  String get aiUsageDay => 'Jour';

  @override
  String get aiUsageEmpty => 'Aucun appel pour l\'instant.';

  @override
  String get aiUsageErrors => 'Erreurs';

  @override
  String get aiUsageHelp =>
      '30 derniers jours, par fournisseur. Les jetons sont ceux déclarés par le fournisseur.';

  @override
  String get aiUsageProvider => 'Fournisseur';

  @override
  String get aiUsageRules => 'Repli sans IA';

  @override
  String get aiUsageTokens => 'Jetons';

  @override
  String get aiWithout => 'Continuer sans IA';

  @override
  String get commonRefresh => 'Actualiser';

  @override
  String get cvUseAi => 'Analyser avec l\'IA';

  @override
  String get cvUseAiHelp =>
      'Le texte du CV est envoyé sans nom, courriel, téléphone ni liens ; chaque élément reste à valider.';

  @override
  String get genFromTemplate => 'Modèle intégré';

  @override
  String get genFromTemplateHelp =>
      'Rédigé localement à partir de votre profil.';

  @override
  String get genWithAi => 'Rédiger avec l\'IA';

  @override
  String get genWithAiHelp =>
      'À partir de votre profil anonymisé ; les ajouts non présents dans le profil sont signalés.';

  @override
  String get provUnverifiable => 'Non vérifiable';

  @override
  String get settingsAi => 'IA';
}
