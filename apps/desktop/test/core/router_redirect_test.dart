import 'package:flutter_test/flutter_test.dart';
import 'package:opportunex/core/engine/engine_supervisor.dart';
import 'package:opportunex/core/router/app_router.dart';
import 'package:opportunex/features/auth/auth_models.dart';
import 'package:opportunex/features/shell/desktop_integration.dart';
import 'package:opportunex/features/shell/nav_items.dart';

const _ready = EngineStatus(phase: EngineRunState.ready, port: 1234, token: 't');
const _starting = EngineStatus(phase: EngineRunState.starting);
const _user = AppUser(
  id: 'u',
  email: 'a@b.c',
  displayName: 'A',
  accountMode: 'local',
  locale: 'fr',
  theme: 'system',
  autoLockMinutes: 15,
  onboardingCompleted: true,
);

void main() {
  test('engine not ready keeps everyone on the startup screen', () {
    expect(redirectFor(engine: _starting, auth: const AuthUnknown(), location: '/settings'), '/startup');
    expect(redirectFor(engine: _starting, auth: const AuthUnknown(), location: '/startup'), isNull);
    expect(redirectFor(engine: _ready, auth: const AuthUnknown(), location: '/welcome'), '/startup');
  });

  test('signed-out users only reach sign-in screens and legal texts', () {
    const auth = SignedOut([]);
    expect(redirectFor(engine: _ready, auth: auth, location: '/startup'), '/welcome');
    expect(redirectFor(engine: _ready, auth: auth, location: '/settings'), '/welcome');
    for (final ok in ['/welcome', '/login', '/register', '/recover', '/import-profile', '/legal']) {
      expect(redirectFor(engine: _ready, auth: auth, location: ok), isNull, reason: ok);
    }
  });

  test('locked profile is sent to the unlock screen', () {
    const auth = LockedOut(profileId: 'u', reason: 'inactivity', profiles: []);
    expect(redirectFor(engine: _ready, auth: auth, location: '/settings'), '/login');
    expect(redirectFor(engine: _ready, auth: auth, location: '/login'), isNull);
    expect(redirectFor(engine: _ready, auth: auth, location: '/register'), '/login');
  });

  test('signed-in users skip auth screens; recovery phrase is shown first', () {
    expect(redirectFor(engine: _ready, auth: const SignedIn(_user), location: '/login'), homePath);
    expect(redirectFor(engine: _ready, auth: const SignedIn(_user), location: '/startup'), homePath);
    expect(redirectFor(engine: _ready, auth: const SignedIn(_user), location: '/settings'), isNull);
    expect(redirectFor(engine: _ready, auth: const SignedIn(_user), location: '/legal'), isNull);
    const withPhrase = SignedIn(_user, recoveryPhrase: 'a b c');
    expect(redirectFor(engine: _ready, auth: withPhrase, location: '/settings'), '/register');
    expect(redirectFor(engine: _ready, auth: withPhrase, location: '/register'), isNull);
  });

  test('onboarding opens right after registration and may be left', () {
    final fresh = SignedIn(_user.copyWith(onboardingCompleted: false));
    expect(redirectFor(engine: _ready, auth: fresh, location: '/register'), '/onboarding');
    expect(redirectFor(engine: _ready, auth: const SignedIn(_user), location: '/register'), homePath);
    // Later sign-ins are not forced back into the wizard (resumable from the profile page).
    expect(redirectFor(engine: _ready, auth: fresh, location: '/login'), homePath);
    expect(redirectFor(engine: _ready, auth: fresh, location: '/onboarding'), isNull);
    // "Later" leads to the dashboard and the CV import stays reachable from the wizard.
    expect(redirectFor(engine: _ready, auth: fresh, location: '/dashboard'), isNull);
    expect(redirectFor(engine: _ready, auth: fresh, location: '/profile/cv'), isNull);
    expect(homePath, '/dashboard');
  });

  test('deep links from notifications target the most specific page', () {
    expect(deepLinkFor({'saved_id': 's', 'opportunity_id': 'o'}), '/saved/s');
    expect(deepLinkFor({'run_id': 'r'}), '/search?run=r');
    expect(deepLinkFor({'opportunity_id': 'o'}), '/opportunities/o');
    expect(deepLinkFor({'source_id': 'x'}), '/sources');
    expect(deepLinkFor(null), isNull);
  });
}
