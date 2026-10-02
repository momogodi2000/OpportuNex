import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../domain/search_models.dart';
import '../data/search_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'https://api.opportunex.local'));
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SearchRepository(dio);
});

class SearchPageStateModel {
  final String query;
  final SearchFilters filters;
  final SearchInterpretation? interpretation;
  final List<SearchResult> results;
  final SearchState status;
  final String? cursor;
  final bool hasMore;
  final String? errorMessage;
  final String? currentRunId;
  final double progress;
  final String? currentSource;

  SearchPageStateModel({
    this.query = '',
    this.filters = const SearchFilters(),
    this.interpretation,
    this.results = const [],
    this.status = SearchState.idle,
    this.cursor,
    this.hasMore = false,
    this.errorMessage,
    this.currentRunId,
    this.progress = 0.0,
    this.currentSource,
  });

  SearchPageStateModel copyWith({
    String? query,
    SearchFilters? filters,
    SearchInterpretation? interpretation,
    List<SearchResult>? results,
    SearchState? status,
    String? cursor,
    bool? hasMore,
    String? errorMessage,
    String? currentRunId,
    double? progress,
    String? currentSource,
  }) {
    return SearchPageStateModel(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      interpretation: interpretation ?? this.interpretation,
      results: results ?? this.results,
      status: status ?? this.status,
      cursor: cursor ?? this.cursor,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
      currentRunId: currentRunId ?? this.currentRunId,
      progress: progress ?? this.progress,
      currentSource: currentSource ?? this.currentSource,
    );
  }
}

class SearchProvider extends StateNotifier<SearchPageStateModel> {
  final SearchRepository _repository;
  Timer? _debounceTimer;

  SearchProvider(this._repository) : super(SearchPageStateModel());

  void interpretQuery(String text) {
    state = state.copyWith(query: text);
    if (text.isEmpty) {
      state = state.copyWith(interpretation: null);
      return;
    }

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final interpretation = await _repository.interpretQuery(text);
        state = state.copyWith(
          interpretation: interpretation,
          filters: interpretation.interpretedFilters,
        );
      } catch (e) {
        // Ignorer l'erreur d'interprétation pour ne pas bloquer l'UI
      }
    });
  }

  Future<void> applyFilters(SearchFilters filters) async {
    state = state.copyWith(
      filters: filters,
      status: SearchState.searching,
      results: [],
      errorMessage: null,
      progress: 0.1,
      currentSource: 'Initialisation...',
    );

    try {
      final runId = await _repository.runSearch(filters);
      state = state.copyWith(currentRunId: runId);

      // Simuler l'écoute WebSocket
      _simulateWebSocketEvents(runId);

      // Récupérer les premiers résultats
      await _fetchResults(runId, null);
    } catch (e) {
      state = state.copyWith(
        status: SearchState.error,
        errorMessage: e.toString(),
      );
    }
  }

  void _simulateWebSocketEvents(String runId) async {
    // Dans une vraie app, on utiliserait EventBusService / WebSocket
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (state.currentRunId != runId) return; // Annulé
      state = state.copyWith(
        progress: i / 10,
        currentSource: 'Source $i/10 en cours...',
      );
    }
  }

  Future<void> _fetchResults(String runId, String? cursor) async {
    try {
      final page = await _repository.getResults(runId, cursor: cursor);
      if (state.currentRunId != runId) return;

      state = state.copyWith(
        status: SearchState.results,
        results: cursor == null
            ? page.items
            : [...state.results, ...page.items],
        cursor: page.cursor,
        hasMore: page.hasMore,
        progress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        status: SearchState.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.status == SearchState.searching ||
        !state.hasMore ||
        state.currentRunId == null)
      return;
    state = state.copyWith(status: SearchState.searching);
    await _fetchResults(state.currentRunId!, state.cursor);
  }

  void cancelSearch() {
    state = state.copyWith(
      status: SearchState.idle,
      currentRunId: null,
      progress: 0.0,
    );
  }

  void resetSearch() {
    state = SearchPageStateModel();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final searchProvider =
    StateNotifierProvider<SearchProvider, SearchPageStateModel>((ref) {
      final repo = ref.watch(searchRepositoryProvider);
      return SearchProvider(repo);
    });
