import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../api/api_exception.dart';

/// Localised, user-facing message for any error thrown by repositories.
String errorText(BuildContext context, Object error) {
  final l = AppLocalizations.of(context);
  // Messages already written for the user (e.g. "AI unavailable") are shown as they are.
  if (error is String) return error;
  if (error is! ApiException) return l.commonUnknownError;
  return switch (error.code) {
    'invalid_credentials' => l.errInvalidCredentials,
    'account_locked' when error.retryAfterSeconds != null => l.authLockedFor(error.retryAfterSeconds!),
    'account_locked' => l.errAccountLocked,
    'email_taken' => l.errEmailTaken,
    'password_policy' => l.errPasswordPolicy,
    'password_mismatch' => l.errPasswordMismatch,
    'terms_not_accepted' => l.errTermsNotAccepted,
    'invalid_recovery' => l.errInvalidRecovery,
    'session_locked' || 'invalid_session' || 'not_authenticated' => l.errSessionLocked,
    'engine_unreachable' => l.errEngineUnreachable,
    'validation_failed' => l.errValidation,
    'not_found' => l.errNotFound,
    'profile_corrupted' => l.errProfileCorrupted,
    'upstream_unavailable' => l.errUpstream,
    'sync_invalid_credentials' => l.errInvalidCredentials,
    'sync_account_locked' => l.errAccountLocked,
    'sync_email_taken' => l.errEmailTaken,
    'sync_email_not_verified' => l.errSyncEmailNotVerified,
    'sync_totp_required' => l.errSyncTotpRequired,
    'sync_totp_invalid' => l.errSyncTotpInvalid,
    'sync_token_invalid' => l.errSyncCodeInvalid,
    'sync_unreachable' => l.errSyncUnreachable,
    'sync_url_insecure' => l.errSyncUrlInsecure,
    'sync_url_invalid' => l.errSyncUrlInvalid,
    'sync_pairing_code_mismatch' => l.errSyncPairingMismatch,
    'sync_invite_invalid' => l.errSyncInviteInvalid,
    'sync_invite_other_email' => l.errSyncInviteOtherEmail,
    'sync_last_owner' => l.errSyncLastOwner,
    'sync_quota_exceeded' => l.errSyncQuota,
    'sync_registration_closed' => l.errSyncRegistrationClosed,
    'sync_rate_limited' => l.errSyncRateLimited,
    _ => error.detail ?? l.commonUnknownError,
  };
}
