import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class AppTheme {
  static const _font = 'Inter';

  static ThemeData light() => _build(
        ColorScheme.fromSeed(
          seedColor: Brand.blue,
          primary: Brand.blue,
          secondary: Brand.green,
          tertiary: Brand.amber,
          error: Brand.red,
          surface: const Color(0xFFFFFFFF),
          onSurface: Brand.navy,
        ).copyWith(
          surfaceContainerLowest: const Color(0xFFFFFFFF),
          surfaceContainerLow: const Color(0xFFF6F8FB),
          surfaceContainer: const Color(0xFFF0F3F8),
          surfaceContainerHigh: const Color(0xFFE8EDF4),
          onSurfaceVariant: const Color(0xFF4A5468),
          outline: const Color(0xFF8A94A8),
          outlineVariant: const Color(0xFFDCE2EB),
        ),
        StatusColors.light,
      );

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(
          seedColor: Brand.blue,
          brightness: Brightness.dark,
          primary: Brand.blueLight,
          secondary: Brand.greenLight,
          tertiary: Brand.amber,
          error: Brand.redLight,
          surface: const Color(0xFF111622),
          onSurface: const Color(0xFFE6EAF2),
        ).copyWith(
          surfaceContainerLowest: const Color(0xFF0B0F18),
          surfaceContainerLow: const Color(0xFF161C2A),
          surfaceContainer: const Color(0xFF1B2232),
          surfaceContainerHigh: const Color(0xFF232B3D),
          onSurfaceVariant: const Color(0xFFAEB7C8),
          outline: const Color(0xFF7D879A),
          outlineVariant: const Color(0xFF2E3749),
        ),
        StatusColors.dark,
      );

  static ThemeData _build(ColorScheme scheme, StatusColors status) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _font,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
      extensions: [status],
    );
    final text = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
    final outlineBorder = OutlineInputBorder(
      borderRadius: Radii.control,
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return base.copyWith(
      textTheme: text,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.card,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: outlineBorder,
        enabledBorder: outlineBorder,
        focusedBorder: outlineBorder.copyWith(borderSide: BorderSide(color: scheme.primary, width: 2)),
        errorBorder: outlineBorder.copyWith(borderSide: BorderSide(color: scheme.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          shape: const RoundedRectangleBorder(borderRadius: Radii.control),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          shape: const RoundedRectangleBorder(borderRadius: Radii.control),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 40),
          shape: const RoundedRectangleBorder(borderRadius: Radii.control),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Radii.pill))),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, width: 480),
      tooltipTheme: const TooltipThemeData(waitDuration: Duration(milliseconds: 500)),
      focusColor: scheme.primary.withValues(alpha: 0.12),
    );
  }
}

extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  StatusColors get status => Theme.of(this).extension<StatusColors>() ?? StatusColors.light;
}
