import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../core/api/api_client.dart' show Json;
import '../../core/api/json.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';
import 'generated_documents.dart';
import 'status_labels.dart';
import 'tracking_repository.dart';

/// One saved opportunity and its application file (EF-12.01..08, EF-10.05..11).
class ApplicationPage extends ConsumerWidget {
  const ApplicationPage({super.key, required this.savedId});
  final String savedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<Json>(
      value: ref.watch(savedItemProvider(savedId)),
      onRetry: () => ref.invalidate(savedItemProvider(savedId)),
      data: (saved) {
        final appId = saved.obj('application').string('id');
        return AsyncView<Json>(
          value: ref.watch(applicationProvider(appId)),
          onRetry: () => ref.invalidate(applicationProvider(appId)),
          data: (app) => _Body(saved: saved, app: app),
        );
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.saved, required this.app});
  final Json saved;
  final Json app;

  String get savedId => saved.string('id');
  String get appId => app.string('id');

  void _refresh(WidgetRef ref) {
    ref.invalidate(savedItemProvider(savedId));
    ref.invalidate(applicationProvider(appId));
  }

  Future<void> _run(BuildContext context, WidgetRef ref, Future<Object?> Function() fn, {String? done}) async {
    try {
      await fn();
      _refresh(ref);
      if (done != null && context.mounted) showSuccess(context, done);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(trackingRepositoryProvider);
    final opp = saved.obj('opportunity');
    final status = app.string('status');
    return PageFrame(
      title: opp.string('title'),
      subtitle: opp.str('organization_name'),
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.push('/opportunities/${opp.string('id')}'),
          icon: const Icon(Icons.article_outlined),
          label: Text(l.trackOpenSheet),
        ),
        PopupMenuButton<String>(
          tooltip: l.oppMore,
          onSelected: (v) async {
            if (v == 'delete') {
              final ok = await confirmAction(context, title: l.trackUnsave, message: l.trackUnsaveConfirm,
                  confirmLabel: l.commonDelete, destructive: true);
              if (!ok) return;
              await repo.unsave(savedId);
              if (context.mounted) context.go('/saved');
            } else {
              await _run(context, ref, () => repo.patchSaved(savedId, {'archived': v == 'archive'}));
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: saved.flag('archived') ? 'unarchive' : 'archive',
                child: Text(saved.flag('archived') ? l.trackUnarchive : l.trackArchive)),
            PopupMenuItem(value: 'delete', child: Text(l.trackUnsave)),
          ],
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _StatusBar(status: status, allowed: app.strings('allowed_transitions'),
            onTransition: (target) => _transition(context, ref, target)),
        const SizedBox(height: Space.lg),
        LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth > 1000;
          final left = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Checklist(savedId: savedId, items: app.list('checklist'), onChanged: () => _refresh(ref)),
            const SizedBox(height: Space.lg),
            _Documents(savedId: savedId, docs: app.list('documents'), checklist: app.list('checklist'),
                onChanged: () => _refresh(ref)),
            const SizedBox(height: Space.lg),
            GeneratedDocuments(savedId: savedId),
          ]);
          final right = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Settings(saved: saved, onPatch: (v) => _run(context, ref, () => repo.patchSaved(savedId, v))),
            const SizedBox(height: Space.lg),
            _Events(appId: appId, events: app.list('events'), onChanged: () => _refresh(ref)),
            const SizedBox(height: Space.lg),
            _Notes(savedId: savedId),
            const SizedBox(height: Space.lg),
            _History(history: app.list('history'), reminders: app.list('reminders')),
          ]);
          return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: left),
                  const SizedBox(width: Space.xl),
                  Expanded(flex: 2, child: right),
                ])
              : Column(children: [left, const SizedBox(height: Space.lg), right]);
        }),
      ]),
    );
  }

  Future<void> _transition(BuildContext context, WidgetRef ref, String target) async {
    final l = AppLocalizations.of(context);
    final body = <String, dynamic>{'status': target};
    if (target == 'submitted') {
      final date = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime.now(),
          helpText: l.trackSubmittedOn);
      if (date == null || !context.mounted) return;
      body['submitted_on'] = date.toIso8601String().substring(0, 10);
    }
    if (!context.mounted) return;
    await _run(context, ref, () => ref.read(trackingRepositoryProvider).transition(appId, body),
        done: l.trackStatusChanged(applicationStatusLabel(l, target)));
  }
}

/// Next steps are offered in lifecycle order; closing states come last (EF-12.04).
const _lifecycle = ['discovered', 'to_review', 'preparing', 'ready', 'submitted', 'interview', 'accepted', 'rejected',
  'withdrawn', 'expired', 'archived'];

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.status, required this.allowed, required this.onTransition});
  final String status;
  final List<String> allowed;
  final ValueChanged<String> onTransition;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: Space.md, runSpacing: Space.sm, children: [
        Chip(
          avatar: Icon(applicationStatusIcon(status)),
          label: Text(applicationStatusLabel(l, status), style: context.text.titleSmall),
        ),
        const Icon(Icons.arrow_forward, size: 18),
        for (final t in [..._lifecycle.where(allowed.contains), ...allowed.where((s) => !_lifecycle.contains(s))])
          OutlinedButton.icon(onPressed: () => onTransition(t), icon: Icon(applicationStatusIcon(t), size: 18),
              label: Text(applicationStatusLabel(l, t))),
      ]),
    );
  }
}

class _Settings extends StatelessWidget {
  const _Settings({required this.saved, required this.onPatch});
  final Json saved;
  final ValueChanged<Json> onPatch;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      title: l.trackSettings,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.trackPriority, style: context.text.labelLarge),
        const SizedBox(height: Space.xs),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [for (final p in const ['high', 'medium', 'low']) ButtonSegment(value: p, label: Text(priorityLabel(l, p)))],
          selected: {saved.string('priority', 'medium')},
          onSelectionChanged: (s) => onPatch({'priority': s.first}),
        ),
        const SizedBox(height: Space.md),
        Text(l.trackInterest, style: context.text.labelLarge),
        const SizedBox(height: Space.xs),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 'interested', label: Text(l.trackInterested)),
            ButtonSegment(value: 'undecided', label: Text(l.trackUndecided)),
            ButtonSegment(value: 'ineligible', label: Text(l.trackIneligible)),
          ],
          selected: {saved.string('interest', 'interested')},
          onSelectionChanged: (s) async {
            if (s.first == 'ineligible') {
              final reason = await _ask(context, l.trackIneligibleReason);
              if (reason == null || reason.isEmpty) return;
              onPatch({'interest': 'ineligible', 'ineligible_reason': reason});
            } else {
              onPatch({'interest': s.first});
            }
          },
        ),
        if (saved.str('ineligible_reason') != null) Text(saved.string('ineligible_reason'), style: context.text.bodySmall),
        const SizedBox(height: Space.md),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.outlined_flag),
          title: Text(l.trackPersonalDeadline),
          subtitle: Text(saved.str('personal_deadline') == null ? l.trackNoPersonalDeadline
              : Fmt.date(context, saved.str('personal_deadline'))),
          trailing: TextButton(
            child: Text(l.commonEdit),
            onPressed: () async {
              final d = await showDatePicker(context: context, firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3 * 365)));
              if (d != null) onPatch({'personal_deadline': d.toIso8601String().substring(0, 10)});
            },
          ),
        ),
        _TagEditor(savedId: saved.string('id'), tags: saved.strings('tags')),
      ]),
    );
  }
}

Future<String?> _ask(BuildContext context, String title, {String initial = '', int lines = 1}) {
  final l = AppLocalizations.of(context);
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(width: 420, child: TextField(controller: c, autofocus: true, minLines: lines, maxLines: lines + 4)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(l.commonSave)),
      ],
    ),
  ).whenComplete(c.dispose);
}

class _TagEditor extends ConsumerWidget {
  const _TagEditor({required this.savedId, required this.tags});
  final String savedId;
  final List<String> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    Future<void> set(List<String> next) async {
      await ref.read(trackingRepositoryProvider).setTags(savedId, next);
      ref.invalidate(savedItemProvider(savedId));
      ref.invalidate(tagsProvider);
    }

    return Wrap(spacing: Space.xs, runSpacing: Space.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
      for (final t in tags) InputChip(label: Text(t), onDeleted: () => set([...tags]..remove(t))),
      ActionChip(
        avatar: const Icon(Icons.sell_outlined, size: 16),
        label: Text(l.trackAddTag),
        onPressed: () async {
          final t = await _ask(context, l.trackAddTag);
          if (t != null && t.isNotEmpty) await set([...tags, t]);
        },
      ),
    ]);
  }
}

class _Checklist extends ConsumerWidget {
  const _Checklist({required this.savedId, required this.items, required this.onChanged});
  final String savedId;
  final List<Json> items;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(trackingRepositoryProvider);
    final done = items.where((i) => i.flag('is_done')).length;
    return SectionCard(
      title: l.trackChecklist,
      subtitle: items.isEmpty ? null : l.trackChecklistProgress(done, items.length),
      trailing: IconButton(
        tooltip: l.trackAddItem,
        icon: const Icon(Icons.add),
        onPressed: () async {
          final label = await _ask(context, l.trackAddItem);
          if (label == null || label.isEmpty) return;
          await repo.addCheck(savedId, label);
          onChanged();
        },
      ),
      child: items.isEmpty
          ? Text(l.trackChecklistEmpty)
          : Column(children: [
              if (items.isNotEmpty)
                LinearProgressIndicator(value: done / items.length, borderRadius: BorderRadius.circular(Radii.pill)),
              for (final i in items)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: i.flag('is_done'),
                  title: Text(i.string('label')),
                  subtitle: i.string('origin') == 'requirement' ? Text(l.trackFromListing) : null,
                  onChanged: (v) async {
                    await repo.patchCheck(savedId, i.integer('id')!, {'is_done': v ?? false});
                    onChanged();
                  },
                  secondary: IconButton(
                    tooltip: l.commonDelete,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () async {
                      await repo.deleteCheck(savedId, i.integer('id')!);
                      onChanged();
                    },
                  ),
                ),
            ]),
    );
  }
}

class _Documents extends ConsumerWidget {
  const _Documents({required this.savedId, required this.docs, required this.checklist, required this.onChanged});
  final String savedId;
  final List<Json> docs;
  final List<Json> checklist;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(trackingRepositoryProvider);
    return SectionCard(
      title: l.trackDocuments,
      subtitle: l.trackDocumentsHelp,
      trailing: IconButton(
        tooltip: l.trackAttach,
        icon: const Icon(Icons.attach_file),
        onPressed: () async {
          final picked = await FilePicker.platform.pickFiles(withData: false);
          final path = picked?.files.single.path;
          if (path == null || !context.mounted) return;
          final label = await _ask(context, l.trackDocumentLabel, initial: p.basenameWithoutExtension(path));
          if (label == null) return;
          try {
            await repo.attach(savedId, p.basename(path), await File(path).readAsBytes(), label.isEmpty ? p.basename(path) : label);
            onChanged();
          } on Object catch (e) {
            if (context.mounted) showError(context, e);
          }
        },
      ),
      child: docs.isEmpty
          ? Text(l.trackNoDocuments)
          : Column(children: [
              for (final d in docs)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_outline),
                  title: Text(d.string('label')),
                  subtitle: Text('${d.string('file_name')} · ${Fmt.bytes(d.integer('file_size') ?? 0)}'),
                  trailing: Wrap(children: [
                    IconButton(
                      tooltip: l.trackDownload,
                      icon: const Icon(Icons.download),
                      onPressed: () async {
                        final target = await FilePicker.platform.saveFile(fileName: d.string('file_name'));
                        if (target == null) return;
                        await File(target).writeAsBytes(await repo.document(savedId, d.string('id')));
                        if (context.mounted) showSuccess(context, l.exportDone);
                      },
                    ),
                    IconButton(
                      tooltip: l.commonDelete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await repo.deleteDocument(savedId, d.string('id'));
                        onChanged();
                      },
                    ),
                  ]),
                ),
            ]),
    );
  }
}

class _Events extends ConsumerWidget {
  const _Events({required this.appId, required this.events, required this.onChanged});
  final String appId;
  final List<Json> events;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(trackingRepositoryProvider);
    return SectionCard(
      title: l.trackEvents,
      trailing: IconButton(
        tooltip: l.trackAddEvent,
        icon: const Icon(Icons.add),
        onPressed: () async {
          final result = await showDialog<Json>(context: context, builder: (_) => const _EventDialog());
          if (result == null) return;
          try {
            await repo.addEvent(appId, result);
            onChanged();
          } on Object catch (e) {
            if (context.mounted) showError(context, e);
          }
        },
      ),
      child: events.isEmpty
          ? Text(l.trackNoEvents)
          : Column(children: [
              for (final e in events)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: e.flag('done'),
                  title: Text(e.string('title')),
                  subtitle: Text([Fmt.dateTime(context, e.str('scheduled_at')), e.str('location'), e.str('contact_name')]
                      .whereType<String>().join(' · ')),
                  onChanged: (v) async {
                    await repo.patchEvent(appId, e.string('id'), {'done': v ?? false});
                    onChanged();
                  },
                ),
            ]),
    );
  }
}

class _EventDialog extends StatefulWidget {
  const _EventDialog();

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _contact = TextEditingController();
  String _type = 'interview';
  DateTime? _when;

  @override
  void dispose() {
    for (final c in [_title, _location, _contact]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.trackAddEvent),
      content: SizedBox(
        width: 440,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: InputDecoration(labelText: l.trackEventType),
            items: [
              DropdownMenuItem(value: 'interview', child: Text(l.evInterview)),
              DropdownMenuItem(value: 'test', child: Text(l.evTest)),
              DropdownMenuItem(value: 'follow_up', child: Text(l.evFollowUp)),
              DropdownMenuItem(value: 'call', child: Text(l.evCall)),
              DropdownMenuItem(value: 'meeting', child: Text(l.evMeeting)),
              DropdownMenuItem(value: 'other', child: Text(l.evOther)),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'other'),
          ),
          const SizedBox(height: Space.md),
          TextField(controller: _title, decoration: InputDecoration(labelText: l.trackEventTitle)),
          const SizedBox(height: Space.md),
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule),
            label: Text(_when == null ? l.trackEventWhen : Fmt.dateTime(context, _when!.toIso8601String())),
            onPressed: () async {
              final d = await showDatePicker(context: context, firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 3 * 365)));
              if (d == null || !context.mounted) return;
              final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
              if (t == null) return;
              setState(() => _when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
            },
          ),
          const SizedBox(height: Space.md),
          TextField(controller: _location, decoration: InputDecoration(labelText: l.trackEventLocation)),
          const SizedBox(height: Space.md),
          TextField(controller: _contact, decoration: InputDecoration(labelText: l.trackEventContact)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: () {
            if (_title.text.trim().isEmpty) return;
            Navigator.pop(context, <String, dynamic>{
              'event_type': _type,
              'title': _title.text.trim(),
              if (_when != null) 'scheduled_at': '${_when!.toUtc().toIso8601String().substring(0, 19)}Z',
              if (_location.text.trim().isNotEmpty) 'location': _location.text.trim(),
              if (_contact.text.trim().isNotEmpty) 'contact_name': _contact.text.trim(),
            });
          },
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}

class _Notes extends ConsumerStatefulWidget {
  const _Notes({required this.savedId});
  final String savedId;

  @override
  ConsumerState<_Notes> createState() => _NotesState();
}

class _NotesState extends ConsumerState<_Notes> {
  final _c = TextEditingController();
  late Future<List<Json>> _future = ref.read(trackingRepositoryProvider).notes(widget.savedId);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = ref.read(trackingRepositoryProvider).notes(widget.savedId));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(trackingRepositoryProvider);
    return SectionCard(
      title: l.trackNotes,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: _c,
          minLines: 2,
          maxLines: 6,
          decoration: InputDecoration(hintText: l.trackNoteHint),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.add_comment_outlined),
            label: Text(l.trackAddNote),
            onPressed: () async {
              if (_c.text.trim().isEmpty) return;
              await repo.addNote(widget.savedId, _c.text.trim());
              _c.clear();
              _reload();
            },
          ),
        ),
        FutureBuilder<List<Json>>(
          future: _future,
          builder: (context, snap) => Column(children: [
            for (final n in snap.data ?? const <Json>[])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: SelectableText(n.string('body')),
                subtitle: Text(Fmt.dateTime(context, n.str('created_at'))),
                trailing: IconButton(
                  tooltip: l.commonDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () async {
                    await repo.deleteNote(widget.savedId, n.string('id'));
                    _reload();
                  },
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.history, required this.reminders});
  final List<Json> history;
  final List<Json> reminders;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      title: l.trackHistory,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final h in history)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(applicationStatusIcon(h.string('to_status')), size: 18),
            title: Text(applicationStatusLabel(l, h.string('to_status'))),
            subtitle: Text([Fmt.dateTime(context, h.str('changed_at')), h.str('note')].whereType<String>().join(' · ')),
          ),
        if (reminders.isNotEmpty) ...[
          const Divider(),
          Text(l.trackReminders, style: context.text.labelLarge),
          for (final r in reminders)
            Text('${Fmt.date(context, r.str('remind_at'))} · ${r.integer('offset_days') == null ? '' : 'J-${r.integer('offset_days')}'} '
                '· ${r.string('status')}', style: context.text.bodySmall),
        ],
      ]),
    );
  }
}
