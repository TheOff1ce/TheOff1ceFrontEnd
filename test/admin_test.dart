import 'dart:convert';

import 'package:farma_go/app/app_routes.dart';
import 'package:farma_go/app/theme/app_theme.dart';
import 'package:farma_go/hooks/admin_orders_controller.dart';
import 'package:farma_go/hooks/admin_users_controller.dart';
import 'package:farma_go/pages/admin_orders_page.dart';
import 'package:farma_go/pages/admin_users_page.dart';
import 'package:farma_go/services/access_token_source.dart';
import 'package:farma_go/services/admin_service.dart';
import 'package:farma_go/services/authorized_json_client.dart';
import 'package:farma_go/services/delivery_service.dart';
import 'package:farma_go/types/admin.dart';
import 'package:farma_go/types/auth_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Tokens implements AccessTokenSource {
  @override
  Future<String?> currentAccessToken({bool forceRefresh = false}) async => 'admin-token';
}

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, dynamic> _user(String id, String role, {String name = 'Ana'}) => {
      'id': id,
      'name': name,
      'email': '$id@x.co',
      'role': role,
      'provider': 'LOCAL',
      'emailVerified': true,
      'createdAt': '2026-10-01T00:00:00.000Z',
      'lastLoginAt': null,
    };

Map<String, dynamic> _order(String id, String status, {String? driverId}) => {
      'id': id,
      'status': status,
      'pharmacy': {'name': 'Farmacia $id', 'address': 'Calle 72'},
      'deliveryAddress': 'Calle 92',
      'items': [
        {'name': 'Acetaminofén', 'quantity': 2},
      ],
      'notes': null,
      'deliveryId': 'd-$id',
      'routeSummary': {'distanceMeters': 2300, 'durationSeconds': 615},
      'driverAssigned': driverId != null,
      'createdAt': '2026-10-23T15:00:00.000Z',
      'takenAt': null,
      'cancelledAt': null,
      'patientId': 'patient-1234567890',
      'driverId': driverId,
    };

class _Backend {
  final requests = <http.Request>[];
  final users = <Map<String, dynamic>>[_user('u-1', 'PATIENT'), _user('admin', 'ADMIN', name: 'Yo')];
  List<Map<String, dynamic>> orders = [_order('o-1', 'PUBLISHED'), _order('o-2', 'TAKEN', driverId: 'driver-9')];

  AuthorizedJsonClient client(String base) => AuthorizedJsonClient(base,
      tokens: _Tokens(), client: MockClient(_handle), timeout: const Duration(seconds: 5));

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    final path = request.url.path;
    if (path == '/admin/users' && request.method == 'GET') {
      final role = request.url.queryParameters['role'];
      final list = users.where((u) => role == null || u['role'] == role).toList();
      return _json({'users': list, 'total': list.length, 'page': 1, 'pageSize': 20});
    }
    final roleMatch = RegExp(r'^/admin/users/([^/]+)/role$').firstMatch(path);
    if (roleMatch != null && request.method == 'PATCH') {
      final user = users.firstWhere((u) => u['id'] == roleMatch.group(1));
      user['role'] = (jsonDecode(request.body) as Map)['role'];
      return _json(user);
    }
    if (path == '/orders/admin') return _json({'orders': orders});
    final cancel = RegExp(r'^/orders/([^/]+)/cancel$').firstMatch(path);
    if (cancel != null) {
      orders = [
        for (final o in orders) o['id'] == cancel.group(1) ? {...o, 'status': 'CANCELLED'} : o,
      ];
      return _json(orders.firstWhere((o) => o['id'] == cancel.group(1)));
    }
    if (path == '/deliveries') return _json({'deliveries': []});
    return _json({'success': false, 'error': {'code': 'NOT_FOUND', 'message': 'x'}}, 404);
  }
}

Widget _app(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void main() {
  group('AdminService / controllers', () {
    test('lists users with the Bearer token and filters by role in the query', () async {
      final backend = _Backend();
      final admin = AdminService(auth: backend.client('https://auth.x'), orders: backend.client('https://orders.x'));
      final c = AdminUsersController(admin, searchDelay: Duration.zero);
      await c.load();
      expect(c.users.map((u) => u.id), ['u-1', 'admin']);
      expect(backend.requests.single.headers['Authorization'], 'Bearer admin-token');
      c.setRoleFilter(UserRole.admin);
      await Future<void>.delayed(Duration.zero);
      expect(backend.requests.last.url.queryParameters['role'], 'ADMIN');
      c.dispose();
    });

    test('changes a role with PATCH and updates the row in place', () async {
      final backend = _Backend();
      final admin = AdminService(auth: backend.client('https://auth.x'), orders: backend.client('https://orders.x'));
      final c = AdminUsersController(admin);
      await c.load();
      final error = await c.changeRole(c.users.first, UserRole.driver);
      expect(error, isNull);
      expect(backend.requests.last.method, 'PATCH');
      expect(jsonDecode(backend.requests.last.body), {'role': 'DELIVERY_DRIVER'});
      expect(c.users.first.role, UserRole.driver);
      c.dispose();
    });

    test('lists pending orders by default and cancels any order', () async {
      final backend = _Backend();
      final admin = AdminService(auth: backend.client('https://auth.x'), orders: backend.client('https://orders.x'));
      final c = AdminOrdersController(admin, DeliveryService(backend.client('https://geo.x')));
      await c.load();
      expect(backend.requests.firstWhere((r) => r.url.path == '/orders/admin').url.queryParameters['status'], 'pending');
      expect(c.orders.map((o) => o.id), ['o-1', 'o-2']);
      expect(c.orders.last.driverId, 'driver-9');
      expect(c.canCancel(c.orders.first), isTrue);
      expect(await c.cancel(c.orders.first), isNull);
      expect(c.orders.first.order.status.code, 'CANCELLED');
      c.setFilter(AdminOrderFilter.cancelled);
      await Future<void>.delayed(Duration.zero);
      expect(backend.requests.lastWhere((r) => r.url.path == '/orders/admin').url.queryParameters['status'], 'CANCELLED');
      c.dispose();
    });
  });

  group('admin pages', () {
    testWidgets('users page: the admin cannot change their own role; changing another asks first', (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final backend = _Backend();
      final admin = AdminService(auth: backend.client('https://auth.x'), orders: backend.client('https://orders.x'));
      final c = AdminUsersController(admin);
      await tester.pumpWidget(_app(AdminUsersPage(controller: c, currentUserId: 'admin', onBack: () {})));
      await tester.pumpAndSettle();
      expect(find.text('2 usuarios'), findsOneWidget);
      expect(find.text('No puedes cambiar tu propio rol.'), findsOneWidget);

      await tester.tap(find.text('Paciente').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Repartidor').last);
      await tester.pumpAndSettle();
      expect(find.text('¿Cambiar el rol?'), findsOneWidget);
      await tester.tap(find.text('Sí, cambiar'));
      await tester.pumpAndSettle();
      expect(backend.requests.last.method, 'PATCH');
      expect(find.text('Rol actualizado: Repartidor.'), findsOneWidget);
      c.dispose();
    });

    testWidgets('orders page shows every pending order with map and cancel actions', (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final backend = _Backend();
      final admin = AdminService(auth: backend.client('https://auth.x'), orders: backend.client('https://orders.x'));
      final c = AdminOrdersController(admin);
      String? tracked;
      await tester.pumpWidget(_app(AdminOrdersPage(controller: c, onTrack: (o) => tracked = o.order.deliveryId, onBack: () {})));
      await tester.pumpAndSettle();
      expect(find.text('Farmacia o-1'), findsOneWidget);
      expect(find.textContaining('repartidor driver-9'), findsOneWidget);
      await tester.tap(find.text('Ver en el mapa').first);
      expect(tracked, 'd-o-1');
      c.dispose();
    });
  });

  test('routes and role labels', () {
    expect(AppRoutes.isAdminPath(AppRoutes.adminUsers), isTrue);
    expect(AppRoutes.isAdminPath(AppRoutes.adminTracking('d-1')), isTrue);
    expect(AppRoutes.isAdminPath('/administrator'), isFalse);
    expect(const AuthUser(id: 'a', name: 'A', email: 'a@x.co', role: 'ADMIN').roleLabel, 'Administrador');
    expect(UserRole.fromCode('ADMIN'), UserRole.admin);
    expect(UserRole.fromCode('ROOT'), isNull);
  });
}
