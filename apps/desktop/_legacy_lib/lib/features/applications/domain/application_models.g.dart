// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ApplicationListItemImpl _$$ApplicationListItemImplFromJson(
  Map<String, dynamic> json,
) => _$ApplicationListItemImpl(
  id: json['id'] as String,
  savedOpportunityId: json['savedOpportunityId'] as String,
  opportunityTitle: json['opportunityTitle'] as String,
  opportunityDeadline: DateTime.parse(json['opportunityDeadline'] as String),
  status: $enumDecode(_$ApplicationStatusEnumMap, json['status']),
  priority: json['priority'] as String,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$ApplicationListItemImplToJson(
  _$ApplicationListItemImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'savedOpportunityId': instance.savedOpportunityId,
  'opportunityTitle': instance.opportunityTitle,
  'opportunityDeadline': instance.opportunityDeadline.toIso8601String(),
  'status': _$ApplicationStatusEnumMap[instance.status]!,
  'priority': instance.priority,
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$ApplicationStatusEnumMap = {
  ApplicationStatus.toReview: 'toReview',
  ApplicationStatus.inPreparation: 'inPreparation',
  ApplicationStatus.submitted: 'submitted',
  ApplicationStatus.accepted: 'accepted',
  ApplicationStatus.rejected: 'rejected',
  ApplicationStatus.archived: 'archived',
  ApplicationStatus.interview: 'interview',
  ApplicationStatus.withdrawn: 'withdrawn',
  ApplicationStatus.onHold: 'onHold',
  ApplicationStatus.waitlisted: 'waitlisted',
  ApplicationStatus.offerReceived: 'offerReceived',
};

_$StatusHistoryEntryImpl _$$StatusHistoryEntryImplFromJson(
  Map<String, dynamic> json,
) => _$StatusHistoryEntryImpl(
  oldStatus: $enumDecode(_$ApplicationStatusEnumMap, json['oldStatus']),
  newStatus: $enumDecode(_$ApplicationStatusEnumMap, json['newStatus']),
  changedAt: DateTime.parse(json['changedAt'] as String),
  note: json['note'] as String?,
);

Map<String, dynamic> _$$StatusHistoryEntryImplToJson(
  _$StatusHistoryEntryImpl instance,
) => <String, dynamic>{
  'oldStatus': _$ApplicationStatusEnumMap[instance.oldStatus]!,
  'newStatus': _$ApplicationStatusEnumMap[instance.newStatus]!,
  'changedAt': instance.changedAt.toIso8601String(),
  'note': instance.note,
};

_$AppDocumentImpl _$$AppDocumentImplFromJson(Map<String, dynamic> json) =>
    _$AppDocumentImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );

Map<String, dynamic> _$$AppDocumentImplToJson(_$AppDocumentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'url': instance.url,
      'uploadedAt': instance.uploadedAt.toIso8601String(),
    };

_$AppNoteImpl _$$AppNoteImplFromJson(Map<String, dynamic> json) =>
    _$AppNoteImpl(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$AppNoteImplToJson(_$AppNoteImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_$ApplicationDetailImpl _$$ApplicationDetailImplFromJson(
  Map<String, dynamic> json,
) => _$ApplicationDetailImpl(
  id: json['id'] as String,
  savedOpportunityId: json['savedOpportunityId'] as String,
  opportunityTitle: json['opportunityTitle'] as String,
  opportunityDeadline: DateTime.parse(json['opportunityDeadline'] as String),
  status: $enumDecode(_$ApplicationStatusEnumMap, json['status']),
  priority: json['priority'] as String,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  statusHistory:
      (json['statusHistory'] as List<dynamic>?)
          ?.map((e) => StatusHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  documents:
      (json['documents'] as List<dynamic>?)
          ?.map((e) => AppDocument.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  notes:
      (json['notes'] as List<dynamic>?)
          ?.map((e) => AppNote.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$ApplicationDetailImplToJson(
  _$ApplicationDetailImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'savedOpportunityId': instance.savedOpportunityId,
  'opportunityTitle': instance.opportunityTitle,
  'opportunityDeadline': instance.opportunityDeadline.toIso8601String(),
  'status': _$ApplicationStatusEnumMap[instance.status]!,
  'priority': instance.priority,
  'updatedAt': instance.updatedAt.toIso8601String(),
  'statusHistory': instance.statusHistory,
  'documents': instance.documents,
  'notes': instance.notes,
};

_$CalendarEventImpl _$$CalendarEventImplFromJson(Map<String, dynamic> json) =>
    _$CalendarEventImpl(
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String,
      applicationId: json['applicationId'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$$CalendarEventImplToJson(_$CalendarEventImpl instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'title': instance.title,
      'applicationId': instance.applicationId,
      'type': instance.type,
    };
