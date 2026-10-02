import 'package:freezed_annotation/freezed_annotation.dart';

part 'application_models.freezed.dart';
part 'application_models.g.dart';

enum ApplicationStatus {
  toReview,
  inPreparation,
  submitted,
  accepted,
  rejected,
  archived,
  interview,
  withdrawn,
  onHold,
  waitlisted,
  offerReceived,
}

@freezed
class ApplicationListItem with _$ApplicationListItem {
  const factory ApplicationListItem({
    required String id,
    required String savedOpportunityId,
    required String opportunityTitle,
    required DateTime opportunityDeadline,
    required ApplicationStatus status,
    required String priority, // high, medium, low
    required DateTime updatedAt,
  }) = _ApplicationListItem;

  factory ApplicationListItem.fromJson(Map<String, dynamic> json) =>
      _$ApplicationListItemFromJson(json);
}

@freezed
class StatusHistoryEntry with _$StatusHistoryEntry {
  const factory StatusHistoryEntry({
    required ApplicationStatus oldStatus,
    required ApplicationStatus newStatus,
    required DateTime changedAt,
    String? note,
  }) = _StatusHistoryEntry;

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$StatusHistoryEntryFromJson(json);
}

@freezed
class AppDocument with _$AppDocument {
  const factory AppDocument({
    required String id,
    required String name,
    required String url,
    required DateTime uploadedAt,
  }) = _AppDocument;

  factory AppDocument.fromJson(Map<String, dynamic> json) =>
      _$AppDocumentFromJson(json);
}

@freezed
class AppNote with _$AppNote {
  const factory AppNote({
    required String id,
    required String content,
    required DateTime createdAt,
  }) = _AppNote;

  factory AppNote.fromJson(Map<String, dynamic> json) =>
      _$AppNoteFromJson(json);
}

@freezed
class ApplicationDetail with _$ApplicationDetail {
  const factory ApplicationDetail({
    required String id,
    required String savedOpportunityId,
    required String opportunityTitle,
    required DateTime opportunityDeadline,
    required ApplicationStatus status,
    required String priority,
    required DateTime updatedAt,
    @Default([]) List<StatusHistoryEntry> statusHistory,
    @Default([]) List<AppDocument> documents,
    @Default([]) List<AppNote> notes,
  }) = _ApplicationDetail;

  factory ApplicationDetail.fromJson(Map<String, dynamic> json) =>
      _$ApplicationDetailFromJson(json);
}

@freezed
class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent({
    required DateTime date,
    required String title,
    required String applicationId,
    required String type, // deadline, reminder, interview
  }) = _CalendarEvent;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventFromJson(json);
}
