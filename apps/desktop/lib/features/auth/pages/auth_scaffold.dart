import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/brand.dart';
import '../../../l10n/app_localizations.dart';

/// Two-pane frame for every signed-out screen: brand panel on the left (hidden when the
/// window is narrow), the form card on the right.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, this.subtitle, required this.child, this.footer});

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final form = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Layout.formMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!wide) ...[const BrandHeader(), const SizedBox(height: Space.xxl)],
              Semantics(header: true, child: Text(title, style: context.text.headlineSmall)),
              if (subtitle != null) ...[
                const SizedBox(height: Space.sm),
                Text(subtitle!, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
              ],
              const SizedBox(height: Space.xl),
              child,
              if (footer != null) ...[const SizedBox(height: Space.xl), footer!],
            ],
          ),
        ),
      ),
    );
    if (!wide) return Scaffold(body: form);
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Brand.navy, Brand.blue],
                ),
              ),
              padding: const EdgeInsets.all(Space.xxxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(size: 72),
                  const SizedBox(height: Space.xl),
                  Text(l.appName,
                      style: context.text.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: Space.sm),
                  Text(l.slogan,
                      style: context.text.titleMedium?.copyWith(color: Brand.greenLight, letterSpacing: 1.5)),
                  const SizedBox(height: Space.lg),
                  Text(l.tagline, style: context.text.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                  const SizedBox(height: Space.xxl),
                  Row(children: [
                    const Icon(Icons.shield_outlined, color: Colors.white70, size: 20),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(l.authWelcomeSubtitle,
                          style: context.text.bodyMedium?.copyWith(color: Colors.white70)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          Expanded(flex: 6, child: ColoredBox(color: context.colors.surface, child: form)),
        ],
      ),
    );
  }
}

/// Inline error banner shown above form actions.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(color: context.colors.errorContainer, borderRadius: Radii.control),
        child: Row(children: [
          Icon(Icons.error_outline, color: context.colors.onErrorContainer),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(message, style: TextStyle(color: context.colors.onErrorContainer))),
        ]),
      ),
    );
  }
}
