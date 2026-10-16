import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../search/search_controller.dart';
import '../sync/orgs_page.dart';

final workspacesProvider = FutureProvider.autoDispose.family<List<Json>, bool>(
    (ref, archived) async => items(await requireApi(ref).getJson('/workspaces', query: {'archived': archived})));
final workspaceProvider =
    FutureProvider.autoDispose.family<Json, String>((ref, id) => requireApi(ref).getJson('/workspaces/$id'));
final templatesProvider =
    FutureProvider.autoDispose<List<Json>>((ref) async => items(await requireApi(ref).getJson('/workspaces/templates')));

class WorkspacesPage extends ConsumerStatefulWidget {
  const WorkspacesPage({super.key});

  @override
  ConsumerState<WorkspacesPage> createState() => _WorkspacesPageState();
}

class _WorkspacesPageState extends ConsumerState<WorkspacesPage> {
  bool _archived = false;

  Future<void> _create() async {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final templates = await ref.read(templatesProvider.future);
    if (!mounted) return;
    final name = TextEditingController();
    String? template;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.wsCreate),
          content: SizedBox(
            width: 460,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, autofocus: true, decoration: InputDecoration(labelText: l.wsName)),
              const SizedBox(height: Space.md),
              DropdownButtonFormField<String?>(
                initialValue: template,
                decoration: InputDecoration(labelText: l.wsTemplate),
                items: [
                  DropdownMenuItem(child: Text(l.wsNoTemplate)),
                  for (final t in templates)
                    DropdownMenuItem(value: t.string('code'), child: Text(t.string(lang == 'en' ? 'name_en' : 'name_fr'))),
                ],
                onChanged: (v) => setState(() {
                  template = v;
                  if (name.text.isEmpty && v != null) {
                    name.text = templates.firstWhere((t) => t.str('code') == v).string(lang == 'en' ? 'name_en' : 'name_fr');
                  }
                }),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.commonSave)),
          ],
        ),
      ),
    );
    final value = name.text.trim();
    name.dispose();
    if (ok != true || value.isEmpty) return;
    try {
      final ws = await readApi(ref).postJson('/workspaces', body: {'name': value, 'template_code': template});
      ref.invalidate(workspacesProvider);
      if (mounted) unawaited(context.push('/workspaces/${ws.string('id')}'));
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PageFrame(
      title: l.navWorkspaces,
      subtitle: l.wsSubtitle,
      actions: [
        FilterChip(label: Text(l.trackArchived), selected: _archived, onSelected: (v) => setState(() => _archived = v)),
        FilledButton.icon(onPressed: _create, icon: const Icon(Icons.create_new_folder_outlined), label: Text(l.wsCreate)),
      ],
      child: AsyncView<List<Json>>(
        value: ref.watch(workspacesProvider(_archived)),
        onRetry: () => ref.invalidate(workspacesProvider),
        isEmpty: (list) => list.isEmpty,
        empty: EmptyState(icon: Icons.folder_open, title: l.wsEmptyTitle, message: l.wsEmptyBody),
        data: (list) => Wrap(spacing: Space.md, runSpacing: Space.md, children: [
          for (final w in list)
            SizedBox(
              width: 320,
              child: Card(
                child: InkWell(
                  borderRadius: Radii.card,
                  onTap: () => context.push('/workspaces/${w.string('id')}'),
                  child: Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(w.flag('archived') ? Icons.inventory_2_outlined : Icons.folder_outlined, color: context.colors.primary),
                        const SizedBox(width: Space.sm),
                        Expanded(child: Text(w.string('name'), style: context.text.titleMedium)),
                      ]),
                      const SizedBox(height: Space.sm),
                      Text(l.wsCounts(w.obj('counts').integer('queries') ?? 0, w.obj('counts').integer('saved') ?? 0,
                          w.obj('counts').integer('opportunities') ?? 0), style: context.text.bodySmall),
                      Text(Fmt.date(context, w.str('updated_at')), style: context.text.labelSmall),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class WorkspacePage extends ConsumerStatefulWidget {
  const WorkspacePage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  final Set<String> _selected = {};
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Object?> Function() fn) async {
    try {
      await fn();
      ref.invalidate(workspaceProvider(widget.id));
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final api = ref.read(apiClientProvider)!;
    return AsyncView<Json>(
      value: ref.watch(workspaceProvider(widget.id)),
      onRetry: () => ref.invalidate(workspaceProvider(widget.id)),
      data: (w) => PageFrame(
        title: w.string('name'),
        subtitle: w.str('description'),
        actions: [
          if (w.objOrNull('suggested_filters') != null)
            FilledButton.icon(
              icon: const Icon(Icons.search),
              label: Text(l.wsSearchHere),
              onPressed: () {
                ref.read(searchControllerProvider.notifier)
                  ..reset()
                  ..updateFilters({...w.obj('suggested_filters'), 'raw': w.string('name')});
                context.go('/search?q=${Uri.encodeQueryComponent(w.string('name'))}');
              },
            ),
          if (_selected.length >= 2 && _selected.length <= 4)
            OutlinedButton.icon(
              icon: const Icon(Icons.compare_arrows),
              label: Text(l.wsCompare(_selected.length)),
              onPressed: () => showDialog<void>(context: context, builder: (_) => _CompareDialog(ids: _selected.toList())),
            ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'share') {
                await shareWithOrg(context, ref, 'workspace', widget.id, w.str('organization_id'));
                ref.invalidate(workspaceProvider(widget.id));
              } else if (v == 'delete') {
                final ok = await confirmAction(context, title: l.commonDelete, message: w.string('name'),
                    confirmLabel: l.commonDelete, destructive: true);
                if (!ok) return;
                await api.delete('/workspaces/${widget.id}');
                ref.invalidate(workspacesProvider);
                if (context.mounted) context.go('/workspaces');
              } else {
                await _run(() => api.patchJson('/workspaces/${widget.id}', body: {'archived': !w.flag('archived')}));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'share', child: Text(l.orgsShareTitle)),
              PopupMenuItem(value: 'archive', child: Text(w.flag('archived') ? l.trackUnarchive : l.trackArchive)),
              PopupMenuItem(value: 'delete', child: Text(l.commonDelete)),
            ],
          ),
        ],
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SectionCard(
            title: l.wsOpportunities,
            child: w.list('opportunities').isEmpty
                ? Text(l.wsNoOpportunities)
                : Column(children: [
                    for (final o in w.list('opportunities'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.sm),
                        child: OpportunityCard(
                          data: o,
                          selected: _selected.contains(o.string('id')),
                          onSelect: (v) => setState(() => v ? _selected.add(o.string('id')) : _selected.remove(o.string('id'))),
                          onOpen: () => context.push('/opportunities/${o.string('id')}'),
                          trailing: IconButton(
                            tooltip: l.wsRemove,
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _run(() => api.delete('/workspaces/${widget.id}/opportunities/${o.string('id')}')),
                          ),
                        ),
                      ),
                  ]),
          ),
          const SizedBox(height: Space.lg),
          SectionCard(
            title: l.wsQueries,
            child: w.list('queries').isEmpty
                ? Text(l.wsNoQueries)
                : Column(children: [
                    for (final q in w.list('queries'))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.search),
                        title: Text(q.str('saved_name') ?? q.string('raw_text')),
                        subtitle: Text(Fmt.dateTime(context, q.str('created_at'))),
                        trailing: IconButton(
                          tooltip: l.historyRerun,
                          icon: const Icon(Icons.replay),
                          onPressed: () {
                            ref.read(searchControllerProvider.notifier).rerun(q.string('id'));
                            context.go('/search');
                          },
                        ),
                      ),
                  ]),
          ),
          const SizedBox(height: Space.lg),
          SectionCard(
            title: l.trackNotes,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(controller: _note, minLines: 2, maxLines: 5, decoration: InputDecoration(hintText: l.trackNoteHint)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    if (_note.text.trim().isEmpty) return;
                    await _run(() => api.postJson('/workspaces/${widget.id}/notes', body: {'body': _note.text.trim()}));
                    _note.clear();
                  },
                  child: Text(l.trackAddNote),
                ),
              ),
              for (final n in w.list('notes'))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: SelectableText(n.string('body')),
                  subtitle: Text(Fmt.dateTime(context, n.str('created_at'))),
                  trailing: IconButton(
                    tooltip: l.commonDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _run(() => api.delete('/workspaces/${widget.id}/notes/${n.string('id')}')),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _CompareDialog extends ConsumerWidget {
  const _CompareDialog({required this.ids});
  final List<String> ids;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 700),
        child: FutureBuilder<Json>(
          future: readApi(ref).postJson('/opportunities/compare', body: {'ids': ids}),
          builder: (context, snap) {
            if (!snap.hasData) return const Padding(padding: EdgeInsets.all(Space.xxl), child: LoadingState());
            final list = snap.data!.list('items');
            final rows = <(String, String Function(Json))>[
              (l.oppRelevance, (o) => '${o.integer('score') ?? '—'}'),
              (l.oppPublisher, (o) => o.str('organization_name') ?? '—'),
              (l.oppDeadline, (o) => Fmt.date(context, o.str('deadline_on'))),
              (l.oppAmount, (o) => o.objOrNull('amount') == null ? '—' : Fmt.money(context,
                  o.obj('amount').integer('min_minor'), o.obj('amount').integer('max_minor'), o.obj('amount').str('currency'))),
              (l.reqEducation, (o) => o.str('education_required') ?? '—'),
              (l.reqExperience, (o) => o.number('experience_min_years') == null ? '—' : '${o.number('experience_min_years')}'),
              (l.oppEligibility, (o) => (o.str('eligibility_raw') ?? '—').split('\n').take(3).join('\n')),
            ];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(Space.xl),
              child: Table(
                border: TableBorder.all(color: context.colors.outlineVariant),
                columnWidths: const {0: FixedColumnWidth(160)},
                children: [
                  TableRow(children: [
                    const SizedBox(),
                    for (final o in list)
                      Padding(padding: const EdgeInsets.all(Space.sm),
                          child: Text(o.string('title'), style: context.text.titleSmall)),
                  ]),
                  for (final (label, getter) in rows)
                    TableRow(children: [
                      Padding(padding: const EdgeInsets.all(Space.sm), child: Text(label, style: context.text.labelLarge)),
                      for (final o in list) Padding(padding: const EdgeInsets.all(Space.sm), child: Text(getter(o))),
                    ]),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
