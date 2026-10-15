import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart' show Json;
import '../../core/api/json.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';
import 'profile_repository.dart';
import 'profile_sections.dart';

String missingLabel(AppLocalizations l, String code) => switch (code) {
      'identity' => l.pfMissingIdentity,
      'status' => l.pfMissingStatus,
      'education' => l.pfMissingEducation,
      'experience' => l.pfMissingExperience,
      'skills' => l.pfMissingSkills,
      'languages' => l.pfMissingLanguages,
      'objectives' => l.pfMissingObjectives,
      'preferences' => l.pfMissingPreferences,
      _ => code,
    };

class CompletenessCard extends StatelessWidget {
  const CompletenessCard({super.key, required this.profile});
  final Json profile;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = profile.obj('completeness');
    final pct = c.integer('percent') ?? 0;
    final missing = c.strings('missing');
    return SectionCard(
      title: l.pfCompleteness(pct),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LinearProgressIndicator(value: pct / 100, minHeight: 8, borderRadius: BorderRadius.circular(Radii.pill)),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: Space.md),
          Text(l.pfImproveHint, style: context.text.labelLarge),
          for (final m in missing.take(4))
            Text('• ${missingLabel(l, m)}', style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
        ],
      ]),
    );
  }
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return AsyncView<Json>(
      value: ref.watch(profileProvider),
      onRetry: () => ref.invalidate(profileProvider),
      data: (p) => PageFrame(
        title: l.navProfile,
        subtitle: l.pfSubtitle,
        actions: [
          OutlinedButton.icon(onPressed: () => context.go('/profile/cv'), icon: const Icon(Icons.upload_file),
              label: Text(l.cvImport)),
          if (!p.flag('onboarding_completed'))
            FilledButton.icon(onPressed: () => context.go('/onboarding'), icon: const Icon(Icons.assistant),
                label: Text(l.onbResume)),
        ],
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final w in [
            CompletenessCard(profile: p),
            GeneralSection(profile: p),
            educationSection(context, p),
            experienceSection(context, p),
            SkillsLanguagesSection(profile: p),
            certificationSection(context, p),
            ObjectivesSection(profile: p),
            LinksLocationsSection(profile: p),
            projectSection(context, p),
            OrganizationSection(profile: p),
            SummarySection(profile: p),
          ])
            Padding(padding: const EdgeInsets.only(bottom: Space.lg), child: w),
        ]),
      ),
    );
  }
}
