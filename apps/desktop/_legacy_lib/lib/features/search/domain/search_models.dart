import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_models.freezed.dart';
part 'search_models.g.dart';

@freezed
class SearchFilters with _$SearchFilters {
  const factory SearchFilters({
    String? keywords,
    @Default([]) List<String> categories,
    @Default([]) List<String> countries,
    double? amountMin,
    double? amountMax,
    String? currencyCode,
    DateTime? deadline,
    @Default([]) List<String> languages,
    @Default([]) List<String> sourceIds,
    @Default(false) bool remoteOnly,
    @Default('relevance') String sortBy,
    @Default(1) int page,
  }) = _SearchFilters;

  factory SearchFilters.fromJson(Map<String, dynamic> json) =>
      _$SearchFiltersFromJson(json);
}

@freezed
class SearchResult with _$SearchResult {
  const factory SearchResult({
    required String id,
    required String title,
    required String organization,
    required String category,
    required double score,
    DateTime? deadline,
    required String location,
    required String provenanceDeadline,
    @Default(false) bool isNew,
    @Default(false) bool isSaved,
  }) = _SearchResult;

  factory SearchResult.fromJson(Map<String, dynamic> json) =>
      _$SearchResultFromJson(json);
}

@freezed
class SearchResultPage with _$SearchResultPage {
  const factory SearchResultPage({
    @Default([]) List<SearchResult> items,
    String? cursor,
    @Default(false) bool hasMore,
    @Default(0) int totalEstimate,
    String? searchRunId,
  }) = _SearchResultPage;

  factory SearchResultPage.fromJson(Map<String, dynamic> json) =>
      _$SearchResultPageFromJson(json);
}

enum SearchState { idle, searching, results, error }

@freezed
class SearchInterpretation with _$SearchInterpretation {
  const factory SearchInterpretation({
    required String originalQuery,
    required SearchFilters interpretedFilters,
    @Default([]) List<String> nlpKeywords,
    @Default(0.0) double confidence,
  }) = _SearchInterpretation;

  factory SearchInterpretation.fromJson(Map<String, dynamic> json) =>
      _$SearchInterpretationFromJson(json);
}
