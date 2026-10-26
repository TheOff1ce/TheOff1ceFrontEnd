import 'package:flutter/material.dart';

/// Tokens del manual unificado de identidad FarmaGo (Anexo A, `farmago-tokens.css`),
/// traducidos uno a uno a Dart. Es la fuente de verdad numérica del manual.
///
/// Reglas del manual (§0): ningún widget de las pantallas de pendientes declara
/// colores, tamaños, radios, sombras ni duraciones literales; solo usa estos tokens.
/// La única excepción permitida es `Colors.white` (texto sobre fondos de color).
///
/// Convive con `app_theme.dart` (tema anterior de la app, Manrope): este archivo se
/// aplica solo a las pantallas que lo envuelven con [FarmaGoTheme] (pendientes).
abstract final class FgColors {
  // Marca
  static const azul100 = Color(0xFFE3F1F9);
  static const azul200 = Color(0xFFBFDDF0);
  static const azul600 = Color(0xFF0474AC);
  static const azul700 = Color(0xFF035C8C);
  static const azul800 = Color(0xFF034E78);

  // Neutros y superficies
  static const ink = Color(0xFF12303F);
  static const inkSoft = Color(0xFF35505E);
  static const placeholder = Color(0xFF5E7683);
  static const fondo = Color(0xFFF3F8FA);
  static const fondoHundido = Color(0xFFE9F1F4);
  static const superficie = Color(0xFFFFFFFF);
  static const linea = Color(0xFFC9DCE3);
  static const lineaControl = Color(0xFF6B8795);
  static const deshabilitadoBg = Color(0xFFE3ECF0);
  static const deshabilitadoFg = Color(0xFF4B6573);
  static const track = Color(0xFFC3D6DE);
  static const skeleton = Color(0xFFDDE8ED);
  static const scrim = Color(0x8F12303F); // rgb(18 48 63 / .56)
  static const scrimSuave = Color(0x5212303F); // rgb(18 48 63 / .32)

  // Estados del plazo y avisos
  static const vigenteFg = Color(0xFF034E78);
  static const vigenteBg = Color(0xFFE3F1F9);
  static const vigenteSolid = Color(0xFF0474AC);
  static const riesgoFg = Color(0xFF6B3F00);
  static const riesgoBg = Color(0xFFFFF1D6);
  static const riesgoSolid = Color(0xFFB35C00);
  static const incumplidoFg = Color(0xFF8C1D18);
  static const incumplidoBg = Color(0xFFFDE7E5);
  static const incumplidoSolid = Color(0xFFB3261E);
  static const cumplidoFg = Color(0xFF18552A);
  static const cumplidoBg = Color(0xFFE4F3E6);
  static const cumplidoSolid = Color(0xFF23703A);
  static const neutroFg = Color(0xFF35505E);
  static const neutroBg = Color(0xFFEEF2F4);
  static const peligro = Color(0xFFB3261E);
  static const peligroHover = Color(0xFF9C1F18);
  static const peligroPressed = Color(0xFF8C1D18);

  /// Excepción permitida por el manual (§0.2): texto sobre fondos de color.
  static const blanco = Color(0xFFFFFFFF);

  /// Enlace de acción dentro del toast oscuro (manual §7.8).
  static const enlaceSobreOscuro = Color(0xFF8CC8EA);
}

/// Espaciado (base 4 px). Solo estos valores.
abstract final class FgSpace {
  static const sp0 = 0.0;
  static const sp1 = 4.0;
  static const sp2 = 8.0;
  static const sp3 = 12.0;
  static const sp4 = 16.0;
  static const sp4h = 20.0;
  static const sp5 = 24.0;
  static const sp6 = 32.0;
  static const sp7 = 48.0;
  static const sp8 = 64.0;
  static const sp9 = 96.0;
}

abstract final class FgRadius {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 24.0;
  static const pill = 999.0;
}

abstract final class FgBorder {
  static const w1 = 1.0;
  static const w2 = 2.0;
  static const foco = 3.0;
  static const w4 = 4.0;
}

abstract final class FgShadow {
  static const e0 = <BoxShadow>[];
  static const e1 = <BoxShadow>[
    BoxShadow(color: Color(0x1412303F), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0F12303F), offset: Offset(0, 2), blurRadius: 8),
  ];
  static const e2 = <BoxShadow>[BoxShadow(color: Color(0x1F12303F), offset: Offset(0, 4), blurRadius: 12)];
  static const e3 = <BoxShadow>[BoxShadow(color: Color(0x2912303F), offset: Offset(0, 8), blurRadius: 24)];
  static const e4 = <BoxShadow>[BoxShadow(color: Color(0x3D12303F), offset: Offset(0, 16), blurRadius: 48)];
  static const eArriba = <BoxShadow>[BoxShadow(color: Color(0x1F12303F), offset: Offset(0, -4), blurRadius: 16)];
}

/// Tamaños de controles y estructura.
abstract final class FgSize {
  static const ctrlSm = 40.0;
  static const ctrlMd = 48.0;
  static const ctrlLg = 56.0;
  static const inputMovil = 56.0;
  static const inputDesktop = 48.0;
  static const tapMin = 48.0;
  static const headerMovil = 56.0;
  static const barraAccion = 88.0;
  static const topbar = 64.0;
  static const filaTabla = 56.0;
  static const encabezadoTabla = 48.0;
  static const pieTabla = 64.0;
  static const dialogSm = 480.0;
  static const dialogMd = 640.0;
  static const panel = 480.0;
  static const panelLg = 640.0;
  static const toast = 480.0;
  static const contenido = 1280.0;
  static const lectura = 720.0; // aprox. 66 caracteres (--w-lectura)
  static const iconoSm = 20.0;
  static const iconoMd = 24.0;
  static const iconoLg = 32.0;
}

/// Breakpoints: móvil < 768 · tablet 768–1199 · desktop >= 1200.
abstract final class FgBreakpoint {
  static const tablet = 768.0;
  static const desktop = 1200.0;

  static bool esCompacto(double ancho) => ancho < tablet;
  static bool esDesktop(double ancho) => ancho >= desktop;

  /// Margen lateral: 16 móvil · 24 tablet · 32 desktop.
  static double margenLateral(double ancho) => ancho >= desktop
      ? FgSpace.sp6
      : ancho >= tablet
          ? FgSpace.sp5
          : FgSpace.sp4;
}

abstract final class FgMotion {
  static const rapida = Duration(milliseconds: 120);
  static const media = Duration(milliseconds: 220);
  static const lenta = Duration(milliseconds: 320);
  static const reloj = Duration(milliseconds: 600);
  static const giroSpinner = Duration(milliseconds: 800);
  static const brilloSkeleton = Duration(milliseconds: 1400);
  static const ease = Cubic(.2, .7, .2, 1);
  static const easeSalida = Cubic(.4, 0, 1, 1);

  /// `prefers-reduced-motion`: sin animación.
  static Duration reducir(BuildContext context, Duration normal) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;
}

/// Estilos de texto del manual (§4). Tamaños lógicos: respetan el factor de texto del sistema.
abstract final class FgText {
  static const family = 'Atkinson Hyperlegible Next';

  static const _tabular = [FontFeature.tabularFigures()];

  static const display = TextStyle(
      fontFamily: family, fontSize: 48, fontWeight: FontWeight.w700, height: 1.1, color: FgColors.ink);
  static const h1Movil = TextStyle(
      fontFamily: family, fontSize: 30, fontWeight: FontWeight.w700, height: 1.2, color: FgColors.ink);
  static const h1Ancho = TextStyle(
      fontFamily: family, fontSize: 38, fontWeight: FontWeight.w700, height: 1.2, color: FgColors.ink);
  static const h2 = TextStyle(
      fontFamily: family, fontSize: 24, fontWeight: FontWeight.w700, height: 1.2, color: FgColors.ink);
  static const h3 = TextStyle(
      fontFamily: family, fontSize: 20, fontWeight: FontWeight.w700, height: 1.3, color: FgColors.ink);
  static const body = TextStyle(
      fontFamily: family, fontSize: 18, fontWeight: FontWeight.w400, height: 1.6, color: FgColors.ink);
  static const bodyLg = TextStyle(
      fontFamily: family, fontSize: 20, fontWeight: FontWeight.w400, height: 1.6, color: FgColors.ink);
  static const label = TextStyle(
      fontFamily: family, fontSize: 18, fontWeight: FontWeight.w600, height: 1.3, color: FgColors.ink);
  static const cell = TextStyle(
      fontFamily: family, fontSize: 17, fontWeight: FontWeight.w400, height: 1.4, color: FgColors.ink);
  static const caption = TextStyle(
      fontFamily: family, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: FgColors.inkSoft);

  /// Texto de botón: 20 (lg) · 18 (md) · 16 (sm), siempre 700.
  static TextStyle boton(double size) =>
      TextStyle(fontFamily: family, fontSize: size, fontWeight: FontWeight.w700, height: 1.3);

  static TextStyle h1(double ancho) => ancho >= FgBreakpoint.tablet ? h1Ancho : h1Movil;

  /// Cifras alineadas (`.num`): fechas, horas, contadores.
  static TextStyle num(TextStyle base) => base.copyWith(fontFeatures: _tabular);
}

/// Tema de Material para las pantallas que siguen el manual unificado.
/// Los widgets propios (`Fg*`) leen los tokens directamente; esto cubre los widgets de Material
/// que no se reescriben (ListView, Scaffold, Tooltip, etc.).
abstract final class FarmaGoTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: FgColors.azul600,
      onPrimary: FgColors.blanco,
      secondary: FgColors.azul800,
      onSecondary: FgColors.blanco,
      error: FgColors.peligro,
      onError: FgColors.blanco,
      surface: FgColors.superficie,
      onSurface: FgColors.ink,
      onSurfaceVariant: FgColors.inkSoft,
      outline: FgColors.lineaControl,
      outlineVariant: FgColors.linea,
      primaryContainer: FgColors.azul100,
      onPrimaryContainer: FgColors.azul800,
      errorContainer: FgColors.incumplidoBg,
      onErrorContainer: FgColors.incumplidoFg,
      surfaceContainerHighest: FgColors.fondoHundido,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: FgText.family,
      colorScheme: scheme,
      scaffoldBackgroundColor: FgColors.fondo,
      dividerColor: FgColors.linea,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textTheme: const TextTheme(
        displaySmall: FgText.display,
        headlineMedium: FgText.h1Ancho,
        headlineSmall: FgText.h2,
        titleLarge: FgText.h3,
        titleMedium: FgText.label,
        bodyLarge: FgText.body,
        bodyMedium: FgText.body,
        bodySmall: FgText.caption,
        labelLarge: FgText.label,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: FgColors.ink,
          borderRadius: BorderRadius.circular(FgRadius.sm),
          boxShadow: FgShadow.e3,
        ),
        textStyle: FgText.caption.copyWith(color: FgColors.blanco),
        padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp3, vertical: FgSpace.sp2),
        waitDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

/// Aplica el tema del manual al subárbol (pantallas de pendientes).
class FarmaGoThemed extends StatelessWidget {
  const FarmaGoThemed({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
        data: FarmaGoTheme.light,
        child: DefaultTextStyle(style: FgText.body, child: child),
      );
}
