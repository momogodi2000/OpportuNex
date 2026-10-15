import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../api/api_client.dart';
import '../api/json.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Semantic badge: colour + icon + label, never colour alone (arch §3.5, WCAG).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.kind, this.dense = false});
  final String kind;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = context.status;
    final (Color bg, Color fg, IconData icon, String label) = switch (kind) {
      'verified' => (s.success, s.onSuccess, Icons.verified_outlined, l.badgeVerified),
      'modified' => (s.warning, s.onWarning, Icons.edit_note, l.badgeModified),
      'ai_generated' => (s.ai, s.onAi, Icons.auto_awesome, l.badgeAiGenerated),
      'expired' => (s.danger, s.onDanger, Icons.event_busy, l.badgeExpired),
      'deadline_soon' => (s.warning, s.onWarning, Icons.alarm, l.badgeDeadlineSoon),
      'eligibility_uncertain' => (s.info, s.onInfo, Icons.help_outline, l.badgeEligibilityUncertain),
      'deadline_unknown' => (s.neutral, s.onNeutral, Icons.event_note, l.badgeDeadlineUnknown),
      'new' => (s.info, s.onInfo, Icons.fiber_new_outlined, l.badgeNew),
      'inferred' => (s.neutral, s.onNeutral, Icons.psychology_alt_outlined, l.provInferred),
      'explicit' => (s.success, s.onSuccess, Icons.format_quote, l.provExplicit),
      'generated' => (s.ai, s.onAi, Icons.auto_awesome, l.provGenerated),
      'not_specified' => (s.neutral, s.onNeutral, Icons.remove, l.commonNotSpecified),
      _ => (s.neutral, s.onNeutral, Icons.label_outline, kind),
    };
    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? Space.sm : Space.md, vertical: dense ? 2 : Space.xs),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: dense ? 14 : 16, color: fg),
          const SizedBox(width: Space.xs),
          Text(label, style: context.text.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

/// Circular relevance gauge 0–100.
class ScoreGauge extends StatelessWidget {
  const ScoreGauge({super.key, required this.score, this.size = 52});
  final int? score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final v = score;
    final color = v == null
        ? context.colors.outline
        : v >= 70
            ? Brand.green
            : v >= 45
                ? Brand.amber
                : context.colors.error;
    return Semantics(
      label: AppLocalizations.of(context).scoreLabel(v ?? 0),
      child: SizedBox.square(
        dimension: size,
        child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(
            value: (v ?? 0) / 100,
            strokeWidth: size / 9,
            color: color,
            backgroundColor: context.colors.surfaceContainerHigh,
          ),
          Text(v == null ? '—' : '$v', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

String categoryLabel(AppLocalizations l, String? code) {
  if (code == null) return l.commonNotSpecified;
  final root = code.split('.').first;
  return switch (root) {
    'employment' => l.catEmployment,
    'internship' => l.catInternship,
    'freelance' => l.catFreelance,
    'scholarship' => l.catScholarship,
    'grant' => l.catGrant,
    'tender' => l.catTender,
    'entrepreneurship' => l.catEntrepreneurship,
    'acceleration' => l.catAcceleration,
    'training' => l.catTraining,
    'competition' => l.catCompetition,
    'research' => l.catResearch,
    'partnership' => l.catPartnership,
    'volunteering' => l.catVolunteering,
    'call_for_applications' => l.catCall,
    _ => l.catOther,
  };
}

/// Result card used by search results, recommendations, workspaces and saved lists.
class OpportunityCard extends StatelessWidget {
  const OpportunityCard({
    super.key,
    required this.data,
    required this.onOpen,
    this.onSave,
    this.trailing,
    this.selected = false,
    this.onSelect,
  });

  final Json data;
  final VoidCallback onOpen;
  final VoidCallback? onSave;
  final Widget? trailing;
  final bool selected;
  final ValueChanged<bool>? onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final badges = [if (data.flag('is_new')) 'new', ...data.strings('badges')];
    final amount = data.objOrNull('amount');
    final daysLeft = data.integer('days_left');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (onSelect != null)
              Padding(
                padding: const EdgeInsets.only(right: Space.sm),
                child: Checkbox(value: selected, onChanged: (v) => onSelect!(v ?? false)),
              ),
            ScoreGauge(score: data.integer('score')),
            const SizedBox(width: Space.lg),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data.string('title'), style: context.text.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: Space.xs),
                Wrap(spacing: Space.md, runSpacing: Space.xs, children: [
                  _Meta(Icons.apartment, data.str('organization_name') ?? l.commonNotSpecified),
                  _Meta(Icons.category_outlined, categoryLabel(l, data.str('category'))),
                  if (data.str('country_code') != null) _Meta(Icons.place_outlined, data.string('country_code')),
                  _Meta(Icons.event, daysLeft == null
                      ? l.deadlineUnknownShort
                      : '${Fmt.date(context, data.str('deadline_on'))} · ${l.daysLeft(daysLeft)}'),
                  if (amount != null)
                    _Meta(Icons.payments_outlined,
                        Fmt.money(context, amount.integer('min_minor'), amount.integer('max_minor'), amount.str('currency'))),
                  if ((data.integer('sources_count') ?? 0) > 1) _Meta(Icons.layers_outlined, l.sourcesCount(data.integer('sources_count')!)),
                ]),
                if (data.str('summary') != null) ...[
                  const SizedBox(height: Space.sm),
                  Text(data.string('summary'), maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                ],
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: Space.sm),
                  Wrap(spacing: Space.xs, runSpacing: Space.xs,
                      children: [for (final b in badges) StatusBadge(kind: b, dense: true)]),
                ],
              ]),
            ),
            const SizedBox(width: Space.md),
            Column(children: [
              if (onSave != null)
                IconButton(
                  tooltip: data.flag('is_saved') ? l.oppSaved : l.oppSave,
                  onPressed: data.flag('is_saved') ? null : onSave,
                  icon: Icon(data.flag('is_saved') ? Icons.bookmark : Icons.bookmark_add_outlined),
                ),
              ?trailing,
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: context.colors.onSurfaceVariant),
        const SizedBox(width: Space.xs),
        Text(text, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
      ]);
}
