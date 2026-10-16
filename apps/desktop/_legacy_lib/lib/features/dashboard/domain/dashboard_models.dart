import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_models.freezed.dart';
part 'dashboard_models.g.dart';

@freezed
class DashboardCounters with _$DashboardCounters {
  const factory DashboardCounters({
    @Default(0) int totalOpportunities,
    @Default(0) int newThisWeek,
    @Default(0) int savedCount,
    @Default(0) int pendingApplications,
    @Default(0) int upcomingDeadlines,
    @Default(0) int monitorsActive,
    @Default(0.0) double averageScore,
  }) = _DashboardCounters;

  factory DashboardCounters.fromJson(Map<String, dynamic> json) =>
      _$DashboardCountersFromJson(json);
}

@freezed
class UpcomingDeadline with _$UpcomingDeadline {
  const factory UpcomingDeadline({
    required String opportunityId,
    required String title,
    required DateTime deadline,
    required int daysLeft,
    required String applicationStatus,
  }) = _UpcomingDeadline;

  factory UpcomingDeadline.fromJson(Map<String, dynamic> json) =>
      _$UpcomingDeadlineFromJson(json);
}

@freezed
class RecentActivity with _$RecentActivity {
  const factory RecentActivity({
    required String type,
    required String description,
    required DateTime occurredAt,
    String? opportunityId,
  }) = _RecentActivity;

  factory RecentActivity.fromJson(Map<String, dynamic> json) =>
      _$RecentActivityFromJson(json);
}

@freezed
class SourceHealth with _$SourceHealth {
  const factory SourceHealth({
    required String sourceId,
    required String name,
    required String status,
    required double reliability,
    DateTime? lastSuccess,
    @Default(0) int consecutiveFailures,
  }) = _SourceHealth;

  factory SourceHealth.fromJson(Map<String, dynamic> json) =>
      _$SourceHealthFromJson(json);
}
