import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opportunex/core/engine/engine_locator.dart';
import 'package:opportunex/core/engine/engine_supervisor.dart';

/// Scriptable stand-in for the engine process.
class FakeProcess implements Process {
  FakeProcess({this.port, int? exitAfterStart}) {
    if (exitAfterStart != null) {
      Timer(const Duration(milliseconds: 20), () => _exit.complete(exitAfterStart));
    }
  }

  final int? port;
  final _out = StreamController<List<int>>();
  final _err = StreamController<List<int>>();
  final _exit = Completer<int>();
  final stdinLines = <String>[];
  late final _stdinCtrl = StreamController<List<int>>()
    ..stream.transform(utf8.decoder).listen((s) {
      stdinLines.add(s.trim());
      if (port != null) _out.add(utf8.encode('PORT:$port\n'));
    });

  late final IOSink _stdin = IOSink(_stdinCtrl.sink);

  @override
  IOSink get stdin => _stdin;

  @override
  Stream<List<int>> get stdout => _out.stream;

  @override
  Stream<List<int>> get stderr => _err.stream;

  @override
  Future<int> get exitCode => _exit.future;

  @override
  int get pid => 4242;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    if (!_exit.isCompleted) _exit.complete(-1);
    return true;
  }
}

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('handshake: token on stdin, PORT on stdout, health with token → ready', () async {
    final c = _container();
    final sup = c.read(engineSupervisorProvider.notifier);
    late FakeProcess proc;
    String? probedToken;
    sup
      ..locate = (() => const EngineCommand('engine', []))
      ..spawn = ((_) async => proc = FakeProcess(port: 5555))
      ..probe = (url, token) async {
        probedToken = token;
        return url == 'http://127.0.0.1:5555/api/v1';
      };
    await sup.start();
    final s = c.read(engineSupervisorProvider);
    expect(s.phase, EngineRunState.ready);
    expect(s.port, 5555);
    expect(proc.stdinLines.single, s.token);
    expect(probedToken, s.token);
    expect(s.token!.length, greaterThanOrEqualTo(32));
  });

  test('engine already running → failure without restart', () async {
    final c = _container();
    final sup = c.read(engineSupervisorProvider.notifier);
    var spawns = 0;
    sup
      ..locate = (() => const EngineCommand('engine', []))
      ..spawn = (_) async {
        spawns++;
        return FakeProcess(exitAfterStart: 3);
      }
      ..probe = ((_, _) async => false);
    unawaited(sup.start());
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final s = c.read(engineSupervisorProvider);
    expect(s.phase, EngineRunState.failed);
    expect(s.failure, EngineFailure.alreadyRunning);
    expect(spawns, 1);
  });

  test('missing engine → notFound diagnostics', () async {
    final c = _container();
    final sup = c.read(engineSupervisorProvider.notifier)..locate = () => throw EngineNotFound(['x']);
    await sup.start();
    expect(c.read(engineSupervisorProvider).failure, EngineFailure.notFound);
  });

  test('tokens are random and url-safe', () {
    final a = EngineSupervisor.newToken();
    final b = EngineSupervisor.newToken();
    expect(a, isNot(b));
    expect(RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(a), isTrue);
  });
}
