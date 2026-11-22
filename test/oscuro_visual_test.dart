import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/app/theme/farmago_tokens.dart';
import 'package:farma_go/auth/auth_controller.dart';
import 'package:farma_go/auth/auth_repository.dart';
import 'package:farma_go/components/farmago/feedback.dart';
import 'package:farma_go/pages/landing_page.dart';
import 'package:farma_go/pages/login_page.dart';
import 'package:farma_go/pages/notifications_page.dart';
import 'package:farma_go/notifications/notification_controller.dart';
import 'package:farma_go/notifications/notification_repository.dart';
import 'package:farma_go/notifications/vigia_domicilios.dart';
import 'package:farma_go/components/farmago/banda_sin_conexion.dart';
import 'package:farma_go/services/estado_conexion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'support/fuentes_reales.dart';
import 'support/home_fakes.dart';

const dir = 'goldens';
/// Capturas del modo oscuro: los mismos tokens con los valores oscuros. El modo claro lo cubren
/// las demás capturas, que no cambian.
void main() {
  setUp(() => FgModo.oscuro = true);
  tearDown(() => FgModo.oscuro = false);
  for (final ancho in [390.0, 1280.0]) {
    testWidgets('paciente domicilio $ancho', (tester) async {
      await montarInicio(tester, role: 'PATIENT', name: 'Ana Gómez', ancho: ancho, foco: focoDomicilio(detalle: entregaDePrueba()));
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('$dir/oscuro_paciente_${ancho.toInt()}.png'));
    });
    testWidgets('pendiente $ancho', (tester) async {
      await montarInicio(tester, role: 'PATIENT', name: 'Ana Gómez', ancho: ancho, foco: focoPendiente());
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('$dir/oscuro_pendiente_${ancho.toInt()}.png'));
    });
    testWidgets('admin $ancho', (tester) async {
      await montarInicio(tester, role: 'ADMIN', name: 'Julian', ancho: ancho, inicioAdmin: InicioAdminFalso());
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('$dir/oscuro_admin_${ancho.toInt()}.png'));
    });
    testWidgets('login $ancho', (tester) async {
      await tester.runAsync(cargarFuentesReales);
      tester.view.physicalSize = Size(ancho, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final auth = AuthController(AuthRepository('https://x', usesBrowserCookies: true, client: MockClient((_) async => http.Response('{}', 200))));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, theme: AppTheme.light,
        builder: (c, child) => FgCapaAvisos(child: child!),
        home: LoginPage(auth: auth, onRegister: () {}, onForgotPassword: () {}, onBack: () {})));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
      avisar('Pedido confirmado', detalle: 'Te avisamos cuando un repartidor lo tome.');
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('$dir/oscuro_login_${ancho.toInt()}.png'));
      await tester.tap(find.byTooltip('Cerrar aviso'));
      await tester.pump();
    });
    testWidgets('landing $ancho', (tester) async {
      await tester.runAsync(cargarFuentesReales);
      tester.view.physicalSize = Size(ancho, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, theme: AppTheme.light, home: LandingPage(onLogin: () {}, onRegister: () {})));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('$dir/oscuro_landing_${ancho.toInt()}.png'));
    });
  }

  testWidgets('notificaciones y banda', (tester) async {
    await tester.runAsync(cargarFuentesReales);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final n = NotificationController(NotificationRepository(persistent: false));
    await n.loadForUser('u');
    await n.addDomicilio(const EventoDomicilio(clave: 'a', titulo: 'Un repartidor tomó tu pedido', mensaje: 'Va a recoger tu pedido de Farmacia 72.', ruta: '/x'));
    await n.addAnalysisCompleted(medicationCount: 2);
    EstadoConexion.instancia.falloDeRed();
    await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, theme: AppTheme.light,
      builder: (c, child) => FgCapaAvisos(child: BandaSinConexion(cada: const Duration(hours: 1), child: child!)),
      home: NotificationsPage(notifications: n, onBack: () {})));
    await tester.pumpAndSettle();
    avisar('Tu pedido va en camino', detalle: 'Síguelo en el mapa hasta tu puerta.', kind: FgToastKind.info);
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('$dir/oscuro_notificaciones.png'));
    await tester.tap(find.byTooltip('Cerrar aviso'));
    EstadoConexion.instancia.reiniciar();
    await tester.pumpWidget(const SizedBox());
  });
}
