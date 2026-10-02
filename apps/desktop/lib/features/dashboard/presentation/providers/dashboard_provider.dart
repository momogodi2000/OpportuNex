import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../domain/dashboard_models.dart';
import '../data/dashboard_repository.dart';

final dioProviderDashboard = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'https://api.opportunex.local'));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dio = ref.watch(dioProviderDashboard);
  return DashboardRepository(dio);
});

class DashboardState {
  final DashboardCounters counters;
  final List<UpcomingDeadline> upcomingDeadlines;
  final List<RecentActivity> recentActivity;
  final List<SourceHealth> sourceHealth;

  DashboardState({
    required this.counters,
    required this.upcomingDeadlines,
    required this.recentActivity,
    required this.sourceHealth,
  });
}

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  Timer? _refreshTimer;

  @override
  Future<DashboardState> build() async {
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      refreshAll();
    });

    ref.onDispose(() {
      _refreshTimer?.cancel();
    });

    return _fetchData();
  }

  Future<DashboardState> _fetchData() async {
    final repo = ref.read(dashboardRepositoryProvider);

    final results = await Future.wait([
      repo.getCounters(),
      repo.getUpcomingDeadlines(),
      repo.getRecentActivity(),
      repo.getSourceHealth(),
    ]);

    return DashboardState(
      counters: results[0] as DashboardCounters,
      upcomingDeadlines: results[1] as List<UpcomingDeadline>,
      recentActivity: results[2] as List<RecentActivity>,
      sourceHealth: results[3] as List<SourceHealth>,
    );
  }

  Future<void> refreshAll() async {
    state = const AsyncValue.loading();
    try {
      final data = await _fetchData();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(() {
      return DashboardNotifier();
    });
