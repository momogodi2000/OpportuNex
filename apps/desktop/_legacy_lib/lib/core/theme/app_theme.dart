import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryNavy = Color(0xFF0D1B3E);
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentGold = Color(0xFFEAB308);
  static const Color accentBlue = Color(0xFF3B82F6);

  // Badge Colors
  static const Color badgeVerified = Color(0xFF22C55E); // Vérifié (green)
  static const Color badgeDeduced = Color(0xFF3B82F6); // Déduit (blue)
  static const Color badgeAIGenerated = Color(0xFFA855F7); // Généré IA (purple)
  static const Color badgeNotSpecified = Color(
    0xFF9CA3AF,
  ); // Non précisé (grey)
  static const Color badgeUnverifiable = Color(
    0xFFF97316,
  ); // Non vérifiable (orange)
  static const Color badgeExpired = Color(0xFFEF4444); // Expiré (red)
  static const Color badgeExpiringSoon = Color(
    0xFFF59E0B,
  ); // Échéance proche (amber)

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w800,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w800,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryNavy,
        secondary: primaryGreen,
        tertiary: accentOrange,
      ),
      textTheme: _buildTextTheme(base.textTheme),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryNavy,
        secondary: primaryGreen,
        tertiary: accentOrange,
        brightness: Brightness.dark,
      ),
      textTheme: _buildTextTheme(base.textTheme),
    );
  }
}
