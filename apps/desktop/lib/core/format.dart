import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Regional formats (D-17): dd/MM/yyyy, French number grouping, XAF without decimals.
abstract final class Fmt {
  static String _locale(BuildContext context) => Localizations.localeOf(context).toLanguageTag();

  static String date(BuildContext context, String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('dd/MM/yyyy', _locale(context)).format(iso.length > 10 ? d.toLocal() : d);
  }

  static String dateTime(BuildContext context, String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('dd/MM/yyyy HH:mm', _locale(context)).format(d.toLocal());
  }

  static const _zeroDecimal = {'XAF', 'XOF'};

  static String money(BuildContext context, int? minorMin, int? minorMax, String? currency) {
    if (currency == null || minorMin == null) return '—';
    final factor = _zeroDecimal.contains(currency) ? 1 : 100;
    final f = NumberFormat.decimalPattern(_locale(context));
    final lo = f.format(minorMin / factor);
    final hi = minorMax == null ? null : f.format(minorMax / factor);
    return hi == null ? '$lo $currency' : '$lo – $hi $currency';
  }

  static String bytes(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} Mo';
  }
}
