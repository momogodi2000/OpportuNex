import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json.dart';

class TrackingRepository {
  TrackingRepository(this._api);
  final ApiClient _api;

  Future<List<Json>> saved({String? q, String? status, String? priority, String? tag, bool archived = false,
          String sort = 'deadline'}) async =>
      items(await _api.getJson('/saved',
          query: {'q': q, 'status': status, 'priority': priority, 'tag': tag, 'archived': archived, 'sort': sort}));
  Future<Json> savedItem(String id) => _api.getJson('/saved/$id');
  Future<Json> patchSaved(String id, Json values) => _api.patchJson('/saved/$id', body: values);
  Future<void> unsave(String id) => _api.delete('/saved/$id');
  Future<Json> setTags(String id, List<String> names) => _api.putJson('/saved/$id/tags', body: {'names': names});
  Future<List<Json>> tags() async => items(await _api.getJson('/tags'));

  Future<List<Json>> notes(String savedId) async => items(await _api.getJson('/saved/$savedId/notes'));
  Future<void> addNote(String savedId, String body) => _api.postJson('/saved/$savedId/notes', body: {'body': body});
  Future<void> deleteNote(String savedId, String noteId) => _api.delete('/saved/$savedId/notes/$noteId');

  Future<void> addCheck(String savedId, String label) => _api.postJson('/saved/$savedId/checklist', body: {'label': label});
  Future<void> patchCheck(String savedId, int itemId, Json values) =>
      _api.patchJson('/saved/$savedId/checklist/$itemId', body: values);
  Future<void> deleteCheck(String savedId, int itemId) => _api.delete('/saved/$savedId/checklist/$itemId');

  Future<Json> attach(String savedId, String fileName, List<int> bytes, String label, {int? checklistItemId}) =>
      _api.upload('/saved/$savedId/documents', fileName: fileName, bytes: bytes,
          fields: {'label': label, if (checklistItemId != null) 'checklist_item_id': '$checklistItemId'});
  Future<Uint8List> document(String savedId, String docId) => _api.getBytes('/saved/$savedId/documents/$docId');
  Future<void> deleteDocument(String savedId, String docId) => _api.delete('/saved/$savedId/documents/$docId');

  Future<Json> application(String id) => _api.getJson('/applications/$id');
  Future<Json> transition(String id, Json body) => _api.postJson('/applications/$id/status', body: body);
  Future<Json> addEvent(String id, Json body) => _api.postJson('/applications/$id/events', body: body);
  Future<Json> patchEvent(String id, String eventId, Json body) => _api.patchJson('/applications/$id/events/$eventId', body: body);
  Future<void> deleteEvent(String id, String eventId) => _api.delete('/applications/$id/events/$eventId');
  Future<Json> board() => _api.getJson('/applications/board');
  Future<List<Json>> calendar(String start, String end) async =>
      items(await _api.getJson('/applications/calendar', query: {'start': start, 'end': end}));
  Future<Uint8List> ics() => _api.getBytes('/applications/calendar.ics');

  Future<List<Json>> generated(String savedId) async => items(await _api.getJson('/saved/$savedId/generated'));
  Future<Json> generate(String savedId, String type, String lang) =>
      _api.postJson('/saved/$savedId/generated', body: {'doc_type': type, 'language': lang});
  Future<Json> generatedDoc(String id) => _api.getJson('/generated/$id');
  Future<Json> saveVersion(String id, String content) => _api.postJson('/generated/$id/versions', body: {'content': content});
  Future<void> deleteGenerated(String id) => _api.delete('/generated/$id');
  Future<Uint8List> exportGenerated(String id, String format) =>
      _api.getBytes('/generated/$id/export', query: {'format': format});
}

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) => TrackingRepository(requireApi(ref)));

final savedListProvider = FutureProvider.autoDispose.family<List<Json>, SavedQuery>(
    (ref, q) => ref.watch(trackingRepositoryProvider).saved(
        q: q.text, status: q.status, priority: q.priority, tag: q.tag, archived: q.archived, sort: q.sort));
final savedItemProvider = FutureProvider.autoDispose.family<Json, String>(
    (ref, id) => ref.watch(trackingRepositoryProvider).savedItem(id));
final applicationProvider = FutureProvider.autoDispose.family<Json, String>(
    (ref, id) => ref.watch(trackingRepositoryProvider).application(id));
final boardProvider = FutureProvider.autoDispose<Json>((ref) => ref.watch(trackingRepositoryProvider).board());
final tagsProvider = FutureProvider.autoDispose<List<Json>>((ref) => ref.watch(trackingRepositoryProvider).tags());

class SavedQuery {
  const SavedQuery({this.text, this.status, this.priority, this.tag, this.archived = false, this.sort = 'deadline'});
  final String? text;
  final String? status;
  final String? priority;
  final String? tag;
  final bool archived;
  final String sort;

  SavedQuery copyWith({String? text, String? status, String? priority, String? tag, bool? archived, String? sort,
          bool clearStatus = false, bool clearPriority = false, bool clearTag = false}) =>
      SavedQuery(
        text: text ?? this.text,
        status: clearStatus ? null : (status ?? this.status),
        priority: clearPriority ? null : (priority ?? this.priority),
        tag: clearTag ? null : (tag ?? this.tag),
        archived: archived ?? this.archived,
        sort: sort ?? this.sort,
      );

  @override
  bool operator ==(Object other) =>
      other is SavedQuery && other.text == text && other.status == status && other.priority == priority &&
      other.tag == tag && other.archived == archived && other.sort == sort;

  @override
  int get hashCode => Object.hash(text, status, priority, tag, archived, sort);
}

const applicationStatuses = ['discovered', 'to_review', 'preparing', 'ready', 'submitted', 'interview', 'accepted',
  'rejected', 'withdrawn', 'expired', 'archived'];
