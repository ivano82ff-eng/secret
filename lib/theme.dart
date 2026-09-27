import 'package:flutter/material.dart';

ThemeData secretTheme() {
  const ink = Color(0xFF1B3A31);
  const paper = Color(0xFFF6F3EC);
  const card = Color(0xFFFFFCF7);
  final scheme = ColorScheme.fromSeed(
    seedColor: ink,
    brightness: Brightness.light,
    surface: paper,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme.copyWith(
      primary: ink,
      onPrimary: Colors.white,
      surface: paper,
      secondary: const Color(0xFF8C5A3C),
    ),
    scaffoldBackgroundColor: paper,
    dividerColor: const Color(0xFFE4DDD2),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: paper,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: const CardThemeData(color: card, elevation: 0),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
