import 'package:flutter/material.dart';

import 'farmago_tokens.dart';

/// Brand palette = tokens of the unified FarmaGo manual (`farmago_tokens.dart`). Widgets never
/// use these directly: they read the [ColorScheme] and [AppStatusColors] built from them (FE-009).
abstract final class _Palette {
  static const navy = FgColors.azul800;
  static const blue = FgColors.azul600;
  static const light = FgColors.azul100;
  static const background = FgColors.fondo;
  static const text = FgColors.ink;
  static const secondaryText = FgColors.inkSoft;
  static const outline = FgColors.lineaControl;
  static const line = FgColors.linea;
  static const warning = FgColors.riesgoBg;
  static const warningText = FgColors.riesgoFg;
  static const error = FgColors.peligro;
  static const errorContainer = FgColors.incumplidoBg;
  static const errorText = FgColors.incumplidoFg;
  static const success = FgColors.cumplidoFg;
  static const successContainer = FgColors.cumplidoBg;
}

/// Spacing scale (multiples of 4). Legacy aliases of [FgSpace]; new code uses [FgSpace] directly.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Radii of the manual: 8 controls, 14 buttons and cards, 24 windows. Legacy aliases of
/// [FgRadius]; new code uses [FgRadius] directly.
abstract final class AppRadii {
  static const s = FgRadius.sm;
  static const m = FgRadius.md;
  static const l = FgRadius.md;
  static const xl = FgRadius.md;
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
    decorative: _Palette.line,
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

/// App-wide theme built from the unified FarmaGo manual: Atkinson Hyperlegible Next, the
/// manual's palette, 48 px controls, radii 8/14/24 and a 2 px focus border. Every Material
/// widget (buttons, fields, chips, cards, dialogs) gets the manual's look without per-screen code.
abstract final class AppTheme {
  static const fontFamily = FgText.family;

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: _Palette.blue,
      onPrimary: FgColors.blanco,
      primaryContainer: _Palette.light,
      onPrimaryContainer: _Palette.navy,
      secondary: _Palette.navy,
      onSecondary: FgColors.blanco,
      surface: FgColors.superficie,
      onSurface: _Palette.text,
      onSurfaceVariant: _Palette.secondaryText,
      surfaceContainerHighest: FgColors.fondoHundido,
      outline: _Palette.outline,
      outlineVariant: _Palette.line,
      error: _Palette.error,
      onError: FgColors.blanco,
      errorContainer: _Palette.errorContainer,
      onErrorContainer: _Palette.errorText,
    );
    final text = _sinEspaciado(_textTheme());
    // §23: 1 px en reposo, 2 px con foco o error.
    OutlineInputBorder border(Color color, {bool activo = false}) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(FgRadius.sm),
          borderSide: BorderSide(color: color, width: activo ? FgBorder.controlActivo : FgBorder.control),
        );
    final buttonShape = WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(FgRadius.md)),
    );
    final buttonBase = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(FgSize.tapMin, FgSize.ctrlMd)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: FgSpace.sp5)),
      textStyle: WidgetStatePropertyAll(FgText.boton(18)),
      iconSize: const WidgetStatePropertyAll(FgSize.iconoMd),
      shape: buttonShape,
      elevation: const WidgetStatePropertyAll(0),
      splashFactory: NoSplash.splashFactory,
    );
    Color? pick(Set<WidgetState> s, {required Color rest, required Color hover, required Color pressed}) =>
        s.contains(WidgetState.pressed) ? pressed : (s.contains(WidgetState.hovered) ? hover : rest);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: _Palette.background,
      dividerColor: _Palette.line,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      extensions: const [AppStatusColors.light],
      dividerTheme: const DividerThemeData(color: _Palette.line, thickness: FgBorder.w1, space: FgBorder.w1),
      appBarTheme: const AppBarTheme(
        backgroundColor: FgColors.superficie,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _Palette.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: FgSize.headerMovil,
        titleTextStyle: FgText.h3,
        shape: Border(bottom: BorderSide(color: _Palette.line, width: FgBorder.w1)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FgColors.superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: FgSpace.sp4, vertical: FgSpace.sp4),
        labelStyle: FgText.body.copyWith(color: _Palette.secondaryText),
        floatingLabelStyle: FgText.label.copyWith(color: _Palette.navy),
        hintStyle: FgText.body.copyWith(color: FgColors.placeholder),
        helperStyle: FgText.caption,
        errorStyle: FgText.caption.copyWith(color: _Palette.errorText),
        border: border(_Palette.outline),
        enabledBorder: border(_Palette.outline),
        focusedBorder: border(_Palette.blue, activo: true),
        errorBorder: border(_Palette.error, activo: true),
        focusedErrorBorder: border(_Palette.error, activo: true),
        disabledBorder: border(FgColors.deshabilitadoBg),
        helperMaxLines: 3,
        errorMaxLines: 3,
      ),
      // Primary button (§8.1): azul 600 → 700 hover → 800 pressed; disabled with the manual's greys.
      filledButtonTheme: FilledButtonThemeData(
        style: buttonBase.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled)
              ? FgColors.deshabilitadoBg
              : pick(s, rest: FgColors.azul600, hover: FgColors.azul700, pressed: FgColors.azul800)),
          foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.disabled) ? FgColors.deshabilitadoFg : FgColors.blanco),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      // Secondary button, tonal (§23): azul 100 background, no border, azul 800 text (7.7:1).
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: buttonBase.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled)
              ? FgColors.deshabilitadoBg
              : pick(s, rest: FgColors.azul100, hover: FgColors.azul200, pressed: FgColors.azul200)),
          foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.disabled) ? FgColors.deshabilitadoFg : FgColors.azul800),
          side: const WidgetStatePropertyAll(BorderSide.none),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      // Tertiary (ghost) button.
      textButtonTheme: TextButtonThemeData(
        style: buttonBase.copyWith(
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: FgSpace.sp4)),
          backgroundColor: WidgetStateProperty.resolveWith(
              (s) => pick(s, rest: Colors.transparent, hover: FgColors.azul100, pressed: FgColors.azul200)),
          foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.disabled) ? FgColors.deshabilitadoFg : FgColors.azul800),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(FgSize.tapMin, FgSize.tapMin)),
          iconSize: const WidgetStatePropertyAll(FgSize.iconoMd),
          shape: buttonShape,
          foregroundColor: const WidgetStatePropertyAll(_Palette.text),
          backgroundColor: WidgetStateProperty.resolveWith(
              (s) => pick(s, rest: Colors.transparent, hover: FgColors.azul100, pressed: FgColors.azul200)),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FgColors.azul600,
        foregroundColor: FgColors.blanco,
        elevation: 0,
        extendedTextStyle: TextStyle(fontFamily: FgText.family, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FgColors.superficie,
        selectedColor: FgColors.azul100,
        disabledColor: FgColors.deshabilitadoBg,
        labelStyle: FgText.caption.copyWith(color: _Palette.text, fontWeight: FontWeight.w600),
        secondaryLabelStyle: FgText.caption.copyWith(color: FgColors.azul800, fontWeight: FontWeight.w700),
        checkmarkColor: FgColors.azul800,
        side: const BorderSide(color: _Palette.outline, width: FgBorder.control),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp3, vertical: FgSpace.sp2),
      ),
      // §23: same edge as FgDecor.tarjeta; Material draws the soft shadow from elevation 1.
      cardTheme: CardThemeData(
        color: FgColors.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: FgColors.sombraMaterial,
        margin: EdgeInsets.zero,
        shape: FgDecor.formaTarjeta(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: FgColors.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FgRadius.lg)),
        titleTextStyle: FgText.h3,
        contentTextStyle: FgText.body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FgColors.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(FgRadius.lg))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _Palette.text,
        contentTextStyle: FgText.body.copyWith(color: FgColors.blanco),
        actionTextColor: FgColors.enlaceSobreOscuro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FgRadius.sm)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FgColors.azul600,
        linearTrackColor: FgColors.track,
        circularTrackColor: Colors.transparent,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _Palette.text,
          borderRadius: BorderRadius.circular(FgRadius.sm),
          boxShadow: FgShadow.e3,
        ),
        textStyle: FgText.caption.copyWith(color: FgColors.blanco),
        padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp3, vertical: FgSpace.sp2),
        waitDuration: const Duration(milliseconds: 300),
      ),
      listTileTheme: const ListTileThemeData(minVerticalPadding: FgSpace.sp3, iconColor: _Palette.secondaryText),
    );
  }

  /// Material 3 adds letter spacing (0.25–0.5) to its type scale; the manual uses none. Without
  /// this, texts that only set a size would inherit that spacing and wrap differently.
  static TextTheme _sinEspaciado(TextTheme t) => TextTheme(
        displaySmall: t.displaySmall?.copyWith(letterSpacing: 0),
        headlineMedium: t.headlineMedium?.copyWith(letterSpacing: 0),
        headlineSmall: t.headlineSmall?.copyWith(letterSpacing: 0),
        titleLarge: t.titleLarge?.copyWith(letterSpacing: 0),
        titleMedium: t.titleMedium?.copyWith(letterSpacing: 0),
        titleSmall: t.titleSmall?.copyWith(letterSpacing: 0),
        bodyLarge: t.bodyLarge?.copyWith(letterSpacing: 0),
        bodyMedium: t.bodyMedium?.copyWith(letterSpacing: 0),
        bodySmall: t.bodySmall?.copyWith(letterSpacing: 0),
        labelLarge: t.labelLarge?.copyWith(letterSpacing: 0),
        labelMedium: t.labelMedium?.copyWith(letterSpacing: 0),
        labelSmall: t.labelSmall?.copyWith(letterSpacing: 0),
      );

  /// Manual type scale (§4): body 18, metadata never below 16.
  static TextTheme _textTheme() => TextTheme(
        displaySmall: FgText.h1Movil,
        headlineMedium: FgText.h1Ancho,
        headlineSmall: FgText.h2,
        titleLarge: FgText.h3,
        titleMedium: FgText.label,
        titleSmall: FgText.label.copyWith(fontSize: 16),
        bodyLarge: FgText.body.copyWith(color: _Palette.secondaryText),
        bodyMedium: FgText.body,
        bodySmall: FgText.caption,
        labelLarge: FgText.boton(18),
        labelMedium: FgText.caption.copyWith(fontWeight: FontWeight.w600),
        labelSmall: FgText.caption.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: _Palette.text),
      );
}

/// Short accessors so widgets read tokens instead of literals.
extension ThemeTokens on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  AppStatusColors get status => Theme.of(this).extension<AppStatusColors>() ?? AppStatusColors.light;
}
