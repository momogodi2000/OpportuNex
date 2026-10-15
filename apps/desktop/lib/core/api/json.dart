import 'api_client.dart';

/// Small typed accessors over engine JSON maps, so views stay readable without a model
/// class for every endpoint.
extension JsonX on Json {
  String? str(String key) => this[key] as String?;
  String string(String key, [String fallback = '']) => (this[key] as String?) ?? fallback;
  int? integer(String key) => (this[key] as num?)?.toInt();
  double? number(String key) => (this[key] as num?)?.toDouble();
  bool flag(String key) => this[key] == true || this[key] == 1;
  Json obj(String key) => (this[key] as Map<String, dynamic>?) ?? <String, dynamic>{};
  Json? objOrNull(String key) => this[key] as Map<String, dynamic>?;
  List<Json> list(String key) => ((this[key] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>();
  List<String> strings(String key) => ((this[key] as List<dynamic>?) ?? const []).map((e) => '$e').toList();
}

List<Json> items(Json response) => response.list('items');
