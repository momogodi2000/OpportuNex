import 'package:dio/dio.dart';
import '../domain/search_models.dart';

class SearchRepositoryException implements Exception {
  final String message;
  SearchRepositoryException(this.message);

  @override
  String toString() => message;
}

class SearchRepository {
  final Dio _dio;

  SearchRepository(this._dio);

  Future<SearchInterpretation> interpretQuery(String text) async {
    try {
      final response = await _dio.post(
        '/api/v1/search/interpret',
        data: {'query': text},
      );
      return SearchInterpretation.fromJson(response.data);
    } on DioException catch (e) {
      throw SearchRepositoryException(
        'Erreur lors de l\'interprétation: ${e.message}',
      );
    }
  }

  Future<String> runSearch(SearchFilters filters) async {
    try {
      final response = await _dio.post(
        '/api/v1/search/run',
        data: filters.toJson(),
      );
      return response.data['job_id'] as String;
    } on DioException catch (e) {
      throw SearchRepositoryException(
        'Erreur lors du lancement de la recherche: ${e.message}',
      );
    }
  }

  Future<SearchResultPage> getResults(String runId, {String? cursor}) async {
    try {
      final response = await _dio.get(
        '/api/v1/search/run/$runId/results',
        queryParameters: cursor != null ? {'cursor': cursor} : null,
      );
      return SearchResultPage.fromJson(response.data);
    } on DioException catch (e) {
      throw SearchRepositoryException(
        'Erreur lors de la récupération des résultats: ${e.message}',
      );
    }
  }

  Future<List<String>> suggestKeywords(String query) async {
    try {
      final response = await _dio.get(
        '/api/v1/search/suggest',
        queryParameters: {'q': query},
      );
      return List<String>.from(response.data['suggestions'] ?? []);
    } on DioException catch (e) {
      throw SearchRepositoryException(
        'Erreur lors de la suggestion: ${e.message}',
      );
    }
  }
}
