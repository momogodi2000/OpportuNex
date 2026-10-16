import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../ai/ai_consent.dart';
import '../ai/ai_repository.dart';

final opportunityProvider = FutureProvider.autoDispose.family<Json, String>(
    (ref, id) => requireApi(ref).getJson('/opportunities/$id'));

class OpportunityPage extends ConsumerWidget {
  const OpportunityPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView(
      value: ref.watch(opportunityProvider(id)),
      onRetry: () => ref.invalidate(opportunityProvider(id)),
      data: (d) => _Sheet(id: id, d: d),
    );
  }
}

class _Sheet extends ConsumerWidget {
  const _Sheet({required this.id, required this.d});
  final String id;
  final Json d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final api = ref.read(apiClientProvider)!;
    final overview = d.obj('overview');
    final relevance = d.objOrNull('relevance');
    final fields = d.obj('fields');
    final aiOn = ref.watch(aiAvailableProvider).valueOrNull ?? false;
    final aiFields = fields.entries
        .where((e) => e.value is Map && (e.value as Map)['extracted_by'] == 'ai' && e.key != 'ai_summary')
        .toList();
    final savedId = d.str('saved_id');

    Future<void> run(Future<void> Function() fn, String done) async {
      try {
        await fn();
        ref.invalidate(opportunityProvider(id));
        if (context.mounted) showSuccess(context, done);
      } on Object catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    return PageFrame(
      title: overview.string('title'),
      subtitle: [d.obj('publisher').str('organization_name'), categoryLabel(l, overview.obj('category').str('code'))]
          .whereType<String>().join(' · '),
      actions: [
        if (savedId == null)
          FilledButton.icon(
            onPressed: () => run(() => api.postJson('/saved', body: {'opportunity_id': id}), l.oppSavedToast),
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(l.oppSave),
          )
        else
          FilledButton.tonalIcon(
            onPressed: () => context.push('/saved/$savedId'),
            icon: const Icon(Icons.assignment_outlined),
            label: Text(l.oppOpenTracking),
          ),
        OutlinedButton.icon(
          onPressed: () => launchUrl(Uri.parse(d.string('official_link'))),
          icon: const Icon(Icons.open_in_new),
          label: Text(l.oppOfficialLink),
        ),
        PopupMenuButton<String>(
          tooltip: l.oppMore,
          onSelected: (v) async {
            switch (v) {
              case 'recheck':
                await run(() => api.postJson('/opportunities/$id/recheck'), l.oppRechecked);
              case 'workspace':
                await _addToWorkspace(context, ref);
              case 'ai_analyze':
                await _analyze(context, ref);
              case 'ai_translate':
                await _translate(context, ref);
              default:
                await run(() => api.postJson('/opportunities/$id/feedback', body: {'feedback': v}), l.oppFeedbackThanks);
                if (v == 'dismissed' && context.mounted && context.canPop()) context.pop();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'recheck', child: ListTile(leading: const Icon(Icons.refresh), title: Text(l.oppRecheck))),
            PopupMenuItem(value: 'workspace', child: ListTile(leading: const Icon(Icons.folder_outlined), title: Text(l.oppAddWorkspace))),
            if (aiOn) ...[
              const PopupMenuDivider(),
              PopupMenuItem(value: 'ai_analyze', child: ListTile(leading: const Icon(Icons.auto_awesome), title: Text(l.aiAnalyze))),
              PopupMenuItem(value: 'ai_translate', child: ListTile(leading: const Icon(Icons.translate), title: Text(l.aiTranslate))),
            ],
            const PopupMenuDivider(),
            PopupMenuItem(value: 'relevant', child: ListTile(leading: const Icon(Icons.thumb_up_outlined), title: Text(l.oppRelevant))),
            PopupMenuItem(value: 'not_relevant', child: ListTile(leading: const Icon(Icons.thumb_down_outlined), title: Text(l.oppNotRelevant))),
            PopupMenuItem(value: 'dismissed', child: ListTile(leading: const Icon(Icons.visibility_off_outlined), title: Text(l.oppDismiss))),
          ],
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [for (final b in d.strings('badges')) StatusBadge(kind: b)]),
        const SizedBox(height: Space.lg),
        _Notice(text: l.oppSubmissionNotice),
        const SizedBox(height: Space.lg),
        LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth > 980;
          final main = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Section(l.oppOverview, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (overview.str('summary') != null) ...[
                _Field(label: l.oppSummary, value: overview.string('summary'), field: fields.objOrNull('summary')),
                const SizedBox(height: Space.md),
              ],
              if (fields.objOrNull('ai_summary') != null) ...[
                _Field(label: l.aiSummary, value: fields.obj('ai_summary').string('value_text'), field: fields.obj('ai_summary')),
                const SizedBox(height: Space.md),
              ],
              _Kv(l.oppLocation, [overview.str('location_text'), overview.str('country_code')].whereType<String>().join(', ')),
              _Kv(l.filterWorkMode, _workMode(l, overview.str('work_mode'))),
              _Kv(l.oppPublished, Fmt.date(context, overview.str('published_on'))),
              if ((overview.str('description') ?? '').isNotEmpty)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(l.oppFullText),
                  children: [SelectableText(overview.string('description'))],
                ),
            ])),
            _Section(l.oppDeadline, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Field(label: l.oppDeadline, value: Fmt.date(context, d.obj('deadline').str('date')), field: fields.objOrNull('deadline_on')),
            ])),
            if (aiFields.isNotEmpty)
              _Section(l.aiFields, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final e in aiFields) ...[
                  Text(aiFieldLabel(l, e.key), style: context.text.labelLarge),
                  _Field(
                    label: aiFieldLabel(l, e.key),
                    value: (e.value as Json).str('value_text') ?? l.commonNotSpecified,
                    field: e.value as Json,
                  ),
                  const SizedBox(height: Space.sm),
                ],
              ])),
            _Section(l.oppEligibility, d.obj('eligibility').strings('clauses').isEmpty
                ? Text(l.oppNoCriteria)
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final c in d.obj('eligibility').strings('clauses'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.xs),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.format_quote, size: 16),
                          const SizedBox(width: Space.sm),
                          Expanded(child: SelectableText(c)),
                        ]),
                      ),
                    const SizedBox(height: Space.xs),
                    Text(l.oppVerbatimNote, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                  ])),
            _Section(l.oppQualifications, _Requirements(d.obj('qualifications'))),
            _Section(l.oppDocumentsRequired, d.list('documents_required').isEmpty
                ? Text(l.commonNotSpecified)
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final r in d.list('documents_required'))
                      ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.description_outlined),
                          title: Text(r.string('label')), subtitle: Text(r.string('original_text'), maxLines: 2)),
                  ])),
            _Section(l.oppFinancial, d.objOrNull('financial') == null
                ? Text(l.commonNotSpecified)
                : _Field(label: l.oppAmount,
                    value: Fmt.money(context, d.obj('financial').integer('min_minor'), d.obj('financial').integer('max_minor'),
                        d.obj('financial').str('currency')),
                    field: fields.objOrNull('amount'))),
            _Section(l.oppProcedure, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Kv(l.oppApplicationUrl, d.obj('procedure').str('application_url') ?? l.commonNotSpecified),
              _Kv(l.oppContact, d.obj('procedure').str('contact_public') ?? l.commonNotSpecified),
            ])),
          ]);
          final side = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Section(l.oppRelevance, relevance == null ? Text(l.commonNotSpecified) : _Relevance(relevance)),
            _Section(l.oppGaps, _Gaps(d.obj('eligibility_gaps'))),
            _Section(l.oppPublisher, _Publisher(d.obj('publisher'))),
            _Section(l.oppVerification, _Verification(d.obj('verification'))),
          ]);
          return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: main),
                  const SizedBox(width: Space.xl),
                  Expanded(flex: 2, child: side),
                ])
              : Column(children: [main, side]);
        }),
      ]),
    );
  }

  String _lang(BuildContext context) => Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'fr';

  /// EF-07.01-05: AI analysis; only values verified against the announcement are applied.
  Future<void> _analyze(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final api = ref.read(apiClientProvider)!;
    try {
      final r = await withAiConsent(context, ref,
          () => api.postJson('/opportunities/$id/analyze', body: {'language': _lang(context)}));
      if (r == null || !context.mounted) return;
      ref.invalidate(opportunityProvider(id));
      if (r.str('status') == 'analyzed') {
        showSuccess(context, l.aiAnalyzed(r.strings('applied').length, r.strings('unverifiable').length));
      } else {
        showError(context, l.aiUnavailable);
      }
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  /// EF-07.08: translation on demand, labelled as generated and never stored as source data.
  Future<void> _translate(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final api = ref.read(apiClientProvider)!;
    final target = _lang(context) == 'fr' && d.obj('overview').str('language_code') == 'fr' ? 'en' : _lang(context);
    try {
      final r = await withAiConsent(context, ref,
          () => api.postJson('/opportunities/$id/translate', body: {'language': target}));
      if (r == null || !context.mounted) return;
      if (r.str('status') != 'translated') {
        showError(context, l.aiUnavailable);
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(r.string('title')),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const StatusBadge(kind: 'generated'),
                const SizedBox(height: Space.md),
                for (final s in r.strings('summary')) Text('• $s'),
                const SizedBox(height: Space.md),
                SelectableText(r.string('description')),
              ]),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonClose))],
        ),
      );
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _addToWorkspace(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final api = ref.read(apiClientProvider)!;
    final ws = items(await api.getJson('/workspaces'));
    if (!context.mounted) return;
    if (ws.isEmpty) {
      showSuccess(context, l.wsNoneYet);
      return;
    }
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(title: Text(l.oppAddWorkspace), children: [
        for (final w in ws) SimpleDialogOption(onPressed: () => Navigator.pop(ctx, w.string('id')), child: Text(w.string('name'))),
      ]),
    );
    if (picked == null) return;
    try {
      await api.putJson('/workspaces/$picked/opportunities/$id');
      if (context.mounted) showSuccess(context, l.wsAdded);
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

String _workMode(AppLocalizations l, String? mode) => switch (mode) {
      'remote' => l.workRemote,
      'hybrid' => l.workHybrid,
      'onsite' => l.workOnsite,
      _ => l.commonNotSpecified,
    };

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(color: context.status.info, borderRadius: Radii.control),
        child: Row(children: [
          Icon(Icons.info_outline, color: context.status.onInfo),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(text, style: TextStyle(color: context.status.onInfo))),
        ]),
      );
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.child);
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Space.lg),
        child: SectionCard(title: title, child: child),
      );
}

class _Kv extends StatelessWidget {
  const _Kv(this.k, this.v);
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Space.xs),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 160, child: Text(k, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant))),
          Expanded(child: SelectableText(v.isEmpty ? AppLocalizations.of(context).commonNotSpecified : v)),
        ]),
      );
}

/// A value with its provenance badge and the source excerpt that justifies it (EF-07.02/03, EF-10.02).
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.field});
  final String label;
  final String value;
  final Json? field;

  @override
  Widget build(BuildContext context) {
    final prov = field?.str('provenance');
    final excerpt = field?.str('evidence_excerpt');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: SelectableText(value, style: context.text.bodyLarge)),
        if (prov != null) StatusBadge(kind: prov, dense: true),
      ]),
      if (excerpt != null && excerpt.isNotEmpty) ...[
        const SizedBox(height: Space.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: context.colors.primary, width: 3)),
            color: context.colors.surfaceContainerLow,
          ),
          child: Text('« $excerpt »', style: context.text.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
        ),
      ],
    ]);
  }
}

class _Requirements extends StatelessWidget {
  const _Requirements(this.q);
  final Json q;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (q.isEmpty) return Text(l.commonNotSpecified);
    final labels = {'education': l.reqEducation, 'experience': l.reqExperience, 'skill': l.reqSkills, 'language': l.reqLanguages};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final entry in q.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.sm),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(labels[entry.key] ?? entry.key, style: context.text.labelLarge),
            const SizedBox(height: Space.xs),
            Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
              for (final r in (entry.value as List<dynamic>).cast<Map<String, dynamic>>())
                Tooltip(message: r.string('original_text'), child: Chip(label: Text(r.string('label')))),
            ]),
          ]),
        ),
    ]);
  }
}

class _Relevance extends StatelessWidget {
  const _Relevance(this.r);
  final Json r;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final names = {'skills': l.critSkills, 'education': l.critEducation, 'experience': l.critExperience,
        'location': l.critLocation, 'language': l.critLanguage, 'objectives': l.critObjectives, 'deadline': l.critDeadline};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        ScoreGauge(score: r.integer('score'), size: 64),
        const SizedBox(width: Space.lg),
        Expanded(child: Text(_eligibility(l, r.string('eligibility')), style: context.text.titleSmall)),
      ]),
      const SizedBox(height: Space.md),
      for (final e in r.obj('breakdown').entries)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.xs),
          child: Row(children: [
            SizedBox(width: 120, child: Text(names[e.key] ?? e.key, style: context.text.bodySmall)),
            Expanded(
              child: LinearProgressIndicator(
                value: ((e.value as Map<String, dynamic>)['score'] as num).toDouble(),
                minHeight: 6,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
            const SizedBox(width: Space.sm),
            if ((e.value as Map<String, dynamic>)['evaluated'] == false)
              Tooltip(message: l.critNotEvaluated, child: const Icon(Icons.help_outline, size: 16)),
          ]),
        ),
      if (r.strings('strengths').isNotEmpty) ...[
        const SizedBox(height: Space.sm),
        Text(l.oppStrengths, style: context.text.labelLarge),
        for (final s in r.strings('strengths')) Text('• ${_humanize(s)}', style: context.text.bodySmall),
      ],
    ]);
  }
}

String _eligibility(AppLocalizations l, String v) => switch (v) {
      'likely' => l.eligLikely,
      'unlikely' => l.eligUnlikely,
      'not_eligible' => l.eligNot,
      _ => l.eligUncertain,
    };

String _humanize(String code) {
  final parts = code.split(':');
  return parts.length > 1 ? parts.sublist(1).join(':') : code;
}

class _Gaps extends StatelessWidget {
  const _Gaps(this.g);
  final Json g;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final gaps = g.strings('gaps');
    final verify = g.strings('to_verify');
    if (gaps.isEmpty && verify.isEmpty) return Text(l.oppNoGaps);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final x in gaps)
        ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(Icons.warning_amber, color: context.colors.error),
            title: Text(_gapLabel(l, x))),
      if (verify.isNotEmpty) ...[
        Text(l.oppToVerify, style: context.text.labelLarge),
        for (final v in verify)
          ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.fact_check_outlined),
              title: Text(v == 'no_published_criteria' ? l.oppNoCriteria : v)),
      ],
    ]);
  }

  String _gapLabel(AppLocalizations l, String code) {
    final key = code.split(':').first;
    final value = _humanize(code);
    return switch (key) {
      'skills_missing' => l.gapSkills(value),
      'education_required' => l.gapEducation(value),
      'experience_required' => l.gapExperience(value),
      'language_required' || 'posting_language' => l.gapLanguage(value),
      'location' => l.gapLocation(value),
      _ => code,
    };
  }
}

class _Publisher extends StatelessWidget {
  const _Publisher(this.p);
  final Json p;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(p.str('organization_name') ?? l.commonNotSpecified, style: context.text.titleSmall),
      const SizedBox(height: Space.sm),
      for (final s in p.list('sources'))
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(s.flag('is_original') ? Icons.verified_outlined : Icons.repeat),
          title: Text(s.string('name')),
          subtitle: Text(s.flag('is_original') ? l.oppOriginalPublisher : l.oppRepost),
          trailing: IconButton(icon: const Icon(Icons.open_in_new), tooltip: l.oppOfficialLink,
              onPressed: () => launchUrl(Uri.parse(s.string('url')))),
        ),
    ]);
  }
}

class _Verification extends StatelessWidget {
  const _Verification(this.v);
  final Json v;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Kv(l.oppStatus, v.string('status')),
      _Kv(l.oppLastChecked, Fmt.dateTime(context, v.str('last_checked_at'))),
      _Kv(l.oppMethod, v.string('analysis_method') == 'deterministic' ? l.oppMethodRules : l.badgeAiGenerated),
      for (final ver in v.list('versions'))
        Text('${Fmt.dateTime(context, ver.str('detected_at'))} — ${ver.strings('changed_fields').join(', ')}',
            style: context.text.bodySmall),
    ]);
  }
}

String aiFieldLabel(AppLocalizations l, String name) => switch (name) {
      'organization_name' => l.aiFieldOrganization,
      'deadline_on' => l.oppDeadline,
      'amount' => l.aiFieldAmount,
      'currency' => l.aiFieldCurrency,
      'country_code' => l.aiFieldCountry,
      'work_mode' => l.filterWorkMode,
      'category' => l.aiFieldCategory,
      'target_audience' => l.aiFieldAudience,
      'application_url' => l.aiFieldApplicationUrl,
      'eligibility_raw' => l.oppEligibility,
      _ => name,
    };
