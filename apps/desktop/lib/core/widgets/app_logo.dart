import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;
  final bool darkBackground;
  final String? subtitle;

  const AppLogo({
    super.key,
    this.fontSize = 24.0,
    this.darkBackground = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
            ),
            children: [
              TextSpan(
                text: 'Opportu',
                style: TextStyle(
                  color: darkBackground ? Colors.white : AppTheme.primaryNavy,
                ),
              ),
              const TextSpan(
                text: 'Nex',
                style: TextStyle(color: AppTheme.primaryGreen),
              ),
            ],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: fontSize * 0.4,
              color: darkBackground ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}
