import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/workspaces_repository.dart';
import '../../../../core/services/engine_http_client.dart';

final workspacesRepositoryProvider = Provider<WorkspacesRepository>((ref) {
  final dio = ref.watch(engineHttpClientProvider);
  if (dio == null) throw Exception('Engine is not healthy');
  return WorkspacesRepository(dio);
});

final workspacesProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(workspacesRepositoryProvider);
  return repo.getWorkspaces();
});
