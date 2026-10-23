import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import '../auth/password_reset_controller.dart';
import '../hooks/prescription_hook.dart';
import '../notifications/notification_controller.dart';
import '../notifications/notification_repository.dart';
import '../services/api_service.dart';
import '../services/prescription_service.dart';
import '../utils/constants.dart';

/// Composition root: the only place that builds services and controllers.
class AppDependencies {
  AppDependencies({
    required this.api,
    required this.prescriptions,
    required this.auth,
    required this.passwordReset,
    required this.notifications,
  });

  factory AppDependencies.create() {
    final auth = AuthController(AuthRepository(AppConfig.authBaseUrl));
    // AI-001: every analysis request carries the access token issued by Auth.
    final api = ApiService(AppConfig.apiBaseUrl, tokens: auth);
    return AppDependencies(
      api: api,
      prescriptions: PrescriptionController(PrescriptionService(api)),
      auth: auth,
      // Password recovery uses its own client so it never shares session state.
      passwordReset: PasswordResetController(AuthRepository(AppConfig.authBaseUrl)),
      notifications: NotificationController(NotificationRepository()),
    );
  }

  final ApiService api;
  final PrescriptionController prescriptions;
  final AuthController auth;
  final PasswordResetController passwordReset;
  final NotificationController notifications;

  void dispose() {
    prescriptions.dispose();
    auth.dispose();
    passwordReset.dispose();
    notifications.dispose();
    api.dispose();
  }
}
