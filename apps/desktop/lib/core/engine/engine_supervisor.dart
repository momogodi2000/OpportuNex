import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../platform/app_paths.dart';
import 'engine_locator.dart';

final _log = Logger('EngineSupervisor');

enum EngineRunState { starting, ready, restarting, failed, stopped }

enum EngineFailure { notFound, alreadyRunning, handshakeTimeout, crashed, healthTimeout }

@immutable
class EngineStatus {
  const EngineStatus({
    required this.phase,
    this.port,
    this.token,
    this.failure,
    this.attempt = 0,
    this.detail,
    this.logTail = const [],
  });

  final EngineRunState phase;
  final int? port;
  final String? token;
  final EngineFailure? failure;
  final int attempt;
  final String? detail;
  final List<String> logTail;

  bool get isReady => phase == EngineRunState.ready && port != null && token != null;
  String get baseUrl => 'http://127.0.0.1:$port/api/v1';

  EngineStatus copyWith({
    EngineRunState? phase,
    int? port,
    String? token,
    EngineFailure? failure,
    int? attempt,
    String? detail,
    List<String>? logTail,
  }) =>
      EngineStatus(
        phase: phase ?? this.phase,
        port: port ?? this.port,
        token: token ?? this.token,
        failure: failure ?? this.failure,
        attempt: attempt ?? this.attempt,
        detail: detail ?? this.detail,
        logTail: logTail ?? this.logTail,
      );
}

/// Starts and watches the local engine (arch §3.4, ADR-002):
/// random token on stdin → `PORT:<n>` on stdout → `/health` polled ≤ 10 s → ready.
/// Unexpected exits are retried 3 times with exponential back-off, then the UI shows a
/// diagnostics screen.
class EngineSupervisor extends Notifier<EngineStatus> {
  static const maxRestarts = 3;
  static const handshakeTimeout = Duration(seconds: 20);
  static const healthTimeout = Duration(seconds: 10);
  static const _tailLines = 80;

  Process? _process;
  final _tail = <String>[];
  IOSink? _logSink;
  bool _stopping = false;
  int _restarts = 0;

  /// Injected in tests.
  EngineCommand Function() locate = EngineLocator.resolve;
  Future<Process> Function(EngineCommand) spawn = _defaultSpawn;
  Future<bool> Function(String baseUrl, String token) probe = _defaultProbe;

  @override
  EngineStatus build() {
    ref.onDispose(() => unawaited(stop()));
    return const EngineStatus(phase: EngineRunState.stopped);
  }

  // `--parent-pid`: the engine exits by itself if this app crashes or is killed.
  static Future<Process> _defaultSpawn(EngineCommand c) => Process.start(
        c.executable,
        [...c.arguments, '--parent-pid', '$pid'],
        workingDirectory: c.workingDirectory,
        environment: const {'PYTHONUNBUFFERED': '1', 'PYTHONIOENCODING': 'utf-8'},
      );

  static Future<bool> _defaultProbe(String baseUrl, String token) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 1),
      receiveTimeout: const Duration(seconds: 2),
      headers: {'X-Engine-Token': token},
    ));
    try {
      final r = await dio.get<Map<String, dynamic>>('$baseUrl/health');
      return r.statusCode == 200 && r.data?['status'] == 'ok';
    } on DioException {
      return false;
    } finally {
      dio.close(force: true);
    }
  }

  static String newToken() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  void _remember(String line) {
    _tail.add(line);
    if (_tail.length > _tailLines) _tail.removeAt(0);
    _logSink?.writeln(line);
  }

  Future<void> start() async {
    if (state.phase == EngineRunState.starting || state.isReady) return;
    _stopping = false;
    _restarts = 0;
    await _launch(EngineRunState.starting);
  }

  Future<void> retry() async {
    await _kill();
    _restarts = 0;
    await _launch(EngineRunState.starting);
  }

  Future<void> _openLog() async {
    if (_logSink != null) return;
    try {
      final dir = Directory(AppPaths.logsDir());
      await dir.create(recursive: true);
      _logSink = File(p.join(dir.path, 'engine-process.log')).openWrite(mode: FileMode.append);
    } on FileSystemException catch (e) {
      _log.warning('cannot open engine log: $e');
    }
  }

  Future<void> _launch(EngineRunState phase) async {
    await _kill();
    final token = newToken();
    state = EngineStatus(phase: phase, attempt: _restarts, logTail: List.of(_tail));
    await _openLog();

    final EngineCommand command;
    try {
      command = locate();
    } on EngineNotFound catch (e) {
      _fail(EngineFailure.notFound, e.toString());
      return;
    }
    _remember('[ui] starting engine: $command');

    final Process process;
    try {
      process = await spawn(command);
    } on ProcessException catch (e) {
      _fail(EngineFailure.notFound, e.message);
      return;
    }
    _process = process;
    final portCompleter = Completer<int>();

    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      _remember('[out] $line');
      if (line.startsWith('PORT:') && !portCompleter.isCompleted) {
        final port = int.tryParse(line.substring(5).trim());
        if (port != null) portCompleter.complete(port);
      }
    });
    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(_remember);

    var exitCodeSeen = false;
    unawaited(process.exitCode.then((code) {
      exitCodeSeen = true;
      _remember('[ui] engine exited with code $code');
      if (identical(_process, process)) _onExit(code);
    }));

    process.stdin.writeln(token);
    await process.stdin.flush();
    unawaited(process.stdin.close());

    final int port;
    try {
      port = await portCompleter.future.timeout(handshakeTimeout);
    } on TimeoutException {
      if (!exitCodeSeen) _fail(EngineFailure.handshakeTimeout, 'no PORT line within ${handshakeTimeout.inSeconds}s');
      return;
    }

    final base = 'http://127.0.0.1:$port/api/v1';
    final deadline = DateTime.now().add(healthTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (!identical(_process, process)) return;
      if (await probe(base, token)) {
        state = EngineStatus(phase: EngineRunState.ready, port: port, token: token, attempt: _restarts);
        _remember('[ui] engine ready on port $port');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    _fail(EngineFailure.healthTimeout, 'health check did not succeed within ${healthTimeout.inSeconds}s');
  }

  void _onExit(int code) {
    _process = null;
    if (_stopping) {
      state = const EngineStatus(phase: EngineRunState.stopped);
      return;
    }
    if (code == 3) {
      _fail(EngineFailure.alreadyRunning, 'another Opportunex engine is already running');
      return;
    }
    if (_restarts >= maxRestarts) {
      _fail(EngineFailure.crashed, 'engine exited with code $code after $_restarts restarts');
      return;
    }
    _restarts++;
    final delay = Duration(seconds: 1 << (_restarts - 1));
    state = state.copyWith(phase: EngineRunState.restarting, attempt: _restarts, logTail: List.of(_tail));
    unawaited(Future<void>.delayed(delay, () {
      if (!_stopping) unawaited(_launch(EngineRunState.restarting));
    }));
  }

  void _fail(EngineFailure failure, String detail) {
    _log.severe('engine failure: $failure $detail');
    _remember('[ui] failure: $failure — $detail');
    state = EngineStatus(
      phase: EngineRunState.failed,
      failure: failure,
      detail: detail,
      attempt: _restarts,
      logTail: List.of(_tail),
    );
    unawaited(_kill());
  }

  Future<void> _kill() async {
    final proc = _process;
    _process = null;
    if (proc == null) return;
    proc.kill();
    try {
      await proc.exitCode.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      proc.kill(ProcessSignal.sigkill);
    }
  }

  /// Graceful stop: ask the engine to close the profile (WAL checkpoint), then kill.
  Future<void> stop() async {
    _stopping = true;
    final s = state;
    final proc = _process;
    if (s.isReady && proc != null) {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 1),
        receiveTimeout: const Duration(seconds: 2),
        headers: {'X-Engine-Token': s.token},
      ));
      try {
        await dio.post<void>('${s.baseUrl}/system/shutdown');
        await proc.exitCode.timeout(const Duration(seconds: 4));
      } on Object {
        // fall through to kill
      } finally {
        dio.close(force: true);
      }
    }
    await _kill();
    await _logSink?.flush();
    await _logSink?.close();
    _logSink = null;
    state = const EngineStatus(phase: EngineRunState.stopped);
  }

  List<String> get logTail => List.unmodifiable(_tail);
}

final engineSupervisorProvider =
    NotifierProvider<EngineSupervisor, EngineStatus>(EngineSupervisor.new);
