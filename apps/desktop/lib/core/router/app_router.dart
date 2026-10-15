import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_models.dart';
import '../../features/auth/pages/import_profile_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/recover_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/auth/pages/welcome_page.dart';
import '../../features/legal/legal_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/shell/app_shell.dart';
import '../../features/shell/nav_items.dart';
import '../../features/startup/startup_page.dart';
import '../engine/engine_supervisor.dart';

const _signedOutRoutes = {'/welcome', '/login', '/register', '/recover', '/import-profile', '/legal'};
const _lockedRoutes = {'/login', '/welcome', '/recover', '/legal'};

/// Pure redirect rules, unit-tested without a widget tree.
String? redirectFor({required EngineStatus engine, required AuthState auth, required String location}) {
  if (!engine.isReady || auth is AuthUnknown) return location == '/startup' ? null : '/startup';
  switch (auth) {
    case SignedOut():
      return _signedOutRoutes.contains(location) ? null : '/welcome';
    case LockedOut():
      return _lockedRoutes.contains(location) ? null : '/login';
    case SignedIn(:final recoveryPhrase):
      if (recoveryPhrase != null) return location == '/register' ? null : '/register';
      if (location == '/startup' || (_signedOutRoutes.contains(location) && location != '/legal')) return homePath;
      return null;
    case AuthUnknown():
      return '/startup';
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(engineSupervisorProvider, (_, _) => refresh.value++)
    ..listen(authControllerProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/startup',
    refreshListenable: refresh,
    redirect: (context, state) => redirectFor(
      engine: ref.read(engineSupervisorProvider),
      auth: ref.read(authControllerProvider),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => homePath),
      GoRoute(path: '/startup', builder: (_, _) => const StartupPage()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomePage()),
      GoRoute(path: '/login', builder: (_, s) => LoginPage(profileId: s.uri.queryParameters['profile'])),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      GoRoute(path: '/recover', builder: (_, _) => const RecoverPage()),
      GoRoute(path: '/import-profile', builder: (_, _) => const ImportProfilePage()),
      GoRoute(path: '/legal', builder: (_, _) => const LegalPage()),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/settings',
            pageBuilder: (_, s) => NoTransitionPage(
              child: SettingsPage(initialTab: int.tryParse(s.uri.queryParameters['tab'] ?? '') ?? 0),
            ),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
