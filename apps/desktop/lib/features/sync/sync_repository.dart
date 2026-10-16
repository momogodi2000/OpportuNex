import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json.dart';

/// Online account, devices, sync rounds, conflicts and organisations (EF-01.09/10, M17).
class SyncRepository {
  SyncRepository(this._api);
  final ApiClient _api;

  Future<Json> status() => _api.getJson('/sync/status');
  Future<Json> register(String server, String email, String password) => _api.postJson('/sync/account/register',
      body: {'server_url': server, 'email': email, 'password': password});
  Future<Json> verify(String server, String code) =>
      _api.postJson('/sync/account/verify', body: {'server_url': server, 'code': code});
  Future<Json> resend(String server, String email) =>
      _api.postJson('/sync/account/verification', body: {'server_url': server, 'email': email});
  Future<Json> link(String server, String email, String password, {String? totp, String? deviceName}) =>
      _api.postJson('/sync/account/link', body: {
        'server_url': server, 'email': email, 'password': password, 'totp': ?totp, 'device_name': ?deviceName,
      });
  Future<Json> unlink() => _api.postJson('/sync/account/unlink');
  Future<Json> resetRequest(String server, String email) =>
      _api.postJson('/sync/account/password-reset/request', body: {'server_url': server, 'email': email});
  Future<Json> reset(String server, String code, String password) => _api.postJson('/sync/account/password-reset',
      body: {'server_url': server, 'code': code, 'password': password});
  Future<Json> account() => _api.getJson('/sync/account');
  Future<Json> totpSetup() => _api.postJson('/sync/account/totp/setup');
  Future<Json> totp(String action, String code) => _api.postJson('/sync/account/totp/$action', body: {'code': code});
  Future<Json> deleteRemote(String password) => _api.postJson('/sync/account/delete', body: {'password': password});
  Future<List<Json>> devices() async => items(await _api.getJson('/sync/devices'));
  Future<Json> approve(String id, String code) => _api.postJson('/sync/devices/$id/approve', body: {'code': code});
  Future<void> revoke(String id) => _api.postJson('/sync/devices/$id/revoke');
  Future<Json> run() => _api.postJson('/sync/run');
  Future<List<Json>> conflicts() async => items(await _api.getJson('/sync/conflicts'));
  Future<Json> resolve(int id, String choice) => _api.postJson('/sync/conflicts/$id/resolve', body: {'choice': choice});

  Future<List<Json>> orgs() async => items(await _api.getJson('/orgs'));
  Future<Json> createOrg(Json body) => _api.postJson('/orgs', body: body);
  Future<Json> join(String token) => _api.postJson('/orgs/join', body: {'token': token});
  Future<Json> invite(String orgId, String? email, String role) =>
      _api.postJson('/orgs/$orgId/invites', body: {'email': ?email, 'role': role});
  Future<Json> members(String orgId) => _api.getJson('/orgs/$orgId/members');
  Future<Json> setRole(String orgId, String accountId, String role) =>
      _api.patchJson('/orgs/$orgId/members/$accountId', body: {'role': role});
  Future<void> removeMember(String orgId, String accountId) => _api.delete('/orgs/$orgId/members/$accountId');
  Future<Json> leave(String orgId) => _api.postJson('/orgs/$orgId/leave');
  Future<List<Json>> audit(String orgId) async => items(await _api.getJson('/orgs/$orgId/audit'));
  Future<Json> share(String kind, String id, String? orgId) =>
      _api.postJson('/orgs/share', body: {'kind': kind, 'id': id, 'organization_id': orgId});
}

final syncRepositoryProvider = Provider<SyncRepository>((ref) => SyncRepository(requireApi(ref)));
final syncStatusProvider = FutureProvider.autoDispose<Json>((ref) => ref.watch(syncRepositoryProvider).status());
final syncDevicesProvider = FutureProvider.autoDispose<List<Json>>((ref) => ref.watch(syncRepositoryProvider).devices());
final syncConflictsProvider =
    FutureProvider.autoDispose<List<Json>>((ref) => ref.watch(syncRepositoryProvider).conflicts());
final orgsProvider = FutureProvider.autoDispose<List<Json>>((ref) async {
  final status = await ref.watch(syncStatusProvider.future);
  if (!status.flag('linked') || !status.flag('paired')) return const [];
  return ref.watch(syncRepositoryProvider).orgs();
});
