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

  @override
  String get badgeAiGenerated => 'AI-generated';

  @override
  String get badgeDeadlineSoon => 'Deadline soon';

  @override
  String get badgeDeadlineUnknown => 'Deadline unknown';

  @override
  String get badgeEligibilityUncertain => 'Eligibility uncertain';

  @override
  String get badgeExpired => 'Expired';

  @override
  String get badgeModified => 'Modified';

  @override
  String get badgeNew => 'New';

  @override
  String get badgeVerified => 'Verified';

  @override
  String scoreLabel(int score) {
    return 'Relevance $score out of 100';
  }

  @override
  String get catAcceleration => 'Incubation & acceleration';

  @override
  String get catCall => 'Calls for applications';

  @override
  String get catCompetition => 'Competitions & awards';

  @override
  String get catEmployment => 'Employment';

  @override
  String get catEntrepreneurship => 'Entrepreneurship';

  @override
  String get catFreelance => 'Freelance missions';

  @override
  String get catGrant => 'Grants & funding';

  @override
  String get catInternship => 'Internships';

  @override
  String get catOther => 'Other opportunities';

  @override
  String get catPartnership => 'Partnerships';

  @override
  String get catResearch => 'Research';

  @override
  String get catScholarship => 'Scholarships';

  @override
  String get catTender => 'Tenders';

  @override
  String get catTraining => 'Training';

  @override
  String get catVolunteering => 'Volunteering';

  @override
  String get critDeadline => 'Deadline';

  @override
  String get critEducation => 'Education';

  @override
  String get critExperience => 'Experience';

  @override
  String get critLanguage => 'Languages';

  @override
  String get critLocation => 'Location';

  @override
  String get critNotEvaluated => 'Not evaluated for lack of information';

  @override
  String get critObjectives => 'Goals';

  @override
  String get critSkills => 'Skills';

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
      zero: 'last day',
    );
    return '$_temp0';
  }

  @override
  String get deadlineUnknownShort => 'Deadline not specified';

  @override
  String get eligLikely => 'Likely eligible (based on published criteria)';

  @override
  String get eligNot => 'Not eligible: the deadline has passed';

  @override
  String get eligUncertain => 'Eligibility to check';

  @override
  String get eligUnlikely => 'Unlikely to be eligible';

  @override
  String get exportAction => 'Export';

  @override
  String get exportDone => 'Export saved';

  @override
  String get filterAdd => 'Add';

  @override
  String get filterAddKeyword => 'Add a keyword';

  @override
  String get filterAmountMin => 'Minimum amount';

  @override
  String get filterAnyBadge => 'All flags';

  @override
  String get filterAnyDate => 'Any date';

  @override
  String get filterAnyScore => 'Any relevance';

  @override
  String get filterBadge => 'Flag';

  @override
  String get filterCategories => 'Categories';

  @override
  String get filterCountries => 'Countries';

  @override
  String get filterDeadlineBefore => 'Deadline before';

  @override
  String get filterIncludeExpired => 'Include expired';

  @override
  String get filterKeywords => 'Keywords';

  @override
  String get filterMinScore => 'Minimum relevance';

  @override
  String get filterWorkMode => 'Work mode';

  @override
  String get filtersSubtitle =>
      'This is how Opportunex understood your request. Correct it freely before starting the search.';

  @override
  String get filtersTitle => 'Search criteria';

  @override
  String gapEducation(String value) {
    return 'Required education: $value';
  }

  @override
  String gapExperience(String value) {
    return 'Required experience: $value year(s)';
  }

  @override
  String gapLanguage(String value) {
    return 'Required language: $value';
  }

  @override
  String gapLocation(String value) {
    return 'Location: $value';
  }

  @override
  String gapSkills(String value) {
    return 'Skills missing from your profile: $value';
  }

  @override
  String get historyClear => 'Clear history';

  @override
  String get historyClearConfirm =>
      'Unsaved searches will be deleted. Saved searches are kept.';

  @override
  String get historyEmpty => 'No searches yet.';

  @override
  String get historyHint =>
      'Save a search to rerun it later or turn it into a monitor.';

  @override
  String get historyOpen => 'View results';

  @override
  String get historyRerun => 'Run again';

  @override
  String get historySave => 'Save search';

  @override
  String get historyUnsave => 'Stop saving';

  @override
  String get loadMore => 'Show more';

  @override
  String get oppAddWorkspace => 'Add to a workspace';

  @override
  String get oppAmount => 'Amount';

  @override
  String get oppApplicationUrl => 'Application link';

  @override
  String get oppContact => 'Public contact';

  @override
  String get oppDeadline => 'Deadline';

  @override
  String get oppDismiss => 'Dismiss';

  @override
  String get oppDocumentsRequired => 'Documents required';

  @override
  String get oppEligibility => 'Eligibility';

  @override
  String get oppFeedbackThanks =>
      'Thanks, your recommendations will be adjusted';

  @override
  String get oppFinancial => 'Financial benefits';

  @override
  String get oppFullText => 'Full listing text';

  @override
  String get oppGaps => 'Gaps and points to check';

  @override
  String get oppLastChecked => 'Last checked';

  @override
  String get oppLocation => 'Location';

  @override
  String get oppMethod => 'Analysis method';

  @override
  String get oppMethodRules => 'Deterministic rules (no AI)';

  @override
  String get oppMore => 'More actions';

  @override
  String get oppNoCriteria =>
      'The listing does not publish precise eligibility criteria: check with the publisher.';

  @override
  String get oppNoGaps => 'No gap detected with your profile.';

  @override
  String get oppNotRelevant => 'Not relevant';

  @override
  String get oppOfficialLink => 'Official link';

  @override
  String get oppOpenTracking => 'View tracking';

  @override
  String get oppOriginalPublisher => 'Original publisher';

  @override
  String get oppOverview => 'Overview';

  @override
  String get oppProcedure => 'Procedure';

  @override
  String get oppPublished => 'Published on';

  @override
  String get oppPublisher => 'Publisher & sources';

  @override
  String get oppQualifications => 'Required qualifications';

  @override
  String get oppRecheck => 'Re-check on the official site';

  @override
  String get oppRechecked => 'Check complete';

  @override
  String get oppRelevance => 'Relevance for you';

  @override
  String get oppRelevant => 'Relevant';

  @override
  String get oppRepost => 'Repost';

  @override
  String get oppSave => 'Save';

  @override
  String get oppSaved => 'Saved';

  @override
  String get oppSavedToast => 'Opportunity saved';

  @override
  String get oppStatus => 'Status';

  @override
  String get oppStrengths => 'Your strengths';

  @override
  String get oppSubmissionNotice =>
      'Opportunex never submits applications: apply through the publisher\'s official channel.';

  @override
  String get oppSummary => 'Summary';

  @override
  String get oppToVerify => 'To check yourself';

  @override
  String get oppVerbatimNote =>
      'Clauses reproduced word for word from the listing.';

  @override
  String get oppVerification => 'Verification';

  @override
  String get provExplicit => 'Explicit';

  @override
  String get provGenerated => 'Generated';

  @override
  String get provInferred => 'Inferred';

  @override
  String get reqEducation => 'Education';

  @override
  String get reqExperience => 'Experience';

  @override
  String get reqLanguages => 'Languages';

  @override
  String get reqSkills => 'Skills';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get resultsEmptyBody =>
      'Broaden your criteria or add sources in the Sources section.';

  @override
  String get resultsEmptyTitle => 'No matching opportunity';

  @override
  String get runCancelled => 'cancelled';

  @override
  String get runCompleted => 'complete';

  @override
  String get runFailed => 'failed';

  @override
  String get runPartial => 'partly complete';

  @override
  String runProgress(int done, int total) {
    return 'Searching: $done of $total source(s)';
  }

  @override
  String get runResume => 'Resume';

  @override
  String runStatus(String status) {
    return 'Search $status';
  }

  @override
  String get runUnavailableBody =>
      'These sources could not be read automatically or do not allow it. Check them directly:';

  @override
  String get runUnavailableTitle => 'Sources to check manually';

  @override
  String get searchEmptyBody =>
      'Describe what you are looking for in French or English, for example \"master\'s scholarship in France\" or \"IT internship in Douala\".';

  @override
  String get searchEmptyTitle => 'What are you looking for?';

  @override
  String get searchHelper => 'Natural-language search, in French or English';

  @override
  String get searchHint =>
      'E.g. master\'s scholarship in public health for 2027';

  @override
  String get searchInterpret => 'Analyse';

  @override
  String get searchLaunch => 'Start search';

  @override
  String get searchSuggestions => 'Suggestions';

  @override
  String get searchTabHistory => 'History';

  @override
  String get searchTabNew => 'Search';

  @override
  String get sortAmount => 'Amount';

  @override
  String get sortDeadline => 'Deadline';

  @override
  String get sortPublished => 'Publication';

  @override
  String get sortRecent => 'Recently added';

  @override
  String get sortRelevance => 'Relevance';

  @override
  String sourcesCount(int count) {
    return '$count sources';
  }

  @override
  String get workHybrid => 'Hybrid';

  @override
  String get workOnsite => 'On site';

  @override
  String get workRemote => 'Remote';

  @override
  String get wsAdded => 'Added to the workspace';

  @override
  String get wsNoneYet => 'Create a workspace first in the Workspaces section.';

  @override
  String get calDeadline => 'Official deadline';

  @override
  String get calEmpty => 'No deadlines this month.';

  @override
  String get calExportIcs => 'Export calendar (.ics)';

  @override
  String get calNext => 'Next month';

  @override
  String get calPersonalDeadline => 'Personal deadline';

  @override
  String get calPrev => 'Previous month';

  @override
  String get cvAccept => 'Accept';

  @override
  String cvApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items added to the profile',
      one: '1 item added to the profile',
      zero: 'No item added to the profile',
    );
    return '$_temp0';
  }

  @override
  String get cvApply => 'Add to profile';

  @override
  String cvConfidence(int pct) {
    return 'Extraction confidence: $pct%';
  }

  @override
  String get cvDiscard => 'Discard import';

  @override
  String get cvIdentity => 'Identity';

  @override
  String get cvImport => 'Import a CV';

  @override
  String get cvKeepFile => 'Keep the CV file';

  @override
  String get cvKeepFileHelp =>
      'The file is encrypted in your local vault. Otherwise it is deleted after parsing.';

  @override
  String get cvNothingFound => 'Nothing could be extracted';

  @override
  String get cvNothingFoundBody =>
      'The document may be scanned (image) or protected. You can fill in your profile manually.';

  @override
  String get cvPick => 'Choose a file';

  @override
  String get cvPickBody =>
      'PDF, DOCX or TXT, up to 10 MB. Parsing happens on this computer, nothing is sent online.';

  @override
  String get cvPickTitle => 'Import your CV';

  @override
  String get cvReject => 'Reject';

  @override
  String get cvReviewHelp =>
      'Check each detected item: accept, correct or reject it. Only accepted items will be added.';

  @override
  String get cvSubtitle => 'Pre-fill your profile from an existing CV';

  @override
  String get dashActivity => 'Recent activity';

  @override
  String get dashApplications => 'Applications by status';

  @override
  String get dashDeadlines => 'Upcoming deadlines';

  @override
  String get dashDiscovered => 'Discovered';

  @override
  String get dashFirstStepsBody => 'A few steps to get relevant results.';

  @override
  String get dashFirstStepsTitle => 'Getting started';

  @override
  String dashFollowUp(String title) {
    return 'Follow-up suggested: $title';
  }

  @override
  String dashHello(String name) {
    return 'Hello $name';
  }

  @override
  String get dashInProgress => 'In preparation';

  @override
  String get dashManage => 'Manage';

  @override
  String get dashNew => 'New';

  @override
  String get dashNewSearch => 'New search';

  @override
  String get dashNoActivity => 'No activity yet.';

  @override
  String get dashNoApplications => 'No tracked applications.';

  @override
  String get dashNoDeadlines => 'No deadlines in the next 30 days.';

  @override
  String get dashNoRecommendations => 'Run a search to get recommendations.';

  @override
  String get dashNoStats =>
      'Statistics will appear after your first applications.';

  @override
  String get dashRecommendations => 'Recommendations';

  @override
  String get dashRecommendationsHelp =>
      'Open opportunities ranked best for your profile (indicative score).';

  @override
  String get dashRelevant => 'Relevant';

  @override
  String get dashSaved => 'Saved';

  @override
  String dashSourceFailing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count consecutive failures',
      one: '1 consecutive failure',
    );
    return '$_temp0';
  }

  @override
  String get dashSources => 'Source health';

  @override
  String dashSourcesSummary(int active, int healthy, int total) {
    return '$active active, $healthy healthy, $total in total';
  }

  @override
  String dashStatAccepted(int count) {
    return 'Accepted: $count';
  }

  @override
  String dashStatDelay(String days) {
    return 'Average response time: $days days';
  }

  @override
  String dashStatRate(String rate) {
    return 'Acceptance rate: $rate';
  }

  @override
  String dashStatSubmitted(int count) {
    return 'Submitted: $count';
  }

  @override
  String get dashStats => 'Personal statistics';

  @override
  String get dashStepCv => 'Import a CV';

  @override
  String get dashStepMonitor => 'Create a monitor';

  @override
  String get dashStepProfile => 'Complete the profile';

  @override
  String get dashStepSearch => 'Run a search';

  @override
  String get dashSubmitted => 'Submitted';

  @override
  String dashSubmittedOn(String date) {
    return 'Submitted on $date';
  }

  @override
  String get dashSubtitle => 'Overview of your opportunities and applications';

  @override
  String dashWithin(int days, int count) {
    return '$days days: $count';
  }

  @override
  String get dayFri => 'Friday';

  @override
  String get dayMon => 'Monday';

  @override
  String get daySat => 'Saturday';

  @override
  String get daySun => 'Sunday';

  @override
  String get dayThu => 'Thursday';

  @override
  String get dayTue => 'Tuesday';

  @override
  String get dayWed => 'Wednesday';

  @override
  String get docCoverLetter => 'Cover letter';

  @override
  String get docCvSuggestions => 'CV tailoring suggestions';

  @override
  String get docEmail => 'Application e-mail';

  @override
  String get docGrant => 'Grant application';

  @override
  String get docInterview => 'Interview preparation';

  @override
  String get docProjectSummary => 'Project summary';

  @override
  String get docScholarship => 'Scholarship application letter';

  @override
  String get edBac => 'High-school diploma';

  @override
  String get edBac2 => 'Associate degree (BTS, DUT, HND)';

  @override
  String get edBachelor => 'Bachelor\'s degree';

  @override
  String get edDoctorate => 'Doctorate';

  @override
  String get edMaster => 'Master\'s degree';

  @override
  String get edNone => 'No diploma';

  @override
  String get edPostdoc => 'Postdoctoral';

  @override
  String get edPrimary => 'Primary school';

  @override
  String get edSecondary => 'Secondary school';

  @override
  String get edVocational => 'Vocational training';

  @override
  String get eraseAction => 'Erase selection';

  @override
  String get eraseConfirm =>
      'The selected data will be permanently deleted from this computer. Type ERASE to confirm.';

  @override
  String get eraseDocuments => 'Documents attached to applications';

  @override
  String get eraseDone => 'Data erased';

  @override
  String get eraseHelp =>
      'Choose exactly what you want to delete. Your account and applications are kept.';

  @override
  String get eraseHistory => 'Unsaved search history';

  @override
  String get eraseLogs => 'Technical logs';

  @override
  String get eraseNotifications => 'Notifications';

  @override
  String get eraseOpportunities => 'Unsaved opportunities';

  @override
  String get eraseProfile => 'Profile details (education, experience, skills…)';

  @override
  String get eraseTitle => 'Selective erasure';

  @override
  String get etConsulting => 'Consulting';

  @override
  String get etFreelance => 'Freelance';

  @override
  String get etFullTime => 'Full time';

  @override
  String get etInternship => 'Internship';

  @override
  String get etPartTime => 'Part time';

  @override
  String get etVolunteer => 'Volunteering';

  @override
  String get evCall => 'Call';

  @override
  String get evFollowUp => 'Follow-up';

  @override
  String get evInterview => 'Interview';

  @override
  String get evMeeting => 'Meeting';

  @override
  String get evOther => 'Other';

  @override
  String get evTest => 'Test';

  @override
  String get genCreate => 'Create a draft';

  @override
  String get genEmpty => 'No draft for this opportunity.';

  @override
  String get genIntegrityTitle =>
      'Check: items not found in your validated profile';

  @override
  String get genNotice =>
      'Draft generated from your validated profile. Review and adapt it before sending anything.';

  @override
  String get genSaveVersion => 'Save a version';

  @override
  String get genSubtitle => 'Editable drafts with version history';

  @override
  String get genTitle => 'Generated documents';

  @override
  String get monCreate => 'New monitor';

  @override
  String monDaily(String time) {
    return 'Every day at $time';
  }

  @override
  String get monDailyLabel => 'Daily';

  @override
  String get monEmptyBody =>
      'A monitor reruns a search on a schedule and tells you what is new.';

  @override
  String get monEmptyTitle => 'No monitors';

  @override
  String get monFrequencyNote =>
      'The actual frequency respects each source\'s limits (usually at most once a day).';

  @override
  String monLastRun(String date, int count) {
    return 'Last run: $date · $count new';
  }

  @override
  String monMinScore(int score) {
    return 'Minimum score to be notified: $score';
  }

  @override
  String get monName => 'Monitor name';

  @override
  String monNextRun(String date) {
    return 'Next run: $date';
  }

  @override
  String get monOnlyWhileOpen =>
      'Monitors only run while Opportunex is open (including minimised to the system tray).';

  @override
  String get monQuery => 'Search to monitor';

  @override
  String get monRunNow => 'Run now';

  @override
  String monScheduleSummary(String schedule, int score) {
    return '$schedule · minimum score $score';
  }

  @override
  String get monStarted => 'Monitor started';

  @override
  String get monTabMonitors => 'Monitors';

  @override
  String get monTabNotifications => 'Notifications';

  @override
  String monWeekly(String when) {
    return 'Every week: $when';
  }

  @override
  String get monWeeklyLabel => 'Weekly';

  @override
  String get nkChanged => 'Tracked opportunity changed';

  @override
  String get nkDeadline => 'Deadline reminders';

  @override
  String get nkMonitor => 'Monitor failure';

  @override
  String get nkNew => 'New opportunities';

  @override
  String get nkSource => 'Source unavailable';

  @override
  String get notifEmpty => 'No notifications';

  @override
  String get notifMarkAllRead => 'Mark all as read';

  @override
  String get onbDone => 'Profile saved. Welcome!';

  @override
  String get onbFinish => 'Finish';

  @override
  String get onbLater => 'Later';

  @override
  String get onbOptionalNote =>
      'Every step is optional and can be changed at any time from your profile.';

  @override
  String get onbResume => 'Resume setup';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbStep1 => 'General information and links';

  @override
  String get onbStep2 => 'Education';

  @override
  String get onbStep3 => 'Experience';

  @override
  String get onbStep4 => 'Skills and languages';

  @override
  String get onbStep5 => 'Objectives';

  @override
  String get onbStep6 => 'Project or organisation';

  @override
  String get onbStep7 => 'Summary';

  @override
  String onbStepOf(int step, int total, String title) {
    return 'Step $step of $total — $title';
  }

  @override
  String get onbTitle => 'Set up your profile';

  @override
  String get orgAcademic => 'Academic institution';

  @override
  String get orgAssociation => 'Association';

  @override
  String get orgBudget => 'Annual budget';

  @override
  String get orgCooperative => 'Cooperative';

  @override
  String get orgHelp =>
      'Fill this in if you look for opportunities on behalf of an organisation.';

  @override
  String get orgName => 'Organisation name';

  @override
  String get orgNgo => 'NGO';

  @override
  String get orgNone => 'No organisation provided.';

  @override
  String get orgPublic => 'Public body';

  @override
  String get orgRegistration => 'Registration number';

  @override
  String get orgSector => 'Sector';

  @override
  String get orgSme => 'SME';

  @override
  String get orgStartup => 'Start-up';

  @override
  String get orgTitle => 'Organisation';

  @override
  String get orgType => 'Organisation type';

  @override
  String get pfAchievements => 'Achievements';

  @override
  String get pfAdd => 'Add';

  @override
  String get pfAddLanguage => 'Add a language';

  @override
  String get pfAddLink => 'Add a link';

  @override
  String get pfAddSkill => 'Add a skill';

  @override
  String get pfAnyMode => 'No preference';

  @override
  String get pfBeneficiaries => 'Beneficiaries';

  @override
  String get pfBio => 'About me';

  @override
  String get pfCertName => 'Certification name';

  @override
  String get pfCertifications => 'Certifications';

  @override
  String get pfCity => 'City';

  @override
  String pfCompleteness(int pct) {
    return 'Profile $pct% complete';
  }

  @override
  String get pfCountry => 'Country';

  @override
  String get pfCredentialUrl => 'Verification link';

  @override
  String get pfCurrency => 'Currency';

  @override
  String get pfCurrentJob => 'Current position';

  @override
  String get pfCustomObjective => 'Other objective…';

  @override
  String get pfDegree => 'Degree';

  @override
  String get pfEducation => 'Education';

  @override
  String get pfEducationLevel => 'Highest education level';

  @override
  String get pfEmployer => 'Employer';

  @override
  String get pfEmploymentType => 'Employment type';

  @override
  String get pfEnd => 'End';

  @override
  String get pfExperience => 'Experience';

  @override
  String get pfExperienceYears => 'Years of experience';

  @override
  String get pfExpiresOn => 'Expires on';

  @override
  String get pfField => 'Field of study';

  @override
  String get pfFullName => 'Full name';

  @override
  String get pfFundingHelp =>
      'Whole amount in the chosen currency (in cents for EUR and USD).';

  @override
  String get pfFundingMax => 'Maximum funding sought';

  @override
  String get pfFundingMin => 'Minimum funding sought';

  @override
  String get pfGeneral => 'General information';

  @override
  String get pfGrade => 'Grade';

  @override
  String get pfImproveHint => 'For more relevant results, complete:';

  @override
  String get pfInstitution => 'Institution';

  @override
  String get pfIssuer => 'Issuer';

  @override
  String get pfJobTitle => 'Job title';

  @override
  String get pfLanguages => 'Languages';

  @override
  String get pfLegalStatus => 'Legal status';

  @override
  String get pfLinkKind => 'Link type';

  @override
  String get pfLinks => 'Links';

  @override
  String get pfLinksLocations => 'Links and locations';

  @override
  String get pfMissingEducation => 'your education';

  @override
  String get pfMissingExperience => 'your experience';

  @override
  String get pfMissingIdentity => 'your name and country';

  @override
  String get pfMissingLanguages => 'your languages';

  @override
  String get pfMissingObjectives => 'your objectives';

  @override
  String get pfMissingPreferences => 'your location preferences';

  @override
  String get pfMissingSkills => 'your skills';

  @override
  String get pfMissingStatus => 'your professional status';

  @override
  String get pfMissions => 'Main responsibilities';

  @override
  String get pfNative => 'Native language';

  @override
  String get pfNothingYet => 'Nothing yet.';

  @override
  String get pfObjectives => 'Objectives';

  @override
  String get pfObjectivesHelp =>
      'What you are looking for: they guide searches and ranking.';

  @override
  String get pfObtainedOn => 'Obtained on';

  @override
  String get pfOccupation => 'Current occupation';

  @override
  String get pfOngoing => 'Ongoing';

  @override
  String get pfPhone => 'Phone';

  @override
  String get pfPhoneHelp => 'Only used in the document drafts you generate.';

  @override
  String get pfPortfolio => 'Portfolio';

  @override
  String get pfPreferredLocations => 'Preferred locations';

  @override
  String get pfProjectDescription => 'Description';

  @override
  String get pfProjectTitle => 'Project name';

  @override
  String get pfProjects => 'Projects';

  @override
  String get pfRegionCentralAfrica => 'All of Central Africa (CEMAC)';

  @override
  String get pfRelocate => 'Willing to relocate';

  @override
  String get pfSkillPrimaryToggle => 'Mark as primary skill';

  @override
  String get pfSkills => 'Skills';

  @override
  String get pfSkillsLanguages => 'Skills and languages';

  @override
  String get pfStage => 'Project stage';

  @override
  String get pfStart => 'Start';

  @override
  String get pfStatus => 'Professional status';

  @override
  String get pfSubtitle =>
      'This information stays on this computer and is used to rank opportunities.';

  @override
  String get pfSummary => 'Profile summary';

  @override
  String get pfSummaryApprove => 'Approve this summary';

  @override
  String get pfSummaryApproved => 'Summary approved';

  @override
  String get pfSummaryGenerate => 'Compose from profile';

  @override
  String get pfSummaryHelp =>
      'Summary composed only from your information. Edit it, then approve it.';

  @override
  String get pfTimeline => 'Planned duration (months)';

  @override
  String get pfWebsite => 'Website';

  @override
  String prefBandwidth(int mb) {
    return 'Maximum data per search: $mb MB';
  }

  @override
  String get prefDataSaver => 'Data saver';

  @override
  String get prefDataSaverHelp =>
      'Does not download detail pages or attachments during searches.';

  @override
  String get prefNetwork => 'Network';

  @override
  String get prefNotifications => 'Notifications';

  @override
  String get prefProxy => 'Proxy (optional)';

  @override
  String get prefReminders => 'Reminders before deadlines';

  @override
  String get prefRemindersHelp =>
      'Days before the deadline, separated by commas (e.g. 14, 7, 3, 1).';

  @override
  String get prefWeights => 'Score weighting';

  @override
  String get prefWeightsHelp =>
      'Adjust how much each criterion counts in the relevance score.';

  @override
  String get prioHigh => 'High';

  @override
  String get prioLow => 'Low';

  @override
  String get prioMedium => 'Medium';

  @override
  String get privConsentAi => 'Processing by an AI service';

  @override
  String get privConsentSync => 'Synchronisation';

  @override
  String get privConsents => 'Consents';

  @override
  String get privDisclosures => 'Data sent to third parties';

  @override
  String get privExportAll => 'Export all my data';

  @override
  String get privImportJson => 'Import a JSON export';

  @override
  String privImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import complete: $count tracked opportunities',
      one: 'Import complete: 1 tracked opportunity',
      zero: 'Import complete',
    );
    return '$_temp0';
  }

  @override
  String get privNoDisclosures =>
      'No personal data has been sent to a third party.';

  @override
  String get privNoTelemetry =>
      'No telemetry: Opportunex sends no usage statistics.';

  @override
  String get privOpportunities => 'Cached opportunities';

  @override
  String get privPortability => 'Portability';

  @override
  String get privPortabilityHelp =>
      'Readable ZIP archive (JSON + files) of all your data, or re-import of a JSON export.';

  @override
  String get privRevoke => 'Withdraw';

  @override
  String privRevokedOn(String date) {
    return 'withdrawn on $date';
  }

  @override
  String get privSearches => 'Searches';

  @override
  String get privStored => 'Stored data';

  @override
  String get privStoredHelp =>
      'Everything is encrypted in this profile\'s local database.';

  @override
  String get psEmployed => 'Employed';

  @override
  String get psEntrepreneur => 'Entrepreneur';

  @override
  String get psFreelancer => 'Freelancer';

  @override
  String get psJobSeeker => 'Job seeker';

  @override
  String get psOther => 'Other';

  @override
  String get psResearcher => 'Researcher';

  @override
  String get psRetired => 'Retired';

  @override
  String get psSelfEmployed => 'Self-employed';

  @override
  String get psStudent => 'Student';

  @override
  String get psUnemployed => 'Unemployed';

  @override
  String get srcActive => 'Active';

  @override
  String get srcAdd => 'Add a source';

  @override
  String get srcAddHelp =>
      'Enter the address of a public page. Opportunex detects an RSS/Atom feed and respects robots.txt.';

  @override
  String srcAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Source added: $count items detected',
      one: 'Source added: 1 item detected',
      zero: 'Source added (no item detected yet)',
    );
    return '$_temp0';
  }

  @override
  String get srcAll => 'All';

  @override
  String srcCount(int shown, int total) {
    return '$shown of $total';
  }

  @override
  String get srcCustom => 'Added by me';

  @override
  String get srcDetect => 'Detect and add';

  @override
  String get srcFailing => 'Failing';

  @override
  String srcLastError(String error) {
    return 'Error: $error';
  }

  @override
  String srcLastSuccess(String date) {
    return 'Last success: $date';
  }

  @override
  String get srcLinkOnly => 'Official link only';

  @override
  String get srcLinks => 'Official links';

  @override
  String get srcName => 'Name (optional)';

  @override
  String srcOppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opportunities',
      one: '1 opportunity',
    );
    return '$_temp0';
  }

  @override
  String get srcPolicy =>
      'Opportunex only queries public sources, respects robots.txt and terms of use, and spaces out its requests. Portals without a feed are offered as an official link.';

  @override
  String srcReliability(int pct) {
    return 'Reliability $pct%';
  }

  @override
  String get srcSubtitle =>
      'Catalogue of public sources queried during searches';

  @override
  String get stAccepted => 'Accepted';

  @override
  String get stArchived => 'Archived';

  @override
  String get stDiscovered => 'Discovered';

  @override
  String get stExpired => 'Expired';

  @override
  String get stInterview => 'Interview';

  @override
  String get stPreparing => 'Preparing';

  @override
  String get stReady => 'Ready to submit';

  @override
  String get stRejected => 'Rejected';

  @override
  String get stSubmitted => 'Submitted';

  @override
  String get stToReview => 'To review';

  @override
  String get stWithdrawn => 'Withdrawn';

  @override
  String get stgEarly => 'Early stage';

  @override
  String get stgEstablished => 'Established';

  @override
  String get stgGrowth => 'Growth';

  @override
  String get stgIdea => 'Idea';

  @override
  String get stgPrototype => 'Prototype';

  @override
  String get stgScale => 'Scaling';

  @override
  String get trackAddEvent => 'Add an event';

  @override
  String get trackAddItem => 'Add an item';

  @override
  String get trackAddNote => 'Add a note';

  @override
  String get trackAddTag => 'Add a tag';

  @override
  String get trackAllPriorities => 'All priorities';

  @override
  String get trackAllStatuses => 'All statuses';

  @override
  String get trackAllTags => 'All tags';

  @override
  String get trackArchive => 'Archive';

  @override
  String get trackArchived => 'Archived';

  @override
  String get trackAttach => 'Attach a file';

  @override
  String get trackBoard => 'Board';

  @override
  String get trackCalendar => 'Calendar';

  @override
  String get trackChecklist => 'Checklist';

  @override
  String get trackChecklistEmpty =>
      'No items. Documents required by the listing appear here when known.';

  @override
  String trackChecklistProgress(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get trackDocumentLabel => 'Document label';

  @override
  String get trackDocuments => 'Attached documents';

  @override
  String get trackDocumentsHelp => 'Files are encrypted in your local vault.';

  @override
  String get trackDownload => 'Save a copy';

  @override
  String get trackDropHere => 'Drop here';

  @override
  String get trackEmptyBody =>
      'Save opportunities from search results to track them here.';

  @override
  String get trackEmptyTitle => 'No tracked opportunities';

  @override
  String get trackEventContact => 'Contact';

  @override
  String get trackEventLocation => 'Location';

  @override
  String get trackEventTitle => 'Title';

  @override
  String get trackEventType => 'Type';

  @override
  String get trackEventWhen => 'Date and time';

  @override
  String get trackEvents => 'Events and contacts';

  @override
  String get trackFromListing => 'Required by the listing';

  @override
  String get trackHistory => 'History';

  @override
  String get trackIneligible => 'Not eligible';

  @override
  String get trackIneligibleReason => 'Reason (optional)';

  @override
  String get trackInterest => 'Interest';

  @override
  String get trackInterested => 'Interested';

  @override
  String get trackList => 'List';

  @override
  String get trackNoDocuments => 'No attached documents.';

  @override
  String get trackNoEvents => 'No events.';

  @override
  String get trackNoPersonalDeadline => 'No personal deadline';

  @override
  String get trackNoteHint => 'Write a note…';

  @override
  String get trackNotes => 'Notes';

  @override
  String get trackOpenSheet => 'Open the sheet';

  @override
  String get trackPersonalDeadline => 'Personal deadline';

  @override
  String get trackPriority => 'Priority';

  @override
  String get trackReminders => 'Scheduled reminders';

  @override
  String get trackSearchHint => 'Filter by title or organisation';

  @override
  String get trackSettings => 'Tracking';

  @override
  String get trackStatus => 'Status';

  @override
  String trackStatusChanged(String status) {
    return 'Status updated: $status';
  }

  @override
  String get trackSubmittedOn => 'Submission date';

  @override
  String get trackTag => 'Tag';

  @override
  String get trackUnarchive => 'Unarchive';

  @override
  String get trackUndecided => 'Undecided';

  @override
  String get trackUnsave => 'Stop tracking';

  @override
  String get trackUnsaveConfirm =>
      'This application\'s notes, documents and history will be deleted.';

  @override
  String wsCompare(int count) {
    return 'Compare ($count)';
  }

  @override
  String wsCounts(int queries, int saved, int opportunities) {
    return '$queries searches · $saved tracked · $opportunities opportunities';
  }

  @override
  String get wsCreate => 'New workspace';

  @override
  String get wsEmptyBody =>
      'A workspace groups searches, opportunities and notes around a project.';

  @override
  String get wsEmptyTitle => 'No workspaces';

  @override
  String get wsName => 'Workspace name';

  @override
  String get wsNoOpportunities => 'No opportunities in this workspace.';

  @override
  String get wsNoQueries => 'No searches saved in this workspace.';

  @override
  String get wsNoTemplate => 'Blank';

  @override
  String get wsOpportunities => 'Opportunities';

  @override
  String get wsQueries => 'Searches';

  @override
  String get wsRemove => 'Remove from workspace';

  @override
  String get wsSearchHere => 'Search in this workspace';

  @override
  String get wsSubtitle => 'Organise your searches by project';

  @override
  String get wsTemplate => 'Template';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get genSaved => 'Version saved';

  @override
  String get prefCloseToTray =>
      'Keep running in the notification area when closed';

  @override
  String get prefCloseToTrayHelp =>
      'Monitors and reminders only run while the app is open; closing the window then minimises it next to the clock.';

  @override
  String get trayOpen => 'Open Opportunex';

  @override
  String get trayQuit => 'Quit';

  @override
  String get trayStillRunning =>
      'Opportunex keeps running in the notification area to run your monitors. Right-click the icon to quit.';

  @override
  String get aiAddProvider => 'Add a provider';

  @override
  String get aiAllow => 'Allow';

  @override
  String get aiAnalyze => 'Analyse with AI';

  @override
  String aiAnalyzed(int applied, int unverifiable) {
    return 'Analysis done: $applied verified fields added, $unverifiable unverifiable';
  }

  @override
  String get aiBaseUrl => 'Service address (optional)';

  @override
  String get aiBaseUrlHelp =>
      'HTTPS is required, except for a server on this computer.';

  @override
  String get aiBaseUrlRequired => 'Service address';

  @override
  String get aiConsentGiven => 'consent given';

  @override
  String aiConsentIntro(String provider) {
    return 'For this action, Opportunex must send data to $provider, an online service:';
  }

  @override
  String get aiConsentNever =>
      'Your name, contact details, links and identifiers are never sent. Every send is listed in the privacy dashboard.';

  @override
  String get aiConsentRevoke =>
      'You can withdraw this consent at any time in Settings > Privacy.';

  @override
  String aiConsentTitle(String provider) {
    return 'Send data to $provider?';
  }

  @override
  String get aiDeleteConfirm =>
      'The provider and its key (removed from the system keychain) will be deleted.';

  @override
  String get aiDisplayName => 'Display name';

  @override
  String get aiEnable => 'Turn on AI features';

  @override
  String get aiEnableHelp =>
      'Off by default. Every feature works without AI; AI only helps to structure, summarise, translate and draft.';

  @override
  String get aiErrAuth => 'The provider rejected the API key.';

  @override
  String get aiErrNetwork =>
      'Service unreachable. Check the connection and address.';

  @override
  String aiErrOther(String code) {
    return 'Provider error ($code).';
  }

  @override
  String get aiErrRateLimited =>
      'The provider\'s quota is reached. Try again later.';

  @override
  String get aiErrTimeout => 'The provider did not answer in time.';

  @override
  String get aiFieldAmount => 'Amount';

  @override
  String get aiFieldApplicationUrl => 'Application link';

  @override
  String get aiFieldAudience => 'Target audience';

  @override
  String get aiFieldCategory => 'Category';

  @override
  String get aiFieldCountry => 'Country';

  @override
  String get aiFieldCurrency => 'Currency';

  @override
  String get aiFieldOrganization => 'Organisation';

  @override
  String get aiFields => 'Information extracted by AI';

  @override
  String get aiKey => 'API key';

  @override
  String get aiKeyHelp =>
      'Kept in the system\'s secure keychain, never in the database or the logs.';

  @override
  String get aiKeyMissing => 'key missing';

  @override
  String get aiKeyReplace =>
      'New API key (leave empty to keep the current one)';

  @override
  String get aiKind => 'Provider';

  @override
  String get aiKindLmStudio => 'LM Studio (on this computer)';

  @override
  String get aiKindOllama => 'Ollama (on this computer)';

  @override
  String get aiKindOpenAi => 'OpenAI-compatible (custom address)';

  @override
  String get aiLocal => 'on this computer';

  @override
  String get aiLocalHelp =>
      'Model running on this computer: no data leaves the machine and no consent is needed.';

  @override
  String get aiModel => 'Model';

  @override
  String get aiModelHelp =>
      'Exact model name; \"Test\" lists the available models.';

  @override
  String aiModelNotListed(String model) {
    return 'The model \"$model\" is not in the list: pick one below.';
  }

  @override
  String aiModelsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count models available',
      one: '1 model available',
      zero: 'No model listed',
    );
    return '$_temp0';
  }

  @override
  String get aiMoveDown => 'Move down the fallback order';

  @override
  String get aiMoveUp => 'Move up the fallback order';

  @override
  String get aiNoProvider => 'No provider configured.';

  @override
  String get aiProviderAdded =>
      'Provider added. Use \"Test\" to check the connection.';

  @override
  String get aiProviders => 'Providers and fallback order';

  @override
  String get aiProvidersHelp =>
      'Providers are tried in this order; as a last resort the application uses its rules without AI.';

  @override
  String get aiPurposeContent =>
      'The text needed for the task (query or public announcement)';

  @override
  String get aiPurposeCv =>
      'Your CV text, without name, e-mail, phone or links';

  @override
  String get aiPurposeProfile =>
      'Your anonymised profile (education, experience, skills, languages)';

  @override
  String get aiRemote => 'online service';

  @override
  String get aiRemoteHelp =>
      'Online service: you will be asked for consent before the first send, and every send is logged.';

  @override
  String get aiRouting => 'Model per task';

  @override
  String get aiRoutingAuto => 'Automatic (fallback order)';

  @override
  String get aiRoutingHelp => 'Pick a specific provider for some tasks.';

  @override
  String get aiRule1 =>
      'Extracted values are checked against the announcement text; otherwise they are marked \"Unverifiable\".';

  @override
  String get aiRule2 =>
      'The relevance score is still computed without AI, in an explainable way.';

  @override
  String get aiRule3 =>
      'Drafts only use your validated profile; any invented addition is flagged.';

  @override
  String get aiRule4 =>
      'Local models (Ollama, LM Studio) keep all data on this computer.';

  @override
  String get aiSummary => 'AI-generated summary';

  @override
  String get aiTaskCv => 'CV parsing';

  @override
  String get aiTaskDrafting => 'Document drafting';

  @override
  String get aiTaskExtraction => 'Announcement analysis';

  @override
  String get aiTaskQuery => 'Search interpretation';

  @override
  String get aiTaskTranslation => 'Translation';

  @override
  String get aiTest => 'Test';

  @override
  String get aiTestFailed => 'test failed';

  @override
  String aiTestOk(String date) {
    return 'tested on $date';
  }

  @override
  String get aiTestSuccess => 'Connection successful';

  @override
  String get aiTitle => 'Artificial intelligence';

  @override
  String get aiTranslate => 'Translate';

  @override
  String get aiUnavailable =>
      'AI could not process the request; the information obtained without AI is still shown.';

  @override
  String get aiUsage => 'Usage';

  @override
  String get aiUsageCache => 'Cache';

  @override
  String get aiUsageCalls => 'Calls';

  @override
  String get aiUsageDay => 'Day';

  @override
  String get aiUsageEmpty => 'No calls yet.';

  @override
  String get aiUsageErrors => 'Errors';

  @override
  String get aiUsageHelp =>
      'Last 30 days, per provider. Tokens are those reported by the provider.';

  @override
  String get aiUsageProvider => 'Provider';

  @override
  String get aiUsageRules => 'Fallback without AI';

  @override
  String get aiUsageTokens => 'Tokens';

  @override
  String get aiWithout => 'Continue without AI';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get cvUseAi => 'Analyse with AI';

  @override
  String get cvUseAiHelp =>
      'The CV text is sent without name, e-mail, phone or links; every item still needs your validation.';

  @override
  String get genFromTemplate => 'Built-in template';

  @override
  String get genFromTemplateHelp => 'Written locally from your profile.';

  @override
  String get genWithAi => 'Draft with AI';

  @override
  String get genWithAiHelp =>
      'From your anonymised profile; additions not in the profile are flagged.';

  @override
  String get provUnverifiable => 'Unverifiable';

  @override
  String get settingsAi => 'AI';

  @override
  String get compareGone => 'Gone';

  @override
  String get compareModified => 'Modified';

  @override
  String get compareNew => 'New';

  @override
  String get compareSame => 'No difference between the two runs.';

  @override
  String dashDaysShort(int days) {
    return 'D-$days';
  }

  @override
  String get freqDaily => 'daily';

  @override
  String freqEveryDays(int days) {
    return 'every $days days';
  }

  @override
  String freqEveryHours(int hours) {
    return 'every $hours h';
  }

  @override
  String get freqMonthly => 'monthly';

  @override
  String get freqWeekly => 'weekly';

  @override
  String get historyCompare => 'Compare with the previous run';

  @override
  String get monHistory => 'History';

  @override
  String get monHistoryEmpty => 'No runs yet.';

  @override
  String monHistoryLine(String date, int created, int updated) {
    return '$date · $created new · $updated changed';
  }

  @override
  String get paletteEmpty => 'No matching command.';

  @override
  String paletteGoTo(String section) {
    return 'Go to: $section';
  }

  @override
  String get paletteHint => 'Type a command or a page…';

  @override
  String get paletteTheme => 'Switch theme (light, dark, system)';

  @override
  String get prefAutoArchive => 'Archive closed applications';

  @override
  String get prefAutoArchiveHelp =>
      'Accepted, rejected, withdrawn or expired, with no activity for this long.';

  @override
  String get prefAutostart =>
      'Start Opportunex when you sign in to the computer';

  @override
  String get prefAutostartHelp =>
      'The app starts minimised in the notification area to run your monitors.';

  @override
  String prefDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'after $days days',
      one: 'after 1 day',
    );
    return '$_temp0';
  }

  @override
  String get prefNever => 'never';

  @override
  String get prefTracking => 'Tracking and start-up';

  @override
  String runUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources to check manually',
      one: '1 source to check manually',
    );
    return '$_temp0';
  }

  @override
  String get shortcutClose => 'Close a dialog';

  @override
  String get shortcutHelp => 'Show this help';

  @override
  String get shortcutPalette => 'Command palette';

  @override
  String get shortcutSearch => 'New search';

  @override
  String get shortcutSections => 'Go to a menu section';

  @override
  String get shortcutsTitle => 'Keyboard shortcuts';

  @override
  String get srcCategories => 'Categories covered';

  @override
  String get srcFrequency => 'Scan frequency';

  @override
  String get srcFrequencyHelp =>
      'Never more than once an hour; politeness delays and robots.txt still apply.';

  @override
  String get srcSettings => 'Frequency and categories';

  @override
  String strEducation(String level) {
    return 'Education level met: $level';
  }

  @override
  String strExperience(String years) {
    return 'Enough experience (at least $years years required)';
  }

  @override
  String get strLanguages => 'Required languages mastered';

  @override
  String strLocation(String country) {
    return 'Wanted country: $country';
  }

  @override
  String strObjective(String objective) {
    return 'Matches your objective: $objective';
  }

  @override
  String get strRemote => 'Remote work possible';

  @override
  String strSkills(String skills) {
    return 'Skills: $skills';
  }

  @override
  String a11yToggle(String name) {
    return 'Turn on or off: $name';
  }

  @override
  String a11ySelect(String title) {
    return 'Select: $title';
  }
}
