import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  await trayManager.setIcon(
    'assets/images/tray_icon.png', // Ensure this exists or catch error
  );

  // Custom structlog-style logging could be initialized here

  runApp(const ProviderScope(child: MyApp()));
}
