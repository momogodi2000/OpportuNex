import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final engineHttpClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl:
          'http://127.0.0.1:8080', // Replace with dynamic port from supervisor
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Engine-Token': 'REPLACE_WITH_ACTUAL_TOKEN', // Inject from config
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add X-User-Id if authenticated
        // options.headers['X-User-Id'] = userId;

        if (kDebugMode) {
          print('--> ${options.method.toUpperCase()} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('<-- ${response.statusCode} ${response.requestOptions.uri}');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (kDebugMode) {
          print('<-- Error ${e.response?.statusCode} ${e.requestOptions.uri}');
        }

        if (e.response?.statusCode == 401) {
          // Trigger auth state locked
          // ref.read(authProvider.notifier).lockSession();
        }

        // Retry logic for 5xx
        if (e.response != null && e.response!.statusCode! >= 500) {
          // Implement retry logic here
        }

        // RFC 9457 parsing
        if (e.response?.data is Map<String, dynamic>) {
          final data = e.response!.data as Map<String, dynamic>;
          if (data.containsKey('type') && data.containsKey('title')) {
            // It's a problem detail
            e = e.copyWith(message: '${data['title']}: ${data['detail']}');
          }
        }

        return handler.next(e);
      },
    ),
  );

  return dio;
});
