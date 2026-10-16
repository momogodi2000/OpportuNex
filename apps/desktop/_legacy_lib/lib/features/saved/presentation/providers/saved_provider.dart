import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/saved_repository.dart';
import '../../../../core/services/engine_http_client.dart';

final savedRepositoryProvider = Provider<SavedRepository>((ref) {
  final dio = ref.watch(engineHttpClientProvider);
  if (dio == null) throw Exception('Engine is not healthy');
  return SavedRepository(dio);
});

final savedOpportunitiesProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(savedRepositoryProvider);
  return repo.getSavedOpportunities();
});
