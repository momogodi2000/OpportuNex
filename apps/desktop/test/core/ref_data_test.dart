import 'package:flutter_test/flutter_test.dart';
import 'package:opportunex/core/ref_data.dart';
import 'package:opportunex/features/opportunity/opportunity_page.dart';
import 'package:opportunex/l10n/app_localizations_fr.dart';

void main() {
  const countries = [
    {'code': 'CM', 'name_fr': 'Cameroun', 'name_en': 'Cameroon'},
    {'code': 'SN', 'name_fr': 'Sénégal', 'name_en': 'Senegal'},
  ];

  // Regression: result cards and the opportunity sheet showed the raw code ("CM").
  test('country codes are shown as names in the UI language', () {
    expect(countryName(countries, 'CM', 'fr'), 'Cameroun');
    expect(countryName(countries, 'cm', 'en'), 'Cameroon');
    expect(countryName(countries, 'XX', 'fr'), 'XX');
    expect(countryName(const [], 'SN', 'fr'), 'SN');
  });

  test('the location strength uses the country name', () {
    final l = AppLocalizationsFr();
    expect(strengthLabel(l, 'location:CM', country: (c) => countryName(countries, c, 'fr')), 'Pays recherché : Cameroun');
    expect(strengthLabel(l, 'location:CM'), 'Pays recherché : CM');
  });
}
