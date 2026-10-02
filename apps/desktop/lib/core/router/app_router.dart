import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import necessary files when they are created
// import '../../features/auth/presentation/providers/auth_provider.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth state changes to redirect
  // final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    // redirect: (context, state) {
    //   final isLoggingIn = state.matchedLocation == '/login' ||
    //       state.matchedLocation == '/register' ||
    //       state.matchedLocation == '/recover' ||
    //       state.matchedLocation == '/local-profiles';
    //
    //   if (authState.isLoading) return null;
    //
    //   final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
    //
    //   if (!isAuthenticated && !isLoggingIn) return '/login';
    //   if (isAuthenticated && isLoggingIn) return '/dashboard';
    //   return null;
    // },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Login'))),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Register'))),
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
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Onboarding'))),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return Scaffold(
            body: Row(
              children: [
                const SizedBox(
                  width: 250,
                  child: Center(child: Text('Sidebar')),
                ),
                Expanded(child: child),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const Center(child: Text('Dashboard')),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const Center(child: Text('Search')),
          ),
          GoRoute(
            path: '/results/:runId',
            builder: (context, state) =>
                Center(child: Text('Results ${state.pathParameters['runId']}')),
          ),
          GoRoute(
            path: '/saved',
            builder: (context, state) => const Center(child: Text('Saved')),
          ),
          GoRoute(
            path: '/applications',
            builder: (context, state) =>
                const Center(child: Text('Applications')),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => Center(
                  child: Text('Application ${state.pathParameters['id']}'),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/monitors',
            builder: (context, state) => const Center(child: Text('Monitors')),
          ),
          GoRoute(
            path: '/workspaces',
            builder: (context, state) =>
                const Center(child: Text('Workspaces')),
          ),
          GoRoute(
            path: '/sources',
            builder: (context, state) => const Center(child: Text('Sources')),
          ),
          GoRoute(
            path: '/organizations',
            builder: (context, state) =>
                const Center(child: Text('Organizations')),
          ),
          GoRoute(
            path: '/opportunities/:id',
            builder: (context, state) => Center(
              child: Text('Opportunity ${state.pathParameters['id']}'),
            ),
          ),
          GoRoute(
            path: '/settings/account',
            builder: (context, state) =>
                const Center(child: Text('Settings Account')),
          ),
          GoRoute(
            path: '/settings/profile',
            builder: (context, state) =>
                const Center(child: Text('Settings Profile')),
          ),
          GoRoute(
            path: '/settings/ai',
            builder: (context, state) =>
                const Center(child: Text('Settings AI')),
          ),
          GoRoute(
            path: '/settings/privacy',
            builder: (context, state) =>
                const Center(child: Text('Settings Privacy')),
          ),
          GoRoute(
            path: '/settings/notifications',
            builder: (context, state) =>
                const Center(child: Text('Settings Notifications')),
          ),
          GoRoute(
            path: '/settings/appearance',
            builder: (context, state) =>
                const Center(child: Text('Settings Appearance')),
          ),
          GoRoute(
            path: '/settings/network',
            builder: (context, state) =>
                const Center(child: Text('Settings Network')),
          ),
          GoRoute(
            path: '/settings/backups',
            builder: (context, state) =>
                const Center(child: Text('Settings Backups')),
          ),
          GoRoute(
            path: '/settings/sync',
            builder: (context, state) =>
                const Center(child: Text('Settings Sync')),
          ),
          GoRoute(
            path: '/settings/about',
            builder: (context, state) =>
                const Center(child: Text('Settings About')),
          ),
        ],
      ),
    ],
  );
});
