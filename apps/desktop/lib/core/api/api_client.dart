import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/engine_supervisor.dart';
import 'api_exception.dart';

typedef Json = Map<String, dynamic>;

/// The single HTTP client to the local engine. Adds the per-launch engine token and the
/// session bearer, and turns every failure into an [ApiException].
class ApiClient {
  ApiClient({required String baseUrl, required String engineToken, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 3),
              receiveTimeout: const Duration(minutes: 2),
              sendTimeout: const Duration(minutes: 2),
              headers: {'X-Engine-Token': engineToken},
            ));

  final Dio _dio;

  /// Bearer token of the signed-in profile; null when signed out or locked.
  String? sessionToken;
  void Function(ApiException)? onSessionLost;

  Options _opts([Options? o]) {
    final headers = <String, Object?>{...?o?.headers};
    if (sessionToken != null) headers['Authorization'] = 'Bearer $sessionToken';
    return (o ?? Options()).copyWith(headers: headers);
  }

  Future<T> _call<T>(Future<Response<dynamic>> Function() send, T Function(dynamic data) map) async {
    try {
      final r = await send();
      return map(r.data);
    } on DioException catch (e) {
      final ex = _toApi(e);
      if (ex.isSessionLost) onSessionLost?.call(ex);
      throw ex;
    }
  }

  ApiException _toApi(DioException e) {
    final res = e.response;
    if (res == null) return ApiException.offline(e.message);
    return ApiException.fromProblem(res.statusCode, res.data);
  }

  Future<Json> getJson(String path, {Map<String, Object?>? query}) =>
      _call(() => _dio.get<dynamic>(path, queryParameters: _clean(query), options: _opts()), _asJson);

  Future<Json> postJson(String path, {Object? body, Map<String, Object?>? query}) => _call(
      () => _dio.post<dynamic>(path, data: body, queryParameters: _clean(query), options: _opts()), _asJson);

  Future<Json> putJson(String path, {Object? body}) =>
      _call(() => _dio.put<dynamic>(path, data: body, options: _opts()), _asJson);

  Future<Json> patchJson(String path, {Object? body}) =>
      _call(() => _dio.patch<dynamic>(path, data: body, options: _opts()), _asJson);

  Future<void> delete(String path, {Object? body}) =>
      _call(() => _dio.delete<dynamic>(path, data: body, options: _opts()), (_) {});

  Future<Uint8List> getBytes(String path, {Map<String, Object?>? query}) => _call(
        () => _dio.get<List<int>>(path,
            queryParameters: _clean(query), options: _opts(Options(responseType: ResponseType.bytes))),
        (d) => Uint8List.fromList(d as List<int>),
      );

  /// POST returning a file (exports, archives).
  Future<Uint8List> postBytes(String path, {Object? body}) => _call(
        () => _dio.post<List<int>>(path, data: body, options: _opts(Options(responseType: ResponseType.bytes))),
        (d) => Uint8List.fromList(d as List<int>),
      );

  Future<Json> upload(String path, {required String fileName, required List<int> bytes, Map<String, String>? fields}) =>
      _call(
        () => _dio.post<dynamic>(path,
            data: FormData.fromMap({
              ...?fields,
              'file': MultipartFile.fromBytes(bytes, filename: fileName),
            }),
            options: _opts()),
        _asJson,
      );

  static Json _asJson(dynamic d) => d is Map<String, dynamic> ? d : <String, dynamic>{};

  static Map<String, Object?>? _clean(Map<String, Object?>? q) {
    if (q == null) return null;
    return Map.of(q)..removeWhere((_, v) => v == null || (v is String && v.isEmpty));
  }

  void close() => _dio.close(force: true);
}

/// Available once the supervisor reports the engine ready; rebuilt after each restart.
final apiClientProvider = Provider<ApiClient?>((ref) {
  final status = ref.watch(engineSupervisorProvider);
  if (!status.isReady) return null;
  final client = ApiClient(baseUrl: status.baseUrl, engineToken: status.token!);
  ref.onDispose(client.close);
  return client;
});

/// Convenience for feature repositories: throws when the engine is not available.
/// Widget-side counterpart of [requireApi] for event handlers: reads (never watches) the client.
ApiClient readApi(WidgetRef ref) {
  final api = ref.read(apiClientProvider);
  if (api == null) throw ApiException.offline('engine not ready');
  return api;
}

ApiClient requireApi(Ref ref) {
  final api = ref.watch(apiClientProvider);
  if (api == null) throw ApiException.offline('engine not ready');
  return api;
}
