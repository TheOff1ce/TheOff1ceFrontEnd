import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/auth_controller.dart';
import '../components/farmago/shell.dart';
import '../pages/account_page.dart';
import '../pages/admin_orders_page.dart';
import '../pages/admin_users_page.dart';
import '../pages/analysis_page.dart';
import '../pages/driver_board_page.dart';
import '../pages/driver_delivery_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/google_auth_callback_page.dart';
import '../pages/home_page.dart';
import '../pages/landing_page.dart';
import '../pages/login_page.dart';
import '../pages/my_orders_page.dart';
import '../pages/notifications_page.dart';
import '../pages/ordenes_page.dart';
import '../pages/pendiente_detail_page.dart';
import '../pages/pendientes_page.dart';
import '../pages/register_page.dart';
import '../pages/request_delivery_page.dart';
import '../pages/reset_password_page.dart';
import '../pages/result_page.dart';
import '../pages/system_pages.dart';
import '../pages/tracking_page.dart';
import '../pages/complete_profile_page.dart';
import '../pages/upload_page.dart';
import '../pages/verify_email_page.dart';
import '../types/order.dart';
import '../utils/pendientes_rol.dart';
import 'app_dependencies.dart';
import 'app_navigation.dart';
import 'app_routes.dart';

/// Declarative routes and access rules (FE-010: extracted from the app widget).
class AppRouter {
  AppRouter(this._deps);

  final AppDependencies _deps;

  AuthController get _auth => _deps.auth;

  static const publicRoutes = {
    AppRoutes.landing,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
    AppRoutes.resetPassword,
    AppRoutes.googleCallback,
  };

  static const protectedRoutes = {
    AppRoutes.home,
    AppRoutes.uploadPrescription,
    AppRoutes.analyzingPrescription,
    AppRoutes.prescriptionResult,
    AppRoutes.notifications,
    AppRoutes.account,
    AppRoutes.completeProfile,
  };

  /// Private paths, including the parameterized delivery routes.
  static bool isProtected(String path) =>
      protectedRoutes.contains(path) ||
      AppRoutes.isPatientDeliveryPath(path) ||
      AppRoutes.isDriverPath(path) ||
      AppRoutes.isPendientesPath(path) ||
      AppRoutes.isOrdenesPath(path) ||
      AppRoutes.isAdminPath(path);

  late final GoRouter router = GoRouter(
    refreshListenable: _auth,
    redirect: redirect,
    routes: [
      ..._legacyRoutes,
      ..._publicPages,
      _completeProfileRoute,
      // Barra lateral fija en tablet y escritorio para todas las pantallas privadas (§23). Las rutas y
      // sus URLs no cambian: el ShellRoute solo agrega el marco de navegación alrededor.
      ShellRoute(builder: _navShell, routes: _privatePages),
    ],
    errorBuilder: (context, state) => UnknownRoutePage(
      onHome: () => context.go(_auth.isAuthenticated ? AppRoutes.home : AppRoutes.landing),
    ),
  );

  /// Access rules. Signed-out users keep the place they wanted (FE-003).
  @visibleForTesting
  String? redirect(BuildContext context, GoRouterState state) {
    final path = state.uri.path;
    switch (_auth.status) {
      case AuthStatus.checking:
      case AuthStatus.unreachable:
        return null;
      case AuthStatus.verifying:
        return path == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
      case AuthStatus.authenticated:
        // Sin los datos del rol (documento, celular, EPS…) solo se ve la pantalla para completarlos.
        // El destino que la persona buscaba se conserva y se abre al terminar.
        final gate = profileGate(
          complete: _auth.user?.profileComplete ?? true,
          path: path,
          takeReturnTo: _auth.takeReturnTo,
        );
        if (gate != null) return gate == path ? null : gate;
        if (publicRoutes.contains(path) || path == AppRoutes.verifyEmail) {
          return _auth.takeReturnTo() ?? AppRoutes.home;
        }
        return _roleRedirect(path);
      case AuthStatus.unauthenticated:
        return _signedOutRedirect(state);
    }
  }

  /// Con el perfil incompleto todo lleva a completarlo; ya completo, esa pantalla manda al destino
  /// guardado o al inicio. `null` = el perfil no decide esta ruta.
  @visibleForTesting
  static String? profileGate({
    required bool complete,
    required String path,
    required String? Function() takeReturnTo,
  }) {
    if (!complete) return AppRoutes.completeProfile;
    if (path == AppRoutes.completeProfile) return takeReturnTo() ?? AppRoutes.home;
    return null;
  }

  /// Delivery screens are role specific: patients request and track, drivers take and deliver,
  /// administrators manage users and every order. Pendientes lo consultan los tres roles que acepta
  /// `pendientes-service`.
  String? _roleRedirect(String path) {
    final role = _auth.user?.role;
    if (AppRoutes.isAdminPath(path) && role != 'ADMIN') return AppRoutes.home;
    if (AppRoutes.isPendientesPath(path) && PendientesRol.fromCode(role) == null) return AppRoutes.home;
    if (AppRoutes.isOrdenesPath(path) && role != 'PATIENT') return AppRoutes.home;
    if (AppRoutes.isDriverPath(path) && role != 'DELIVERY_DRIVER') return AppRoutes.home;
    if (AppRoutes.isPatientDeliveryPath(path) && role != 'PATIENT') return AppRoutes.home;
    return null;
  }

  String? _signedOutRedirect(GoRouterState state) {
    final path = state.uri.path;
    if (isProtected(path)) {
      // The processing step needs the in-memory image, so it resumes at the upload step.
      _auth.rememberReturnTo(
        path == AppRoutes.analyzingPrescription ? AppRoutes.uploadPrescription : state.uri.toString(),
      );
      return AppRoutes.login;
    }
    if (path == AppRoutes.verifyEmail) return AppRoutes.login;
    final error = state.uri.queryParameters['error'];
    if (path == AppRoutes.login && error != null) {
      return Uri(path: AppRoutes.googleCallback, queryParameters: {'error': error}).toString();
    }
    if (path == AppRoutes.resetPassword && _deps.passwordReset.email == null) return AppRoutes.forgotPassword;
    return null;
  }

  /// Marco con la barra lateral del rol. Sin sesión confirmada no hay barra: la página muestra su
  /// propio estado de carga o error (vía [_gate]).
  Widget _navShell(BuildContext context, GoRouterState state, Widget child) => ListenableBuilder(
        listenable: _auth,
        builder: (context, _) {
          final user = _auth.user;
          if (_auth.status != AuthStatus.authenticated || user == null) return child;
          return FgNavLateral(
            destinos: AppNavigation.lateral(role: user.role, path: state.uri.path, go: context.go),
            child: child,
          );
        },
      );

  /// Pages that need a known session state show loading or "unavailable" first.
  Widget _gate(Widget child) => ListenableBuilder(
        listenable: _auth,
        builder: (context, _) => switch (_auth.status) {
          AuthStatus.checking => const SessionLoadingPage(),
          AuthStatus.unreachable => SessionUnavailablePage(
              error: _auth.startupError,
              onRetry: _auth.restore,
              onContinue: _auth.continueSignedOut,
            ),
          _ => child,
        },
      );

  List<RouteBase> get _legacyRoutes => [
        GoRoute(
          path: LegacyRoutes.login,
          redirect: (context, state) {
            final error = state.uri.queryParameters['error'];
            return error == null
                ? AppRoutes.login
                : Uri(path: AppRoutes.googleCallback, queryParameters: {'error': error}).toString();
          },
        ),
        GoRoute(
          path: AppRoutes.oauthLanding,
          redirect: (context, state) =>
              Uri(path: AppRoutes.googleCallback, queryParameters: state.uri.queryParameters).toString(),
        ),
        for (final (legacy, current) in LegacyRoutes.mapping)
          GoRoute(path: legacy, redirect: (context, state) => current),
      ];

  List<RouteBase> get _publicPages => [
        GoRoute(
          path: AppRoutes.landing,
          builder: (context, state) => _gate(LandingPage(
            onLogin: () => context.push(AppRoutes.login),
            onRegister: () => context.push(AppRoutes.register),
          )),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => _gate(LoginPage(
            auth: _auth,
            onRegister: () => context.push(AppRoutes.register),
            onForgotPassword: () {
              _deps.passwordReset.restart();
              context.push(AppRoutes.forgotPassword);
            },
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.landing),
          )),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => _gate(RegisterPage(
            auth: _auth,
            onLogin: () => context.push(AppRoutes.login),
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.landing),
          )),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => _gate(ForgotPasswordPage(
            reset: _deps.passwordReset,
            onSent: () => context.push(AppRoutes.resetPassword),
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.login),
          )),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (context, state) => _gate(ResetPasswordPage(
            reset: _deps.passwordReset,
            onLogin: () {
              _deps.passwordReset.restart();
              context.go(AppRoutes.login);
            },
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.forgotPassword),
          )),
        ),
        GoRoute(
          path: AppRoutes.verifyEmail,
          builder: (context, state) => _gate(VerifyEmailPage(
            auth: _auth,
            onBack: () {
              _auth.cancelVerification();
              context.go(AppRoutes.login);
            },
          )),
        ),
        GoRoute(
          path: AppRoutes.googleCallback,
          builder: (context, state) =>
              GoogleAuthCallbackPage(auth: _auth, errorCode: state.uri.queryParameters['error']),
        ),
      ];

  List<RouteBase> get _privatePages => [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => _gate(HomePage(
            auth: _auth,
            notifications: _deps.notifications,
            inicio: _deps.patientHome,
            resumenEps: _auth.user?.role == 'EPS' ? _deps.epsResumen : null,
            onTracking: (deliveryId) => context.push(AppRoutes.tracking(deliveryId)),
            onPendienteDetalle: (pendienteId) => context.push(AppRoutes.pendiente(pendienteId)),
            onAnalyze: () => context.push(AppRoutes.uploadPrescription),
            onNotifications: () => context.push(AppRoutes.notifications),
            onAccount: () => context.push(AppRoutes.account),
            onRequestDelivery: () => context.push(AppRoutes.requestDelivery),
            onMyOrders: () => context.push(AppRoutes.myOrders),
            onOrdenes: () => context.push(AppRoutes.ordenes),
            onDriverBoard: () => context.push(AppRoutes.driverBoard),
            onPendientes: () => context.push(AppRoutes.pendientes),
            onAdminUsers: () => context.push(AppRoutes.adminUsers),
            onAdminOrders: () => context.push(AppRoutes.adminOrders),
          )),
        ),
        ..._pendientesPages,
        ..._ordenesPages,
        ..._deliveryPages,
        ..._adminPages,
        GoRoute(
          path: AppRoutes.uploadPrescription,
          builder: (context, state) => _gate(UploadPage(
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.home),
            onAnalyze: (image) => context.push(AppRoutes.analyzingPrescription, extra: image),
          )),
        ),
        GoRoute(
          path: AppRoutes.analyzingPrescription,
          builder: (context, state) {
            final image = state.extra;
            if (image is! XFile) {
              return _gate(MissingAnalysisStepPage(onBack: () => context.go(AppRoutes.uploadPrescription)));
            }
            return _gate(AnalysisPage(
              controller: _deps.prescriptions,
              image: image,
              onBack: () => AppRoutes.backOrGo(context, AppRoutes.uploadPrescription),
              onComplete: () {
                final result = _deps.prescriptions.result;
                if (result != null) {
                  _deps.notifications.addAnalysisCompleted(medicationCount: result.medications.length);
                }
                context.go(AppRoutes.prescriptionResult);
              },
            ));
          },
        ),
        GoRoute(
          path: AppRoutes.prescriptionResult,
          builder: (context, state) {
            final result = _deps.prescriptions.result;
            if (result == null) {
              return _gate(MissingAnalysisStepPage(onBack: () => context.go(AppRoutes.uploadPrescription)));
            }
            return _gate(ResultPage(
              result: result,
              onHome: () => context.go(AppRoutes.home),
              onAnalyzeAnother: () {
                _deps.prescriptions.reset();
                context.go(AppRoutes.uploadPrescription);
              },
              // Solo el paciente pide domicilios (las demás rutas de pedido lo exigen también).
              onRequestDelivery: _auth.user?.role == 'PATIENT'
                  ? (items) => context.push(AppRoutes.requestDelivery, extra: items)
                  : null,
            ));
          },
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => _gate(NotificationsPage(
            notifications: _deps.notifications,
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.home),
          )),
        ),
        GoRoute(
          path: AppRoutes.account,
          builder: (context, state) => _gate(AccountPage(
            auth: _auth,
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.home),
          )),
        ),
      ];

  /// Completar el perfil va fuera del marco con navegación: hasta terminarlo no hay otro destino.
  GoRoute get _completeProfileRoute => GoRoute(
        path: AppRoutes.completeProfile,
        builder: (context, state) => _gate(CompleteProfilePage(auth: _auth)),
      );

  List<RouteBase> get _pendientesPages => [
        GoRoute(
          path: AppRoutes.pendientes,
          builder: (context, state) => _gate(PendientesPage(
            controller: _deps.pendientes,
            rol: PendientesRol.fromCode(_auth.user?.role),
            createDetailController: _deps.pendienteDetailFor,
            onOpen: (pendiente) => context.push(AppRoutes.pendiente(pendiente.id)),
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.home),
          )),
        ),
        GoRoute(
          path: AppRoutes.pendientePattern,
          builder: (context, state) {
            final id = state.pathParameters['pendienteId'] ?? '';
            return _gate(PendienteDetailPage(
              key: ValueKey(id),
              rol: PendientesRol.fromCode(_auth.user?.role),
              createController: () => _deps.pendienteDetailFor(id),
              onBack: () => AppRoutes.backOrGo(context, AppRoutes.pendientes),
            ));
          },
        ),
      ];

  List<RouteBase> get _ordenesPages => [
        GoRoute(
          path: AppRoutes.ordenes,
          builder: (context, state) => _gate(_ordenesPage(context)),
        ),
        GoRoute(
          path: AppRoutes.ordenPattern,
          builder: (context, state) => _gate(_ordenesPage(context, ordenId: state.pathParameters['ordenId'])),
        ),
      ];

  Widget _ordenesPage(BuildContext context, {String? ordenId}) => OrdenesPage(
        key: ValueKey('ordenes-${ordenId ?? ''}'),
        ordenEnlace: ordenId,
        createController: _deps.crearOrdenes,
        onBack: () => AppRoutes.backOrGo(context, AppRoutes.home),
        // Destinos pendientes del equipo (D9): la cuenta y la lista de domicilios del paciente.
        onRevisarDatos: () => context.push(AppRoutes.account),
        onSeguirEnDomicilios: () => context.push(AppRoutes.myOrders),
      );

  List<RouteBase> get _deliveryPages => [
        GoRoute(
          path: AppRoutes.myOrders,
          builder: (context, state) => _gate(MyOrdersPage(
            controller: _deps.patientOrders,
            onRequest: () => context.push(AppRoutes.requestDelivery),
            onTrack: (order) => context.push(AppRoutes.tracking(order.deliveryId)),
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.home),
          )),
        ),
        GoRoute(
          path: AppRoutes.requestDelivery,
          builder: (context, state) => _gate(RequestDeliveryPage(
            controller: _deps.patientOrders,
            defaultAddress: _auth.user?.profile.address,
            initialItems: state.extra is List<OrderItem> ? state.extra! as List<OrderItem> : const [],
            onCreated: (order) => context.pushReplacement(AppRoutes.tracking(order.deliveryId)),
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.myOrders),
          )),
        ),
        GoRoute(
          path: AppRoutes.trackingPattern,
          builder: (context, state) {
            final deliveryId = state.pathParameters['deliveryId'] ?? '';
            return _gate(TrackingPage(
              key: ValueKey(deliveryId),
              createController: () => _deps.trackingFor(deliveryId),
              onBack: () => AppRoutes.backOrGo(context, AppRoutes.myOrders),
            ));
          },
        ),
        GoRoute(
          path: AppRoutes.driverBoard,
          builder: (context, state) => _gate(DriverBoardPage(
            controller: _deps.driverBoard,
            onOpen: (order) => context.push(AppRoutes.driverDelivery(order.id)),
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.home),
          )),
        ),
        GoRoute(
          path: AppRoutes.driverDeliveryPattern,
          builder: (context, state) {
            final order = _deps.driverBoard.takenById(state.pathParameters['orderId'] ?? '');
            if (order == null) {
              return _gate(MissingDeliveryPage(onBack: () => context.go(AppRoutes.driverBoard)));
            }
            return _gate(DriverDeliveryPage(
              key: ValueKey(order.id),
              order: order,
              createController: _deps.driverDeliveryFor,
              onBack: () => AppRoutes.backOrGo(context, AppRoutes.driverBoard),
            ));
          },
        ),
      ];

  List<RouteBase> get _adminPages => [
        GoRoute(
          path: AppRoutes.adminUsers,
          builder: (context, state) => _gate(AdminUsersPage(
            controller: _deps.adminUsers,
            currentUserId: _auth.user?.id,
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.home),
          )),
        ),
        GoRoute(
          path: AppRoutes.adminOrders,
          builder: (context, state) => _gate(AdminOrdersPage(
            controller: _deps.adminOrders,
            onTrack: (order) => context.push(AppRoutes.adminTracking(order.order.deliveryId)),
            onBack: () => AppRoutes.backOrGo(context, AppRoutes.home),
          )),
        ),
        GoRoute(
          path: AppRoutes.adminTrackingPattern,
          builder: (context, state) {
            final deliveryId = state.pathParameters['deliveryId'] ?? '';
            return _gate(TrackingPage(
              key: ValueKey('admin-$deliveryId'),
              createController: () => _deps.trackingFor(deliveryId),
              showPatientActions: false,
              onBack: () => AppRoutes.backOrGo(context, AppRoutes.adminOrders),
            ));
          },
        ),
      ];

  void dispose() => router.dispose();
}
