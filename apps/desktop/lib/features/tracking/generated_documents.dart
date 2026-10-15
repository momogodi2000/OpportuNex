import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart' show Json;
import '../../core/api/json.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/layout.dart';
import '../../l10n/app_localizations.dart';
import 'status_labels.dart';
import 'tracking_repository.dart';

final generatedListProvider = FutureProvider.autoDispose.family<List<Json>, String>(
    (ref, savedId) => ref.watch(trackingRepositoryProvider).generated(savedId));

class GeneratedDocuments extends ConsumerWidget {
  const GeneratedDocuments({super.key, required this.savedId});
  final String savedId;

  static const types = ['cover_letter', 'scholarship_statement', 'grant_proposal', 'project_summary',
    'application_email', 'cv_suggestions', 'interview_prep'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final docs = ref.watch(generatedListProvider(savedId)).valueOrNull ?? const <Json>[];
    final lang = Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'fr';
    return SectionCard(
      title: l.genTitle,
      subtitle: l.genSubtitle,
      trailing: PopupMenuButton<String>(
        tooltip: l.genCreate,
        icon: const Icon(Icons.post_add),
        onSelected: (t) async {
          try {
            final doc = await ref.read(trackingRepositoryProvider).generate(savedId, t, lang);
            ref.invalidate(generatedListProvider(savedId));
            if (context.mounted) {
              await showDialog<void>(context: context, builder: (_) => _Editor(docId: doc.string('id')));
              ref.invalidate(generatedListProvider(savedId));
            }
          } on Object catch (e) {
            if (context.mounted) showError(context, e);
          }
        },
        itemBuilder: (_) => [for (final t in types) PopupMenuItem(value: t, child: Text(docTypeLabel(l, t)))],
      ),
      child: docs.isEmpty
          ? Text(l.genEmpty)
          : Column(children: [
              for (final d in docs)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(d.string('title')),
                  subtitle: Text('${docTypeLabel(l, d.string('doc_type'))} · v${d.integer('current_version')} · '
                      '${Fmt.dateTime(context, d.str('updated_at'))}'),
                  onTap: () async {
                    await showDialog<void>(context: context, builder: (_) => _Editor(docId: d.string('id')));
                    ref.invalidate(generatedListProvider(savedId));
                  },
                ),
            ]),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.docId});
  final String docId;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  final _c = TextEditingController();
  Json? _doc;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await ref.read(trackingRepositoryProvider).generatedDoc(widget.docId);
    if (!mounted) return;
    setState(() {
      _doc = doc;
      _c.text = doc.string('content');
      _dirty = false;
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final doc = await ref.read(trackingRepositoryProvider).saveVersion(widget.docId, _c.text);
      setState(() {
        _doc = doc;
        _dirty = false;
      });
      if (mounted) showSuccess(context, AppLocalizations.of(context).genSaved);
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _export(String format) async {
    final l = AppLocalizations.of(context);
    final target = await FilePicker.platform.saveFile(fileName: 'document.$format');
    if (target == null) return;
    try {
      await File(target).writeAsBytes(await ref.read(trackingRepositoryProvider).exportGenerated(widget.docId, format));
      if (mounted) showSuccess(context, l.exportDone);
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final doc = _doc;
    final flags = doc == null ? const <String>[] : doc.list('versions').first.strings('integrity_flags');
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: doc == null
              ? const Center(child: CircularProgressIndicator())
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(child: Text(doc.string('title'), style: context.text.titleLarge)),
                    Text('v${doc.integer('current_version')}', style: context.text.labelLarge),
                  ]),
                  const SizedBox(height: Space.sm),
                  Container(
                    padding: const EdgeInsets.all(Space.sm),
                    decoration: BoxDecoration(color: context.status.ai, borderRadius: Radii.control),
                    child: Text(l.genNotice, style: TextStyle(color: context.status.onAi)),
                  ),
                  if (flags.isNotEmpty) ...[
                    const SizedBox(height: Space.sm),
                    Container(
                      padding: const EdgeInsets.all(Space.sm),
                      decoration: BoxDecoration(color: context.status.danger, borderRadius: Radii.control),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l.genIntegrityTitle, style: TextStyle(color: context.status.onDanger, fontWeight: FontWeight.w600)),
                        for (final f in flags) Text('• ${f.split(':').skip(1).join(':')}', style: TextStyle(color: context.status.onDanger)),
                      ]),
                    ),
                  ],
                  const SizedBox(height: Space.md),
                  Expanded(
                    child: TextField(
                      controller: _c,
                      expands: true,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      onChanged: (_) => setState(() => _dirty = true),
                      decoration: const InputDecoration(alignLabelWithHint: true),
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  Row(children: [
                    for (final f in const ['docx', 'pdf', 'md'])
                      Padding(
                        padding: const EdgeInsets.only(right: Space.sm),
                        child: OutlinedButton(onPressed: _dirty ? null : () => _export(f), child: Text(f.toUpperCase())),
                      ),
                    const Spacer(),
                    TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonClose)),
                    const SizedBox(width: Space.sm),
                    FilledButton(onPressed: _dirty ? _save : null, child: Text(l.genSaveVersion)),
                  ]),
                ]),
        ),
      ),
    );
  }
}
