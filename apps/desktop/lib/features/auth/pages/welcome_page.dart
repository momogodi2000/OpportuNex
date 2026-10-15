import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/prefs/ui_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_controller.dart';
import '../auth_models.dart';
import 'auth_scaffold.dart';

/// Entry screen when nobody is signed in: pick a local profile or create one.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final profiles = switch (auth) {
      SignedOut(:final profiles) => profiles,
      LockedOut(:final profiles) => profiles,
      _ => const <LocalProfile>[],
    };
    final last = ref.watch(uiPrefsProvider).lastProfileId;
    final ordered = [...profiles]..sort((a, b) => a.id == last ? -1 : (b.id == last ? 1 : 0));

    return AuthScaffold(
      title: profiles.isEmpty ? l.authWelcomeTitle : l.authChooseProfile,
      subtitle: profiles.isEmpty ? l.authRegisterSubtitle : null,
      footer: _LanguageSwitch(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in ordered) ...[
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
                leading: CircleAvatar(
                  backgroundColor: context.colors.primaryContainer,
                  child: Text(p.displayName.characters.first.toUpperCase(),
                      style: TextStyle(color: context.colors.onPrimaryContainer)),
                ),
                title: Text(p.displayName),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => context.go('/login?profile=${p.id}'),
              ),
            ),
            const SizedBox(height: Space.sm),
          ],
          if (profiles.isNotEmpty) const SizedBox(height: Space.lg),
          FilledButton.icon(
            onPressed: () => context.go('/register'),
            icon: const Icon(Icons.person_add_alt),
            label: Text(l.authNewProfile),
          ),
          const SizedBox(height: Space.sm),
          if (profiles.isNotEmpty)
            OutlinedButton(onPressed: () => context.go('/login'), child: Text(l.authOtherAccount)),
          TextButton.icon(
            onPressed: () => context.go('/import-profile'),
            icon: const Icon(Icons.unarchive_outlined),
            label: Text(l.authImportProfile),
          ),
        ],
      ),
    );
  }
}

class _LanguageSwitch extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final current = ref.watch(uiPrefsProvider).locale.languageCode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.language, size: 18),
        const SizedBox(width: Space.sm),
        Text(l.authLanguage),
        const SizedBox(width: Space.md),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'fr', label: Text('Français')),
            ButtonSegment(value: 'en', label: Text('English')),
          ],
          selected: {current},
          onSelectionChanged: (s) => ref.read(uiPrefsProvider.notifier).setLocale(s.first),
        ),
      ],
    );
  }
}
