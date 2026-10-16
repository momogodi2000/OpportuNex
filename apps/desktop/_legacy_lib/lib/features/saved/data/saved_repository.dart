import 'package:dio/dio.dart';

class SavedRepository {
  final Dio _dio;
  SavedRepository(this._dio);

  Future<List<dynamic>> getSavedOpportunities() async {
    final response = await _dio.get('/api/v1/saved');
    return response.data['items'] as List<dynamic>;
  }

  Future<void> saveOpportunity(String opportunityId) async {
    await _dio.post('/api/v1/saved', data: {'opportunity_id': opportunityId});
  }

  Future<void> unsaveOpportunity(String savedId) async {
    await _dio.delete('/api/v1/saved/$savedId');
  }
}
