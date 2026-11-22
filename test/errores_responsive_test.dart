import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/auth/auth_controller.dart';
import 'package:farma_go/auth/auth_repository.dart';
import 'package:farma_go/auth/google_mobile_sign_in.dart';
import 'package:farma_go/components/farmago/feedback.dart';
import 'package:farma_go/errors/app_error.dart';
import 'package:farma_go/errors/error_mapper.dart';
import 'package:farma_go/errors/error_messages.dart';
import 'package:farma_go/pages/login_page.dart';
import 'package:farma_go/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Pantallas de celular pequeñas, con y sin texto agrandado (accesibilidad).
const _pantallas = [(Size(320, 568), 1.0), (Size(320, 568), 1.6), (Size(375, 667), 1.3)];

void _pantalla(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget child, double escala) => MaterialApp(
      theme: AppTheme.light,
      builder: (context, c) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(escala)), child: c!),
      home: child,
    );

AuthController _auth() => AuthController(AuthRepository('https://auth.example',
    usesBrowserCookies: true, client: MockClient((_) async => http.Response('{}', 200))));

const _largo = 'No pudimos conectarnos con el servicio de autenticación porque la red respondió con un error '
    'inesperado. Revisa tu conexión a internet e inténtalo de nuevo en unos minutos; si sigue pasando, '
    'escríbenos con el código de referencia.';

void main() {
  group('la sesión de la web va por el mismo dominio', () {
    test('en la web con AUTH_SAME_ORIGIN usa el origen de la página', () {
      expect(
        AppConfig.sessionAuthFor(
            isWeb: true,
            sameOrigin: true,
            pageUri: Uri.parse('https://farmago-eta.vercel.app/auth/callback#c=1'),
            fallback: 'https://gw'),
        'https://farmago-eta.vercel.app',
      );
    });

    test('en la app, sin la bandera o fuera de http usa el gateway', () {
      expect(AppConfig.sessionAuthFor(isWeb: false, sameOrigin: true, fallback: 'https://gw'), 'https://gw');
      expect(
        AppConfig.sessionAuthFor(
            isWeb: true, sameOrigin: false, pageUri: Uri.parse('https://x.app'), fallback: 'https://gw'),
        'https://gw',
      );
      expect(
        AppConfig.sessionAuthFor(
            isWeb: true, sameOrigin: true, pageUri: Uri.parse('file:///a'), fallback: 'https://gw'),
        'https://gw',
      );
    });
  });

  group('los mensajes de error no dañan el diseño en pantallas pequeñas', () {
    for (final (size, escala) in _pantallas) {
      final nombre = '${size.width.toInt()}x${size.height.toInt()} texto ×$escala';

      testWidgets('login con el error de Google de la web ($nombre)', (tester) async {
        _pantalla(tester, size);
        final auth = _auth()
          ..showNotice(AppError(
            kind: AppErrorKind.unauthorized,
            userMessage: ErrorMapper.googleRedirectMessage('oauth_state_invalid'),
            retryable: true,
            code: 'oauth_state_invalid',
          ));
        await tester
            .pumpWidget(_app(LoginPage(auth: auth, onRegister: () {}, onForgotPassword: () {}, onBack: () {}), escala));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text(ErrorMessages.googleState), findsOneWidget);
        // El aviso cabe en el ancho de la pantalla.
        final caja = tester.getRect(find.byType(FgBanner));
        expect(caja.left, greaterThanOrEqualTo(0));
        expect(caja.right, lessThanOrEqualTo(size.width));
        auth.dispose();
      });

      testWidgets('login con el error de Google del celular ($nombre)', (tester) async {
        _pantalla(tester, size);
        final auth = _auth();
        await tester.pumpWidget(_app(
            LoginPage(
              auth: auth,
              onRegister: () {},
              onForgotPassword: () {},
              onBack: () {},
              googleMobile: () async => const GoogleCallback.error('google_account_conflict'),
            ),
            escala));
        await tester.ensureVisible(find.text('Continuar con Google'));
        await tester.tap(find.text('Continuar con Google'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(ErrorMessages.googleConflict), findsOneWidget);
        auth.dispose();
      });

      testWidgets('aviso largo con código de referencia y acción ($nombre)', (tester) async {
        _pantalla(tester, size);
        await tester.pumpWidget(_app(
          Scaffold(
            body: SafeArea(
              child: ListView(padding: const EdgeInsets.all(16), children: [
                ErrorBanner(
                  error: AppError(
                    kind: AppErrorKind.server,
                    userMessage: _largo,
                    retryable: true,
                    referenceId: 'REF-7F3A9C21-0B44-4D2E-9A61-ABCDEF123456',
                  ),
                ),
                FgBanner(
                  kind: FgBannerKind.aviso,
                  title: 'Tu sesión terminó por seguridad después de un tiempo sin actividad',
                  message: _largo,
                  actionLabel: 'Volver a intentarlo ahora',
                  onAction: () {},
                ),
              ]),
            ),
          ),
          escala,
        ));
        expect(tester.takeException(), isNull);
        for (final banner in tester.widgetList(find.byType(FgBanner))) {
          final r = tester.getRect(find.byWidget(banner));
          expect(r.right, lessThanOrEqualTo(size.width));
        }
      });

      testWidgets('pantalla de error completa ($nombre)', (tester) async {
        _pantalla(tester, size);
        await tester.pumpWidget(_app(
          Scaffold(
            body: ErrorStateView(
              title: 'No pudimos cargar tus pedidos de domicilio',
              error: AppError(kind: AppErrorKind.server, userMessage: _largo, retryable: true, referenceId: 'REF-1234'),
              primaryLabel: 'Reintentar',
              onPrimary: () {},
              secondaryLabel: 'Volver al inicio',
              onSecondary: () {},
            ),
          ),
          escala,
        ));
        expect(tester.takeException(), isNull);
      });

      testWidgets('aviso flotante de error, también con el teclado abierto ($nombre)', (tester) async {
        _pantalla(tester, size);
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpWidget(_app(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child:
                    TextButton(onPressed: () => showAppSnackBar(context, _largo, error: true), child: const Text('x')),
              ),
            ),
          ),
          escala,
        ));
        await tester.tap(find.text('x'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final aviso = tester.getRect(find.ancestor(of: find.text(_largo), matching: find.byType(Material)).first);
        expect(aviso.right, lessThanOrEqualTo(size.width));
        // Queda entre el borde de arriba y el teclado (260 px), y el botón de cerrar se puede tocar.
        expect(aviso.top, greaterThanOrEqualTo(0));
        expect(aviso.bottom, lessThanOrEqualTo(size.height - 260));
        final cerrar = tester.getRect(find.byTooltip('Cerrar aviso'));
        expect(cerrar.top, greaterThanOrEqualTo(aviso.top));
        expect(cerrar.bottom, lessThanOrEqualTo(aviso.bottom));
        await tester.tap(find.byTooltip('Cerrar aviso'));
        await tester.pump();
      });
    }
  });
}
