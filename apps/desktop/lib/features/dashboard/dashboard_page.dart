import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/json.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/opportunity_widgets.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import '../tracking/status_labels.dart';

final dashboardProvider = FutureProvider.autoDispose<Json>((ref) => requireApi(ref).getJson('/dashboard'));

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final name = auth is SignedIn ? auth.user.displayName.split(' ').first : '';
    return AsyncView<Json>(
      value: ref.watch(dashboardProvider),
      onRetry: () => ref.invalidate(dashboardProvider),
      data: (d) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: PageFrame(
          title: l.dashHello(name),
          subtitle: l.dashSubtitle,
          actions: [
            IconButton(tooltip: l.commonRetry, onPressed: () => ref.invalidate(dashboardProvider), icon: const Icon(Icons.refresh)),
            FilledButton.icon(onPressed: () => context.go('/search'), icon: const Icon(Icons.search), label: Text(l.dashNewSearch)),
          ],
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (d.flag('is_new_user')) _FirstSteps(completeness: d.integer('profile_completeness') ?? 0),
            _Counters(d.obj('counters')),
            const SizedBox(height: Space.xl),
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth > 1000;
              final left = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _Deadlines(d.obj('deadlines')),
                const SizedBox(height: Space.lg),
                _Recommendations(d.list('recommendations')),
              ]);
              final right = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _Applications(d.obj('applications')),
                const SizedBox(height: Space.lg),
                _Activity(d.list('activity')),
                const SizedBox(height: Space.lg),
                _Sources(d.obj('sources')),
                const SizedBox(height: Space.lg),
                _Stats(d.obj('stats')),
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
        ),
      ),
    );
  }
}

class _FirstSteps extends StatelessWidget {
  const _FirstSteps({required this.completeness});
  final int completeness;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xl),
      child: SectionCard(
        title: l.dashFirstStepsTitle,
        subtitle: l.dashFirstStepsBody,
        child: Wrap(spacing: Space.md, runSpacing: Space.md, children: [
          _Step(icon: Icons.person_outline, title: l.dashStepProfile, done: completeness >= 60,
              detail: '$completeness %', onTap: () => context.go('/profile')),
          _Step(icon: Icons.upload_file, title: l.dashStepCv, done: false, onTap: () => context.go('/profile/cv')),
          _Step(icon: Icons.travel_explore, title: l.dashStepSearch, done: false, onTap: () => context.go('/search')),
          _Step(icon: Icons.notifications_active_outlined, title: l.dashStepMonitor, done: false,
              onTap: () => context.go('/monitors')),
        ]),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.title, required this.done, required this.onTap, this.detail});
  final IconData icon;
  final String title;
  final bool done;
  final VoidCallback onTap;
  final String? detail;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(Space.lg), alignment: Alignment.centerLeft),
          child: Row(children: [
            Icon(done ? Icons.check_circle : icon, color: done ? Brand.green : null),
            const SizedBox(width: Space.sm),
            Expanded(child: Text(title)),
            if (detail != null) Text(detail!, style: context.text.labelSmall),
          ]),
        ),
      );
}

class _Counters extends StatelessWidget {
  const _Counters(this.c);
  final Json c;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tiles = [
      (Icons.travel_explore, l.dashDiscovered, c.integer('discovered') ?? 0, '/search'),
      (Icons.fiber_new_outlined, l.dashNew, c.integer('new_since_last_search') ?? 0, '/search'),
      (Icons.thumb_up_alt_outlined, l.dashRelevant, c.integer('relevant') ?? 0, '/search'),
      (Icons.bookmark_outline, l.dashSaved, c.integer('saved') ?? 0, '/saved'),
      (Icons.edit_note, l.dashInProgress, c.integer('in_progress') ?? 0, '/saved?tab=1'),
      (Icons.send_outlined, l.dashSubmitted, c.integer('submitted') ?? 0, '/saved?tab=1'),
    ];
    return LayoutBuilder(builder: (context, box) {
      final perRow = box.maxWidth >= 1000 ? 6 : (box.maxWidth >= 560 ? 3 : 2);
      final width = (box.maxWidth - Space.md * (perRow - 1)) / perRow;
      return Wrap(spacing: Space.md, runSpacing: Space.md, children: [
      for (final (icon, label, value, route) in tiles)
        SizedBox(
          width: width,
          child: Card(
            child: InkWell(
              onTap: () => context.go(route),
              borderRadius: Radii.card,
              child: Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(icon, color: context.colors.primary),
                  const SizedBox(height: Space.sm),
                  Text('$value', style: context.text.headlineSmall),
                  Text(label, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ),
          ),
        ),
      ]);
    });
  }
}

class _Deadlines extends StatelessWidget {
  const _Deadlines(this.d);
  final Json d;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final w = d.obj('windows');
    final items = d.list('items');
    return SectionCard(
      title: l.dashDeadlines,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: Space.sm, children: [
          Chip(label: Text(l.dashWithin(7, w.integer('days_7') ?? 0))),
          Chip(label: Text(l.dashWithin(14, w.integer('days_14') ?? 0))),
          Chip(label: Text(l.dashWithin(30, w.integer('days_30') ?? 0))),
        ]),
        const SizedBox(height: Space.sm),
        if (items.isEmpty)
          Text(l.dashNoDeadlines, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant))
        else
          for (final i in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Tooltip(
                message: l.daysLeft(i.integer('days_left') ?? 0),
                child: CircleAvatar(
                  backgroundColor: (i.integer('days_left') ?? 99) <= 7 ? context.status.warning : context.colors.surfaceContainer,
                  foregroundColor: (i.integer('days_left') ?? 99) <= 7 ? context.status.onWarning : context.colors.onSurface,
                  child: Text(l.dashDaysShort(i.integer('days_left') ?? 0), style: context.text.labelMedium),
                ),
              ),
              title: Text(i.string('title'), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text([Fmt.date(context, i.str('effective_deadline')),
                if (i.str('application_status') != null) applicationStatusLabel(l, i.string('application_status'))].join(' · ')),
              onTap: () => context.push('/saved/${i.string('saved_id')}'),
            ),
      ]),
    );
  }
}

class _Recommendations extends StatelessWidget {
  const _Recommendations(this.items);
  final List<Json> items;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      title: l.dashRecommendations,
      subtitle: l.dashRecommendationsHelp,
      child: items.isEmpty
          ? Text(l.dashNoRecommendations)
          : Column(children: [
              for (final r in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: OpportunityCard(data: r, onOpen: () => context.push('/opportunities/${r.string('id')}')),
                ),
            ]),
    );
  }
}

class _Applications extends StatelessWidget {
  const _Applications(this.a);
  final Json a;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final byStatus = a.obj('by_status');
    return SectionCard(
      title: l.dashApplications,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (byStatus.isEmpty) Text(l.dashNoApplications)
        else Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
          for (final e in byStatus.entries)
            Chip(avatar: Icon(applicationStatusIcon(e.key), size: 16), label: Text('${applicationStatusLabel(l, e.key)} · ${e.value}')),
        ]),
        for (final f in a.list('follow_ups'))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.mark_email_unread_outlined),
            title: Text(l.dashFollowUp(f.string('title'))),
            subtitle: Text(l.dashSubmittedOn(Fmt.date(context, f.str('submitted_on')))),
            onTap: () => context.push('/saved/${f.string('saved_id')}'),
          ),
        for (final e in a.list('upcoming_events'))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(e.string('title')),
            subtitle: Text(Fmt.dateTime(context, e.str('scheduled_at'))),
          ),
      ]),
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity(this.items);
  final List<Json> items;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      title: l.dashActivity,
      child: items.isEmpty
          ? Text(l.dashNoActivity)
          : Column(children: [
              for (final r in items)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(r.string('trigger') == 'monitor' ? Icons.notifications_active_outlined : Icons.search),
                  title: Text(r.string('raw_text'), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${Fmt.dateTime(context, r.str('created_at'))} · ${l.resultsCount(r.integer('results_count') ?? 0)}'),
                  onTap: () => context.go('/search?run=${r.string('id')}'),
                ),
            ]),
    );
  }
}

class _Sources extends StatelessWidget {
  const _Sources(this.s);
  final Json s;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final failing = s.list('failing');
    return SectionCard(
      title: l.dashSources,
      trailing: TextButton(onPressed: () => context.go('/sources'), child: Text(l.dashManage)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.dashSourcesSummary(s.integer('active') ?? 0, s.integer('healthy') ?? 0, s.integer('total') ?? 0)),
        for (final f in failing)
          ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(Icons.error_outline, color: context.colors.error),
              title: Text(f.string('name')), subtitle: Text(l.dashSourceFailing(f.integer('consecutive_failures') ?? 0))),
      ]),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats(this.s);
  final Json s;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rate = s.number('response_rate');
    final avg = s.number('average_response_days');
    return SectionCard(
      title: l.dashStats,
      child: (s.integer('submitted') ?? 0) == 0
          ? Text(l.dashNoStats)
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.dashStatSubmitted(s.integer('submitted') ?? 0)),
              Text(l.dashStatRate(rate == null ? '—' : '${(rate * 100).round()} %')),
              Text(l.dashStatDelay(avg == null ? '—' : avg.toStringAsFixed(0))),
              Text(l.dashStatAccepted(s.integer('accepted') ?? 0)),
            ]),
    );
  }
}
