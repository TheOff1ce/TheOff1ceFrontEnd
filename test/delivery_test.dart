import 'dart:async';
import 'dart:convert';

import 'package:farma_go/errors/app_error.dart';
import 'package:farma_go/errors/error_mapper.dart';
import 'package:farma_go/errors/error_messages.dart';
import 'package:farma_go/hooks/driver_board_controller.dart';
import 'package:farma_go/hooks/driver_delivery_controller.dart';
import 'package:farma_go/hooks/patient_orders_controller.dart';
import 'package:farma_go/hooks/tracking_controller.dart';
import 'package:farma_go/services/access_token_source.dart';
import 'package:farma_go/services/authorized_json_client.dart';
import 'package:farma_go/services/delivery_service.dart';
import 'package:farma_go/services/location_source.dart';
import 'package:farma_go/services/order_service.dart';
import 'package:farma_go/services/tracking_channel.dart';
import 'package:farma_go/types/delivery.dart';
import 'package:farma_go/types/order.dart';
import 'package:farma_go/utils/delivery_format.dart';
import 'package:farma_go/utils/polyline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeTokens implements AccessTokenSource {
  int refreshes = 0;
  String token = 'token-1';

  @override
  Future<String?> currentAccessToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      refreshes++;
      token = 'token-${refreshes + 1}';
    }
    return token;
  }
}

class FakeChannel implements TrackingChannel {
  final controller = StreamController<TrackingEvent>.broadcast();
  String? watching;
  bool closed = false;

  @override
  Stream<TrackingEvent> get events => controller.stream;

  @override
  void watch(String deliveryId) => watching = deliveryId;

  @override
  void close() => closed = true;
}

class FakeLocation implements LocationSource {
  AppError? notReady;
  int fixes = 0;

  @override
  Future<void> ensureReady() async {
    if (notReady != null) throw notReady!;
  }

  @override
  Future<GpsFix> currentFix() async {
    fixes++;
    return GpsFix(point: const GeoPoint(4.665, -74.06), accuracy: 8, recordedAt: DateTime.now(), heading: 90, speed: -1);
  }
}

http.Response respond(Object body, int status) => http.Response(jsonEncode(body), status);

Map<String, dynamic> deliveryJson({String status = 'IN_TRANSIT', Map<String, dynamic>? location}) => {
      'id': 'd-1',
      'orderId': 'o-1',
      'status': status,
      'origin': {'address': 'Farmacia', 'lat': 4.66, 'lng': -74.06},
      'destination': {'address': 'Casa', 'lat': 4.68, 'lng': -74.06},
      'route': {'encodedPolyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@', 'distanceMeters': 2300, 'durationSeconds': 615},
      'eta': '2026-10-23T15:10:15.000Z',
      'driverAssigned': true,
      'driverLocation': location,
      'distanceToDestinationMeters': location == null ? null : 1668,
      'statusTimestamps': {},
      'updatedAt': '2026-10-23T15:00:00.000Z',
    };

Map<String, dynamic> patientOrderJson({String status = 'PUBLISHED'}) => {
      'id': 'o-1',
      'status': status,
      'pharmacy': {'name': 'Farmacia 72', 'address': 'Calle 72 # 10-20'},
      'deliveryAddress': 'Calle 92 # 15-30',
      'items': [
        {'name': 'Acetaminofén 500 mg', 'quantity': 2},
      ],
      'notes': null,
      'deliveryId': 'd-1',
      'routeSummary': {'distanceMeters': 2300, 'durationSeconds': 615},
      'driverAssigned': false,
      'createdAt': '2026-10-23T15:00:00.000Z',
    };

AuthorizedJsonClient clientWith(MockClientHandler handler, [AccessTokenSource? tokens]) => AuthorizedJsonClient(
      'https://svc.example',
      tokens: tokens ?? FakeTokens(),
      client: MockClient(handler),
      timeout: const Duration(seconds: 5),
    );

void main() {
  group('models and formatting', () {
    test('decodes the reference polyline', () {
      expect(decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@'),
          const [GeoPoint(38.5, -120.2), GeoPoint(40.7, -120.95), GeoPoint(43.252, -126.453)]);
    });

    test('parses a delivery and applies realtime location updates', () {
      final delivery = Delivery.fromJson(deliveryJson());
      expect(delivery.status, DeliveryStatus.inTransit);
      expect(delivery.status.isTracking, isTrue);
      expect(delivery.driverLocation, isNull);
      final moved = delivery.withLocation({
        'driverLocation': {'lat': 4.67, 'lng': -74.06, 'heading': 0, 'speed': 8, 'recordedAt': '2026-10-23T15:01:00Z'},
        'eta': '2026-10-23T15:09:00.000Z',
        'distanceToDestinationMeters': 1100,
      });
      expect(moved.driverLocation?.point, const GeoPoint(4.67, -74.06));
      expect(moved.distanceToDestinationMeters, 1100);
      expect(DeliveryStatus.fromCode('SOMETHING_NEW'), DeliveryStatus.unknown);
    });

    test('formats distances and durations in Spanish', () {
      expect(DeliveryFormat.distance(350), '350 m');
      expect(DeliveryFormat.distance(2300), '2,3 km');
      expect(DeliveryFormat.duration(615), '11 min');
      expect(DeliveryFormat.duration(3900), '1 h 5 min');
    });

    test('delivery request JSON never carries patient ids and drops empty notes', () {
      final json = const DeliveryRequest(
        pharmacy: Pharmacy(name: 'F', address: 'Calle 1'),
        deliveryAddress: 'Calle 2',
        items: [OrderItem(name: 'X', quantity: 1)],
        notes: '  ',
      ).toJson();
      expect(json.keys, unorderedEquals(['pharmacy', 'deliveryAddress', 'items']));
    });
  });

  group('errors', () {
    test('maps delivery codes to Spanish messages without showing server text', () {
      final taken = ErrorMapper.fromDelivery(409, {
        'success': false,
        'error': {'code': 'ORDER_NOT_AVAILABLE', 'message': 'server text'},
      });
      expect(taken.kind, AppErrorKind.conflict);
      expect(taken.userMessage, ErrorMessages.orderNotAvailable);
      expect(ErrorMapper.fromDelivery(503, {'error': {'code': 'MAPS_UNAVAILABLE'}}).retryable, isTrue);
      expect(ErrorMapper.fromDelivery(422, {'error': {'code': 'ADDRESS_NOT_FOUND'}}).userMessage, ErrorMessages.addressNotFound);
      expect(ErrorMapper.fromDelivery(401, const {}).endsSession, isTrue);
    });
  });

  group('AuthorizedJsonClient', () {
    test('sends the Bearer token and retries once after a 401 with a refreshed token', () async {
      final seen = <String?>[];
      final tokens = FakeTokens();
      final client = clientWith((request) async {
        seen.add(request.headers['Authorization']);
        return seen.length == 1 ? respond({'error': {'code': 'TOKEN_INVALID'}}, 401) : respond({'ok': true}, 200);
      }, tokens);
      expect(await client.get('/x'), {'ok': true});
      expect(seen, ['Bearer token-1', 'Bearer token-2']);
      expect(tokens.refreshes, 1);
    });

    test('never puts the token in the URL', () async {
      Uri? url;
      final client = clientWith((request) async {
        url = request.url;
        return respond({}, 200);
      });
      await client.post('/orders', {'a': 1});
      expect(url.toString(), isNot(contains('token')));
    });
  });

  group('PatientOrdersController', () {
    test('publishes and lists the new order first', () async {
      final controller = PatientOrdersController(OrderService(clientWith((request) async {
        expect(request.url.path, '/orders');
        expect(jsonDecode(request.body)['items'], isNotEmpty);
        return respond(patientOrderJson(), 201);
      })));
      final order = await controller.publish(const DeliveryRequest(
        pharmacy: Pharmacy(name: 'Farmacia 72', address: 'Calle 72 # 10-20'),
        deliveryAddress: 'Calle 92 # 15-30',
        items: [OrderItem(name: 'Acetaminofén 500 mg', quantity: 2)],
      ));
      expect(order?.deliveryId, 'd-1');
      expect(controller.orders.single.status, OrderStatus.published);
    });

    test('shows a clear message when an address cannot be found', () async {
      final controller = PatientOrdersController(OrderService(clientWith(
          (_) async => respond({'success': false, 'error': {'code': 'ADDRESS_NOT_FOUND', 'message': 'x'}}, 422))));
      expect(
        await controller.publish(const DeliveryRequest(
            pharmacy: Pharmacy(name: 'F', address: 'nowhere'), deliveryAddress: 'nowhere', items: [])),
        isNull,
      );
      expect(controller.error?.userMessage, ErrorMessages.addressNotFound);
    });
  });

  group('DriverBoardController', () {
    test('a lost race (409) reloads the board and explains it', () async {
      var takes = 0;
      final controller = DriverBoardController(OrderService(clientWith((request) async {
        if (request.url.path.endsWith('/take')) {
          takes++;
          return respond({'success': false, 'error': {'code': 'ORDER_NOT_AVAILABLE', 'message': 'x'}}, 409);
        }
        return respond({'orders': []}, 200);
      })));
      final (order, error) = await controller.take('o-1');
      expect(order, isNull);
      expect(error?.userMessage, ErrorMessages.orderNotAvailable);
      expect(takes, 1);
      expect(controller.available, isEmpty);
    });
  });

  group('TrackingController', () {
    test('loads the snapshot, applies realtime events and stops when delivered', () async {
      final channel = FakeChannel();
      final controller = TrackingController(
        deliveryId: 'd-1',
        deliveries: DeliveryService(clientWith((_) async => respond(deliveryJson(), 200))),
        channel: channel,
      );
      await controller.start();
      expect(channel.watching, 'd-1');
      channel.controller.add(const LocationChanged({
        'deliveryId': 'd-1',
        'driverLocation': {'lat': 4.67, 'lng': -74.06, 'recordedAt': '2026-10-23T15:01:00Z'},
        'eta': '2026-10-23T15:09:00.000Z',
        'distanceToDestinationMeters': 1100,
      }));
      await Future<void>.delayed(Duration.zero);
      expect(controller.delivery?.driverLocation?.point, const GeoPoint(4.67, -74.06));

      channel.controller.add(DeliverySnapshot(Delivery.fromJson(deliveryJson(status: 'DELIVERED'))));
      channel.controller.add(const TrackingEnded(DeliveryStatus.delivered));
      await Future<void>.delayed(Duration.zero);
      expect(controller.delivery?.status, DeliveryStatus.delivered);
      expect(channel.closed, isTrue);
      controller.dispose();
    });

    test('does not open the realtime channel for finished deliveries', () async {
      final channel = FakeChannel();
      final controller = TrackingController(
        deliveryId: 'd-1',
        deliveries: DeliveryService(clientWith((_) async => respond(deliveryJson(status: 'CANCELLED'), 200))),
        channel: channel,
      );
      await controller.start();
      expect(channel.watching, isNull);
      controller.dispose();
    });
  });

  group('DriverDeliveryController', () {
    test('shares the location only while on the way and stops when delivered', () async {
      var status = 'ASSIGNED';
      final reports = <Map<String, dynamic>>[];
      final service = DeliveryService(clientWith((request) async {
        if (request.method == 'PATCH') status = jsonDecode(request.body)['status'] as String;
        if (request.url.path.endsWith('/locations')) {
          reports.add(jsonDecode(request.body) as Map<String, dynamic>);
          return respond({'accepted': true, 'reason': null, 'status': status, 'eta': '2026-10-23T15:10:00Z'}, 200);
        }
        return respond(deliveryJson(status: status), 200);
      }));
      final location = FakeLocation();
      final controller = DriverDeliveryController(
        deliveryId: 'd-1',
        deliveries: service,
        location: location,
        interval: const Duration(hours: 1),
      );
      await controller.start();
      expect(controller.sharing, isFalse);
      expect(controller.nextStep, DeliveryStatus.pickedUp);

      await controller.advance(DeliveryStatus.pickedUp);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.sharing, isTrue);
      expect(reports, hasLength(1));
      expect(reports.single.containsKey('speed'), isFalse); // -1 from the GPS is not sent
      expect(reports.single['heading'], 90);

      await controller.advance(DeliveryStatus.inTransit);
      await controller.advance(DeliveryStatus.delivered);
      expect(controller.sharing, isFalse);
      controller.dispose();
    });

    test('explains a denied location permission instead of failing silently', () async {
      final location = FakeLocation()
        ..notReady = AppError(kind: AppErrorKind.forbidden, userMessage: ErrorMessages.locationPermission, retryable: false);
      final controller = DriverDeliveryController(
        deliveryId: 'd-1',
        deliveries: DeliveryService(clientWith((_) async => respond(deliveryJson(status: 'PICKED_UP'), 200))),
        location: location,
      );
      await controller.start();
      expect(controller.sharing, isFalse);
      expect(controller.locationError?.userMessage, ErrorMessages.locationPermission);
      controller.dispose();
    });
  });

  group('live delivery status in the lists', () {
    Map<String, dynamic> takenOrder(String id, String deliveryId) => {
          'id': id,
          'deliveryId': deliveryId,
          'pharmacy': {'name': 'F', 'address': 'Calle 72'},
          'deliveryAddress': 'Calle 92',
          'items': [],
          'notes': null,
          'status': 'TAKEN',
        };

    test('the driver only sees deliveries still in progress under "Mis entregas"', () async {
      final orders = OrderService(clientWith((request) async => switch (request.url.path) {
            '/orders/available' => respond({'orders': []}, 200),
            _ => respond({'orders': [takenOrder('o-1', 'd-1'), takenOrder('o-2', 'd-2')]}, 200),
          }));
      final deliveries = DeliveryService(clientWith((_) async => respond({
            'deliveries': [
              {...deliveryJson(status: 'DELIVERED'), 'id': 'd-1'},
              {...deliveryJson(status: 'IN_TRANSIT'), 'id': 'd-2'},
            ],
          }, 200)));
      final controller = DriverBoardController(orders, deliveries);
      await controller.load();
      expect(controller.active.map((o) => o.id), ['o-2']);
      expect(controller.deliveryStatuses['d-2'], DeliveryStatus.inTransit);
    });

    test('the patient can cancel only before pickup, and the list survives a Geolocation outage', () async {
      final orders = OrderService(clientWith((_) async => respond({
            'orders': [patientOrderJson(status: 'TAKEN')],
          }, 200)));
      final pickedUp = DeliveryService(clientWith((_) async => respond({
            'deliveries': [deliveryJson(status: 'PICKED_UP')],
          }, 200)));
      final withStatus = PatientOrdersController(orders, pickedUp);
      await withStatus.load();
      expect(withStatus.deliveryStatusOf(withStatus.orders.single), DeliveryStatus.pickedUp);
      expect(withStatus.canCancel(withStatus.orders.single), isFalse);

      final down = DeliveryService(clientWith((_) async => respond({'error': {'code': 'INTERNAL_ERROR'}}, 500)));
      final withoutStatus = PatientOrdersController(orders, down);
      await withoutStatus.load();
      expect(withoutStatus.error, isNull);
      expect(withoutStatus.orders, hasLength(1));
      expect(withoutStatus.canCancel(withoutStatus.orders.single), isTrue);
    });
  });
}
