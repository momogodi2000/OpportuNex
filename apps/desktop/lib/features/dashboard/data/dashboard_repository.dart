import 'package:dio/dio.dart';
import '../domain/dashboard_models.dart';

class DashboardRepositoryException implements Exception {
  final String message;
  DashboardRepositoryException(this.message);

  @override
  String toString() => message;
}

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<DashboardCounters> getCounters() async {
    try {
      final response = await _dio.get('/api/v1/dashboard/counters');
      return DashboardCounters.fromJson(response.data);
    } on DioException catch (e) {
      throw DashboardRepositoryException(
        'Erreur lors de la récupération des compteurs: ${e.message}',
      );
    }
  }

  Future<List<UpcomingDeadline>> getUpcomingDeadlines({int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/api/v1/dashboard/upcoming-deadlines',
        queryParameters: {'limit': limit},
      );
      return (response.data as List)
          .map((e) => UpcomingDeadline.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw DashboardRepositoryException(
        'Erreur lors de la récupération des dates limites: ${e.message}',
      );
    }
  }

  Future<List<RecentActivity>> getRecentActivity({int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/api/v1/dashboard/recent-activity',
        queryParameters: {'limit': limit},
      );
      return (response.data as List)
          .map((e) => RecentActivity.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw DashboardRepositoryException(
        'Erreur lors de la récupération de l\'activité: ${e.message}',
      );
    }
  }

  Future<List<SourceHealth>> getSourceHealth() async {
    try {
      final response = await _dio.get('/api/v1/dashboard/source-health');
      return (response.data as List)
          .map((e) => SourceHealth.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw DashboardRepositoryException(
        'Erreur lors de la récupération de la santé des sources: ${e.message}',
      );
    }
  }
}
