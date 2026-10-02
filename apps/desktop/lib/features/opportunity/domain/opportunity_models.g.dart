// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opportunity_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProvenancedFieldImpl<T> _$$ProvenancedFieldImplFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => _$ProvenancedFieldImpl<T>(
  value: fromJsonT(json['value']),
  provenance:
      $enumDecodeNullable(_$ProvenanceTagEnumMap, json['provenance']) ??
      ProvenanceTag.notSpecified,
  excerpt: json['excerpt'] as String?,
  confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$ProvenancedFieldImplToJson<T>(
  _$ProvenancedFieldImpl<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'value': toJsonT(instance.value),
  'provenance': _$ProvenanceTagEnumMap[instance.provenance]!,
  'excerpt': instance.excerpt,
  'confidence': instance.confidence,
};

const _$ProvenanceTagEnumMap = {
  ProvenanceTag.explicit: 'explicit',
  ProvenanceTag.inferred: 'inferred',
  ProvenanceTag.generated: 'generated',
  ProvenanceTag.notSpecified: 'notSpecified',
  ProvenanceTag.unverifiable: 'unverifiable',
};

_$OpportunityListItemImpl _$$OpportunityListItemImplFromJson(
  Map<String, dynamic> json,
) => _$OpportunityListItemImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  organization: json['organization'] as String,
  categoryId: json['categoryId'] as String,
  deadlineIso: DateTime.parse(json['deadlineIso'] as String),
  location: json['location'] as String,
  countryCode: json['countryCode'] as String,
  matchScore: (json['matchScore'] as num?)?.toInt(),
  provenanceDeadline: $enumDecode(
    _$ProvenanceTagEnumMap,
    json['provenanceDeadline'],
  ),
  isSaved: json['isSaved'] as bool? ?? false,
  isNew: json['isNew'] as bool? ?? true,
  currencyCode: json['currencyCode'] as String?,
  amountMin: (json['amountMin'] as num?)?.toDouble(),
  amountMax: (json['amountMax'] as num?)?.toDouble(),
  sourceCount: (json['sourceCount'] as num?)?.toInt() ?? 1,
  collectedAt: DateTime.parse(json['collectedAt'] as String),
);

Map<String, dynamic> _$$OpportunityListItemImplToJson(
  _$OpportunityListItemImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'organization': instance.organization,
  'categoryId': instance.categoryId,
  'deadlineIso': instance.deadlineIso.toIso8601String(),
  'location': instance.location,
  'countryCode': instance.countryCode,
  'matchScore': instance.matchScore,
  'provenanceDeadline': _$ProvenanceTagEnumMap[instance.provenanceDeadline]!,
  'isSaved': instance.isSaved,
  'isNew': instance.isNew,
  'currencyCode': instance.currencyCode,
  'amountMin': instance.amountMin,
  'amountMax': instance.amountMax,
  'sourceCount': instance.sourceCount,
  'collectedAt': instance.collectedAt.toIso8601String(),
};

_$OpportunityDetailImpl _$$OpportunityDetailImplFromJson(
  Map<String, dynamic> json,
) => _$OpportunityDetailImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  organization: json['organization'] as String,
  categoryId: json['categoryId'] as String,
  deadlineIso: DateTime.parse(json['deadlineIso'] as String),
  location: json['location'] as String,
  countryCode: json['countryCode'] as String,
  matchScore: (json['matchScore'] as num?)?.toInt(),
  provenanceDeadline: $enumDecode(
    _$ProvenanceTagEnumMap,
    json['provenanceDeadline'],
  ),
  isSaved: json['isSaved'] as bool? ?? false,
  isNew: json['isNew'] as bool? ?? true,
  currencyCode: json['currencyCode'] as String?,
  amountMin: (json['amountMin'] as num?)?.toDouble(),
  amountMax: (json['amountMax'] as num?)?.toDouble(),
  sourceCount: (json['sourceCount'] as num?)?.toInt() ?? 1,
  collectedAt: DateTime.parse(json['collectedAt'] as String),
  fullText: json['fullText'] as String,
  summaryAi: json['summaryAi'] as String,
  eligibilityVerbatim: json['eligibilityVerbatim'] as String?,
  eligibilityAnalysis: json['eligibilityAnalysis'] as String?,
  allFields:
      (json['allFields'] as List<dynamic>?)
          ?.map(
            (e) => OpportunityFieldSummary.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  relatedOpportunities:
      (json['relatedOpportunities'] as List<dynamic>?)
          ?.map((e) => OpportunityListItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  applicationStatus: json['applicationStatus'] as String?,
  userNotes: json['userNotes'] as String?,
);

Map<String, dynamic> _$$OpportunityDetailImplToJson(
  _$OpportunityDetailImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'organization': instance.organization,
  'categoryId': instance.categoryId,
  'deadlineIso': instance.deadlineIso.toIso8601String(),
  'location': instance.location,
  'countryCode': instance.countryCode,
  'matchScore': instance.matchScore,
  'provenanceDeadline': _$ProvenanceTagEnumMap[instance.provenanceDeadline]!,
  'isSaved': instance.isSaved,
  'isNew': instance.isNew,
  'currencyCode': instance.currencyCode,
  'amountMin': instance.amountMin,
  'amountMax': instance.amountMax,
  'sourceCount': instance.sourceCount,
  'collectedAt': instance.collectedAt.toIso8601String(),
  'fullText': instance.fullText,
  'summaryAi': instance.summaryAi,
  'eligibilityVerbatim': instance.eligibilityVerbatim,
  'eligibilityAnalysis': instance.eligibilityAnalysis,
  'allFields': instance.allFields,
  'relatedOpportunities': instance.relatedOpportunities,
  'applicationStatus': instance.applicationStatus,
  'userNotes': instance.userNotes,
};

_$OpportunityFieldSummaryImpl _$$OpportunityFieldSummaryImplFromJson(
  Map<String, dynamic> json,
) => _$OpportunityFieldSummaryImpl(
  fieldName: json['fieldName'] as String,
  displayName: json['displayName'] as String,
  value: json['value'] as String,
  provenance: $enumDecode(_$ProvenanceTagEnumMap, json['provenance']),
  excerpt: json['excerpt'] as String?,
  confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$OpportunityFieldSummaryImplToJson(
  _$OpportunityFieldSummaryImpl instance,
) => <String, dynamic>{
  'fieldName': instance.fieldName,
  'displayName': instance.displayName,
  'value': instance.value,
  'provenance': _$ProvenanceTagEnumMap[instance.provenance]!,
  'excerpt': instance.excerpt,
  'confidence': instance.confidence,
};

_$MatchScoreDetailImpl _$$MatchScoreDetailImplFromJson(
  Map<String, dynamic> json,
) => _$MatchScoreDetailImpl(
  totalScore: (json['totalScore'] as num).toInt(),
  eligibility: json['eligibility'] as String,
  criteria:
      (json['criteria'] as List<dynamic>?)
          ?.map((e) => MatchCriterion.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  strengths:
      (json['strengths'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  gaps:
      (json['gaps'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  conditionsToVerify:
      (json['conditionsToVerify'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$$MatchScoreDetailImplToJson(
  _$MatchScoreDetailImpl instance,
) => <String, dynamic>{
  'totalScore': instance.totalScore,
  'eligibility': instance.eligibility,
  'criteria': instance.criteria,
  'strengths': instance.strengths,
  'gaps': instance.gaps,
  'conditionsToVerify': instance.conditionsToVerify,
};

_$MatchCriterionImpl _$$MatchCriterionImplFromJson(Map<String, dynamic> json) =>
    _$MatchCriterionImpl(
      name: json['name'] as String,
      labelFr: json['labelFr'] as String,
      score: (json['score'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      notEvaluated: json['notEvaluated'] as bool? ?? false,
    );

Map<String, dynamic> _$$MatchCriterionImplToJson(
  _$MatchCriterionImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'labelFr': instance.labelFr,
  'score': instance.score,
  'weight': instance.weight,
  'notEvaluated': instance.notEvaluated,
};
