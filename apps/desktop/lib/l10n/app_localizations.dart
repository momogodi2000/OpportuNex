import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Opportunex'**
  String get appName;

  /// No description provided for @slogan.
  ///
  /// In fr, this message translates to:
  /// **'Trouvez · Analysez · Réalisez'**
  String get slogan;

  /// No description provided for @tagline.
  ///
  /// In fr, this message translates to:
  /// **'Votre assistant pour les opportunités publiques et privées'**
  String get tagline;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get commonConfirm;

  /// No description provided for @commonContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get commonContinue;

  /// No description provided for @commonBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get commonBack;

  /// No description provided for @commonSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get commonEdit;

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// No description provided for @commonCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get commonCopy;

  /// No description provided for @commonCopied.
  ///
  /// In fr, this message translates to:
  /// **'Copié dans le presse-papiers'**
  String get commonCopied;

  /// No description provided for @commonLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get commonLoading;

  /// No description provided for @commonOptional.
  ///
  /// In fr, this message translates to:
  /// **'facultatif'**
  String get commonOptional;

  /// No description provided for @commonShow.
  ///
  /// In fr, this message translates to:
  /// **'Afficher'**
  String get commonShow;

  /// No description provided for @commonHide.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get commonHide;

  /// No description provided for @commonYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get commonNo;

  /// No description provided for @commonDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get commonDone;

  /// No description provided for @commonSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get commonSearch;

  /// No description provided for @commonNotSpecified.
  ///
  /// In fr, this message translates to:
  /// **'Non précisé'**
  String get commonNotSpecified;

  /// No description provided for @commonUnknownError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue est survenue. Réessayez ; si le problème persiste, exportez les journaux depuis Paramètres › Maintenance.'**
  String get commonUnknownError;

  /// No description provided for @startupStarting.
  ///
  /// In fr, this message translates to:
  /// **'Démarrage du moteur local…'**
  String get startupStarting;

  /// No description provided for @startupRestarting.
  ///
  /// In fr, this message translates to:
  /// **'Le moteur s\'est arrêté. Redémarrage (tentative {attempt} sur 3)…'**
  String startupRestarting(int attempt);

  /// No description provided for @diagTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le moteur local n\'a pas pu démarrer'**
  String get diagTitle;

  /// No description provided for @diagNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Le moteur Opportunex est introuvable. Réinstallez l\'application ou, en développement, exécutez « launch-dev.ps1 -Setup ».'**
  String get diagNotFound;

  /// No description provided for @diagAlreadyRunning.
  ///
  /// In fr, this message translates to:
  /// **'Opportunex est déjà ouvert pour cet utilisateur. Fermez l\'autre fenêtre avant de réessayer.'**
  String get diagAlreadyRunning;

  /// No description provided for @diagHandshake.
  ///
  /// In fr, this message translates to:
  /// **'Le moteur n\'a pas répondu à temps. Votre antivirus bloque peut-être son lancement.'**
  String get diagHandshake;

  /// No description provided for @diagCrashed.
  ///
  /// In fr, this message translates to:
  /// **'Le moteur s\'est arrêté plusieurs fois de suite.'**
  String get diagCrashed;

  /// No description provided for @diagHealth.
  ///
  /// In fr, this message translates to:
  /// **'Le moteur a démarré mais ne répond pas aux vérifications.'**
  String get diagHealth;

  /// No description provided for @diagDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails techniques'**
  String get diagDetails;

  /// No description provided for @diagExportLogs.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le dossier des journaux'**
  String get diagExportLogs;

  /// No description provided for @diagRetry.
  ///
  /// In fr, this message translates to:
  /// **'Relancer le moteur'**
  String get diagRetry;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get authWelcomeTitle;

  /// No description provided for @authWelcomeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos données restent sur cet ordinateur, chiffrées.'**
  String get authWelcomeSubtitle;

  /// No description provided for @authChooseProfile.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre profil'**
  String get authChooseProfile;

  /// No description provided for @authNewProfile.
  ///
  /// In fr, this message translates to:
  /// **'Créer un profil'**
  String get authNewProfile;

  /// No description provided for @authOtherAccount.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec un autre courriel'**
  String get authOtherAccount;

  /// No description provided for @authImportProfile.
  ///
  /// In fr, this message translates to:
  /// **'Importer un profil depuis une sauvegarde'**
  String get authImportProfile;

  /// No description provided for @authEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse électronique'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get authConfirmPassword;

  /// No description provided for @authDisplayName.
  ///
  /// In fr, this message translates to:
  /// **'Nom affiché'**
  String get authDisplayName;

  /// No description provided for @authLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get authLanguage;

  /// No description provided for @authSignIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authSignIn;

  /// No description provided for @authSignInTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get authSignInTitle;

  /// No description provided for @authForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get authForgotPassword;

  /// No description provided for @authCreateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get authCreateAccount;

  /// No description provided for @authRegisterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer votre profil local'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Un profil est chiffré avec votre mot de passe. Personne d\'autre, pas même ETS Monthe Network, ne peut le lire.'**
  String get authRegisterSubtitle;

  /// No description provided for @authAcceptTerms.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte les conditions d\'utilisation et la politique de confidentialité'**
  String get authAcceptTerms;

  /// No description provided for @authReadTerms.
  ///
  /// In fr, this message translates to:
  /// **'Lire les conditions'**
  String get authReadTerms;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai déjà un profil'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'12 caractères minimum. Une phrase de plusieurs mots est idéale.'**
  String get authPasswordHint;

  /// No description provided for @authStrength0.
  ///
  /// In fr, this message translates to:
  /// **'Très faible'**
  String get authStrength0;

  /// No description provided for @authStrength1.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get authStrength1;

  /// No description provided for @authStrength2.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get authStrength2;

  /// No description provided for @authStrength3.
  ///
  /// In fr, this message translates to:
  /// **'Bon'**
  String get authStrength3;

  /// No description provided for @authStrength4.
  ///
  /// In fr, this message translates to:
  /// **'Excellent'**
  String get authStrength4;

  /// No description provided for @authPhraseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre phrase de récupération'**
  String get authPhraseTitle;

  /// No description provided for @authPhraseBody.
  ///
  /// In fr, this message translates to:
  /// **'Notez ces 12 mots dans l\'ordre et conservez-les hors de l\'ordinateur. Ils sont le seul moyen de récupérer vos données si vous oubliez votre mot de passe. Ils ne seront plus jamais affichés.'**
  String get authPhraseBody;

  /// No description provided for @authPhraseConfirm.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai noté ma phrase de récupération en lieu sûr'**
  String get authPhraseConfirm;

  /// No description provided for @authUnlockTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil verrouillé'**
  String get authUnlockTitle;

  /// No description provided for @authUnlockInactivity.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillé après une période d\'inactivité.'**
  String get authUnlockInactivity;

  /// No description provided for @authUnlockManual.
  ///
  /// In fr, this message translates to:
  /// **'Profil verrouillé.'**
  String get authUnlockManual;

  /// No description provided for @authUnlockExpired.
  ///
  /// In fr, this message translates to:
  /// **'Votre session a expiré.'**
  String get authUnlockExpired;

  /// No description provided for @authUnlock.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller'**
  String get authUnlock;

  /// No description provided for @authSwitchProfile.
  ///
  /// In fr, this message translates to:
  /// **'Changer de profil'**
  String get authSwitchProfile;

  /// No description provided for @authRecoverTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer votre profil'**
  String get authRecoverTitle;

  /// No description provided for @authRecoverBody.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez les 12 mots de votre phrase de récupération, puis choisissez un nouveau mot de passe.'**
  String get authRecoverBody;

  /// No description provided for @authRecoveryPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Phrase de récupération (12 mots)'**
  String get authRecoveryPhrase;

  /// No description provided for @authNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get authNewPassword;

  /// No description provided for @authRecover.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer et se connecter'**
  String get authRecover;

  /// No description provided for @authLock.
  ///
  /// In fr, this message translates to:
  /// **'Verrouiller'**
  String get authLock;

  /// No description provided for @authSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get authSignOut;

  /// No description provided for @authModeLocal.
  ///
  /// In fr, this message translates to:
  /// **'Mode local'**
  String get authModeLocal;

  /// No description provided for @authModeSynced.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisé'**
  String get authModeSynced;

  /// No description provided for @authLockedFor.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Réessayez dans {seconds} s.'**
  String authLockedFor(int seconds);

  /// No description provided for @validationRequired.
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire'**
  String get validationRequired;

  /// No description provided for @validationEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse électronique invalide'**
  String get validationEmail;

  /// No description provided for @validationPasswordMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get validationPasswordMatch;

  /// No description provided for @validationPhraseWords.
  ///
  /// In fr, this message translates to:
  /// **'La phrase doit contenir exactement 12 mots'**
  String get validationPhraseWords;

  /// No description provided for @navDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get navDashboard;

  /// No description provided for @navSearch.
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get navSearch;

  /// No description provided for @navSaved.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardées'**
  String get navSaved;

  /// No description provided for @navApplications.
  ///
  /// In fr, this message translates to:
  /// **'Candidatures'**
  String get navApplications;

  /// No description provided for @navMonitors.
  ///
  /// In fr, this message translates to:
  /// **'Veilles'**
  String get navMonitors;

  /// No description provided for @navWorkspaces.
  ///
  /// In fr, this message translates to:
  /// **'Espaces'**
  String get navWorkspaces;

  /// No description provided for @navSources.
  ///
  /// In fr, this message translates to:
  /// **'Sources'**
  String get navSources;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get navProfile;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get navSettings;

  /// No description provided for @navCollapse.
  ///
  /// In fr, this message translates to:
  /// **'Réduire le menu'**
  String get navCollapse;

  /// No description provided for @navExpand.
  ///
  /// In fr, this message translates to:
  /// **'Déployer le menu'**
  String get navExpand;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Adresse ou mot de passe incorrect.'**
  String get errInvalidCredentials;

  /// No description provided for @errAccountLocked.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives échouées. Patientez avant de réessayer.'**
  String get errAccountLocked;

  /// No description provided for @errEmailTaken.
  ///
  /// In fr, this message translates to:
  /// **'Un profil utilise déjà cette adresse sur cet ordinateur.'**
  String get errEmailTaken;

  /// No description provided for @errPasswordPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop faible : 12 caractères minimum, non présent dans la liste des mots de passe compromis.'**
  String get errPasswordPolicy;

  /// No description provided for @errPasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas.'**
  String get errPasswordMismatch;

  /// No description provided for @errTermsNotAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez accepter les conditions d\'utilisation.'**
  String get errTermsNotAccepted;

  /// No description provided for @errInvalidRecovery.
  ///
  /// In fr, this message translates to:
  /// **'Phrase de récupération incorrecte.'**
  String get errInvalidRecovery;

  /// No description provided for @errSessionLocked.
  ///
  /// In fr, this message translates to:
  /// **'Votre session est verrouillée.'**
  String get errSessionLocked;

  /// No description provided for @errEngineUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Le moteur local ne répond pas. Il redémarre peut-être.'**
  String get errEngineUnreachable;

  /// No description provided for @errValidation.
  ///
  /// In fr, this message translates to:
  /// **'Certains champs sont invalides.'**
  String get errValidation;

  /// No description provided for @errNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Élément introuvable.'**
  String get errNotFound;

  /// No description provided for @errProfileCorrupted.
  ///
  /// In fr, this message translates to:
  /// **'Le profil ne peut pas être déchiffré. Restaurez une sauvegarde.'**
  String get errProfileCorrupted;

  /// No description provided for @errUpstream.
  ///
  /// In fr, this message translates to:
  /// **'Le service externe est indisponible pour le moment.'**
  String get errUpstream;

  /// No description provided for @settingsAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte et sécurité'**
  String get settingsAccount;

  /// No description provided for @settingsBackups.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardes'**
  String get settingsBackups;

  /// No description provided for @settingsMaintenance.
  ///
  /// In fr, this message translates to:
  /// **'Maintenance'**
  String get settingsMaintenance;

  /// No description provided for @settingsAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get settingsAbout;

  /// No description provided for @settingsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Modifications enregistrées'**
  String get settingsSaved;

  /// No description provided for @settingsProfileSection.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get settingsProfileSection;

  /// No description provided for @settingsModeLocalHelp.
  ///
  /// In fr, this message translates to:
  /// **'Vos données restent uniquement sur cet ordinateur.'**
  String get settingsModeLocalHelp;

  /// No description provided for @settingsModeSyncedHelp.
  ///
  /// In fr, this message translates to:
  /// **'Vos données sont chiffrées de bout en bout et synchronisées entre vos appareils.'**
  String get settingsModeSyncedHelp;

  /// No description provided for @settingsAppearance.
  ///
  /// In fr, this message translates to:
  /// **'Langue et apparence'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get settingsThemeDark;

  /// No description provided for @settingsSecurity.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get settingsSecurity;

  /// No description provided for @settingsAutoLock.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage automatique'**
  String get settingsAutoLock;

  /// No description provided for @settingsAutoLockHelp.
  ///
  /// In fr, this message translates to:
  /// **'Après cette durée d\'inactivité, le profil se verrouille et la clé de chiffrement est effacée de la mémoire.'**
  String get settingsAutoLockHelp;

  /// No description provided for @settingsMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String settingsMinutes(int minutes);

  /// No description provided for @settingsChangePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get settingsChangePassword;

  /// No description provided for @settingsChangePasswordHelp.
  ///
  /// In fr, this message translates to:
  /// **'Vos données restent chiffrées ; seule l\'enveloppe de la clé est renouvelée.'**
  String get settingsChangePasswordHelp;

  /// No description provided for @settingsCurrentPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get settingsCurrentPassword;

  /// No description provided for @settingsPasswordChanged.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié'**
  String get settingsPasswordChanged;

  /// No description provided for @settingsDangerZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone sensible'**
  String get settingsDangerZone;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountHelp.
  ///
  /// In fr, this message translates to:
  /// **'Efface définitivement de cet ordinateur le profil, la base chiffrée, les documents et les sauvegardes.'**
  String get settingsDeleteAccountHelp;

  /// No description provided for @settingsDeleteAccountConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible : toutes vos données locales seront supprimées. Tapez DELETE pour confirmer.'**
  String get settingsDeleteAccountConfirm;

  /// No description provided for @settingsConfirmWithPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez avec votre mot de passe'**
  String get settingsConfirmWithPassword;

  /// No description provided for @backupsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardes'**
  String get backupsTitle;

  /// No description provided for @backupsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Archives chiffrées de votre base et de vos documents. Les 7 dernières sauvegardes automatiques sont conservées.'**
  String get backupsHelp;

  /// No description provided for @backupsCreate.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder maintenant'**
  String get backupsCreate;

  /// No description provided for @backupsCreated.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde créée'**
  String get backupsCreated;

  /// No description provided for @backupsAuto.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde automatique quotidienne'**
  String get backupsAuto;

  /// No description provided for @backupsAutoHelp.
  ///
  /// In fr, this message translates to:
  /// **'Effectuée quand l\'application est ouverte, au plus une fois par jour.'**
  String get backupsAutoHelp;

  /// No description provided for @backupsFolder.
  ///
  /// In fr, this message translates to:
  /// **'Dossier des sauvegardes'**
  String get backupsFolder;

  /// No description provided for @backupsHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get backupsHistory;

  /// No description provided for @backupsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sauvegarde pour le moment.'**
  String get backupsEmpty;

  /// No description provided for @backupsOkTag.
  ///
  /// In fr, this message translates to:
  /// **'intègre'**
  String get backupsOkTag;

  /// No description provided for @backupsRestoredTag.
  ///
  /// In fr, this message translates to:
  /// **'restaurée'**
  String get backupsRestoredTag;

  /// No description provided for @backupsVerify.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier l\'intégrité'**
  String get backupsVerify;

  /// No description provided for @backupsVerified.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde vérifiée : intègre'**
  String get backupsVerified;

  /// No description provided for @backupsRestore.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer'**
  String get backupsRestore;

  /// No description provided for @backupsRestoreConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Vos données actuelles seront remplacées par celles de la sauvegarde. Une sauvegarde de sécurité est d\'abord créée. Tapez RESTORE pour confirmer.'**
  String get backupsRestoreConfirm;

  /// No description provided for @backupsRestored.
  ///
  /// In fr, this message translates to:
  /// **'Restauration terminée'**
  String get backupsRestored;

  /// No description provided for @backupsDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la sauvegarde'**
  String get backupsDelete;

  /// No description provided for @backupsDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier de sauvegarde sera supprimé définitivement.'**
  String get backupsDeleteConfirm;

  /// No description provided for @backupsDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde supprimée'**
  String get backupsDeleted;

  /// No description provided for @backupKindManual.
  ///
  /// In fr, this message translates to:
  /// **'manuelle'**
  String get backupKindManual;

  /// No description provided for @backupKindScheduled.
  ///
  /// In fr, this message translates to:
  /// **'automatique'**
  String get backupKindScheduled;

  /// No description provided for @backupKindPreMigration.
  ///
  /// In fr, this message translates to:
  /// **'avant mise à jour'**
  String get backupKindPreMigration;

  /// No description provided for @backupKindPreRestore.
  ///
  /// In fr, this message translates to:
  /// **'avant restauration'**
  String get backupKindPreRestore;

  /// No description provided for @maintenanceStorage.
  ///
  /// In fr, this message translates to:
  /// **'Espace utilisé'**
  String get maintenanceStorage;

  /// No description provided for @maintenanceDatabase.
  ///
  /// In fr, this message translates to:
  /// **'Base de données'**
  String get maintenanceDatabase;

  /// No description provided for @maintenanceVault.
  ///
  /// In fr, this message translates to:
  /// **'Documents chiffrés'**
  String get maintenanceVault;

  /// No description provided for @maintenanceDataDir.
  ///
  /// In fr, this message translates to:
  /// **'Dossier des données'**
  String get maintenanceDataDir;

  /// No description provided for @maintenanceTools.
  ///
  /// In fr, this message translates to:
  /// **'Outils'**
  String get maintenanceTools;

  /// No description provided for @maintenanceRun.
  ///
  /// In fr, this message translates to:
  /// **'Lancer'**
  String get maintenanceRun;

  /// No description provided for @maintenanceIntegrity.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle d\'intégrité'**
  String get maintenanceIntegrity;

  /// No description provided for @maintenanceIntegrityHelp.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie la base, les clés étrangères et l\'index de recherche.'**
  String get maintenanceIntegrityHelp;

  /// No description provided for @maintenanceIntegrityOk.
  ///
  /// In fr, this message translates to:
  /// **'Aucun problème détecté'**
  String get maintenanceIntegrityOk;

  /// No description provided for @maintenanceOptimize.
  ///
  /// In fr, this message translates to:
  /// **'Optimiser la base'**
  String get maintenanceOptimize;

  /// No description provided for @maintenanceOptimizeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Compacte la base et optimise l\'index de recherche.'**
  String get maintenanceOptimizeHelp;

  /// No description provided for @maintenanceOptimized.
  ///
  /// In fr, this message translates to:
  /// **'Base optimisée'**
  String get maintenanceOptimized;

  /// No description provided for @maintenanceLogs.
  ///
  /// In fr, this message translates to:
  /// **'Journaux techniques'**
  String get maintenanceLogs;

  /// No description provided for @maintenanceLogsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Exporte les journaux expurgés (sans courriel, jeton ni clé) pour l\'assistance.'**
  String get maintenanceLogsHelp;

  /// No description provided for @maintenanceExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get maintenanceExport;

  /// No description provided for @maintenanceLogsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Journaux exportés'**
  String get maintenanceLogsSaved;

  /// No description provided for @aboutVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @aboutEngine.
  ///
  /// In fr, this message translates to:
  /// **'moteur'**
  String get aboutEngine;

  /// No description provided for @aboutSchema.
  ///
  /// In fr, this message translates to:
  /// **'schéma'**
  String get aboutSchema;

  /// No description provided for @aboutCredits.
  ///
  /// In fr, this message translates to:
  /// **'Éditeur et auteur'**
  String get aboutCredits;

  /// No description provided for @aboutPublisher.
  ///
  /// In fr, this message translates to:
  /// **'Éditeur'**
  String get aboutPublisher;

  /// No description provided for @aboutAuthor.
  ///
  /// In fr, this message translates to:
  /// **'Développeur principal'**
  String get aboutAuthor;

  /// No description provided for @aboutCopyright.
  ///
  /// In fr, this message translates to:
  /// **'Droit d\'auteur'**
  String get aboutCopyright;

  /// No description provided for @aboutLicense.
  ///
  /// In fr, this message translates to:
  /// **'Licence'**
  String get aboutLicense;

  /// No description provided for @aboutLicenseBody.
  ///
  /// In fr, this message translates to:
  /// **'Opportunex est un logiciel libre et gratuit, distribué sous la licence GNU Affero General Public License v3. Vous pouvez l\'utiliser, l\'étudier, le modifier et le redistribuer selon les termes de cette licence. Le nom et le logo Opportunex restent réservés.'**
  String get aboutLicenseBody;

  /// No description provided for @aboutSourceCode.
  ///
  /// In fr, this message translates to:
  /// **'Code source'**
  String get aboutSourceCode;

  /// No description provided for @aboutThirdParty.
  ///
  /// In fr, this message translates to:
  /// **'Licences des composants tiers'**
  String get aboutThirdParty;

  /// No description provided for @aboutTermsPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Conditions et confidentialité'**
  String get aboutTermsPrivacy;

  /// No description provided for @legalTerms.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get legalTerms;

  /// No description provided for @legalPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get legalPrivacy;

  /// No description provided for @importProfileBody.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un fichier de sauvegarde Opportunex (.opxbak) et saisissez le mot de passe du profil sauvegardé.'**
  String get importProfileBody;

  /// No description provided for @importChooseFile.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une sauvegarde…'**
  String get importChooseFile;

  /// No description provided for @importAction.
  ///
  /// In fr, this message translates to:
  /// **'Importer et se connecter'**
  String get importAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
