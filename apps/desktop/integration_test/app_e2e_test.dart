import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:opportunex/app.dart';
import 'package:opportunex/core/engine/engine_supervisor.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end: real desktop UI + real Python engine (spawned through the supervisor, as
/// in production), isolated in a temporary data directory.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dataDir;
  late ProviderContainer container;

  setUp(() {
    dataDir = Directory.systemTemp.createTempSync('opx-e2e-');
    SharedPreferences.setMockInitialValues({'locale': 'fr', 'theme': 'light'});
    container = ProviderContainer();
    container.read(engineSupervisorProvider.notifier).spawn = (c) => Process.start(
          c.executable,
          c.arguments,
          workingDirectory: c.workingDirectory,
          environment: {
            'OPX_DATA_DIR': dataDir.path,
            'OPX_KDF_MEMORY_KIB': '8192',
            'OPX_KDF_ITERATIONS': '1',
            'PYTHONUNBUFFERED': '1',
            'PYTHONIOENCODING': 'utf-8',
          },
        );
  });

  tearDown(() async {
    await container.read(engineSupervisorProvider.notifier).stop();
    container.dispose();
    try {
      dataDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows may hold the log file briefly; the OS cleans temp later.
    }
  });

  Future<void> waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 60)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('timed out waiting for $finder');
  }

  testWidgets('register, recovery phrase, settings, lock/unlock, backup', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const OpportunexApp()));

    // Engine starts and the first-run screen appears.
    await waitFor(tester, find.text('Créer un profil'));
    await tester.tap(find.text('Créer un profil'));
    await tester.pumpAndSettle();

    const password = 'Baobab-Lumiere-Kribi-2026!';
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Awa Ndjock');
    await tester.enterText(fields.at(1), 'awa@example.com');
    await tester.enterText(fields.at(2), password);
    await tester.enterText(fields.at(3), password);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Créer un compte'));

    // Recovery phrase shown once, must be acknowledged.
    await waitFor(tester, find.text('Votre phrase de récupération'));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continuer'));
    await waitFor(tester, find.text('Compte et sécurité'));
    expect(find.text('awa@example.com'), findsOneWidget);

    // Lock with Ctrl+L, then unlock with the password.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await waitFor(tester, find.text('Profil verrouillé'));
    await tester.enterText(find.byType(TextFormField).first, password);
    await tester.tap(find.text('Déverrouiller'));
    await waitFor(tester, find.text('Compte et sécurité'));

    // Create a real encrypted backup from the Backups tab.
    await tester.tap(find.widgetWithText(Tab, 'Sauvegardes'));
    await waitFor(tester, find.text('Sauvegarder maintenant'));
    await tester.pumpAndSettle();
    final backupButton = find.text('Sauvegarder maintenant');
    await tester.ensureVisible(backupButton);
    await tester.tap(backupButton);
    await waitFor(tester, find.text('Sauvegarde créée'));
    await waitFor(tester, find.textContaining('manuelle'));
    final backups = Directory('${dataDir.path}${Platform.pathSeparator}backups').listSync(recursive: true);
    expect(backups.whereType<File>().where((f) => f.path.endsWith('.opxbak')), hasLength(1));
  });
}
