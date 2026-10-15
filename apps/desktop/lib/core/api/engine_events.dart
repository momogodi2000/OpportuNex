import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/engine_supervisor.dart';

class EngineEvent {
  const EngineEvent(this.type, this.data, this.at);

  factory EngineEvent.parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return EngineEvent(
      json['type'] as String? ?? 'unknown',
      (json['data'] as Map<String, dynamic>?) ?? const {},
      json['at'] as String?,
    );
  }

  final String type;
  final Map<String, dynamic> data;
  final String? at;
}

/// Stream of engine events (`/api/v1/events`), reconnecting while the engine is ready.
final engineEventsProvider = StreamProvider<EngineEvent>((ref) {
  final status = ref.watch(engineSupervisorProvider);
  final controller = StreamController<EngineEvent>();
  if (!status.isReady) {
    unawaited(controller.close());
    return controller.stream;
  }
  WebSocket? socket;
  var disposed = false;

  Future<void> connect() async {
    var backoff = 1;
    while (!disposed) {
      try {
        socket = await WebSocket.connect(
          'ws://127.0.0.1:${status.port}/api/v1/events',
          headers: {'X-Engine-Token': status.token!},
        );
        backoff = 1;
        await for (final msg in socket!) {
          if (msg is String) {
            final event = EngineEvent.parse(msg);
            if (event.type != 'ping') controller.add(event);
          }
        }
      } on Object {
        // engine restarting or socket dropped: retry below
      }
      if (disposed) break;
      await Future<void>.delayed(Duration(seconds: backoff));
      backoff = backoff >= 8 ? 8 : backoff * 2;
    }
  }

  unawaited(connect());
  ref.onDispose(() {
    disposed = true;
    unawaited(socket?.close());
    unawaited(controller.close());
  });
  return controller.stream;
});
