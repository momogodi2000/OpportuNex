import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/engine/engine_supervisor.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final EngineData _engineData;

  AuthRepository({
    required Dio dio,
    required FlutterSecureStorage storage,
    required EngineData engineData,
  }) : _dio = dio,
       _storage = storage,
       _engineData = engineData {
    _dio.options.baseUrl = _engineData.engineUrl;
    _dio.options.headers['X-Engine-Token'] = _engineData.sessionToken;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '/api/v1/auth/login',
      data: {'email': email, 'password': password},
    );

    final userId = response.data['user_id'] as String;
    final displayName = response.data['display_name'] as String;

    await _storage.write(key: 'user_id', value: userId);

    return {'user_id': userId, 'display_name': displayName};
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    await _dio.post(
      '/api/v1/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      },
    );
  }

  Future<void> logout() async {
    final userId = await _storage.read(key: 'user_id');
    if (userId != null) {
      await _dio.post(
        '/api/v1/auth/logout',
        options: Options(headers: {'X-User-Id': userId}),
      );
      await _storage.delete(key: 'user_id');
    }
  }

  Future<void> lock() async {
    final userId = await _storage.read(key: 'user_id');
    if (userId != null) {
      await _dio.post(
        '/api/v1/auth/lock',
        options: Options(headers: {'X-User-Id': userId}),
      );
    }
  }

  Future<void> unlock(String password) async {
    final userId = await _storage.read(key: 'user_id');
    if (userId != null) {
      await _dio.post(
        '/api/v1/auth/unlock',
        data: {'password': password},
        options: Options(headers: {'X-User-Id': userId}),
      );
    }
  }

  Future<void> recover(List<String> phrase) async {
    await _dio.post('/api/v1/auth/recover', data: {'phrase': phrase});
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    final userId = await _storage.read(key: 'user_id');
    if (userId != null) {
      await _dio.put(
        '/api/v1/auth/password',
        data: {'old_password': oldPassword, 'new_password': newPassword},
        options: Options(headers: {'X-User-Id': userId}),
      );
    }
  }

  Future<void> deleteAccount() async {
    final userId = await _storage.read(key: 'user_id');
    if (userId != null) {
      await _dio.delete(
        '/api/v1/auth/account',
        options: Options(headers: {'X-User-Id': userId}),
      );
      await _storage.delete(key: 'user_id');
    }
  }

  Future<List<dynamic>> getLocalProfiles() async {
    final response = await _dio.get('/api/v1/auth/local-profiles');
    return response.data['profiles'] as List<dynamic>;
  }
}
