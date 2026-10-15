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
import 'core/engine/engine_supervisor.dart';
import 'core/platform/app_paths.dart';

Future<void> main() async {
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
      await windowManager.show();
      await windowManager.focus();
    },
  );
  windowManager.addListener(_CloseHandler(container));

  runApp(UncontrolledProviderScope(container: container, child: const OpportunexApp()));
}

/// Stop the engine cleanly (WAL checkpoint, job state persisted) before the window closes.
class _CloseHandler extends WindowListener {
  _CloseHandler(this.container);
  final ProviderContainer container;
  bool _closing = false;

  @override
  Future<void> onWindowClose() async {
    if (_closing) return;
    _closing = true;
    try {
      await container.read(engineSupervisorProvider.notifier).stop().timeout(const Duration(seconds: 6));
    } on Object {
      // Closing must never hang.
    }
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }
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
