import 'dart:convert';
import 'dart:typed_data';

import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/components/delivery_proof.dart';
import 'package:farma_go/components/farmago/buttons.dart';
import 'package:farma_go/components/farmago/feedback.dart';
import 'package:farma_go/components/farmago/inputs.dart';
import 'package:farma_go/components/signature_pad.dart';
import 'package:farma_go/errors/app_error.dart';
import 'package:farma_go/errors/error_mapper.dart';
import 'package:farma_go/errors/error_messages.dart';
import 'package:farma_go/hooks/driver_delivery_controller.dart';
import 'package:farma_go/pages/driver_delivery_page.dart';
import 'package:farma_go/pages/register_delivery_proof_page.dart';
import 'package:farma_go/services/delivery_service.dart';
import 'package:farma_go/services/location_source.dart';
import 'package:farma_go/types/delivery.dart';
import 'package:farma_go/types/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'delivery_test.dart' show clientWith, deliveryJson, patientOrderJson, respond;

/// PNG válido de 1×1, para la foto y la firma de las pruebas.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

Map<String, dynamic> _proofJson({String? receiverName = 'Marta Gómez'}) => {
      'recordedAt': '2026-11-23T15:04:00.000Z',
      'location': {'lat': 4.68, 'lng': -74.06, 'accuracy': 8},
      'distanceToDestinationMeters': 35,
      if (receiverName != null) 'receiverName': receiverName,
    };

Map<String, dynamic> _delivered() => {...deliveryJson(status: 'DELIVERED'), 'proof': _proofJson()};

Map<String, dynamic> _codeError(String code) => {
      'success': false,
      'error': {'code': code, 'message': 'internal english text'},
    };

class _Gps implements LocationSource {
  _Gps({this.accuracy = 8, this.notReady});

  final double accuracy;
  final AppError? notReady;

  @override
  Future<void> ensureReady() async {
    if (notReady != null) throw notReady!;
  }

  @override
  Future<GpsFix> currentFix() async =>
      GpsFix(point: const GeoPoint(4.6801, -74.0601), accuracy: accuracy, recordedAt: DateTime.now().toUtc());
}

DeliveryProofDraft _draft({String? name = 'Marta Gómez'}) =>
    DeliveryProofDraft(photo: _png, photoContentType: 'image/png', signaturePng: _png, receiverName: name);

Widget _app(Widget home) => MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => FgCapaAvisos(child: child!),
      home: home,
    );

void _pantalla(WidgetTester tester, [Size size = const Size(420, 2400)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Deja avanzar lo que necesita el motor de verdad (exportar la firma, decodificar imágenes).
Future<void> _red(WidgetTester tester, {int vueltas = 1}) async {
  for (var i = 0; i < vueltas; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump();
  }
}

FgButton _boton(WidgetTester tester, String label) => tester.widget<FgButton>(find.widgetWithText(FgButton, label));

DriverDeliveryController _controller(DeliveryService service, LocationSource gps) => DriverDeliveryController(
      deliveryId: 'd-1',
      deliveries: service,
      location: gps,
      interval: const Duration(hours: 1),
    );

void main() {
  group('errores de la prueba de entrega', () {
    test('cada código nuevo tiene su frase en español y nunca el texto del servidor', () {
      final casos = {
        'PROOF_INVALID': (400, ErrorMessages.proofInvalid),
        'PROOF_LOCATION_INVALID': (422, ErrorMessages.proofLocationInvalid),
        'PROOF_TOO_FAR': (422, ErrorMessages.proofTooFar),
        'PROOF_NOT_FOUND': (404, ErrorMessages.proofNotFound),
        'PAYLOAD_TOO_LARGE': (413, ErrorMessages.payloadTooLarge),
      };
      casos.forEach((code, caso) {
        final error = ErrorMapper.fromDelivery(caso.$1, _codeError(code));
        expect(error.userMessage, caso.$2, reason: code);
        expect(error.userMessage, isNot(contains('internal')), reason: code);
        expect(error.code, code);
      });
      expect(ErrorMessages.proofTooFar, 'Estás lejos de la dirección de entrega. Acércate y vuelve a intentarlo.');
      // Un 413 del proxy, sin cuerpo JSON, también dice qué hacer.
      expect(ErrorMapper.fromDelivery(413, const {}).userMessage, ErrorMessages.payloadTooLarge);
    });

    test('cerrar sin prueba ni código explica las dos formas de hacerlo', () {
      final error = ErrorMapper.fromDelivery(409, _codeError('CODE_CONFIRMATION_REQUIRED'));
      expect(error.userMessage, ErrorMessages.codeConfirmationRequired);
      expect(error.userMessage, allOf(contains('foto'), contains('firma'), contains('código')));
    });

    test('los problemas del GPS se explican para registrar la entrega', () {
      AppError gps(String message) =>
          AppError(kind: AppErrorKind.forbidden, userMessage: message, retryable: false, code: 'LOCATION_UNAVAILABLE');
      expect(ErrorMapper.forProofLocation(gps(ErrorMessages.locationPermission)).userMessage,
          ErrorMessages.proofLocationPermission);
      expect(ErrorMapper.forProofLocation(gps(ErrorMessages.locationDisabled)).userMessage,
          ErrorMessages.proofLocationDisabled);
      final sinSenal = ErrorMapper.forProofLocation(gps(ErrorMessages.locationUnavailable));
      expect(sinSenal.userMessage, ErrorMessages.proofLocationUnavailable);
      expect(sinSenal.retryable, isTrue);
    });
  });

  group('SignaturePad', () {
    testWidgets('«Borrar» se habilita al dibujar y vuelve a dejar el panel vacío', (tester) async {
      final firma = SignaturePadController();
      addTearDown(firma.dispose);
      await tester.pumpWidget(_app(Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: SignaturePad(controller: firma)),
      )));
      expect(find.text('Firma de quien recibe'), findsOneWidget); // etiqueta visible
      expect(_boton(tester, 'Borrar').onPressed, isNull);
      expect(firma.isEmpty, isTrue);

      await tester.dragFrom(tester.getCenter(find.text('Firma aquí')), const Offset(120, 30));
      await tester.pump();
      expect(firma.isNotEmpty, isTrue);
      expect(_boton(tester, 'Borrar').onPressed, isNotNull);
      expect(find.text('Firma aquí'), findsNothing);

      await tester.tap(find.text('Borrar'));
      await tester.pump();
      expect(firma.isEmpty, isTrue);
      expect(_boton(tester, 'Borrar').onPressed, isNull);
    });

    testWidgets('firmar dentro de una lista no la desplaza', (tester) async {
      _pantalla(tester, const Size(360, 640));
      final firma = SignaturePadController();
      final scroll = ScrollController();
      addTearDown(firma.dispose);
      addTearDown(scroll.dispose);
      await tester.pumpWidget(_app(Scaffold(
        body: ListView(controller: scroll, children: [
          const SizedBox(height: 120),
          SignaturePad(controller: firma),
          const SizedBox(height: 2000),
        ]),
      )));
      await tester.dragFrom(tester.getCenter(find.text('Firma aquí')), const Offset(10, -90));
      await tester.pump();
      expect(scroll.offset, 0);
      expect(firma.isNotEmpty, isTrue);
    });

    testWidgets('exporta la firma como PNG liviano', (tester) async {
      final firma = SignaturePadController();
      addTearDown(firma.dispose);
      await tester.pumpWidget(_app(Scaffold(body: SignaturePad(controller: firma))));
      expect(await tester.runAsync(firma.toPng), isNull); // vacía: no hay nada que enviar
      await tester.dragFrom(tester.getCenter(find.text('Firma aquí')), const Offset(150, 40));
      await tester.pump();
      final png = await tester.runAsync(firma.toPng);
      expect(png, isNotNull);
      expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      expect(png.lengthInBytes, lessThan(RegisterDeliveryProofPage.maxSignatureBytes));
    });
  });

  group('DriverDeliveryController.registerProof', () {
    test('envía foto, firma y ubicación en multipart y la entrega queda cerrada', () async {
      http.Request? enviada;
      final service = DeliveryService(clientWith((request) async {
        if (request.url.path == '/deliveries/d-1/proof') {
          enviada = request;
          return respond(_delivered(), 200);
        }
        if (request.url.path.endsWith('/locations')) {
          return respond({'accepted': true, 'reason': null, 'status': 'IN_TRANSIT', 'eta': null}, 200);
        }
        return respond({...deliveryJson(status: 'IN_TRANSIT'), 'deliveryCode': '482913'}, 200);
      }));
      final controller = _controller(service, _Gps());
      await controller.start();
      expect(controller.canRegisterProof, isTrue);
      expect(controller.sharing, isTrue);

      expect(await controller.registerProof(_draft()), isNull);
      final request = enviada!;
      expect(request.method, 'POST');
      expect(request.headers['content-type'], startsWith('multipart/form-data'));
      expect(request.headers['authorization'], startsWith('Bearer '));
      final body = utf8.decode(request.bodyBytes, allowMalformed: true);
      for (final parte in [
        'name="photo"',
        'filename="entrega.png"',
        'name="signature"',
        'filename="firma.png"',
        'name="lat"',
        '4.6801',
        'name="lng"',
        'name="accuracy"',
        'name="recordedAt"',
        'name="receiverName"',
        'Marta Gómez',
      ]) {
        expect(body, contains(parte));
      }
      expect(controller.delivery?.status, DeliveryStatus.delivered);
      expect(controller.delivery?.proof?.receiverName, 'Marta Gómez');
      expect(controller.delivery?.proof?.distanceToDestinationMeters, 35);
      expect(controller.sharing, isFalse); // entregado: deja de compartir la ubicación
      expect(controller.registeringProof, isFalse);
      controller.dispose();
    });

    test('lejos de la dirección: explica qué hacer y la entrega sigue abierta', () async {
      final service = DeliveryService(clientWith((request) async {
        if (request.url.path == '/deliveries/d-1/proof') return respond(_codeError('PROOF_TOO_FAR'), 422);
        if (request.url.path.endsWith('/locations')) {
          return respond({'accepted': true, 'reason': null, 'status': 'ARRIVING', 'eta': null}, 200);
        }
        return respond(deliveryJson(status: 'ARRIVING'), 200);
      }));
      final controller = _controller(service, _Gps());
      await controller.start();
      final error = await controller.registerProof(_draft(name: null));
      expect(error?.userMessage, ErrorMessages.proofTooFar);
      expect(error?.retryable, isTrue);
      expect(controller.delivery?.status, DeliveryStatus.arriving);
      expect(controller.sharing, isTrue);
      controller.dispose();
    });

    test('sin permiso de ubicación o con una ubicación imprecisa no sube nada', () async {
      var subidas = 0;
      final service = DeliveryService(clientWith((request) async {
        if (request.url.path == '/deliveries/d-1/proof') subidas++;
        return respond(deliveryJson(status: 'IN_TRANSIT'), 200);
      }));
      final sinPermiso = _controller(
        service,
        _Gps(
          notReady: AppError(
            kind: AppErrorKind.forbidden,
            userMessage: ErrorMessages.locationPermission,
            retryable: false,
            code: 'LOCATION_UNAVAILABLE',
          ),
        ),
      );
      await sinPermiso.start();
      expect((await sinPermiso.registerProof(_draft()))?.userMessage, ErrorMessages.proofLocationPermission);
      sinPermiso.dispose();

      final impreciso = _controller(service, _Gps(accuracy: 250));
      await impreciso.start();
      final error = await impreciso.registerProof(_draft());
      expect(error?.code, 'PROOF_LOCATION_INVALID');
      expect(error?.userMessage, ErrorMessages.proofLocationInvalid);
      impreciso.dispose();
      expect(subidas, 0);
    });
  });

  group('Registrar entrega (pantallas)', () {
    testWidgets('el repartidor toma la foto, recoge la firma, confirma y ve la prueba', (tester) async {
      _pantalla(tester);
      var estado = 'IN_TRANSIT';
      var subidas = 0;
      final imagenes = <String>[];
      final deliveries = DeliveryService(clientWith((request) async {
        final path = request.url.path;
        if (path == '/deliveries/d-1/proof') {
          subidas++;
          estado = 'DELIVERED';
          return respond(_delivered(), 200);
        }
        if (path.startsWith('/deliveries/d-1/proof/')) {
          imagenes.add(path.split('/').last);
          return http.Response.bytes(_png, 200, headers: {'content-type': 'image/png'});
        }
        if (path.endsWith('/locations')) {
          return respond({'accepted': true, 'reason': null, 'status': estado, 'eta': null}, 200);
        }
        return respond(estado == 'DELIVERED' ? _delivered() : {...deliveryJson(status: estado), 'deliveryCode': '482913'}, 200);
      }));
      final pedido = DriverOrder.fromJson({...patientOrderJson(status: 'TAKEN'), 'deliveryId': 'd-1'});
      await tester.pumpWidget(_app(DriverDeliveryPage(
        order: pedido,
        onBack: () {},
        createController: (id) => DriverDeliveryController(
          deliveryId: id,
          deliveries: deliveries,
          location: _Gps(),
          interval: const Duration(hours: 1),
        ),
        takeProofPhoto: (_) async => XFile.fromData(_png, name: 'entrega.png', mimeType: 'image/png'),
      )));
      await _red(tester);

      // Acción principal y, como alternativa, el código para el paciente.
      expect(find.text('Código de entrega'), findsOneWidget);
      await tester.ensureVisible(find.widgetWithText(FgButton, 'Registrar entrega'));
      await tester.tap(find.widgetWithText(FgButton, 'Registrar entrega'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(RegisterDeliveryProofPage), findsOneWidget);

      // Sin foto ni firma no se puede confirmar, y la pantalla dice por qué.
      expect(_boton(tester, 'Confirmar entrega').onPressed, isNull);
      expect(find.text('Para confirmar, faltan la foto y la firma.'), findsOneWidget);

      await tester.tap(find.text('Tomar la foto'));
      await _red(tester);
      expect(find.text('Repetir la foto'), findsOneWidget);
      expect(find.text('Para confirmar, falta la firma.'), findsOneWidget);

      await tester.ensureVisible(find.text('Firma aquí'));
      await tester.dragFrom(tester.getCenter(find.text('Firma aquí')), const Offset(100, 20));
      await tester.pump();
      expect(_boton(tester, 'Confirmar entrega').onPressed, isNotNull);

      await tester.enterText(
        find.descendant(of: find.byType(FgTextField), matching: find.byType(TextField)),
        'Marta Gómez',
      );
      await tester.tap(find.text('Confirmar entrega'));
      await _red(tester, vueltas: 8);
      await tester.pump(const Duration(milliseconds: 500));

      expect(subidas, 1);
      expect(find.byType(RegisterDeliveryProofPage), findsNothing);
      expect(find.text('Entrega registrada'), findsOneWidget);
      expect(find.text('Entrega confirmada'), findsNothing); // no se atribuye al código del paciente
      expect(find.text('Registraste la entrega con foto, firma y ubicación.'), findsOneWidget);
      expect(find.text('Prueba de entrega'), findsOneWidget);
      expect(find.text('Recibió: Marta Gómez'), findsOneWidget);
      await _red(tester, vueltas: 3);
      expect(imagenes, containsAll(['photo', 'signature']));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('si el servidor la rechaza, se explica y se conserva lo hecho', (tester) async {
      _pantalla(tester);
      var intentos = 0;
      await tester.pumpWidget(_app(RegisterDeliveryProofPage(
        address: 'Calle 92 # 15-30',
        takePhoto: (_) async => XFile.fromData(_png, name: 'entrega.png', mimeType: 'image/png'),
        onSubmit: (draft) async {
          intentos++;
          expect(draft.receiverName, isNull);
          expect(draft.photoContentType, 'image/png');
          return ErrorMapper.fromDelivery(422, _codeError('PROOF_TOO_FAR'));
        },
      )));
      expect(find.text('Calle 92 # 15-30'), findsOneWidget);
      await tester.tap(find.text('Tomar la foto'));
      await _red(tester);
      await tester.ensureVisible(find.text('Firma aquí'));
      await tester.dragFrom(tester.getCenter(find.text('Firma aquí')), const Offset(90, 25));
      await tester.pump();
      await tester.tap(find.text('Confirmar entrega'));
      await _red(tester, vueltas: 6);

      expect(intentos, 1);
      expect(find.text(ErrorMessages.proofTooFar), findsOneWidget);
      expect(find.textContaining('internal'), findsNothing);
      expect(find.text('Repetir la foto'), findsOneWidget); // la foto sigue
      expect(_boton(tester, 'Borrar').onPressed, isNotNull); // la firma sigue
      expect(_boton(tester, 'Confirmar entrega').onPressed, isNotNull); // se puede reintentar
    });

    testWidgets('la prueba muestra quién recibió y cada imagen con su error y reintento', (tester) async {
      _pantalla(tester, const Size(360, 1400));
      var intentosFoto = 0;
      await tester.pumpWidget(_app(Scaffold(
        body: SingleChildScrollView(
          child: DeliveryProofSection(
            proof: DeliveryProof.fromJson(_proofJson())!,
            loadImage: (imagen) async {
              if (imagen == DeliveryProofImage.photo && intentosFoto++ == 0) {
                throw AppError(kind: AppErrorKind.network, userMessage: ErrorMessages.network, retryable: true);
              }
              return _png;
            },
          ),
        ),
      )));
      await _red(tester);
      expect(find.text('Prueba de entrega'), findsOneWidget);
      expect(find.text('Recibió: Marta Gómez'), findsOneWidget);
      expect(find.text('Registrada el 23 nov 2026, 10:04 a. m.'), findsOneWidget);
      expect(find.text('A 35 m de la dirección de entrega'), findsOneWidget);
      // La foto falló, la firma no: el error queda en su sección.
      expect(find.text(ErrorMessages.network), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await _red(tester, vueltas: 2);
      expect(intentosFoto, 2);
      expect(find.text(ErrorMessages.network), findsNothing);
      expect(find.byType(Image), findsNWidgets(2));
    });

    test('cerrada con el código no trae prueba que mostrar', () {
      expect(Delivery.fromJson(deliveryJson(status: 'DELIVERED')).proof, isNull);
      expect(Delivery.fromJson(_delivered()).proof, isNotNull);
      expect(DeliveryStatus.inTransit.driverHint, contains('Registrar entrega'));
      expect(DeliveryStatus.arriving.patientHint, contains('código'));
    });
  });
}
