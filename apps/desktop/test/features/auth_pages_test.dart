import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:opportunex/core/api/api_exception.dart';
import 'package:opportunex/core/theme/app_theme.dart';
import 'package:opportunex/features/auth/auth_controller.dart';
import 'package:opportunex/features/auth/auth_models.dart';
import 'package:opportunex/features/auth/pages/login_page.dart';
import 'package:opportunex/features/auth/pages/register_page.dart';
import 'package:opportunex/features/auth/pages/welcome_page.dart';
import 'package:opportunex/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuth extends AuthController {
  FakeAuth(this.initial);
  final AuthState initial;
  final calls = <String>[];
  Object? failWith;

  @override
  AuthState build() => initial;

  @override
  Future<void> login(String email, String password) async {
    calls.add('login:$email');
    if (failWith != null) throw failWith!;
  }

  @override
  Future<void> unlock(String profileId, String password) async {
    calls.add('unlock:$profileId');
    if (failWith != null) throw failWith!;
  }

  @override
  Future<Map<String, dynamic>> passwordStrength(String password, List<String> hints) async =>
      {'score': password.length >= 12 ? 4 : 0, 'problems': <String>[]};
}

Future<FakeAuth> _pump(WidgetTester tester, Widget page, AuthState state, {Locale locale = const Locale('fr')}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final fake = FakeAuth(state);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => page),
    GoRoute(path: '/welcome', builder: (_, _) => const Text('welcome-route')),
    GoRoute(path: '/login', builder: (_, _) => const Text('login-route')),
    GoRoute(path: '/register', builder: (_, _) => const Text('register-route')),
    GoRoute(path: '/recover', builder: (_, _) => const Text('recover-route')),
    GoRoute(path: '/import-profile', builder: (_, _) => const Text('import-route')),
    GoRoute(path: '/legal', builder: (_, _) => const Text('legal-route')),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [authControllerProvider.overrideWith(() => fake)],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    ),
  ));
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('welcome lists local profiles and opens their sign-in', (tester) async {
    await _pump(tester, const WelcomePage(), const SignedOut([
      LocalProfile(id: 'p1', displayName: 'Awa Ndjock', locale: 'fr'),
    ]));
    expect(find.text('Choisissez votre profil'), findsOneWidget);
    await tester.tap(find.text('Awa Ndjock'));
    await tester.pumpAndSettle();
    expect(find.text('login-route'), findsOneWidget);
  });

  testWidgets('first run invites to create a profile', (tester) async {
    await _pump(tester, const WelcomePage(), const SignedOut([]));
    expect(find.text('Bienvenue'), findsOneWidget);
    expect(find.text('Créer un profil'), findsOneWidget);
  });

  testWidgets('login validates fields then shows localized engine errors', (tester) async {
    final fake = await _pump(tester, const LoginPage(), const SignedOut([]));
    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    expect(find.text('Adresse électronique invalide'), findsOneWidget);
    expect(fake.calls, isEmpty);

    fake.failWith = ApiException(code: 'invalid_credentials', status: 401);
    await tester.enterText(find.byType(TextFormField).at(0), 'awa@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(fake.calls, ['login:awa@example.com']);
    expect(find.text('Adresse ou mot de passe incorrect.'), findsOneWidget);
  });

  testWidgets('locked profile shows the unlock form for that profile', (tester) async {
    final fake = await _pump(
      tester,
      const LoginPage(),
      const LockedOut(
        profileId: 'p1',
        reason: 'inactivity',
        profiles: [LocalProfile(id: 'p1', displayName: 'Awa', locale: 'fr')],
      ),
    );
    expect(find.text('Profil verrouillé'), findsOneWidget);
    expect(find.text("Verrouillé après une période d'inactivité."), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'secret');
    await tester.tap(find.text('Déverrouiller'));
    await tester.pumpAndSettle();
    expect(fake.calls, ['unlock:p1']);
  });

  testWidgets('register requires matching passwords and terms', (tester) async {
    await _pump(tester, const RegisterPage(), const SignedOut([]), locale: const Locale('en'));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Awa');
    await tester.enterText(fields.at(1), 'awa@example.com');
    await tester.enterText(fields.at(2), 'Baobab-Lumiere-Kribi-2026!');
    await tester.enterText(fields.at(3), 'different');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);
    await tester.enterText(fields.at(3), 'Baobab-Lumiere-Kribi-2026!');
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('You must accept the terms of use.'), findsOneWidget);
  });

  testWidgets('recovery phrase is displayed once and must be acknowledged', (tester) async {
    const phrase = 'un deux trois quatre cinq six sept huit neuf dix onze douze';
    await _pump(tester, const RegisterPage(), const SignedIn(
      AppUser(
        id: 'u', email: 'a@b.c', displayName: 'A', accountMode: 'local', locale: 'fr', theme: 'system',
        autoLockMinutes: 15, onboardingCompleted: false,
      ),
      recoveryPhrase: phrase,
    ));
    expect(find.text('Votre phrase de récupération'), findsOneWidget);
    expect(find.textContaining('douze', findRichText: true), findsOneWidget);
    final continueButton = find.widgetWithText(FilledButton, 'Continuer');
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
  });
}
