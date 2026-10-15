import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart' show Json;
import '../../core/api/json.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/opportunity_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'search_repository.dart';

/// The query interpretation shown as editable filters before the search starts (EF-04.03),
/// plus the manual filters (EF-04.05).
class FiltersPanel extends ConsumerWidget {
  const FiltersPanel({super.key, required this.filters, required this.onChanged});
  final Json filters;
  final ValueChanged<Json> onChanged;

  void _set(String key, Object? value) => onChanged({...filters, key: value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final categories = ref.watch(refCategoriesProvider).valueOrNull ?? const <Json>[];
    final countries = ref.watch(refCountriesProvider).valueOrNull ?? const <Json>[];
    final lang = Localizations.localeOf(context).languageCode;
    final selectedCats = filters.strings('categories');
    final selectedCountries = filters.strings('countries');
    final keywords = filters.strings('keywords');
    final allCats = [for (final c in categories) ...[c, ...c.list('children')]];

    return SectionCard(
      title: l.filtersTitle,
      subtitle: l.filtersSubtitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Row(label: l.filterCategories, child: Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
          for (final code in selectedCats)
            InputChip(label: Text(_catName(allCats, code, lang) ?? categoryLabel(l, code)),
                onDeleted: () => _set('categories', [...selectedCats]..remove(code))),
          _AddMenu(
            label: l.filterAdd,
            options: {for (final c in allCats) c.string('code'): c.string(lang == 'en' ? 'name_en' : 'name_fr')},
            exclude: selectedCats,
            onPick: (code) => _set('categories', [...selectedCats, code]),
          ),
        ])),
        _Row(label: l.filterCountries, child: Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
          for (final code in selectedCountries)
            InputChip(label: Text(_countryName(countries, code, lang)),
                onDeleted: () => _set('countries', [...selectedCountries]..remove(code))),
          _AddMenu(
            label: l.filterAdd,
            options: {for (final c in countries) c.string('code'): c.string(lang == 'en' ? 'name_en' : 'name_fr')},
            exclude: selectedCountries,
            onPick: (code) => _set('countries', [...selectedCountries, code]),
          ),
        ])),
        _Row(label: l.filterKeywords, child: _KeywordEditor(
          keywords: keywords, onChanged: (k) => _set('keywords', k))),
        _Row(label: l.filterWorkMode, child: SegmentedButton<String>(
          emptySelectionAllowed: true,
          segments: [
            ButtonSegment(value: 'remote', label: Text(l.workRemote)),
            ButtonSegment(value: 'hybrid', label: Text(l.workHybrid)),
            ButtonSegment(value: 'onsite', label: Text(l.workOnsite)),
          ],
          selected: {if (filters.str('work_mode') != null) filters.string('work_mode')},
          onSelectionChanged: (s) => _set('work_mode', s.isEmpty ? null : s.first),
        )),
        _Row(label: l.filterDeadlineBefore, child: Row(children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.event),
            label: Text(filters.str('deadline_before') == null ? l.filterAnyDate : Fmt.date(context, filters.str('deadline_before'))),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3 * 365)),
              );
              if (picked != null) _set('deadline_before', picked.toIso8601String().substring(0, 10));
            },
          ),
          if (filters.str('deadline_before') != null)
            IconButton(tooltip: l.commonDelete, icon: const Icon(Icons.clear), onPressed: () => _set('deadline_before', null)),
        ])),
        _Row(label: l.filterIncludeExpired, child: Switch(
          value: filters.flag('include_expired'),
          onChanged: (v) => _set('include_expired', v),
        )),
        if (filters.integer('amount_min') != null)
          _Row(label: l.filterAmountMin, child: InputChip(
            label: Text('≥ ${Fmt.money(context, filters.integer('amount_min'), null, filters.str('amount_currency'))
                .replaceAll(RegExp(r',00'), '')}'),
            onDeleted: () => onChanged({...filters, 'amount_min': null, 'amount_currency': null}),
          )),
      ]),
    );
  }

  String? _catName(List<Json> cats, String code, String lang) =>
      cats.where((c) => c.str('code') == code).map((c) => c.string(lang == 'en' ? 'name_en' : 'name_fr')).firstOrNull;

  String _countryName(List<Json> countries, String code, String lang) =>
      countries.where((c) => c.str('code') == code).map((c) => c.string(lang == 'en' ? 'name_en' : 'name_fr')).firstOrNull ?? code;
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Space.md),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Text(label, style: context.text.labelLarge?.copyWith(color: context.colors.onSurfaceVariant)),
            ),
          ),
          Expanded(child: child),
        ]),
      );
}

class _AddMenu extends StatelessWidget {
  const _AddMenu({required this.label, required this.options, required this.exclude, required this.onPick});
  final String label;
  final Map<String, String> options;
  final List<String> exclude;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final entries = options.entries.where((e) => !exclude.contains(e.key)).toList();
    return MenuAnchor(
      menuChildren: [
        for (final e in entries) MenuItemButton(onPressed: () => onPick(e.key), child: Text(e.value)),
      ],
      builder: (context, controller, _) => ActionChip(
        avatar: const Icon(Icons.add, size: 18),
        label: Text(label),
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _KeywordEditor extends StatefulWidget {
  const _KeywordEditor({required this.keywords, required this.onChanged});
  final List<String> keywords;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_KeywordEditor> createState() => _KeywordEditorState();
}

class _KeywordEditorState extends State<_KeywordEditor> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Wrap(spacing: Space.xs, runSpacing: Space.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
      for (final k in widget.keywords)
        InputChip(label: Text(k), onDeleted: () => widget.onChanged([...widget.keywords]..remove(k))),
      SizedBox(
        width: 200,
        child: TextField(
          controller: _c,
          decoration: InputDecoration(isDense: true, hintText: l.filterAddKeyword),
          onSubmitted: (v) {
            final word = v.trim();
            if (word.isNotEmpty && !widget.keywords.contains(word)) widget.onChanged([...widget.keywords, word]);
            _c.clear();
          },
        ),
      ),
    ]);
  }
}
