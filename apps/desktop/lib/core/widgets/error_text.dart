import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../api/api_exception.dart';

/// Localised, user-facing message for any error thrown by repositories.
String errorText(BuildContext context, Object error) {
  final l = AppLocalizations.of(context);
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
    _ => error.detail ?? l.commonUnknownError,
  };
}
