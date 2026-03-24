import 'package:flutter/material.dart';

class AppColors {
  // Dark teal palette inspired by the PeakPicks branding
  static const Color background = Color(0xFF0D1B2A);
  static const Color surface = Color(0xFF1B2838);
  static const Color surfaceLight = Color(0xFF243447);
  static const Color accent = Color(0xFF00BFA6); // teal accent
  static const Color accentLight = Color(0xFF64FFDA);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color error = Color(0xFFEF5350);
  static const Color divider = Color(0xFF37474F);
}

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.accent,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accentLight,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.background,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 28,
          color: AppColors.textPrimary),
      headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 22,
          color: AppColors.textPrimary),
      titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: AppColors.textPrimary),
      bodyMedium:
          TextStyle(fontSize: 14, color: AppColors.textSecondary),
      bodySmall:
          TextStyle(fontSize: 12, color: AppColors.textSecondary),
    ),
    dividerColor: AppColors.divider,
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
