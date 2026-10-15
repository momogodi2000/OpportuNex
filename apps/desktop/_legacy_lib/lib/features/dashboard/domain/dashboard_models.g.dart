// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DashboardCountersImpl _$$DashboardCountersImplFromJson(
  Map<String, dynamic> json,
) => _$DashboardCountersImpl(
  totalOpportunities: (json['totalOpportunities'] as num?)?.toInt() ?? 0,
  newThisWeek: (json['newThisWeek'] as num?)?.toInt() ?? 0,
  savedCount: (json['savedCount'] as num?)?.toInt() ?? 0,
  pendingApplications: (json['pendingApplications'] as num?)?.toInt() ?? 0,
  upcomingDeadlines: (json['upcomingDeadlines'] as num?)?.toInt() ?? 0,
  monitorsActive: (json['monitorsActive'] as num?)?.toInt() ?? 0,
  averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$DashboardCountersImplToJson(
  _$DashboardCountersImpl instance,
) => <String, dynamic>{
  'totalOpportunities': instance.totalOpportunities,
  'newThisWeek': instance.newThisWeek,
  'savedCount': instance.savedCount,
  'pendingApplications': instance.pendingApplications,
  'upcomingDeadlines': instance.upcomingDeadlines,
  'monitorsActive': instance.monitorsActive,
  'averageScore': instance.averageScore,
};

_$UpcomingDeadlineImpl _$$UpcomingDeadlineImplFromJson(
  Map<String, dynamic> json,
) => _$UpcomingDeadlineImpl(
  opportunityId: json['opportunityId'] as String,
  title: json['title'] as String,
  deadline: DateTime.parse(json['deadline'] as String),
  daysLeft: (json['daysLeft'] as num).toInt(),
  applicationStatus: json['applicationStatus'] as String,
);

Map<String, dynamic> _$$UpcomingDeadlineImplToJson(
  _$UpcomingDeadlineImpl instance,
) => <String, dynamic>{
  'opportunityId': instance.opportunityId,
  'title': instance.title,
  'deadline': instance.deadline.toIso8601String(),
  'daysLeft': instance.daysLeft,
  'applicationStatus': instance.applicationStatus,
};

_$RecentActivityImpl _$$RecentActivityImplFromJson(Map<String, dynamic> json) =>
    _$RecentActivityImpl(
      type: json['type'] as String,
      description: json['description'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      opportunityId: json['opportunityId'] as String?,
    );

Map<String, dynamic> _$$RecentActivityImplToJson(
  _$RecentActivityImpl instance,
) => <String, dynamic>{
  'type': instance.type,
  'description': instance.description,
  'occurredAt': instance.occurredAt.toIso8601String(),
  'opportunityId': instance.opportunityId,
};

_$SourceHealthImpl _$$SourceHealthImplFromJson(Map<String, dynamic> json) =>
    _$SourceHealthImpl(
      sourceId: json['sourceId'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      reliability: (json['reliability'] as num).toDouble(),
      lastSuccess: json['lastSuccess'] == null
          ? null
          : DateTime.parse(json['lastSuccess'] as String),
      consecutiveFailures: (json['consecutiveFailures'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$SourceHealthImplToJson(_$SourceHealthImpl instance) =>
    <String, dynamic>{
      'sourceId': instance.sourceId,
      'name': instance.name,
      'status': instance.status,
      'reliability': instance.reliability,
      'lastSuccess': instance.lastSuccess?.toIso8601String(),
      'consecutiveFailures': instance.consecutiveFailures,
    };
