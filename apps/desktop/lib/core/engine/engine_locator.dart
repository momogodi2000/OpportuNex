import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// How to start the engine process.
class EngineCommand {
  const EngineCommand(this.executable, this.arguments, {this.workingDirectory});

  final String executable;
  final List<String> arguments;
  final String? workingDirectory;

  @override
  String toString() => [executable, ...arguments].join(' ');
}

class EngineNotFound implements Exception {
  EngineNotFound(this.searched);
  final List<String> searched;

  @override
  String toString() => 'Engine not found. Searched: ${searched.join(', ')}';
}

/// Resolves the engine, in order:
/// 1. `OPX_ENGINE_CMD` — JSON array, e.g. `["C:/py/python.exe","D:/repo/engine/main.py"]`;
/// 2. packaged build — `<app dir>/engine/opportunex-engine(.exe)` (PyInstaller --onedir);
/// 3. development checkout — `engine/.venv` interpreter + `engine/main.py` found by walking up
///    from the executable and the working directory.
abstract final class EngineLocator {
  static String get _exeSuffix => Platform.isWindows ? '.exe' : '';

  static EngineCommand resolve({
    Map<String, String>? environment,
    String? resolvedExecutable,
    String? currentDirectory,
  }) {
    final env = environment ?? Platform.environment;
    final exe = resolvedExecutable ?? Platform.resolvedExecutable;
    final cwd = currentDirectory ?? Directory.current.path;
    final searched = <String>[];

    final override = env['OPX_ENGINE_CMD'];
    if (override != null && override.trim().isNotEmpty) {
      final parts = (jsonDecode(override) as List<dynamic>).cast<String>();
      return EngineCommand(parts.first, parts.sublist(1));
    }

    final appDir = p.dirname(exe);
    final packaged = p.join(appDir, 'engine', 'opportunex-engine$_exeSuffix');
    searched.add(packaged);
    if (File(packaged).existsSync()) {
      return EngineCommand(packaged, const [], workingDirectory: p.dirname(packaged));
    }

    for (final start in {appDir, cwd}) {
      var dir = Directory(start);
      for (var i = 0; i < 10; i++) {
        final engineDir = p.join(dir.path, 'engine');
        final mainPy = p.join(engineDir, 'main.py');
        final python = Platform.isWindows
            ? p.join(engineDir, '.venv', 'Scripts', 'python.exe')
            : p.join(engineDir, '.venv', 'bin', 'python');
        if (File(mainPy).existsSync() && File(python).existsSync()) {
          return EngineCommand(python, [mainPy], workingDirectory: engineDir);
        }
        searched.add(mainPy);
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    }
    throw EngineNotFound(searched);
  }
}
