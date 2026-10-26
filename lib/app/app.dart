import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../auth/auth_controller.dart';
import 'app_dependencies.dart';
import 'app_router.dart';
import 'theme/app_theme.dart';

class FarmaGoApp extends StatefulWidget {
  const FarmaGoApp({super.key, this.dependencies, this.googleHandoffCode});

  /// Injected in tests; built from `AppConfig` otherwise.
  final AppDependencies? dependencies;

  /// One-time Google sign-in code read from the launch URL (web only).
  final String? googleHandoffCode;

  @override
  State<FarmaGoApp> createState() => _FarmaGoAppState();
}

class _FarmaGoAppState extends State<FarmaGoApp> {
  late final AppDependencies _deps = widget.dependencies ?? AppDependencies.create(googleHandoffCode: widget.googleHandoffCode);
  late final AppRouter _router = AppRouter(_deps);
  String? _lastUserId;

  AuthController get _auth => _deps.auth;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_syncSessionScopedState);
    _auth.restore();
  }

  @override
  void dispose() {
    _auth.removeListener(_syncSessionScopedState);
    _router.dispose();
    _deps.dispose();
    super.dispose();
  }

  /// Keeps per-user data in step with the session.
  void _syncSessionScopedState() {
    final user = _auth.user;
    if (_auth.status == AuthStatus.authenticated && user != null) {
      // A different person never sees the previous user's prescription result.
      if (_lastUserId != null && _lastUserId != user.id) {
        _deps.prescriptions.reset();
        _deps.patientOrders.clear();
        _deps.driverBoard.clear();
        _deps.adminUsers.clear();
        _deps.adminOrders.clear();
      }
      _lastUserId = user.id;
      _deps.notifications.loadForUser(user.id);
    } else if (_auth.status == AuthStatus.unauthenticated) {
      _deps.notifications.clearSession();
      _deps.patientOrders.clear();
      _deps.driverBoard.clear();
      _deps.adminUsers.clear();
      _deps.adminOrders.clear();
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'FARMA GO',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: _router.router,
      );
}
