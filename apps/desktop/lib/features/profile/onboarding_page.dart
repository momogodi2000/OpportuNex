import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart' show Json;
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/states.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_controller.dart';
import 'profile_page.dart';
import 'profile_repository.dart';
import 'profile_sections.dart';

/// Seven-step profile assistant (EF-02.01). Every step can be skipped and revisited later.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0;

  Future<void> _finish() async {
    final l = AppLocalizations.of(context);
    try {
      await ref.read(profileRepositoryProvider).completeOnboarding();
      ref.read(authControllerProvider.notifier).markOnboarded();
      if (mounted) {
        showSuccess(context, l.onbDone);
        context.go('/dashboard');
      }
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final titles = [l.onbStep1, l.onbStep2, l.onbStep3, l.onbStep4, l.onbStep5, l.onbStep6, l.onbStep7];
    return Scaffold(
      body: AsyncView<Json>(
        value: ref.watch(profileProvider),
        onRetry: () => ref.invalidate(profileProvider),
        data: (p) {
          final pages = <Widget>[
            Column(children: [
              GeneralSection(profile: p),
              const SizedBox(height: Space.lg),
              LinksLocationsSection(profile: p),
            ]),
            educationSection(context, p),
            Column(children: [experienceSection(context, p), const SizedBox(height: Space.lg), certificationSection(context, p)]),
            SkillsLanguagesSection(profile: p),
            ObjectivesSection(profile: p),
            Column(children: [projectSection(context, p), const SizedBox(height: Space.lg), OrganizationSection(profile: p)]),
            Column(children: [CompletenessCard(profile: p), const SizedBox(height: Space.lg), SummarySection(profile: p)]),
          ];
          return Column(children: [
            Container(
              color: context.colors.surface,
              padding: const EdgeInsets.symmetric(horizontal: Space.xxl, vertical: Space.lg),
              child: Row(children: [
                const AppLogo(size: 36),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.onbTitle, style: context.text.titleLarge),
                    Text(l.onbStepOf(_step + 1, titles.length, titles[_step]),
                        style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                  ]),
                ),
                OutlinedButton.icon(onPressed: () => context.go('/profile/cv'), icon: const Icon(Icons.upload_file),
                    label: Text(l.cvImport)),
                const SizedBox(width: Space.sm),
                TextButton(onPressed: () => context.go('/dashboard'), child: Text(l.onbLater)),
              ]),
            ),
            LinearProgressIndicator(value: (_step + 1) / titles.length),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: ListView(padding: const EdgeInsets.all(Space.xxl), children: [
                    Text(titles[_step], style: context.text.headlineSmall),
                    const SizedBox(height: Space.sm),
                    Text(l.onbOptionalNote, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                    const SizedBox(height: Space.xl),
                    pages[_step],
                  ]),
                ),
              ),
            ),
            Container(
              color: context.colors.surface,
              padding: const EdgeInsets.all(Space.lg),
              child: Row(children: [
                if (_step > 0)
                  OutlinedButton(onPressed: () => setState(() => _step--), child: Text(l.commonBack)),
                const Spacer(),
                TextButton(
                  onPressed: _step < titles.length - 1 ? () => setState(() => _step++) : null,
                  child: Text(l.onbSkip),
                ),
                const SizedBox(width: Space.sm),
                FilledButton(
                  onPressed: _step < titles.length - 1 ? () => setState(() => _step++) : _finish,
                  child: Text(_step < titles.length - 1 ? l.commonContinue : l.onbFinish),
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}
