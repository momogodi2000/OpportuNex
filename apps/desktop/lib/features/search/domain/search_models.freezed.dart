// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SearchFilters _$SearchFiltersFromJson(Map<String, dynamic> json) {
  return _SearchFilters.fromJson(json);
}

/// @nodoc
mixin _$SearchFilters {
  String? get keywords => throw _privateConstructorUsedError;
  List<String> get categories => throw _privateConstructorUsedError;
  List<String> get countries => throw _privateConstructorUsedError;
  double? get amountMin => throw _privateConstructorUsedError;
  double? get amountMax => throw _privateConstructorUsedError;
  String? get currencyCode => throw _privateConstructorUsedError;
  DateTime? get deadline => throw _privateConstructorUsedError;
  List<String> get languages => throw _privateConstructorUsedError;
  List<String> get sourceIds => throw _privateConstructorUsedError;
  bool get remoteOnly => throw _privateConstructorUsedError;
  String get sortBy => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;

  /// Serializes this SearchFilters to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchFilters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchFiltersCopyWith<SearchFilters> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchFiltersCopyWith<$Res> {
  factory $SearchFiltersCopyWith(
    SearchFilters value,
    $Res Function(SearchFilters) then,
  ) = _$SearchFiltersCopyWithImpl<$Res, SearchFilters>;
  @useResult
  $Res call({
    String? keywords,
    List<String> categories,
    List<String> countries,
    double? amountMin,
    double? amountMax,
    String? currencyCode,
    DateTime? deadline,
    List<String> languages,
    List<String> sourceIds,
    bool remoteOnly,
    String sortBy,
    int page,
  });
}

/// @nodoc
class _$SearchFiltersCopyWithImpl<$Res, $Val extends SearchFilters>
    implements $SearchFiltersCopyWith<$Res> {
  _$SearchFiltersCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchFilters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keywords = freezed,
    Object? categories = null,
    Object? countries = null,
    Object? amountMin = freezed,
    Object? amountMax = freezed,
    Object? currencyCode = freezed,
    Object? deadline = freezed,
    Object? languages = null,
    Object? sourceIds = null,
    Object? remoteOnly = null,
    Object? sortBy = null,
    Object? page = null,
  }) {
    return _then(
      _value.copyWith(
            keywords: freezed == keywords
                ? _value.keywords
                : keywords // ignore: cast_nullable_to_non_nullable
                      as String?,
            categories: null == categories
                ? _value.categories
                : categories // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            countries: null == countries
                ? _value.countries
                : countries // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            amountMin: freezed == amountMin
                ? _value.amountMin
                : amountMin // ignore: cast_nullable_to_non_nullable
                      as double?,
            amountMax: freezed == amountMax
                ? _value.amountMax
                : amountMax // ignore: cast_nullable_to_non_nullable
                      as double?,
            currencyCode: freezed == currencyCode
                ? _value.currencyCode
                : currencyCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            deadline: freezed == deadline
                ? _value.deadline
                : deadline // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            languages: null == languages
                ? _value.languages
                : languages // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            sourceIds: null == sourceIds
                ? _value.sourceIds
                : sourceIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            remoteOnly: null == remoteOnly
                ? _value.remoteOnly
                : remoteOnly // ignore: cast_nullable_to_non_nullable
                      as bool,
            sortBy: null == sortBy
                ? _value.sortBy
                : sortBy // ignore: cast_nullable_to_non_nullable
                      as String,
            page: null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SearchFiltersImplCopyWith<$Res>
    implements $SearchFiltersCopyWith<$Res> {
  factory _$$SearchFiltersImplCopyWith(
    _$SearchFiltersImpl value,
    $Res Function(_$SearchFiltersImpl) then,
  ) = __$$SearchFiltersImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? keywords,
    List<String> categories,
    List<String> countries,
    double? amountMin,
    double? amountMax,
    String? currencyCode,
    DateTime? deadline,
    List<String> languages,
    List<String> sourceIds,
    bool remoteOnly,
    String sortBy,
    int page,
  });
}

/// @nodoc
class __$$SearchFiltersImplCopyWithImpl<$Res>
    extends _$SearchFiltersCopyWithImpl<$Res, _$SearchFiltersImpl>
    implements _$$SearchFiltersImplCopyWith<$Res> {
  __$$SearchFiltersImplCopyWithImpl(
    _$SearchFiltersImpl _value,
    $Res Function(_$SearchFiltersImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchFilters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keywords = freezed,
    Object? categories = null,
    Object? countries = null,
    Object? amountMin = freezed,
    Object? amountMax = freezed,
    Object? currencyCode = freezed,
    Object? deadline = freezed,
    Object? languages = null,
    Object? sourceIds = null,
    Object? remoteOnly = null,
    Object? sortBy = null,
    Object? page = null,
  }) {
    return _then(
      _$SearchFiltersImpl(
        keywords: freezed == keywords
            ? _value.keywords
            : keywords // ignore: cast_nullable_to_non_nullable
                  as String?,
        categories: null == categories
            ? _value._categories
            : categories // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        countries: null == countries
            ? _value._countries
            : countries // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        amountMin: freezed == amountMin
            ? _value.amountMin
            : amountMin // ignore: cast_nullable_to_non_nullable
                  as double?,
        amountMax: freezed == amountMax
            ? _value.amountMax
            : amountMax // ignore: cast_nullable_to_non_nullable
                  as double?,
        currencyCode: freezed == currencyCode
            ? _value.currencyCode
            : currencyCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        deadline: freezed == deadline
            ? _value.deadline
            : deadline // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        languages: null == languages
            ? _value._languages
            : languages // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        sourceIds: null == sourceIds
            ? _value._sourceIds
            : sourceIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        remoteOnly: null == remoteOnly
            ? _value.remoteOnly
            : remoteOnly // ignore: cast_nullable_to_non_nullable
                  as bool,
        sortBy: null == sortBy
            ? _value.sortBy
            : sortBy // ignore: cast_nullable_to_non_nullable
                  as String,
        page: null == page
            ? _value.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SearchFiltersImpl implements _SearchFilters {
  const _$SearchFiltersImpl({
    this.keywords,
    final List<String> categories = const [],
    final List<String> countries = const [],
    this.amountMin,
    this.amountMax,
    this.currencyCode,
    this.deadline,
    final List<String> languages = const [],
    final List<String> sourceIds = const [],
    this.remoteOnly = false,
    this.sortBy = 'relevance',
    this.page = 1,
  }) : _categories = categories,
       _countries = countries,
       _languages = languages,
       _sourceIds = sourceIds;

  factory _$SearchFiltersImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchFiltersImplFromJson(json);

  @override
  final String? keywords;
  final List<String> _categories;
  @override
  @JsonKey()
  List<String> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  final List<String> _countries;
  @override
  @JsonKey()
  List<String> get countries {
    if (_countries is EqualUnmodifiableListView) return _countries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_countries);
  }

  @override
  final double? amountMin;
  @override
  final double? amountMax;
  @override
  final String? currencyCode;
  @override
  final DateTime? deadline;
  final List<String> _languages;
  @override
  @JsonKey()
  List<String> get languages {
    if (_languages is EqualUnmodifiableListView) return _languages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_languages);
  }

  final List<String> _sourceIds;
  @override
  @JsonKey()
  List<String> get sourceIds {
    if (_sourceIds is EqualUnmodifiableListView) return _sourceIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sourceIds);
  }

  @override
  @JsonKey()
  final bool remoteOnly;
  @override
  @JsonKey()
  final String sortBy;
  @override
  @JsonKey()
  final int page;

  @override
  String toString() {
    return 'SearchFilters(keywords: $keywords, categories: $categories, countries: $countries, amountMin: $amountMin, amountMax: $amountMax, currencyCode: $currencyCode, deadline: $deadline, languages: $languages, sourceIds: $sourceIds, remoteOnly: $remoteOnly, sortBy: $sortBy, page: $page)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchFiltersImpl &&
            (identical(other.keywords, keywords) ||
                other.keywords == keywords) &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ) &&
            const DeepCollectionEquality().equals(
              other._countries,
              _countries,
            ) &&
            (identical(other.amountMin, amountMin) ||
                other.amountMin == amountMin) &&
            (identical(other.amountMax, amountMax) ||
                other.amountMax == amountMax) &&
            (identical(other.currencyCode, currencyCode) ||
                other.currencyCode == currencyCode) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            const DeepCollectionEquality().equals(
              other._languages,
              _languages,
            ) &&
            const DeepCollectionEquality().equals(
              other._sourceIds,
              _sourceIds,
            ) &&
            (identical(other.remoteOnly, remoteOnly) ||
                other.remoteOnly == remoteOnly) &&
            (identical(other.sortBy, sortBy) || other.sortBy == sortBy) &&
            (identical(other.page, page) || other.page == page));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    keywords,
    const DeepCollectionEquality().hash(_categories),
    const DeepCollectionEquality().hash(_countries),
    amountMin,
    amountMax,
    currencyCode,
    deadline,
    const DeepCollectionEquality().hash(_languages),
    const DeepCollectionEquality().hash(_sourceIds),
    remoteOnly,
    sortBy,
    page,
  );

  /// Create a copy of SearchFilters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchFiltersImplCopyWith<_$SearchFiltersImpl> get copyWith =>
      __$$SearchFiltersImplCopyWithImpl<_$SearchFiltersImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchFiltersImplToJson(this);
  }
}

abstract class _SearchFilters implements SearchFilters {
  const factory _SearchFilters({
    final String? keywords,
    final List<String> categories,
    final List<String> countries,
    final double? amountMin,
    final double? amountMax,
    final String? currencyCode,
    final DateTime? deadline,
    final List<String> languages,
    final List<String> sourceIds,
    final bool remoteOnly,
    final String sortBy,
    final int page,
  }) = _$SearchFiltersImpl;

  factory _SearchFilters.fromJson(Map<String, dynamic> json) =
      _$SearchFiltersImpl.fromJson;

  @override
  String? get keywords;
  @override
  List<String> get categories;
  @override
  List<String> get countries;
  @override
  double? get amountMin;
  @override
  double? get amountMax;
  @override
  String? get currencyCode;
  @override
  DateTime? get deadline;
  @override
  List<String> get languages;
  @override
  List<String> get sourceIds;
  @override
  bool get remoteOnly;
  @override
  String get sortBy;
  @override
  int get page;

  /// Create a copy of SearchFilters
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchFiltersImplCopyWith<_$SearchFiltersImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SearchResult _$SearchResultFromJson(Map<String, dynamic> json) {
  return _SearchResult.fromJson(json);
}

/// @nodoc
mixin _$SearchResult {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get organization => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  double get score => throw _privateConstructorUsedError;
  DateTime? get deadline => throw _privateConstructorUsedError;
  String get location => throw _privateConstructorUsedError;
  String get provenanceDeadline => throw _privateConstructorUsedError;
  bool get isNew => throw _privateConstructorUsedError;
  bool get isSaved => throw _privateConstructorUsedError;

  /// Serializes this SearchResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchResultCopyWith<SearchResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchResultCopyWith<$Res> {
  factory $SearchResultCopyWith(
    SearchResult value,
    $Res Function(SearchResult) then,
  ) = _$SearchResultCopyWithImpl<$Res, SearchResult>;
  @useResult
  $Res call({
    String id,
    String title,
    String organization,
    String category,
    double score,
    DateTime? deadline,
    String location,
    String provenanceDeadline,
    bool isNew,
    bool isSaved,
  });
}

/// @nodoc
class _$SearchResultCopyWithImpl<$Res, $Val extends SearchResult>
    implements $SearchResultCopyWith<$Res> {
  _$SearchResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? organization = null,
    Object? category = null,
    Object? score = null,
    Object? deadline = freezed,
    Object? location = null,
    Object? provenanceDeadline = null,
    Object? isNew = null,
    Object? isSaved = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            organization: null == organization
                ? _value.organization
                : organization // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as double,
            deadline: freezed == deadline
                ? _value.deadline
                : deadline // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            location: null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String,
            provenanceDeadline: null == provenanceDeadline
                ? _value.provenanceDeadline
                : provenanceDeadline // ignore: cast_nullable_to_non_nullable
                      as String,
            isNew: null == isNew
                ? _value.isNew
                : isNew // ignore: cast_nullable_to_non_nullable
                      as bool,
            isSaved: null == isSaved
                ? _value.isSaved
                : isSaved // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SearchResultImplCopyWith<$Res>
    implements $SearchResultCopyWith<$Res> {
  factory _$$SearchResultImplCopyWith(
    _$SearchResultImpl value,
    $Res Function(_$SearchResultImpl) then,
  ) = __$$SearchResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String organization,
    String category,
    double score,
    DateTime? deadline,
    String location,
    String provenanceDeadline,
    bool isNew,
    bool isSaved,
  });
}

/// @nodoc
class __$$SearchResultImplCopyWithImpl<$Res>
    extends _$SearchResultCopyWithImpl<$Res, _$SearchResultImpl>
    implements _$$SearchResultImplCopyWith<$Res> {
  __$$SearchResultImplCopyWithImpl(
    _$SearchResultImpl _value,
    $Res Function(_$SearchResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? organization = null,
    Object? category = null,
    Object? score = null,
    Object? deadline = freezed,
    Object? location = null,
    Object? provenanceDeadline = null,
    Object? isNew = null,
    Object? isSaved = null,
  }) {
    return _then(
      _$SearchResultImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        organization: null == organization
            ? _value.organization
            : organization // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as double,
        deadline: freezed == deadline
            ? _value.deadline
            : deadline // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        location: null == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String,
        provenanceDeadline: null == provenanceDeadline
            ? _value.provenanceDeadline
            : provenanceDeadline // ignore: cast_nullable_to_non_nullable
                  as String,
        isNew: null == isNew
            ? _value.isNew
            : isNew // ignore: cast_nullable_to_non_nullable
                  as bool,
        isSaved: null == isSaved
            ? _value.isSaved
            : isSaved // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SearchResultImpl implements _SearchResult {
  const _$SearchResultImpl({
    required this.id,
    required this.title,
    required this.organization,
    required this.category,
    required this.score,
    this.deadline,
    required this.location,
    required this.provenanceDeadline,
    this.isNew = false,
    this.isSaved = false,
  });

  factory _$SearchResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchResultImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String organization;
  @override
  final String category;
  @override
  final double score;
  @override
  final DateTime? deadline;
  @override
  final String location;
  @override
  final String provenanceDeadline;
  @override
  @JsonKey()
  final bool isNew;
  @override
  @JsonKey()
  final bool isSaved;

  @override
  String toString() {
    return 'SearchResult(id: $id, title: $title, organization: $organization, category: $category, score: $score, deadline: $deadline, location: $location, provenanceDeadline: $provenanceDeadline, isNew: $isNew, isSaved: $isSaved)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchResultImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.organization, organization) ||
                other.organization == organization) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.provenanceDeadline, provenanceDeadline) ||
                other.provenanceDeadline == provenanceDeadline) &&
            (identical(other.isNew, isNew) || other.isNew == isNew) &&
            (identical(other.isSaved, isSaved) || other.isSaved == isSaved));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    organization,
    category,
    score,
    deadline,
    location,
    provenanceDeadline,
    isNew,
    isSaved,
  );

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchResultImplCopyWith<_$SearchResultImpl> get copyWith =>
      __$$SearchResultImplCopyWithImpl<_$SearchResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchResultImplToJson(this);
  }
}

abstract class _SearchResult implements SearchResult {
  const factory _SearchResult({
    required final String id,
    required final String title,
    required final String organization,
    required final String category,
    required final double score,
    final DateTime? deadline,
    required final String location,
    required final String provenanceDeadline,
    final bool isNew,
    final bool isSaved,
  }) = _$SearchResultImpl;

  factory _SearchResult.fromJson(Map<String, dynamic> json) =
      _$SearchResultImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get organization;
  @override
  String get category;
  @override
  double get score;
  @override
  DateTime? get deadline;
  @override
  String get location;
  @override
  String get provenanceDeadline;
  @override
  bool get isNew;
  @override
  bool get isSaved;

  /// Create a copy of SearchResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchResultImplCopyWith<_$SearchResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SearchResultPage _$SearchResultPageFromJson(Map<String, dynamic> json) {
  return _SearchResultPage.fromJson(json);
}

/// @nodoc
mixin _$SearchResultPage {
  List<SearchResult> get items => throw _privateConstructorUsedError;
  String? get cursor => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;
  int get totalEstimate => throw _privateConstructorUsedError;
  String? get searchRunId => throw _privateConstructorUsedError;

  /// Serializes this SearchResultPage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchResultPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchResultPageCopyWith<SearchResultPage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchResultPageCopyWith<$Res> {
  factory $SearchResultPageCopyWith(
    SearchResultPage value,
    $Res Function(SearchResultPage) then,
  ) = _$SearchResultPageCopyWithImpl<$Res, SearchResultPage>;
  @useResult
  $Res call({
    List<SearchResult> items,
    String? cursor,
    bool hasMore,
    int totalEstimate,
    String? searchRunId,
  });
}

/// @nodoc
class _$SearchResultPageCopyWithImpl<$Res, $Val extends SearchResultPage>
    implements $SearchResultPageCopyWith<$Res> {
  _$SearchResultPageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchResultPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? cursor = freezed,
    Object? hasMore = null,
    Object? totalEstimate = null,
    Object? searchRunId = freezed,
  }) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<SearchResult>,
            cursor: freezed == cursor
                ? _value.cursor
                : cursor // ignore: cast_nullable_to_non_nullable
                      as String?,
            hasMore: null == hasMore
                ? _value.hasMore
                : hasMore // ignore: cast_nullable_to_non_nullable
                      as bool,
            totalEstimate: null == totalEstimate
                ? _value.totalEstimate
                : totalEstimate // ignore: cast_nullable_to_non_nullable
                      as int,
            searchRunId: freezed == searchRunId
                ? _value.searchRunId
                : searchRunId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SearchResultPageImplCopyWith<$Res>
    implements $SearchResultPageCopyWith<$Res> {
  factory _$$SearchResultPageImplCopyWith(
    _$SearchResultPageImpl value,
    $Res Function(_$SearchResultPageImpl) then,
  ) = __$$SearchResultPageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<SearchResult> items,
    String? cursor,
    bool hasMore,
    int totalEstimate,
    String? searchRunId,
  });
}

/// @nodoc
class __$$SearchResultPageImplCopyWithImpl<$Res>
    extends _$SearchResultPageCopyWithImpl<$Res, _$SearchResultPageImpl>
    implements _$$SearchResultPageImplCopyWith<$Res> {
  __$$SearchResultPageImplCopyWithImpl(
    _$SearchResultPageImpl _value,
    $Res Function(_$SearchResultPageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchResultPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? cursor = freezed,
    Object? hasMore = null,
    Object? totalEstimate = null,
    Object? searchRunId = freezed,
  }) {
    return _then(
      _$SearchResultPageImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<SearchResult>,
        cursor: freezed == cursor
            ? _value.cursor
            : cursor // ignore: cast_nullable_to_non_nullable
                  as String?,
        hasMore: null == hasMore
            ? _value.hasMore
            : hasMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        totalEstimate: null == totalEstimate
            ? _value.totalEstimate
            : totalEstimate // ignore: cast_nullable_to_non_nullable
                  as int,
        searchRunId: freezed == searchRunId
            ? _value.searchRunId
            : searchRunId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SearchResultPageImpl implements _SearchResultPage {
  const _$SearchResultPageImpl({
    final List<SearchResult> items = const [],
    this.cursor,
    this.hasMore = false,
    this.totalEstimate = 0,
    this.searchRunId,
  }) : _items = items;

  factory _$SearchResultPageImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchResultPageImplFromJson(json);

  final List<SearchResult> _items;
  @override
  @JsonKey()
  List<SearchResult> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final String? cursor;
  @override
  @JsonKey()
  final bool hasMore;
  @override
  @JsonKey()
  final int totalEstimate;
  @override
  final String? searchRunId;

  @override
  String toString() {
    return 'SearchResultPage(items: $items, cursor: $cursor, hasMore: $hasMore, totalEstimate: $totalEstimate, searchRunId: $searchRunId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchResultPageImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.cursor, cursor) || other.cursor == cursor) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.totalEstimate, totalEstimate) ||
                other.totalEstimate == totalEstimate) &&
            (identical(other.searchRunId, searchRunId) ||
                other.searchRunId == searchRunId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    cursor,
    hasMore,
    totalEstimate,
    searchRunId,
  );

  /// Create a copy of SearchResultPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchResultPageImplCopyWith<_$SearchResultPageImpl> get copyWith =>
      __$$SearchResultPageImplCopyWithImpl<_$SearchResultPageImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchResultPageImplToJson(this);
  }
}

abstract class _SearchResultPage implements SearchResultPage {
  const factory _SearchResultPage({
    final List<SearchResult> items,
    final String? cursor,
    final bool hasMore,
    final int totalEstimate,
    final String? searchRunId,
  }) = _$SearchResultPageImpl;

  factory _SearchResultPage.fromJson(Map<String, dynamic> json) =
      _$SearchResultPageImpl.fromJson;

  @override
  List<SearchResult> get items;
  @override
  String? get cursor;
  @override
  bool get hasMore;
  @override
  int get totalEstimate;
  @override
  String? get searchRunId;

  /// Create a copy of SearchResultPage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchResultPageImplCopyWith<_$SearchResultPageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SearchInterpretation _$SearchInterpretationFromJson(Map<String, dynamic> json) {
  return _SearchInterpretation.fromJson(json);
}

/// @nodoc
mixin _$SearchInterpretation {
  String get originalQuery => throw _privateConstructorUsedError;
  SearchFilters get interpretedFilters => throw _privateConstructorUsedError;
  List<String> get nlpKeywords => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;

  /// Serializes this SearchInterpretation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SearchInterpretation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchInterpretationCopyWith<SearchInterpretation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchInterpretationCopyWith<$Res> {
  factory $SearchInterpretationCopyWith(
    SearchInterpretation value,
    $Res Function(SearchInterpretation) then,
  ) = _$SearchInterpretationCopyWithImpl<$Res, SearchInterpretation>;
  @useResult
  $Res call({
    String originalQuery,
    SearchFilters interpretedFilters,
    List<String> nlpKeywords,
    double confidence,
  });

  $SearchFiltersCopyWith<$Res> get interpretedFilters;
}

/// @nodoc
class _$SearchInterpretationCopyWithImpl<
  $Res,
  $Val extends SearchInterpretation
>
    implements $SearchInterpretationCopyWith<$Res> {
  _$SearchInterpretationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchInterpretation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalQuery = null,
    Object? interpretedFilters = null,
    Object? nlpKeywords = null,
    Object? confidence = null,
  }) {
    return _then(
      _value.copyWith(
            originalQuery: null == originalQuery
                ? _value.originalQuery
                : originalQuery // ignore: cast_nullable_to_non_nullable
                      as String,
            interpretedFilters: null == interpretedFilters
                ? _value.interpretedFilters
                : interpretedFilters // ignore: cast_nullable_to_non_nullable
                      as SearchFilters,
            nlpKeywords: null == nlpKeywords
                ? _value.nlpKeywords
                : nlpKeywords // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }

  /// Create a copy of SearchInterpretation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SearchFiltersCopyWith<$Res> get interpretedFilters {
    return $SearchFiltersCopyWith<$Res>(_value.interpretedFilters, (value) {
      return _then(_value.copyWith(interpretedFilters: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SearchInterpretationImplCopyWith<$Res>
    implements $SearchInterpretationCopyWith<$Res> {
  factory _$$SearchInterpretationImplCopyWith(
    _$SearchInterpretationImpl value,
    $Res Function(_$SearchInterpretationImpl) then,
  ) = __$$SearchInterpretationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String originalQuery,
    SearchFilters interpretedFilters,
    List<String> nlpKeywords,
    double confidence,
  });

  @override
  $SearchFiltersCopyWith<$Res> get interpretedFilters;
}

/// @nodoc
class __$$SearchInterpretationImplCopyWithImpl<$Res>
    extends _$SearchInterpretationCopyWithImpl<$Res, _$SearchInterpretationImpl>
    implements _$$SearchInterpretationImplCopyWith<$Res> {
  __$$SearchInterpretationImplCopyWithImpl(
    _$SearchInterpretationImpl _value,
    $Res Function(_$SearchInterpretationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchInterpretation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalQuery = null,
    Object? interpretedFilters = null,
    Object? nlpKeywords = null,
    Object? confidence = null,
  }) {
    return _then(
      _$SearchInterpretationImpl(
        originalQuery: null == originalQuery
            ? _value.originalQuery
            : originalQuery // ignore: cast_nullable_to_non_nullable
                  as String,
        interpretedFilters: null == interpretedFilters
            ? _value.interpretedFilters
            : interpretedFilters // ignore: cast_nullable_to_non_nullable
                  as SearchFilters,
        nlpKeywords: null == nlpKeywords
            ? _value._nlpKeywords
            : nlpKeywords // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SearchInterpretationImpl implements _SearchInterpretation {
  const _$SearchInterpretationImpl({
    required this.originalQuery,
    required this.interpretedFilters,
    final List<String> nlpKeywords = const [],
    this.confidence = 0.0,
  }) : _nlpKeywords = nlpKeywords;

  factory _$SearchInterpretationImpl.fromJson(Map<String, dynamic> json) =>
      _$$SearchInterpretationImplFromJson(json);

  @override
  final String originalQuery;
  @override
  final SearchFilters interpretedFilters;
  final List<String> _nlpKeywords;
  @override
  @JsonKey()
  List<String> get nlpKeywords {
    if (_nlpKeywords is EqualUnmodifiableListView) return _nlpKeywords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nlpKeywords);
  }

  @override
  @JsonKey()
  final double confidence;

  @override
  String toString() {
    return 'SearchInterpretation(originalQuery: $originalQuery, interpretedFilters: $interpretedFilters, nlpKeywords: $nlpKeywords, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchInterpretationImpl &&
            (identical(other.originalQuery, originalQuery) ||
                other.originalQuery == originalQuery) &&
            (identical(other.interpretedFilters, interpretedFilters) ||
                other.interpretedFilters == interpretedFilters) &&
            const DeepCollectionEquality().equals(
              other._nlpKeywords,
              _nlpKeywords,
            ) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    originalQuery,
    interpretedFilters,
    const DeepCollectionEquality().hash(_nlpKeywords),
    confidence,
  );

  /// Create a copy of SearchInterpretation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchInterpretationImplCopyWith<_$SearchInterpretationImpl>
  get copyWith =>
      __$$SearchInterpretationImplCopyWithImpl<_$SearchInterpretationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SearchInterpretationImplToJson(this);
  }
}

abstract class _SearchInterpretation implements SearchInterpretation {
  const factory _SearchInterpretation({
    required final String originalQuery,
    required final SearchFilters interpretedFilters,
    final List<String> nlpKeywords,
    final double confidence,
  }) = _$SearchInterpretationImpl;

  factory _SearchInterpretation.fromJson(Map<String, dynamic> json) =
      _$SearchInterpretationImpl.fromJson;

  @override
  String get originalQuery;
  @override
  SearchFilters get interpretedFilters;
  @override
  List<String> get nlpKeywords;
  @override
  double get confidence;

  /// Create a copy of SearchInterpretation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchInterpretationImplCopyWith<_$SearchInterpretationImpl>
  get copyWith => throw _privateConstructorUsedError;
}
