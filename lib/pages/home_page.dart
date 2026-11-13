import 'package:flutter/material.dart';

import '../app/app_navigation.dart';
import '../app/app_routes.dart';
import '../app/theme/farmago_tokens.dart';
import '../auth/auth_controller.dart';
import '../components/farmago/acciones.dart';
import '../components/farmago/buttons.dart';
import '../components/farmago/estampado.dart';
import '../components/farmago/deadline_ring.dart';
import '../components/farmago/feedback.dart';
import '../components/farmago/shell.dart';
import '../components/farmago/status_badge.dart';
import '../components/farmago/trail.dart';
import '../components/farmago/wordmark.dart';
import '../hooks/eps_resumen_controller.dart';
import '../hooks/patient_home_controller.dart';
import '../notifications/notification_controller.dart';
import '../types/delivery.dart';
import '../types/pendiente.dart';
import '../utils/delivery_format.dart';
import '../utils/pendiente_format.dart';
import '../utils/pendientes_rol.dart';
import '../utils/plazo_vista.dart';
import 'notifications_page.dart';

part 'home_contenido.dart';
part 'home_eps.dart';

/// Inicio de FarmaGo: el punto de entrada al estado real del paciente.
///
/// Prioridad, según los datos que existen: domicilio en curso, luego un pendiente que conviene
/// mirar, y por último un estado vacío con acciones concretas. La navegación vive en el shell
/// (barra lateral en escritorio, barra inferior en móvil) y no en la pantalla.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.auth,
    required this.notifications,
    required this.inicio,
    this.resumenEps,
    required this.onAnalyze,
    required this.onNotifications,
    required this.onAccount,
    required this.onTracking,
    this.onCalificar,
    required this.onPendienteDetalle,
    this.onRequestDelivery,
    this.onMyOrders,
    this.onOrdenes,
    this.onDriverBoard,
    this.onPendientes,
    this.onAdminUsers,
    this.onAdminRatings,
    this.onAdminOrders,
  });

  final AuthController auth;
  final NotificationController notifications;

  /// Datos del paciente: domicilio en curso, pendientes y su estado de carga.
  final PatientHomeController inicio;

  /// Cifras del plazo de 48 h para la EPS (solo ese rol).
  final EpsResumenController? resumenEps;

  final VoidCallback onAnalyze;
  final VoidCallback onNotifications;
  final VoidCallback onAccount;
  final VoidCallback? onRequestDelivery;
  final VoidCallback? onMyOrders;

  /// Órdenes y autorizaciones (solo paciente). La barra inferior ya tiene cuatro destinos
  /// (manual §8.12), así que en móvil se llega desde las acciones del inicio.
  final VoidCallback? onOrdenes;
  final VoidCallback? onDriverBoard;
  final VoidCallback? onPendientes;
  final VoidCallback? onAdminUsers;
  final VoidCallback? onAdminRatings;
  final VoidCallback? onAdminOrders;

  /// Abre el seguimiento de un domicilio (por `deliveryId`).
  final void Function(String deliveryId) onTracking;

  /// Abre la entrega para calificarla (por defecto, el mismo seguimiento).
  final void Function(String deliveryId)? onCalificar;

  /// Abre el detalle de un pendiente (por `id`).
  final void Function(String pendienteId) onPendienteDetalle;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool get isPatient => widget.auth.user?.role == 'PATIENT';
  bool get isDriver => widget.auth.user?.role == 'DELIVERY_DRIVER';
  bool get isAdmin => widget.auth.user?.role == 'ADMIN';
  bool get isEps => widget.auth.user?.role == 'EPS';
  PendientesRol? get _rol => PendientesRol.fromCode(widget.auth.user?.role);
  bool get _pendientesVisible => widget.onPendientes != null && _rol != null;

  @override
  void initState() {
    super.initState();
    // Solo los pacientes tienen pedidos y pendientes propios; los demás roles no consultan esos datos.
    if (isPatient) widget.inicio.load();
    if (isEps) widget.resumenEps?.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([
          widget.auth,
          widget.notifications,
          widget.inicio,
          if (widget.resumenEps != null) widget.resumenEps!,
        ]),
        builder: (context, _) {
          final ancho = MediaQuery.sizeOf(context).width;
          return FgAppShell(
            titulo: 'Inicio',
            destinos: _destinos(),
            destinosMovil: _destinosMovil(),
            accionesSuperiores: [
              ListenableBuilder(
                listenable: widget.notifications,
                builder: (context, _) => NotificationBellButton(
                  unreadCount: widget.notifications.unreadCount,
                  onPressed: widget.onNotifications,
                ),
              ),
              FgIconButton(icon: Icons.account_circle_outlined, tooltip: 'Mi cuenta', onPressed: widget.onAccount),
            ],
            cuerpo: _Contenido(pantalla: this, movil: false, ancho: ancho),
            cuerpoMovil: _Contenido(pantalla: this, movil: true, ancho: ancho),
          );
        },
      );

  /// Destinos del menú: los mismos de [AppNavigation] que usa el resto de la app, para que el
  /// menú no cambie entre pantallas. Aquí cada ruta abre la pantalla con su callback; un destino
  /// sin callback no se muestra.
  VoidCallback? _accion(String ruta) => switch (ruta) {
        AppRoutes.home => () {},
        AppRoutes.uploadPrescription => widget.onAnalyze,
        AppRoutes.requestDelivery => widget.onRequestDelivery,
        AppRoutes.ordenes => widget.onOrdenes,
        AppRoutes.myOrders => widget.onMyOrders,
        AppRoutes.pendientes => widget.onPendientes,
        AppRoutes.account => widget.onAccount,
        AppRoutes.driverBoard => widget.onDriverBoard,
        AppRoutes.adminOrders => widget.onAdminOrders,
        AppRoutes.adminUsers => widget.onAdminUsers,
        AppRoutes.adminRatings => widget.onAdminRatings,
        _ => null,
      };

  List<FgDestino> _conAccion(
    List<FgDestino> Function({required String? role, required String path, required void Function(String) go}) armar,
  ) =>
      [
        for (final d in armar(role: widget.auth.user?.role, path: AppRoutes.home, go: (_) {}))
          if (_accion(d.ruta ?? '') case final accion?)
            FgDestino(icono: d.icono, etiqueta: d.etiqueta, ruta: d.ruta, seleccionado: d.seleccionado, onTap: accion),
      ];

  /// Todos los destinos reales del rol (barra lateral).
  List<FgDestino> _destinos() => _conAccion(AppNavigation.lateral);

  /// Hasta cuatro destinos para la barra inferior del móvil (manual §8.12).
  List<FgDestino> _destinosMovil() => _conAccion(AppNavigation.movil);
}
