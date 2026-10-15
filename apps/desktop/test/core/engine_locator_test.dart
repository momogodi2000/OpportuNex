import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opportunex/core/engine/engine_locator.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('opx-locator-'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('OPX_ENGINE_CMD overrides everything', () {
    final c = EngineLocator.resolve(
      environment: {'OPX_ENGINE_CMD': '["py","main.py","--x"]'},
      resolvedExecutable: p.join(tmp.path, 'app.exe'),
      currentDirectory: tmp.path,
    );
    expect(c.executable, 'py');
    expect(c.arguments, ['main.py', '--x']);
  });

  test('packaged engine next to the executable wins over a checkout', () {
    final suffix = Platform.isWindows ? '.exe' : '';
    final engine = File(p.join(tmp.path, 'engine', 'opportunex-engine$suffix'))..createSync(recursive: true);
    final c = EngineLocator.resolve(
      environment: const {},
      resolvedExecutable: p.join(tmp.path, 'opportunex.exe'),
      currentDirectory: tmp.path,
    );
    expect(c.executable, engine.path);
    expect(c.arguments, isEmpty);
  });

  test('development checkout is found by walking up from the build folder', () {
    final engineDir = Directory(p.join(tmp.path, 'repo', 'engine'))..createSync(recursive: true);
    File(p.join(engineDir.path, 'main.py')).createSync();
    final python = Platform.isWindows
        ? File(p.join(engineDir.path, '.venv', 'Scripts', 'python.exe'))
        : File(p.join(engineDir.path, '.venv', 'bin', 'python'));
    python.createSync(recursive: true);
    final exe = p.join(tmp.path, 'repo', 'apps', 'desktop', 'build', 'windows', 'x64', 'runner', 'Debug', 'opportunex.exe');
    final c = EngineLocator.resolve(environment: const {}, resolvedExecutable: exe, currentDirectory: tmp.path);
    expect(c.executable, python.path);
    expect(c.arguments.single, p.join(engineDir.path, 'main.py'));
    expect(c.workingDirectory, engineDir.path);
  });

  test('missing engine reports where it looked', () {
    expect(
      () => EngineLocator.resolve(
        environment: const {},
        resolvedExecutable: p.join(tmp.path, 'x', 'app.exe'),
        currentDirectory: tmp.path,
      ),
      throwsA(isA<EngineNotFound>().having((e) => e.searched, 'searched', isNotEmpty)),
    );
  });
}
