import 'package:flutter/material.dart';
import 'color_tokens.dart';

/// ThemeData builders for the Ink & Amber palette.
class AppTheme {
  AppTheme._();

  static ThemeData buildLightTheme() => _build(
        brightness: Brightness.light,
        ink: AppColors.inkLight,
        paper: AppColors.paperLight,
        surface: AppColors.surfaceLight,
        accent: AppColors.accentLight,
        onAccent: AppColors.onAccent,
        extensions: const AppThemeExtension(
          glassSurface: Color(0x0D1A1A18), // ink @ ~5%
          glassSurfaceStrong: Color(0x261A1A18), // ink @ ~15%
          glassBorder: Color(0x1F1A1A18), // ink @ ~12%
          inkMuted: Color(0x991A1A18), // ink @ ~60%
        ),
      );

  static ThemeData buildDarkTheme() => _build(
        brightness: Brightness.dark,
        ink: AppColors.inkDark,
        paper: AppColors.paperDark,
        surface: AppColors.surfaceDark,
        accent: AppColors.accentDark,
        onAccent: AppColors.onAccent,
        extensions: const AppThemeExtension(
          glassSurface: Color(0x0DFFFFFF), // white @ ~5%
          glassSurfaceStrong: Color(0x26FFFFFF), // white @ ~15%
          glassBorder: Color(0x1FFFFFFF), // white @ ~12%
          inkMuted: Color(0xB3FFFFFF), // white @ ~70%
        ),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color ink,
    required Color paper,
    required Color surface,
    required Color accent,
    required Color onAccent,
    required AppThemeExtension extensions,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      surface: surface,
      onSurface: ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      extensions: [extensions],
      // Dialogs / bottom sheets
      dialogTheme: DialogThemeData(
        backgroundColor: surface.withValues(alpha: 0.96),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface.withValues(alpha: 0.98),
      ),
      // Cards
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
      ),
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
        ),
      ),
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: extensions.inkMuted),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0x40FFFFFF)), // neutral divider
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: ink,
        unselectedLabelColor: extensions.inkMuted,
        dividerColor: Colors.transparent,
      ),
      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
      ),
    );
  }
}
