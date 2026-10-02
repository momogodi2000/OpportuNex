import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/engine_http_client.dart';
import '../domain/monitor_models.dart';

final monitorRepositoryProvider = Provider<MonitorRepository>((ref) {
  final dio = ref.watch(engineHttpClientProvider);
  return MonitorRepository(dio);
});

class MonitorRepository {
  final Dio _dio;

  MonitorRepository(this._dio);

  Future<List<MonitorModel>> getMonitors() async {
    final response = await _dio.get('/api/v1/monitors');
    final data = response.data as List;
    return data
        .map((e) => MonitorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MonitorModel> createMonitor(MonitorModel monitor) async {
    final response = await _dio.post(
      '/api/v1/monitors',
      data: monitor.toJson()
        ..remove('id')
        ..remove('createdAt'),
    );
    return MonitorModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MonitorModel> getMonitorById(String id) async {
    final response = await _dio.get('/api/v1/monitors/$id');
    return MonitorModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MonitorModel> updateMonitor(String id, MonitorModel monitor) async {
    final response = await _dio.put(
      '/api/v1/monitors/$id',
      data: monitor.toJson(),
    );
    return MonitorModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteMonitor(String id) async {
    await _dio.delete('/api/v1/monitors/$id');
  }

  Future<void> runMonitorNow(String id) async {
    await _dio.post('/api/v1/monitors/$id/run-now');
  }

  Future<List<MonitorResult>> getMonitorResults(String id) async {
    final response = await _dio.get('/api/v1/monitors/$id/results');
    final data = response.data as List;
    return data
        .map((e) => MonitorResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
