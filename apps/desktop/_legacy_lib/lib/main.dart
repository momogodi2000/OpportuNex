import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tray_manager/tray_manager.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    // Setup window_manager
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1024, 720),
      minimumSize: Size(1024, 720),
      center: true,
      title: 'OpportuNex',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // Setup tray_manager
    try {
      await trayManager.setIcon(
        'assets/images/icon.png', 
      );
    } catch (e) {
      // ignore
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}
