import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import '../auth/password_reset_controller.dart';
import '../hooks/driver_board_controller.dart';
import '../hooks/driver_delivery_controller.dart';
import '../hooks/patient_orders_controller.dart';
import '../hooks/prescription_hook.dart';
import '../hooks/tracking_controller.dart';
import '../notifications/notification_controller.dart';
import '../notifications/notification_repository.dart';
import '../services/api_service.dart';
import '../services/authorized_json_client.dart';
import '../services/delivery_service.dart';
import '../services/location_source.dart';
import '../services/order_service.dart';
import '../services/prescription_service.dart';
import '../services/tracking_channel.dart';
import '../utils/constants.dart';

/// Composition root: the only place that builds services and controllers.
class AppDependencies {
  AppDependencies({
    required this.api,
    required this.prescriptions,
    required this.auth,
    required this.passwordReset,
    required this.notifications,
    required this.patientOrders,
    required this.driverBoard,
    required this.deliveries,
    required this.trackingChannels,
    required this.location,
    this.deliveryClients = const [],
  });

  factory AppDependencies.create({String? googleHandoffCode}) {
    final auth = AuthController(AuthRepository(AppConfig.authBaseUrl), googleHandoffCode: googleHandoffCode);
    // AI-001: every analysis request carries the access token issued by Auth.
    final api = ApiService(AppConfig.apiBaseUrl, tokens: auth);
    // Orders and tracking carry the same Bearer token; there are no other secrets in the app.
    final ordersClient = AuthorizedJsonClient(AppConfig.ordersBaseUrl, tokens: auth, timeout: NetworkTimeouts.orders);
    final trackingClient =
        AuthorizedJsonClient(AppConfig.geolocationBaseUrl, tokens: auth, timeout: NetworkTimeouts.tracking);
    final orders = OrderService(ordersClient);
    final deliveries = DeliveryService(trackingClient);
    return AppDependencies(
      api: api,
      prescriptions: PrescriptionController(PrescriptionService(api)),
      auth: auth,
      // Password recovery uses its own client so it never shares session state.
      passwordReset: PasswordResetController(AuthRepository(AppConfig.authBaseUrl)),
      notifications: NotificationController(NotificationRepository()),
      patientOrders: PatientOrdersController(orders, deliveries),
      driverBoard: DriverBoardController(orders, deliveries),
      deliveries: deliveries,
      trackingChannels: () => SocketTrackingChannel(AppConfig.geolocationBaseUrl, auth),
      location: GeolocatorLocationSource(),
      deliveryClients: [ordersClient, trackingClient],
    );
  }

  final ApiService api;
  final PrescriptionController prescriptions;
  final AuthController auth;
  final PasswordResetController passwordReset;
  final NotificationController notifications;
  final PatientOrdersController patientOrders;
  final DriverBoardController driverBoard;
  final DeliveryService deliveries;
  final TrackingChannelFactory trackingChannels;
  final LocationSource location;
  final List<AuthorizedJsonClient> deliveryClients;

  /// One live tracking session per screen (closed when the screen is disposed).
  TrackingController trackingFor(String deliveryId) =>
      TrackingController(deliveryId: deliveryId, deliveries: deliveries, channel: trackingChannels());

  DriverDeliveryController driverDeliveryFor(String deliveryId) => DriverDeliveryController(
        deliveryId: deliveryId,
        deliveries: deliveries,
        location: location,
        interval: TrackingConfig.locationInterval,
      );

  void dispose() {
    prescriptions.dispose();
    auth.dispose();
    passwordReset.dispose();
    notifications.dispose();
    patientOrders.dispose();
    driverBoard.dispose();
    for (final client in deliveryClients) {
      client.dispose();
    }
    api.dispose();
  }
}
