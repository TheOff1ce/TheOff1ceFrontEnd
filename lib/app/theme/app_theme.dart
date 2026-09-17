import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF6D3FD6),
      dark = Color(0xFF4D249D),
      light = Color(0xFFEDE7FB),
      background = Color(0xFFF9F8FC),
      text = Color(0xFF201B2B),
      secondary = Color(0xFF6C6677),
      warning = Color(0xFFFFF2D7),
      warningText = Color(0xFF9A5B00),
      error = Color(0xFFBA1A1A);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          elevation: 0,
        ),
      );
}

abstract final class AppText {
  static const display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.12,
    color: AppColors.text,
  );
  static const heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const body = TextStyle(
    fontSize: 15,
    height: 1.45,
    color: AppColors.secondary,
  );
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.secondary,
  );
}
