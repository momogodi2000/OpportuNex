import 'package:dio/dio.dart';

class WorkspacesRepository {
  final Dio _dio;
  WorkspacesRepository(this._dio);

  Future<List<dynamic>> getWorkspaces() async {
    final response = await _dio.get('/api/v1/workspaces');
    return response.data as List<dynamic>;
  }

  Future<void> createWorkspace(String name) async {
    await _dio.post('/api/v1/workspaces', data: {'name': name});
  }
}
