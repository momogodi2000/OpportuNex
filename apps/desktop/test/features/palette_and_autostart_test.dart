import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opportunex/core/platform/autostart.dart';
import 'package:opportunex/features/shell/command_palette.dart';
import 'package:opportunex/l10n/app_localizations.dart';

Widget _app(Widget Function(BuildContext) body) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(builder: (context) => Scaffold(body: body(context))),
    );

void main() {
  testWidgets('palette filters accent-insensitively and runs the highlighted command with the keyboard', (tester) async {
    final ran = <String>[];
    await tester.pumpWidget(_app((context) => TextButton(
          onPressed: () => showCommandPalette(context, [
            PaletteCommand('Aller à : Tableau de bord', Icons.dashboard, () => ran.add('dashboard')),
            PaletteCommand('Aller à : Sauvegardées', Icons.bookmarks, () => ran.add('saved')),
            PaletteCommand('Aller à : Paramètres', Icons.settings, () => ran.add('settings'), keywords: 'settings'),
          ]),
          child: const Text('open'),
        )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'parametres');
    await tester.pump();
    expect(find.text('Aller à : Paramètres'), findsOneWidget);
    expect(find.text('Aller à : Sauvegardées'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(ran, ['settings']);

    // Arrow keys move the selection; Enter runs it.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(ran, ['settings', 'saved']);
  });

  testWidgets('shortcut help lists the palette and lock shortcuts', (tester) async {
    await tester.pumpWidget(_app((context) => TextButton(onPressed: () => showShortcutsHelp(context), child: const Text('help'))));
    await tester.tap(find.text('help'));
    await tester.pumpAndSettle();
    expect(find.text('Raccourcis clavier'), findsOneWidget);
    expect(find.text('Ctrl+K'), findsOneWidget);
    expect(find.text('Ctrl+L'), findsOneWidget);
  });

  test('autostart entries quote the executable path and start minimised', () {
    final a = Autostart(executable: r'C:\Program Files\Opportunex\opportunex.exe', environment: {'HOME': '/home/awa'});
    expect(a.windowsCommand, r'"C:\Program Files\Opportunex\opportunex.exe" --minimized');
    expect(a.windowsEnableArgs(), [
      'add', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run', '/v', 'Opportunex', '/t', 'REG_SZ',
      '/d', r'"C:\Program Files\Opportunex\opportunex.exe" --minimized', '/f',
    ]);
    expect(a.windowsDisableArgs().first, 'delete');
    expect(a.linuxEntry.path.replaceAll(r'\', '/'), '/home/awa/.config/autostart/opportunex.desktop');
    expect(a.linuxDesktopEntry(), contains('Exec="C:\\Program Files\\Opportunex\\opportunex.exe" --minimized'));
  });

  test('autostart reads the registry without changing it', () async {
    final calls = <List<String>>[];
    final a = Autostart(
      executable: 'x.exe',
      run: (exe, args) async {
        calls.add([exe, ...args]);
        return ProcessResult(0, 0, '    Opportunex    REG_SZ    "x.exe" --minimized', '');
      },
    );
    if (Platform.isWindows) {
      expect(await a.isEnabled(), isTrue);
      expect(calls.single.sublist(0, 2), ['reg', 'query']);
    }
  });
}
