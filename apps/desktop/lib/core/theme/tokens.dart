import 'package:flutter/material.dart';

/// Design tokens (arch §3.5). Defined once; themes and widgets read them from here.
///
/// Palette comes from the brand sheet (D-19). Every foreground/background pair used in
/// light and dark themes meets WCAG 2.2 AA (4.5:1 for text).
abstract final class Brand {
  static const navy = Color(0xFF0B1F4D);
  static const blue = Color(0xFF1E5BC6);
  static const blueLight = Color(0xFF8AB4FF);
  static const green = Color(0xFF1E9E4A);
  static const greenLight = Color(0xFF6FD594);
  static const amber = Color(0xFFF2A900);
  static const red = Color(0xFFC62828);
  static const redLight = Color(0xFFFF8A80);
}

abstract final class Space {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class Radii {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double pill = 999;
  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius control = BorderRadius.all(Radius.circular(md));
}

/// Motion tokens. Durations collapse to zero when the platform asks for reduced motion.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
  static const Curve standard = Curves.easeOutCubic;

  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;
}

abstract final class Layout {
  static const double sidebarWidth = 248;
  static const double sidebarCollapsed = 72;
  static const double contentMaxWidth = 1280;
  static const double formMaxWidth = 520;
  static const double compactBreakpoint = 1100;
}

/// Semantic status colours used by badges. A colour is never the only signal:
/// badges always pair it with an icon and a label (arch §3.5).
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
    required this.info,
    required this.onInfo,
    required this.neutral,
    required this.onNeutral,
    required this.ai,
    required this.onAi,
  });

  final Color success, onSuccess, warning, onWarning, danger, onDanger;
  final Color info, onInfo, neutral, onNeutral, ai, onAi;

  static const light = StatusColors(
    success: Color(0xFFE3F5E9),
    onSuccess: Color(0xFF0E5A2A),
    warning: Color(0xFFFFF3D1),
    onWarning: Color(0xFF6B4A00),
    danger: Color(0xFFFDE7E7),
    onDanger: Color(0xFF8E1B1B),
    info: Color(0xFFE5EEFC),
    onInfo: Color(0xFF15418F),
    neutral: Color(0xFFEDEFF3),
    onNeutral: Color(0xFF3A4252),
    ai: Color(0xFFF0E8FD),
    onAi: Color(0xFF4F2A8C),
  );

  static const dark = StatusColors(
    success: Color(0xFF173D26),
    onSuccess: Color(0xFFA8E8BE),
    warning: Color(0xFF433411),
    onWarning: Color(0xFFFFD98A),
    danger: Color(0xFF4A1F1F),
    onDanger: Color(0xFFFFB4AB),
    info: Color(0xFF1A2F55),
    onInfo: Color(0xFFB5CCFF),
    neutral: Color(0xFF2A2F3A),
    onNeutral: Color(0xFFCBD2DE),
    ai: Color(0xFF34245A),
    onAi: Color(0xFFD9C6FF),
  );

  @override
  StatusColors copyWith({Color? success}) => this;

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) =>
      other is StatusColors && t >= 0.5 ? other : this;
}
