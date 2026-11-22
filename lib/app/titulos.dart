import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import 'theme/farmago_tokens.dart';

/// Título de la pestaña del navegador para cada pantalla: «Seguimiento del domicilio · FarmaGo».
/// Ayuda a distinguir varias pestañas, al historial del navegador y a los lectores de pantalla,
/// que anuncian el título al cambiar de pantalla. Usa los mismos nombres que la pantalla y el menú.
abstract final class TitulosDePantalla {
  static const marca = 'FarmaGo';

  static String paraRuta(String path) {
    final nombre = _nombre(path);
    return nombre == null ? marca : '$nombre · $marca';
  }

  static String? _nombre(String path) {
    if (path.startsWith('/orders/tracking/')) return 'Seguimiento del domicilio';
    if (path.startsWith('/admin/orders/tracking/')) return 'Seguimiento del domicilio';
    if (path.startsWith('${AppRoutes.driverBoard}/')) return 'Entrega';
    if (path.startsWith('${AppRoutes.ordenes}/')) return 'Orden';
    if (path.startsWith('${AppRoutes.pendientes}/')) return 'Pendiente';
    return switch (path) {
      AppRoutes.landing => null,
      AppRoutes.login || LegacyRoutes.login => 'Iniciar sesión',
      AppRoutes.register => 'Crear cuenta',
      AppRoutes.forgotPassword => 'Recuperar contraseña',
      AppRoutes.resetPassword => 'Nueva contraseña',
      AppRoutes.verifyEmail => 'Confirma tu correo',
      AppRoutes.googleCallback || AppRoutes.oauthLanding => 'Ingresando',
      AppRoutes.home => 'Inicio',
      AppRoutes.uploadPrescription => 'Analizar fórmula',
      AppRoutes.analyzingPrescription => 'Analizando fórmula',
      AppRoutes.prescriptionResult => 'Resultado del análisis',
      AppRoutes.notifications => 'Notificaciones',
      AppRoutes.account => 'Mi cuenta',
      AppRoutes.completeProfile => 'Completa tu perfil',
      AppRoutes.myOrders => 'Mis domicilios',
      AppRoutes.requestDelivery => 'Pedir domicilio',
      AppRoutes.ordenes => 'Órdenes y autorizaciones',
      AppRoutes.pendientes => 'Pendientes',
      AppRoutes.driverBoard => 'Domicilios',
      AppRoutes.adminUsers => 'Usuarios',
      AppRoutes.adminOrders => 'Domicilios',
      AppRoutes.adminRatings => 'Calificaciones',
      _ => 'Página no encontrada',
    };
  }
}

/// Mantiene el título al día con la ruta actual. Va dentro de `MaterialApp.builder`, así se
/// construye después del `Title` de la app y su título es el que queda.
class TituloDePantalla extends StatefulWidget {
  const TituloDePantalla({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  State<TituloDePantalla> createState() => _TituloDePantallaState();
}

class _TituloDePantallaState extends State<TituloDePantalla> {
  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_cambioDeRuta);
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_cambioDeRuta);
    super.dispose();
  }

  /// El enrutador puede avisar en medio de una construcción (por ejemplo, al redirigir): entonces
  /// el título se actualiza al terminar el cuadro.
  void _cambioDeRuta() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  String get _ruta {
    try {
      return widget.router.routerDelegate.currentConfiguration.uri.path;
    } catch (_) {
      return '/';
    }
  }

  @override
  Widget build(BuildContext context) =>
      Title(title: TitulosDePantalla.paraRuta(_ruta), color: FgColors.azul600, child: widget.child);
}
