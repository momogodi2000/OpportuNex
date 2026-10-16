import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json.dart';

export '../../core/ref_data.dart' show refCountriesProvider;

class SearchRepository {
  SearchRepository(this._api);
  final ApiClient _api;

  /// Filters plus `interpreter` (`rules` or `ai`); the engine answers 409 `ai_consent_required` when needed.
  Future<Json> interpret(String text, {bool useAi = true}) =>
      _api.postJson('/search/interpret', body: {'text': text, 'use_ai': useAi});
  Future<List<String>> suggestions() async => (await _api.getJson('/search/suggestions')).strings('items');
  Future<Json> start(String text, Json filters, {String? workspaceId}) => _api.postJson('/search/runs',
      body: {'text': text, 'filters': filters, 'workspace_id': ?workspaceId});
  Future<Json> run(String runId) => _api.getJson('/search/runs/$runId');
  Future<Json> results(String runId, {String sort = 'relevance', String? cursor, int? minScore, String? badge}) =>
      _api.getJson('/search/runs/$runId/results',
          query: {'sort': sort, 'cursor': cursor, 'limit': 30, 'min_score': minScore, 'badge': badge});
  Future<void> cancel(String runId) => _api.postJson('/search/runs/$runId/cancel');
  Future<Json> resume(String runId) => _api.postJson('/search/runs/$runId/resume');
  Future<List<Json>> history({bool saved = false}) async => items(await _api.getJson('/search/history', query: {'saved': saved}));
  Future<void> saveQuery(String queryId, String? name) => _api.putJson('/search/queries/$queryId/save', body: {'name': name});
  Future<Json> rerun(String queryId) => _api.postJson('/search/queries/$queryId/rerun');
  Future<void> clearHistory() => _api.delete('/search/history');
  Future<Json> compare(String a, String b) => _api.getJson('/search/runs/compare', query: {'a': a, 'b': b});
  Future<Json> local(String q, {String? cursor}) => _api.getJson('/search/local', query: {'q': q, 'cursor': cursor});
  Future<Json> save(String opportunityId) => _api.postJson('/saved', body: {'opportunity_id': opportunityId});
  Future<Uint8List> export(String format, String runId) async {
    // Exports are POST requests returning a file; ApiClient.getBytes covers GET, so reuse Dio via postJson-like call.
    return _api.postBytes('/exports', body: {'format': format, 'scope': 'filtered_results', 'run_id': runId});
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) => SearchRepository(requireApi(ref)));

final refCategoriesProvider = FutureProvider<List<Json>>((ref) async =>
    items(await requireApi(ref).getJson('/ref/categories')));
final refLanguagesProvider = FutureProvider<List<Json>>((ref) async =>
    items(await requireApi(ref).getJson('/ref/languages')));
final refObjectivesProvider = FutureProvider<List<Json>>((ref) async =>
    items(await requireApi(ref).getJson('/ref/objectives')));
