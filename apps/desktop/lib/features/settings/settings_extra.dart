import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/api/api_client.dart';
import '../../core/api/json.dart';
import '../../core/format.dart';
import '../../core/platform/autostart.dart';
import '../../core/prefs/ui_prefs.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';

final privacyProvider = FutureProvider.autoDispose<Json>((ref) => requireApi(ref).getJson('/privacy'));
final networkProvider = FutureProvider.autoDispose<Json>((ref) => requireApi(ref).getJson('/settings/network'));
final weightsProvider = FutureProvider.autoDispose<Json>((ref) => requireApi(ref).getJson('/matching/weights'));
final trackingSettingsProvider =
    FutureProvider.autoDispose<Json>((ref) => requireApi(ref).getJson('/settings/tracking'));
final autostartProvider = FutureProvider.autoDispose<bool>((ref) => Autostart().isEnabled());
final notifPrefsProvider =
    FutureProvider.autoDispose<List<Json>>((ref) async => items(await requireApi(ref).getJson('/notifications/preferences')));

Widget _body(List<Widget> children) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(padding: const EdgeInsets.all(Space.xxl), children: [
          for (final c in children) Padding(padding: const EdgeInsets.only(bottom: Space.xl), child: c),
        ]),
      ),
    );

/// Privacy dashboard, consents, selective erasure, personal-data export/import (EF-18.07/08, EF-16.07/08).
class PrivacyTab extends ConsumerWidget {
  const PrivacyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final api = ref.read(apiClientProvider)!;
    return AsyncView<Json>(
      value: ref.watch(privacyProvider),
      onRetry: () => ref.invalidate(privacyProvider),
      data: (pv) {
        final stored = pv.obj('stored');
        final profile = stored.obj('profile');
        return _body([
          SectionCard(
            title: l.privStored,
            subtitle: l.privStoredHelp,
            child: Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
              for (final (label, value) in [
                (l.pfEducation, profile.integer('education')), (l.pfExperience, profile.integer('experiences')),
                (l.pfSkills, profile.integer('skills')), (l.privSearches, stored.integer('search_history')),
                (l.privOpportunities, stored.integer('opportunities')), (l.navSaved, stored.integer('saved')),
                (l.trackDocuments, stored.integer('documents')), (l.genTitle, stored.integer('generated_documents')),
                (l.monTabNotifications, stored.integer('notifications')),
              ])
                Chip(label: Text('$label : ${value ?? 0}')),
              Chip(label: Text('${l.maintenanceVault} : ${Fmt.bytes(pv.integer('vault_bytes') ?? 0)}')),
            ]),
          ),
          SectionCard(
            title: l.privDisclosures,
            subtitle: pv.list('disclosures').isEmpty ? l.privNoDisclosures : null,
            child: Column(children: [
              for (final d in pv.list('disclosures'))
                ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.outbox_outlined),
                    title: Text('${d.string('recipient')} — ${d.string('data_category')}'),
                    subtitle: Text('${Fmt.dateTime(context, d.str('disclosed_at'))} · ${Fmt.bytes(d.integer('byte_count') ?? 0)}')),
              ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.block),
                  title: Text(l.privNoTelemetry)),
            ]),
          ),
          SectionCard(
            title: l.privConsents,
            child: Column(children: [
              for (final c in pv.list('consents'))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(c.flag('granted') ? Icons.check_circle_outline : Icons.remove_circle_outline),
                  title: Text(_purpose(l, c.string('purpose'))),
                  subtitle: Text([c.str('target'), Fmt.dateTime(context, c.str('granted_at')),
                    if (c.str('revoked_at') != null) l.privRevokedOn(Fmt.dateTime(context, c.str('revoked_at')))]
                      .whereType<String>().join(' · ')),
                  trailing: c.flag('granted') && !const {'terms', 'privacy_policy'}.contains(c.str('purpose'))
                      ? TextButton(
                          onPressed: () async {
                            await api.postJson('/privacy/consents/${c.string('id')}/revoke');
                            ref.invalidate(privacyProvider);
                          },
                          child: Text(l.privRevoke))
                      : null,
                ),
            ]),
          ),
          SectionCard(
            title: l.privPortability,
            subtitle: l.privPortabilityHelp,
            child: Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.archive_outlined),
                label: Text(l.privExportAll),
                onPressed: () async {
                  final target = await FilePicker.platform.saveFile(fileName: 'opportunex-mes-donnees.zip');
                  if (target == null) return;
                  try {
                    await File(target).writeAsBytes(await api.postBytes('/exports/personal-data'));
                    if (context.mounted) showSuccess(context, l.exportDone);
                  } on Object catch (e) {
                    if (context.mounted) showError(context, e);
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.file_upload_outlined),
                label: Text(l.privImportJson),
                onPressed: () async {
                  final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['json']);
                  final path = picked?.files.single.path;
                  if (path == null) return;
                  try {
                    final r = await api.upload('/imports/json', fileName: p.basename(path), bytes: await File(path).readAsBytes());
                    if (context.mounted) showSuccess(context, l.privImported(r.integer('saved') ?? 0));
                  } on Object catch (e) {
                    if (context.mounted) showError(context, e);
                  }
                },
              ),
            ]),
          ),
          _EraseCard(onDone: () => ref.invalidate(privacyProvider)),
        ]);
      },
    );
  }

  String _purpose(AppLocalizations l, String p) => switch (p) {
        'terms' => l.legalTerms,
        'privacy_policy' => l.legalPrivacy,
        'ai_remote_processing' || 'profile_to_ai' || 'cv_parsing_ai' => l.privConsentAi,
        'sync' => l.privConsentSync,
        _ => p,
      };
}

class _EraseCard extends ConsumerStatefulWidget {
  const _EraseCard({required this.onDone});
  final VoidCallback onDone;

  @override
  ConsumerState<_EraseCard> createState() => _EraseCardState();
}

class _EraseCardState extends ConsumerState<_EraseCard> {
  final Set<String> _kinds = {};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final options = {
      'search_history': l.eraseHistory, 'documents': l.eraseDocuments, 'unsaved_opportunities': l.eraseOpportunities,
      'notifications': l.eraseNotifications, 'profile_details': l.eraseProfile, 'logs': l.eraseLogs,
    };
    return SectionCard(
      title: l.eraseTitle,
      subtitle: l.eraseHelp,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final o in options.entries)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _kinds.contains(o.key),
            onChanged: (v) => setState(() => v == true ? _kinds.add(o.key) : _kinds.remove(o.key)),
            title: Text(o.value),
          ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: context.colors.error),
          icon: const Icon(Icons.delete_sweep_outlined),
          label: Text(l.eraseAction),
          onPressed: _kinds.isEmpty ? null : () async {
            final ok = await confirmAction(context, title: l.eraseTitle, message: l.eraseConfirm, confirmLabel: l.commonDelete,
                destructive: true, typedWord: 'ERASE');
            if (!ok) return;
            try {
              await ref.read(apiClientProvider)!.postJson('/privacy/erase', body: {'kinds': _kinds.toList(), 'confirmation': 'ERASE'});
              setState(_kinds.clear);
              widget.onDone();
              if (context.mounted) showSuccess(context, l.eraseDone);
            } on Object catch (e) {
              if (context.mounted) showError(context, e);
            }
          },
        ),
      ]),
    );
  }
}

/// Notifications, reminders, matching weights and network settings (EF-08.05, EF-13.05, EF-18.10).
class PreferencesTab extends ConsumerWidget {
  const PreferencesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final api = ref.read(apiClientProvider)!;
    Future<void> run(Future<Object?> Function() fn) async {
      try {
        await fn();
        if (context.mounted) showSuccess(context, l.settingsSaved);
      } on Object catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    final prefs = ref.watch(notifPrefsProvider).valueOrNull ?? const <Json>[];
    final weights = ref.watch(weightsProvider).valueOrNull;
    final network = ref.watch(networkProvider).valueOrNull;
    final offsets = prefs.isEmpty ? const <String>[] : prefs.first.strings('reminder_offsets');
    final kinds = {'new_opportunities': l.nkNew, 'opportunity_changed': l.nkChanged, 'deadline': l.nkDeadline,
      'source_failure': l.nkSource, 'monitor_failed': l.nkMonitor};
    return _body([
      SectionCard(
        title: l.prefNotifications,
        child: Column(children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.prefCloseToTray),
            subtitle: Text(l.prefCloseToTrayHelp),
            value: ref.watch(uiPrefsProvider).closeToTray,
            onChanged: (v) => ref.read(uiPrefsProvider.notifier).setCloseToTray(v),
          ),
          for (final pref in prefs.where((x) => kinds.containsKey(x.str('kind'))))
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(kinds[pref.string('kind')]!),
              value: pref.flag('enabled'),
              onChanged: (v) async {
                await run(() => api.putJson('/notifications/preferences/${pref.string('kind')}', body: {'enabled': v}));
                ref.invalidate(notifPrefsProvider);
              },
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.prefReminders),
            subtitle: Text(offsets.map((o) => 'J-$o').join(', ')),
            trailing: TextButton(
              child: Text(l.commonEdit),
              onPressed: () async {
                final c = TextEditingController(text: offsets.join(', '));
                final value = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l.prefReminders),
                    content: TextField(controller: c, decoration: InputDecoration(helperText: l.prefRemindersHelp)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
                      FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(l.commonSave)),
                    ],
                  ),
                );
                c.dispose();
                if (value == null) return;
                final list = value.split(RegExp(r'[,\s]+')).map(int.tryParse).whereType<int>().toList();
                await run(() => api.putJson('/notifications/reminder-offsets', body: {'offsets': list}));
                ref.invalidate(notifPrefsProvider);
              },
            ),
          ),
        ]),
      ),
      SectionCard(
        title: l.prefTracking,
        child: Column(children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.prefAutoArchive),
            subtitle: Text(l.prefAutoArchiveHelp),
            trailing: DropdownButton<int>(
              value: ref.watch(trackingSettingsProvider).valueOrNull?.integer('auto_archive_days') ?? 60,
              items: [
                for (final d in const [0, 30, 60, 90, 180, 365])
                  DropdownMenuItem(value: d, child: Text(d == 0 ? l.prefNever : l.prefDays(d))),
              ],
              onChanged: (v) async {
                if (v == null) return;
                await run(() => api.putJson('/settings/tracking', body: {'auto_archive_days': v}));
                ref.invalidate(trackingSettingsProvider);
              },
            ),
          ),
          if (Autostart().supported)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.prefAutostart),
              subtitle: Text(l.prefAutostartHelp),
              value: ref.watch(autostartProvider).valueOrNull ?? false,
              onChanged: (v) async {
                await run(() => Autostart().setEnabled(v));
                ref.invalidate(autostartProvider);
              },
            ),
        ]),
      ),
      if (weights != null)
        SectionCard(
          title: l.prefWeights,
          subtitle: l.prefWeightsHelp,
          child: _WeightsEditor(weights: weights, onSave: (w) async {
            await run(() => api.putJson('/matching/weights', body: w));
            ref.invalidate(weightsProvider);
          }),
        ),
      if (network != null)
        SectionCard(
          title: l.prefNetwork,
          child: _NetworkEditor(network: network, onSave: (n) async {
            await run(() => api.putJson('/settings/network', body: n));
            ref.invalidate(networkProvider);
          }),
        ),
    ]);
  }
}

class _WeightsEditor extends StatefulWidget {
  const _WeightsEditor({required this.weights, required this.onSave});
  final Json weights;
  final ValueChanged<Json> onSave;

  @override
  State<_WeightsEditor> createState() => _WeightsEditorState();
}

class _WeightsEditorState extends State<_WeightsEditor> {
  late final Map<String, double> _w = {for (final e in widget.weights.entries) e.key: (e.value as num).toDouble()};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final names = {'skills': l.critSkills, 'education': l.critEducation, 'experience': l.critExperience,
      'location': l.critLocation, 'language': l.critLanguage, 'objectives': l.critObjectives, 'deadline': l.critDeadline};
    return Column(children: [
      for (final k in names.keys)
        Row(children: [
          SizedBox(width: 140, child: Text(names[k]!)),
          Expanded(child: Slider(value: _w[k] ?? 0, divisions: 20, label: (_w[k] ?? 0).toStringAsFixed(2),
              onChanged: (v) => setState(() => _w[k] = v))),
        ]),
      Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: () => widget.onSave(_w), child: Text(l.commonSave))),
    ]);
  }
}

class _NetworkEditor extends StatefulWidget {
  const _NetworkEditor({required this.network, required this.onSave});
  final Json network;
  final ValueChanged<Json> onSave;

  @override
  State<_NetworkEditor> createState() => _NetworkEditorState();
}

class _NetworkEditorState extends State<_NetworkEditor> {
  late final _proxy = TextEditingController(text: widget.network.str('proxy_url') ?? '');
  late bool _saver = widget.network.flag('data_saver');
  late double _mb = (widget.network.integer('max_mb_per_search') ?? 50).toDouble();

  @override
  void dispose() {
    _proxy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(controller: _proxy, decoration: InputDecoration(labelText: l.prefProxy, hintText: 'http://proxy:3128')),
      SwitchListTile(contentPadding: EdgeInsets.zero, value: _saver, onChanged: (v) => setState(() => _saver = v),
          title: Text(l.prefDataSaver), subtitle: Text(l.prefDataSaverHelp)),
      Text(l.prefBandwidth(_mb.round())),
      Slider(value: _mb, min: 5, max: 500, divisions: 99, onChanged: (v) => setState(() => _mb = v)),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: () => widget.onSave({'proxy_url': _proxy.text.trim().isEmpty ? null : _proxy.text.trim(),
            'data_saver': _saver, 'max_mb_per_search': _mb.round()}),
          child: Text(l.commonSave),
        ),
      ),
    ]);
  }
}
