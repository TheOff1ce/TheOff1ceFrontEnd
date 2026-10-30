import 'package:flutter/material.dart';

/// Brand palette. Widgets never use these directly: they read the
/// [ColorScheme] and [AppStatusColors] built from them (FE-009).
abstract final class _Palette {
  static const navy = Color(0xFF0B3A6E);
  static const blue = Color(0xFF2F6FAF);
  static const sky = Color(0xFFA9CBEA);
  static const light = Color(0xFFEAF4FC);
  static const background = Color(0xFFF5FAFE);
  static const text = Color(0xFF172536);
  static const secondaryText = Color(0xFF5B6B7D); // 5.2:1 on background
  static const outline = Color(0xFF6A8BB0); // ≥3:1 on white/background (FE-007)
  static const warning = Color(0xFFFFF2D7);
  static const warningText = Color(0xFF9A5B00); // 4.9:1 on warning
  static const error = Color(0xFFB42318); // 6.6:1 on white
  static const errorContainer = Color(0xFFFFE9E7);
  static const success = Color(0xFF087443); // 5.2:1 on successContainer
  static const successContainer = Color(0xFFE1F5EC);
}

/// Spacing scale (multiples of 4).
abstract final class AppSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadii {
  static const s = 12.0;
  static const m = 16.0;
  static const l = 20.0;
  static const xl = 24.0;
}

/// Semantic colors Material 3 does not cover (warning/success) plus brand surfaces.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.warningContainer,
    required this.onWarningContainer,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.brandSurface,
    required this.decorative,
    required this.mutedText,
  });

  final Color warningContainer;
  final Color onWarningContainer;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color brandSurface;

  /// Only for decoration, never as the only boundary of an interactive element.
  final Color decorative;
  final Color mutedText;

  static const light = AppStatusColors(
    warningContainer: _Palette.warning,
    onWarningContainer: _Palette.warningText,
    successContainer: _Palette.successContainer,
    onSuccessContainer: _Palette.success,
    brandSurface: _Palette.light,
    decorative: _Palette.sky,
    mutedText: _Palette.secondaryText,
  );

  @override
  AppStatusColors copyWith({
    Color? warningContainer,
    Color? onWarningContainer,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? brandSurface,
    Color? decorative,
    Color? mutedText,
  }) =>
      AppStatusColors(
        warningContainer: warningContainer ?? this.warningContainer,
        onWarningContainer: onWarningContainer ?? this.onWarningContainer,
        successContainer: successContainer ?? this.successContainer,
        onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
        brandSurface: brandSurface ?? this.brandSurface,
        decorative: decorative ?? this.decorative,
        mutedText: mutedText ?? this.mutedText,
      );

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      brandSurface: Color.lerp(brandSurface, other.brandSurface, t)!,
      decorative: Color.lerp(decorative, other.decorative, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
    );
  }
}

abstract final class AppTheme {
  static const fontFamily = 'Manrope';

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _Palette.navy,
      primary: _Palette.navy,
      onPrimary: Colors.white,
      secondary: _Palette.blue,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: _Palette.text,
      onSurfaceVariant: _Palette.secondaryText,
      outline: _Palette.outline,
      outlineVariant: _Palette.sky,
      error: _Palette.error,
      onError: Colors.white,
      errorContainer: _Palette.errorContainer,
      onErrorContainer: _Palette.error,
      primaryContainer: _Palette.light,
      onPrimaryContainer: _Palette.navy,
    );
    final text = _textTheme(scheme);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.m),
      borderSide: const BorderSide(color: _Palette.outline),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: _Palette.background,
      extensions: const [AppStatusColors.light],
      appBarTheme: AppBarTheme(
        backgroundColor: _Palette.background,
        foregroundColor: _Palette.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: _Palette.navy, width: 2)),
        errorBorder: border.copyWith(borderSide: const BorderSide(color: _Palette.error)),
        focusedErrorBorder: border.copyWith(borderSide: const BorderSide(color: _Palette.error, width: 2)),
        helperMaxLines: 3,
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(style: _buttonStyle(text)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(text).copyWith(
          side: const WidgetStatePropertyAll(BorderSide(color: _Palette.outline)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48), textStyle: text.labelLarge),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
      ),
    );
  }

  static ButtonStyle _buttonStyle(TextTheme text) => ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
        textStyle: WidgetStatePropertyAll(text.labelLarge),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.m)),
        ),
      );

  /// Type scale: body text is never below 16 px; captions never below 14 px.
  static TextTheme _textTheme(ColorScheme scheme) {
    final strong = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;
    return TextTheme(
      displaySmall: TextStyle(fontSize: 32, height: 1.15, fontWeight: FontWeight.w800, color: strong),
      headlineSmall: TextStyle(fontSize: 24, height: 1.25, fontWeight: FontWeight.w700, color: strong),
      titleLarge: TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.w700, color: strong),
      titleMedium: TextStyle(fontSize: 18, height: 1.3, fontWeight: FontWeight.w700, color: strong),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: muted),
      bodyMedium: TextStyle(fontSize: 16, height: 1.45, color: strong),
      bodySmall: TextStyle(fontSize: 14, height: 1.4, color: muted),
      labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: muted),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: strong),
    );
  }
}

/// Short accessors so widgets read tokens instead of literals.
extension ThemeTokens on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  AppStatusColors get status => Theme.of(this).extension<AppStatusColors>() ?? AppStatusColors.light;
}
