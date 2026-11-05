import 'package:farma_go/components/farmago/buttons.dart';
import 'package:farma_go/hooks/patient_home_controller.dart';
import 'package:farma_go/types/delivery.dart';
import 'package:farma_go/types/order.dart';
import 'package:farma_go/types/pendiente.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/home_fakes.dart';

PendienteResumen _pendiente(String id, String cumplimiento, String fechaLimite) => PendienteResumen.fromJson({
      'id': id,
      'ordenMedicamentoId': 'om-$id',
      'pacienteId': 'pac-1',
      'epsUserId': 'eps-1',
      'dispensarioId': 'disp-1',
      'fechaEvento': '2026-10-31T12:00:00Z',
      'fechaRegistro': '2026-10-31T12:00:00Z',
      'fechaLimite': fechaLimite,
      'estadoEntrega': 'PENDIENTE',
      'fechaEntrega': null,
      'cumplimientoPlazo': cumplimiento,
      'evaluadoEn': '2026-11-01T12:00:00Z',
      'medicamentosTotal': 1,
      'medicamentosEntregados': 0,
      'cantidadNovedades': 0,
    });

PatientOrder _pedido(String id, {OrderStatus estado = OrderStatus.taken, DateTime? creado}) => PatientOrder(
      id: id,
      status: estado,
      pharmacy: const Pharmacy(name: 'F', address: 'A'),
      deliveryAddress: 'Entrega',
      items: const [],
      notes: null,
      deliveryId: 'd-$id',
      routeSummary: const RouteSummary(distanceMeters: 0, durationSeconds: 0),
      driverAssigned: true,
      createdAt: creado,
    );

void main() {
  group('elegirFoco (regla pura, sin red)', () {
    test('un domicilio en curso tiene prioridad sobre cualquier pendiente', () {
      final pedido = _pedido('1', creado: DateTime.utc(2026, 11, 1));
      final foco = elegirFoco(
        pedidos: [pedido],
        estadoDe: (_) => DeliveryStatus.inTransit,
        pendientes: [_pendiente('a', 'VIGENTE', '2026-11-02T12:00:00Z')],
      );
      expect(foco, isA<FocoDomicilio>());
      expect((foco as FocoDomicilio).estado, DeliveryStatus.inTransit);
    });

    test('entregas terminales, pedidos cancelados y estados desconocidos no cuentan como activos', () {
      final entregado = _pedido('1', creado: DateTime.utc(2026, 11, 1));
      final cancelado = _pedido('2', estado: OrderStatus.cancelled, creado: DateTime.utc(2026, 11, 1));
      final desconocido = _pedido('3', creado: DateTime.utc(2026, 11, 1));
      final foco = elegirFoco(
        pedidos: [entregado, cancelado, desconocido],
        estadoDe: (p) => switch (p.id) {
          '1' => DeliveryStatus.delivered,
          '2' => DeliveryStatus.inTransit,
          _ => DeliveryStatus.unknown,
        },
        pendientes: [_pendiente('a', 'VIGENTE', '2026-11-02T12:00:00Z')],
      );
      expect(foco, isA<FocoPendiente>());
    });

    test('entre varios domicilios en curso gana el más reciente', () {
      final viejo = _pedido('viejo', creado: DateTime.utc(2026, 10, 30));
      final nuevo = _pedido('nuevo', creado: DateTime.utc(2026, 11, 1));
      final foco = elegirFoco(
        pedidos: [viejo, nuevo],
        estadoDe: (_) => DeliveryStatus.assigned,
        pendientes: const [],
      );
      expect((foco as FocoDomicilio).pedido.id, 'nuevo');
    });

    test('sin domicilio activo, el pendiente vigente con la fecha límite más cercana', () {
      final lejano = _pendiente('lejano', 'VIGENTE', '2026-11-05T12:00:00Z');
      final cercano = _pendiente('cercano', 'VIGENTE', '2026-11-02T12:00:00Z');
      final cumplido = _pendiente('cumplido', 'CUMPLIDO', '2026-10-30T12:00:00Z');
      final foco = elegirFoco(pedidos: const [], estadoDe: (_) => null, pendientes: [lejano, cumplido, cercano]);
      expect((foco as FocoPendiente).pendiente.id, 'cercano');
    });

    test('si no hay pendientes vigentes, muestra el más reciente que entrega el backend', () {
      final primero = _pendiente('reciente', 'CUMPLIDO', '2026-10-30T12:00:00Z');
      final segundo = _pendiente('anterior', 'INCUMPLIDO', '2026-10-20T12:00:00Z');
      final foco = elegirFoco(pedidos: const [], estadoDe: (_) => null, pendientes: [primero, segundo]);
      expect((foco as FocoPendiente).pendiente.id, 'reciente');
    });

    test('sin domicilios ni pendientes, el foco es vacío', () {
      final foco = elegirFoco(pedidos: const [], estadoDe: (_) => null, pendientes: const []);
      expect(foco, isA<FocoVacio>());
    });
  });

  group('inicio del paciente en pantalla', () {
    testWidgets('domicilio en curso: estado, trayecto y acceso al seguimiento', (tester) async {
      String? entregaAbierta;
      await montarInicio(
        tester,
        role: 'PATIENT',
        name: 'Ana Gómez',
        ancho: 1280,
        foco: focoDomicilio(detalle: entregaDePrueba()),
        onTracking: (id) => entregaAbierta = id,
      );
      expect(find.text('En camino'), findsWidgets);
      expect(find.text('Llegada estimada'), findsOneWidget);
      expect(find.text('Completado'), findsNWidgets(3));
      await tester.tap(find.text('Ver seguimiento'));
      expect(entregaAbierta, 'd-1');
    });

    testWidgets('pendiente vigente: plazo, medicamentos y acceso al detalle', (tester) async {
      String? pendienteAbierto;
      await montarInicio(
        tester,
        role: 'PATIENT',
        name: 'Ana Gómez',
        ancho: 1280,
        foco: focoPendiente(),
        onPendienteDetalle: (id) => pendienteAbierto = id,
      );
      expect(find.text('1 de 2 medicamentos entregados'), findsOneWidget);
      expect(find.text('Vigente'), findsOneWidget);
      await tester.tap(find.text('Ver pendiente'));
      expect(pendienteAbierto, 'pend-1');
    });

    testWidgets('sin actividad: estado vacío con la acción concreta', (tester) async {
      var analizar = 0;
      await montarInicio(
        tester,
        role: 'PATIENT',
        name: 'Ana Gómez',
        ancho: 360,
        foco: const FocoVacio(),
        onAnalyze: () => analizar++,
      );
      expect(find.text('No tienes domicilios ni pendientes activos.'), findsOneWidget);
      expect(find.text('Cuando pidas un domicilio o se registre un pendiente, lo verás aquí.'), findsOneWidget);
      await tester.tap(find.widgetWithText(FgButton, 'Analizar fórmula').first);
      expect(analizar, 1);
    });
  });

  group('navegación del shell', () {
    testWidgets('en escritorio la barra lateral tiene 264 px y los destinos reales del paciente', (tester) async {

      await montarInicio(tester, role: 'PATIENT', name: 'Ana', ancho: 1280, foco: const FocoVacio());
      final lateral = find.byKey(const ValueKey('navegacion-lateral'));
      expect(tester.getSize(lateral).width, 264);
      expect(find.text('Mis domicilios'), findsOneWidget);
      expect(find.text('Mis pendientes'), findsWidgets);

    });

    testWidgets('en escritorio, un destino de la barra lateral abre su pantalla', (tester) async {
      var abiertos = 0;
      await montarInicio(
        tester,
        role: 'PATIENT',
        name: 'Ana',
        ancho: 1280,
        foco: const FocoVacio(),
        onMyOrders: () => abiertos++,
      );
      await tester.tap(find.text('Mis domicilios'));
      expect(abiertos, 1);
    });

    testWidgets('en móvil no hay barra lateral y la barra inferior tiene el destino de domicilios', (tester) async {
      var abiertos = 0;
      await montarInicio(
        tester,
        role: 'PATIENT',
        name: 'Ana',
        ancho: 360,
        foco: const FocoVacio(),
        onMyOrders: () => abiertos++,
      );
      expect(find.text('Mis domicilios'), findsNothing);
      await tester.tap(find.text('Domicilios'));
      expect(abiertos, 1);
    });
  });
}
