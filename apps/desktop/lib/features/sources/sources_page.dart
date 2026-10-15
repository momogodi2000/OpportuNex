import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/opportunity_widgets.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';

final sourcesProvider = FutureProvider.autoDispose<List<Json>>((ref) async => items(await requireApi(ref).getJson('/sources')));

class SourcesPage extends ConsumerStatefulWidget {
  const SourcesPage({super.key});

  @override
  ConsumerState<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends ConsumerState<SourcesPage> {
  String _filter = 'all';
  String _q = '';

  Future<void> _add() async {
    final l = AppLocalizations.of(context);
    final url = TextEditingController();
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.srcAdd),
        content: SizedBox(
          width: 480,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l.srcAddHelp),
            const SizedBox(height: Space.md),
            TextField(controller: url, autofocus: true, decoration: const InputDecoration(labelText: 'URL', hintText: 'https://…')),
            const SizedBox(height: Space.md),
            TextField(controller: name, decoration: InputDecoration(labelText: l.srcName)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.srcDetect)),
        ],
      ),
    );
    final u = url.text.trim();
    final n = name.text.trim();
    url.dispose();
    name.dispose();
    if (ok != true || u.isEmpty) return;
    try {
      final r = await readApi(ref).postJson('/sources', body: {'url': u, if (n.isNotEmpty) 'name': n});
      ref.invalidate(sourcesProvider);
      if (mounted) showSuccess(context, l.srcAdded(r.list('preview').length));
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final api = ref.read(apiClientProvider)!;
    Future<void> patch(String id, Json body) async {
      try {
        await api.patchJson('/sources/$id', body: body);
        ref.invalidate(sourcesProvider);
      } on Object catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    return PageFrame(
      title: l.navSources,
      subtitle: l.srcSubtitle,
      actions: [FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add_link), label: Text(l.srcAdd))],
      child: AsyncView<List<Json>>(
        value: ref.watch(sourcesProvider),
        onRetry: () => ref.invalidate(sourcesProvider),
        data: (all) {
          final list = all.where((s) {
            final matches = _q.isEmpty || '${s['name']} ${s['domain']}'.toLowerCase().contains(_q.toLowerCase());
            return matches && switch (_filter) {
              'active' => s.flag('enabled'),
              'links' => s.str('access_method') == 'manual_link',
              'custom' => s.flag('custom'),
              'failing' => (s.integer('consecutive_failures') ?? 0) > 0,
              _ => true,
            };
          }).toList();
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: InputDecoration(isDense: true, prefixIcon: const Icon(Icons.search), hintText: l.commonSearch),
                  onChanged: (v) => setState(() => _q = v),
                ),
              ),
              for (final (code, label) in [('all', l.srcAll), ('active', l.srcActive), ('links', l.srcLinks),
                ('custom', l.srcCustom), ('failing', l.srcFailing)])
                ChoiceChip(label: Text(label), selected: _filter == code, onSelected: (_) => setState(() => _filter = code)),
              Text(l.srcCount(list.length, all.length), style: context.text.bodySmall),
            ]),
            const SizedBox(height: Space.lg),
            Card(
              child: Column(children: [
                for (final s in list) ...[
                  ListTile(
                    leading: Icon(s.str('access_method') == 'manual_link' ? Icons.link
                        : s.flag('enabled') ? Icons.rss_feed : Icons.rss_feed_outlined,
                        color: s.flag('enabled') ? context.colors.primary : context.colors.outline),
                    title: Row(children: [
                      Flexible(child: Text(s.string('name'))),
                      if (s.flag('is_official')) ...[const SizedBox(width: Space.xs), const StatusBadge(kind: 'verified', dense: true)],
                    ]),
                    subtitle: Text([
                      s.string('domain'),
                      _method(l, s.string('access_method')),
                      l.srcReliability((((s.number('reliability_score') ?? 0.5) * 100).round())),
                      if (s.str('last_success_at') != null) l.srcLastSuccess(Fmt.dateTime(context, s.str('last_success_at'))),
                      if (s.str('last_error') != null) l.srcLastError(s.string('last_error')),
                      if ((s.integer('opportunities_count') ?? 0) > 0) l.srcOppCount(s.integer('opportunities_count')!),
                    ].join(' · ')),
                    trailing: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                      if (s.str('official_search_url') != null)
                        IconButton(tooltip: l.oppOfficialLink, icon: const Icon(Icons.open_in_new),
                            onPressed: () => launchUrl(Uri.parse(s.string('official_search_url')))),
                      if (s.str('access_method') != 'manual_link')
                        Switch(value: s.flag('enabled'), onChanged: (v) => patch(s.string('id'), {'enabled': v})),
                      if (s.flag('custom'))
                        IconButton(
                          tooltip: l.commonDelete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await confirmAction(context, title: l.commonDelete, message: s.string('name'),
                                confirmLabel: l.commonDelete, destructive: true);
                            if (!ok) return;
                            await api.delete('/sources/${s.string('id')}');
                            ref.invalidate(sourcesProvider);
                          },
                        ),
                    ]),
                  ),
                  const Divider(height: 1),
                ],
              ]),
            ),
            const SizedBox(height: Space.md),
            Text(l.srcPolicy, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
          ]);
        },
      ),
    );
  }

  String _method(AppLocalizations l, String m) => switch (m) {
        'rss' || 'atom' => 'RSS',
        'api' => 'API',
        'manual_link' => l.srcLinkOnly,
        _ => m,
      };
}
