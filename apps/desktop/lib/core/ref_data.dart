import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'api/json.dart';

/// Reference list of countries (ISO 3166 code, French and English names), loaded once from the engine.
final refCountriesProvider = FutureProvider<List<Json>>((ref) async =>
    items(await requireApi(ref).getJson('/ref/countries')));

/// Country name in the UI language; falls back to the code while the list loads or for an unknown code.
String countryName(List<Json> countries, String code, String lang) =>
    countries
        .where((c) => c.str('code') == code.toUpperCase())
        .map((c) => c.string(lang == 'en' ? 'name_en' : 'name_fr'))
        .firstOrNull ??
    code;

extension CountryNames on WidgetRef {
  String country(BuildContext context, String code) => countryName(
      watch(refCountriesProvider).valueOrNull ?? const [], code, Localizations.localeOf(context).languageCode);
}
