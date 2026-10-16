import 'package:flutter/foundation.dart';

@immutable
class LocalProfile {
  const LocalProfile({required this.id, required this.displayName, required this.locale, this.lastLoginAt});

  factory LocalProfile.fromJson(Map<String, dynamic> j) => LocalProfile(
        id: j['id'] as String,
        displayName: j['display_name'] as String,
        locale: j['locale'] as String? ?? 'fr',
        lastLoginAt: j['last_login_at'] as String?,
      );

  final String id;
  final String displayName;
  final String locale;
  final String? lastLoginAt;
}

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.accountMode,
    required this.locale,
    required this.theme,
    required this.autoLockMinutes,
    required this.onboardingCompleted,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        email: j['email'] as String,
        displayName: j['display_name'] as String,
        accountMode: j['account_mode'] as String? ?? 'local',
        locale: j['preferred_locale'] as String? ?? 'fr',
        theme: j['theme'] as String? ?? 'system',
        autoLockMinutes: (j['auto_lock_minutes'] as num?)?.toInt() ?? 15,
        onboardingCompleted: j['onboarding_completed'] as bool? ?? false,
      );

  final String id;
  final String email;
  final String displayName;
  final String accountMode;
  final String locale;
  final String theme;
  final int autoLockMinutes;
  final bool onboardingCompleted;

  bool get isSynced => accountMode == 'synced';

  AppUser copyWith({bool? onboardingCompleted, String? displayName, String? locale, String? theme, int? autoLockMinutes}) =>
      AppUser(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        accountMode: accountMode,
        locale: locale ?? this.locale,
        theme: theme ?? this.theme,
        autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      );
}

sealed class AuthState {
  const AuthState();
}

/// Engine not ready yet or status not fetched.
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class SignedOut extends AuthState {
  const SignedOut(this.profiles);
  final List<LocalProfile> profiles;
}

class LockedOut extends AuthState {
  const LockedOut({required this.profileId, required this.reason, required this.profiles});
  final String profileId;
  final String reason;
  final List<LocalProfile> profiles;
}

class SignedIn extends AuthState {
  const SignedIn(this.user, {this.recoveryPhrase});
  final AppUser user;

  /// Shown once right after registration, then cleared.
  final String? recoveryPhrase;
}
