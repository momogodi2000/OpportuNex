import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'ai_repository.dart';

/// Explicit consent before the first send to a remote AI provider (EF-14.09).
///
/// Shows who receives what, records the consent on "Allow", and returns false on "Without AI".
Future<bool> askAiConsent(BuildContext context, WidgetRef ref, Map<String, dynamic> request) async {
  final l = AppLocalizations.of(context);
  final purposes = (request['purposes'] as List<dynamic>? ?? const []).map((e) => '$e').toList();
  final provider = request['provider_name'] as String? ?? '';
  final providerId = request['provider_id'] as String?;
  if (providerId == null || purposes.isEmpty) return false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.privacy_tip_outlined),
      title: Text(l.aiConsentTitle(provider)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.aiConsentIntro(provider)),
          const SizedBox(height: Space.md),
          for (final p in purposes)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.outbox_outlined),
              title: Text(aiPurposeLabel(l, p)),
            ),
          const SizedBox(height: Space.sm),
          Text(l.aiConsentNever, style: ctx.text.bodySmall),
          const SizedBox(height: Space.xs),
          Text(l.aiConsentRevoke, style: ctx.text.bodySmall?.copyWith(color: ctx.colors.onSurfaceVariant)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.aiWithout)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.aiAllow)),
      ],
    ),
  );
  if (ok != true) return false;
  await ref.read(aiRepositoryProvider).grant(providerId, purposes);
  ref.invalidate(aiProvidersProvider);
  return true;
}

String aiPurposeLabel(AppLocalizations l, String purpose) => switch (purpose) {
      'profile_to_ai' => l.aiPurposeProfile,
      'cv_parsing_ai' => l.aiPurposeCv,
      _ => l.aiPurposeContent,
    };

bool isAiConsentRequired(Object e) => e is ApiException && e.code == 'ai_consent_required';

/// Runs [action]; when the engine asks for consent, asks the user and retries, or runs [withoutAi].
Future<T?> withAiConsent<T>(
  BuildContext context,
  WidgetRef ref,
  Future<T> Function() action, {
  Future<T> Function()? withoutAi,
}) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      return await action();
    } on ApiException catch (e) {
      if (e.code != 'ai_consent_required' || !context.mounted) rethrow;
      final granted = await askAiConsent(context, ref, e.extra);
      if (!granted) return withoutAi == null ? null : await withoutAi();
    }
  }
  return withoutAi == null ? null : await withoutAi();
}
