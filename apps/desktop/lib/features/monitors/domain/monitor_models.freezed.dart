// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'monitor_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MonitorModel _$MonitorModelFromJson(Map<String, dynamic> json) {
  return _MonitorModel.fromJson(json);
}

/// @nodoc
mixin _$MonitorModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  Map<String, dynamic> get filtersJson => throw _privateConstructorUsedError;
  MonitorFrequency get frequency => throw _privateConstructorUsedError;
  int get minScore => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get nextRunAt => throw _privateConstructorUsedError;
  DateTime? get lastRunAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this MonitorModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MonitorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MonitorModelCopyWith<MonitorModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MonitorModelCopyWith<$Res> {
  factory $MonitorModelCopyWith(
    MonitorModel value,
    $Res Function(MonitorModel) then,
  ) = _$MonitorModelCopyWithImpl<$Res, MonitorModel>;
  @useResult
  $Res call({
    String id,
    String name,
    Map<String, dynamic> filtersJson,
    MonitorFrequency frequency,
    int minScore,
    bool isActive,
    DateTime? nextRunAt,
    DateTime? lastRunAt,
    DateTime createdAt,
  });
}

/// @nodoc
class _$MonitorModelCopyWithImpl<$Res, $Val extends MonitorModel>
    implements $MonitorModelCopyWith<$Res> {
  _$MonitorModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MonitorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? filtersJson = null,
    Object? frequency = null,
    Object? minScore = null,
    Object? isActive = null,
    Object? nextRunAt = freezed,
    Object? lastRunAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            filtersJson: null == filtersJson
                ? _value.filtersJson
                : filtersJson // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            frequency: null == frequency
                ? _value.frequency
                : frequency // ignore: cast_nullable_to_non_nullable
                      as MonitorFrequency,
            minScore: null == minScore
                ? _value.minScore
                : minScore // ignore: cast_nullable_to_non_nullable
                      as int,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            nextRunAt: freezed == nextRunAt
                ? _value.nextRunAt
                : nextRunAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastRunAt: freezed == lastRunAt
                ? _value.lastRunAt
                : lastRunAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MonitorModelImplCopyWith<$Res>
    implements $MonitorModelCopyWith<$Res> {
  factory _$$MonitorModelImplCopyWith(
    _$MonitorModelImpl value,
    $Res Function(_$MonitorModelImpl) then,
  ) = __$$MonitorModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    Map<String, dynamic> filtersJson,
    MonitorFrequency frequency,
    int minScore,
    bool isActive,
    DateTime? nextRunAt,
    DateTime? lastRunAt,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$MonitorModelImplCopyWithImpl<$Res>
    extends _$MonitorModelCopyWithImpl<$Res, _$MonitorModelImpl>
    implements _$$MonitorModelImplCopyWith<$Res> {
  __$$MonitorModelImplCopyWithImpl(
    _$MonitorModelImpl _value,
    $Res Function(_$MonitorModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MonitorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? filtersJson = null,
    Object? frequency = null,
    Object? minScore = null,
    Object? isActive = null,
    Object? nextRunAt = freezed,
    Object? lastRunAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$MonitorModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        filtersJson: null == filtersJson
            ? _value._filtersJson
            : filtersJson // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        frequency: null == frequency
            ? _value.frequency
            : frequency // ignore: cast_nullable_to_non_nullable
                  as MonitorFrequency,
        minScore: null == minScore
            ? _value.minScore
            : minScore // ignore: cast_nullable_to_non_nullable
                  as int,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        nextRunAt: freezed == nextRunAt
            ? _value.nextRunAt
            : nextRunAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastRunAt: freezed == lastRunAt
            ? _value.lastRunAt
            : lastRunAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MonitorModelImpl implements _MonitorModel {
  const _$MonitorModelImpl({
    required this.id,
    required this.name,
    required final Map<String, dynamic> filtersJson,
    required this.frequency,
    required this.minScore,
    this.isActive = true,
    this.nextRunAt,
    this.lastRunAt,
    required this.createdAt,
  }) : _filtersJson = filtersJson;

  factory _$MonitorModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MonitorModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  final Map<String, dynamic> _filtersJson;
  @override
  Map<String, dynamic> get filtersJson {
    if (_filtersJson is EqualUnmodifiableMapView) return _filtersJson;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_filtersJson);
  }

  @override
  final MonitorFrequency frequency;
  @override
  final int minScore;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final DateTime? nextRunAt;
  @override
  final DateTime? lastRunAt;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'MonitorModel(id: $id, name: $name, filtersJson: $filtersJson, frequency: $frequency, minScore: $minScore, isActive: $isActive, nextRunAt: $nextRunAt, lastRunAt: $lastRunAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonitorModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(
              other._filtersJson,
              _filtersJson,
            ) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.minScore, minScore) ||
                other.minScore == minScore) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.nextRunAt, nextRunAt) ||
                other.nextRunAt == nextRunAt) &&
            (identical(other.lastRunAt, lastRunAt) ||
                other.lastRunAt == lastRunAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    const DeepCollectionEquality().hash(_filtersJson),
    frequency,
    minScore,
    isActive,
    nextRunAt,
    lastRunAt,
    createdAt,
  );

  /// Create a copy of MonitorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MonitorModelImplCopyWith<_$MonitorModelImpl> get copyWith =>
      __$$MonitorModelImplCopyWithImpl<_$MonitorModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MonitorModelImplToJson(this);
  }
}

abstract class _MonitorModel implements MonitorModel {
  const factory _MonitorModel({
    required final String id,
    required final String name,
    required final Map<String, dynamic> filtersJson,
    required final MonitorFrequency frequency,
    required final int minScore,
    final bool isActive,
    final DateTime? nextRunAt,
    final DateTime? lastRunAt,
    required final DateTime createdAt,
  }) = _$MonitorModelImpl;

  factory _MonitorModel.fromJson(Map<String, dynamic> json) =
      _$MonitorModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  Map<String, dynamic> get filtersJson;
  @override
  MonitorFrequency get frequency;
  @override
  int get minScore;
  @override
  bool get isActive;
  @override
  DateTime? get nextRunAt;
  @override
  DateTime? get lastRunAt;
  @override
  DateTime get createdAt;

  /// Create a copy of MonitorModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MonitorModelImplCopyWith<_$MonitorModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MonitorResult _$MonitorResultFromJson(Map<String, dynamic> json) {
  return _MonitorResult.fromJson(json);
}

/// @nodoc
mixin _$MonitorResult {
  String get monitorId => throw _privateConstructorUsedError;
  DateTime get runAt => throw _privateConstructorUsedError;
  int get newCount => throw _privateConstructorUsedError;
  List<String> get opportunityIds => throw _privateConstructorUsedError;

  /// Serializes this MonitorResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MonitorResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MonitorResultCopyWith<MonitorResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MonitorResultCopyWith<$Res> {
  factory $MonitorResultCopyWith(
    MonitorResult value,
    $Res Function(MonitorResult) then,
  ) = _$MonitorResultCopyWithImpl<$Res, MonitorResult>;
  @useResult
  $Res call({
    String monitorId,
    DateTime runAt,
    int newCount,
    List<String> opportunityIds,
  });
}

/// @nodoc
class _$MonitorResultCopyWithImpl<$Res, $Val extends MonitorResult>
    implements $MonitorResultCopyWith<$Res> {
  _$MonitorResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MonitorResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? monitorId = null,
    Object? runAt = null,
    Object? newCount = null,
    Object? opportunityIds = null,
  }) {
    return _then(
      _value.copyWith(
            monitorId: null == monitorId
                ? _value.monitorId
                : monitorId // ignore: cast_nullable_to_non_nullable
                      as String,
            runAt: null == runAt
                ? _value.runAt
                : runAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            newCount: null == newCount
                ? _value.newCount
                : newCount // ignore: cast_nullable_to_non_nullable
                      as int,
            opportunityIds: null == opportunityIds
                ? _value.opportunityIds
                : opportunityIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MonitorResultImplCopyWith<$Res>
    implements $MonitorResultCopyWith<$Res> {
  factory _$$MonitorResultImplCopyWith(
    _$MonitorResultImpl value,
    $Res Function(_$MonitorResultImpl) then,
  ) = __$$MonitorResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String monitorId,
    DateTime runAt,
    int newCount,
    List<String> opportunityIds,
  });
}

/// @nodoc
class __$$MonitorResultImplCopyWithImpl<$Res>
    extends _$MonitorResultCopyWithImpl<$Res, _$MonitorResultImpl>
    implements _$$MonitorResultImplCopyWith<$Res> {
  __$$MonitorResultImplCopyWithImpl(
    _$MonitorResultImpl _value,
    $Res Function(_$MonitorResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MonitorResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? monitorId = null,
    Object? runAt = null,
    Object? newCount = null,
    Object? opportunityIds = null,
  }) {
    return _then(
      _$MonitorResultImpl(
        monitorId: null == monitorId
            ? _value.monitorId
            : monitorId // ignore: cast_nullable_to_non_nullable
                  as String,
        runAt: null == runAt
            ? _value.runAt
            : runAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        newCount: null == newCount
            ? _value.newCount
            : newCount // ignore: cast_nullable_to_non_nullable
                  as int,
        opportunityIds: null == opportunityIds
            ? _value._opportunityIds
            : opportunityIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MonitorResultImpl implements _MonitorResult {
  const _$MonitorResultImpl({
    required this.monitorId,
    required this.runAt,
    required this.newCount,
    required final List<String> opportunityIds,
  }) : _opportunityIds = opportunityIds;

  factory _$MonitorResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$MonitorResultImplFromJson(json);

  @override
  final String monitorId;
  @override
  final DateTime runAt;
  @override
  final int newCount;
  final List<String> _opportunityIds;
  @override
  List<String> get opportunityIds {
    if (_opportunityIds is EqualUnmodifiableListView) return _opportunityIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_opportunityIds);
  }

  @override
  String toString() {
    return 'MonitorResult(monitorId: $monitorId, runAt: $runAt, newCount: $newCount, opportunityIds: $opportunityIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonitorResultImpl &&
            (identical(other.monitorId, monitorId) ||
                other.monitorId == monitorId) &&
            (identical(other.runAt, runAt) || other.runAt == runAt) &&
            (identical(other.newCount, newCount) ||
                other.newCount == newCount) &&
            const DeepCollectionEquality().equals(
              other._opportunityIds,
              _opportunityIds,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    monitorId,
    runAt,
    newCount,
    const DeepCollectionEquality().hash(_opportunityIds),
  );

  /// Create a copy of MonitorResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MonitorResultImplCopyWith<_$MonitorResultImpl> get copyWith =>
      __$$MonitorResultImplCopyWithImpl<_$MonitorResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MonitorResultImplToJson(this);
  }
}

abstract class _MonitorResult implements MonitorResult {
  const factory _MonitorResult({
    required final String monitorId,
    required final DateTime runAt,
    required final int newCount,
    required final List<String> opportunityIds,
  }) = _$MonitorResultImpl;

  factory _MonitorResult.fromJson(Map<String, dynamic> json) =
      _$MonitorResultImpl.fromJson;

  @override
  String get monitorId;
  @override
  DateTime get runAt;
  @override
  int get newCount;
  @override
  List<String> get opportunityIds;

  /// Create a copy of MonitorResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MonitorResultImplCopyWith<_$MonitorResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MonitorAlertItem _$MonitorAlertItemFromJson(Map<String, dynamic> json) {
  return _MonitorAlertItem.fromJson(json);
}

/// @nodoc
mixin _$MonitorAlertItem {
  String get opportunityTitle => throw _privateConstructorUsedError;
  int get score => throw _privateConstructorUsedError;
  DateTime? get deadline => throw _privateConstructorUsedError;
  DateTime get savedAt => throw _privateConstructorUsedError;

  /// Serializes this MonitorAlertItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MonitorAlertItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MonitorAlertItemCopyWith<MonitorAlertItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MonitorAlertItemCopyWith<$Res> {
  factory $MonitorAlertItemCopyWith(
    MonitorAlertItem value,
    $Res Function(MonitorAlertItem) then,
  ) = _$MonitorAlertItemCopyWithImpl<$Res, MonitorAlertItem>;
  @useResult
  $Res call({
    String opportunityTitle,
    int score,
    DateTime? deadline,
    DateTime savedAt,
  });
}

/// @nodoc
class _$MonitorAlertItemCopyWithImpl<$Res, $Val extends MonitorAlertItem>
    implements $MonitorAlertItemCopyWith<$Res> {
  _$MonitorAlertItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MonitorAlertItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? opportunityTitle = null,
    Object? score = null,
    Object? deadline = freezed,
    Object? savedAt = null,
  }) {
    return _then(
      _value.copyWith(
            opportunityTitle: null == opportunityTitle
                ? _value.opportunityTitle
                : opportunityTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as int,
            deadline: freezed == deadline
                ? _value.deadline
                : deadline // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            savedAt: null == savedAt
                ? _value.savedAt
                : savedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MonitorAlertItemImplCopyWith<$Res>
    implements $MonitorAlertItemCopyWith<$Res> {
  factory _$$MonitorAlertItemImplCopyWith(
    _$MonitorAlertItemImpl value,
    $Res Function(_$MonitorAlertItemImpl) then,
  ) = __$$MonitorAlertItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String opportunityTitle,
    int score,
    DateTime? deadline,
    DateTime savedAt,
  });
}

/// @nodoc
class __$$MonitorAlertItemImplCopyWithImpl<$Res>
    extends _$MonitorAlertItemCopyWithImpl<$Res, _$MonitorAlertItemImpl>
    implements _$$MonitorAlertItemImplCopyWith<$Res> {
  __$$MonitorAlertItemImplCopyWithImpl(
    _$MonitorAlertItemImpl _value,
    $Res Function(_$MonitorAlertItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MonitorAlertItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? opportunityTitle = null,
    Object? score = null,
    Object? deadline = freezed,
    Object? savedAt = null,
  }) {
    return _then(
      _$MonitorAlertItemImpl(
        opportunityTitle: null == opportunityTitle
            ? _value.opportunityTitle
            : opportunityTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as int,
        deadline: freezed == deadline
            ? _value.deadline
            : deadline // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        savedAt: null == savedAt
            ? _value.savedAt
            : savedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MonitorAlertItemImpl implements _MonitorAlertItem {
  const _$MonitorAlertItemImpl({
    required this.opportunityTitle,
    required this.score,
    this.deadline,
    required this.savedAt,
  });

  factory _$MonitorAlertItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MonitorAlertItemImplFromJson(json);

  @override
  final String opportunityTitle;
  @override
  final int score;
  @override
  final DateTime? deadline;
  @override
  final DateTime savedAt;

  @override
  String toString() {
    return 'MonitorAlertItem(opportunityTitle: $opportunityTitle, score: $score, deadline: $deadline, savedAt: $savedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonitorAlertItemImpl &&
            (identical(other.opportunityTitle, opportunityTitle) ||
                other.opportunityTitle == opportunityTitle) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.savedAt, savedAt) || other.savedAt == savedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, opportunityTitle, score, deadline, savedAt);

  /// Create a copy of MonitorAlertItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MonitorAlertItemImplCopyWith<_$MonitorAlertItemImpl> get copyWith =>
      __$$MonitorAlertItemImplCopyWithImpl<_$MonitorAlertItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MonitorAlertItemImplToJson(this);
  }
}

abstract class _MonitorAlertItem implements MonitorAlertItem {
  const factory _MonitorAlertItem({
    required final String opportunityTitle,
    required final int score,
    final DateTime? deadline,
    required final DateTime savedAt,
  }) = _$MonitorAlertItemImpl;

  factory _MonitorAlertItem.fromJson(Map<String, dynamic> json) =
      _$MonitorAlertItemImpl.fromJson;

  @override
  String get opportunityTitle;
  @override
  int get score;
  @override
  DateTime? get deadline;
  @override
  DateTime get savedAt;

  /// Create a copy of MonitorAlertItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MonitorAlertItemImplCopyWith<_$MonitorAlertItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
