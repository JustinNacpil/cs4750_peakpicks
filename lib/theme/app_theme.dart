import 'package:flutter/material.dart';

class AppColors {
  // Deep monochrome dark palette
  static const Color background  = Color(0xFF080A0C); // near-black
  static const Color surface     = Color(0xFF111518); // dark card
  static const Color surfaceLight= Color(0xFF1C2128); // slightly lighter
  static const Color accent      = Color(0xFF00C896); // teal-green stays as brand pop
  static const Color accentLight = Color(0xFF4DFFD2);
  static const Color textPrimary = Color(0xFFF0F2F4);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color error       = Color(0xFFEF5350);
  static const Color divider     = Color(0xFF21262D);
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
      backgroundColor: AppColors.background,
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.divider, width: 1),
      ),
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
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 28,
          color: AppColors.textPrimary),
      headlineMedium: TextStyle(
          fontWeight: FontWeight.w700, fontSize: 22,
          color: AppColors.textPrimary),
      titleMedium: TextStyle(
          fontWeight: FontWeight.w600, fontSize: 16,
          color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      bodySmall:  TextStyle(fontSize: 12, color: AppColors.textSecondary),
    ),
    dividerColor: AppColors.divider,
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
    ),
  );
}
