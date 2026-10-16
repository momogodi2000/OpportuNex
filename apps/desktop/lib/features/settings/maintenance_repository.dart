import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';

class BackupInfo {
  const BackupInfo({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.sizeBytes,
    required this.status,
    required this.available,
    required this.schemaVersion,
  });

  factory BackupInfo.fromJson(Json j) => BackupInfo(
        id: j['id'] as String,
        kind: j['kind'] as String,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        sizeBytes: (j['size_bytes'] as num).toInt(),
        status: j['status'] as String,
        available: j['available'] as bool? ?? false,
        schemaVersion: j['schema_version'] as String? ?? '',
      );

  final String id;
  final String kind;
  final DateTime createdAt;
  final int sizeBytes;
  final String status;
  final bool available;
  final String schemaVersion;
}

class BackupOverview {
  const BackupOverview({required this.items, required this.autoEnabled, required this.directory, this.lastScheduledAt});

  final List<BackupInfo> items;
  final bool autoEnabled;
  final String directory;
  final String? lastScheduledAt;
}

class MaintenanceRepository {
  MaintenanceRepository(this._api);
  final ApiClient _api;

  Future<BackupOverview> backups() async {
    final r = await _api.getJson('/backups');
    final settings = r['settings'] as Json;
    return BackupOverview(
      items: (r['items'] as List<dynamic>).cast<Json>().map(BackupInfo.fromJson).toList(),
      autoEnabled: settings['auto_enabled'] as bool,
      directory: settings['directory'] as String,
      lastScheduledAt: settings['last_scheduled_at'] as String?,
    );
  }

  Future<void> createBackup() => _api.postJson('/backups');
  Future<void> setAutoBackup(bool enabled) => _api.putJson('/backups/settings', body: {'auto_enabled': enabled});
  Future<Json> verify(String id) => _api.postJson('/backups/$id/verify');
  Future<void> restore(String id, String password) =>
      _api.postJson('/backups/$id/restore', body: {'password': password, 'confirmation': 'RESTORE'});
  Future<void> delete(String id) => _api.delete('/backups/$id');

  Future<Json> integrity() => _api.getJson('/maintenance/integrity');
  Future<Json> optimize() => _api.postJson('/maintenance/optimize');
  Future<Json> storage() => _api.getJson('/maintenance/storage');
  Future<List<int>> logs() => _api.getBytes('/maintenance/logs');
  Future<Json> version() => _api.getJson('/version');
}

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) => MaintenanceRepository(requireApi(ref)));

final backupsProvider = FutureProvider.autoDispose<BackupOverview>(
  (ref) => ref.watch(maintenanceRepositoryProvider).backups(),
);

final storageProvider = FutureProvider.autoDispose<Json>((ref) => ref.watch(maintenanceRepositoryProvider).storage());

final versionProvider = FutureProvider<Json>((ref) => ref.watch(maintenanceRepositoryProvider).version());
