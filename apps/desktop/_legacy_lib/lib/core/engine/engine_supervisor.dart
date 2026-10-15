import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path/path.dart' as p;

enum EngineState { starting, healthy, restarting, failed }

class EngineData {
  final String engineUrl;
  final String sessionToken;
  final Stream<dynamic>? websocketStream;
  final EngineState state;
  final String? diagnosticInfo;

  EngineData({
    required this.engineUrl,
    required this.sessionToken,
    this.websocketStream,
    required this.state,
    this.diagnosticInfo,
  });
}

class EngineSupervisor extends AsyncNotifier<EngineData> {
  Process? _engineProcess;
  WebSocketChannel? _wsChannel;
  int _restartCount = 0;
  static const int _maxRestarts = 3;
  String _sessionToken = '';
  String _engineUrl = '';

  @override
  FutureOr<EngineData> build() async {
    _sessionToken = _generateSessionToken();
    return _startEngine();
  }

  String _generateSessionToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return sha256.convert(values).toString();
  }

  Future<EngineData> _startEngine() async {
    try {
      final String enginePath = _getEnginePath();

      _engineProcess = await Process.start(enginePath, []);

      // Send token via stdin
      _engineProcess!.stdin.writeln(_sessionToken);
      await _engineProcess!.stdin.flush();

      // Read PORT from stdout
      final completer = Completer<int>();
      _engineProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            if (line.startsWith('PORT:') && !completer.isCompleted) {
              final port = int.tryParse(line.substring(5));
              if (port != null) {
                completer.complete(port);
              }
            }
          });

      final port = await completer.future.timeout(const Duration(seconds: 5));
      _engineUrl = 'http://localhost:$port';

      // Health check poll
      await _waitForHealth();

      // Open WebSocket
      _wsChannel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:$port/api/v1/events'),
      );

      _engineProcess!.exitCode.then((code) {
        if (code != 0 && _restartCount < _maxRestarts) {
          _restartCount++;
          state = const AsyncLoading();
          _startEngine().then((data) => state = AsyncData(data));
        } else if (code != 0) {
          state = AsyncData(
            EngineData(
              engineUrl: _engineUrl,
              sessionToken: _sessionToken,
              state: EngineState.failed,
              diagnosticInfo:
                  'Engine exited with code $code after $_maxRestarts restarts',
            ),
          );
        }
      });

      return EngineData(
        engineUrl: _engineUrl,
        sessionToken: _sessionToken,
        websocketStream: _wsChannel?.stream,
        state: EngineState.healthy,
      );
    } catch (e) {
      if (_restartCount < _maxRestarts) {
        _restartCount++;
        await Future.delayed(Duration(seconds: pow(2, _restartCount).toInt()));
        return _startEngine();
      }
      return EngineData(
        engineUrl: '',
        sessionToken: _sessionToken,
        state: EngineState.failed,
        diagnosticInfo: e.toString(),
      );
    }
  }

  Future<void> _waitForHealth() async {
    int attempts = 0;
    while (attempts < 5) {
      try {
        final response = await http.get(Uri.parse('$_engineUrl/api/v1/health'));
        if (response.statusCode == 200) {
          return;
        }
      } catch (_) {}
      attempts++;
      await Future.delayed(Duration(seconds: pow(2, attempts).toInt()));
    }
    throw Exception('Engine health check failed after max attempts');
  }

  String _getEnginePath() {
    final executable = Platform.resolvedExecutable;
    final dir = p.dirname(executable);
    if (Platform.isWindows) {
      return p.join(dir, 'engine.exe');
    } else {
      return p.join(dir, 'engine');
    }
  }

  Future<void> shutdown() async {
    if (_engineUrl.isNotEmpty) {
      try {
        await http.post(Uri.parse('$_engineUrl/api/v1/shutdown'));
      } catch (_) {}
    }
    _wsChannel?.sink.close();
    _engineProcess?.kill();
  }
}

final engineSupervisorProvider =
    AsyncNotifierProvider<EngineSupervisor, EngineData>(() {
      return EngineSupervisor();
    });
