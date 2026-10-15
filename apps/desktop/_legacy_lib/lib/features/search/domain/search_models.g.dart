// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SearchFiltersImpl _$$SearchFiltersImplFromJson(
  Map<String, dynamic> json,
) => _$SearchFiltersImpl(
  keywords: json['keywords'] as String?,
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  countries:
      (json['countries'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  amountMin: (json['amountMin'] as num?)?.toDouble(),
  amountMax: (json['amountMax'] as num?)?.toDouble(),
  currencyCode: json['currencyCode'] as String?,
  deadline: json['deadline'] == null
      ? null
      : DateTime.parse(json['deadline'] as String),
  languages:
      (json['languages'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  sourceIds:
      (json['sourceIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  remoteOnly: json['remoteOnly'] as bool? ?? false,
  sortBy: json['sortBy'] as String? ?? 'relevance',
  page: (json['page'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$$SearchFiltersImplToJson(_$SearchFiltersImpl instance) =>
    <String, dynamic>{
      'keywords': instance.keywords,
      'categories': instance.categories,
      'countries': instance.countries,
      'amountMin': instance.amountMin,
      'amountMax': instance.amountMax,
      'currencyCode': instance.currencyCode,
      'deadline': instance.deadline?.toIso8601String(),
      'languages': instance.languages,
      'sourceIds': instance.sourceIds,
      'remoteOnly': instance.remoteOnly,
      'sortBy': instance.sortBy,
      'page': instance.page,
    };

_$SearchResultImpl _$$SearchResultImplFromJson(Map<String, dynamic> json) =>
    _$SearchResultImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      organization: json['organization'] as String,
      category: json['category'] as String,
      score: (json['score'] as num).toDouble(),
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      location: json['location'] as String,
      provenanceDeadline: json['provenanceDeadline'] as String,
      isNew: json['isNew'] as bool? ?? false,
      isSaved: json['isSaved'] as bool? ?? false,
    );

Map<String, dynamic> _$$SearchResultImplToJson(_$SearchResultImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'organization': instance.organization,
      'category': instance.category,
      'score': instance.score,
      'deadline': instance.deadline?.toIso8601String(),
      'location': instance.location,
      'provenanceDeadline': instance.provenanceDeadline,
      'isNew': instance.isNew,
      'isSaved': instance.isSaved,
    };

_$SearchResultPageImpl _$$SearchResultPageImplFromJson(
  Map<String, dynamic> json,
) => _$SearchResultPageImpl(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  cursor: json['cursor'] as String?,
  hasMore: json['hasMore'] as bool? ?? false,
  totalEstimate: (json['totalEstimate'] as num?)?.toInt() ?? 0,
  searchRunId: json['searchRunId'] as String?,
);

Map<String, dynamic> _$$SearchResultPageImplToJson(
  _$SearchResultPageImpl instance,
) => <String, dynamic>{
  'items': instance.items,
  'cursor': instance.cursor,
  'hasMore': instance.hasMore,
  'totalEstimate': instance.totalEstimate,
  'searchRunId': instance.searchRunId,
};

_$SearchInterpretationImpl _$$SearchInterpretationImplFromJson(
  Map<String, dynamic> json,
) => _$SearchInterpretationImpl(
  originalQuery: json['originalQuery'] as String,
  interpretedFilters: SearchFilters.fromJson(
    json['interpretedFilters'] as Map<String, dynamic>,
  ),
  nlpKeywords:
      (json['nlpKeywords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$SearchInterpretationImplToJson(
  _$SearchInterpretationImpl instance,
) => <String, dynamic>{
  'originalQuery': instance.originalQuery,
  'interpretedFilters': instance.interpretedFilters,
  'nlpKeywords': instance.nlpKeywords,
  'confidence': instance.confidence,
};
