import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json.dart';

class ProfileRepository {
  ProfileRepository(this._api);
  final ApiClient _api;

  Future<Json> get() => _api.getJson('/profile');
  Future<Json> updateGeneral(Json values) => _api.putJson('/profile/general', body: values);
  Future<Json> setLocations(List<Json> items) => _api.putJson('/profile/locations', body: items);
  Future<Json> createItem(String collection, Json values) => _api.postJson('/profile/$collection', body: values);
  Future<Json> updateItem(String collection, String id, Json values) => _api.putJson('/profile/$collection/$id', body: values);
  Future<void> deleteItem(String collection, String id) => _api.delete('/profile/$collection/$id');
  Future<Json> setSkills(List<Json> skills) => _api.putJson('/profile/skills', body: skills);
  Future<Json> setLanguages(List<Json> langs) => _api.putJson('/profile/languages', body: langs);
  Future<Json> setLinks(List<Json> links) => _api.putJson('/profile/links', body: links);
  Future<Json> setObjectives(List<int> ids, List<String> custom) =>
      _api.putJson('/profile/objectives', body: {'objective_ids': ids, 'custom': custom});
  Future<Json> setOrganization(Json values) => _api.putJson('/profile/organization', body: values);
  Future<void> deleteOrganization() => _api.delete('/profile/organization');
  Future<String> generateSummary(String lang) async =>
      (await _api.postJson('/profile/summary/generate', query: {'lang': lang})).string('text');
  Future<Json> saveSummary(String text, bool approved) =>
      _api.putJson('/profile/summary', body: {'text': text, 'approved': approved});
  Future<Json> completeOnboarding() => _api.postJson('/profile/onboarding/complete');
  Future<List<Json>> skills(String q) async => items(await _api.getJson('/ref/skills', query: {'q': q, 'limit': 12}));

  Future<List<Json>> cvImports() async => items(await _api.getJson('/cv-imports'));
  Future<Json> uploadCv(String name, List<int> bytes, bool keep) =>
      _api.upload('/cv-imports', fileName: name, bytes: bytes, fields: {'keep_file': '$keep'});
  Future<Json> cvImport(String id) => _api.getJson('/cv-imports/$id');
  Future<Json> decide(String id, int itemId, String decision, {Json? payload}) =>
      _api.putJson('/cv-imports/$id/items/$itemId', body: {'decision': decision, 'payload': ?payload});
  Future<Json> applyCv(String id) => _api.postJson('/cv-imports/$id/apply');
  Future<void> discardCv(String id) => _api.delete('/cv-imports/$id');
  Future<void> deleteCvFile(String id) => _api.delete('/cv-imports/$id/file');
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository(requireApi(ref)));
final profileProvider = FutureProvider.autoDispose<Json>((ref) => ref.watch(profileRepositoryProvider).get());
