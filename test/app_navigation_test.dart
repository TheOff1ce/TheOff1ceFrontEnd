import 'package:farma_go/app/app_navigation.dart';
import 'package:farma_go/app/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Barra lateral fija (§23): destinos por rol y destino activo según la ruta.
void main() {
  List<String> etiquetas(String role) =>
      [for (final d in AppNavigation.lateral(role: role, path: AppRoutes.home, go: (_) {})) d.etiqueta];

  String? activo(String role, String path) {
    final seleccionados = AppNavigation.lateral(role: role, path: path, go: (_) {}).where((d) => d.seleccionado);
    return seleccionados.isEmpty ? null : seleccionados.single.etiqueta;
  }

  test('cada rol ve solo sus destinos', () {
    expect(etiquetas('PATIENT'), contains('Mis domicilios'));
    expect(etiquetas('PATIENT'), isNot(contains('Usuarios y roles')));
    expect(etiquetas('ADMIN'), containsAll(['Domicilios pendientes', 'Usuarios y roles', 'Calificaciones']));
    expect(etiquetas('DELIVERY_DRIVER'), contains('Domicilios disponibles'));
    expect(etiquetas('DELIVERY_DRIVER'), isNot(contains('Mis domicilios')));
    expect(etiquetas('EPS'), ['Inicio', 'Pendientes', 'Mi cuenta']);
  });

  test('el destino activo sigue a la ruta, también en pantallas internas', () {
    expect(activo('PATIENT', AppRoutes.home), 'Inicio');
    expect(activo('PATIENT', AppRoutes.myOrders), 'Mis domicilios');
    expect(activo('PATIENT', AppRoutes.tracking('d-1')), 'Mis domicilios');
    expect(activo('PATIENT', AppRoutes.requestDelivery), 'Pedir a casa');
    expect(activo('PATIENT', AppRoutes.pendiente('p-1')), 'Mis pendientes');
    expect(activo('PATIENT', AppRoutes.prescriptionResult), 'Analizar fórmula');
    expect(activo('ADMIN', AppRoutes.adminTracking('d-1')), 'Domicilios pendientes');
    expect(activo('PATIENT', AppRoutes.notifications), isNull);
  });

  test('tocar un destino navega a su ruta', () {
    final visitadas = <String>[];
    final destinos = AppNavigation.lateral(role: 'PATIENT', path: AppRoutes.home, go: visitadas.add);
    destinos.firstWhere((d) => d.etiqueta == 'Mi cuenta').onTap();
    expect(visitadas, [AppRoutes.account]);
  });
}
