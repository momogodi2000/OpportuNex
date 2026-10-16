import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opportunex/core/theme/app_theme.dart';
import 'package:opportunex/core/theme/tokens.dart';

/// WCAG 2.1 contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final la = lum(a), lb = lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, theme) in [('light', AppTheme.light()), ('dark', AppTheme.dark())]) {
    group('$name theme meets WCAG AA for text (4.5:1)', () {
      final s = theme.colorScheme;
      final st = theme.extension<StatusColors>()!;
      final pairs = <String, (Color, Color)>{
        'onSurface/surface': (s.onSurface, s.surface),
        'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
        'onSurfaceVariant/surfaceContainerLow': (s.onSurfaceVariant, s.surfaceContainerLow),
        'onSurface/surfaceContainer': (s.onSurface, s.surfaceContainer),
        'primary/surface (links, text buttons)': (s.primary, s.surface),
        'onPrimary/primary': (s.onPrimary, s.primary),
        'onPrimaryContainer/primaryContainer': (s.onPrimaryContainer, s.primaryContainer),
        'onSecondaryContainer/secondaryContainer': (s.onSecondaryContainer, s.secondaryContainer),
        'error/surface': (s.error, s.surface),
        'success': (st.onSuccess, st.success),
        'warning': (st.onWarning, st.warning),
        'danger': (st.onDanger, st.danger),
        'info': (st.onInfo, st.info),
        'neutral': (st.onNeutral, st.neutral),
        'ai': (st.onAi, st.ai),
      };
      for (final e in pairs.entries) {
        test(e.key, () {
          final ratio = contrast(e.value.$1, e.value.$2);
          expect(ratio, greaterThanOrEqualTo(4.5), reason: '${e.key}: ${ratio.toStringAsFixed(2)}:1');
        });
      }
    });
  }
}
