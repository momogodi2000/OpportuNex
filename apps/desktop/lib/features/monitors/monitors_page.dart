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
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';
import '../search/search_repository.dart';

final monitorsProvider = FutureProvider.autoDispose<List<Json>>((ref) async => items(await requireApi(ref).getJson('/monitors')));
final notificationsProvider =
    FutureProvider.autoDispose<List<Json>>((ref) async => items(await requireApi(ref).getJson('/notifications')));

class MonitorsPage extends ConsumerWidget {
  const MonitorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xxl, Space.xl, Space.xxl, 0),
          child: Row(children: [
            Expanded(child: Text(l.navMonitors, style: context.text.headlineSmall)),
            FilledButton.icon(
              onPressed: () => _create(context, ref),
              icon: const Icon(Icons.add_alert_outlined),
              label: Text(l.monCreate),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          child: TabBar(isScrollable: true, tabAlignment: TabAlignment.start,
              tabs: [Tab(text: l.monTabMonitors), Tab(text: l.monTabNotifications)]),
        ),
        const Divider(),
        const Expanded(child: TabBarView(children: [_MonitorList(), NotificationsView()])),
      ]),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final body = await showDialog<Json>(context: context, builder: (_) => const _MonitorDialog());
    if (body == null) return;
    try {
      await readApi(ref).postJson('/monitors', body: body);
      ref.invalidate(monitorsProvider);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

class _MonitorList extends ConsumerWidget {
  const _MonitorList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final api = ref.read(apiClientProvider)!;
    Future<void> run(Future<Object?> Function() fn, [String? done]) async {
      try {
        await fn();
        ref.invalidate(monitorsProvider);
        if (done != null && context.mounted) showSuccess(context, done);
      } on Object catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    return ListView(padding: const EdgeInsets.all(Space.xxl), children: [
      Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(color: context.status.info, borderRadius: Radii.control),
        child: Row(children: [
          Icon(Icons.info_outline, color: context.status.onInfo),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(l.monOnlyWhileOpen, style: TextStyle(color: context.status.onInfo))),
        ]),
      ),
      const SizedBox(height: Space.lg),
      AsyncView<List<Json>>(
        value: ref.watch(monitorsProvider),
        onRetry: () => ref.invalidate(monitorsProvider),
        isEmpty: (list) => list.isEmpty,
        empty: EmptyState(icon: Icons.notifications_none, title: l.monEmptyTitle, message: l.monEmptyBody),
        data: (list) => Column(children: [
          for (final m in list)
            Card(
              margin: const EdgeInsets.only(bottom: Space.md),
              child: Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Row(children: [
                  Switch(
                    value: m.flag('enabled'),
                    onChanged: (v) => run(() => api.patchJson('/monitors/${m.string('id')}', body: {'enabled': v})),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.string('name'), style: context.text.titleMedium),
                      Text(l.monScheduleSummary(_schedule(l, m.string('schedule_kind'), m.string('schedule_expr')),
                          m.integer('min_score') ?? 0), style: context.text.bodySmall),
                      Text(l.monNextRun(Fmt.dateTime(context, m.str('next_run_at'))), style: context.text.bodySmall),
                      if (m.objOrNull('last_run') != null)
                        Text(l.monLastRun(Fmt.dateTime(context, m.obj('last_run').str('started_at')),
                            m.obj('last_run').integer('new_items') ?? 0), style: context.text.bodySmall),
                    ]),
                  ),
                  if (m.objOrNull('last_run')?.str('search_run_id') != null)
                    IconButton(tooltip: l.historyOpen, icon: const Icon(Icons.visibility_outlined),
                        onPressed: () => context.go('/search?run=${m.obj('last_run').string('search_run_id')}')),
                  IconButton(tooltip: l.monRunNow, icon: const Icon(Icons.play_arrow),
                      onPressed: () => run(() => api.postJson('/monitors/${m.string('id')}/run'), l.monStarted)),
                  IconButton(
                    tooltip: l.commonDelete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await confirmAction(context, title: l.commonDelete, message: m.string('name'),
                          confirmLabel: l.commonDelete, destructive: true);
                      if (ok) await run(() => api.delete('/monitors/${m.string('id')}'));
                    },
                  ),
                ]),
              ),
            ),
        ]),
      ),
    ]);
  }

  String _schedule(AppLocalizations l, String kind, String expr) => switch (kind) {
        'daily' => l.monDaily(expr),
        'weekly' => l.monWeekly(expr),
        _ => expr,
      };
}

class _MonitorDialog extends ConsumerStatefulWidget {
  const _MonitorDialog();

  @override
  ConsumerState<_MonitorDialog> createState() => _MonitorDialogState();
}

class _MonitorDialogState extends ConsumerState<_MonitorDialog> {
  final _name = TextEditingController();
  final _query = TextEditingController();
  String _kind = 'daily';
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  String _day = 'mon';
  double _minScore = 50;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _query.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _query.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final filters = await ref.read(searchRepositoryProvider).interpret(_query.text.trim());
      final hm = '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
      if (mounted) {
        Navigator.pop(context, <String, dynamic>{
          'name': _name.text.trim(),
          'filters': {...filters, 'raw': _query.text.trim()},
          'schedule_kind': _kind,
          'schedule_expr': _kind == 'weekly' ? '$_day $hm' : hm,
          'min_score': _minScore.round(),
        });
      }
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.monCreate),
      content: SizedBox(
        width: 480,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _name, decoration: InputDecoration(labelText: l.monName)),
          const SizedBox(height: Space.md),
          TextField(controller: _query, decoration: InputDecoration(labelText: l.monQuery, helperText: l.searchHelper)),
          const SizedBox(height: Space.md),
          SegmentedButton<String>(
            segments: [ButtonSegment(value: 'daily', label: Text(l.monDailyLabel)),
              ButtonSegment(value: 'weekly', label: Text(l.monWeeklyLabel))],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: Space.md),
          Row(children: [
            if (_kind == 'weekly')
              DropdownButton<String>(
                value: _day,
                items: [
                  for (final (code, label) in [('mon', l.dayMon), ('tue', l.dayTue), ('wed', l.dayWed), ('thu', l.dayThu),
                    ('fri', l.dayFri), ('sat', l.daySat), ('sun', l.daySun)])
                    DropdownMenuItem(value: code, child: Text(label)),
                ],
                onChanged: (v) => setState(() => _day = v ?? 'mon'),
              ),
            const SizedBox(width: Space.md),
            OutlinedButton.icon(
              icon: const Icon(Icons.schedule),
              label: Text(_time.format(context)),
              onPressed: () async {
                final t = await showTimePicker(context: context, initialTime: _time);
                if (t != null) setState(() => _time = t);
              },
            ),
          ]),
          const SizedBox(height: Space.md),
          Text(l.monMinScore(_minScore.round())),
          Slider(value: _minScore, min: 0, max: 100, divisions: 20, label: '${_minScore.round()}',
              onChanged: (v) => setState(() => _minScore = v)),
          Text(l.monFrequencyNote, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton(onPressed: _busy ? null : _submit, child: Text(l.commonSave)),
      ],
    );
  }
}

class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final api = ref.read(apiClientProvider)!;
    return AsyncView<List<Json>>(
      value: ref.watch(notificationsProvider),
      onRetry: () => ref.invalidate(notificationsProvider),
      isEmpty: (list) => list.isEmpty,
      empty: EmptyState(icon: Icons.notifications_off_outlined, title: l.notifEmpty),
      data: (list) => ListView(padding: const EdgeInsets.all(Space.xxl), children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.done_all),
            label: Text(l.notifMarkAllRead),
            onPressed: () async {
              await api.postJson('/notifications/read', body: {});
              ref.invalidate(notificationsProvider);
            },
          ),
        ),
        for (final n in list)
          Card(
            margin: const EdgeInsets.only(bottom: Space.sm),
            child: ListTile(
              leading: Icon(switch (n.string('kind')) {
                'deadline' => Icons.alarm,
                'new_opportunities' => Icons.fiber_new_outlined,
                'opportunity_changed' => Icons.edit_note,
                'source_failure' || 'monitor_failed' => Icons.error_outline,
                _ => Icons.notifications_outlined,
              }, color: n.str('read_at') == null ? context.colors.primary : null),
              title: Text(n.string('title'), style: n.str('read_at') == null ? const TextStyle(fontWeight: FontWeight.w600) : null),
              subtitle: Text([n.str('body'), Fmt.dateTime(context, n.str('created_at'))].whereType<String>().join(' · ')),
              onTap: () async {
                await api.postJson('/notifications/read', body: {'ids': [n.string('id')]});
                ref.invalidate(notificationsProvider);
                final payload = n.obj('payload');
                if (!context.mounted) return;
                if (payload.str('saved_id') != null) {
                  unawaited(context.push('/saved/${payload.string('saved_id')}'));
                } else if (payload.str('run_id') != null) {
                  context.go('/search?run=${payload.string('run_id')}');
                } else if (payload.str('opportunity_id') != null) {
                  unawaited(context.push('/opportunities/${payload.string('opportunity_id')}'));
                }
              },
            ),
          ),
      ]),
    );
  }
}
