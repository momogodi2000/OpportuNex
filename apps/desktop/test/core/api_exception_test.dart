import 'package:flutter_test/flutter_test.dart';
import 'package:opportunex/core/api/api_exception.dart';

void main() {
  test('parses RFC 9457 problem with extras and field errors', () {
    final e = ApiException.fromProblem(422, {
      'type': 'https://opportunex.app/problems/validation_failed',
      'title': 'Validation failed',
      'status': 422,
      'code': 'validation_failed',
      'errors': [
        {'loc': ['body', 'email'], 'type': 'value_error', 'msg': 'bad'},
      ],
      'retry_after_seconds': 60,
    });
    expect(e.code, 'validation_failed');
    expect(e.fieldErrors.single.field, 'email');
    expect(e.retryAfterSeconds, 60);
    expect(e.isSessionLost, isFalse);
  });

  test('session loss is detected only for 401 session codes', () {
    expect(ApiException.fromProblem(401, {'code': 'session_locked'}).isSessionLost, isTrue);
    expect(ApiException.fromProblem(401, {'code': 'invalid_credentials'}).isSessionLost, isFalse);
    expect(ApiException.fromProblem(500, 'oops').code, 'http_500');
    expect(ApiException.offline().code, 'engine_unreachable');
  });
}
