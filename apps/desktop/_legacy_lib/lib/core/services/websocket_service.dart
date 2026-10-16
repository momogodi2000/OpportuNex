import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  bool _isDisposed = false;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  void connect(int port) {
    if (_isDisposed) return;

    final wsUrl = Uri.parse('ws://127.0.0.1:$port/api/v1/events');
    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen(
      (message) {
        if (kDebugMode) print('WS Message: $message');
        try {
          final data = jsonDecode(message);
          _eventController.add(data);
        } catch (e) {
          if (kDebugMode) print('WS parse error: $e');
        }
      },
      onDone: () {
        _handleDisconnect(port);
      },
      onError: (error) {
        if (kDebugMode) print('WS Error: $error');
        _handleDisconnect(port);
      },
    );

    _reconnectAttempts = 0;
    _startPingTimer();
  }

  void _handleDisconnect(int port) {
    _pingTimer?.cancel();
    if (_isDisposed) return;

    final delay = Duration(seconds: (2 ^ _reconnectAttempts).clamp(1, 60));
    _reconnectAttempts++;

    if (kDebugMode) print('WS Reconnecting in ${delay.inSeconds}s...');

    Future.delayed(delay, () {
      connect(port);
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_channel != null && _channel!.closeCode == null) {
        _channel!.sink.add(jsonEncode({'type': 'ping'}));
      }
    });
  }

  void dispose() {
    _isDisposed = true;
    _pingTimer?.cancel();
    _channel?.sink.close();
    _eventController.close();
  }
}
