import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/saved/presentation/pages/saved_page.dart';
import '../../features/applications/presentation/pages/applications_page.dart';
import '../../features/opportunity/presentation/pages/opportunity_detail_page.dart';
import '../../features/monitors/presentation/pages/monitors_page.dart';
import '../../features/workspaces/presentation/pages/workspaces_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/recover',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Recover'))),
      ),
      GoRoute(
        path: '/local-profiles',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Local Profiles'))),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 250,
                  child: ListView(
                    children: [
                      ListTile(
                        title: const Text('Dashboard'),
                        onTap: () => context.go('/dashboard'),
                      ),
                      ListTile(
                        title: const Text('Search'),
                        onTap: () => context.go('/search'),
                      ),
                      ListTile(
                        title: const Text('Saved'),
                        onTap: () => context.go('/saved'),
                      ),
                      ListTile(
                        title: const Text('Applications'),
                        onTap: () => context.go('/applications'),
                      ),
                      ListTile(
                        title: const Text('Monitors'),
                        onTap: () => context.go('/monitors'),
                      ),
                      ListTile(
                        title: const Text('Settings'),
                        onTap: () => context.go('/settings/account'),
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: '/results/:runId',
            builder: (context, state) => Scaffold(
              body: Center(
                child: Text('Results ${state.pathParameters['runId']}'),
              ),
            ),
          ),
          GoRoute(
            path: '/saved',
            builder: (context, state) => const SavedPage(),
          ),
          GoRoute(
            path: '/applications',
            builder: (context, state) => const ApplicationsPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => Scaffold(
                  body: Center(
                    child: Text('Application ${state.pathParameters['id']}'),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/monitors',
            builder: (context, state) => const MonitorsPage(),
          ),
          GoRoute(
            path: '/workspaces',
            builder: (context, state) => const WorkspacesPage(),
          ),
          GoRoute(
            path: '/sources',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Sources'))),
          ),
          GoRoute(
            path: '/organizations',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Organizations'))),
          ),
          GoRoute(
            path: '/opportunities/:id',
            builder: (context, state) => OpportunityDetailPage(
              opportunityId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: '/settings/account',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/settings/profile',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/settings/ai',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/settings/privacy',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/settings/notifications',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/settings/appearance',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/settings/network',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/settings/backups',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/settings/sync',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/settings/about',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});
