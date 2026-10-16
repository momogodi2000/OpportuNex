import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart' show Json;
import '../../core/api/json.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';
import 'ai_repository.dart';

const _kinds = ['mistral', 'gemini', 'anthropic', 'groq', 'openrouter', 'openai_compatible', 'ollama', 'lmstudio'];
const _localKinds = {'ollama', 'lmstudio'};
// Tasks the application actually routes to a model.
const _tasks = ['query_interpretation', 'extraction', 'translation', 'cv_parsing', 'document_drafting'];

String aiKindLabel(AppLocalizations l, String k) => switch (k) {
      'mistral' => 'Mistral AI',
      'gemini' => 'Google Gemini',
      'anthropic' => 'Anthropic Claude',
      'groq' => 'Groq',
      'openrouter' => 'OpenRouter',
      'openai_compatible' => l.aiKindOpenAi,
      'ollama' => l.aiKindOllama,
      'lmstudio' => l.aiKindLmStudio,
      _ => k,
    };

String _taskLabel(AppLocalizations l, String t) => switch (t) {
      'query_interpretation' => l.aiTaskQuery,
      'extraction' => l.aiTaskExtraction,
      'translation' => l.aiTaskTranslation,
      'cv_parsing' => l.aiTaskCv,
      'document_drafting' => l.aiTaskDrafting,
      _ => t,
    };

String aiErrorLabel(AppLocalizations l, String? code) => switch (code) {
      'auth' => l.aiErrAuth,
      'timeout' => l.aiErrTimeout,
      'rate_limited' => l.aiErrRateLimited,
      'network' => l.aiErrNetwork,
      null => '',
      _ => l.aiErrOther(code),
    };

/// Settings > AI (M14): master switch, providers and fallback order, routing per task, usage.
class AiSettingsTab extends ConsumerWidget {
  const AiSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.read(aiRepositoryProvider);
    Future<void> run(Future<Object?> Function() fn, [String? done]) async {
      try {
        await fn();
        ref
          ..invalidate(aiSettingsProvider)
          ..invalidate(aiProvidersProvider);
        if (done != null && context.mounted) showSuccess(context, done);
      } on Object catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    return AsyncView<Json>(
      value: ref.watch(aiSettingsProvider),
      onRetry: () => ref.invalidate(aiSettingsProvider),
      data: (settings) {
        final providers = ref.watch(aiProvidersProvider).valueOrNull ?? const <Json>[];
        final routing = settings.obj('routing');
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(padding: const EdgeInsets.all(Space.xxl), children: [
              SectionCard(
                title: l.aiTitle,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.flag('enabled'),
                    title: Text(l.aiEnable),
                    subtitle: Text(l.aiEnableHelp),
                    onChanged: (v) => run(() => repo.setEnabled(v)),
                  ),
                  const SizedBox(height: Space.sm),
                  for (final line in [l.aiRule1, l.aiRule2, l.aiRule3, l.aiRule4])
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xs),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.check, size: 18, color: context.colors.primary),
                        const SizedBox(width: Space.sm),
                        Expanded(child: Text(line, style: context.text.bodySmall)),
                      ]),
                    ),
                ]),
              ),
              const SizedBox(height: Space.xl),
              SectionCard(
                title: l.aiProviders,
                subtitle: l.aiProvidersHelp,
                trailing: FilledButton.tonalIcon(
                  onPressed: () async {
                    final body = await showDialog<Json>(context: context, builder: (_) => const _ProviderDialog());
                    if (body != null) await run(() => repo.create(body), l.aiProviderAdded);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l.aiAddProvider),
                ),
                child: providers.isEmpty
                    ? Text(l.aiNoProvider)
                    : Column(children: [
                        for (final (i, p) in providers.indexed)
                          _ProviderTile(
                            provider: p,
                            first: i == 0,
                            last: i == providers.length - 1,
                            onMove: (delta) {
                              final ids = [for (final x in providers) x.string('id')];
                              final id = ids.removeAt(i);
                              ids.insert(i + delta, id);
                              return run(() => repo.reorder(ids));
                            },
                            run: run,
                          ),
                      ]),
              ),
              if (providers.length > 1) ...[
                const SizedBox(height: Space.xl),
                SectionCard(
                  title: l.aiRouting,
                  subtitle: l.aiRoutingHelp,
                  child: Column(children: [
                    for (final t in _tasks)
                      Row(children: [
                        Expanded(child: Text(_taskLabel(l, t))),
                        DropdownButton<String?>(
                          value: routing.str(t),
                          items: [
                            DropdownMenuItem(child: Text(l.aiRoutingAuto)),
                            for (final p in providers)
                              DropdownMenuItem(value: p.string('id'), child: Text(p.string('display_name'))),
                          ],
                          onChanged: (v) => run(() => repo.route(t, v)),
                        ),
                      ]),
                  ]),
                ),
              ],
              const SizedBox(height: Space.xl),
              _UsageCard(providers: providers),
            ]),
          ),
        );
      },
    );
  }
}

class _ProviderTile extends ConsumerWidget {
  const _ProviderTile({
    required this.provider,
    required this.first,
    required this.last,
    required this.onMove,
    required this.run,
  });

  final Json provider;
  final bool first;
  final bool last;
  final Future<void> Function(int delta) onMove;
  final Future<void> Function(Future<Object?> Function() fn, [String? done]) run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = provider;
    final repo = ref.read(aiRepositoryProvider);
    final id = p.string('id');
    final local = p.flag('is_local');
    final tested = p.str('last_test_at');
    final details = [
      aiKindLabel(l, p.string('kind')),
      p.string('model'),
      if (local) l.aiLocal else l.aiRemote,
      if (p.flag('key_required') && !p.flag('has_key')) l.aiKeyMissing,
      if (tested != null) (p['last_test_ok'] == true ? l.aiTestOk(Fmt.dateTime(context, tested)) : l.aiTestFailed),
      if (!local && p.strings('consents').isNotEmpty) l.aiConsentGiven,
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(local ? Icons.computer : Icons.cloud_outlined, color: p.flag('enabled') ? context.colors.primary : null),
      title: Text(p.string('display_name')),
      subtitle: Text(details.join(' · ')),
      trailing: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
        IconButton(tooltip: l.aiMoveUp, icon: const Icon(Icons.arrow_upward), onPressed: first ? null : () => onMove(-1)),
        IconButton(tooltip: l.aiMoveDown, icon: const Icon(Icons.arrow_downward), onPressed: last ? null : () => onMove(1)),
        Semantics(
          label: l.a11yToggle(p.string('display_name')),
          child: Switch(value: p.flag('enabled'), onChanged: (v) => run(() => repo.update(id, {'enabled': v}))),
        ),
        PopupMenuButton<String>(
          onSelected: (v) async {
            switch (v) {
              case 'test':
                await _test(context, ref);
              case 'edit':
                final body = await showDialog<Json>(context: context, builder: (_) => _ProviderDialog(existing: p));
                if (body != null) await run(() => repo.update(id, body), l.settingsSaved);
              case 'delete':
                final ok = await confirmAction(context, title: l.commonDelete, message: l.aiDeleteConfirm,
                    confirmLabel: l.commonDelete, destructive: true);
                if (ok) await run(() => repo.delete(id));
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'test', child: ListTile(leading: const Icon(Icons.wifi_tethering), title: Text(l.aiTest))),
            PopupMenuItem(value: 'edit', child: ListTile(leading: const Icon(Icons.edit_outlined), title: Text(l.commonEdit))),
            PopupMenuItem(value: 'delete', child: ListTile(leading: const Icon(Icons.delete_outline), title: Text(l.commonDelete))),
          ],
        ),
      ]),
    );
  }

  Future<void> _test(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final repo = ref.read(aiRepositoryProvider);
    try {
      final r = await repo.test(provider.string('id'));
      ref.invalidate(aiProvidersProvider);
      if (!context.mounted) return;
      final models = r.strings('models');
      final chosen = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(r.flag('ok') ? l.aiTestSuccess : l.aiTestFailed),
          content: SizedBox(
            width: 480,
            child: r.flag('ok')
                ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (!r.flag('model_listed')) Text(l.aiModelNotListed(provider.string('model'))),
                    const SizedBox(height: Space.sm),
                    Text(l.aiModelsAvailable(models.length)),
                    const SizedBox(height: Space.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: SingleChildScrollView(
                        child: Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
                          for (final m in models)
                            ActionChip(
                              label: Text(m),
                              avatar: m == provider.string('model') ? const Icon(Icons.check, size: 16) : null,
                              onPressed: () => Navigator.pop(ctx, m),
                            ),
                        ]),
                      ),
                    ),
                  ])
                : Text(aiErrorLabel(l, r.str('error'))),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonClose))],
        ),
      );
      if (chosen != null && chosen != provider.string('model')) {
        await repo.update(provider.string('id'), {'model': chosen});
        ref.invalidate(aiProvidersProvider);
      }
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

class _ProviderDialog extends StatefulWidget {
  const _ProviderDialog({this.existing});
  final Json? existing;

  @override
  State<_ProviderDialog> createState() => _ProviderDialogState();
}

class _ProviderDialogState extends State<_ProviderDialog> {
  late String _kind = widget.existing?.str('kind') ?? 'mistral';
  late final _name = TextEditingController(text: widget.existing?.str('display_name') ?? '');
  late final _model = TextEditingController(text: widget.existing?.str('model') ?? '');
  late final _url = TextEditingController(text: widget.existing == null ? '' : widget.existing!.str('base_url') ?? '');
  final _key = TextEditingController();
  bool _showKey = false;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    for (final c in [_name, _model, _url, _key]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final local = _localKinds.contains(_kind);
    return AlertDialog(
      title: Text(_editing ? l.commonEdit : l.aiAddProvider),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (!_editing)
              DropdownButtonFormField<String>(
                initialValue: _kind,
                decoration: InputDecoration(labelText: l.aiKind),
                items: [for (final k in _kinds) DropdownMenuItem(value: k, child: Text(aiKindLabel(l, k)))],
                onChanged: (v) => setState(() => _kind = v ?? _kind),
              ),
            const SizedBox(height: Space.md),
            TextField(controller: _name, decoration: InputDecoration(labelText: l.aiDisplayName, hintText: aiKindLabel(l, _kind))),
            const SizedBox(height: Space.md),
            TextField(controller: _model, decoration: InputDecoration(labelText: l.aiModel, helperText: l.aiModelHelp)),
            const SizedBox(height: Space.md),
            TextField(
              controller: _url,
              decoration: InputDecoration(
                labelText: _kind == 'openai_compatible' ? l.aiBaseUrlRequired : l.aiBaseUrl,
                helperText: l.aiBaseUrlHelp,
                hintText: 'https://…',
              ),
            ),
            if (!local) ...[
              const SizedBox(height: Space.md),
              TextField(
                controller: _key,
                obscureText: !_showKey,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: _editing ? l.aiKeyReplace : l.aiKey,
                  helperText: l.aiKeyHelp,
                  suffixIcon: IconButton(
                    icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showKey = !_showKey),
                  ),
                ),
              ),
            ],
            const SizedBox(height: Space.md),
            Text(local ? l.aiLocalHelp : l.aiRemoteHelp, style: context.text.bodySmall),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: () {
            if (_model.text.trim().isEmpty) return;
            Navigator.pop(context, <String, dynamic>{
              if (!_editing) 'kind': _kind,
              'display_name': _name.text.trim().isEmpty ? aiKindLabel(l, _kind) : _name.text.trim(),
              'model': _model.text.trim(),
              if (_url.text.trim().isNotEmpty) 'base_url': _url.text.trim(),
              if (_key.text.trim().isNotEmpty) 'api_key': _key.text.trim(),
            });
          },
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}

class _UsageCard extends ConsumerWidget {
  const _UsageCard({required this.providers});
  final List<Json> providers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rows = ref.watch(aiUsageProvider).valueOrNull ?? const <Json>[];
    final names = {for (final p in providers) p.string('id'): p.string('display_name')};
    return SectionCard(
      title: l.aiUsage,
      subtitle: l.aiUsageHelp,
      trailing: IconButton(tooltip: l.commonRefresh, icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(aiUsageProvider)),
      child: rows.isEmpty
          ? Text(l.aiUsageEmpty)
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(columns: [
                DataColumn(label: Text(l.aiUsageDay)),
                DataColumn(label: Text(l.aiUsageProvider)),
                DataColumn(label: Text(l.aiUsageCalls), numeric: true),
                DataColumn(label: Text(l.aiUsageErrors), numeric: true),
                DataColumn(label: Text(l.aiUsageCache), numeric: true),
                DataColumn(label: Text(l.aiUsageTokens), numeric: true),
              ], rows: [
                for (final r in rows)
                  DataRow(cells: [
                    DataCell(Text(r.string('day'))),
                    DataCell(Text(r.str('provider_id') == null ? l.aiUsageRules : names[r.str('provider_id')] ?? '—')),
                    DataCell(Text('${r.integer('calls') ?? 0}')),
                    DataCell(Text('${r.integer('errors') ?? 0}')),
                    DataCell(Text('${r.integer('cache_hits') ?? 0}')),
                    DataCell(Text('${(r.integer('prompt_tokens') ?? 0) + (r.integer('completion_tokens') ?? 0)}')),
                  ]),
              ]),
            ),
    );
  }
}
