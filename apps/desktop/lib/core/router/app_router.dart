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
import '../../features/dashboard/dashboard_page.dart';
import '../../features/legal/legal_page.dart';
import '../../features/monitors/monitors_page.dart';
import '../../features/opportunity/opportunity_page.dart';
import '../../features/profile/cv_import_page.dart';
import '../../features/profile/onboarding_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/search/search_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/shell/app_shell.dart';
import '../../features/shell/nav_items.dart';
import '../../features/sources/sources_page.dart';
import '../../features/startup/startup_page.dart';
import '../../features/sync/orgs_page.dart';
import '../../features/tracking/application_page.dart';
import '../../features/tracking/saved_page.dart';
import '../../features/workspaces/workspaces_page.dart';
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
    case SignedIn(:final user, :final recoveryPhrase):
      if (recoveryPhrase != null) return location == '/register' ? null : '/register';
      if (location == '/startup' || (_signedOutRoutes.contains(location) && location != '/legal')) {
        // Right after registration the guided onboarding opens (EF-02.01); it can be left and resumed
        // from the profile page, so later sign-ins land on the dashboard.
        return location == '/register' && !user.onboardingCompleted ? '/onboarding' : homePath;
      }
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
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/dashboard', pageBuilder: (_, s) => NoTransitionPage(key: s.pageKey, child: const DashboardPage())),
          GoRoute(
            path: '/search',
            pageBuilder: (_, s) => NoTransitionPage(
              key: s.pageKey,
              child: SearchPage(initialQuery: s.uri.queryParameters['q'], runId: s.uri.queryParameters['run']),
            ),
          ),
          GoRoute(
            path: '/opportunities/:id',
            builder: (_, s) => OpportunityPage(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/saved',
            pageBuilder: (_, s) => NoTransitionPage(
              key: s.pageKey,
              child: TrackingPage(initialTab: int.tryParse(s.uri.queryParameters['tab'] ?? '') ?? 0),
            ),
          ),
          GoRoute(path: '/saved/:id', builder: (_, s) => ApplicationPage(savedId: s.pathParameters['id']!)),
          GoRoute(path: '/monitors', pageBuilder: (_, s) => NoTransitionPage(key: s.pageKey, child: const MonitorsPage())),
          GoRoute(path: '/workspaces', pageBuilder: (_, s) => NoTransitionPage(key: s.pageKey, child: const WorkspacesPage())),
          GoRoute(path: '/workspaces/:id', builder: (_, s) => WorkspacePage(id: s.pathParameters['id']!)),
          GoRoute(path: '/orgs', pageBuilder: (_, s) => NoTransitionPage(key: s.pageKey, child: const OrgsPage())),
          GoRoute(path: '/orgs/:id', builder: (_, s) => OrgPage(id: s.pathParameters['id']!)),
          GoRoute(path: '/sources', pageBuilder: (_, s) => NoTransitionPage(key: s.pageKey, child: const SourcesPage())),
          GoRoute(path: '/profile', pageBuilder: (_, s) => NoTransitionPage(key: s.pageKey, child: const ProfilePage())),
          GoRoute(path: '/profile/cv', builder: (_, _) => const CvImportPage()),
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
