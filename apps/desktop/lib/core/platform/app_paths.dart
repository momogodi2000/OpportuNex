import 'dart:io';

import 'package:path/path.dart' as p;

/// Same data folder as the engine (decision D-27).
abstract final class AppPaths {
  static String dataDir() {
    final override = Platform.environment['OPX_DATA_DIR'];
    if (override != null && override.isNotEmpty) return override;
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ??
          p.join(Platform.environment['USERPROFILE'] ?? '.', 'AppData', 'Roaming');
      return p.join(appData, 'PIO');
    }
    final home = Platform.environment['HOME'] ?? '.';
    if (Platform.isMacOS) return p.join(home, 'Library', 'Application Support', 'PIO');
    final xdg = Platform.environment['XDG_DATA_HOME'];
    return xdg != null && xdg.isNotEmpty ? p.join(xdg, 'pio') : p.join(home, '.local', 'share', 'pio');
  }

  static String logsDir() => p.join(dataDir(), 'logs');
}
