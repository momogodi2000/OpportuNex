import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/engine_supervisor.dart';

final engineHttpClientProvider = Provider<Dio?>((ref) {
  final engineState = ref.watch(engineSupervisorProvider);

  return engineState.maybeWhen(
    data: (engineData) {
      if (engineData.state != EngineState.healthy) return null;

      final dio = Dio(
        BaseOptions(
          baseUrl: engineData.engineUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-Engine-Token': engineData.sessionToken,
          },
        ),
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.next(options);
          },
          onResponse: (response, handler) {
            return handler.next(response);
          },
          onError: (DioException e, handler) async {
            if (e.response?.data is Map<String, dynamic>) {
              final data = e.response!.data as Map<String, dynamic>;
              if (data.containsKey('title')) {
                e = e.copyWith(
                  message: '${data['title']}: ${data['detail'] ?? ''}',
                );
              }
            }
            return handler.next(e);
          },
        ),
      );

      return dio;
    },
    orElse: () => null,
  );
});
