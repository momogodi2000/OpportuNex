// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'application_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ApplicationListItem _$ApplicationListItemFromJson(Map<String, dynamic> json) {
  return _ApplicationListItem.fromJson(json);
}

/// @nodoc
mixin _$ApplicationListItem {
  String get id => throw _privateConstructorUsedError;
  String get savedOpportunityId => throw _privateConstructorUsedError;
  String get opportunityTitle => throw _privateConstructorUsedError;
  DateTime get opportunityDeadline => throw _privateConstructorUsedError;
  ApplicationStatus get status => throw _privateConstructorUsedError;
  String get priority =>
      throw _privateConstructorUsedError; // high, medium, low
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ApplicationListItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApplicationListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApplicationListItemCopyWith<ApplicationListItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApplicationListItemCopyWith<$Res> {
  factory $ApplicationListItemCopyWith(
    ApplicationListItem value,
    $Res Function(ApplicationListItem) then,
  ) = _$ApplicationListItemCopyWithImpl<$Res, ApplicationListItem>;
  @useResult
  $Res call({
    String id,
    String savedOpportunityId,
    String opportunityTitle,
    DateTime opportunityDeadline,
    ApplicationStatus status,
    String priority,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$ApplicationListItemCopyWithImpl<$Res, $Val extends ApplicationListItem>
    implements $ApplicationListItemCopyWith<$Res> {
  _$ApplicationListItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApplicationListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? savedOpportunityId = null,
    Object? opportunityTitle = null,
    Object? opportunityDeadline = null,
    Object? status = null,
    Object? priority = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            savedOpportunityId: null == savedOpportunityId
                ? _value.savedOpportunityId
                : savedOpportunityId // ignore: cast_nullable_to_non_nullable
                      as String,
            opportunityTitle: null == opportunityTitle
                ? _value.opportunityTitle
                : opportunityTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            opportunityDeadline: null == opportunityDeadline
                ? _value.opportunityDeadline
                : opportunityDeadline // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ApplicationStatus,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as String,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ApplicationListItemImplCopyWith<$Res>
    implements $ApplicationListItemCopyWith<$Res> {
  factory _$$ApplicationListItemImplCopyWith(
    _$ApplicationListItemImpl value,
    $Res Function(_$ApplicationListItemImpl) then,
  ) = __$$ApplicationListItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String savedOpportunityId,
    String opportunityTitle,
    DateTime opportunityDeadline,
    ApplicationStatus status,
    String priority,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$ApplicationListItemImplCopyWithImpl<$Res>
    extends _$ApplicationListItemCopyWithImpl<$Res, _$ApplicationListItemImpl>
    implements _$$ApplicationListItemImplCopyWith<$Res> {
  __$$ApplicationListItemImplCopyWithImpl(
    _$ApplicationListItemImpl _value,
    $Res Function(_$ApplicationListItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApplicationListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? savedOpportunityId = null,
    Object? opportunityTitle = null,
    Object? opportunityDeadline = null,
    Object? status = null,
    Object? priority = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$ApplicationListItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        savedOpportunityId: null == savedOpportunityId
            ? _value.savedOpportunityId
            : savedOpportunityId // ignore: cast_nullable_to_non_nullable
                  as String,
        opportunityTitle: null == opportunityTitle
            ? _value.opportunityTitle
            : opportunityTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        opportunityDeadline: null == opportunityDeadline
            ? _value.opportunityDeadline
            : opportunityDeadline // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ApplicationStatus,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as String,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ApplicationListItemImpl implements _ApplicationListItem {
  const _$ApplicationListItemImpl({
    required this.id,
    required this.savedOpportunityId,
    required this.opportunityTitle,
    required this.opportunityDeadline,
    required this.status,
    required this.priority,
    required this.updatedAt,
  });

  factory _$ApplicationListItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApplicationListItemImplFromJson(json);

  @override
  final String id;
  @override
  final String savedOpportunityId;
  @override
  final String opportunityTitle;
  @override
  final DateTime opportunityDeadline;
  @override
  final ApplicationStatus status;
  @override
  final String priority;
  // high, medium, low
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ApplicationListItem(id: $id, savedOpportunityId: $savedOpportunityId, opportunityTitle: $opportunityTitle, opportunityDeadline: $opportunityDeadline, status: $status, priority: $priority, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApplicationListItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.savedOpportunityId, savedOpportunityId) ||
                other.savedOpportunityId == savedOpportunityId) &&
            (identical(other.opportunityTitle, opportunityTitle) ||
                other.opportunityTitle == opportunityTitle) &&
            (identical(other.opportunityDeadline, opportunityDeadline) ||
                other.opportunityDeadline == opportunityDeadline) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    savedOpportunityId,
    opportunityTitle,
    opportunityDeadline,
    status,
    priority,
    updatedAt,
  );

  /// Create a copy of ApplicationListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApplicationListItemImplCopyWith<_$ApplicationListItemImpl> get copyWith =>
      __$$ApplicationListItemImplCopyWithImpl<_$ApplicationListItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ApplicationListItemImplToJson(this);
  }
}

abstract class _ApplicationListItem implements ApplicationListItem {
  const factory _ApplicationListItem({
    required final String id,
    required final String savedOpportunityId,
    required final String opportunityTitle,
    required final DateTime opportunityDeadline,
    required final ApplicationStatus status,
    required final String priority,
    required final DateTime updatedAt,
  }) = _$ApplicationListItemImpl;

  factory _ApplicationListItem.fromJson(Map<String, dynamic> json) =
      _$ApplicationListItemImpl.fromJson;

  @override
  String get id;
  @override
  String get savedOpportunityId;
  @override
  String get opportunityTitle;
  @override
  DateTime get opportunityDeadline;
  @override
  ApplicationStatus get status;
  @override
  String get priority; // high, medium, low
  @override
  DateTime get updatedAt;

  /// Create a copy of ApplicationListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApplicationListItemImplCopyWith<_$ApplicationListItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StatusHistoryEntry _$StatusHistoryEntryFromJson(Map<String, dynamic> json) {
  return _StatusHistoryEntry.fromJson(json);
}

/// @nodoc
mixin _$StatusHistoryEntry {
  ApplicationStatus get oldStatus => throw _privateConstructorUsedError;
  ApplicationStatus get newStatus => throw _privateConstructorUsedError;
  DateTime get changedAt => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  /// Serializes this StatusHistoryEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StatusHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StatusHistoryEntryCopyWith<StatusHistoryEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StatusHistoryEntryCopyWith<$Res> {
  factory $StatusHistoryEntryCopyWith(
    StatusHistoryEntry value,
    $Res Function(StatusHistoryEntry) then,
  ) = _$StatusHistoryEntryCopyWithImpl<$Res, StatusHistoryEntry>;
  @useResult
  $Res call({
    ApplicationStatus oldStatus,
    ApplicationStatus newStatus,
    DateTime changedAt,
    String? note,
  });
}

/// @nodoc
class _$StatusHistoryEntryCopyWithImpl<$Res, $Val extends StatusHistoryEntry>
    implements $StatusHistoryEntryCopyWith<$Res> {
  _$StatusHistoryEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StatusHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? oldStatus = null,
    Object? newStatus = null,
    Object? changedAt = null,
    Object? note = freezed,
  }) {
    return _then(
      _value.copyWith(
            oldStatus: null == oldStatus
                ? _value.oldStatus
                : oldStatus // ignore: cast_nullable_to_non_nullable
                      as ApplicationStatus,
            newStatus: null == newStatus
                ? _value.newStatus
                : newStatus // ignore: cast_nullable_to_non_nullable
                      as ApplicationStatus,
            changedAt: null == changedAt
                ? _value.changedAt
                : changedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StatusHistoryEntryImplCopyWith<$Res>
    implements $StatusHistoryEntryCopyWith<$Res> {
  factory _$$StatusHistoryEntryImplCopyWith(
    _$StatusHistoryEntryImpl value,
    $Res Function(_$StatusHistoryEntryImpl) then,
  ) = __$$StatusHistoryEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    ApplicationStatus oldStatus,
    ApplicationStatus newStatus,
    DateTime changedAt,
    String? note,
  });
}

/// @nodoc
class __$$StatusHistoryEntryImplCopyWithImpl<$Res>
    extends _$StatusHistoryEntryCopyWithImpl<$Res, _$StatusHistoryEntryImpl>
    implements _$$StatusHistoryEntryImplCopyWith<$Res> {
  __$$StatusHistoryEntryImplCopyWithImpl(
    _$StatusHistoryEntryImpl _value,
    $Res Function(_$StatusHistoryEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StatusHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? oldStatus = null,
    Object? newStatus = null,
    Object? changedAt = null,
    Object? note = freezed,
  }) {
    return _then(
      _$StatusHistoryEntryImpl(
        oldStatus: null == oldStatus
            ? _value.oldStatus
            : oldStatus // ignore: cast_nullable_to_non_nullable
                  as ApplicationStatus,
        newStatus: null == newStatus
            ? _value.newStatus
            : newStatus // ignore: cast_nullable_to_non_nullable
                  as ApplicationStatus,
        changedAt: null == changedAt
            ? _value.changedAt
            : changedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StatusHistoryEntryImpl implements _StatusHistoryEntry {
  const _$StatusHistoryEntryImpl({
    required this.oldStatus,
    required this.newStatus,
    required this.changedAt,
    this.note,
  });

  factory _$StatusHistoryEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$StatusHistoryEntryImplFromJson(json);

  @override
  final ApplicationStatus oldStatus;
  @override
  final ApplicationStatus newStatus;
  @override
  final DateTime changedAt;
  @override
  final String? note;

  @override
  String toString() {
    return 'StatusHistoryEntry(oldStatus: $oldStatus, newStatus: $newStatus, changedAt: $changedAt, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StatusHistoryEntryImpl &&
            (identical(other.oldStatus, oldStatus) ||
                other.oldStatus == oldStatus) &&
            (identical(other.newStatus, newStatus) ||
                other.newStatus == newStatus) &&
            (identical(other.changedAt, changedAt) ||
                other.changedAt == changedAt) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, oldStatus, newStatus, changedAt, note);

  /// Create a copy of StatusHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StatusHistoryEntryImplCopyWith<_$StatusHistoryEntryImpl> get copyWith =>
      __$$StatusHistoryEntryImplCopyWithImpl<_$StatusHistoryEntryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StatusHistoryEntryImplToJson(this);
  }
}

abstract class _StatusHistoryEntry implements StatusHistoryEntry {
  const factory _StatusHistoryEntry({
    required final ApplicationStatus oldStatus,
    required final ApplicationStatus newStatus,
    required final DateTime changedAt,
    final String? note,
  }) = _$StatusHistoryEntryImpl;

  factory _StatusHistoryEntry.fromJson(Map<String, dynamic> json) =
      _$StatusHistoryEntryImpl.fromJson;

  @override
  ApplicationStatus get oldStatus;
  @override
  ApplicationStatus get newStatus;
  @override
  DateTime get changedAt;
  @override
  String? get note;

  /// Create a copy of StatusHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StatusHistoryEntryImplCopyWith<_$StatusHistoryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AppDocument _$AppDocumentFromJson(Map<String, dynamic> json) {
  return _AppDocument.fromJson(json);
}

/// @nodoc
mixin _$AppDocument {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  DateTime get uploadedAt => throw _privateConstructorUsedError;

  /// Serializes this AppDocument to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppDocument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppDocumentCopyWith<AppDocument> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppDocumentCopyWith<$Res> {
  factory $AppDocumentCopyWith(
    AppDocument value,
    $Res Function(AppDocument) then,
  ) = _$AppDocumentCopyWithImpl<$Res, AppDocument>;
  @useResult
  $Res call({String id, String name, String url, DateTime uploadedAt});
}

/// @nodoc
class _$AppDocumentCopyWithImpl<$Res, $Val extends AppDocument>
    implements $AppDocumentCopyWith<$Res> {
  _$AppDocumentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppDocument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? url = null,
    Object? uploadedAt = null,
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
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            uploadedAt: null == uploadedAt
                ? _value.uploadedAt
                : uploadedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppDocumentImplCopyWith<$Res>
    implements $AppDocumentCopyWith<$Res> {
  factory _$$AppDocumentImplCopyWith(
    _$AppDocumentImpl value,
    $Res Function(_$AppDocumentImpl) then,
  ) = __$$AppDocumentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String url, DateTime uploadedAt});
}

/// @nodoc
class __$$AppDocumentImplCopyWithImpl<$Res>
    extends _$AppDocumentCopyWithImpl<$Res, _$AppDocumentImpl>
    implements _$$AppDocumentImplCopyWith<$Res> {
  __$$AppDocumentImplCopyWithImpl(
    _$AppDocumentImpl _value,
    $Res Function(_$AppDocumentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppDocument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? url = null,
    Object? uploadedAt = null,
  }) {
    return _then(
      _$AppDocumentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        uploadedAt: null == uploadedAt
            ? _value.uploadedAt
            : uploadedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppDocumentImpl implements _AppDocument {
  const _$AppDocumentImpl({
    required this.id,
    required this.name,
    required this.url,
    required this.uploadedAt,
  });

  factory _$AppDocumentImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppDocumentImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String url;
  @override
  final DateTime uploadedAt;

  @override
  String toString() {
    return 'AppDocument(id: $id, name: $name, url: $url, uploadedAt: $uploadedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppDocumentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.uploadedAt, uploadedAt) ||
                other.uploadedAt == uploadedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, url, uploadedAt);

  /// Create a copy of AppDocument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppDocumentImplCopyWith<_$AppDocumentImpl> get copyWith =>
      __$$AppDocumentImplCopyWithImpl<_$AppDocumentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppDocumentImplToJson(this);
  }
}

abstract class _AppDocument implements AppDocument {
  const factory _AppDocument({
    required final String id,
    required final String name,
    required final String url,
    required final DateTime uploadedAt,
  }) = _$AppDocumentImpl;

  factory _AppDocument.fromJson(Map<String, dynamic> json) =
      _$AppDocumentImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get url;
  @override
  DateTime get uploadedAt;

  /// Create a copy of AppDocument
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppDocumentImplCopyWith<_$AppDocumentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AppNote _$AppNoteFromJson(Map<String, dynamic> json) {
  return _AppNote.fromJson(json);
}

/// @nodoc
mixin _$AppNote {
  String get id => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this AppNote to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppNote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppNoteCopyWith<AppNote> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppNoteCopyWith<$Res> {
  factory $AppNoteCopyWith(AppNote value, $Res Function(AppNote) then) =
      _$AppNoteCopyWithImpl<$Res, AppNote>;
  @useResult
  $Res call({String id, String content, DateTime createdAt});
}

/// @nodoc
class _$AppNoteCopyWithImpl<$Res, $Val extends AppNote>
    implements $AppNoteCopyWith<$Res> {
  _$AppNoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppNote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
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
abstract class _$$AppNoteImplCopyWith<$Res> implements $AppNoteCopyWith<$Res> {
  factory _$$AppNoteImplCopyWith(
    _$AppNoteImpl value,
    $Res Function(_$AppNoteImpl) then,
  ) = __$$AppNoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String content, DateTime createdAt});
}

/// @nodoc
class __$$AppNoteImplCopyWithImpl<$Res>
    extends _$AppNoteCopyWithImpl<$Res, _$AppNoteImpl>
    implements _$$AppNoteImplCopyWith<$Res> {
  __$$AppNoteImplCopyWithImpl(
    _$AppNoteImpl _value,
    $Res Function(_$AppNoteImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppNote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$AppNoteImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
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
class _$AppNoteImpl implements _AppNote {
  const _$AppNoteImpl({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  factory _$AppNoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppNoteImplFromJson(json);

  @override
  final String id;
  @override
  final String content;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'AppNote(id: $id, content: $content, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppNoteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, content, createdAt);

  /// Create a copy of AppNote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppNoteImplCopyWith<_$AppNoteImpl> get copyWith =>
      __$$AppNoteImplCopyWithImpl<_$AppNoteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppNoteImplToJson(this);
  }
}

abstract class _AppNote implements AppNote {
  const factory _AppNote({
    required final String id,
    required final String content,
    required final DateTime createdAt,
  }) = _$AppNoteImpl;

  factory _AppNote.fromJson(Map<String, dynamic> json) = _$AppNoteImpl.fromJson;

  @override
  String get id;
  @override
  String get content;
  @override
  DateTime get createdAt;

  /// Create a copy of AppNote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppNoteImplCopyWith<_$AppNoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ApplicationDetail _$ApplicationDetailFromJson(Map<String, dynamic> json) {
  return _ApplicationDetail.fromJson(json);
}

/// @nodoc
mixin _$ApplicationDetail {
  String get id => throw _privateConstructorUsedError;
  String get savedOpportunityId => throw _privateConstructorUsedError;
  String get opportunityTitle => throw _privateConstructorUsedError;
  DateTime get opportunityDeadline => throw _privateConstructorUsedError;
  ApplicationStatus get status => throw _privateConstructorUsedError;
  String get priority => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  List<StatusHistoryEntry> get statusHistory =>
      throw _privateConstructorUsedError;
  List<AppDocument> get documents => throw _privateConstructorUsedError;
  List<AppNote> get notes => throw _privateConstructorUsedError;

  /// Serializes this ApplicationDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApplicationDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApplicationDetailCopyWith<ApplicationDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApplicationDetailCopyWith<$Res> {
  factory $ApplicationDetailCopyWith(
    ApplicationDetail value,
    $Res Function(ApplicationDetail) then,
  ) = _$ApplicationDetailCopyWithImpl<$Res, ApplicationDetail>;
  @useResult
  $Res call({
    String id,
    String savedOpportunityId,
    String opportunityTitle,
    DateTime opportunityDeadline,
    ApplicationStatus status,
    String priority,
    DateTime updatedAt,
    List<StatusHistoryEntry> statusHistory,
    List<AppDocument> documents,
    List<AppNote> notes,
  });
}

/// @nodoc
class _$ApplicationDetailCopyWithImpl<$Res, $Val extends ApplicationDetail>
    implements $ApplicationDetailCopyWith<$Res> {
  _$ApplicationDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApplicationDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? savedOpportunityId = null,
    Object? opportunityTitle = null,
    Object? opportunityDeadline = null,
    Object? status = null,
    Object? priority = null,
    Object? updatedAt = null,
    Object? statusHistory = null,
    Object? documents = null,
    Object? notes = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            savedOpportunityId: null == savedOpportunityId
                ? _value.savedOpportunityId
                : savedOpportunityId // ignore: cast_nullable_to_non_nullable
                      as String,
            opportunityTitle: null == opportunityTitle
                ? _value.opportunityTitle
                : opportunityTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            opportunityDeadline: null == opportunityDeadline
                ? _value.opportunityDeadline
                : opportunityDeadline // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ApplicationStatus,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as String,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            statusHistory: null == statusHistory
                ? _value.statusHistory
                : statusHistory // ignore: cast_nullable_to_non_nullable
                      as List<StatusHistoryEntry>,
            documents: null == documents
                ? _value.documents
                : documents // ignore: cast_nullable_to_non_nullable
                      as List<AppDocument>,
            notes: null == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as List<AppNote>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ApplicationDetailImplCopyWith<$Res>
    implements $ApplicationDetailCopyWith<$Res> {
  factory _$$ApplicationDetailImplCopyWith(
    _$ApplicationDetailImpl value,
    $Res Function(_$ApplicationDetailImpl) then,
  ) = __$$ApplicationDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String savedOpportunityId,
    String opportunityTitle,
    DateTime opportunityDeadline,
    ApplicationStatus status,
    String priority,
    DateTime updatedAt,
    List<StatusHistoryEntry> statusHistory,
    List<AppDocument> documents,
    List<AppNote> notes,
  });
}

/// @nodoc
class __$$ApplicationDetailImplCopyWithImpl<$Res>
    extends _$ApplicationDetailCopyWithImpl<$Res, _$ApplicationDetailImpl>
    implements _$$ApplicationDetailImplCopyWith<$Res> {
  __$$ApplicationDetailImplCopyWithImpl(
    _$ApplicationDetailImpl _value,
    $Res Function(_$ApplicationDetailImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApplicationDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? savedOpportunityId = null,
    Object? opportunityTitle = null,
    Object? opportunityDeadline = null,
    Object? status = null,
    Object? priority = null,
    Object? updatedAt = null,
    Object? statusHistory = null,
    Object? documents = null,
    Object? notes = null,
  }) {
    return _then(
      _$ApplicationDetailImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        savedOpportunityId: null == savedOpportunityId
            ? _value.savedOpportunityId
            : savedOpportunityId // ignore: cast_nullable_to_non_nullable
                  as String,
        opportunityTitle: null == opportunityTitle
            ? _value.opportunityTitle
            : opportunityTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        opportunityDeadline: null == opportunityDeadline
            ? _value.opportunityDeadline
            : opportunityDeadline // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ApplicationStatus,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as String,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        statusHistory: null == statusHistory
            ? _value._statusHistory
            : statusHistory // ignore: cast_nullable_to_non_nullable
                  as List<StatusHistoryEntry>,
        documents: null == documents
            ? _value._documents
            : documents // ignore: cast_nullable_to_non_nullable
                  as List<AppDocument>,
        notes: null == notes
            ? _value._notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as List<AppNote>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ApplicationDetailImpl implements _ApplicationDetail {
  const _$ApplicationDetailImpl({
    required this.id,
    required this.savedOpportunityId,
    required this.opportunityTitle,
    required this.opportunityDeadline,
    required this.status,
    required this.priority,
    required this.updatedAt,
    final List<StatusHistoryEntry> statusHistory = const [],
    final List<AppDocument> documents = const [],
    final List<AppNote> notes = const [],
  }) : _statusHistory = statusHistory,
       _documents = documents,
       _notes = notes;

  factory _$ApplicationDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApplicationDetailImplFromJson(json);

  @override
  final String id;
  @override
  final String savedOpportunityId;
  @override
  final String opportunityTitle;
  @override
  final DateTime opportunityDeadline;
  @override
  final ApplicationStatus status;
  @override
  final String priority;
  @override
  final DateTime updatedAt;
  final List<StatusHistoryEntry> _statusHistory;
  @override
  @JsonKey()
  List<StatusHistoryEntry> get statusHistory {
    if (_statusHistory is EqualUnmodifiableListView) return _statusHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_statusHistory);
  }

  final List<AppDocument> _documents;
  @override
  @JsonKey()
  List<AppDocument> get documents {
    if (_documents is EqualUnmodifiableListView) return _documents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_documents);
  }

  final List<AppNote> _notes;
  @override
  @JsonKey()
  List<AppNote> get notes {
    if (_notes is EqualUnmodifiableListView) return _notes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notes);
  }

  @override
  String toString() {
    return 'ApplicationDetail(id: $id, savedOpportunityId: $savedOpportunityId, opportunityTitle: $opportunityTitle, opportunityDeadline: $opportunityDeadline, status: $status, priority: $priority, updatedAt: $updatedAt, statusHistory: $statusHistory, documents: $documents, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApplicationDetailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.savedOpportunityId, savedOpportunityId) ||
                other.savedOpportunityId == savedOpportunityId) &&
            (identical(other.opportunityTitle, opportunityTitle) ||
                other.opportunityTitle == opportunityTitle) &&
            (identical(other.opportunityDeadline, opportunityDeadline) ||
                other.opportunityDeadline == opportunityDeadline) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(
              other._statusHistory,
              _statusHistory,
            ) &&
            const DeepCollectionEquality().equals(
              other._documents,
              _documents,
            ) &&
            const DeepCollectionEquality().equals(other._notes, _notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    savedOpportunityId,
    opportunityTitle,
    opportunityDeadline,
    status,
    priority,
    updatedAt,
    const DeepCollectionEquality().hash(_statusHistory),
    const DeepCollectionEquality().hash(_documents),
    const DeepCollectionEquality().hash(_notes),
  );

  /// Create a copy of ApplicationDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApplicationDetailImplCopyWith<_$ApplicationDetailImpl> get copyWith =>
      __$$ApplicationDetailImplCopyWithImpl<_$ApplicationDetailImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ApplicationDetailImplToJson(this);
  }
}

abstract class _ApplicationDetail implements ApplicationDetail {
  const factory _ApplicationDetail({
    required final String id,
    required final String savedOpportunityId,
    required final String opportunityTitle,
    required final DateTime opportunityDeadline,
    required final ApplicationStatus status,
    required final String priority,
    required final DateTime updatedAt,
    final List<StatusHistoryEntry> statusHistory,
    final List<AppDocument> documents,
    final List<AppNote> notes,
  }) = _$ApplicationDetailImpl;

  factory _ApplicationDetail.fromJson(Map<String, dynamic> json) =
      _$ApplicationDetailImpl.fromJson;

  @override
  String get id;
  @override
  String get savedOpportunityId;
  @override
  String get opportunityTitle;
  @override
  DateTime get opportunityDeadline;
  @override
  ApplicationStatus get status;
  @override
  String get priority;
  @override
  DateTime get updatedAt;
  @override
  List<StatusHistoryEntry> get statusHistory;
  @override
  List<AppDocument> get documents;
  @override
  List<AppNote> get notes;

  /// Create a copy of ApplicationDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApplicationDetailImplCopyWith<_$ApplicationDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CalendarEvent _$CalendarEventFromJson(Map<String, dynamic> json) {
  return _CalendarEvent.fromJson(json);
}

/// @nodoc
mixin _$CalendarEvent {
  DateTime get date => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get applicationId => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;

  /// Serializes this CalendarEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CalendarEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CalendarEventCopyWith<CalendarEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CalendarEventCopyWith<$Res> {
  factory $CalendarEventCopyWith(
    CalendarEvent value,
    $Res Function(CalendarEvent) then,
  ) = _$CalendarEventCopyWithImpl<$Res, CalendarEvent>;
  @useResult
  $Res call({DateTime date, String title, String applicationId, String type});
}

/// @nodoc
class _$CalendarEventCopyWithImpl<$Res, $Val extends CalendarEvent>
    implements $CalendarEventCopyWith<$Res> {
  _$CalendarEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CalendarEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? title = null,
    Object? applicationId = null,
    Object? type = null,
  }) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            applicationId: null == applicationId
                ? _value.applicationId
                : applicationId // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CalendarEventImplCopyWith<$Res>
    implements $CalendarEventCopyWith<$Res> {
  factory _$$CalendarEventImplCopyWith(
    _$CalendarEventImpl value,
    $Res Function(_$CalendarEventImpl) then,
  ) = __$$CalendarEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime date, String title, String applicationId, String type});
}

/// @nodoc
class __$$CalendarEventImplCopyWithImpl<$Res>
    extends _$CalendarEventCopyWithImpl<$Res, _$CalendarEventImpl>
    implements _$$CalendarEventImplCopyWith<$Res> {
  __$$CalendarEventImplCopyWithImpl(
    _$CalendarEventImpl _value,
    $Res Function(_$CalendarEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CalendarEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? title = null,
    Object? applicationId = null,
    Object? type = null,
  }) {
    return _then(
      _$CalendarEventImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        applicationId: null == applicationId
            ? _value.applicationId
            : applicationId // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CalendarEventImpl implements _CalendarEvent {
  const _$CalendarEventImpl({
    required this.date,
    required this.title,
    required this.applicationId,
    required this.type,
  });

  factory _$CalendarEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$CalendarEventImplFromJson(json);

  @override
  final DateTime date;
  @override
  final String title;
  @override
  final String applicationId;
  @override
  final String type;

  @override
  String toString() {
    return 'CalendarEvent(date: $date, title: $title, applicationId: $applicationId, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CalendarEventImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.applicationId, applicationId) ||
                other.applicationId == applicationId) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, date, title, applicationId, type);

  /// Create a copy of CalendarEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CalendarEventImplCopyWith<_$CalendarEventImpl> get copyWith =>
      __$$CalendarEventImplCopyWithImpl<_$CalendarEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CalendarEventImplToJson(this);
  }
}

abstract class _CalendarEvent implements CalendarEvent {
  const factory _CalendarEvent({
    required final DateTime date,
    required final String title,
    required final String applicationId,
    required final String type,
  }) = _$CalendarEventImpl;

  factory _CalendarEvent.fromJson(Map<String, dynamic> json) =
      _$CalendarEventImpl.fromJson;

  @override
  DateTime get date;
  @override
  String get title;
  @override
  String get applicationId;
  @override
  String get type;

  /// Create a copy of CalendarEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CalendarEventImplCopyWith<_$CalendarEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
