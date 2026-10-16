import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../core/api/api_client.dart' show Json;
import '../../core/api/json.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';
import '../ai/ai_consent.dart';
import '../ai/ai_repository.dart';
import 'profile_repository.dart';

/// CV import (M03): upload → isolated parsing → validate each item → apply (EF-03.01..05).
class CvImportPage extends ConsumerStatefulWidget {
  const CvImportPage({super.key});

  @override
  ConsumerState<CvImportPage> createState() => _CvImportPageState();
}

class _CvImportPageState extends ConsumerState<CvImportPage> {
  Json? _import;
  bool _keepFile = false;
  bool _useAi = false;
  bool _busy = false;

  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  Future<void> _pick() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf', 'docx', 'txt']);
    final path = picked?.files.single.path;
    if (path == null) return;
    setState(() => _busy = true);
    try {
      final name = p.basename(path);
      final bytes = await File(path).readAsBytes();
      if (!mounted) return;
      final imp = await withAiConsent(context, ref, () => _repo.uploadCv(name, bytes, _keepFile, useAi: _useAi),
          withoutAi: () => _repo.uploadCv(name, bytes, _keepFile));
      if (imp != null) setState(() => _import = imp);
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decide(Json item, String decision, {Json? payload}) async {
    try {
      final imp = await _repo.decide(_import!.string('id'), item.integer('id')!, decision, payload: payload);
      setState(() => _import = imp);
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _apply() async {
    final l = AppLocalizations.of(context);
    try {
      final r = await _repo.applyCv(_import!.string('id'));
      ref.invalidate(profileProvider);
      if (!mounted) return;
      showSuccess(context, l.cvApplied(r.integer('applied') ?? 0));
      context.go('/profile');
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final imp = _import;
    return PageFrame(
      title: l.cvImport,
      subtitle: l.cvSubtitle,
      actions: [
        if (imp != null) ...[
          OutlinedButton(
            onPressed: () async {
              await _repo.discardCv(imp.string('id'));
              setState(() => _import = null);
            },
            child: Text(l.cvDiscard),
          ),
          FilledButton.icon(onPressed: _apply, icon: const Icon(Icons.done_all), label: Text(l.cvApply)),
        ],
      ],
      child: imp == null
          ? SectionCard(
              child: Column(children: [
                EmptyState(icon: Icons.upload_file, title: l.cvPickTitle, message: l.cvPickBody,
                    action: FilledButton.icon(
                      onPressed: _busy ? null : _pick,
                      icon: _busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.folder_open),
                      label: Text(l.cvPick),
                    )),
                if (ref.watch(aiAvailableProvider).valueOrNull ?? false)
                  SwitchListTile(
                    value: _useAi,
                    onChanged: (v) => setState(() => _useAi = v),
                    secondary: const Icon(Icons.auto_awesome),
                    title: Text(l.cvUseAi),
                    subtitle: Text(l.cvUseAiHelp),
                  ),
                SwitchListTile(
                  value: _keepFile,
                  onChanged: (v) => setState(() => _keepFile = v),
                  title: Text(l.cvKeepFile),
                  subtitle: Text(l.cvKeepFileHelp),
                ),
              ]),
            )
          : _Review(imp: imp, onDecide: _decide),
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({required this.imp, required this.onDecide});
  final Json imp;
  final Future<void> Function(Json item, String decision, {Json? payload}) onDecide;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final groups = <String, List<Json>>{};
    for (final i in imp.list('items')) {
      groups.putIfAbsent(i.string('item_type'), () => []).add(i);
    }
    final labels = {'identity': l.cvIdentity, 'education': l.pfEducation, 'experience': l.pfExperience,
      'skill': l.pfSkills, 'language': l.pfLanguages, 'certification': l.pfCertifications, 'link': l.pfLinks};
    if (groups.isEmpty) return EmptyState(icon: Icons.search_off, title: l.cvNothingFound, message: l.cvNothingFoundBody);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.cvReviewHelp, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
      const SizedBox(height: Space.lg),
      for (final g in groups.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.lg),
          child: SectionCard(
            title: labels[g.key] ?? g.key,
            child: Column(children: [
              for (final i in g.value) _ItemRow(item: i, onDecide: onDecide),
            ]),
          ),
        ),
    ]);
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onDecide});
  final Json item;
  final Future<void> Function(Json item, String decision, {Json? payload}) onDecide;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final payload = item.obj('payload');
    final decision = item.string('decision');
    final text = payload.entries.where((e) => e.value != null && '${e.value}'.isNotEmpty && e.value != false)
        .map((e) => '${e.value}').join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(switch (decision) {
        'accepted' || 'edited' => Icons.check_circle,
        'rejected' => Icons.cancel,
        _ => Icons.radio_button_unchecked,
      }, color: decision == 'rejected' ? context.colors.error : (decision == 'pending' ? null : context.colors.primary)),
      title: Text(text),
      subtitle: Text(l.cvConfidence(((item.number('confidence') ?? 0) * 100).round())),
      trailing: Wrap(spacing: Space.xs, children: [
        IconButton(tooltip: l.cvAccept, icon: const Icon(Icons.check), onPressed: () => onDecide(item, 'accepted')),
        IconButton(
          tooltip: l.commonEdit,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () async {
            final edited = await _editPayload(context, payload);
            if (edited != null) await onDecide(item, 'accepted', payload: edited);
          },
        ),
        IconButton(tooltip: l.cvReject, icon: const Icon(Icons.close), onPressed: () => onDecide(item, 'rejected')),
      ]),
    );
  }

  Future<Json?> _editPayload(BuildContext context, Json payload) {
    final l = AppLocalizations.of(context);
    final controllers = {for (final e in payload.entries) if (e.value is! bool) e.key: TextEditingController(text: '${e.value ?? ''}')};
    return showDialog<Json>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.commonEdit),
        content: SizedBox(
          width: 480,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final c in controllers.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: TextField(controller: c.value, decoration: InputDecoration(labelText: c.key)),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, <String, dynamic>{
              ...payload,
              for (final c in controllers.entries) c.key: c.value.text.trim().isEmpty ? null : c.value.text.trim(),
            }),
            child: Text(l.commonSave),
          ),
        ],
      ),
    ).whenComplete(() {
      for (final c in controllers.values) {
        c.dispose();
      }
    });
  }
}
