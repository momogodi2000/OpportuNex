import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/engine_events.dart';
import '../../core/prefs/ui_prefs.dart';
import 'auth_models.dart';

/// Single source of truth for who is signed in. Reacts to engine restarts, auto-lock
/// events and 401 `session_locked` answers from any request.
class AuthController extends Notifier<AuthState> {
  ApiClient? _api;

  @override
  AuthState build() {
    final api = ref.watch(apiClientProvider);
    _api = api;
    if (api == null) return const AuthUnknown();
    api.onSessionLost = (_) => unawaited(refresh());
    ref.listen(engineEventsProvider, (_, next) {
      final type = next.valueOrNull?.type;
      if (type == 'auth.locked' || type == 'auth.account_deleted') unawaited(refresh());
    });
    unawaited(refresh());
    return const AuthUnknown();
  }

  ApiClient get _client {
    final api = _api;
    if (api == null) throw ApiException.offline();
    return api;
  }

  Future<List<LocalProfile>> _profiles() async {
    final r = await _client.getJson('/auth/profiles');
    return (r['items'] as List<dynamic>).cast<Map<String, dynamic>>().map(LocalProfile.fromJson).toList();
  }

  Future<void> refresh() async {
    try {
      final status = await _client.getJson('/auth/status');
      switch (status['state']) {
        case 'signed_in' when _client.sessionToken != null:
          final me = await _client.getJson('/auth/me');
          state = SignedIn(AppUser.fromJson(me));
        case 'locked':
          _client.sessionToken = null;
          state = LockedOut(
            profileId: status['profile_id'] as String,
            reason: status['reason'] as String? ?? 'manual',
            profiles: await _profiles(),
          );
        default:
          _client.sessionToken = null;
          state = SignedOut(await _profiles());
      }
    } on ApiException {
      state = const AuthUnknown();
    }
  }

  Future<void> _signedIn(Json body, {bool keepPhrase = false}) async {
    _client.sessionToken = body['session_token'] as String;
    final user = AppUser.fromJson(body['user'] as Map<String, dynamic>);
    state = SignedIn(user, recoveryPhrase: keepPhrase ? body['recovery_phrase'] as String? : null);
    final prefs = ref.read(uiPrefsProvider.notifier);
    await prefs.setLastProfile(user.id);
    await prefs.setLocale(user.locale);
    await prefs.setTheme(themeModeFromName(user.theme));
  }

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
    required String confirmPassword,
    required String locale,
    required bool acceptTerms,
  }) async {
    final body = await _client.postJson('/auth/register', body: {
      'display_name': displayName,
      'email': email,
      'password': password,
      'confirm_password': confirmPassword,
      'locale': locale,
      'accept_terms': acceptTerms,
    });
    await _signedIn(body, keepPhrase: true);
  }

  void acknowledgeRecoveryPhrase() {
    final s = state;
    if (s is SignedIn) state = SignedIn(s.user);
  }

  Future<void> login(String email, String password) async =>
      _signedIn(await _client.postJson('/auth/login', body: {'email': email, 'password': password}));

  Future<void> unlock(String profileId, String password) async =>
      _signedIn(await _client.postJson('/auth/unlock', body: {'profile_id': profileId, 'password': password}));

  Future<void> recover({
    required String email,
    required String phrase,
    required String newPassword,
    required String confirmPassword,
  }) async =>
      _signedIn(await _client.postJson('/auth/recover', body: {
        'email': email,
        'recovery_phrase': phrase,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      }));

  Future<void> lock() async {
    try {
      await _client.postJson('/auth/lock');
    } finally {
      await refresh();
    }
  }

  Future<void> logout() async {
    try {
      await _client.postJson('/auth/logout');
    } finally {
      _client.sessionToken = null;
      await refresh();
    }
  }

  Future<void> updatePreferences({String? displayName, String? locale, String? theme, int? autoLockMinutes}) async {
    final me = await _client.patchJson('/auth/me', body: {
      if (displayName != null) 'display_name': displayName,
      if (locale != null) 'preferred_locale': locale,
      if (theme != null) 'theme': theme,
      if (autoLockMinutes != null) 'auto_lock_minutes': autoLockMinutes,
    });
    state = SignedIn(AppUser.fromJson(me));
    final prefs = ref.read(uiPrefsProvider.notifier);
    if (locale != null) await prefs.setLocale(locale);
    if (theme != null) await prefs.setTheme(themeModeFromName(theme));
  }

  /// Called by the onboarding flow once the profile is complete.
  void markOnboarded() {
    final s = state;
    if (s is SignedIn) state = SignedIn(s.user.copyWith(onboardingCompleted: true));
  }

  Future<Json> passwordStrength(String password, List<String> hints) =>
      _client.postJson('/auth/password-strength', body: {'password': password, 'hints': hints});

  Future<void> changePassword(String current, String next, String confirm) => _client.putJson('/auth/password', body: {
        'current_password': current,
        'new_password': next,
        'confirm_password': confirm,
      });

  Future<void> deleteAccount(String password) async {
    await _client.postJson('/auth/account/delete', body: {'password': password, 'confirmation': 'DELETE'});
    _client.sessionToken = null;
    await refresh();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
