// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Opportunex';

  @override
  String get slogan => 'Find · Analyse · Achieve';

  @override
  String get tagline => 'Your assistant for public and private opportunities';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonBack => 'Back';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied to clipboard';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonOptional => 'optional';

  @override
  String get commonShow => 'Show';

  @override
  String get commonHide => 'Hide';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonNotSpecified => 'Not specified';

  @override
  String get commonUnknownError =>
      'Something unexpected went wrong. Try again; if it keeps happening, export the logs from Settings › Maintenance.';

  @override
  String get startupStarting => 'Starting the local engine…';

  @override
  String startupRestarting(int attempt) {
    return 'The engine stopped. Restarting (attempt $attempt of 3)…';
  }

  @override
  String get diagTitle => 'The local engine could not start';

  @override
  String get diagNotFound =>
      'The Opportunex engine could not be found. Reinstall the application or, in development, run \"launch-dev.ps1 -Setup\".';

  @override
  String get diagAlreadyRunning =>
      'Opportunex is already open for this user. Close the other window, then retry.';

  @override
  String get diagHandshake =>
      'The engine did not answer in time. Your antivirus may be blocking it.';

  @override
  String get diagCrashed => 'The engine stopped several times in a row.';

  @override
  String get diagHealth =>
      'The engine started but does not pass its health checks.';

  @override
  String get diagDetails => 'Technical details';

  @override
  String get diagExportLogs => 'Open the logs folder';

  @override
  String get diagRetry => 'Restart the engine';

  @override
  String get authWelcomeTitle => 'Welcome';

  @override
  String get authWelcomeSubtitle =>
      'Your data stays on this computer, encrypted.';

  @override
  String get authChooseProfile => 'Choose your profile';

  @override
  String get authNewProfile => 'Create a profile';

  @override
  String get authOtherAccount => 'Sign in with another e-mail';

  @override
  String get authImportProfile => 'Import a profile from a backup';

  @override
  String get authEmail => 'E-mail address';

  @override
  String get authPassword => 'Password';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authDisplayName => 'Display name';

  @override
  String get authLanguage => 'Language';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authCreateAccount => 'Create an account';

  @override
  String get authRegisterTitle => 'Create your local profile';

  @override
  String get authRegisterSubtitle =>
      'A profile is encrypted with your password. Nobody else, not even ETS Monthe Network, can read it.';

  @override
  String get authAcceptTerms =>
      'I accept the terms of use and the privacy policy';

  @override
  String get authReadTerms => 'Read the terms';

  @override
  String get authAlreadyHaveAccount => 'I already have a profile';

  @override
  String get authPasswordHint =>
      'At least 12 characters. A phrase of several words works best.';

  @override
  String get authStrength0 => 'Very weak';

  @override
  String get authStrength1 => 'Weak';

  @override
  String get authStrength2 => 'Fair';

  @override
  String get authStrength3 => 'Good';

  @override
  String get authStrength4 => 'Excellent';

  @override
  String get authPhraseTitle => 'Your recovery phrase';

  @override
  String get authPhraseBody =>
      'Write these 12 words down in order and keep them away from this computer. They are the only way to recover your data if you forget your password. They will never be shown again.';

  @override
  String get authPhraseConfirm =>
      'I have stored my recovery phrase in a safe place';

  @override
  String get authUnlockTitle => 'Profile locked';

  @override
  String get authUnlockInactivity => 'Locked after a period of inactivity.';

  @override
  String get authUnlockManual => 'Profile locked.';

  @override
  String get authUnlockExpired => 'Your session has expired.';

  @override
  String get authUnlock => 'Unlock';

  @override
  String get authSwitchProfile => 'Switch profile';

  @override
  String get authRecoverTitle => 'Recover your profile';

  @override
  String get authRecoverBody =>
      'Enter the 12 words of your recovery phrase, then choose a new password.';

  @override
  String get authRecoveryPhrase => 'Recovery phrase (12 words)';

  @override
  String get authNewPassword => 'New password';

  @override
  String get authRecover => 'Recover and sign in';

  @override
  String get authLock => 'Lock';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authModeLocal => 'Local mode';

  @override
  String get authModeSynced => 'Synced';

  @override
  String authLockedFor(int seconds) {
    return 'Too many attempts. Try again in $seconds s.';
  }

  @override
  String get validationRequired => 'Required';

  @override
  String get validationEmail => 'Invalid e-mail address';

  @override
  String get validationPasswordMatch => 'Passwords do not match';

  @override
  String get validationPhraseWords =>
      'The phrase must contain exactly 12 words';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navSearch => 'Search';

  @override
  String get navSaved => 'Saved';

  @override
  String get navApplications => 'Applications';

  @override
  String get navMonitors => 'Monitors';

  @override
  String get navWorkspaces => 'Workspaces';

  @override
  String get navSources => 'Sources';

  @override
  String get navProfile => 'My profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get navCollapse => 'Collapse menu';

  @override
  String get navExpand => 'Expand menu';

  @override
  String get errInvalidCredentials => 'Wrong e-mail or password.';

  @override
  String get errAccountLocked =>
      'Too many failed attempts. Please wait before trying again.';

  @override
  String get errEmailTaken =>
      'A profile already uses this e-mail on this computer.';

  @override
  String get errPasswordPolicy =>
      'Password too weak: at least 12 characters and not in the compromised-password list.';

  @override
  String get errPasswordMismatch => 'Passwords do not match.';

  @override
  String get errTermsNotAccepted => 'You must accept the terms of use.';

  @override
  String get errInvalidRecovery => 'Wrong recovery phrase.';

  @override
  String get errSessionLocked => 'Your session is locked.';

  @override
  String get errEngineUnreachable =>
      'The local engine is not responding. It may be restarting.';

  @override
  String get errValidation => 'Some fields are invalid.';

  @override
  String get errNotFound => 'Item not found.';

  @override
  String get errProfileCorrupted =>
      'The profile cannot be decrypted. Restore a backup.';

  @override
  String get errUpstream => 'The external service is unavailable right now.';

  @override
  String get settingsAccount => 'Account & security';

  @override
  String get settingsBackups => 'Backups';

  @override
  String get settingsMaintenance => 'Maintenance';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsSaved => 'Changes saved';

  @override
  String get settingsProfileSection => 'Profile';

  @override
  String get settingsModeLocalHelp => 'Your data stays on this computer only.';

  @override
  String get settingsModeSyncedHelp =>
      'Your data is end-to-end encrypted and synced across your devices.';

  @override
  String get settingsAppearance => 'Language & appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsAutoLock => 'Auto-lock';

  @override
  String get settingsAutoLockHelp =>
      'After this long without activity, the profile locks and the encryption key is erased from memory.';

  @override
  String settingsMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsChangePasswordHelp =>
      'Your data stays encrypted; only the key wrapping is renewed.';

  @override
  String get settingsCurrentPassword => 'Current password';

  @override
  String get settingsPasswordChanged => 'Password changed';

  @override
  String get settingsDangerZone => 'Danger zone';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountHelp =>
      'Permanently erases the profile, encrypted database, documents and backups from this computer.';

  @override
  String get settingsDeleteAccountConfirm =>
      'This cannot be undone: all your local data will be deleted. Type DELETE to confirm.';

  @override
  String get settingsConfirmWithPassword => 'Confirm with your password';

  @override
  String get backupsTitle => 'Backups';

  @override
  String get backupsHelp =>
      'Encrypted archives of your database and documents. The last 7 automatic backups are kept.';

  @override
  String get backupsCreate => 'Back up now';

  @override
  String get backupsCreated => 'Backup created';

  @override
  String get backupsAuto => 'Daily automatic backup';

  @override
  String get backupsAutoHelp =>
      'Runs while the application is open, at most once a day.';

  @override
  String get backupsFolder => 'Backup folder';

  @override
  String get backupsHistory => 'History';

  @override
  String get backupsEmpty => 'No backups yet.';

  @override
  String get backupsOkTag => 'intact';

  @override
  String get backupsRestoredTag => 'restored';

  @override
  String get backupsVerify => 'Check integrity';

  @override
  String get backupsVerified => 'Backup checked: intact';

  @override
  String get backupsRestore => 'Restore';

  @override
  String get backupsRestoreConfirm =>
      'Your current data will be replaced by the backup. A safety backup is made first. Type RESTORE to confirm.';

  @override
  String get backupsRestored => 'Restore complete';

  @override
  String get backupsDelete => 'Delete backup';

  @override
  String get backupsDeleteConfirm =>
      'The backup file will be permanently deleted.';

  @override
  String get backupsDeleted => 'Backup deleted';

  @override
  String get backupKindManual => 'manual';

  @override
  String get backupKindScheduled => 'automatic';

  @override
  String get backupKindPreMigration => 'before update';

  @override
  String get backupKindPreRestore => 'before restore';

  @override
  String get maintenanceStorage => 'Storage used';

  @override
  String get maintenanceDatabase => 'Database';

  @override
  String get maintenanceVault => 'Encrypted documents';

  @override
  String get maintenanceDataDir => 'Data folder';

  @override
  String get maintenanceTools => 'Tools';

  @override
  String get maintenanceRun => 'Run';

  @override
  String get maintenanceIntegrity => 'Integrity check';

  @override
  String get maintenanceIntegrityHelp =>
      'Checks the database, the foreign keys and the search index.';

  @override
  String get maintenanceIntegrityOk => 'No problems found';

  @override
  String get maintenanceOptimize => 'Optimise the database';

  @override
  String get maintenanceOptimizeHelp =>
      'Compacts the database and optimises the search index.';

  @override
  String get maintenanceOptimized => 'Database optimised';

  @override
  String get maintenanceLogs => 'Technical logs';

  @override
  String get maintenanceLogsHelp =>
      'Exports redacted logs (no e-mails, tokens or keys) for support.';

  @override
  String get maintenanceExport => 'Export';

  @override
  String get maintenanceLogsSaved => 'Logs exported';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutEngine => 'engine';

  @override
  String get aboutSchema => 'schema';

  @override
  String get aboutCredits => 'Publisher & author';

  @override
  String get aboutPublisher => 'Publisher';

  @override
  String get aboutAuthor => 'Lead developer';

  @override
  String get aboutCopyright => 'Copyright';

  @override
  String get aboutLicense => 'Licence';

  @override
  String get aboutLicenseBody =>
      'Opportunex is free, open-source software, distributed under the GNU Affero General Public License v3. You may use, study, modify and redistribute it under the terms of that licence. The Opportunex name and logo remain reserved.';

  @override
  String get aboutSourceCode => 'Source code';

  @override
  String get aboutThirdParty => 'Third-party licences';

  @override
  String get aboutTermsPrivacy => 'Terms & privacy';

  @override
  String get legalTerms => 'Terms of use';

  @override
  String get legalPrivacy => 'Privacy';

  @override
  String get importProfileBody =>
      'Choose an Opportunex backup file (.opxbak) and enter the password of the backed-up profile.';

  @override
  String get importChooseFile => 'Choose a backup…';

  @override
  String get importAction => 'Import and sign in';
}
