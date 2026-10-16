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

  /// No description provided for @badgeAiGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Généré par IA'**
  String get badgeAiGenerated;

  /// No description provided for @badgeDeadlineSoon.
  ///
  /// In fr, this message translates to:
  /// **'Échéance proche'**
  String get badgeDeadlineSoon;

  /// No description provided for @badgeDeadlineUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Date limite inconnue'**
  String get badgeDeadlineUnknown;

  /// No description provided for @badgeEligibilityUncertain.
  ///
  /// In fr, this message translates to:
  /// **'Éligibilité incertaine'**
  String get badgeEligibilityUncertain;

  /// No description provided for @badgeExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expirée'**
  String get badgeExpired;

  /// No description provided for @badgeModified.
  ///
  /// In fr, this message translates to:
  /// **'Modifiée'**
  String get badgeModified;

  /// No description provided for @badgeNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle'**
  String get badgeNew;

  /// No description provided for @badgeVerified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiée'**
  String get badgeVerified;

  /// No description provided for @scoreLabel.
  ///
  /// In fr, this message translates to:
  /// **'Pertinence {score} sur 100'**
  String scoreLabel(int score);

  /// No description provided for @catAcceleration.
  ///
  /// In fr, this message translates to:
  /// **'Incubation et accélération'**
  String get catAcceleration;

  /// No description provided for @catCall.
  ///
  /// In fr, this message translates to:
  /// **'Appels à candidatures'**
  String get catCall;

  /// No description provided for @catCompetition.
  ///
  /// In fr, this message translates to:
  /// **'Concours et prix'**
  String get catCompetition;

  /// No description provided for @catEmployment.
  ///
  /// In fr, this message translates to:
  /// **'Emploi'**
  String get catEmployment;

  /// No description provided for @catEntrepreneurship.
  ///
  /// In fr, this message translates to:
  /// **'Entrepreneuriat'**
  String get catEntrepreneurship;

  /// No description provided for @catFreelance.
  ///
  /// In fr, this message translates to:
  /// **'Missions freelance'**
  String get catFreelance;

  /// No description provided for @catGrant.
  ///
  /// In fr, this message translates to:
  /// **'Subventions et financements'**
  String get catGrant;

  /// No description provided for @catInternship.
  ///
  /// In fr, this message translates to:
  /// **'Stages'**
  String get catInternship;

  /// No description provided for @catOther.
  ///
  /// In fr, this message translates to:
  /// **'Autres opportunités'**
  String get catOther;

  /// No description provided for @catPartnership.
  ///
  /// In fr, this message translates to:
  /// **'Partenariats'**
  String get catPartnership;

  /// No description provided for @catResearch.
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get catResearch;

  /// No description provided for @catScholarship.
  ///
  /// In fr, this message translates to:
  /// **'Bourses'**
  String get catScholarship;

  /// No description provided for @catTender.
  ///
  /// In fr, this message translates to:
  /// **'Appels d\'offres'**
  String get catTender;

  /// No description provided for @catTraining.
  ///
  /// In fr, this message translates to:
  /// **'Formations'**
  String get catTraining;

  /// No description provided for @catVolunteering.
  ///
  /// In fr, this message translates to:
  /// **'Volontariat'**
  String get catVolunteering;

  /// No description provided for @critDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Date limite'**
  String get critDeadline;

  /// No description provided for @critEducation.
  ///
  /// In fr, this message translates to:
  /// **'Formation'**
  String get critEducation;

  /// No description provided for @critExperience.
  ///
  /// In fr, this message translates to:
  /// **'Expérience'**
  String get critExperience;

  /// No description provided for @critLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langues'**
  String get critLanguage;

  /// No description provided for @critLocation.
  ///
  /// In fr, this message translates to:
  /// **'Localisation'**
  String get critLocation;

  /// No description provided for @critNotEvaluated.
  ///
  /// In fr, this message translates to:
  /// **'Critère non évalué faute d\'information'**
  String get critNotEvaluated;

  /// No description provided for @critObjectives.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs'**
  String get critObjectives;

  /// No description provided for @critSkills.
  ///
  /// In fr, this message translates to:
  /// **'Compétences'**
  String get critSkills;

  /// No description provided for @daysLeft.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{dernier jour} =1{1 jour restant} other{{days} jours restants}}'**
  String daysLeft(int days);

  /// No description provided for @deadlineUnknownShort.
  ///
  /// In fr, this message translates to:
  /// **'Date limite non précisée'**
  String get deadlineUnknownShort;

  /// No description provided for @eligLikely.
  ///
  /// In fr, this message translates to:
  /// **'Éligibilité probable (selon les critères publiés)'**
  String get eligLikely;

  /// No description provided for @eligNot.
  ///
  /// In fr, this message translates to:
  /// **'Non éligible : date limite dépassée'**
  String get eligNot;

  /// No description provided for @eligUncertain.
  ///
  /// In fr, this message translates to:
  /// **'Éligibilité à vérifier'**
  String get eligUncertain;

  /// No description provided for @eligUnlikely.
  ///
  /// In fr, this message translates to:
  /// **'Éligibilité peu probable'**
  String get eligUnlikely;

  /// No description provided for @exportAction.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get exportAction;

  /// No description provided for @exportDone.
  ///
  /// In fr, this message translates to:
  /// **'Export enregistré'**
  String get exportDone;

  /// No description provided for @filterAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get filterAdd;

  /// No description provided for @filterAddKeyword.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un mot-clé'**
  String get filterAddKeyword;

  /// No description provided for @filterAmountMin.
  ///
  /// In fr, this message translates to:
  /// **'Montant minimal'**
  String get filterAmountMin;

  /// No description provided for @filterAnyBadge.
  ///
  /// In fr, this message translates to:
  /// **'Tous les signalements'**
  String get filterAnyBadge;

  /// No description provided for @filterAnyDate.
  ///
  /// In fr, this message translates to:
  /// **'Toute date'**
  String get filterAnyDate;

  /// No description provided for @filterAnyScore.
  ///
  /// In fr, this message translates to:
  /// **'Toute pertinence'**
  String get filterAnyScore;

  /// No description provided for @filterBadge.
  ///
  /// In fr, this message translates to:
  /// **'Signalement'**
  String get filterBadge;

  /// No description provided for @filterCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get filterCategories;

  /// No description provided for @filterCountries.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get filterCountries;

  /// No description provided for @filterDeadlineBefore.
  ///
  /// In fr, this message translates to:
  /// **'Date limite avant le'**
  String get filterDeadlineBefore;

  /// No description provided for @filterIncludeExpired.
  ///
  /// In fr, this message translates to:
  /// **'Inclure les expirées'**
  String get filterIncludeExpired;

  /// No description provided for @filterKeywords.
  ///
  /// In fr, this message translates to:
  /// **'Mots-clés'**
  String get filterKeywords;

  /// No description provided for @filterMinScore.
  ///
  /// In fr, this message translates to:
  /// **'Pertinence minimale'**
  String get filterMinScore;

  /// No description provided for @filterWorkMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode de travail'**
  String get filterWorkMode;

  /// No description provided for @filtersSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Voici comment Opportunex a compris votre demande. Corrigez librement avant de lancer la recherche.'**
  String get filtersSubtitle;

  /// No description provided for @filtersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Critères de recherche'**
  String get filtersTitle;

  /// No description provided for @gapEducation.
  ///
  /// In fr, this message translates to:
  /// **'Niveau d\'études demandé : {value}'**
  String gapEducation(String value);

  /// No description provided for @gapExperience.
  ///
  /// In fr, this message translates to:
  /// **'Expérience demandée : {value} an(s)'**
  String gapExperience(String value);

  /// No description provided for @gapLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue demandée : {value}'**
  String gapLanguage(String value);

  /// No description provided for @gapLocation.
  ///
  /// In fr, this message translates to:
  /// **'Localisation : {value}'**
  String gapLocation(String value);

  /// No description provided for @gapSkills.
  ///
  /// In fr, this message translates to:
  /// **'Compétences absentes de votre profil : {value}'**
  String gapSkills(String value);

  /// No description provided for @historyClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer l\'historique'**
  String get historyClear;

  /// No description provided for @historyClearConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Les recherches non enregistrées seront supprimées. Les recherches enregistrées sont conservées.'**
  String get historyClearConfirm;

  /// No description provided for @historyEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recherche pour le moment.'**
  String get historyEmpty;

  /// No description provided for @historyHint.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez une recherche pour la relancer plus tard ou en faire une veille.'**
  String get historyHint;

  /// No description provided for @historyOpen.
  ///
  /// In fr, this message translates to:
  /// **'Voir les résultats'**
  String get historyOpen;

  /// No description provided for @historyRerun.
  ///
  /// In fr, this message translates to:
  /// **'Relancer'**
  String get historyRerun;

  /// No description provided for @historySave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la recherche'**
  String get historySave;

  /// No description provided for @historyUnsave.
  ///
  /// In fr, this message translates to:
  /// **'Ne plus enregistrer'**
  String get historyUnsave;

  /// No description provided for @loadMore.
  ///
  /// In fr, this message translates to:
  /// **'Afficher plus'**
  String get loadMore;

  /// No description provided for @oppAddWorkspace.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à un espace'**
  String get oppAddWorkspace;

  /// No description provided for @oppAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get oppAmount;

  /// No description provided for @oppApplicationUrl.
  ///
  /// In fr, this message translates to:
  /// **'Lien de candidature'**
  String get oppApplicationUrl;

  /// No description provided for @oppContact.
  ///
  /// In fr, this message translates to:
  /// **'Contact public'**
  String get oppContact;

  /// No description provided for @oppDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Date limite'**
  String get oppDeadline;

  /// No description provided for @oppDismiss.
  ///
  /// In fr, this message translates to:
  /// **'Écarter'**
  String get oppDismiss;

  /// No description provided for @oppDocumentsRequired.
  ///
  /// In fr, this message translates to:
  /// **'Pièces à fournir'**
  String get oppDocumentsRequired;

  /// No description provided for @oppEligibility.
  ///
  /// In fr, this message translates to:
  /// **'Éligibilité'**
  String get oppEligibility;

  /// No description provided for @oppFeedbackThanks.
  ///
  /// In fr, this message translates to:
  /// **'Merci, vos recommandations seront ajustées'**
  String get oppFeedbackThanks;

  /// No description provided for @oppFinancial.
  ///
  /// In fr, this message translates to:
  /// **'Avantages financiers'**
  String get oppFinancial;

  /// No description provided for @oppFullText.
  ///
  /// In fr, this message translates to:
  /// **'Texte complet de l\'annonce'**
  String get oppFullText;

  /// No description provided for @oppGaps.
  ///
  /// In fr, this message translates to:
  /// **'Écarts et points à vérifier'**
  String get oppGaps;

  /// No description provided for @oppLastChecked.
  ///
  /// In fr, this message translates to:
  /// **'Dernière vérification'**
  String get oppLastChecked;

  /// No description provided for @oppLocation.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get oppLocation;

  /// No description provided for @oppMethod.
  ///
  /// In fr, this message translates to:
  /// **'Méthode d\'analyse'**
  String get oppMethod;

  /// No description provided for @oppMethodRules.
  ///
  /// In fr, this message translates to:
  /// **'Règles déterministes (sans IA)'**
  String get oppMethodRules;

  /// No description provided for @oppMore.
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'actions'**
  String get oppMore;

  /// No description provided for @oppNoCriteria.
  ///
  /// In fr, this message translates to:
  /// **'L\'annonce ne publie pas de critères d\'éligibilité précis : vérifiez auprès de l\'éditeur.'**
  String get oppNoCriteria;

  /// No description provided for @oppNoGaps.
  ///
  /// In fr, this message translates to:
  /// **'Aucun écart détecté avec votre profil.'**
  String get oppNoGaps;

  /// No description provided for @oppNotRelevant.
  ///
  /// In fr, this message translates to:
  /// **'Non pertinent'**
  String get oppNotRelevant;

  /// No description provided for @oppOfficialLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien officiel'**
  String get oppOfficialLink;

  /// No description provided for @oppOpenTracking.
  ///
  /// In fr, this message translates to:
  /// **'Voir le suivi'**
  String get oppOpenTracking;

  /// No description provided for @oppOriginalPublisher.
  ///
  /// In fr, this message translates to:
  /// **'Éditeur d\'origine'**
  String get oppOriginalPublisher;

  /// No description provided for @oppOverview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get oppOverview;

  /// No description provided for @oppProcedure.
  ///
  /// In fr, this message translates to:
  /// **'Procédure'**
  String get oppProcedure;

  /// No description provided for @oppPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publiée le'**
  String get oppPublished;

  /// No description provided for @oppPublisher.
  ///
  /// In fr, this message translates to:
  /// **'Éditeur et sources'**
  String get oppPublisher;

  /// No description provided for @oppQualifications.
  ///
  /// In fr, this message translates to:
  /// **'Qualifications demandées'**
  String get oppQualifications;

  /// No description provided for @oppRecheck.
  ///
  /// In fr, this message translates to:
  /// **'Revérifier sur le site officiel'**
  String get oppRecheck;

  /// No description provided for @oppRechecked.
  ///
  /// In fr, this message translates to:
  /// **'Vérification terminée'**
  String get oppRechecked;

  /// No description provided for @oppRelevance.
  ///
  /// In fr, this message translates to:
  /// **'Pertinence pour vous'**
  String get oppRelevance;

  /// No description provided for @oppRelevant.
  ///
  /// In fr, this message translates to:
  /// **'Pertinent'**
  String get oppRelevant;

  /// No description provided for @oppRepost.
  ///
  /// In fr, this message translates to:
  /// **'Republication'**
  String get oppRepost;

  /// No description provided for @oppSave.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder'**
  String get oppSave;

  /// No description provided for @oppSaved.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardée'**
  String get oppSaved;

  /// No description provided for @oppSavedToast.
  ///
  /// In fr, this message translates to:
  /// **'Opportunité sauvegardée'**
  String get oppSavedToast;

  /// No description provided for @oppStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get oppStatus;

  /// No description provided for @oppStrengths.
  ///
  /// In fr, this message translates to:
  /// **'Vos atouts'**
  String get oppStrengths;

  /// No description provided for @oppSubmissionNotice.
  ///
  /// In fr, this message translates to:
  /// **'Opportunex ne soumet jamais de candidature : postulez sur le canal officiel de l\'éditeur.'**
  String get oppSubmissionNotice;

  /// No description provided for @oppSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé'**
  String get oppSummary;

  /// No description provided for @oppToVerify.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier vous-même'**
  String get oppToVerify;

  /// No description provided for @oppVerbatimNote.
  ///
  /// In fr, this message translates to:
  /// **'Clauses reproduites mot pour mot depuis l\'annonce.'**
  String get oppVerbatimNote;

  /// No description provided for @oppVerification.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get oppVerification;

  /// No description provided for @provExplicit.
  ///
  /// In fr, this message translates to:
  /// **'Explicite'**
  String get provExplicit;

  /// No description provided for @provGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Généré'**
  String get provGenerated;

  /// No description provided for @provInferred.
  ///
  /// In fr, this message translates to:
  /// **'Déduit'**
  String get provInferred;

  /// No description provided for @reqEducation.
  ///
  /// In fr, this message translates to:
  /// **'Formation'**
  String get reqEducation;

  /// No description provided for @reqExperience.
  ///
  /// In fr, this message translates to:
  /// **'Expérience'**
  String get reqExperience;

  /// No description provided for @reqLanguages.
  ///
  /// In fr, this message translates to:
  /// **'Langues'**
  String get reqLanguages;

  /// No description provided for @reqSkills.
  ///
  /// In fr, this message translates to:
  /// **'Compétences'**
  String get reqSkills;

  /// No description provided for @resultsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun résultat} =1{1 résultat} other{{count} résultats}}'**
  String resultsCount(int count);

  /// No description provided for @resultsEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Élargissez vos critères ou ajoutez des sources dans la section Sources.'**
  String get resultsEmptyBody;

  /// No description provided for @resultsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opportunité ne correspond'**
  String get resultsEmptyTitle;

  /// No description provided for @runCancelled.
  ///
  /// In fr, this message translates to:
  /// **'annulée'**
  String get runCancelled;

  /// No description provided for @runCompleted.
  ///
  /// In fr, this message translates to:
  /// **'terminée'**
  String get runCompleted;

  /// No description provided for @runFailed.
  ///
  /// In fr, this message translates to:
  /// **'échouée'**
  String get runFailed;

  /// No description provided for @runPartial.
  ///
  /// In fr, this message translates to:
  /// **'terminée partiellement'**
  String get runPartial;

  /// No description provided for @runProgress.
  ///
  /// In fr, this message translates to:
  /// **'Recherche en cours : {done} source(s) sur {total}'**
  String runProgress(int done, int total);

  /// No description provided for @runResume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get runResume;

  /// No description provided for @runStatus.
  ///
  /// In fr, this message translates to:
  /// **'Recherche {status}'**
  String runStatus(String status);

  /// No description provided for @runUnavailableBody.
  ///
  /// In fr, this message translates to:
  /// **'Ces sources n\'ont pas pu être consultées automatiquement ou ne le permettent pas. Consultez-les directement :'**
  String get runUnavailableBody;

  /// No description provided for @runUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sources à consulter manuellement'**
  String get runUnavailableTitle;

  /// No description provided for @searchEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez ce que vous cherchez en français ou en anglais, par exemple « bourse de master en France » ou « stage en informatique à Douala ».'**
  String get searchEmptyBody;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Que recherchez-vous ?'**
  String get searchEmptyTitle;

  /// No description provided for @searchHelper.
  ///
  /// In fr, this message translates to:
  /// **'Recherche en langage naturel, en français ou en anglais'**
  String get searchHelper;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : bourse de master en santé publique pour 2027'**
  String get searchHint;

  /// No description provided for @searchInterpret.
  ///
  /// In fr, this message translates to:
  /// **'Analyser'**
  String get searchInterpret;

  /// No description provided for @searchLaunch.
  ///
  /// In fr, this message translates to:
  /// **'Lancer la recherche'**
  String get searchLaunch;

  /// No description provided for @searchSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions'**
  String get searchSuggestions;

  /// No description provided for @searchTabHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get searchTabHistory;

  /// No description provided for @searchTabNew.
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get searchTabNew;

  /// No description provided for @sortAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get sortAmount;

  /// No description provided for @sortDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Date limite'**
  String get sortDeadline;

  /// No description provided for @sortPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publication'**
  String get sortPublished;

  /// No description provided for @sortRecent.
  ///
  /// In fr, this message translates to:
  /// **'Ajout récent'**
  String get sortRecent;

  /// No description provided for @sortRelevance.
  ///
  /// In fr, this message translates to:
  /// **'Pertinence'**
  String get sortRelevance;

  /// No description provided for @sourcesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} sources'**
  String sourcesCount(int count);

  /// No description provided for @workHybrid.
  ///
  /// In fr, this message translates to:
  /// **'Hybride'**
  String get workHybrid;

  /// No description provided for @workOnsite.
  ///
  /// In fr, this message translates to:
  /// **'Présentiel'**
  String get workOnsite;

  /// No description provided for @workRemote.
  ///
  /// In fr, this message translates to:
  /// **'À distance'**
  String get workRemote;

  /// No description provided for @wsAdded.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutée à l\'espace'**
  String get wsAdded;

  /// No description provided for @wsNoneYet.
  ///
  /// In fr, this message translates to:
  /// **'Créez d\'abord un espace dans la section Espaces.'**
  String get wsNoneYet;

  /// No description provided for @calDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Date limite officielle'**
  String get calDeadline;

  /// No description provided for @calEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune échéance ce mois-ci.'**
  String get calEmpty;

  /// No description provided for @calExportIcs.
  ///
  /// In fr, this message translates to:
  /// **'Exporter le calendrier (.ics)'**
  String get calExportIcs;

  /// No description provided for @calNext.
  ///
  /// In fr, this message translates to:
  /// **'Mois suivant'**
  String get calNext;

  /// No description provided for @calPersonalDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Échéance personnelle'**
  String get calPersonalDeadline;

  /// No description provided for @calPrev.
  ///
  /// In fr, this message translates to:
  /// **'Mois précédent'**
  String get calPrev;

  /// No description provided for @cvAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get cvAccept;

  /// No description provided for @cvApplied.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun élément ajouté au profil} =1{1 élément ajouté au profil} other{{count} éléments ajoutés au profil}}'**
  String cvApplied(int count);

  /// No description provided for @cvApply.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au profil'**
  String get cvApply;

  /// No description provided for @cvConfidence.
  ///
  /// In fr, this message translates to:
  /// **'Confiance de l\'extraction : {pct} %'**
  String cvConfidence(int pct);

  /// No description provided for @cvDiscard.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner l\'import'**
  String get cvDiscard;

  /// No description provided for @cvIdentity.
  ///
  /// In fr, this message translates to:
  /// **'Identité'**
  String get cvIdentity;

  /// No description provided for @cvImport.
  ///
  /// In fr, this message translates to:
  /// **'Importer un CV'**
  String get cvImport;

  /// No description provided for @cvKeepFile.
  ///
  /// In fr, this message translates to:
  /// **'Conserver le fichier du CV'**
  String get cvKeepFile;

  /// No description provided for @cvKeepFileHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier est chiffré dans votre coffre local. Sinon il est supprimé après l\'analyse.'**
  String get cvKeepFileHelp;

  /// No description provided for @cvNothingFound.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'a pu être extrait'**
  String get cvNothingFound;

  /// No description provided for @cvNothingFoundBody.
  ///
  /// In fr, this message translates to:
  /// **'Le document est peut-être scanné (image) ou protégé. Vous pouvez remplir votre profil manuellement.'**
  String get cvNothingFoundBody;

  /// No description provided for @cvPick.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier'**
  String get cvPick;

  /// No description provided for @cvPickBody.
  ///
  /// In fr, this message translates to:
  /// **'PDF, DOCX ou TXT, 10 Mo maximum. L\'analyse se fait sur cet ordinateur, sans envoi en ligne.'**
  String get cvPickBody;

  /// No description provided for @cvPickTitle.
  ///
  /// In fr, this message translates to:
  /// **'Importer votre CV'**
  String get cvPickTitle;

  /// No description provided for @cvReject.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter'**
  String get cvReject;

  /// No description provided for @cvReviewHelp.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez chaque élément détecté : acceptez, corrigez ou rejetez. Seuls les éléments acceptés seront ajoutés.'**
  String get cvReviewHelp;

  /// No description provided for @cvSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Pré-remplissez votre profil à partir d\'un CV existant'**
  String get cvSubtitle;

  /// No description provided for @dashActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activité récente'**
  String get dashActivity;

  /// No description provided for @dashApplications.
  ///
  /// In fr, this message translates to:
  /// **'Candidatures par statut'**
  String get dashApplications;

  /// No description provided for @dashDeadlines.
  ///
  /// In fr, this message translates to:
  /// **'Échéances à venir'**
  String get dashDeadlines;

  /// No description provided for @dashDiscovered.
  ///
  /// In fr, this message translates to:
  /// **'Découvertes'**
  String get dashDiscovered;

  /// No description provided for @dashFirstStepsBody.
  ///
  /// In fr, this message translates to:
  /// **'Quelques étapes pour obtenir des résultats pertinents.'**
  String get dashFirstStepsBody;

  /// No description provided for @dashFirstStepsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Premiers pas'**
  String get dashFirstStepsTitle;

  /// No description provided for @dashFollowUp.
  ///
  /// In fr, this message translates to:
  /// **'Relance conseillée : {title}'**
  String dashFollowUp(String title);

  /// No description provided for @dashHello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name}'**
  String dashHello(String name);

  /// No description provided for @dashInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get dashInProgress;

  /// No description provided for @dashManage.
  ///
  /// In fr, this message translates to:
  /// **'Gérer'**
  String get dashManage;

  /// No description provided for @dashNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles'**
  String get dashNew;

  /// No description provided for @dashNewSearch.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle recherche'**
  String get dashNewSearch;

  /// No description provided for @dashNoActivity.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité pour le moment.'**
  String get dashNoActivity;

  /// No description provided for @dashNoApplications.
  ///
  /// In fr, this message translates to:
  /// **'Aucune candidature suivie.'**
  String get dashNoApplications;

  /// No description provided for @dashNoDeadlines.
  ///
  /// In fr, this message translates to:
  /// **'Aucune échéance dans les 30 prochains jours.'**
  String get dashNoDeadlines;

  /// No description provided for @dashNoRecommendations.
  ///
  /// In fr, this message translates to:
  /// **'Lancez une recherche pour obtenir des recommandations.'**
  String get dashNoRecommendations;

  /// No description provided for @dashNoStats.
  ///
  /// In fr, this message translates to:
  /// **'Les statistiques apparaîtront après vos premières candidatures.'**
  String get dashNoStats;

  /// No description provided for @dashRecommendations.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations'**
  String get dashRecommendations;

  /// No description provided for @dashRecommendationsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Opportunités ouvertes les mieux classées pour votre profil (score indicatif).'**
  String get dashRecommendationsHelp;

  /// No description provided for @dashRelevant.
  ///
  /// In fr, this message translates to:
  /// **'Pertinentes'**
  String get dashRelevant;

  /// No description provided for @dashSaved.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardées'**
  String get dashSaved;

  /// No description provided for @dashSourceFailing.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 échec consécutif} other{{count} échecs consécutifs}}'**
  String dashSourceFailing(int count);

  /// No description provided for @dashSources.
  ///
  /// In fr, this message translates to:
  /// **'État des sources'**
  String get dashSources;

  /// No description provided for @dashSourcesSummary.
  ///
  /// In fr, this message translates to:
  /// **'{active} actives, {healthy} en bon état, {total} au total'**
  String dashSourcesSummary(int active, int healthy, int total);

  /// No description provided for @dashStatAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Acceptées : {count}'**
  String dashStatAccepted(int count);

  /// No description provided for @dashStatDelay.
  ///
  /// In fr, this message translates to:
  /// **'Délai moyen de réponse : {days} jours'**
  String dashStatDelay(String days);

  /// No description provided for @dashStatRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux d\'acceptation : {rate}'**
  String dashStatRate(String rate);

  /// No description provided for @dashStatSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Soumises : {count}'**
  String dashStatSubmitted(int count);

  /// No description provided for @dashStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques personnelles'**
  String get dashStats;

  /// No description provided for @dashStepCv.
  ///
  /// In fr, this message translates to:
  /// **'Importer un CV'**
  String get dashStepCv;

  /// No description provided for @dashStepMonitor.
  ///
  /// In fr, this message translates to:
  /// **'Créer une veille'**
  String get dashStepMonitor;

  /// No description provided for @dashStepProfile.
  ///
  /// In fr, this message translates to:
  /// **'Compléter le profil'**
  String get dashStepProfile;

  /// No description provided for @dashStepSearch.
  ///
  /// In fr, this message translates to:
  /// **'Lancer une recherche'**
  String get dashStepSearch;

  /// No description provided for @dashSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Soumises'**
  String get dashSubmitted;

  /// No description provided for @dashSubmittedOn.
  ///
  /// In fr, this message translates to:
  /// **'Soumise le {date}'**
  String dashSubmittedOn(String date);

  /// No description provided for @dashSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble de vos opportunités et candidatures'**
  String get dashSubtitle;

  /// No description provided for @dashWithin.
  ///
  /// In fr, this message translates to:
  /// **'{days} jours : {count}'**
  String dashWithin(int days, int count);

  /// No description provided for @dayFri.
  ///
  /// In fr, this message translates to:
  /// **'Vendredi'**
  String get dayFri;

  /// No description provided for @dayMon.
  ///
  /// In fr, this message translates to:
  /// **'Lundi'**
  String get dayMon;

  /// No description provided for @daySat.
  ///
  /// In fr, this message translates to:
  /// **'Samedi'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In fr, this message translates to:
  /// **'Dimanche'**
  String get daySun;

  /// No description provided for @dayThu.
  ///
  /// In fr, this message translates to:
  /// **'Jeudi'**
  String get dayThu;

  /// No description provided for @dayTue.
  ///
  /// In fr, this message translates to:
  /// **'Mardi'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In fr, this message translates to:
  /// **'Mercredi'**
  String get dayWed;

  /// No description provided for @docCoverLetter.
  ///
  /// In fr, this message translates to:
  /// **'Lettre de motivation'**
  String get docCoverLetter;

  /// No description provided for @docCvSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions d\'adaptation du CV'**
  String get docCvSuggestions;

  /// No description provided for @docEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail de candidature'**
  String get docEmail;

  /// No description provided for @docGrant.
  ///
  /// In fr, this message translates to:
  /// **'Demande de subvention'**
  String get docGrant;

  /// No description provided for @docInterview.
  ///
  /// In fr, this message translates to:
  /// **'Préparation d\'entretien'**
  String get docInterview;

  /// No description provided for @docProjectSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé de projet'**
  String get docProjectSummary;

  /// No description provided for @docScholarship.
  ///
  /// In fr, this message translates to:
  /// **'Lettre de candidature à une bourse'**
  String get docScholarship;

  /// No description provided for @edBac.
  ///
  /// In fr, this message translates to:
  /// **'Baccalauréat'**
  String get edBac;

  /// No description provided for @edBac2.
  ///
  /// In fr, this message translates to:
  /// **'Bac+2 (BTS, DUT, HND)'**
  String get edBac2;

  /// No description provided for @edBachelor.
  ///
  /// In fr, this message translates to:
  /// **'Licence / Bachelor'**
  String get edBachelor;

  /// No description provided for @edDoctorate.
  ///
  /// In fr, this message translates to:
  /// **'Doctorat'**
  String get edDoctorate;

  /// No description provided for @edMaster.
  ///
  /// In fr, this message translates to:
  /// **'Master'**
  String get edMaster;

  /// No description provided for @edNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun diplôme'**
  String get edNone;

  /// No description provided for @edPostdoc.
  ///
  /// In fr, this message translates to:
  /// **'Post-doctorat'**
  String get edPostdoc;

  /// No description provided for @edPrimary.
  ///
  /// In fr, this message translates to:
  /// **'Primaire'**
  String get edPrimary;

  /// No description provided for @edSecondary.
  ///
  /// In fr, this message translates to:
  /// **'Secondaire'**
  String get edSecondary;

  /// No description provided for @edVocational.
  ///
  /// In fr, this message translates to:
  /// **'Formation professionnelle'**
  String get edVocational;

  /// No description provided for @eraseAction.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la sélection'**
  String get eraseAction;

  /// No description provided for @eraseConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Les données sélectionnées seront supprimées définitivement de cet ordinateur. Saisissez ERASE pour confirmer.'**
  String get eraseConfirm;

  /// No description provided for @eraseDocuments.
  ///
  /// In fr, this message translates to:
  /// **'Documents joints aux candidatures'**
  String get eraseDocuments;

  /// No description provided for @eraseDone.
  ///
  /// In fr, this message translates to:
  /// **'Données effacées'**
  String get eraseDone;

  /// No description provided for @eraseHelp.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez précisément ce que vous voulez supprimer. Votre compte et vos candidatures sont conservés.'**
  String get eraseHelp;

  /// No description provided for @eraseHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des recherches non enregistrées'**
  String get eraseHistory;

  /// No description provided for @eraseLogs.
  ///
  /// In fr, this message translates to:
  /// **'Journaux techniques'**
  String get eraseLogs;

  /// No description provided for @eraseNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get eraseNotifications;

  /// No description provided for @eraseOpportunities.
  ///
  /// In fr, this message translates to:
  /// **'Opportunités non sauvegardées'**
  String get eraseOpportunities;

  /// No description provided for @eraseProfile.
  ///
  /// In fr, this message translates to:
  /// **'Détails du profil (formation, expérience, compétences…)'**
  String get eraseProfile;

  /// No description provided for @eraseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Effacement sélectif'**
  String get eraseTitle;

  /// No description provided for @etConsulting.
  ///
  /// In fr, this message translates to:
  /// **'Conseil'**
  String get etConsulting;

  /// No description provided for @etFreelance.
  ///
  /// In fr, this message translates to:
  /// **'Freelance'**
  String get etFreelance;

  /// No description provided for @etFullTime.
  ///
  /// In fr, this message translates to:
  /// **'Temps plein'**
  String get etFullTime;

  /// No description provided for @etInternship.
  ///
  /// In fr, this message translates to:
  /// **'Stage'**
  String get etInternship;

  /// No description provided for @etPartTime.
  ///
  /// In fr, this message translates to:
  /// **'Temps partiel'**
  String get etPartTime;

  /// No description provided for @etVolunteer.
  ///
  /// In fr, this message translates to:
  /// **'Bénévolat'**
  String get etVolunteer;

  /// No description provided for @evCall.
  ///
  /// In fr, this message translates to:
  /// **'Appel'**
  String get evCall;

  /// No description provided for @evFollowUp.
  ///
  /// In fr, this message translates to:
  /// **'Relance'**
  String get evFollowUp;

  /// No description provided for @evInterview.
  ///
  /// In fr, this message translates to:
  /// **'Entretien'**
  String get evInterview;

  /// No description provided for @evMeeting.
  ///
  /// In fr, this message translates to:
  /// **'Rendez-vous'**
  String get evMeeting;

  /// No description provided for @evOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get evOther;

  /// No description provided for @evTest.
  ///
  /// In fr, this message translates to:
  /// **'Test'**
  String get evTest;

  /// No description provided for @genCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer un brouillon'**
  String get genCreate;

  /// No description provided for @genEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun brouillon pour cette opportunité.'**
  String get genEmpty;

  /// No description provided for @genIntegrityTitle.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier : éléments absents de votre profil validé'**
  String get genIntegrityTitle;

  /// No description provided for @genNotice.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon généré à partir de votre profil validé. Relisez-le et adaptez-le avant tout envoi.'**
  String get genNotice;

  /// No description provided for @genSaveVersion.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer une version'**
  String get genSaveVersion;

  /// No description provided for @genSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Brouillons modifiables, avec historique des versions'**
  String get genSubtitle;

  /// No description provided for @genTitle.
  ///
  /// In fr, this message translates to:
  /// **'Documents générés'**
  String get genTitle;

  /// No description provided for @monCreate.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle veille'**
  String get monCreate;

  /// No description provided for @monDaily.
  ///
  /// In fr, this message translates to:
  /// **'Tous les jours à {time}'**
  String monDaily(String time);

  /// No description provided for @monDailyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Quotidienne'**
  String get monDailyLabel;

  /// No description provided for @monEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Une veille relance une recherche à intervalle régulier et vous signale les nouveautés.'**
  String get monEmptyBody;

  /// No description provided for @monEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune veille'**
  String get monEmptyTitle;

  /// No description provided for @monFrequencyNote.
  ///
  /// In fr, this message translates to:
  /// **'La fréquence réelle respecte les limites de chaque source (au plus une fois par jour en général).'**
  String get monFrequencyNote;

  /// No description provided for @monLastRun.
  ///
  /// In fr, this message translates to:
  /// **'Dernière exécution : {date} · {count} nouvelles'**
  String monLastRun(String date, int count);

  /// No description provided for @monMinScore.
  ///
  /// In fr, this message translates to:
  /// **'Score minimal pour être notifié : {score}'**
  String monMinScore(int score);

  /// No description provided for @monName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la veille'**
  String get monName;

  /// No description provided for @monNextRun.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine exécution : {date}'**
  String monNextRun(String date);

  /// No description provided for @monOnlyWhileOpen.
  ///
  /// In fr, this message translates to:
  /// **'Les veilles s\'exécutent uniquement lorsque Opportunex est ouvert (y compris réduit dans la zone de notification).'**
  String get monOnlyWhileOpen;

  /// No description provided for @monQuery.
  ///
  /// In fr, this message translates to:
  /// **'Recherche à surveiller'**
  String get monQuery;

  /// No description provided for @monRunNow.
  ///
  /// In fr, this message translates to:
  /// **'Exécuter maintenant'**
  String get monRunNow;

  /// No description provided for @monScheduleSummary.
  ///
  /// In fr, this message translates to:
  /// **'{schedule} · score minimal {score}'**
  String monScheduleSummary(String schedule, int score);

  /// No description provided for @monStarted.
  ///
  /// In fr, this message translates to:
  /// **'Veille lancée'**
  String get monStarted;

  /// No description provided for @monTabMonitors.
  ///
  /// In fr, this message translates to:
  /// **'Veilles'**
  String get monTabMonitors;

  /// No description provided for @monTabNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get monTabNotifications;

  /// No description provided for @monWeekly.
  ///
  /// In fr, this message translates to:
  /// **'Chaque semaine : {when}'**
  String monWeekly(String when);

  /// No description provided for @monWeeklyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Hebdomadaire'**
  String get monWeeklyLabel;

  /// No description provided for @nkChanged.
  ///
  /// In fr, this message translates to:
  /// **'Opportunité suivie modifiée'**
  String get nkChanged;

  /// No description provided for @nkDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Rappels d\'échéance'**
  String get nkDeadline;

  /// No description provided for @nkMonitor.
  ///
  /// In fr, this message translates to:
  /// **'Échec d\'une veille'**
  String get nkMonitor;

  /// No description provided for @nkNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles opportunités'**
  String get nkNew;

  /// No description provided for @nkSource.
  ///
  /// In fr, this message translates to:
  /// **'Source indisponible'**
  String get nkSource;

  /// No description provided for @notifEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get notifEmpty;

  /// No description provided for @notifMarkAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer comme lu'**
  String get notifMarkAllRead;

  /// No description provided for @onbDone.
  ///
  /// In fr, this message translates to:
  /// **'Profil enregistré. Bienvenue !'**
  String get onbDone;

  /// No description provided for @onbFinish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get onbFinish;

  /// No description provided for @onbLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get onbLater;

  /// No description provided for @onbOptionalNote.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les étapes sont facultatives et modifiables à tout moment depuis votre profil.'**
  String get onbOptionalNote;

  /// No description provided for @onbResume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre la configuration'**
  String get onbResume;

  /// No description provided for @onbSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onbSkip;

  /// No description provided for @onbStep1.
  ///
  /// In fr, this message translates to:
  /// **'Informations générales et liens'**
  String get onbStep1;

  /// No description provided for @onbStep2.
  ///
  /// In fr, this message translates to:
  /// **'Formation'**
  String get onbStep2;

  /// No description provided for @onbStep3.
  ///
  /// In fr, this message translates to:
  /// **'Expérience'**
  String get onbStep3;

  /// No description provided for @onbStep4.
  ///
  /// In fr, this message translates to:
  /// **'Compétences et langues'**
  String get onbStep4;

  /// No description provided for @onbStep5.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs'**
  String get onbStep5;

  /// No description provided for @onbStep6.
  ///
  /// In fr, this message translates to:
  /// **'Projet ou organisation'**
  String get onbStep6;

  /// No description provided for @onbStep7.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get onbStep7;

  /// No description provided for @onbStepOf.
  ///
  /// In fr, this message translates to:
  /// **'Étape {step} sur {total} — {title}'**
  String onbStepOf(int step, int total, String title);

  /// No description provided for @onbTitle.
  ///
  /// In fr, this message translates to:
  /// **'Configurer votre profil'**
  String get onbTitle;

  /// No description provided for @orgAcademic.
  ///
  /// In fr, this message translates to:
  /// **'Établissement académique'**
  String get orgAcademic;

  /// No description provided for @orgAssociation.
  ///
  /// In fr, this message translates to:
  /// **'Association'**
  String get orgAssociation;

  /// No description provided for @orgBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget annuel'**
  String get orgBudget;

  /// No description provided for @orgCooperative.
  ///
  /// In fr, this message translates to:
  /// **'Coopérative / GIC'**
  String get orgCooperative;

  /// No description provided for @orgHelp.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez-la si vous cherchez des opportunités au nom d\'une structure.'**
  String get orgHelp;

  /// No description provided for @orgName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'organisation'**
  String get orgName;

  /// No description provided for @orgNgo.
  ///
  /// In fr, this message translates to:
  /// **'ONG'**
  String get orgNgo;

  /// No description provided for @orgNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune organisation renseignée.'**
  String get orgNone;

  /// No description provided for @orgPublic.
  ///
  /// In fr, this message translates to:
  /// **'Organisme public'**
  String get orgPublic;

  /// No description provided for @orgRegistration.
  ///
  /// In fr, this message translates to:
  /// **'Numéro d\'immatriculation (RCCM…)'**
  String get orgRegistration;

  /// No description provided for @orgSector.
  ///
  /// In fr, this message translates to:
  /// **'Secteur d\'activité'**
  String get orgSector;

  /// No description provided for @orgSme.
  ///
  /// In fr, this message translates to:
  /// **'PME'**
  String get orgSme;

  /// No description provided for @orgStartup.
  ///
  /// In fr, this message translates to:
  /// **'Start-up'**
  String get orgStartup;

  /// No description provided for @orgTitle.
  ///
  /// In fr, this message translates to:
  /// **'Organisation'**
  String get orgTitle;

  /// No description provided for @orgType.
  ///
  /// In fr, this message translates to:
  /// **'Type d\'organisation'**
  String get orgType;

  /// No description provided for @pfAchievements.
  ///
  /// In fr, this message translates to:
  /// **'Réalisations'**
  String get pfAchievements;

  /// No description provided for @pfAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get pfAdd;

  /// No description provided for @pfAddLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une langue'**
  String get pfAddLanguage;

  /// No description provided for @pfAddLink.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un lien'**
  String get pfAddLink;

  /// No description provided for @pfAddSkill.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une compétence'**
  String get pfAddSkill;

  /// No description provided for @pfAnyMode.
  ///
  /// In fr, this message translates to:
  /// **'Indifférent'**
  String get pfAnyMode;

  /// No description provided for @pfBeneficiaries.
  ///
  /// In fr, this message translates to:
  /// **'Bénéficiaires'**
  String get pfBeneficiaries;

  /// No description provided for @pfBio.
  ///
  /// In fr, this message translates to:
  /// **'Présentation'**
  String get pfBio;

  /// No description provided for @pfCertName.
  ///
  /// In fr, this message translates to:
  /// **'Intitulé de la certification'**
  String get pfCertName;

  /// No description provided for @pfCertifications.
  ///
  /// In fr, this message translates to:
  /// **'Certifications'**
  String get pfCertifications;

  /// No description provided for @pfCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get pfCity;

  /// No description provided for @pfCompleteness.
  ///
  /// In fr, this message translates to:
  /// **'Profil complété à {pct} %'**
  String pfCompleteness(int pct);

  /// No description provided for @pfCountry.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get pfCountry;

  /// No description provided for @pfCredentialUrl.
  ///
  /// In fr, this message translates to:
  /// **'Lien de vérification'**
  String get pfCredentialUrl;

  /// No description provided for @pfCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise'**
  String get pfCurrency;

  /// No description provided for @pfCurrentJob.
  ///
  /// In fr, this message translates to:
  /// **'Poste actuel'**
  String get pfCurrentJob;

  /// No description provided for @pfCustomObjective.
  ///
  /// In fr, this message translates to:
  /// **'Autre objectif…'**
  String get pfCustomObjective;

  /// No description provided for @pfDegree.
  ///
  /// In fr, this message translates to:
  /// **'Diplôme'**
  String get pfDegree;

  /// No description provided for @pfEducation.
  ///
  /// In fr, this message translates to:
  /// **'Formation'**
  String get pfEducation;

  /// No description provided for @pfEducationLevel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau d\'études le plus élevé'**
  String get pfEducationLevel;

  /// No description provided for @pfEmployer.
  ///
  /// In fr, this message translates to:
  /// **'Employeur'**
  String get pfEmployer;

  /// No description provided for @pfEmploymentType.
  ///
  /// In fr, this message translates to:
  /// **'Type de contrat'**
  String get pfEmploymentType;

  /// No description provided for @pfEnd.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get pfEnd;

  /// No description provided for @pfExperience.
  ///
  /// In fr, this message translates to:
  /// **'Expérience'**
  String get pfExperience;

  /// No description provided for @pfExperienceYears.
  ///
  /// In fr, this message translates to:
  /// **'Années d\'expérience'**
  String get pfExperienceYears;

  /// No description provided for @pfExpiresOn.
  ///
  /// In fr, this message translates to:
  /// **'Expire le'**
  String get pfExpiresOn;

  /// No description provided for @pfField.
  ///
  /// In fr, this message translates to:
  /// **'Domaine d\'études'**
  String get pfField;

  /// No description provided for @pfFullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get pfFullName;

  /// No description provided for @pfFundingHelp.
  ///
  /// In fr, this message translates to:
  /// **'Montant entier dans la devise choisie (en centimes pour EUR et USD).'**
  String get pfFundingHelp;

  /// No description provided for @pfFundingMax.
  ///
  /// In fr, this message translates to:
  /// **'Financement maximal recherché'**
  String get pfFundingMax;

  /// No description provided for @pfFundingMin.
  ///
  /// In fr, this message translates to:
  /// **'Financement minimal recherché'**
  String get pfFundingMin;

  /// No description provided for @pfGeneral.
  ///
  /// In fr, this message translates to:
  /// **'Informations générales'**
  String get pfGeneral;

  /// No description provided for @pfGrade.
  ///
  /// In fr, this message translates to:
  /// **'Mention'**
  String get pfGrade;

  /// No description provided for @pfImproveHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour des résultats plus pertinents, complétez :'**
  String get pfImproveHint;

  /// No description provided for @pfInstitution.
  ///
  /// In fr, this message translates to:
  /// **'Établissement'**
  String get pfInstitution;

  /// No description provided for @pfIssuer.
  ///
  /// In fr, this message translates to:
  /// **'Organisme émetteur'**
  String get pfIssuer;

  /// No description provided for @pfJobTitle.
  ///
  /// In fr, this message translates to:
  /// **'Intitulé du poste'**
  String get pfJobTitle;

  /// No description provided for @pfLanguages.
  ///
  /// In fr, this message translates to:
  /// **'Langues'**
  String get pfLanguages;

  /// No description provided for @pfLegalStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut juridique'**
  String get pfLegalStatus;

  /// No description provided for @pfLinkKind.
  ///
  /// In fr, this message translates to:
  /// **'Type de lien'**
  String get pfLinkKind;

  /// No description provided for @pfLinks.
  ///
  /// In fr, this message translates to:
  /// **'Liens'**
  String get pfLinks;

  /// No description provided for @pfLinksLocations.
  ///
  /// In fr, this message translates to:
  /// **'Liens et localisations'**
  String get pfLinksLocations;

  /// No description provided for @pfMissingEducation.
  ///
  /// In fr, this message translates to:
  /// **'votre formation'**
  String get pfMissingEducation;

  /// No description provided for @pfMissingExperience.
  ///
  /// In fr, this message translates to:
  /// **'votre expérience'**
  String get pfMissingExperience;

  /// No description provided for @pfMissingIdentity.
  ///
  /// In fr, this message translates to:
  /// **'votre nom et votre pays'**
  String get pfMissingIdentity;

  /// No description provided for @pfMissingLanguages.
  ///
  /// In fr, this message translates to:
  /// **'vos langues'**
  String get pfMissingLanguages;

  /// No description provided for @pfMissingObjectives.
  ///
  /// In fr, this message translates to:
  /// **'vos objectifs'**
  String get pfMissingObjectives;

  /// No description provided for @pfMissingPreferences.
  ///
  /// In fr, this message translates to:
  /// **'vos préférences de localisation'**
  String get pfMissingPreferences;

  /// No description provided for @pfMissingSkills.
  ///
  /// In fr, this message translates to:
  /// **'vos compétences'**
  String get pfMissingSkills;

  /// No description provided for @pfMissingStatus.
  ///
  /// In fr, this message translates to:
  /// **'votre situation professionnelle'**
  String get pfMissingStatus;

  /// No description provided for @pfMissions.
  ///
  /// In fr, this message translates to:
  /// **'Missions principales'**
  String get pfMissions;

  /// No description provided for @pfNative.
  ///
  /// In fr, this message translates to:
  /// **'Langue maternelle'**
  String get pfNative;

  /// No description provided for @pfNothingYet.
  ///
  /// In fr, this message translates to:
  /// **'Rien pour le moment.'**
  String get pfNothingYet;

  /// No description provided for @pfObjectives.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs'**
  String get pfObjectives;

  /// No description provided for @pfObjectivesHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ce que vous recherchez : ils orientent les recherches et le classement.'**
  String get pfObjectivesHelp;

  /// No description provided for @pfObtainedOn.
  ///
  /// In fr, this message translates to:
  /// **'Obtenu le'**
  String get pfObtainedOn;

  /// No description provided for @pfOccupation.
  ///
  /// In fr, this message translates to:
  /// **'Occupation actuelle'**
  String get pfOccupation;

  /// No description provided for @pfOngoing.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get pfOngoing;

  /// No description provided for @pfPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get pfPhone;

  /// No description provided for @pfPhoneHelp.
  ///
  /// In fr, this message translates to:
  /// **'Utilisé uniquement dans les brouillons de documents que vous générez.'**
  String get pfPhoneHelp;

  /// No description provided for @pfPortfolio.
  ///
  /// In fr, this message translates to:
  /// **'Portfolio'**
  String get pfPortfolio;

  /// No description provided for @pfPreferredLocations.
  ///
  /// In fr, this message translates to:
  /// **'Localisations recherchées'**
  String get pfPreferredLocations;

  /// No description provided for @pfProjectDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get pfProjectDescription;

  /// No description provided for @pfProjectTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nom du projet'**
  String get pfProjectTitle;

  /// No description provided for @pfProjects.
  ///
  /// In fr, this message translates to:
  /// **'Projets'**
  String get pfProjects;

  /// No description provided for @pfRegionCentralAfrica.
  ///
  /// In fr, this message translates to:
  /// **'Toute l\'Afrique centrale (CEMAC)'**
  String get pfRegionCentralAfrica;

  /// No description provided for @pfRelocate.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à déménager'**
  String get pfRelocate;

  /// No description provided for @pfSkillPrimaryToggle.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme compétence principale'**
  String get pfSkillPrimaryToggle;

  /// No description provided for @pfSkills.
  ///
  /// In fr, this message translates to:
  /// **'Compétences'**
  String get pfSkills;

  /// No description provided for @pfSkillsLanguages.
  ///
  /// In fr, this message translates to:
  /// **'Compétences et langues'**
  String get pfSkillsLanguages;

  /// No description provided for @pfStage.
  ///
  /// In fr, this message translates to:
  /// **'Stade du projet'**
  String get pfStage;

  /// No description provided for @pfStart.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get pfStart;

  /// No description provided for @pfStatus.
  ///
  /// In fr, this message translates to:
  /// **'Situation professionnelle'**
  String get pfStatus;

  /// No description provided for @pfSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ces informations restent sur cet ordinateur et servent au classement des opportunités.'**
  String get pfSubtitle;

  /// No description provided for @pfSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé du profil'**
  String get pfSummary;

  /// No description provided for @pfSummaryApprove.
  ///
  /// In fr, this message translates to:
  /// **'Valider ce résumé'**
  String get pfSummaryApprove;

  /// No description provided for @pfSummaryApproved.
  ///
  /// In fr, this message translates to:
  /// **'Résumé validé'**
  String get pfSummaryApproved;

  /// No description provided for @pfSummaryGenerate.
  ///
  /// In fr, this message translates to:
  /// **'Composer à partir du profil'**
  String get pfSummaryGenerate;

  /// No description provided for @pfSummaryHelp.
  ///
  /// In fr, this message translates to:
  /// **'Résumé composé uniquement à partir de vos informations. Modifiez-le puis validez-le.'**
  String get pfSummaryHelp;

  /// No description provided for @pfTimeline.
  ///
  /// In fr, this message translates to:
  /// **'Durée prévue (mois)'**
  String get pfTimeline;

  /// No description provided for @pfWebsite.
  ///
  /// In fr, this message translates to:
  /// **'Site web'**
  String get pfWebsite;

  /// No description provided for @prefBandwidth.
  ///
  /// In fr, this message translates to:
  /// **'Volume maximal par recherche : {mb} Mo'**
  String prefBandwidth(int mb);

  /// No description provided for @prefDataSaver.
  ///
  /// In fr, this message translates to:
  /// **'Économiseur de données'**
  String get prefDataSaver;

  /// No description provided for @prefDataSaverHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ne télécharge pas les pages de détail ni les pièces jointes pendant la recherche.'**
  String get prefDataSaverHelp;

  /// No description provided for @prefNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Réseau'**
  String get prefNetwork;

  /// No description provided for @prefNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get prefNotifications;

  /// No description provided for @prefProxy.
  ///
  /// In fr, this message translates to:
  /// **'Proxy (facultatif)'**
  String get prefProxy;

  /// No description provided for @prefReminders.
  ///
  /// In fr, this message translates to:
  /// **'Rappels avant échéance'**
  String get prefReminders;

  /// No description provided for @prefRemindersHelp.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de jours avant la date limite, séparés par des virgules (ex. 14, 7, 3, 1).'**
  String get prefRemindersHelp;

  /// No description provided for @prefWeights.
  ///
  /// In fr, this message translates to:
  /// **'Pondération du score'**
  String get prefWeights;

  /// No description provided for @prefWeightsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ajustez l\'importance de chaque critère dans le score de pertinence.'**
  String get prefWeightsHelp;

  /// No description provided for @prioHigh.
  ///
  /// In fr, this message translates to:
  /// **'Haute'**
  String get prioHigh;

  /// No description provided for @prioLow.
  ///
  /// In fr, this message translates to:
  /// **'Basse'**
  String get prioLow;

  /// No description provided for @prioMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne'**
  String get prioMedium;

  /// No description provided for @privConsentAi.
  ///
  /// In fr, this message translates to:
  /// **'Traitement par un service d\'IA'**
  String get privConsentAi;

  /// No description provided for @privConsentSync.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation'**
  String get privConsentSync;

  /// No description provided for @privConsents.
  ///
  /// In fr, this message translates to:
  /// **'Consentements'**
  String get privConsents;

  /// No description provided for @privDisclosures.
  ///
  /// In fr, this message translates to:
  /// **'Données envoyées à des tiers'**
  String get privDisclosures;

  /// No description provided for @privExportAll.
  ///
  /// In fr, this message translates to:
  /// **'Exporter toutes mes données'**
  String get privExportAll;

  /// No description provided for @privImportJson.
  ///
  /// In fr, this message translates to:
  /// **'Importer un export JSON'**
  String get privImportJson;

  /// No description provided for @privImported.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Import terminé} =1{Import terminé : 1 opportunité suivie} other{Import terminé : {count} opportunités suivies}}'**
  String privImported(int count);

  /// No description provided for @privNoDisclosures.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée personnelle n\'a été envoyée à un tiers.'**
  String get privNoDisclosures;

  /// No description provided for @privNoTelemetry.
  ///
  /// In fr, this message translates to:
  /// **'Aucune télémétrie : Opportunex n\'envoie aucune statistique d\'utilisation.'**
  String get privNoTelemetry;

  /// No description provided for @privOpportunities.
  ///
  /// In fr, this message translates to:
  /// **'Opportunités en cache'**
  String get privOpportunities;

  /// No description provided for @privPortability.
  ///
  /// In fr, this message translates to:
  /// **'Portabilité'**
  String get privPortability;

  /// No description provided for @privPortabilityHelp.
  ///
  /// In fr, this message translates to:
  /// **'Archive ZIP lisible (JSON + fichiers) de toutes vos données, ou réimport d\'un export JSON.'**
  String get privPortabilityHelp;

  /// No description provided for @privRevoke.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get privRevoke;

  /// No description provided for @privRevokedOn.
  ///
  /// In fr, this message translates to:
  /// **'retiré le {date}'**
  String privRevokedOn(String date);

  /// No description provided for @privSearches.
  ///
  /// In fr, this message translates to:
  /// **'Recherches'**
  String get privSearches;

  /// No description provided for @privStored.
  ///
  /// In fr, this message translates to:
  /// **'Données stockées'**
  String get privStored;

  /// No description provided for @privStoredHelp.
  ///
  /// In fr, this message translates to:
  /// **'Tout est chiffré dans la base locale de ce profil.'**
  String get privStoredHelp;

  /// No description provided for @psEmployed.
  ///
  /// In fr, this message translates to:
  /// **'Salarié(e)'**
  String get psEmployed;

  /// No description provided for @psEntrepreneur.
  ///
  /// In fr, this message translates to:
  /// **'Entrepreneur(e)'**
  String get psEntrepreneur;

  /// No description provided for @psFreelancer.
  ///
  /// In fr, this message translates to:
  /// **'Freelance'**
  String get psFreelancer;

  /// No description provided for @psJobSeeker.
  ///
  /// In fr, this message translates to:
  /// **'En recherche d\'emploi'**
  String get psJobSeeker;

  /// No description provided for @psOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get psOther;

  /// No description provided for @psResearcher.
  ///
  /// In fr, this message translates to:
  /// **'Chercheur(se)'**
  String get psResearcher;

  /// No description provided for @psRetired.
  ///
  /// In fr, this message translates to:
  /// **'Retraité(e)'**
  String get psRetired;

  /// No description provided for @psSelfEmployed.
  ///
  /// In fr, this message translates to:
  /// **'Indépendant(e)'**
  String get psSelfEmployed;

  /// No description provided for @psStudent.
  ///
  /// In fr, this message translates to:
  /// **'Étudiant(e)'**
  String get psStudent;

  /// No description provided for @psUnemployed.
  ///
  /// In fr, this message translates to:
  /// **'Sans emploi'**
  String get psUnemployed;

  /// No description provided for @srcActive.
  ///
  /// In fr, this message translates to:
  /// **'Actives'**
  String get srcActive;

  /// No description provided for @srcAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une source'**
  String get srcAdd;

  /// No description provided for @srcAddHelp.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez l\'adresse d\'une page publique. Opportunex détecte un flux RSS/Atom et respecte robots.txt.'**
  String get srcAddHelp;

  /// No description provided for @srcAdded.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Source ajoutée (aucun élément détecté pour l\'instant)} =1{Source ajoutée : 1 élément détecté} other{Source ajoutée : {count} éléments détectés}}'**
  String srcAdded(int count);

  /// No description provided for @srcAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get srcAll;

  /// No description provided for @srcCount.
  ///
  /// In fr, this message translates to:
  /// **'{shown} sur {total}'**
  String srcCount(int shown, int total);

  /// No description provided for @srcCustom.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutées par moi'**
  String get srcCustom;

  /// No description provided for @srcDetect.
  ///
  /// In fr, this message translates to:
  /// **'Détecter et ajouter'**
  String get srcDetect;

  /// No description provided for @srcFailing.
  ///
  /// In fr, this message translates to:
  /// **'En échec'**
  String get srcFailing;

  /// No description provided for @srcLastError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String srcLastError(String error);

  /// No description provided for @srcLastSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Dernier succès : {date}'**
  String srcLastSuccess(String date);

  /// No description provided for @srcLinkOnly.
  ///
  /// In fr, this message translates to:
  /// **'Lien officiel uniquement'**
  String get srcLinkOnly;

  /// No description provided for @srcLinks.
  ///
  /// In fr, this message translates to:
  /// **'Liens officiels'**
  String get srcLinks;

  /// No description provided for @srcName.
  ///
  /// In fr, this message translates to:
  /// **'Nom (facultatif)'**
  String get srcName;

  /// No description provided for @srcOppCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 opportunité} other{{count} opportunités}}'**
  String srcOppCount(int count);

  /// No description provided for @srcPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Opportunex n\'interroge que des sources publiques, respecte robots.txt et les conditions d\'utilisation, et espace ses requêtes. Les portails sans flux sont proposés sous forme de lien officiel.'**
  String get srcPolicy;

  /// No description provided for @srcReliability.
  ///
  /// In fr, this message translates to:
  /// **'Fiabilité {pct} %'**
  String srcReliability(int pct);

  /// No description provided for @srcSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue des sources publiques interrogées lors des recherches'**
  String get srcSubtitle;

  /// No description provided for @stAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Acceptée'**
  String get stAccepted;

  /// No description provided for @stArchived.
  ///
  /// In fr, this message translates to:
  /// **'Archivée'**
  String get stArchived;

  /// No description provided for @stDiscovered.
  ///
  /// In fr, this message translates to:
  /// **'Découverte'**
  String get stDiscovered;

  /// No description provided for @stExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expirée'**
  String get stExpired;

  /// No description provided for @stInterview.
  ///
  /// In fr, this message translates to:
  /// **'Entretien'**
  String get stInterview;

  /// No description provided for @stPreparing.
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get stPreparing;

  /// No description provided for @stReady.
  ///
  /// In fr, this message translates to:
  /// **'Prête à soumettre'**
  String get stReady;

  /// No description provided for @stRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get stRejected;

  /// No description provided for @stSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Soumise'**
  String get stSubmitted;

  /// No description provided for @stToReview.
  ///
  /// In fr, this message translates to:
  /// **'À examiner'**
  String get stToReview;

  /// No description provided for @stWithdrawn.
  ///
  /// In fr, this message translates to:
  /// **'Retirée'**
  String get stWithdrawn;

  /// No description provided for @stgEarly.
  ///
  /// In fr, this message translates to:
  /// **'Démarrage'**
  String get stgEarly;

  /// No description provided for @stgEstablished.
  ///
  /// In fr, this message translates to:
  /// **'Établi'**
  String get stgEstablished;

  /// No description provided for @stgGrowth.
  ///
  /// In fr, this message translates to:
  /// **'Croissance'**
  String get stgGrowth;

  /// No description provided for @stgIdea.
  ///
  /// In fr, this message translates to:
  /// **'Idée'**
  String get stgIdea;

  /// No description provided for @stgPrototype.
  ///
  /// In fr, this message translates to:
  /// **'Prototype'**
  String get stgPrototype;

  /// No description provided for @stgScale.
  ///
  /// In fr, this message translates to:
  /// **'Changement d\'échelle'**
  String get stgScale;

  /// No description provided for @trackAddEvent.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un événement'**
  String get trackAddEvent;

  /// No description provided for @trackAddItem.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un élément'**
  String get trackAddItem;

  /// No description provided for @trackAddNote.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une note'**
  String get trackAddNote;

  /// No description provided for @trackAddTag.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une étiquette'**
  String get trackAddTag;

  /// No description provided for @trackAllPriorities.
  ///
  /// In fr, this message translates to:
  /// **'Toutes priorités'**
  String get trackAllPriorities;

  /// No description provided for @trackAllStatuses.
  ///
  /// In fr, this message translates to:
  /// **'Tous statuts'**
  String get trackAllStatuses;

  /// No description provided for @trackAllTags.
  ///
  /// In fr, this message translates to:
  /// **'Toutes étiquettes'**
  String get trackAllTags;

  /// No description provided for @trackArchive.
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get trackArchive;

  /// No description provided for @trackArchived.
  ///
  /// In fr, this message translates to:
  /// **'Archivées'**
  String get trackArchived;

  /// No description provided for @trackAttach.
  ///
  /// In fr, this message translates to:
  /// **'Joindre un fichier'**
  String get trackAttach;

  /// No description provided for @trackBoard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau'**
  String get trackBoard;

  /// No description provided for @trackCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get trackCalendar;

  /// No description provided for @trackChecklist.
  ///
  /// In fr, this message translates to:
  /// **'Liste de contrôle'**
  String get trackChecklist;

  /// No description provided for @trackChecklistEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élément. Les pièces demandées par l\'annonce apparaissent ici quand elles sont connues.'**
  String get trackChecklistEmpty;

  /// No description provided for @trackChecklistProgress.
  ///
  /// In fr, this message translates to:
  /// **'{done} sur {total} terminés'**
  String trackChecklistProgress(int done, int total);

  /// No description provided for @trackDocumentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Libellé du document'**
  String get trackDocumentLabel;

  /// No description provided for @trackDocuments.
  ///
  /// In fr, this message translates to:
  /// **'Documents joints'**
  String get trackDocuments;

  /// No description provided for @trackDocumentsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les fichiers sont chiffrés dans votre coffre local.'**
  String get trackDocumentsHelp;

  /// No description provided for @trackDownload.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer une copie'**
  String get trackDownload;

  /// No description provided for @trackDropHere.
  ///
  /// In fr, this message translates to:
  /// **'Déposer ici'**
  String get trackDropHere;

  /// No description provided for @trackEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegardez des opportunités depuis les résultats de recherche pour les suivre ici.'**
  String get trackEmptyBody;

  /// No description provided for @trackEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opportunité suivie'**
  String get trackEmptyTitle;

  /// No description provided for @trackEventContact.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get trackEventContact;

  /// No description provided for @trackEventLocation.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get trackEventLocation;

  /// No description provided for @trackEventTitle.
  ///
  /// In fr, this message translates to:
  /// **'Intitulé'**
  String get trackEventTitle;

  /// No description provided for @trackEventType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get trackEventType;

  /// No description provided for @trackEventWhen.
  ///
  /// In fr, this message translates to:
  /// **'Date et heure'**
  String get trackEventWhen;

  /// No description provided for @trackEvents.
  ///
  /// In fr, this message translates to:
  /// **'Événements et contacts'**
  String get trackEvents;

  /// No description provided for @trackFromListing.
  ///
  /// In fr, this message translates to:
  /// **'Exigé par l\'annonce'**
  String get trackFromListing;

  /// No description provided for @trackHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get trackHistory;

  /// No description provided for @trackIneligible.
  ///
  /// In fr, this message translates to:
  /// **'Non éligible'**
  String get trackIneligible;

  /// No description provided for @trackIneligibleReason.
  ///
  /// In fr, this message translates to:
  /// **'Raison (facultatif)'**
  String get trackIneligibleReason;

  /// No description provided for @trackInterest.
  ///
  /// In fr, this message translates to:
  /// **'Intérêt'**
  String get trackInterest;

  /// No description provided for @trackInterested.
  ///
  /// In fr, this message translates to:
  /// **'Intéressante'**
  String get trackInterested;

  /// No description provided for @trackList.
  ///
  /// In fr, this message translates to:
  /// **'Liste'**
  String get trackList;

  /// No description provided for @trackNoDocuments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document joint.'**
  String get trackNoDocuments;

  /// No description provided for @trackNoEvents.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement.'**
  String get trackNoEvents;

  /// No description provided for @trackNoPersonalDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Aucune échéance personnelle'**
  String get trackNoPersonalDeadline;

  /// No description provided for @trackNoteHint.
  ///
  /// In fr, this message translates to:
  /// **'Écrire une note…'**
  String get trackNoteHint;

  /// No description provided for @trackNotes.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get trackNotes;

  /// No description provided for @trackOpenSheet.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la fiche'**
  String get trackOpenSheet;

  /// No description provided for @trackPersonalDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Échéance personnelle'**
  String get trackPersonalDeadline;

  /// No description provided for @trackPriority.
  ///
  /// In fr, this message translates to:
  /// **'Priorité'**
  String get trackPriority;

  /// No description provided for @trackReminders.
  ///
  /// In fr, this message translates to:
  /// **'Rappels programmés'**
  String get trackReminders;

  /// No description provided for @trackSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer par titre ou organisme'**
  String get trackSearchHint;

  /// No description provided for @trackSettings.
  ///
  /// In fr, this message translates to:
  /// **'Suivi'**
  String get trackSettings;

  /// No description provided for @trackStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get trackStatus;

  /// No description provided for @trackStatusChanged.
  ///
  /// In fr, this message translates to:
  /// **'Statut mis à jour : {status}'**
  String trackStatusChanged(String status);

  /// No description provided for @trackSubmittedOn.
  ///
  /// In fr, this message translates to:
  /// **'Date de soumission'**
  String get trackSubmittedOn;

  /// No description provided for @trackTag.
  ///
  /// In fr, this message translates to:
  /// **'Étiquette'**
  String get trackTag;

  /// No description provided for @trackUnarchive.
  ///
  /// In fr, this message translates to:
  /// **'Désarchiver'**
  String get trackUnarchive;

  /// No description provided for @trackUndecided.
  ///
  /// In fr, this message translates to:
  /// **'À décider'**
  String get trackUndecided;

  /// No description provided for @trackUnsave.
  ///
  /// In fr, this message translates to:
  /// **'Ne plus suivre'**
  String get trackUnsave;

  /// No description provided for @trackUnsaveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Les notes, documents et l\'historique de cette candidature seront supprimés.'**
  String get trackUnsaveConfirm;

  /// No description provided for @wsCompare.
  ///
  /// In fr, this message translates to:
  /// **'Comparer ({count})'**
  String wsCompare(int count);

  /// No description provided for @wsCounts.
  ///
  /// In fr, this message translates to:
  /// **'{queries} recherches · {saved} suivies · {opportunities} opportunités'**
  String wsCounts(int queries, int saved, int opportunities);

  /// No description provided for @wsCreate.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel espace'**
  String get wsCreate;

  /// No description provided for @wsEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Un espace regroupe des recherches, des opportunités et des notes autour d\'un projet.'**
  String get wsEmptyBody;

  /// No description provided for @wsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun espace de travail'**
  String get wsEmptyTitle;

  /// No description provided for @wsName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'espace'**
  String get wsName;

  /// No description provided for @wsNoOpportunities.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opportunité dans cet espace.'**
  String get wsNoOpportunities;

  /// No description provided for @wsNoQueries.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recherche enregistrée dans cet espace.'**
  String get wsNoQueries;

  /// No description provided for @wsNoTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Vide'**
  String get wsNoTemplate;

  /// No description provided for @wsOpportunities.
  ///
  /// In fr, this message translates to:
  /// **'Opportunités'**
  String get wsOpportunities;

  /// No description provided for @wsQueries.
  ///
  /// In fr, this message translates to:
  /// **'Recherches'**
  String get wsQueries;

  /// No description provided for @wsRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de l\'espace'**
  String get wsRemove;

  /// No description provided for @wsSearchHere.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans cet espace'**
  String get wsSearchHere;

  /// No description provided for @wsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Organisez vos recherches par projet'**
  String get wsSubtitle;

  /// No description provided for @wsTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Modèle'**
  String get wsTemplate;

  /// No description provided for @settingsPreferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get settingsPreferences;

  /// No description provided for @settingsPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get settingsPrivacy;

  /// No description provided for @genSaved.
  ///
  /// In fr, this message translates to:
  /// **'Version enregistrée'**
  String get genSaved;

  /// No description provided for @prefCloseToTray.
  ///
  /// In fr, this message translates to:
  /// **'Continuer dans la zone de notification à la fermeture'**
  String get prefCloseToTray;

  /// No description provided for @prefCloseToTrayHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les veilles et les rappels ne fonctionnent que lorsque l\'application est ouverte ; fermer la fenêtre la réduit alors à côté de l\'horloge.'**
  String get prefCloseToTrayHelp;

  /// No description provided for @trayOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir Opportunex'**
  String get trayOpen;

  /// No description provided for @trayQuit.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get trayQuit;

  /// No description provided for @trayStillRunning.
  ///
  /// In fr, this message translates to:
  /// **'Opportunex continue dans la zone de notification pour exécuter vos veilles. Clic droit sur l\'icône pour quitter.'**
  String get trayStillRunning;

  /// No description provided for @aiAddProvider.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un fournisseur'**
  String get aiAddProvider;

  /// No description provided for @aiAllow.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser'**
  String get aiAllow;

  /// No description provided for @aiAnalyze.
  ///
  /// In fr, this message translates to:
  /// **'Analyser avec l\'IA'**
  String get aiAnalyze;

  /// No description provided for @aiAnalyzed.
  ///
  /// In fr, this message translates to:
  /// **'Analyse terminée : {applied} champs vérifiés ajoutés, {unverifiable} non vérifiables'**
  String aiAnalyzed(int applied, int unverifiable);

  /// No description provided for @aiBaseUrl.
  ///
  /// In fr, this message translates to:
  /// **'Adresse du service (facultatif)'**
  String get aiBaseUrl;

  /// No description provided for @aiBaseUrlHelp.
  ///
  /// In fr, this message translates to:
  /// **'HTTPS obligatoire, sauf pour un serveur sur cet ordinateur.'**
  String get aiBaseUrlHelp;

  /// No description provided for @aiBaseUrlRequired.
  ///
  /// In fr, this message translates to:
  /// **'Adresse du service'**
  String get aiBaseUrlRequired;

  /// No description provided for @aiConsentGiven.
  ///
  /// In fr, this message translates to:
  /// **'consentement donné'**
  String get aiConsentGiven;

  /// No description provided for @aiConsentIntro.
  ///
  /// In fr, this message translates to:
  /// **'Pour cette action, Opportunex doit envoyer des données à {provider}, un service en ligne :'**
  String aiConsentIntro(String provider);

  /// No description provided for @aiConsentNever.
  ///
  /// In fr, this message translates to:
  /// **'Votre nom, vos coordonnées, vos liens et vos identifiants ne sont jamais envoyés. Chaque envoi est inscrit dans le tableau de bord de confidentialité.'**
  String get aiConsentNever;

  /// No description provided for @aiConsentRevoke.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez retirer ce consentement à tout moment dans Paramètres > Confidentialité.'**
  String get aiConsentRevoke;

  /// No description provided for @aiConsentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer des données à {provider} ?'**
  String aiConsentTitle(String provider);

  /// No description provided for @aiDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Le fournisseur et sa clé (retirée du trousseau du système) seront supprimés.'**
  String get aiDeleteConfirm;

  /// No description provided for @aiDisplayName.
  ///
  /// In fr, this message translates to:
  /// **'Nom affiché'**
  String get aiDisplayName;

  /// No description provided for @aiEnable.
  ///
  /// In fr, this message translates to:
  /// **'Activer les fonctions d\'IA'**
  String get aiEnable;

  /// No description provided for @aiEnableHelp.
  ///
  /// In fr, this message translates to:
  /// **'Désactivées par défaut. Toutes les fonctions marchent sans IA ; l\'IA ne fait qu\'aider à structurer, résumer, traduire et rédiger.'**
  String get aiEnableHelp;

  /// No description provided for @aiErrAuth.
  ///
  /// In fr, this message translates to:
  /// **'Clé d\'API refusée par le fournisseur.'**
  String get aiErrAuth;

  /// No description provided for @aiErrNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Service injoignable. Vérifiez la connexion et l\'adresse.'**
  String get aiErrNetwork;

  /// No description provided for @aiErrOther.
  ///
  /// In fr, this message translates to:
  /// **'Erreur du fournisseur ({code}).'**
  String aiErrOther(String code);

  /// No description provided for @aiErrRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Quota atteint chez le fournisseur. Réessayez plus tard.'**
  String get aiErrRateLimited;

  /// No description provided for @aiErrTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Le fournisseur n\'a pas répondu à temps.'**
  String get aiErrTimeout;

  /// No description provided for @aiFieldAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get aiFieldAmount;

  /// No description provided for @aiFieldApplicationUrl.
  ///
  /// In fr, this message translates to:
  /// **'Lien de candidature'**
  String get aiFieldApplicationUrl;

  /// No description provided for @aiFieldAudience.
  ///
  /// In fr, this message translates to:
  /// **'Public visé'**
  String get aiFieldAudience;

  /// No description provided for @aiFieldCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get aiFieldCategory;

  /// No description provided for @aiFieldCountry.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get aiFieldCountry;

  /// No description provided for @aiFieldCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise'**
  String get aiFieldCurrency;

  /// No description provided for @aiFieldOrganization.
  ///
  /// In fr, this message translates to:
  /// **'Organisme'**
  String get aiFieldOrganization;

  /// No description provided for @aiFields.
  ///
  /// In fr, this message translates to:
  /// **'Informations extraites par l\'IA'**
  String get aiFields;

  /// No description provided for @aiKey.
  ///
  /// In fr, this message translates to:
  /// **'Clé d\'API'**
  String get aiKey;

  /// No description provided for @aiKeyHelp.
  ///
  /// In fr, this message translates to:
  /// **'Conservée dans le trousseau sécurisé du système, jamais dans la base ni dans les journaux.'**
  String get aiKeyHelp;

  /// No description provided for @aiKeyMissing.
  ///
  /// In fr, this message translates to:
  /// **'clé manquante'**
  String get aiKeyMissing;

  /// No description provided for @aiKeyReplace.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle clé d\'API (laisser vide pour garder l\'actuelle)'**
  String get aiKeyReplace;

  /// No description provided for @aiKind.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur'**
  String get aiKind;

  /// No description provided for @aiKindLmStudio.
  ///
  /// In fr, this message translates to:
  /// **'LM Studio (sur cet ordinateur)'**
  String get aiKindLmStudio;

  /// No description provided for @aiKindOllama.
  ///
  /// In fr, this message translates to:
  /// **'Ollama (sur cet ordinateur)'**
  String get aiKindOllama;

  /// No description provided for @aiKindOpenAi.
  ///
  /// In fr, this message translates to:
  /// **'Compatible OpenAI (adresse personnalisée)'**
  String get aiKindOpenAi;

  /// No description provided for @aiLocal.
  ///
  /// In fr, this message translates to:
  /// **'sur cet ordinateur'**
  String get aiLocal;

  /// No description provided for @aiLocalHelp.
  ///
  /// In fr, this message translates to:
  /// **'Modèle exécuté sur cet ordinateur : aucune donnée ne quitte la machine, aucun consentement n\'est demandé.'**
  String get aiLocalHelp;

  /// No description provided for @aiModel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle'**
  String get aiModel;

  /// No description provided for @aiModelHelp.
  ///
  /// In fr, this message translates to:
  /// **'Nom exact du modèle ; « Tester » liste les modèles disponibles.'**
  String get aiModelHelp;

  /// No description provided for @aiModelNotListed.
  ///
  /// In fr, this message translates to:
  /// **'Le modèle « {model} » n\'apparaît pas dans la liste : choisissez-en un ci-dessous.'**
  String aiModelNotListed(String model);

  /// No description provided for @aiModelsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun modèle listé} =1{1 modèle disponible} other{{count} modèles disponibles}}'**
  String aiModelsAvailable(int count);

  /// No description provided for @aiMoveDown.
  ///
  /// In fr, this message translates to:
  /// **'Descendre dans l\'ordre de repli'**
  String get aiMoveDown;

  /// No description provided for @aiMoveUp.
  ///
  /// In fr, this message translates to:
  /// **'Monter dans l\'ordre de repli'**
  String get aiMoveUp;

  /// No description provided for @aiNoProvider.
  ///
  /// In fr, this message translates to:
  /// **'Aucun fournisseur configuré.'**
  String get aiNoProvider;

  /// No description provided for @aiProviderAdded.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur ajouté. Utilisez « Tester » pour vérifier la connexion.'**
  String get aiProviderAdded;

  /// No description provided for @aiProviders.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseurs et ordre de repli'**
  String get aiProviders;

  /// No description provided for @aiProvidersHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les fournisseurs sont essayés dans cet ordre ; en dernier recours, l\'application utilise ses règles sans IA.'**
  String get aiProvidersHelp;

  /// No description provided for @aiPurposeContent.
  ///
  /// In fr, this message translates to:
  /// **'Le texte nécessaire à la tâche (requête ou annonce publique)'**
  String get aiPurposeContent;

  /// No description provided for @aiPurposeCv.
  ///
  /// In fr, this message translates to:
  /// **'Le texte de votre CV, sans nom, courriel, téléphone ni liens'**
  String get aiPurposeCv;

  /// No description provided for @aiPurposeProfile.
  ///
  /// In fr, this message translates to:
  /// **'Votre profil anonymisé (formations, expériences, compétences, langues)'**
  String get aiPurposeProfile;

  /// No description provided for @aiRemote.
  ///
  /// In fr, this message translates to:
  /// **'service en ligne'**
  String get aiRemote;

  /// No description provided for @aiRemoteHelp.
  ///
  /// In fr, this message translates to:
  /// **'Service en ligne : un consentement vous sera demandé avant le premier envoi, et chaque envoi sera journalisé.'**
  String get aiRemoteHelp;

  /// No description provided for @aiRouting.
  ///
  /// In fr, this message translates to:
  /// **'Modèle par tâche'**
  String get aiRouting;

  /// No description provided for @aiRoutingAuto.
  ///
  /// In fr, this message translates to:
  /// **'Automatique (ordre de repli)'**
  String get aiRoutingAuto;

  /// No description provided for @aiRoutingHelp.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un fournisseur précis pour certaines tâches.'**
  String get aiRoutingHelp;

  /// No description provided for @aiRule1.
  ///
  /// In fr, this message translates to:
  /// **'Les valeurs extraites sont vérifiées dans le texte de l\'annonce ; sinon elles sont marquées « Non vérifiable ».'**
  String get aiRule1;

  /// No description provided for @aiRule2.
  ///
  /// In fr, this message translates to:
  /// **'Le score de pertinence reste calculé sans IA, de façon explicable.'**
  String get aiRule2;

  /// No description provided for @aiRule3.
  ///
  /// In fr, this message translates to:
  /// **'Les brouillons n\'utilisent que votre profil validé ; tout ajout inventé est signalé.'**
  String get aiRule3;

  /// No description provided for @aiRule4.
  ///
  /// In fr, this message translates to:
  /// **'Les modèles locaux (Ollama, LM Studio) ne font sortir aucune donnée de l\'ordinateur.'**
  String get aiRule4;

  /// No description provided for @aiSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé généré par l\'IA'**
  String get aiSummary;

  /// No description provided for @aiTaskCv.
  ///
  /// In fr, this message translates to:
  /// **'Analyse de CV'**
  String get aiTaskCv;

  /// No description provided for @aiTaskDrafting.
  ///
  /// In fr, this message translates to:
  /// **'Rédaction de documents'**
  String get aiTaskDrafting;

  /// No description provided for @aiTaskExtraction.
  ///
  /// In fr, this message translates to:
  /// **'Analyse des annonces'**
  String get aiTaskExtraction;

  /// No description provided for @aiTaskQuery.
  ///
  /// In fr, this message translates to:
  /// **'Interprétation des recherches'**
  String get aiTaskQuery;

  /// No description provided for @aiTaskTranslation.
  ///
  /// In fr, this message translates to:
  /// **'Traduction'**
  String get aiTaskTranslation;

  /// No description provided for @aiTest.
  ///
  /// In fr, this message translates to:
  /// **'Tester'**
  String get aiTest;

  /// No description provided for @aiTestFailed.
  ///
  /// In fr, this message translates to:
  /// **'échec du test'**
  String get aiTestFailed;

  /// No description provided for @aiTestOk.
  ///
  /// In fr, this message translates to:
  /// **'testé le {date}'**
  String aiTestOk(String date);

  /// No description provided for @aiTestSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Connexion réussie'**
  String get aiTestSuccess;

  /// No description provided for @aiTitle.
  ///
  /// In fr, this message translates to:
  /// **'Intelligence artificielle'**
  String get aiTitle;

  /// No description provided for @aiTranslate.
  ///
  /// In fr, this message translates to:
  /// **'Traduire'**
  String get aiTranslate;

  /// No description provided for @aiUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'L\'IA n\'a pas pu traiter la demande ; les informations sans IA restent affichées.'**
  String get aiUnavailable;

  /// No description provided for @aiUsage.
  ///
  /// In fr, this message translates to:
  /// **'Consommation'**
  String get aiUsage;

  /// No description provided for @aiUsageCache.
  ///
  /// In fr, this message translates to:
  /// **'Cache'**
  String get aiUsageCache;

  /// No description provided for @aiUsageCalls.
  ///
  /// In fr, this message translates to:
  /// **'Appels'**
  String get aiUsageCalls;

  /// No description provided for @aiUsageDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get aiUsageDay;

  /// No description provided for @aiUsageEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun appel pour l\'instant.'**
  String get aiUsageEmpty;

  /// No description provided for @aiUsageErrors.
  ///
  /// In fr, this message translates to:
  /// **'Erreurs'**
  String get aiUsageErrors;

  /// No description provided for @aiUsageHelp.
  ///
  /// In fr, this message translates to:
  /// **'30 derniers jours, par fournisseur. Les jetons sont ceux déclarés par le fournisseur.'**
  String get aiUsageHelp;

  /// No description provided for @aiUsageProvider.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur'**
  String get aiUsageProvider;

  /// No description provided for @aiUsageRules.
  ///
  /// In fr, this message translates to:
  /// **'Repli sans IA'**
  String get aiUsageRules;

  /// No description provided for @aiUsageTokens.
  ///
  /// In fr, this message translates to:
  /// **'Jetons'**
  String get aiUsageTokens;

  /// No description provided for @aiWithout.
  ///
  /// In fr, this message translates to:
  /// **'Continuer sans IA'**
  String get aiWithout;

  /// No description provided for @commonRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get commonRefresh;

  /// No description provided for @cvUseAi.
  ///
  /// In fr, this message translates to:
  /// **'Analyser avec l\'IA'**
  String get cvUseAi;

  /// No description provided for @cvUseAiHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le texte du CV est envoyé sans nom, courriel, téléphone ni liens ; chaque élément reste à valider.'**
  String get cvUseAiHelp;

  /// No description provided for @genFromTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Modèle intégré'**
  String get genFromTemplate;

  /// No description provided for @genFromTemplateHelp.
  ///
  /// In fr, this message translates to:
  /// **'Rédigé localement à partir de votre profil.'**
  String get genFromTemplateHelp;

  /// No description provided for @genWithAi.
  ///
  /// In fr, this message translates to:
  /// **'Rédiger avec l\'IA'**
  String get genWithAi;

  /// No description provided for @genWithAiHelp.
  ///
  /// In fr, this message translates to:
  /// **'À partir de votre profil anonymisé ; les ajouts non présents dans le profil sont signalés.'**
  String get genWithAiHelp;

  /// No description provided for @provUnverifiable.
  ///
  /// In fr, this message translates to:
  /// **'Non vérifiable'**
  String get provUnverifiable;

  /// No description provided for @settingsAi.
  ///
  /// In fr, this message translates to:
  /// **'IA'**
  String get settingsAi;

  /// No description provided for @compareGone.
  ///
  /// In fr, this message translates to:
  /// **'Disparues'**
  String get compareGone;

  /// No description provided for @compareModified.
  ///
  /// In fr, this message translates to:
  /// **'Modifiées'**
  String get compareModified;

  /// No description provided for @compareNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles'**
  String get compareNew;

  /// No description provided for @compareSame.
  ///
  /// In fr, this message translates to:
  /// **'Aucune différence entre les deux exécutions.'**
  String get compareSame;

  /// No description provided for @dashDaysShort.
  ///
  /// In fr, this message translates to:
  /// **'J-{days}'**
  String dashDaysShort(int days);

  /// No description provided for @freqDaily.
  ///
  /// In fr, this message translates to:
  /// **'tous les jours'**
  String get freqDaily;

  /// No description provided for @freqEveryDays.
  ///
  /// In fr, this message translates to:
  /// **'tous les {days} jours'**
  String freqEveryDays(int days);

  /// No description provided for @freqEveryHours.
  ///
  /// In fr, this message translates to:
  /// **'toutes les {hours} h'**
  String freqEveryHours(int hours);

  /// No description provided for @freqMonthly.
  ///
  /// In fr, this message translates to:
  /// **'tous les mois'**
  String get freqMonthly;

  /// No description provided for @freqWeekly.
  ///
  /// In fr, this message translates to:
  /// **'chaque semaine'**
  String get freqWeekly;

  /// No description provided for @historyCompare.
  ///
  /// In fr, this message translates to:
  /// **'Comparer avec l\'exécution précédente'**
  String get historyCompare;

  /// No description provided for @monHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get monHistory;

  /// No description provided for @monHistoryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune exécution pour l\'instant.'**
  String get monHistoryEmpty;

  /// No description provided for @monHistoryLine.
  ///
  /// In fr, this message translates to:
  /// **'{date} · {created} nouvelles · {updated} modifiées'**
  String monHistoryLine(String date, int created, int updated);

  /// No description provided for @paletteEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande ne correspond.'**
  String get paletteEmpty;

  /// No description provided for @paletteGoTo.
  ///
  /// In fr, this message translates to:
  /// **'Aller à : {section}'**
  String paletteGoTo(String section);

  /// No description provided for @paletteHint.
  ///
  /// In fr, this message translates to:
  /// **'Tapez une commande ou une page…'**
  String get paletteHint;

  /// No description provided for @paletteTheme.
  ///
  /// In fr, this message translates to:
  /// **'Changer de thème (clair, sombre, système)'**
  String get paletteTheme;

  /// No description provided for @prefAutoArchive.
  ///
  /// In fr, this message translates to:
  /// **'Archiver les candidatures closes'**
  String get prefAutoArchive;

  /// No description provided for @prefAutoArchiveHelp.
  ///
  /// In fr, this message translates to:
  /// **'Acceptées, refusées, retirées ou expirées, sans activité depuis ce délai.'**
  String get prefAutoArchiveHelp;

  /// No description provided for @prefAutostart.
  ///
  /// In fr, this message translates to:
  /// **'Lancer Opportunex à l\'ouverture de session'**
  String get prefAutostart;

  /// No description provided for @prefAutostartHelp.
  ///
  /// In fr, this message translates to:
  /// **'L\'application démarre réduite dans la zone de notification pour exécuter vos veilles.'**
  String get prefAutostartHelp;

  /// No description provided for @prefDays.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =1{après 1 jour} other{après {days} jours}}'**
  String prefDays(int days);

  /// No description provided for @prefNever.
  ///
  /// In fr, this message translates to:
  /// **'jamais'**
  String get prefNever;

  /// No description provided for @prefTracking.
  ///
  /// In fr, this message translates to:
  /// **'Suivi et démarrage'**
  String get prefTracking;

  /// No description provided for @runUnavailableCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 source à consulter manuellement} other{{count} sources à consulter manuellement}}'**
  String runUnavailableCount(int count);

  /// No description provided for @shortcutClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer une fenêtre de dialogue'**
  String get shortcutClose;

  /// No description provided for @shortcutHelp.
  ///
  /// In fr, this message translates to:
  /// **'Afficher cette aide'**
  String get shortcutHelp;

  /// No description provided for @shortcutPalette.
  ///
  /// In fr, this message translates to:
  /// **'Palette de commandes'**
  String get shortcutPalette;

  /// No description provided for @shortcutSearch.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle recherche'**
  String get shortcutSearch;

  /// No description provided for @shortcutSections.
  ///
  /// In fr, this message translates to:
  /// **'Aller à une section du menu'**
  String get shortcutSections;

  /// No description provided for @shortcutsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Raccourcis clavier'**
  String get shortcutsTitle;

  /// No description provided for @srcCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories couvertes'**
  String get srcCategories;

  /// No description provided for @srcFrequency.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence d\'analyse'**
  String get srcFrequency;

  /// No description provided for @srcFrequencyHelp.
  ///
  /// In fr, this message translates to:
  /// **'Jamais plus d\'une fois par heure ; les délais de politesse et robots.txt restent appliqués.'**
  String get srcFrequencyHelp;

  /// No description provided for @srcSettings.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence et catégories'**
  String get srcSettings;

  /// No description provided for @strEducation.
  ///
  /// In fr, this message translates to:
  /// **'Niveau d\'études atteint : {level}'**
  String strEducation(String level);

  /// No description provided for @strExperience.
  ///
  /// In fr, this message translates to:
  /// **'Expérience suffisante (au moins {years} ans demandés)'**
  String strExperience(String years);

  /// No description provided for @strLanguages.
  ///
  /// In fr, this message translates to:
  /// **'Langues demandées maîtrisées'**
  String get strLanguages;

  /// No description provided for @strLocation.
  ///
  /// In fr, this message translates to:
  /// **'Pays recherché : {country}'**
  String strLocation(String country);

  /// No description provided for @strObjective.
  ///
  /// In fr, this message translates to:
  /// **'Correspond à votre objectif : {objective}'**
  String strObjective(String objective);

  /// No description provided for @strRemote.
  ///
  /// In fr, this message translates to:
  /// **'Télétravail possible'**
  String get strRemote;

  /// No description provided for @strSkills.
  ///
  /// In fr, this message translates to:
  /// **'Compétences : {skills}'**
  String strSkills(String skills);

  /// No description provided for @a11yToggle.
  ///
  /// In fr, this message translates to:
  /// **'Activer ou désactiver : {name}'**
  String a11yToggle(String name);

  /// No description provided for @a11ySelect.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner : {title}'**
  String a11ySelect(String title);
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
