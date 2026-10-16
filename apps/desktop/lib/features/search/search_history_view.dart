import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart' show Json;
import '../../core/api/json.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';
import 'search_controller.dart';
import 'search_repository.dart';

/// Past and saved searches: reopen, rerun, save under a name, clear (EF-15.03, 15.05).
class SearchHistoryView extends ConsumerWidget {
  const SearchHistoryView({super.key, required this.onOpenRun, required this.onRerun});
  final ValueChanged<String> onOpenRun;
  final ValueChanged<String> onRerun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final history = ref.watch(searchHistoryProvider);
    final repo = ref.read(searchRepositoryProvider);
    return AsyncView(
      value: history,
      onRetry: () => ref.invalidate(searchHistoryProvider),
      isEmpty: (List<dynamic> h) => h.isEmpty,
      empty: EmptyState(icon: Icons.history, title: l.historyEmpty),
      data: (items) => ListView(padding: const EdgeInsets.all(Space.xxl), children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.delete_sweep_outlined),
            label: Text(l.historyClear),
            onPressed: () async {
              final ok = await confirmAction(context, title: l.historyClear, message: l.historyClearConfirm,
                  confirmLabel: l.commonDelete, destructive: true);
              if (!ok) return;
              await repo.clearHistory();
              ref.invalidate(searchHistoryProvider);
            },
          ),
        ),
        for (final q in items)
          Card(
            margin: const EdgeInsets.only(bottom: Space.sm),
            child: ListTile(
              leading: Icon(q.flag('is_saved') ? Icons.bookmark : Icons.history),
              title: Text(q.str('saved_name') ?? q.string('raw_text')),
              subtitle: Text([
                if (q.str('saved_name') != null) q.string('raw_text'),
                Fmt.dateTime(context, q.str('last_run_at')),
                if (q.objOrNull('last_run') != null) l.resultsCount(q.obj('last_run').integer('results_count') ?? 0),
              ].join(' · ')),
              trailing: Wrap(spacing: Space.xs, children: [
                if (q.objOrNull('last_run') != null)
                  IconButton(tooltip: l.historyOpen, icon: const Icon(Icons.visibility_outlined),
                      onPressed: () => onOpenRun(q.obj('last_run').string('id'))),
                if (q.objOrNull('previous_run') != null && q.objOrNull('last_run') != null)
                  IconButton(
                    tooltip: l.historyCompare,
                    icon: const Icon(Icons.compare_arrows),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _Compare(a: q.obj('previous_run').string('id'), b: q.obj('last_run').string('id')),
                    ),
                  ),
                IconButton(tooltip: l.historyRerun, icon: const Icon(Icons.replay), onPressed: () => onRerun(q.string('id'))),
                IconButton(
                  tooltip: q.flag('is_saved') ? l.historyUnsave : l.historySave,
                  icon: Icon(q.flag('is_saved') ? Icons.bookmark_remove_outlined : Icons.bookmark_add_outlined),
                  onPressed: () async {
                    String? name;
                    if (!q.flag('is_saved')) {
                      name = await _askName(context, q.string('raw_text'));
                      if (name == null) return;
                    }
                    try {
                      await repo.saveQuery(q.string('id'), name);
                      ref.invalidate(searchHistoryProvider);
                    } on Object catch (e) {
                      if (context.mounted) showError(context, e);
                    }
                  },
                ),
              ]),
            ),
          ),
        Text(l.historyHint, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
      ]),
    );
  }

  Future<String?> _askName(BuildContext context, String initial) {
    final l = AppLocalizations.of(context);
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.historySave),
        content: SizedBox(width: 400, child: TextField(controller: c, autofocus: true,
            onSubmitted: (v) => Navigator.pop(ctx, v.trim().isEmpty ? null : v.trim()))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim().isEmpty ? null : c.text.trim()),
              child: Text(l.commonSave)),
        ],
      ),
    ).whenComplete(c.dispose);
  }
}

/// New, disappeared and modified results between two runs of the same search (EF-15.04).
class _Compare extends ConsumerWidget {
  const _Compare({required this.a, required this.b});
  final String a;
  final String b;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.historyCompare),
      content: SizedBox(
        width: 640,
        height: 440,
        child: FutureBuilder<Json>(
          future: ref.read(searchRepositoryProvider).compare(a, b),
          builder: (context, snap) {
            if (snap.hasError) return ErrorState(error: snap.error!);
            if (!snap.hasData) return const LoadingState();
            final d = snap.data!;
            final groups = [
              (l.compareNew, Icons.fiber_new_outlined, d.list('new')),
              (l.compareModified, Icons.edit_note, d.list('modified')),
              (l.compareGone, Icons.remove_circle_outline, d.list('disappeared')),
            ];
            if (groups.every((g) => g.$3.isEmpty)) return Center(child: Text(l.compareSame));
            return ListView(children: [
              for (final (label, icon, list) in groups) ...[
                ListTile(leading: Icon(icon), title: Text('$label (${list.length})', style: context.text.titleSmall)),
                for (final o in list)
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: Space.xxxl),
                    title: Text(o.string('title')),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/opportunities/${o.string('id')}');
                    },
                  ),
              ],
            ]);
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonClose))],
    );
  }
}
