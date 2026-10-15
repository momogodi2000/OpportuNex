import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart' show Json;
import '../../core/api/engine_events.dart';
import '../../core/api/json.dart';
import 'search_repository.dart';

enum SearchStage { idle, interpreting, editing, running, done }

@immutable
class SearchState {
  const SearchState({
    this.stage = SearchStage.idle,
    this.text = '',
    this.filters,
    this.run,
    this.results = const [],
    this.total = 0,
    this.nextCursor,
    this.sort = 'relevance',
    this.minScore,
    this.badge,
    this.error,
    this.loadingMore = false,
  });

  final SearchStage stage;
  final String text;
  final Json? filters;
  final Json? run;
  final List<Json> results;
  final int total;
  final String? nextCursor;
  final String sort;
  final int? minScore;
  final String? badge;
  final Object? error;
  final bool loadingMore;

  String? get runId => run?.obj('run').str('id');
  String get runStatus => run?.obj('run').string('status') ?? '';
  bool get isRunning => runStatus == 'queued' || runStatus == 'running';

  SearchState copyWith({
    SearchStage? stage,
    String? text,
    Json? filters,
    Json? run,
    List<Json>? results,
    int? total,
    String? nextCursor,
    bool clearCursor = false,
    String? sort,
    int? minScore,
    bool clearMinScore = false,
    String? badge,
    bool clearBadge = false,
    Object? error,
    bool clearError = false,
    bool? loadingMore,
  }) =>
      SearchState(
        stage: stage ?? this.stage,
        text: text ?? this.text,
        filters: filters ?? this.filters,
        run: run ?? this.run,
        results: results ?? this.results,
        total: total ?? this.total,
        nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
        sort: sort ?? this.sort,
        minScore: clearMinScore ? null : (minScore ?? this.minScore),
        badge: clearBadge ? null : (badge ?? this.badge),
        error: clearError ? null : (error ?? this.error),
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

class SearchController extends Notifier<SearchState> {
  Timer? _poll;

  SearchRepository get _repo => ref.read(searchRepositoryProvider);

  @override
  SearchState build() {
    ref.onDispose(() => _poll?.cancel());
    ref.listen(engineEventsProvider, (_, next) {
      final e = next.valueOrNull;
      if (e == null || state.runId == null) return;
      if ((e.type == 'job.progress' && e.data['run_id'] == state.runId) ||
          (e.type == 'search.completed' && e.data['run_id'] == state.runId)) {
        unawaited(_refreshRun());
      }
    });
    return const SearchState();
  }

  Future<void> interpret(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;
    state = state.copyWith(stage: SearchStage.interpreting, text: query, clearError: true);
    try {
      final filters = await _repo.interpret(query);
      state = state.copyWith(stage: SearchStage.editing, filters: filters);
    } on Object catch (e) {
      state = state.copyWith(stage: SearchStage.idle, error: e);
    }
  }

  void updateFilters(Json filters) => state = state.copyWith(filters: filters);

  Future<void> start({String? workspaceId}) async {
    final filters = state.filters;
    if (filters == null) return;
    state = state.copyWith(stage: SearchStage.running, results: const [], total: 0, clearCursor: true, clearError: true);
    try {
      final started = await _repo.start(state.text, filters, workspaceId: workspaceId);
      await _loadRun(started.string('run_id'));
    } on Object catch (e) {
      state = state.copyWith(stage: SearchStage.editing, error: e);
    }
  }

  Future<void> open(String runId) async {
    state = state.copyWith(stage: SearchStage.running, clearError: true);
    await _loadRun(runId);
  }

  Future<void> rerun(String queryId) async {
    state = state.copyWith(stage: SearchStage.running, results: const [], clearCursor: true, clearError: true);
    try {
      final started = await _repo.rerun(queryId);
      await _loadRun(started.string('run_id'));
    } on Object catch (e) {
      state = state.copyWith(stage: SearchStage.idle, error: e);
    }
  }

  Future<void> _loadRun(String runId) async {
    final run = await _repo.run(runId);
    final query = run.obj('query');
    state = state.copyWith(run: run, text: query.string('raw_text'), filters: query.obj('filters'));
    _poll?.cancel();
    if (state.isRunning) {
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => unawaited(_refreshRun()));
    } else {
      await _finish();
    }
  }

  Future<void> _refreshRun() async {
    final id = state.runId;
    if (id == null) return;
    try {
      final run = await _repo.run(id);
      state = state.copyWith(run: run);
      if (!state.isRunning) {
        _poll?.cancel();
        await _finish();
      }
    } on Object catch (e) {
      state = state.copyWith(error: e);
    }
  }

  Future<void> _finish() async {
    state = state.copyWith(stage: SearchStage.done);
    await reload();
  }

  Future<void> reload() async {
    final id = state.runId;
    if (id == null) return;
    try {
      final page = await _repo.results(id, sort: state.sort, minScore: state.minScore, badge: state.badge);
      state = state.copyWith(results: page.list('items'), total: page.integer('total') ?? 0,
          nextCursor: page.str('next_cursor'), clearCursor: page.str('next_cursor') == null);
    } on Object catch (e) {
      state = state.copyWith(error: e);
    }
  }

  Future<void> loadMore() async {
    final id = state.runId;
    final cursor = state.nextCursor;
    if (id == null || cursor == null || state.loadingMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _repo.results(id, sort: state.sort, cursor: cursor, minScore: state.minScore, badge: state.badge);
      state = state.copyWith(results: [...state.results, ...page.list('items')], nextCursor: page.str('next_cursor'),
          clearCursor: page.str('next_cursor') == null, loadingMore: false);
    } on Object catch (e) {
      state = state.copyWith(error: e, loadingMore: false);
    }
  }

  Future<void> setSort(String sort) async {
    state = state.copyWith(sort: sort);
    await reload();
  }

  Future<void> setMinScore(int? v) async {
    state = v == null ? state.copyWith(clearMinScore: true) : state.copyWith(minScore: v);
    await reload();
  }

  Future<void> setBadge(String? b) async {
    state = b == null ? state.copyWith(clearBadge: true) : state.copyWith(badge: b);
    await reload();
  }

  Future<void> cancel() async {
    final id = state.runId;
    if (id == null) return;
    await _repo.cancel(id);
    await _refreshRun();
  }

  Future<void> resume() async {
    final id = state.runId;
    if (id == null) return;
    await _repo.resume(id);
    await _loadRun(id);
  }

  Future<void> save(String opportunityId) async {
    await _repo.save(opportunityId);
    state = state.copyWith(results: [
      for (final r in state.results) r.str('id') == opportunityId ? ({...r, 'is_saved': true}) : r,
    ]);
  }

  void reset() {
    _poll?.cancel();
    state = const SearchState();
  }
}

final searchControllerProvider = NotifierProvider<SearchController, SearchState>(SearchController.new);
final searchHistoryProvider = FutureProvider.autoDispose<List<Json>>((ref) => ref.watch(searchRepositoryProvider).history());
final searchSuggestionsProvider =
    FutureProvider.autoDispose<List<String>>((ref) => ref.watch(searchRepositoryProvider).suggestions());
