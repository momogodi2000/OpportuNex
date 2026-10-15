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
}
