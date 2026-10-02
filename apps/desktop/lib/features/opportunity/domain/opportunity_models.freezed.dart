// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'opportunity_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ProvenancedField<T> _$ProvenancedFieldFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object?) fromJsonT,
) {
  return _ProvenancedField<T>.fromJson(json, fromJsonT);
}

/// @nodoc
mixin _$ProvenancedField<T> {
  T get value => throw _privateConstructorUsedError;
  ProvenanceTag get provenance => throw _privateConstructorUsedError;
  String? get excerpt => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;

  /// Serializes this ProvenancedField to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      throw _privateConstructorUsedError;

  /// Create a copy of ProvenancedField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProvenancedFieldCopyWith<T, ProvenancedField<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProvenancedFieldCopyWith<T, $Res> {
  factory $ProvenancedFieldCopyWith(
    ProvenancedField<T> value,
    $Res Function(ProvenancedField<T>) then,
  ) = _$ProvenancedFieldCopyWithImpl<T, $Res, ProvenancedField<T>>;
  @useResult
  $Res call({
    T value,
    ProvenanceTag provenance,
    String? excerpt,
    double confidence,
  });
}

/// @nodoc
class _$ProvenancedFieldCopyWithImpl<T, $Res, $Val extends ProvenancedField<T>>
    implements $ProvenancedFieldCopyWith<T, $Res> {
  _$ProvenancedFieldCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProvenancedField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = freezed,
    Object? provenance = null,
    Object? excerpt = freezed,
    Object? confidence = null,
  }) {
    return _then(
      _value.copyWith(
            value: freezed == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as T,
            provenance: null == provenance
                ? _value.provenance
                : provenance // ignore: cast_nullable_to_non_nullable
                      as ProvenanceTag,
            excerpt: freezed == excerpt
                ? _value.excerpt
                : excerpt // ignore: cast_nullable_to_non_nullable
                      as String?,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProvenancedFieldImplCopyWith<T, $Res>
    implements $ProvenancedFieldCopyWith<T, $Res> {
  factory _$$ProvenancedFieldImplCopyWith(
    _$ProvenancedFieldImpl<T> value,
    $Res Function(_$ProvenancedFieldImpl<T>) then,
  ) = __$$ProvenancedFieldImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({
    T value,
    ProvenanceTag provenance,
    String? excerpt,
    double confidence,
  });
}

/// @nodoc
class __$$ProvenancedFieldImplCopyWithImpl<T, $Res>
    extends _$ProvenancedFieldCopyWithImpl<T, $Res, _$ProvenancedFieldImpl<T>>
    implements _$$ProvenancedFieldImplCopyWith<T, $Res> {
  __$$ProvenancedFieldImplCopyWithImpl(
    _$ProvenancedFieldImpl<T> _value,
    $Res Function(_$ProvenancedFieldImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of ProvenancedField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = freezed,
    Object? provenance = null,
    Object? excerpt = freezed,
    Object? confidence = null,
  }) {
    return _then(
      _$ProvenancedFieldImpl<T>(
        value: freezed == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as T,
        provenance: null == provenance
            ? _value.provenance
            : provenance // ignore: cast_nullable_to_non_nullable
                  as ProvenanceTag,
        excerpt: freezed == excerpt
            ? _value.excerpt
            : excerpt // ignore: cast_nullable_to_non_nullable
                  as String?,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)
class _$ProvenancedFieldImpl<T> implements _ProvenancedField<T> {
  const _$ProvenancedFieldImpl({
    required this.value,
    this.provenance = ProvenanceTag.notSpecified,
    this.excerpt,
    this.confidence = 0.0,
  });

  factory _$ProvenancedFieldImpl.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$$ProvenancedFieldImplFromJson(json, fromJsonT);

  @override
  final T value;
  @override
  @JsonKey()
  final ProvenanceTag provenance;
  @override
  final String? excerpt;
  @override
  @JsonKey()
  final double confidence;

  @override
  String toString() {
    return 'ProvenancedField<$T>(value: $value, provenance: $provenance, excerpt: $excerpt, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProvenancedFieldImpl<T> &&
            const DeepCollectionEquality().equals(other.value, value) &&
            (identical(other.provenance, provenance) ||
                other.provenance == provenance) &&
            (identical(other.excerpt, excerpt) || other.excerpt == excerpt) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(value),
    provenance,
    excerpt,
    confidence,
  );

  /// Create a copy of ProvenancedField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProvenancedFieldImplCopyWith<T, _$ProvenancedFieldImpl<T>> get copyWith =>
      __$$ProvenancedFieldImplCopyWithImpl<T, _$ProvenancedFieldImpl<T>>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return _$$ProvenancedFieldImplToJson<T>(this, toJsonT);
  }
}

abstract class _ProvenancedField<T> implements ProvenancedField<T> {
  const factory _ProvenancedField({
    required final T value,
    final ProvenanceTag provenance,
    final String? excerpt,
    final double confidence,
  }) = _$ProvenancedFieldImpl<T>;

  factory _ProvenancedField.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) = _$ProvenancedFieldImpl<T>.fromJson;

  @override
  T get value;
  @override
  ProvenanceTag get provenance;
  @override
  String? get excerpt;
  @override
  double get confidence;

  /// Create a copy of ProvenancedField
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProvenancedFieldImplCopyWith<T, _$ProvenancedFieldImpl<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

OpportunityListItem _$OpportunityListItemFromJson(Map<String, dynamic> json) {
  return _OpportunityListItem.fromJson(json);
}

/// @nodoc
mixin _$OpportunityListItem {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get organization => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  DateTime get deadlineIso => throw _privateConstructorUsedError;
  String get location => throw _privateConstructorUsedError;
  String get countryCode => throw _privateConstructorUsedError;
  int? get matchScore => throw _privateConstructorUsedError;
  ProvenanceTag get provenanceDeadline => throw _privateConstructorUsedError;
  bool get isSaved => throw _privateConstructorUsedError;
  bool get isNew => throw _privateConstructorUsedError;
  String? get currencyCode => throw _privateConstructorUsedError;
  double? get amountMin => throw _privateConstructorUsedError;
  double? get amountMax => throw _privateConstructorUsedError;
  int get sourceCount => throw _privateConstructorUsedError;
  DateTime get collectedAt => throw _privateConstructorUsedError;

  /// Serializes this OpportunityListItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OpportunityListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OpportunityListItemCopyWith<OpportunityListItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OpportunityListItemCopyWith<$Res> {
  factory $OpportunityListItemCopyWith(
    OpportunityListItem value,
    $Res Function(OpportunityListItem) then,
  ) = _$OpportunityListItemCopyWithImpl<$Res, OpportunityListItem>;
  @useResult
  $Res call({
    String id,
    String title,
    String organization,
    String categoryId,
    DateTime deadlineIso,
    String location,
    String countryCode,
    int? matchScore,
    ProvenanceTag provenanceDeadline,
    bool isSaved,
    bool isNew,
    String? currencyCode,
    double? amountMin,
    double? amountMax,
    int sourceCount,
    DateTime collectedAt,
  });
}

/// @nodoc
class _$OpportunityListItemCopyWithImpl<$Res, $Val extends OpportunityListItem>
    implements $OpportunityListItemCopyWith<$Res> {
  _$OpportunityListItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OpportunityListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? organization = null,
    Object? categoryId = null,
    Object? deadlineIso = null,
    Object? location = null,
    Object? countryCode = null,
    Object? matchScore = freezed,
    Object? provenanceDeadline = null,
    Object? isSaved = null,
    Object? isNew = null,
    Object? currencyCode = freezed,
    Object? amountMin = freezed,
    Object? amountMax = freezed,
    Object? sourceCount = null,
    Object? collectedAt = null,
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
            categoryId: null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String,
            deadlineIso: null == deadlineIso
                ? _value.deadlineIso
                : deadlineIso // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            location: null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String,
            countryCode: null == countryCode
                ? _value.countryCode
                : countryCode // ignore: cast_nullable_to_non_nullable
                      as String,
            matchScore: freezed == matchScore
                ? _value.matchScore
                : matchScore // ignore: cast_nullable_to_non_nullable
                      as int?,
            provenanceDeadline: null == provenanceDeadline
                ? _value.provenanceDeadline
                : provenanceDeadline // ignore: cast_nullable_to_non_nullable
                      as ProvenanceTag,
            isSaved: null == isSaved
                ? _value.isSaved
                : isSaved // ignore: cast_nullable_to_non_nullable
                      as bool,
            isNew: null == isNew
                ? _value.isNew
                : isNew // ignore: cast_nullable_to_non_nullable
                      as bool,
            currencyCode: freezed == currencyCode
                ? _value.currencyCode
                : currencyCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            amountMin: freezed == amountMin
                ? _value.amountMin
                : amountMin // ignore: cast_nullable_to_non_nullable
                      as double?,
            amountMax: freezed == amountMax
                ? _value.amountMax
                : amountMax // ignore: cast_nullable_to_non_nullable
                      as double?,
            sourceCount: null == sourceCount
                ? _value.sourceCount
                : sourceCount // ignore: cast_nullable_to_non_nullable
                      as int,
            collectedAt: null == collectedAt
                ? _value.collectedAt
                : collectedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OpportunityListItemImplCopyWith<$Res>
    implements $OpportunityListItemCopyWith<$Res> {
  factory _$$OpportunityListItemImplCopyWith(
    _$OpportunityListItemImpl value,
    $Res Function(_$OpportunityListItemImpl) then,
  ) = __$$OpportunityListItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String organization,
    String categoryId,
    DateTime deadlineIso,
    String location,
    String countryCode,
    int? matchScore,
    ProvenanceTag provenanceDeadline,
    bool isSaved,
    bool isNew,
    String? currencyCode,
    double? amountMin,
    double? amountMax,
    int sourceCount,
    DateTime collectedAt,
  });
}

/// @nodoc
class __$$OpportunityListItemImplCopyWithImpl<$Res>
    extends _$OpportunityListItemCopyWithImpl<$Res, _$OpportunityListItemImpl>
    implements _$$OpportunityListItemImplCopyWith<$Res> {
  __$$OpportunityListItemImplCopyWithImpl(
    _$OpportunityListItemImpl _value,
    $Res Function(_$OpportunityListItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OpportunityListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? organization = null,
    Object? categoryId = null,
    Object? deadlineIso = null,
    Object? location = null,
    Object? countryCode = null,
    Object? matchScore = freezed,
    Object? provenanceDeadline = null,
    Object? isSaved = null,
    Object? isNew = null,
    Object? currencyCode = freezed,
    Object? amountMin = freezed,
    Object? amountMax = freezed,
    Object? sourceCount = null,
    Object? collectedAt = null,
  }) {
    return _then(
      _$OpportunityListItemImpl(
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
        categoryId: null == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        deadlineIso: null == deadlineIso
            ? _value.deadlineIso
            : deadlineIso // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        location: null == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String,
        countryCode: null == countryCode
            ? _value.countryCode
            : countryCode // ignore: cast_nullable_to_non_nullable
                  as String,
        matchScore: freezed == matchScore
            ? _value.matchScore
            : matchScore // ignore: cast_nullable_to_non_nullable
                  as int?,
        provenanceDeadline: null == provenanceDeadline
            ? _value.provenanceDeadline
            : provenanceDeadline // ignore: cast_nullable_to_non_nullable
                  as ProvenanceTag,
        isSaved: null == isSaved
            ? _value.isSaved
            : isSaved // ignore: cast_nullable_to_non_nullable
                  as bool,
        isNew: null == isNew
            ? _value.isNew
            : isNew // ignore: cast_nullable_to_non_nullable
                  as bool,
        currencyCode: freezed == currencyCode
            ? _value.currencyCode
            : currencyCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        amountMin: freezed == amountMin
            ? _value.amountMin
            : amountMin // ignore: cast_nullable_to_non_nullable
                  as double?,
        amountMax: freezed == amountMax
            ? _value.amountMax
            : amountMax // ignore: cast_nullable_to_non_nullable
                  as double?,
        sourceCount: null == sourceCount
            ? _value.sourceCount
            : sourceCount // ignore: cast_nullable_to_non_nullable
                  as int,
        collectedAt: null == collectedAt
            ? _value.collectedAt
            : collectedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OpportunityListItemImpl implements _OpportunityListItem {
  const _$OpportunityListItemImpl({
    required this.id,
    required this.title,
    required this.organization,
    required this.categoryId,
    required this.deadlineIso,
    required this.location,
    required this.countryCode,
    this.matchScore,
    required this.provenanceDeadline,
    this.isSaved = false,
    this.isNew = true,
    this.currencyCode,
    this.amountMin,
    this.amountMax,
    this.sourceCount = 1,
    required this.collectedAt,
  });

  factory _$OpportunityListItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$OpportunityListItemImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String organization;
  @override
  final String categoryId;
  @override
  final DateTime deadlineIso;
  @override
  final String location;
  @override
  final String countryCode;
  @override
  final int? matchScore;
  @override
  final ProvenanceTag provenanceDeadline;
  @override
  @JsonKey()
  final bool isSaved;
  @override
  @JsonKey()
  final bool isNew;
  @override
  final String? currencyCode;
  @override
  final double? amountMin;
  @override
  final double? amountMax;
  @override
  @JsonKey()
  final int sourceCount;
  @override
  final DateTime collectedAt;

  @override
  String toString() {
    return 'OpportunityListItem(id: $id, title: $title, organization: $organization, categoryId: $categoryId, deadlineIso: $deadlineIso, location: $location, countryCode: $countryCode, matchScore: $matchScore, provenanceDeadline: $provenanceDeadline, isSaved: $isSaved, isNew: $isNew, currencyCode: $currencyCode, amountMin: $amountMin, amountMax: $amountMax, sourceCount: $sourceCount, collectedAt: $collectedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OpportunityListItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.organization, organization) ||
                other.organization == organization) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.deadlineIso, deadlineIso) ||
                other.deadlineIso == deadlineIso) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.countryCode, countryCode) ||
                other.countryCode == countryCode) &&
            (identical(other.matchScore, matchScore) ||
                other.matchScore == matchScore) &&
            (identical(other.provenanceDeadline, provenanceDeadline) ||
                other.provenanceDeadline == provenanceDeadline) &&
            (identical(other.isSaved, isSaved) || other.isSaved == isSaved) &&
            (identical(other.isNew, isNew) || other.isNew == isNew) &&
            (identical(other.currencyCode, currencyCode) ||
                other.currencyCode == currencyCode) &&
            (identical(other.amountMin, amountMin) ||
                other.amountMin == amountMin) &&
            (identical(other.amountMax, amountMax) ||
                other.amountMax == amountMax) &&
            (identical(other.sourceCount, sourceCount) ||
                other.sourceCount == sourceCount) &&
            (identical(other.collectedAt, collectedAt) ||
                other.collectedAt == collectedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    organization,
    categoryId,
    deadlineIso,
    location,
    countryCode,
    matchScore,
    provenanceDeadline,
    isSaved,
    isNew,
    currencyCode,
    amountMin,
    amountMax,
    sourceCount,
    collectedAt,
  );

  /// Create a copy of OpportunityListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OpportunityListItemImplCopyWith<_$OpportunityListItemImpl> get copyWith =>
      __$$OpportunityListItemImplCopyWithImpl<_$OpportunityListItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OpportunityListItemImplToJson(this);
  }
}

abstract class _OpportunityListItem implements OpportunityListItem {
  const factory _OpportunityListItem({
    required final String id,
    required final String title,
    required final String organization,
    required final String categoryId,
    required final DateTime deadlineIso,
    required final String location,
    required final String countryCode,
    final int? matchScore,
    required final ProvenanceTag provenanceDeadline,
    final bool isSaved,
    final bool isNew,
    final String? currencyCode,
    final double? amountMin,
    final double? amountMax,
    final int sourceCount,
    required final DateTime collectedAt,
  }) = _$OpportunityListItemImpl;

  factory _OpportunityListItem.fromJson(Map<String, dynamic> json) =
      _$OpportunityListItemImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get organization;
  @override
  String get categoryId;
  @override
  DateTime get deadlineIso;
  @override
  String get location;
  @override
  String get countryCode;
  @override
  int? get matchScore;
  @override
  ProvenanceTag get provenanceDeadline;
  @override
  bool get isSaved;
  @override
  bool get isNew;
  @override
  String? get currencyCode;
  @override
  double? get amountMin;
  @override
  double? get amountMax;
  @override
  int get sourceCount;
  @override
  DateTime get collectedAt;

  /// Create a copy of OpportunityListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OpportunityListItemImplCopyWith<_$OpportunityListItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OpportunityDetail _$OpportunityDetailFromJson(Map<String, dynamic> json) {
  return _OpportunityDetail.fromJson(json);
}

/// @nodoc
mixin _$OpportunityDetail {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get organization => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  DateTime get deadlineIso => throw _privateConstructorUsedError;
  String get location => throw _privateConstructorUsedError;
  String get countryCode => throw _privateConstructorUsedError;
  int? get matchScore => throw _privateConstructorUsedError;
  ProvenanceTag get provenanceDeadline => throw _privateConstructorUsedError;
  bool get isSaved => throw _privateConstructorUsedError;
  bool get isNew => throw _privateConstructorUsedError;
  String? get currencyCode => throw _privateConstructorUsedError;
  double? get amountMin => throw _privateConstructorUsedError;
  double? get amountMax => throw _privateConstructorUsedError;
  int get sourceCount => throw _privateConstructorUsedError;
  DateTime get collectedAt => throw _privateConstructorUsedError;
  String get fullText => throw _privateConstructorUsedError;
  String get summaryAi => throw _privateConstructorUsedError;
  String? get eligibilityVerbatim => throw _privateConstructorUsedError;
  String? get eligibilityAnalysis => throw _privateConstructorUsedError;
  List<OpportunityFieldSummary> get allFields =>
      throw _privateConstructorUsedError;
  List<OpportunityListItem> get relatedOpportunities =>
      throw _privateConstructorUsedError;
  String? get applicationStatus => throw _privateConstructorUsedError;
  String? get userNotes => throw _privateConstructorUsedError;

  /// Serializes this OpportunityDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OpportunityDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OpportunityDetailCopyWith<OpportunityDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OpportunityDetailCopyWith<$Res> {
  factory $OpportunityDetailCopyWith(
    OpportunityDetail value,
    $Res Function(OpportunityDetail) then,
  ) = _$OpportunityDetailCopyWithImpl<$Res, OpportunityDetail>;
  @useResult
  $Res call({
    String id,
    String title,
    String organization,
    String categoryId,
    DateTime deadlineIso,
    String location,
    String countryCode,
    int? matchScore,
    ProvenanceTag provenanceDeadline,
    bool isSaved,
    bool isNew,
    String? currencyCode,
    double? amountMin,
    double? amountMax,
    int sourceCount,
    DateTime collectedAt,
    String fullText,
    String summaryAi,
    String? eligibilityVerbatim,
    String? eligibilityAnalysis,
    List<OpportunityFieldSummary> allFields,
    List<OpportunityListItem> relatedOpportunities,
    String? applicationStatus,
    String? userNotes,
  });
}

/// @nodoc
class _$OpportunityDetailCopyWithImpl<$Res, $Val extends OpportunityDetail>
    implements $OpportunityDetailCopyWith<$Res> {
  _$OpportunityDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OpportunityDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? organization = null,
    Object? categoryId = null,
    Object? deadlineIso = null,
    Object? location = null,
    Object? countryCode = null,
    Object? matchScore = freezed,
    Object? provenanceDeadline = null,
    Object? isSaved = null,
    Object? isNew = null,
    Object? currencyCode = freezed,
    Object? amountMin = freezed,
    Object? amountMax = freezed,
    Object? sourceCount = null,
    Object? collectedAt = null,
    Object? fullText = null,
    Object? summaryAi = null,
    Object? eligibilityVerbatim = freezed,
    Object? eligibilityAnalysis = freezed,
    Object? allFields = null,
    Object? relatedOpportunities = null,
    Object? applicationStatus = freezed,
    Object? userNotes = freezed,
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
            categoryId: null == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String,
            deadlineIso: null == deadlineIso
                ? _value.deadlineIso
                : deadlineIso // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            location: null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String,
            countryCode: null == countryCode
                ? _value.countryCode
                : countryCode // ignore: cast_nullable_to_non_nullable
                      as String,
            matchScore: freezed == matchScore
                ? _value.matchScore
                : matchScore // ignore: cast_nullable_to_non_nullable
                      as int?,
            provenanceDeadline: null == provenanceDeadline
                ? _value.provenanceDeadline
                : provenanceDeadline // ignore: cast_nullable_to_non_nullable
                      as ProvenanceTag,
            isSaved: null == isSaved
                ? _value.isSaved
                : isSaved // ignore: cast_nullable_to_non_nullable
                      as bool,
            isNew: null == isNew
                ? _value.isNew
                : isNew // ignore: cast_nullable_to_non_nullable
                      as bool,
            currencyCode: freezed == currencyCode
                ? _value.currencyCode
                : currencyCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            amountMin: freezed == amountMin
                ? _value.amountMin
                : amountMin // ignore: cast_nullable_to_non_nullable
                      as double?,
            amountMax: freezed == amountMax
                ? _value.amountMax
                : amountMax // ignore: cast_nullable_to_non_nullable
                      as double?,
            sourceCount: null == sourceCount
                ? _value.sourceCount
                : sourceCount // ignore: cast_nullable_to_non_nullable
                      as int,
            collectedAt: null == collectedAt
                ? _value.collectedAt
                : collectedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            fullText: null == fullText
                ? _value.fullText
                : fullText // ignore: cast_nullable_to_non_nullable
                      as String,
            summaryAi: null == summaryAi
                ? _value.summaryAi
                : summaryAi // ignore: cast_nullable_to_non_nullable
                      as String,
            eligibilityVerbatim: freezed == eligibilityVerbatim
                ? _value.eligibilityVerbatim
                : eligibilityVerbatim // ignore: cast_nullable_to_non_nullable
                      as String?,
            eligibilityAnalysis: freezed == eligibilityAnalysis
                ? _value.eligibilityAnalysis
                : eligibilityAnalysis // ignore: cast_nullable_to_non_nullable
                      as String?,
            allFields: null == allFields
                ? _value.allFields
                : allFields // ignore: cast_nullable_to_non_nullable
                      as List<OpportunityFieldSummary>,
            relatedOpportunities: null == relatedOpportunities
                ? _value.relatedOpportunities
                : relatedOpportunities // ignore: cast_nullable_to_non_nullable
                      as List<OpportunityListItem>,
            applicationStatus: freezed == applicationStatus
                ? _value.applicationStatus
                : applicationStatus // ignore: cast_nullable_to_non_nullable
                      as String?,
            userNotes: freezed == userNotes
                ? _value.userNotes
                : userNotes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OpportunityDetailImplCopyWith<$Res>
    implements $OpportunityDetailCopyWith<$Res> {
  factory _$$OpportunityDetailImplCopyWith(
    _$OpportunityDetailImpl value,
    $Res Function(_$OpportunityDetailImpl) then,
  ) = __$$OpportunityDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String organization,
    String categoryId,
    DateTime deadlineIso,
    String location,
    String countryCode,
    int? matchScore,
    ProvenanceTag provenanceDeadline,
    bool isSaved,
    bool isNew,
    String? currencyCode,
    double? amountMin,
    double? amountMax,
    int sourceCount,
    DateTime collectedAt,
    String fullText,
    String summaryAi,
    String? eligibilityVerbatim,
    String? eligibilityAnalysis,
    List<OpportunityFieldSummary> allFields,
    List<OpportunityListItem> relatedOpportunities,
    String? applicationStatus,
    String? userNotes,
  });
}

/// @nodoc
class __$$OpportunityDetailImplCopyWithImpl<$Res>
    extends _$OpportunityDetailCopyWithImpl<$Res, _$OpportunityDetailImpl>
    implements _$$OpportunityDetailImplCopyWith<$Res> {
  __$$OpportunityDetailImplCopyWithImpl(
    _$OpportunityDetailImpl _value,
    $Res Function(_$OpportunityDetailImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OpportunityDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? organization = null,
    Object? categoryId = null,
    Object? deadlineIso = null,
    Object? location = null,
    Object? countryCode = null,
    Object? matchScore = freezed,
    Object? provenanceDeadline = null,
    Object? isSaved = null,
    Object? isNew = null,
    Object? currencyCode = freezed,
    Object? amountMin = freezed,
    Object? amountMax = freezed,
    Object? sourceCount = null,
    Object? collectedAt = null,
    Object? fullText = null,
    Object? summaryAi = null,
    Object? eligibilityVerbatim = freezed,
    Object? eligibilityAnalysis = freezed,
    Object? allFields = null,
    Object? relatedOpportunities = null,
    Object? applicationStatus = freezed,
    Object? userNotes = freezed,
  }) {
    return _then(
      _$OpportunityDetailImpl(
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
        categoryId: null == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        deadlineIso: null == deadlineIso
            ? _value.deadlineIso
            : deadlineIso // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        location: null == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String,
        countryCode: null == countryCode
            ? _value.countryCode
            : countryCode // ignore: cast_nullable_to_non_nullable
                  as String,
        matchScore: freezed == matchScore
            ? _value.matchScore
            : matchScore // ignore: cast_nullable_to_non_nullable
                  as int?,
        provenanceDeadline: null == provenanceDeadline
            ? _value.provenanceDeadline
            : provenanceDeadline // ignore: cast_nullable_to_non_nullable
                  as ProvenanceTag,
        isSaved: null == isSaved
            ? _value.isSaved
            : isSaved // ignore: cast_nullable_to_non_nullable
                  as bool,
        isNew: null == isNew
            ? _value.isNew
            : isNew // ignore: cast_nullable_to_non_nullable
                  as bool,
        currencyCode: freezed == currencyCode
            ? _value.currencyCode
            : currencyCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        amountMin: freezed == amountMin
            ? _value.amountMin
            : amountMin // ignore: cast_nullable_to_non_nullable
                  as double?,
        amountMax: freezed == amountMax
            ? _value.amountMax
            : amountMax // ignore: cast_nullable_to_non_nullable
                  as double?,
        sourceCount: null == sourceCount
            ? _value.sourceCount
            : sourceCount // ignore: cast_nullable_to_non_nullable
                  as int,
        collectedAt: null == collectedAt
            ? _value.collectedAt
            : collectedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        fullText: null == fullText
            ? _value.fullText
            : fullText // ignore: cast_nullable_to_non_nullable
                  as String,
        summaryAi: null == summaryAi
            ? _value.summaryAi
            : summaryAi // ignore: cast_nullable_to_non_nullable
                  as String,
        eligibilityVerbatim: freezed == eligibilityVerbatim
            ? _value.eligibilityVerbatim
            : eligibilityVerbatim // ignore: cast_nullable_to_non_nullable
                  as String?,
        eligibilityAnalysis: freezed == eligibilityAnalysis
            ? _value.eligibilityAnalysis
            : eligibilityAnalysis // ignore: cast_nullable_to_non_nullable
                  as String?,
        allFields: null == allFields
            ? _value._allFields
            : allFields // ignore: cast_nullable_to_non_nullable
                  as List<OpportunityFieldSummary>,
        relatedOpportunities: null == relatedOpportunities
            ? _value._relatedOpportunities
            : relatedOpportunities // ignore: cast_nullable_to_non_nullable
                  as List<OpportunityListItem>,
        applicationStatus: freezed == applicationStatus
            ? _value.applicationStatus
            : applicationStatus // ignore: cast_nullable_to_non_nullable
                  as String?,
        userNotes: freezed == userNotes
            ? _value.userNotes
            : userNotes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OpportunityDetailImpl implements _OpportunityDetail {
  const _$OpportunityDetailImpl({
    required this.id,
    required this.title,
    required this.organization,
    required this.categoryId,
    required this.deadlineIso,
    required this.location,
    required this.countryCode,
    this.matchScore,
    required this.provenanceDeadline,
    this.isSaved = false,
    this.isNew = true,
    this.currencyCode,
    this.amountMin,
    this.amountMax,
    this.sourceCount = 1,
    required this.collectedAt,
    required this.fullText,
    required this.summaryAi,
    this.eligibilityVerbatim,
    this.eligibilityAnalysis,
    final List<OpportunityFieldSummary> allFields = const [],
    final List<OpportunityListItem> relatedOpportunities = const [],
    this.applicationStatus,
    this.userNotes,
  }) : _allFields = allFields,
       _relatedOpportunities = relatedOpportunities;

  factory _$OpportunityDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$OpportunityDetailImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String organization;
  @override
  final String categoryId;
  @override
  final DateTime deadlineIso;
  @override
  final String location;
  @override
  final String countryCode;
  @override
  final int? matchScore;
  @override
  final ProvenanceTag provenanceDeadline;
  @override
  @JsonKey()
  final bool isSaved;
  @override
  @JsonKey()
  final bool isNew;
  @override
  final String? currencyCode;
  @override
  final double? amountMin;
  @override
  final double? amountMax;
  @override
  @JsonKey()
  final int sourceCount;
  @override
  final DateTime collectedAt;
  @override
  final String fullText;
  @override
  final String summaryAi;
  @override
  final String? eligibilityVerbatim;
  @override
  final String? eligibilityAnalysis;
  final List<OpportunityFieldSummary> _allFields;
  @override
  @JsonKey()
  List<OpportunityFieldSummary> get allFields {
    if (_allFields is EqualUnmodifiableListView) return _allFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allFields);
  }

  final List<OpportunityListItem> _relatedOpportunities;
  @override
  @JsonKey()
  List<OpportunityListItem> get relatedOpportunities {
    if (_relatedOpportunities is EqualUnmodifiableListView)
      return _relatedOpportunities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_relatedOpportunities);
  }

  @override
  final String? applicationStatus;
  @override
  final String? userNotes;

  @override
  String toString() {
    return 'OpportunityDetail(id: $id, title: $title, organization: $organization, categoryId: $categoryId, deadlineIso: $deadlineIso, location: $location, countryCode: $countryCode, matchScore: $matchScore, provenanceDeadline: $provenanceDeadline, isSaved: $isSaved, isNew: $isNew, currencyCode: $currencyCode, amountMin: $amountMin, amountMax: $amountMax, sourceCount: $sourceCount, collectedAt: $collectedAt, fullText: $fullText, summaryAi: $summaryAi, eligibilityVerbatim: $eligibilityVerbatim, eligibilityAnalysis: $eligibilityAnalysis, allFields: $allFields, relatedOpportunities: $relatedOpportunities, applicationStatus: $applicationStatus, userNotes: $userNotes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OpportunityDetailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.organization, organization) ||
                other.organization == organization) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.deadlineIso, deadlineIso) ||
                other.deadlineIso == deadlineIso) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.countryCode, countryCode) ||
                other.countryCode == countryCode) &&
            (identical(other.matchScore, matchScore) ||
                other.matchScore == matchScore) &&
            (identical(other.provenanceDeadline, provenanceDeadline) ||
                other.provenanceDeadline == provenanceDeadline) &&
            (identical(other.isSaved, isSaved) || other.isSaved == isSaved) &&
            (identical(other.isNew, isNew) || other.isNew == isNew) &&
            (identical(other.currencyCode, currencyCode) ||
                other.currencyCode == currencyCode) &&
            (identical(other.amountMin, amountMin) ||
                other.amountMin == amountMin) &&
            (identical(other.amountMax, amountMax) ||
                other.amountMax == amountMax) &&
            (identical(other.sourceCount, sourceCount) ||
                other.sourceCount == sourceCount) &&
            (identical(other.collectedAt, collectedAt) ||
                other.collectedAt == collectedAt) &&
            (identical(other.fullText, fullText) ||
                other.fullText == fullText) &&
            (identical(other.summaryAi, summaryAi) ||
                other.summaryAi == summaryAi) &&
            (identical(other.eligibilityVerbatim, eligibilityVerbatim) ||
                other.eligibilityVerbatim == eligibilityVerbatim) &&
            (identical(other.eligibilityAnalysis, eligibilityAnalysis) ||
                other.eligibilityAnalysis == eligibilityAnalysis) &&
            const DeepCollectionEquality().equals(
              other._allFields,
              _allFields,
            ) &&
            const DeepCollectionEquality().equals(
              other._relatedOpportunities,
              _relatedOpportunities,
            ) &&
            (identical(other.applicationStatus, applicationStatus) ||
                other.applicationStatus == applicationStatus) &&
            (identical(other.userNotes, userNotes) ||
                other.userNotes == userNotes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    title,
    organization,
    categoryId,
    deadlineIso,
    location,
    countryCode,
    matchScore,
    provenanceDeadline,
    isSaved,
    isNew,
    currencyCode,
    amountMin,
    amountMax,
    sourceCount,
    collectedAt,
    fullText,
    summaryAi,
    eligibilityVerbatim,
    eligibilityAnalysis,
    const DeepCollectionEquality().hash(_allFields),
    const DeepCollectionEquality().hash(_relatedOpportunities),
    applicationStatus,
    userNotes,
  ]);

  /// Create a copy of OpportunityDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OpportunityDetailImplCopyWith<_$OpportunityDetailImpl> get copyWith =>
      __$$OpportunityDetailImplCopyWithImpl<_$OpportunityDetailImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OpportunityDetailImplToJson(this);
  }
}

abstract class _OpportunityDetail implements OpportunityDetail {
  const factory _OpportunityDetail({
    required final String id,
    required final String title,
    required final String organization,
    required final String categoryId,
    required final DateTime deadlineIso,
    required final String location,
    required final String countryCode,
    final int? matchScore,
    required final ProvenanceTag provenanceDeadline,
    final bool isSaved,
    final bool isNew,
    final String? currencyCode,
    final double? amountMin,
    final double? amountMax,
    final int sourceCount,
    required final DateTime collectedAt,
    required final String fullText,
    required final String summaryAi,
    final String? eligibilityVerbatim,
    final String? eligibilityAnalysis,
    final List<OpportunityFieldSummary> allFields,
    final List<OpportunityListItem> relatedOpportunities,
    final String? applicationStatus,
    final String? userNotes,
  }) = _$OpportunityDetailImpl;

  factory _OpportunityDetail.fromJson(Map<String, dynamic> json) =
      _$OpportunityDetailImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get organization;
  @override
  String get categoryId;
  @override
  DateTime get deadlineIso;
  @override
  String get location;
  @override
  String get countryCode;
  @override
  int? get matchScore;
  @override
  ProvenanceTag get provenanceDeadline;
  @override
  bool get isSaved;
  @override
  bool get isNew;
  @override
  String? get currencyCode;
  @override
  double? get amountMin;
  @override
  double? get amountMax;
  @override
  int get sourceCount;
  @override
  DateTime get collectedAt;
  @override
  String get fullText;
  @override
  String get summaryAi;
  @override
  String? get eligibilityVerbatim;
  @override
  String? get eligibilityAnalysis;
  @override
  List<OpportunityFieldSummary> get allFields;
  @override
  List<OpportunityListItem> get relatedOpportunities;
  @override
  String? get applicationStatus;
  @override
  String? get userNotes;

  /// Create a copy of OpportunityDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OpportunityDetailImplCopyWith<_$OpportunityDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OpportunityFieldSummary _$OpportunityFieldSummaryFromJson(
  Map<String, dynamic> json,
) {
  return _OpportunityFieldSummary.fromJson(json);
}

/// @nodoc
mixin _$OpportunityFieldSummary {
  String get fieldName => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;
  ProvenanceTag get provenance => throw _privateConstructorUsedError;
  String? get excerpt => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;

  /// Serializes this OpportunityFieldSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OpportunityFieldSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OpportunityFieldSummaryCopyWith<OpportunityFieldSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OpportunityFieldSummaryCopyWith<$Res> {
  factory $OpportunityFieldSummaryCopyWith(
    OpportunityFieldSummary value,
    $Res Function(OpportunityFieldSummary) then,
  ) = _$OpportunityFieldSummaryCopyWithImpl<$Res, OpportunityFieldSummary>;
  @useResult
  $Res call({
    String fieldName,
    String displayName,
    String value,
    ProvenanceTag provenance,
    String? excerpt,
    double confidence,
  });
}

/// @nodoc
class _$OpportunityFieldSummaryCopyWithImpl<
  $Res,
  $Val extends OpportunityFieldSummary
>
    implements $OpportunityFieldSummaryCopyWith<$Res> {
  _$OpportunityFieldSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OpportunityFieldSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fieldName = null,
    Object? displayName = null,
    Object? value = null,
    Object? provenance = null,
    Object? excerpt = freezed,
    Object? confidence = null,
  }) {
    return _then(
      _value.copyWith(
            fieldName: null == fieldName
                ? _value.fieldName
                : fieldName // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String,
            provenance: null == provenance
                ? _value.provenance
                : provenance // ignore: cast_nullable_to_non_nullable
                      as ProvenanceTag,
            excerpt: freezed == excerpt
                ? _value.excerpt
                : excerpt // ignore: cast_nullable_to_non_nullable
                      as String?,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OpportunityFieldSummaryImplCopyWith<$Res>
    implements $OpportunityFieldSummaryCopyWith<$Res> {
  factory _$$OpportunityFieldSummaryImplCopyWith(
    _$OpportunityFieldSummaryImpl value,
    $Res Function(_$OpportunityFieldSummaryImpl) then,
  ) = __$$OpportunityFieldSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String fieldName,
    String displayName,
    String value,
    ProvenanceTag provenance,
    String? excerpt,
    double confidence,
  });
}

/// @nodoc
class __$$OpportunityFieldSummaryImplCopyWithImpl<$Res>
    extends
        _$OpportunityFieldSummaryCopyWithImpl<
          $Res,
          _$OpportunityFieldSummaryImpl
        >
    implements _$$OpportunityFieldSummaryImplCopyWith<$Res> {
  __$$OpportunityFieldSummaryImplCopyWithImpl(
    _$OpportunityFieldSummaryImpl _value,
    $Res Function(_$OpportunityFieldSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OpportunityFieldSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fieldName = null,
    Object? displayName = null,
    Object? value = null,
    Object? provenance = null,
    Object? excerpt = freezed,
    Object? confidence = null,
  }) {
    return _then(
      _$OpportunityFieldSummaryImpl(
        fieldName: null == fieldName
            ? _value.fieldName
            : fieldName // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
        provenance: null == provenance
            ? _value.provenance
            : provenance // ignore: cast_nullable_to_non_nullable
                  as ProvenanceTag,
        excerpt: freezed == excerpt
            ? _value.excerpt
            : excerpt // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$OpportunityFieldSummaryImpl implements _OpportunityFieldSummary {
  const _$OpportunityFieldSummaryImpl({
    required this.fieldName,
    required this.displayName,
    required this.value,
    required this.provenance,
    this.excerpt,
    this.confidence = 0.0,
  });

  factory _$OpportunityFieldSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$OpportunityFieldSummaryImplFromJson(json);

  @override
  final String fieldName;
  @override
  final String displayName;
  @override
  final String value;
  @override
  final ProvenanceTag provenance;
  @override
  final String? excerpt;
  @override
  @JsonKey()
  final double confidence;

  @override
  String toString() {
    return 'OpportunityFieldSummary(fieldName: $fieldName, displayName: $displayName, value: $value, provenance: $provenance, excerpt: $excerpt, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OpportunityFieldSummaryImpl &&
            (identical(other.fieldName, fieldName) ||
                other.fieldName == fieldName) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.provenance, provenance) ||
                other.provenance == provenance) &&
            (identical(other.excerpt, excerpt) || other.excerpt == excerpt) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    fieldName,
    displayName,
    value,
    provenance,
    excerpt,
    confidence,
  );

  /// Create a copy of OpportunityFieldSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OpportunityFieldSummaryImplCopyWith<_$OpportunityFieldSummaryImpl>
  get copyWith =>
      __$$OpportunityFieldSummaryImplCopyWithImpl<
        _$OpportunityFieldSummaryImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OpportunityFieldSummaryImplToJson(this);
  }
}

abstract class _OpportunityFieldSummary implements OpportunityFieldSummary {
  const factory _OpportunityFieldSummary({
    required final String fieldName,
    required final String displayName,
    required final String value,
    required final ProvenanceTag provenance,
    final String? excerpt,
    final double confidence,
  }) = _$OpportunityFieldSummaryImpl;

  factory _OpportunityFieldSummary.fromJson(Map<String, dynamic> json) =
      _$OpportunityFieldSummaryImpl.fromJson;

  @override
  String get fieldName;
  @override
  String get displayName;
  @override
  String get value;
  @override
  ProvenanceTag get provenance;
  @override
  String? get excerpt;
  @override
  double get confidence;

  /// Create a copy of OpportunityFieldSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OpportunityFieldSummaryImplCopyWith<_$OpportunityFieldSummaryImpl>
  get copyWith => throw _privateConstructorUsedError;
}

MatchScoreDetail _$MatchScoreDetailFromJson(Map<String, dynamic> json) {
  return _MatchScoreDetail.fromJson(json);
}

/// @nodoc
mixin _$MatchScoreDetail {
  int get totalScore => throw _privateConstructorUsedError;
  String get eligibility =>
      throw _privateConstructorUsedError; // probable, uncertain, unlikely
  List<MatchCriterion> get criteria => throw _privateConstructorUsedError;
  List<String> get strengths => throw _privateConstructorUsedError;
  List<String> get gaps => throw _privateConstructorUsedError;
  List<String> get conditionsToVerify => throw _privateConstructorUsedError;

  /// Serializes this MatchScoreDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MatchScoreDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MatchScoreDetailCopyWith<MatchScoreDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchScoreDetailCopyWith<$Res> {
  factory $MatchScoreDetailCopyWith(
    MatchScoreDetail value,
    $Res Function(MatchScoreDetail) then,
  ) = _$MatchScoreDetailCopyWithImpl<$Res, MatchScoreDetail>;
  @useResult
  $Res call({
    int totalScore,
    String eligibility,
    List<MatchCriterion> criteria,
    List<String> strengths,
    List<String> gaps,
    List<String> conditionsToVerify,
  });
}

/// @nodoc
class _$MatchScoreDetailCopyWithImpl<$Res, $Val extends MatchScoreDetail>
    implements $MatchScoreDetailCopyWith<$Res> {
  _$MatchScoreDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MatchScoreDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalScore = null,
    Object? eligibility = null,
    Object? criteria = null,
    Object? strengths = null,
    Object? gaps = null,
    Object? conditionsToVerify = null,
  }) {
    return _then(
      _value.copyWith(
            totalScore: null == totalScore
                ? _value.totalScore
                : totalScore // ignore: cast_nullable_to_non_nullable
                      as int,
            eligibility: null == eligibility
                ? _value.eligibility
                : eligibility // ignore: cast_nullable_to_non_nullable
                      as String,
            criteria: null == criteria
                ? _value.criteria
                : criteria // ignore: cast_nullable_to_non_nullable
                      as List<MatchCriterion>,
            strengths: null == strengths
                ? _value.strengths
                : strengths // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            gaps: null == gaps
                ? _value.gaps
                : gaps // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            conditionsToVerify: null == conditionsToVerify
                ? _value.conditionsToVerify
                : conditionsToVerify // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MatchScoreDetailImplCopyWith<$Res>
    implements $MatchScoreDetailCopyWith<$Res> {
  factory _$$MatchScoreDetailImplCopyWith(
    _$MatchScoreDetailImpl value,
    $Res Function(_$MatchScoreDetailImpl) then,
  ) = __$$MatchScoreDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalScore,
    String eligibility,
    List<MatchCriterion> criteria,
    List<String> strengths,
    List<String> gaps,
    List<String> conditionsToVerify,
  });
}

/// @nodoc
class __$$MatchScoreDetailImplCopyWithImpl<$Res>
    extends _$MatchScoreDetailCopyWithImpl<$Res, _$MatchScoreDetailImpl>
    implements _$$MatchScoreDetailImplCopyWith<$Res> {
  __$$MatchScoreDetailImplCopyWithImpl(
    _$MatchScoreDetailImpl _value,
    $Res Function(_$MatchScoreDetailImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MatchScoreDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalScore = null,
    Object? eligibility = null,
    Object? criteria = null,
    Object? strengths = null,
    Object? gaps = null,
    Object? conditionsToVerify = null,
  }) {
    return _then(
      _$MatchScoreDetailImpl(
        totalScore: null == totalScore
            ? _value.totalScore
            : totalScore // ignore: cast_nullable_to_non_nullable
                  as int,
        eligibility: null == eligibility
            ? _value.eligibility
            : eligibility // ignore: cast_nullable_to_non_nullable
                  as String,
        criteria: null == criteria
            ? _value._criteria
            : criteria // ignore: cast_nullable_to_non_nullable
                  as List<MatchCriterion>,
        strengths: null == strengths
            ? _value._strengths
            : strengths // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        gaps: null == gaps
            ? _value._gaps
            : gaps // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        conditionsToVerify: null == conditionsToVerify
            ? _value._conditionsToVerify
            : conditionsToVerify // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchScoreDetailImpl implements _MatchScoreDetail {
  const _$MatchScoreDetailImpl({
    required this.totalScore,
    required this.eligibility,
    final List<MatchCriterion> criteria = const [],
    final List<String> strengths = const [],
    final List<String> gaps = const [],
    final List<String> conditionsToVerify = const [],
  }) : _criteria = criteria,
       _strengths = strengths,
       _gaps = gaps,
       _conditionsToVerify = conditionsToVerify;

  factory _$MatchScoreDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchScoreDetailImplFromJson(json);

  @override
  final int totalScore;
  @override
  final String eligibility;
  // probable, uncertain, unlikely
  final List<MatchCriterion> _criteria;
  // probable, uncertain, unlikely
  @override
  @JsonKey()
  List<MatchCriterion> get criteria {
    if (_criteria is EqualUnmodifiableListView) return _criteria;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_criteria);
  }

  final List<String> _strengths;
  @override
  @JsonKey()
  List<String> get strengths {
    if (_strengths is EqualUnmodifiableListView) return _strengths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_strengths);
  }

  final List<String> _gaps;
  @override
  @JsonKey()
  List<String> get gaps {
    if (_gaps is EqualUnmodifiableListView) return _gaps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_gaps);
  }

  final List<String> _conditionsToVerify;
  @override
  @JsonKey()
  List<String> get conditionsToVerify {
    if (_conditionsToVerify is EqualUnmodifiableListView)
      return _conditionsToVerify;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_conditionsToVerify);
  }

  @override
  String toString() {
    return 'MatchScoreDetail(totalScore: $totalScore, eligibility: $eligibility, criteria: $criteria, strengths: $strengths, gaps: $gaps, conditionsToVerify: $conditionsToVerify)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchScoreDetailImpl &&
            (identical(other.totalScore, totalScore) ||
                other.totalScore == totalScore) &&
            (identical(other.eligibility, eligibility) ||
                other.eligibility == eligibility) &&
            const DeepCollectionEquality().equals(other._criteria, _criteria) &&
            const DeepCollectionEquality().equals(
              other._strengths,
              _strengths,
            ) &&
            const DeepCollectionEquality().equals(other._gaps, _gaps) &&
            const DeepCollectionEquality().equals(
              other._conditionsToVerify,
              _conditionsToVerify,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalScore,
    eligibility,
    const DeepCollectionEquality().hash(_criteria),
    const DeepCollectionEquality().hash(_strengths),
    const DeepCollectionEquality().hash(_gaps),
    const DeepCollectionEquality().hash(_conditionsToVerify),
  );

  /// Create a copy of MatchScoreDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchScoreDetailImplCopyWith<_$MatchScoreDetailImpl> get copyWith =>
      __$$MatchScoreDetailImplCopyWithImpl<_$MatchScoreDetailImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchScoreDetailImplToJson(this);
  }
}

abstract class _MatchScoreDetail implements MatchScoreDetail {
  const factory _MatchScoreDetail({
    required final int totalScore,
    required final String eligibility,
    final List<MatchCriterion> criteria,
    final List<String> strengths,
    final List<String> gaps,
    final List<String> conditionsToVerify,
  }) = _$MatchScoreDetailImpl;

  factory _MatchScoreDetail.fromJson(Map<String, dynamic> json) =
      _$MatchScoreDetailImpl.fromJson;

  @override
  int get totalScore;
  @override
  String get eligibility; // probable, uncertain, unlikely
  @override
  List<MatchCriterion> get criteria;
  @override
  List<String> get strengths;
  @override
  List<String> get gaps;
  @override
  List<String> get conditionsToVerify;

  /// Create a copy of MatchScoreDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MatchScoreDetailImplCopyWith<_$MatchScoreDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MatchCriterion _$MatchCriterionFromJson(Map<String, dynamic> json) {
  return _MatchCriterion.fromJson(json);
}

/// @nodoc
mixin _$MatchCriterion {
  String get name => throw _privateConstructorUsedError;
  String get labelFr => throw _privateConstructorUsedError;
  double get score => throw _privateConstructorUsedError;
  double get weight => throw _privateConstructorUsedError;
  bool get notEvaluated => throw _privateConstructorUsedError;

  /// Serializes this MatchCriterion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MatchCriterion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MatchCriterionCopyWith<MatchCriterion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatchCriterionCopyWith<$Res> {
  factory $MatchCriterionCopyWith(
    MatchCriterion value,
    $Res Function(MatchCriterion) then,
  ) = _$MatchCriterionCopyWithImpl<$Res, MatchCriterion>;
  @useResult
  $Res call({
    String name,
    String labelFr,
    double score,
    double weight,
    bool notEvaluated,
  });
}

/// @nodoc
class _$MatchCriterionCopyWithImpl<$Res, $Val extends MatchCriterion>
    implements $MatchCriterionCopyWith<$Res> {
  _$MatchCriterionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MatchCriterion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? labelFr = null,
    Object? score = null,
    Object? weight = null,
    Object? notEvaluated = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            labelFr: null == labelFr
                ? _value.labelFr
                : labelFr // ignore: cast_nullable_to_non_nullable
                      as String,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as double,
            weight: null == weight
                ? _value.weight
                : weight // ignore: cast_nullable_to_non_nullable
                      as double,
            notEvaluated: null == notEvaluated
                ? _value.notEvaluated
                : notEvaluated // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MatchCriterionImplCopyWith<$Res>
    implements $MatchCriterionCopyWith<$Res> {
  factory _$$MatchCriterionImplCopyWith(
    _$MatchCriterionImpl value,
    $Res Function(_$MatchCriterionImpl) then,
  ) = __$$MatchCriterionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String labelFr,
    double score,
    double weight,
    bool notEvaluated,
  });
}

/// @nodoc
class __$$MatchCriterionImplCopyWithImpl<$Res>
    extends _$MatchCriterionCopyWithImpl<$Res, _$MatchCriterionImpl>
    implements _$$MatchCriterionImplCopyWith<$Res> {
  __$$MatchCriterionImplCopyWithImpl(
    _$MatchCriterionImpl _value,
    $Res Function(_$MatchCriterionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MatchCriterion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? labelFr = null,
    Object? score = null,
    Object? weight = null,
    Object? notEvaluated = null,
  }) {
    return _then(
      _$MatchCriterionImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        labelFr: null == labelFr
            ? _value.labelFr
            : labelFr // ignore: cast_nullable_to_non_nullable
                  as String,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as double,
        weight: null == weight
            ? _value.weight
            : weight // ignore: cast_nullable_to_non_nullable
                  as double,
        notEvaluated: null == notEvaluated
            ? _value.notEvaluated
            : notEvaluated // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MatchCriterionImpl implements _MatchCriterion {
  const _$MatchCriterionImpl({
    required this.name,
    required this.labelFr,
    required this.score,
    required this.weight,
    this.notEvaluated = false,
  });

  factory _$MatchCriterionImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatchCriterionImplFromJson(json);

  @override
  final String name;
  @override
  final String labelFr;
  @override
  final double score;
  @override
  final double weight;
  @override
  @JsonKey()
  final bool notEvaluated;

  @override
  String toString() {
    return 'MatchCriterion(name: $name, labelFr: $labelFr, score: $score, weight: $weight, notEvaluated: $notEvaluated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatchCriterionImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.labelFr, labelFr) || other.labelFr == labelFr) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.notEvaluated, notEvaluated) ||
                other.notEvaluated == notEvaluated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, labelFr, score, weight, notEvaluated);

  /// Create a copy of MatchCriterion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MatchCriterionImplCopyWith<_$MatchCriterionImpl> get copyWith =>
      __$$MatchCriterionImplCopyWithImpl<_$MatchCriterionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MatchCriterionImplToJson(this);
  }
}

abstract class _MatchCriterion implements MatchCriterion {
  const factory _MatchCriterion({
    required final String name,
    required final String labelFr,
    required final double score,
    required final double weight,
    final bool notEvaluated,
  }) = _$MatchCriterionImpl;

  factory _MatchCriterion.fromJson(Map<String, dynamic> json) =
      _$MatchCriterionImpl.fromJson;

  @override
  String get name;
  @override
  String get labelFr;
  @override
  double get score;
  @override
  double get weight;
  @override
  bool get notEvaluated;

  /// Create a copy of MatchCriterion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MatchCriterionImplCopyWith<_$MatchCriterionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
