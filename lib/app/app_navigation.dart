import 'package:flutter/material.dart';

import '../components/farmago/shell.dart';
import '../utils/pendientes_rol.dart';
import 'app_routes.dart';

/// Destinos de la barra lateral fija (§23) según el rol, con el destino activo marcado según la
/// ruta actual. Son los mismos destinos que el inicio muestra en su barra lateral; aquí se arman
/// desde la ruta para que la barra siga visible en todas las pantallas privadas.
///
/// Solo navega: no decide permisos. Las reglas de acceso siguen en `AppRouter.redirect`.
abstract final class AppNavigation {
  static List<FgDestino> lateral({
    required String? role,
    required String path,
    required void Function(String location) go,
  }) {
    FgDestino destino(IconData icono, String etiqueta, String ruta, {bool Function(String)? activo}) => FgDestino(
          icono: icono,
          etiqueta: etiqueta,
          seleccionado: (activo ?? (p) => p == ruta || p.startsWith('$ruta/'))(path),
          onTap: () => go(ruta),
        );

    final inicio = destino(Icons.home_outlined, 'Inicio', AppRoutes.home);
    final cuenta = destino(Icons.account_circle_outlined, 'Mi cuenta', AppRoutes.account);
    final rolPendientes = PendientesRol.fromCode(role);
    final pendientes = rolPendientes == null
        ? null
        : destino(Icons.medication_outlined, rolPendientes.tituloEntrada, AppRoutes.pendientes);

    switch (role) {
      case 'ADMIN':
        return [
          inicio,
          destino(Icons.pending_actions_outlined, 'Domicilios pendientes', AppRoutes.adminOrders),
          destino(Icons.manage_accounts_outlined, 'Usuarios y roles', AppRoutes.adminUsers),
          destino(Icons.document_scanner_outlined, 'Analizar fórmula', AppRoutes.uploadPrescription),
          cuenta,
        ];
      case 'DELIVERY_DRIVER':
        return [
          inicio,
          destino(Icons.delivery_dining_outlined, 'Domicilios disponibles', AppRoutes.driverBoard),
          if (pendientes != null) pendientes,
          cuenta,
        ];
      case 'PATIENT':
        return [
          inicio,
          destino(Icons.document_scanner_outlined, 'Analizar fórmula', AppRoutes.uploadPrescription),
          destino(Icons.add_home_outlined, 'Pedir a casa', AppRoutes.requestDelivery),
          destino(Icons.assignment_outlined, 'Órdenes y autorizaciones', AppRoutes.ordenes),
          // «Mis domicilios» incluye el seguimiento, pero no «Pedir a casa» (/orders/new).
          destino(
            Icons.receipt_long_outlined,
            'Mis domicilios',
            AppRoutes.myOrders,
            activo: (p) => p == AppRoutes.myOrders || p.startsWith('${AppRoutes.myOrders}/tracking/'),
          ),
          if (pendientes != null) pendientes,
          cuenta,
        ];
      default:
        // EPS y cualquier otro rol con acceso a pendientes.
        return [inicio, if (pendientes != null) pendientes, cuenta];
    }
  }
}
