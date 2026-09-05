import 'package:flutter/material.dart';

/// Ink & Amber palette (Option A).
///
/// Neutral ink/paper base + one warm amber accent. High contrast, night-safe.
class AppColors {
  AppColors._();

  // Ink & paper
  static const Color inkLight = Color(0xFF1A1A18);
  static const Color inkDark = Color(0xFFE9E6DE);
  static const Color paperLight = Color(0xFFFAF7F2);
  static const Color paperDark = Color(0xFF191816);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF211F1B);

  // Accent
  static const Color accentLight = Color(0xFFC98A2D);
  static const Color accentDark = Color(0xFFE4A94B);
  static const Color onAccent = Color(0xFF1A1A18);

  /// Home background gradient (amber -> warm neutral).
  static const LinearGradient homeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC98A2D), Color(0xFF5A4630), Color(0xFF191816)],
  );
}

/// Theme extension for non-ColorScheme chrome (glass surfaces, muted ink).
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.glassSurface,
    required this.glassSurfaceStrong,
    required this.glassBorder,
    required this.inkMuted,
  });

  final Color glassSurface;
  final Color glassSurfaceStrong;
  final Color glassBorder;
  final Color inkMuted;

  @override
  AppThemeExtension copyWith({
    Color? glassSurface,
    Color? glassSurfaceStrong,
    Color? glassBorder,
    Color? inkMuted,
  }) {
    return AppThemeExtension(
      glassSurface: glassSurface ?? this.glassSurface,
      glassSurfaceStrong: glassSurfaceStrong ?? this.glassSurfaceStrong,
      glassBorder: glassBorder ?? this.glassBorder,
      inkMuted: inkMuted ?? this.inkMuted,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t)!,
      glassSurfaceStrong:
          Color.lerp(glassSurfaceStrong, other.glassSurfaceStrong, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
    );
  }
}
