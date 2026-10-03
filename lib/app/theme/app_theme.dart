import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const navy = Color(0xFF0B3A6E),
      blue = Color(0xFF2F6FAF),
      sky = Color(0xFFA9CBEA),
      primary = blue,
      dark = navy,
      light = Color(0xFFEAF4FC),
      background = Color(0xFFF5FAFE),
      text = Color(0xFF172536),
      secondary = Color(0xFF5B6B7D),
      warning = Color(0xFFFFF2D7),
      warningText = Color(0xFF9A5B00),
      error = Color(0xFFB42318),
      success = Color(0xFF087443);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy),
        textTheme: GoogleFonts.manropeTextTheme(),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.sky)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.sky)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.navy, width: 2)),
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
