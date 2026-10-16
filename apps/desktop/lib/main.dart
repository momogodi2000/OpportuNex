import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/platform/app_paths.dart';
import 'core/platform/autostart.dart';
import 'features/shell/desktop_integration.dart';

Future<void> main(List<String> args) async {
  // Started by the session autostart entry: stay in the tray until the user opens the window.
  final minimized = args.contains(Autostart.flag);
  WidgetsFlutterBinding.ensureInitialized();
  _setupLogging();
  _registerFontLicense();

  final container = ProviderContainer();
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(960, 640),
      center: true,
      title: 'Opportunex',
    ),
    () async {
      await windowManager.setPreventClose(true);
      if (!minimized) {
        await windowManager.show();
        await windowManager.focus();
      }
    },
  );
  final desktop = DesktopIntegration(container);
  await desktop.start();
  // Without a tray icon a hidden window could not be reopened: show it.
  if (minimized && !desktop.trayReady) await windowManager.show();

  runApp(UncontrolledProviderScope(container: container, child: const OpportunexApp()));
}

/// UI log file, open for the whole process lifetime (flushed by the OS on exit).
IOSink? _uiLog;

void _setupLogging() {
  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;
  try {
    final dir = Directory(AppPaths.logsDir())..createSync(recursive: true);
    _uiLog = File(p.join(dir.path, 'ui.log')).openWrite(mode: FileMode.append);
  } on FileSystemException {
    _uiLog = null;
  }
  Logger.root.onRecord.listen((r) {
    final line = '${r.time.toUtc().toIso8601String()} ${r.level.name} ${r.loggerName}: ${r.message}';
    _uiLog?.writeln(line);
    if (kDebugMode) debugPrint(line);
  });
  FlutterError.onError = (details) {
    Logger('Flutter').severe(details.exceptionAsString());
    FlutterError.presentError(details);
  };
}

void _registerFontLicense() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/Inter-OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Inter (font)'], text);
  });
}
