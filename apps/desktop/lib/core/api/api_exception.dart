/// RFC 9457 problem returned by the engine, or a transport failure.
///
/// `code` is stable and is what the UI localises; `detail` is a developer hint.
class ApiException implements Exception {
  ApiException({
    required this.code,
    this.status,
    this.detail,
    this.extra = const {},
    this.fieldErrors = const [],
  });

  factory ApiException.fromProblem(int? status, Object? body) {
    if (body is Map<String, dynamic>) {
      final extra = Map<String, dynamic>.of(body)
        ..removeWhere((k, _) => const {'type', 'title', 'status', 'code', 'detail', 'instance', 'errors'}.contains(k));
      final errors = (body['errors'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FieldError.fromJson)
          .toList();
      return ApiException(
        code: body['code'] as String? ?? 'http_$status',
        status: status,
        detail: body['detail'] as String?,
        extra: extra,
        fieldErrors: errors,
      );
    }
    return ApiException(code: 'http_${status ?? 0}', status: status);
  }

  /// Engine unreachable (stopped, restarting, network stack error).
  factory ApiException.offline([String? detail]) =>
      ApiException(code: 'engine_unreachable', detail: detail);

  final String code;
  final int? status;
  final String? detail;
  final Map<String, dynamic> extra;
  final List<FieldError> fieldErrors;

  bool get isSessionLost =>
      status == 401 && const {'session_locked', 'invalid_session', 'not_authenticated'}.contains(code);

  int? get retryAfterSeconds => (extra['retry_after_seconds'] as num?)?.toInt();

  @override
  String toString() => 'ApiException($code, $status${detail == null ? '' : ', $detail'})';
}

class FieldError {
  const FieldError({required this.field, required this.type, this.message});

  factory FieldError.fromJson(Map<String, dynamic> json) {
    final loc = (json['loc'] as List<dynamic>? ?? const []).map((e) => '$e').toList();
    return FieldError(
      field: loc.isEmpty ? '' : loc.last,
      type: json['type'] as String? ?? 'invalid',
      message: json['msg'] as String?,
    );
  }

  final String field;
  final String type;
  final String? message;
}
