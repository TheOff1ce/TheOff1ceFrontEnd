import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../auth/auth_controller.dart';
import '../components/farmago/banda_sin_conexion.dart';
import '../components/farmago/feedback.dart';
import '../notifications/vigia_domicilios.dart';
import 'apariencia.dart';
import 'app_dependencies.dart';
import 'app_router.dart';
import 'theme/app_theme.dart';
import 'theme/farmago_tokens.dart';
import 'titulos.dart';

class FarmaGoApp extends StatefulWidget {
  const FarmaGoApp({super.key, this.dependencies, this.googleHandoffCode});

  /// Injected in tests; built from `AppConfig` otherwise.
  final AppDependencies? dependencies;

  /// One-time Google sign-in code read from the launch URL (web only).
  final String? googleHandoffCode;

  @override
  State<FarmaGoApp> createState() => _FarmaGoAppState();
}

class _FarmaGoAppState extends State<FarmaGoApp> with WidgetsBindingObserver {
  late final AppDependencies _deps = widget.dependencies ?? AppDependencies.create(googleHandoffCode: widget.googleHandoffCode);
  late final AppRouter _router = AppRouter(_deps);
  String? _lastUserId;
  late final VigiaDomicilios? _vigia = _deps.vigia?.call(_avisarCambio);
  late final AppLifecycleListener _ciclo = AppLifecycleListener(
    onShow: () => _vigia?.reanudar(),
    onHide: () => _vigia?.pausar(),
  );

  /// Un cambio en un domicilio: queda en la campana y, si la app está abierta, se ve flotando.
  void _avisarCambio(EventoDomicilio evento) {
    _deps.notifications.addDomicilio(evento);
    avisar(
      evento.titulo,
      detalle: evento.mensaje,
      kind: switch (evento.tono) {
        TonoEvento.exito => FgToastKind.exito,
        TonoEvento.problema => FgToastKind.error,
        TonoEvento.info => FgToastKind.info,
      },
    );
  }

  AuthController get _auth => _deps.auth;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_syncSessionScopedState);
    WidgetsBinding.instance.addObserver(this);
    FgModo.oscuro = _oscuroAhora;
    AparienciaController.instancia
      ..addListener(_aplicarModo)
      ..cargar();
    _ciclo; // empieza a escuchar si la app se ve o se oculta
    _auth.restore();
  }

  @override
  void dispose() {
    _auth.removeListener(_syncSessionScopedState);
    WidgetsBinding.instance.removeObserver(this);
    AparienciaController.instancia.removeListener(_aplicarModo);
    _ciclo.dispose();
    _vigia?.detener();
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
        _deps.pendientes.clear();
        _deps.adminUsers.clear();
        _deps.adminOrders.clear();
      }
      _lastUserId = user.id;
      _deps.notifications.loadForUser(user.id);
      _vigia?.iniciar(switch (user.role) {
        'PATIENT' => RolVigilado.paciente,
        'DELIVERY_DRIVER' => RolVigilado.repartidor,
        _ => null,
      });
    } else if (_auth.status == AuthStatus.unauthenticated) {
      _vigia?.detener();
      _deps.notifications.clearSession();
      _deps.patientOrders.clear();
      _deps.driverBoard.clear();
      _deps.pendientes.clear();
      _deps.adminUsers.clear();
      _deps.adminOrders.clear();
    }
  }

  static bool get _sistemaOscuro =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;

  /// Oscuro o claro según la apariencia elegida (o el dispositivo, si es automática).
  static bool get _oscuroAhora =>
      AparienciaController.instancia.valor.oscuraCon(sistemaOscuro: _sistemaOscuro);

  @override
  void didChangePlatformBrightness() => _aplicarModo();

  /// Cambió el modo (el dispositivo o la persona en «Apariencia»): los tokens cambian de valor y toda
  /// la app se vuelve a pintar, incluidos los widgets `const` (que Flutter no reconstruiría solos).
  /// No se pierde nada: ni la pantalla abierta ni lo escrito en los formularios.
  void _aplicarModo() {
    final oscuro = _oscuroAhora;
    if (oscuro == FgModo.oscuro || !mounted) return;
    setState(() => FgModo.oscuro = oscuro);
    void marcar(Element e) {
      e.markNeedsBuild();
      e.visitChildren(marcar);
    }

    (context as Element).visitChildren(marcar);
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: TitulosDePantalla.marca,
        debugShowCheckedModeBanner: false,
        // Tema del modo actual (claro u oscuro, según el sistema): los tokens ya traen sus colores.
        theme: AppTheme.light,
        themeAnimationDuration: Duration.zero,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: _router.router,
        // Los avisos flotantes viven encima de todas las pantallas (sobreviven a los cambios de ruta).
        builder: (context, child) => TituloDePantalla(
          router: _router.router,
          child: FgCapaAvisos(child: BandaSinConexion(child: child ?? const SizedBox.shrink())),
        ),
      );
}
