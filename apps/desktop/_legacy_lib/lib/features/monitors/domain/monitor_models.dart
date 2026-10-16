import 'package:freezed_annotation/freezed_annotation.dart';

part 'monitor_models.freezed.dart';
part 'monitor_models.g.dart';

enum MonitorFrequency {
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
  @JsonValue('custom')
  custom,
}

@freezed
class MonitorModel with _$MonitorModel {
  const factory MonitorModel({
    required String id,
    required String name,
    required Map<String, dynamic> filtersJson,
    required MonitorFrequency frequency,
    required int minScore,
    @Default(true) bool isActive,
    DateTime? nextRunAt,
    DateTime? lastRunAt,
    required DateTime createdAt,
  }) = _MonitorModel;

  factory MonitorModel.fromJson(Map<String, dynamic> json) =>
      _$MonitorModelFromJson(json);
}

@freezed
class MonitorResult with _$MonitorResult {
  const factory MonitorResult({
    required String monitorId,
    required DateTime runAt,
    required int newCount,
    required List<String> opportunityIds,
  }) = _MonitorResult;

  factory MonitorResult.fromJson(Map<String, dynamic> json) =>
      _$MonitorResultFromJson(json);
}

@freezed
class MonitorAlertItem with _$MonitorAlertItem {
  const factory MonitorAlertItem({
    required String opportunityTitle,
    required int score,
    DateTime? deadline,
    required DateTime savedAt,
  }) = _MonitorAlertItem;

  factory MonitorAlertItem.fromJson(Map<String, dynamic> json) =>
      _$MonitorAlertItemFromJson(json);
}
