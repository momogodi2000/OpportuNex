// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monitor_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MonitorModelImpl _$$MonitorModelImplFromJson(Map<String, dynamic> json) =>
    _$MonitorModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      filtersJson: json['filtersJson'] as Map<String, dynamic>,
      frequency: $enumDecode(_$MonitorFrequencyEnumMap, json['frequency']),
      minScore: (json['minScore'] as num).toInt(),
      isActive: json['isActive'] as bool? ?? true,
      nextRunAt: json['nextRunAt'] == null
          ? null
          : DateTime.parse(json['nextRunAt'] as String),
      lastRunAt: json['lastRunAt'] == null
          ? null
          : DateTime.parse(json['lastRunAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$MonitorModelImplToJson(_$MonitorModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'filtersJson': instance.filtersJson,
      'frequency': _$MonitorFrequencyEnumMap[instance.frequency]!,
      'minScore': instance.minScore,
      'isActive': instance.isActive,
      'nextRunAt': instance.nextRunAt?.toIso8601String(),
      'lastRunAt': instance.lastRunAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$MonitorFrequencyEnumMap = {
  MonitorFrequency.daily: 'daily',
  MonitorFrequency.weekly: 'weekly',
  MonitorFrequency.custom: 'custom',
};

_$MonitorResultImpl _$$MonitorResultImplFromJson(Map<String, dynamic> json) =>
    _$MonitorResultImpl(
      monitorId: json['monitorId'] as String,
      runAt: DateTime.parse(json['runAt'] as String),
      newCount: (json['newCount'] as num).toInt(),
      opportunityIds: (json['opportunityIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$MonitorResultImplToJson(_$MonitorResultImpl instance) =>
    <String, dynamic>{
      'monitorId': instance.monitorId,
      'runAt': instance.runAt.toIso8601String(),
      'newCount': instance.newCount,
      'opportunityIds': instance.opportunityIds,
    };

_$MonitorAlertItemImpl _$$MonitorAlertItemImplFromJson(
  Map<String, dynamic> json,
) => _$MonitorAlertItemImpl(
  opportunityTitle: json['opportunityTitle'] as String,
  score: (json['score'] as num).toInt(),
  deadline: json['deadline'] == null
      ? null
      : DateTime.parse(json['deadline'] as String),
  savedAt: DateTime.parse(json['savedAt'] as String),
);

Map<String, dynamic> _$$MonitorAlertItemImplToJson(
  _$MonitorAlertItemImpl instance,
) => <String, dynamic>{
  'opportunityTitle': instance.opportunityTitle,
  'score': instance.score,
  'deadline': instance.deadline?.toIso8601String(),
  'savedAt': instance.savedAt.toIso8601String(),
};
