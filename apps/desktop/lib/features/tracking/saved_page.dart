import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart' show Json;
import '../../core/api/json.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/opportunity_widgets.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';
import 'status_labels.dart';
import 'tracking_repository.dart';

/// Saved opportunities and applications: list, Kanban board, calendar.
class TrackingPage extends ConsumerStatefulWidget {
  const TrackingPage({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends ConsumerState<TrackingPage> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTab.clamp(0, 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.xxl, Space.xl, Space.xxl, 0),
          child: Semantics(header: true, child: Text(l.navSaved, style: context.text.headlineSmall)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          child: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [
            Tab(icon: const Icon(Icons.list_alt), text: l.trackList),
            Tab(icon: const Icon(Icons.view_kanban_outlined), text: l.trackBoard),
            Tab(icon: const Icon(Icons.calendar_month_outlined), text: l.trackCalendar),
          ]),
        ),
        const Divider(),
        const Expanded(child: TabBarView(children: [_SavedList(), BoardView(), CalendarView()])),
      ]),
    );
  }
}

class _SavedList extends ConsumerStatefulWidget {
  const _SavedList();

  @override
  ConsumerState<_SavedList> createState() => _SavedListState();
}

class _SavedListState extends ConsumerState<_SavedList> {
  SavedQuery _q = const SavedQuery();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final value = ref.watch(savedListProvider(_q));
    final tags = ref.watch(tagsProvider).valueOrNull ?? const <Json>[];
    return ListView(padding: const EdgeInsets.all(Space.xxl), children: [
      Wrap(spacing: Space.md, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(
          width: 280,
          child: TextField(
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.trackSearchHint, isDense: true),
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () => setState(() => _q = _q.copyWith(text: v)));
            },
          ),
        ),
        DropdownButton<String?>(
          value: _q.status,
          hint: Text(l.trackStatus),
          items: [
            DropdownMenuItem(child: Text(l.trackAllStatuses)),
            for (final s in applicationStatuses) DropdownMenuItem(value: s, child: Text(applicationStatusLabel(l, s))),
          ],
          onChanged: (v) => setState(() => _q = v == null ? _q.copyWith(clearStatus: true) : _q.copyWith(status: v)),
        ),
        DropdownButton<String?>(
          value: _q.priority,
          hint: Text(l.trackPriority),
          items: [
            DropdownMenuItem(child: Text(l.trackAllPriorities)),
            for (final p in const ['high', 'medium', 'low']) DropdownMenuItem(value: p, child: Text(priorityLabel(l, p))),
          ],
          onChanged: (v) => setState(() => _q = v == null ? _q.copyWith(clearPriority: true) : _q.copyWith(priority: v)),
        ),
        if (tags.isNotEmpty)
          DropdownButton<String?>(
            value: _q.tag,
            hint: Text(l.trackTag),
            items: [
              DropdownMenuItem(child: Text(l.trackAllTags)),
              for (final t in tags) DropdownMenuItem(value: t.string('name'), child: Text(t.string('name'))),
            ],
            onChanged: (v) => setState(() => _q = v == null ? _q.copyWith(clearTag: true) : _q.copyWith(tag: v)),
          ),
        FilterChip(
          label: Text(l.trackArchived),
          selected: _q.archived,
          onSelected: (v) => setState(() => _q = _q.copyWith(archived: v)),
        ),
      ]),
      const SizedBox(height: Space.lg),
      AsyncView<List<Json>>(
        value: value,
        onRetry: () => ref.invalidate(savedListProvider(_q)),
        isEmpty: (list) => list.isEmpty,
        empty: EmptyState(
          icon: Icons.bookmarks_outlined,
          title: l.trackEmptyTitle,
          message: l.trackEmptyBody,
          action: FilledButton.icon(onPressed: () => context.go('/search'), icon: const Icon(Icons.search),
              label: Text(l.navSearch)),
        ),
        data: (list) => Column(children: [
          for (final s in list)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: OpportunityCard(
                data: s.obj('opportunity'),
                onOpen: () => context.push('/saved/${s.string('id')}'),
                trailing: Column(children: [
                  Chip(
                    avatar: Icon(applicationStatusIcon(s.obj('application').string('status')), size: 16),
                    label: Text(applicationStatusLabel(l, s.obj('application').string('status'))),
                  ),
                  Text('${s.obj('checklist_progress').integer('done')}/${s.obj('checklist_progress').integer('total')}',
                      style: context.text.labelSmall),
                ]),
              ),
            ),
        ]),
      ),
    ]);
  }
}

class BoardView extends ConsumerWidget {
  const BoardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return AsyncView<Json>(
      value: ref.watch(boardProvider),
      onRetry: () => ref.invalidate(boardProvider),
      data: (board) {
        final transitions = board.obj('transitions');
        return Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(Space.xl),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final col in board.list('columns'))
                _Column(
                  status: col.string('status'),
                  items: col.list('items'),
                  canAccept: (fromStatus) => ((transitions[fromStatus] as List<dynamic>?) ?? const []).contains(col.string('status')),
                  onDrop: (item) async {
                    final target = col.string('status');
                    Json body = {'status': target};
                    if (target == 'submitted') {
                      final date = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime.now(),
                          helpText: l.trackSubmittedOn);
                      if (date == null) return;
                      body = {...body, 'submitted_on': date.toIso8601String().substring(0, 10)};
                    }
                    try {
                      await ref.read(trackingRepositoryProvider).transition(item.string('application_id'), body);
                      ref.invalidate(boardProvider);
                    } on Object catch (e) {
                      if (context.mounted) showError(context, e);
                    }
                  },
                ),
            ]),
          ),
        );
      },
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.status, required this.items, required this.canAccept, required this.onDrop});
  final String status;
  final List<Json> items;
  final bool Function(String fromStatus) canAccept;
  final ValueChanged<Json> onDrop;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DragTarget<Json>(
      onWillAcceptWithDetails: (d) => canAccept(d.data.obj('application').string('status')),
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) => Container(
        width: 260,
        margin: const EdgeInsets.only(right: Space.md),
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? context.colors.primaryContainer : context.colors.surfaceContainer,
          borderRadius: Radii.card,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.all(Space.sm),
            child: Row(children: [
              Icon(applicationStatusIcon(status), size: 18),
              const SizedBox(width: Space.xs),
              Expanded(child: Text(applicationStatusLabel(l, status), style: context.text.titleSmall)),
              Text('${items.length}', style: context.text.labelMedium),
            ]),
          ),
          for (final item in items)
            Draggable<Json>(
              data: item,
              feedback: Material(elevation: 6, borderRadius: Radii.card, child: SizedBox(width: 240, child: _BoardCard(item))),
              childWhenDragging: Opacity(opacity: 0.4, child: _BoardCard(item)),
              child: _BoardCard(item),
            ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Text(l.trackDropHere, textAlign: TextAlign.center, style: context.text.bodySmall),
            ),
        ]),
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard(this.item);
  final Json item;

  @override
  Widget build(BuildContext context) {
    final opp = item.obj('opportunity');
    return Card(
      margin: const EdgeInsets.only(bottom: Space.sm),
      child: InkWell(
        onTap: () => context.push('/saved/${item.string('id')}'),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(opp.string('title'), maxLines: 3, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium),
            const SizedBox(height: Space.xs),
            Text(Fmt.date(context, opp.str('deadline_on')), style: context.text.labelSmall),
          ]),
        ),
      ),
    );
  }
}

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final start = DateTime(_month.year, _month.month);
    final end = DateTime(_month.year, _month.month + 1, 0);
    String fmt(DateTime d) => d.toIso8601String().substring(0, 10);
    return FutureBuilder<List<Json>>(
      future: ref.read(trackingRepositoryProvider).calendar(fmt(start), fmt(end)),
      builder: (context, snap) {
        final events = snap.data ?? const <Json>[];
        return ListView(padding: const EdgeInsets.all(Space.xxl), children: [
          Row(children: [
            IconButton(tooltip: l.calPrev, icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
            Text(MaterialLocalizations.of(context).formatMonthYear(_month), style: context.text.titleMedium),
            IconButton(tooltip: l.calNext, icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
            const Spacer(),
            OutlinedButton.icon(
              icon: const Icon(Icons.ios_share),
              label: Text(l.calExportIcs),
              onPressed: () async {
                final target = await FilePicker.platform.saveFile(fileName: 'opportunex.ics');
                if (target == null) return;
                try {
                  await File(target).writeAsBytes(await ref.read(trackingRepositoryProvider).ics());
                  if (context.mounted) showSuccess(context, l.exportDone);
                } on Object catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
            ),
          ]),
          const SizedBox(height: Space.md),
          if (snap.connectionState != ConnectionState.done) const LoadingState()
          else if (events.isEmpty) EmptyState(icon: Icons.event_available, title: l.calEmpty)
          else
            for (final e in events)
              Card(
                margin: const EdgeInsets.only(bottom: Space.sm),
                child: ListTile(
                  leading: Icon(switch (e.string('type')) {
                    'deadline' => Icons.flag_outlined,
                    'personal_deadline' => Icons.outlined_flag,
                    'interview' => Icons.record_voice_over_outlined,
                    _ => Icons.event,
                  }),
                  title: Text(e.string('title')),
                  subtitle: Text('${Fmt.dateTime(context, e.str('date'))} · ${_typeLabel(l, e.string('type'))}'),
                  onTap: () => context.push('/saved/${e.string('saved_id')}'),
                ),
              ),
        ]);
      },
    );
  }

  String _typeLabel(AppLocalizations l, String t) => switch (t) {
        'deadline' => l.calDeadline,
        'personal_deadline' => l.calPersonalDeadline,
        'interview' => l.evInterview,
        _ => t,
      };
}
