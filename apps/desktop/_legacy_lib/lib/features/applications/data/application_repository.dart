import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/application_models.dart';

class ApplicationRepository {
  final http.Client client;
  final String baseUrl;

  ApplicationRepository({required this.client, required this.baseUrl});

  Future<List<ApplicationListItem>> getApplications() async {
    final uri = Uri.parse('$baseUrl/api/v1/applications');
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['data'];
      return data.map((json) => ApplicationListItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load applications');
    }
  }

  Future<ApplicationDetail> getApplicationById(String id) async {
    final uri = Uri.parse('$baseUrl/api/v1/applications/$id');
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      return ApplicationDetail.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load application details');
    }
  }

  Future<void> transitionApplicationStatus(
    String id,
    ApplicationStatus newStatus, {
    String? note,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/applications/$id/transition');
    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'status': newStatus.toString().split('.').last,
        if (note != null) 'note': note,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to transition application status');
    }
  }

  Future<Map<ApplicationStatus, List<ApplicationListItem>>>
  getKanbanBoard() async {
    final uri = Uri.parse('$baseUrl/api/v1/applications/kanban');
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data.map((key, value) {
        final status = ApplicationStatus.values.firstWhere(
          (e) => e.toString().split('.').last == key,
        );
        final items = (value as List)
            .map((json) => ApplicationListItem.fromJson(json))
            .toList();
        return MapEntry(status, items);
      });
    } else {
      throw Exception('Failed to load kanban board');
    }
  }

  Future<List<CalendarEvent>> getCalendarEvents(String from, String to) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/applications/calendar',
    ).replace(queryParameters: {'from': from, 'to': to});
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['data'];
      return data.map((json) => CalendarEvent.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load calendar events');
    }
  }

  Future<void> addNoteToApplication(String id, String note) async {
    final uri = Uri.parse('$baseUrl/api/v1/applications/$id/notes');
    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'content': note}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add note');
    }
  }
}
