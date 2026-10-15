import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/json.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/error_text.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/opportunity_widgets.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';
import 'filters_panel.dart';
import 'search_controller.dart';
import 'search_history_view.dart';
import 'search_repository.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.initialQuery, this.runId});
  final String? initialQuery;
  final String? runId;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _query = TextEditingController(text: widget.initialQuery ?? '');

  @override
  void initState() {
    super.initState();
    final ctrl = ref.read(searchControllerProvider.notifier);
    if (widget.runId != null) {
      Future.microtask(() => ctrl.open(widget.runId!));
    } else if ((widget.initialQuery ?? '').isNotEmpty) {
      Future.microtask(() => ctrl.interpret(widget.initialQuery!));
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(searchControllerProvider);
    final ctrl = ref.read(searchControllerProvider.notifier);
    if (s.text.isNotEmpty && _query.text.isEmpty) _query.text = s.text;

    return DefaultTabController(
      length: 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xxl, Space.xl, Space.xxl, 0),
          child: Row(children: [
            Expanded(child: Semantics(header: true, child: Text(l.navSearch, style: context.text.headlineSmall))),
            SizedBox(
              width: 260,
              child: TabBar(tabs: [Tab(text: l.searchTabNew), Tab(text: l.searchTabHistory)]),
            ),
          ]),
        ),
        Expanded(
          child: TabBarView(children: [
            ListView(padding: const EdgeInsets.all(Space.xxl), children: [
              _QueryBox(controller: _query, busy: s.stage == SearchStage.interpreting || s.isRunning,
                  onSubmit: () => ctrl.interpret(_query.text)),
              if (s.error != null) ...[
                const SizedBox(height: Space.md),
                Text(errorText(context, s.error!), style: TextStyle(color: context.colors.error)),
              ],
              const SizedBox(height: Space.lg),
              if (s.stage == SearchStage.idle) const _Suggestions(),
              if (s.filters != null && (s.stage == SearchStage.editing || s.stage == SearchStage.interpreting)) ...[
                FiltersPanel(filters: s.filters!, onChanged: ctrl.updateFilters),
                const SizedBox(height: Space.lg),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: ctrl.start,
                    icon: const Icon(Icons.travel_explore),
                    label: Text(l.searchLaunch),
                  ),
                ),
              ],
              if (s.run != null) ...[_RunPanel(state: s), const SizedBox(height: Space.lg)],
              if (s.stage == SearchStage.done) _Results(state: s),
            ]),
            SearchHistoryView(onOpenRun: (id) {
              DefaultTabController.of(context).animateTo(0);
              ctrl.open(id);
            }, onRerun: (queryId) {
              DefaultTabController.of(context).animateTo(0);
              ctrl.rerun(queryId);
            }),
          ]),
        ),
      ]),
    );
  }
}

class _QueryBox extends StatelessWidget {
  const _QueryBox({required this.controller, required this.busy, required this.onSubmit});
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(children: [
      Expanded(
        child: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            hintText: l.searchHint,
            prefixIcon: const Icon(Icons.search),
            helperText: l.searchHelper,
          ),
        ),
      ),
      const SizedBox(width: Space.md),
      FilledButton.tonalIcon(
        onPressed: busy ? null : onSubmit,
        icon: busy ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.tune),
        label: Text(l.searchInterpret),
      ),
    ]);
  }
}

class _Suggestions extends ConsumerWidget {
  const _Suggestions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final suggestions = ref.watch(searchSuggestionsProvider).valueOrNull ?? const <String>[];
    if (suggestions.isEmpty) {
      return EmptyState(icon: Icons.manage_search, title: l.searchEmptyTitle, message: l.searchEmptyBody);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.searchSuggestions, style: context.text.labelLarge),
      const SizedBox(height: Space.sm),
      Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
        for (final s in suggestions)
          ActionChip(
            avatar: const Icon(Icons.lightbulb_outline, size: 18),
            label: Text(s),
            onPressed: () => ref.read(searchControllerProvider.notifier).interpret(s),
          ),
      ]),
    ]);
  }
}

class _RunPanel extends ConsumerWidget {
  const _RunPanel({required this.state});
  final SearchState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final run = state.run!.obj('run');
    final sources = state.run!.list('sources');
    final total = run.integer('sources_total') ?? sources.length;
    final done = run.integer('sources_done') ?? 0;
    final failed = sources.where((s) => const {'failed', 'blocked'}.contains(s.str('status'))).toList();
    final links = state.run!.list('official_links');
    final ctrl = ref.read(searchControllerProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(state.isRunning ? Icons.sync : Icons.task_alt, color: context.colors.primary),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(state.isRunning ? l.runProgress(done, total) : l.runStatus(_statusLabel(l, run.string('status'))),
                    style: context.text.titleSmall),
              ),
            ),
            if (state.isRunning) TextButton.icon(onPressed: ctrl.cancel, icon: const Icon(Icons.stop), label: Text(l.commonCancel)),
            if (run.str('status') == 'cancelled')
              TextButton.icon(onPressed: ctrl.resume, icon: const Icon(Icons.play_arrow), label: Text(l.runResume)),
          ]),
          if (state.isRunning) ...[
            const SizedBox(height: Space.sm),
            LinearProgressIndicator(value: total == 0 ? null : done / total),
          ],
          const SizedBox(height: Space.sm),
          Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
            for (final src in sources)
              Chip(
                avatar: Icon(_sourceIcon(src.string('status')), size: 16),
                label: Text(src.string('name')),
                visualDensity: VisualDensity.compact,
              ),
          ]),
          if (failed.isNotEmpty || (!state.isRunning && links.isNotEmpty)) ...[
            const Divider(height: Space.xl),
            Text(l.runUnavailableTitle, style: context.text.labelLarge),
            const SizedBox(height: Space.xs),
            Text(l.runUnavailableBody, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
            const SizedBox(height: Space.sm),
            Wrap(spacing: Space.sm, runSpacing: Space.xs, children: [
              for (final src in [...failed, ...links])
                if (src.str('official_search_url') != null)
                  ActionChip(
                    avatar: const Icon(Icons.open_in_new, size: 16),
                    label: Text(src.string('name')),
                    onPressed: () => launchUrl(Uri.parse(src.string('official_search_url'))),
                  ),
            ]),
          ],
        ]),
      ),
    );
  }

  IconData _sourceIcon(String status) => switch (status) {
        'ok' || 'partial' => Icons.check_circle_outline,
        'running' => Icons.hourglass_top,
        'queued' => Icons.schedule,
        'blocked' => Icons.block,
        'failed' => Icons.error_outline,
        _ => Icons.circle_outlined,
      };
}

String _statusLabel(AppLocalizations l, String status) => switch (status) {
      'completed' => l.runCompleted,
      'partial' => l.runPartial,
      'failed' => l.runFailed,
      'cancelled' => l.runCancelled,
      _ => status,
    };

class _Results extends ConsumerWidget {
  const _Results({required this.state});
  final SearchState state;

  Future<void> _export(BuildContext context, WidgetRef ref, String format) async {
    final l = AppLocalizations.of(context);
    final target = await FilePicker.platform.saveFile(fileName: 'opportunex-resultats.$format');
    if (target == null) return;
    try {
      final bytes = await ref.read(searchRepositoryProvider).export(format, state.runId!);
      await File(target).writeAsBytes(bytes);
      if (context.mounted) showSuccess(context, l.exportDone);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final ctrl = ref.read(searchControllerProvider.notifier);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: Space.md, runSpacing: Space.sm, children: [
        Text(l.resultsCount(state.total), style: context.text.titleMedium),
        DropdownButton<String>(
          value: state.sort,
          items: [
            DropdownMenuItem(value: 'relevance', child: Text(l.sortRelevance)),
            DropdownMenuItem(value: 'deadline', child: Text(l.sortDeadline)),
            DropdownMenuItem(value: 'published', child: Text(l.sortPublished)),
            DropdownMenuItem(value: 'amount', child: Text(l.sortAmount)),
            DropdownMenuItem(value: 'recent', child: Text(l.sortRecent)),
          ],
          onChanged: (v) => v == null ? null : ctrl.setSort(v),
        ),
        DropdownButton<int?>(
          value: state.minScore,
          hint: Text(l.filterMinScore),
          items: [
            DropdownMenuItem(child: Text(l.filterAnyScore)),
            for (final v in const [40, 60, 80]) DropdownMenuItem(value: v, child: Text('≥ $v')),
          ],
          onChanged: ctrl.setMinScore,
        ),
        DropdownButton<String?>(
          value: state.badge,
          hint: Text(l.filterBadge),
          items: [
            DropdownMenuItem(child: Text(l.filterAnyBadge)),
            DropdownMenuItem(value: 'deadline_soon', child: Text(l.badgeDeadlineSoon)),
            DropdownMenuItem(value: 'verified', child: Text(l.badgeVerified)),
            DropdownMenuItem(value: 'eligibility_uncertain', child: Text(l.badgeEligibilityUncertain)),
          ],
          onChanged: ctrl.setBadge,
        ),
        PopupMenuButton<String>(
          tooltip: l.exportAction,
          onSelected: (f) => _export(context, ref, f),
          itemBuilder: (_) => [
            for (final f in const ['csv', 'xlsx', 'pdf', 'json']) PopupMenuItem(value: f, child: Text(f.toUpperCase())),
          ],
          child: Chip(avatar: const Icon(Icons.download, size: 18), label: Text(l.exportAction)),
        ),
      ]),
      const SizedBox(height: Space.md),
      if (state.results.isEmpty)
        EmptyState(icon: Icons.search_off, title: l.resultsEmptyTitle, message: l.resultsEmptyBody)
      else
        for (final r in state.results)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: OpportunityCard(
              data: r,
              onOpen: () => context.push('/opportunities/${r.string('id')}'),
              onSave: () async {
                try {
                  await ctrl.save(r.string('id'));
                  if (context.mounted) showSuccess(context, l.oppSavedToast);
                } on Object catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
            ),
          ),
      if (state.nextCursor != null)
        Center(
          child: OutlinedButton(
            onPressed: state.loadingMore ? null : ctrl.loadMore,
            child: Text(l.loadMore),
          ),
        ),
    ]);
  }
}
