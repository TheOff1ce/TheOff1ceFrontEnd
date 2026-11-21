import 'dart:convert';

import 'package:farma_go/hooks/admin_inicio_controller.dart';
import 'package:farma_go/services/admin_service.dart';
import 'package:farma_go/services/delivery_service.dart';
import 'package:farma_go/types/delivery.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'delivery_test.dart' show clientWith, deliveryJson, respond;
import 'support/home_fakes.dart';

/// Inicio del administrador: tablero de la operación (domicilios, semana, espera, calificaciones).
void main() {
  final ahora = DateTime(2026, 11, 21, 16);

  Map<String, dynamic> entrega(String id, String estado, DateTime desde) => {
        ...deliveryJson(status: estado),
        'id': id,
        'statusTimestamps': {estado: desde.toUtc().toIso8601String()},
      };

  group('operación de hoy', () {
    test('cuenta por estado, ordena la espera y arma los 7 días', () {
      final o = OperacionHoy.de([
        for (final m in [
          entrega('a', 'CREATED', ahora.subtract(const Duration(minutes: 5))),
          entrega('b', 'CREATED', ahora.subtract(const Duration(minutes: 40))),
          entrega('c', 'IN_TRANSIT', ahora),
          entrega('d', 'ASSIGNED', ahora),
          entrega('e', 'DELIVERED', ahora.subtract(const Duration(hours: 1))),
          entrega('f', 'DELIVERED', ahora.subtract(const Duration(days: 2))),
          entrega('g', 'FAILED', ahora.subtract(const Duration(hours: 2))),
          entrega('h', 'CANCELLED', ahora.subtract(const Duration(days: 9))),
        ])
          Delivery.fromJson(m),
      ], ahora);
      expect(o.buscandoRepartidor, 2);
      expect(o.esperando.map((d) => d.id), ['b', 'a']);
      expect(o.enCamino, 2);
      expect(o.entregadosHoy, 1);
      expect(o.noEntregadosHoy, 1);
      expect(o.semana, hasLength(7));
      expect(o.semana.last.entregados, 1);
      expect(o.semana.last.noEntregados, 1);
      expect(o.semana[4].entregados, 1); // hace 2 días
      expect(o.entregadosSemana, 2);
      expect(o.noEntregadosSemana, 1); // la cancelada hace 9 días no entra
      expect(o.efectividadSemana, 67);
    });

    test('sin entregas no inventa porcentajes', () {
      final o = OperacionHoy.de(const [], ahora);
      expect(o.efectividadSemana, isNull);
      expect(o.semana.every((d) => d.total == 0), isTrue);
    });
  });

  test('si un servicio falla, los demás bloques igual cargan', () async {
    final c = AdminInicioController(
      now: () => ahora,
      deliveries: DeliveryService(clientWith((request) async {
        if (request.url.path.endsWith('/ratings')) return respond({'message': 'x'}, 503);
        return respond({
          'deliveries': [entrega('a', 'CREATED', ahora)],
        }, 200);
      })),
      admin: AdminService(
        auth: clientWith((request) async => http.Response(
            jsonEncode({
              'users': [],
              'total': request.url.queryParameters['role'] == 'DELIVERY_DRIVER' ? 4 : 30,
              'page': 1,
              'pageSize': 20,
            }),
            200)),
        orders: clientWith((_) async => respond({}, 200)),
      ),
    );
    await c.load();
    expect(c.operacion?.buscandoRepartidor, 1);
    expect(c.calificaciones, isNull);
    expect(c.errorCalificaciones, isNotNull);
    expect(c.usuarios?.total, 30);
    expect(c.usuarios?.repartidores, 4);
    expect(c.loading, isFalse);
  });

  testWidgets('el inicio muestra el tablero, sin repetir la barra ni «Mi cuenta»', (tester) async {
    final abiertas = <String>[];
    await montarInicio(
      tester,
      role: 'ADMIN',
      name: 'Carlos Ruiz',
      ancho: 1280,
      altura: 1500,
      inicioAdmin: InicioAdminFalso(),
      onAdminTracking: abiertas.add,
    );
    expect(find.text('Domicilios ahora'), findsOneWidget);
    expect(find.text('Últimos 7 días'), findsOneWidget);
    expect(find.text('Esperan repartidor'), findsOneWidget);
    expect(find.text('Calificaciones de la semana'), findsOneWidget);
    expect(find.text('Usuarios'), findsOneWidget);
    expect(find.text('Tus datos, tu contraseña y cerrar sesión.'), findsNothing);
    expect(find.text('Busca personas, corrige documentos y cambia roles.'), findsNothing);
    // El que más espera va primero y abre su seguimiento.
    expect(find.text('42 min'), findsOneWidget);
    await tester.tap(find.text('42 min'));
    expect(abiertas, ['e1']);
  });
}
