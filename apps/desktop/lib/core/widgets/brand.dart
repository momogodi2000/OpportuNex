import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/app_icon.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
        semanticLabel: AppLocalizations.of(context).appName,
      ),
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.showSlogan = true});
  final bool showSlogan;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        const AppLogo(size: 64),
        const SizedBox(height: Space.md),
        Text(l.appName, style: context.text.headlineSmall),
        if (showSlogan) ...[
          const SizedBox(height: Space.xs),
          Text(l.slogan, style: context.text.labelLarge?.copyWith(color: context.colors.primary, letterSpacing: 1.2)),
        ],
      ],
    );
  }
}
