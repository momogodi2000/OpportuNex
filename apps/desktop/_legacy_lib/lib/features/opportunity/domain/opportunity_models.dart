import 'package:freezed_annotation/freezed_annotation.dart';

part 'opportunity_models.freezed.dart';
part 'opportunity_models.g.dart';

enum ProvenanceTag { explicit, inferred, generated, notSpecified, unverifiable }

@Freezed(genericArgumentFactories: true)
class ProvenancedField<T> with _$ProvenancedField<T> {
  const factory ProvenancedField({
    required T value,
    @Default(ProvenanceTag.notSpecified) ProvenanceTag provenance,
    String? excerpt,
    @Default(0.0) double confidence,
  }) = _ProvenancedField<T>;

  factory ProvenancedField.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ProvenancedFieldFromJson(json, fromJsonT);
}

@freezed
class OpportunityListItem with _$OpportunityListItem {
  const factory OpportunityListItem({
    required String id,
    required String title,
    required String organization,
    required String categoryId,
    required DateTime deadlineIso,
    required String location,
    required String countryCode,
    int? matchScore,
    required ProvenanceTag provenanceDeadline,
    @Default(false) bool isSaved,
    @Default(true) bool isNew,
    String? currencyCode,
    double? amountMin,
    double? amountMax,
    @Default(1) int sourceCount,
    required DateTime collectedAt,
  }) = _OpportunityListItem;

  factory OpportunityListItem.fromJson(Map<String, dynamic> json) =>
      _$OpportunityListItemFromJson(json);
}

@freezed
class OpportunityDetail with _$OpportunityDetail {
  const factory OpportunityDetail({
    required String id,
    required String title,
    required String organization,
    required String categoryId,
    required DateTime deadlineIso,
    required String location,
    required String countryCode,
    int? matchScore,
    required ProvenanceTag provenanceDeadline,
    @Default(false) bool isSaved,
    @Default(true) bool isNew,
    String? currencyCode,
    double? amountMin,
    double? amountMax,
    @Default(1) int sourceCount,
    required DateTime collectedAt,

    required String fullText,
    required String summaryAi,
    String? eligibilityVerbatim,
    String? eligibilityAnalysis,
    @Default([]) List<OpportunityFieldSummary> allFields,
    @Default([]) List<OpportunityListItem> relatedOpportunities,
    String? applicationStatus,
    String? userNotes,
  }) = _OpportunityDetail;

  factory OpportunityDetail.fromJson(Map<String, dynamic> json) =>
      _$OpportunityDetailFromJson(json);
}

@freezed
class OpportunityFieldSummary with _$OpportunityFieldSummary {
  const factory OpportunityFieldSummary({
    required String fieldName,
    required String displayName,
    required String value,
    required ProvenanceTag provenance,
    String? excerpt,
    @Default(0.0) double confidence,
  }) = _OpportunityFieldSummary;

  factory OpportunityFieldSummary.fromJson(Map<String, dynamic> json) =>
      _$OpportunityFieldSummaryFromJson(json);
}

@freezed
class MatchScoreDetail with _$MatchScoreDetail {
  const factory MatchScoreDetail({
    required int totalScore,
    required String eligibility, // probable, uncertain, unlikely
    @Default([]) List<MatchCriterion> criteria,
    @Default([]) List<String> strengths,
    @Default([]) List<String> gaps,
    @Default([]) List<String> conditionsToVerify,
  }) = _MatchScoreDetail;

  factory MatchScoreDetail.fromJson(Map<String, dynamic> json) =>
      _$MatchScoreDetailFromJson(json);
}

@freezed
class MatchCriterion with _$MatchCriterion {
  const factory MatchCriterion({
    required String name,
    required String labelFr,
    required double score,
    required double weight,
    @Default(false) bool notEvaluated,
  }) = _MatchCriterion;

  factory MatchCriterion.fromJson(Map<String, dynamic> json) =>
      _$MatchCriterionFromJson(json);
}
