import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json.dart';

/// AI configuration (M14). AI stays off until the user turns it on (D-15).
class AiRepository {
  AiRepository(this._api);
  final ApiClient _api;

  Future<Json> settings() => _api.getJson('/ai/settings');
  Future<Json> setEnabled(bool enabled) => _api.putJson('/ai/settings', body: {'enabled': enabled});
  Future<Json> route(String task, String? providerId) =>
      _api.putJson('/ai/routing/$task', body: {'provider_id': providerId});
  Future<List<Json>> providers() async => items(await _api.getJson('/ai/providers'));
  Future<Json> create(Json body) => _api.postJson('/ai/providers', body: body);
  Future<Json> update(String id, Json body) => _api.patchJson('/ai/providers/$id', body: body);
  Future<void> delete(String id) => _api.delete('/ai/providers/$id');
  Future<Json> test(String id) => _api.postJson('/ai/providers/$id/test');
  Future<void> reorder(List<String> ids) => _api.putJson('/ai/providers/order', body: {'ids': ids});
  Future<Json> grant(String id, List<String> purposes) =>
      _api.postJson('/ai/providers/$id/consents', body: {'purposes': purposes});
  Future<List<Json>> usage({int days = 30}) async => items(await _api.getJson('/ai/usage', query: {'days': days}));
}

final aiRepositoryProvider = Provider<AiRepository>((ref) => AiRepository(requireApi(ref)));
final aiSettingsProvider = FutureProvider.autoDispose<Json>((ref) => ref.watch(aiRepositoryProvider).settings());
final aiProvidersProvider = FutureProvider.autoDispose<List<Json>>((ref) => ref.watch(aiRepositoryProvider).providers());
final aiUsageProvider = FutureProvider.autoDispose<List<Json>>((ref) => ref.watch(aiRepositoryProvider).usage());

/// True when AI features should be offered in the UI (switched on and at least one provider enabled).
final aiAvailableProvider = FutureProvider.autoDispose<bool>((ref) async {
  final s = await ref.watch(aiSettingsProvider.future);
  if (!s.flag('enabled')) return false;
  final providers = await ref.watch(aiProvidersProvider.future);
  return providers.any((p) => p.flag('enabled'));
});
