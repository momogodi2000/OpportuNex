import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/opportunity_models.dart';

class OpportunityRepository {
  final http.Client client;
  final String baseUrl;

  OpportunityRepository({required this.client, required this.baseUrl});

  Future<List<OpportunityListItem>> getOpportunities({
    String? category,
    String? country,
    String? language,
    String? source,
    String? deadlineBefore,
    String? deadlineAfter,
    double? amountMin,
    double? amountMax,
    int? minScore,
    bool? isSaved,
    String? sortBy,
    String? cursor,
    int limit = 20,
  }) async {
    final queryParameters = {
      if (category != null) 'category': category,
      if (country != null) 'country': country,
      if (language != null) 'language': language,
      if (source != null) 'source': source,
      if (deadlineBefore != null) 'deadlineBefore': deadlineBefore,
      if (deadlineAfter != null) 'deadlineAfter': deadlineAfter,
      if (amountMin != null) 'amountMin': amountMin.toString(),
      if (amountMax != null) 'amountMax': amountMax.toString(),
      if (minScore != null) 'minScore': minScore.toString(),
      if (isSaved != null) 'isSaved': isSaved.toString(),
      if (sortBy != null) 'sortBy': sortBy,
      if (cursor != null) 'cursor': cursor,
      'limit': limit.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/api/v1/opportunities',
    ).replace(queryParameters: queryParameters);
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['data'];
      return data.map((json) => OpportunityListItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load opportunities');
    }
  }

  Future<OpportunityDetail> getOpportunityById(String id) async {
    final uri = Uri.parse('$baseUrl/api/v1/opportunities/$id');
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      return OpportunityDetail.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load opportunity details');
    }
  }

  Future<void> updateOpportunity(String id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/api/v1/opportunities/$id');
    final response = await client.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update opportunity');
    }
  }

  Future<Map<String, dynamic>> getBadgeSummary(String id) async {
    final uri = Uri.parse('$baseUrl/api/v1/opportunities/$id/badge-summary');
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load badge summary');
    }
  }
}
