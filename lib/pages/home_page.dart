import 'package:flutter/material.dart';

import '../app/theme/farmago_tokens.dart';
import '../auth/auth_controller.dart';
import '../components/farmago/buttons.dart';
import '../components/farmago/estampado.dart';
import '../components/farmago/deadline_ring.dart';
import '../components/farmago/feedback.dart';
import '../components/farmago/shell.dart';
import '../components/farmago/status_badge.dart';
import '../components/farmago/trail.dart';
import '../components/farmago/wordmark.dart';
import '../hooks/patient_home_controller.dart';
import '../notifications/notification_controller.dart';
import '../types/delivery.dart';
import '../utils/delivery_format.dart';
import '../utils/pendientes_rol.dart';
import '../utils/plazo_vista.dart';
import 'notifications_page.dart';

/// Inicio de FarmaGo: el punto de entrada al estado real del paciente.
///
/// Prioridad, según los datos que existen: domicilio en curso, luego un pendiente que conviene
/// mirar, y por último un estado vacío con acciones concretas. La navegación vive en el shell
/// (barra lateral en escritorio, barra inferior en móvil) y no en la pantalla.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.auth,
    required this.notifications,
    required this.inicio,
    required this.onAnalyze,
    required this.onNotifications,
    required this.onAccount,
    required this.onTracking,
    required this.onPendienteDetalle,
    this.onRequestDelivery,
    this.onMyOrders,
    this.onOrdenes,
    this.onDriverBoard,
    this.onPendientes,
    this.onAdminUsers,
    this.onAdminOrders,
  });

  final AuthController auth;
  final NotificationController notifications;

  /// Datos del paciente: domicilio en curso, pendientes y su estado de carga.
  final PatientHomeController inicio;

  final VoidCallback onAnalyze;
  final VoidCallback onNotifications;
  final VoidCallback onAccount;
  final VoidCallback? onRequestDelivery;
  final VoidCallback? onMyOrders;

  /// Órdenes y autorizaciones (solo paciente). La barra inferior ya tiene cuatro destinos
  /// (manual §8.12), así que en móvil se llega desde las acciones del inicio.
  final VoidCallback? onOrdenes;
  final VoidCallback? onDriverBoard;
  final VoidCallback? onPendientes;
  final VoidCallback? onAdminUsers;
  final VoidCallback? onAdminOrders;

  /// Abre el seguimiento de un domicilio (por `deliveryId`).
  final void Function(String deliveryId) onTracking;

  /// Abre el detalle de un pendiente (por `id`).
  final void Function(String pendienteId) onPendienteDetalle;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool get isPatient => widget.auth.user?.role == 'PATIENT';
  bool get isDriver => widget.auth.user?.role == 'DELIVERY_DRIVER';
  bool get isAdmin => widget.auth.user?.role == 'ADMIN';
  PendientesRol? get _rol => PendientesRol.fromCode(widget.auth.user?.role);
  bool get _pendientesVisible => widget.onPendientes != null && _rol != null;

  @override
  void initState() {
    super.initState();
    // Solo los pacientes tienen pedidos y pendientes propios; los demás roles no consultan esos datos.
    if (isPatient) widget.inicio.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([widget.auth, widget.notifications, widget.inicio]),
        builder: (context, _) {
          final ancho = MediaQuery.sizeOf(context).width;
          return FgAppShell(
            titulo: 'Inicio',
            destinos: _destinos(),
            destinosMovil: _destinosMovil(),
            accionesSuperiores: [
              ListenableBuilder(
                listenable: widget.notifications,
                builder: (context, _) => NotificationBellButton(
                  unreadCount: widget.notifications.unreadCount,
                  onPressed: widget.onNotifications,
                ),
              ),
              FgIconButton(icon: Icons.account_circle_outlined, tooltip: 'Mi cuenta', onPressed: widget.onAccount),
            ],
            cuerpo: _Contenido(pantalla: this, movil: false, ancho: ancho),
            cuerpoMovil: _Contenido(pantalla: this, movil: true, ancho: ancho),
          );
        },
      );

  /// Todos los destinos reales del rol (barra lateral).
  List<FgDestino> _destinos() {
    final inicio = FgDestino(icono: Icons.home_outlined, etiqueta: 'Inicio', onTap: () {}, seleccionado: true);
    final cuenta = FgDestino(icono: Icons.account_circle_outlined, etiqueta: 'Mi cuenta', onTap: widget.onAccount);
    if (isAdmin) {
      return [
        inicio,
        if (widget.onAdminOrders != null)
          FgDestino(icono: Icons.pending_actions_outlined, etiqueta: 'Domicilios pendientes', onTap: widget.onAdminOrders!),
        if (widget.onAdminUsers != null)
          FgDestino(icono: Icons.manage_accounts_outlined, etiqueta: 'Usuarios y roles', onTap: widget.onAdminUsers!),
        FgDestino(icono: Icons.document_scanner_outlined, etiqueta: 'Analizar fórmula', onTap: widget.onAnalyze),
        cuenta,
      ];
    }
    if (isDriver) {
      return [
        inicio,
        if (widget.onDriverBoard != null)
          FgDestino(icono: Icons.delivery_dining_outlined, etiqueta: 'Domicilios disponibles', onTap: widget.onDriverBoard!),
        if (_pendientesVisible)
          FgDestino(icono: Icons.medication_outlined, etiqueta: _rol!.tituloEntrada, onTap: widget.onPendientes!),
        cuenta,
      ];
    }
    return [
      inicio,
      FgDestino(icono: Icons.document_scanner_outlined, etiqueta: 'Analizar fórmula', onTap: widget.onAnalyze),
      if (widget.onRequestDelivery != null)
        FgDestino(icono: Icons.home_outlined, etiqueta: 'Pedir a casa', onTap: widget.onRequestDelivery!),
      if (widget.onOrdenes != null)
        FgDestino(icono: Icons.assignment_outlined, etiqueta: 'Órdenes y autorizaciones', onTap: widget.onOrdenes!),
      if (widget.onMyOrders != null)
        FgDestino(icono: Icons.receipt_long_outlined, etiqueta: 'Mis domicilios', onTap: widget.onMyOrders!),
      if (_pendientesVisible)
        FgDestino(icono: Icons.medication_outlined, etiqueta: _rol!.tituloEntrada, onTap: widget.onPendientes!),
      cuenta,
    ];
  }

  /// Hasta cuatro destinos para la barra inferior del móvil (manual §8.12).
  List<FgDestino> _destinosMovil() {
    final inicio = FgDestino(icono: Icons.home_outlined, etiqueta: 'Inicio', onTap: () {}, seleccionado: true);
    final cuenta = FgDestino(icono: Icons.account_circle_outlined, etiqueta: 'Cuenta', onTap: widget.onAccount);
    if (isAdmin) {
      return [
        inicio,
        if (widget.onAdminOrders != null)
          FgDestino(icono: Icons.pending_actions_outlined, etiqueta: 'Domicilios', onTap: widget.onAdminOrders!),
        if (widget.onAdminUsers != null)
          FgDestino(icono: Icons.manage_accounts_outlined, etiqueta: 'Usuarios', onTap: widget.onAdminUsers!),
        cuenta,
      ];
    }
    if (isDriver) {
      return [
        inicio,
        if (widget.onDriverBoard != null)
          FgDestino(icono: Icons.delivery_dining_outlined, etiqueta: 'Disponibles', onTap: widget.onDriverBoard!),
        if (_pendientesVisible)
          FgDestino(icono: Icons.medication_outlined, etiqueta: 'Pendientes', onTap: widget.onPendientes!),
        cuenta,
      ];
    }
    return [
      inicio,
      if (widget.onMyOrders != null)
        FgDestino(icono: Icons.receipt_long_outlined, etiqueta: 'Domicilios', onTap: widget.onMyOrders!),
      if (_pendientesVisible)
        FgDestino(icono: Icons.medication_outlined, etiqueta: 'Pendientes', onTap: widget.onPendientes!),
      cuenta,
    ];
  }
}

/// Contenido de la pantalla de inicio. Lee los datos y los roles de [_HomePageState].
class _Contenido extends StatelessWidget {
  const _Contenido({required this.pantalla, required this.movil, required this.ancho});

  final _HomePageState pantalla;
  final bool movil;
  final double ancho;

  HomePage get _w => pantalla.widget;

  @override
  Widget build(BuildContext context) {
    final margen = FgBreakpoint.margenLateral(ancho);
    return FarmaGoThemed(
      child: ColoredBox(
        color: FgColors.fondo,
        child: FgEstampado(opacidad: movil ? FgOpacity.estampadoMovil : null, child: ListView(
          padding: EdgeInsets.fromLTRB(margen, movil ? FgSpace.sp4 : FgSpace.sp6, margen, FgSpace.sp7),
          children: [
            if (movil) ...[
              // Encabezado móvil con la marca tipográfica (manual §2): el logo no cabe a este tamaño.
              Row(children: [
                const FgMarca(compacta: true),
                const Spacer(),
                ListenableBuilder(
                  listenable: _w.notifications,
                  builder: (context, _) => NotificationBellButton(
                    unreadCount: _w.notifications.unreadCount,
                    onPressed: _w.onNotifications,
                  ),
                ),
              ]),
              const SizedBox(height: FgSpace.sp5),
            ],
            if (_w.auth.connectionIssue)
              Padding(
                padding: const EdgeInsets.only(bottom: FgSpace.sp5),
                child: FgBanner(
                  kind: FgBannerKind.aviso,
                  message: 'Sin conexión con el servicio. Seguiremos intentando; puedes seguir usando la app.',
                  actionLabel: 'Reintentar',
                  onAction: _w.auth.refreshNow,
                ),
              ),
            LayoutBuilder(builder: (context, constraints) {
              // El estado del paciente va en un panel elevado: jerarquía funcional, no decoración.
              // El rol con una sola acción no lo necesita y la acción conserva todo el ancho.
              final foco = pantalla.isPatient ? _Panel(child: _focoPaciente()) : _focoRol();
              final saludo = _saludo();
              final dosColumnas = !movil &&
                  constraints.maxWidth >= 880 &&
                  pantalla.isPatient &&
                  _w.inicio.foco is! FocoVacio;
              if (dosColumnas) {
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    flex: 5,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      saludo,
                      const SizedBox(height: FgSpace.sp6),
                      _acciones(incluyeAnalizar: true),
                      const SizedBox(height: FgSpace.sp7),
                      _Banda(child: _proximamente()),
                    ]),
                  ),
                  const SizedBox(width: FgSpace.sp7),
                  Expanded(flex: 6, child: foco),
                ]);
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                saludo,
                const SizedBox(height: FgSpace.sp6),
                foco,
                if (pantalla.isPatient) ...[
                  const SizedBox(height: FgSpace.sp6),
                  _acciones(incluyeAnalizar: _w.inicio.foco is! FocoVacio),
                  const SizedBox(height: FgSpace.sp7),
                  _Banda(child: _proximamente()),
                ],
              ]);
            }),
          ],
        )),
      ),
    );
  }

  Widget _saludo() {
    final name = _w.auth.user?.name.trim();
    final firstName = name?.isNotEmpty == true ? name!.split(RegExp(r'\s+')).first : null;
    final subtitulo = pantalla.isAdmin
        ? 'Administra los usuarios y los domicilios de FARMA GO.'
        : pantalla.isDriver
            ? 'Aquí ves los domicilios que puedes tomar y los que ya llevas.'
            : 'Aquí puedes ver lo que más importa de tu tratamiento.';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
        header: true,
        child: Text('Hola${firstName == null ? '' : ', $firstName'}', style: FgText.h1(ancho)),
      ),
      const SizedBox(height: FgSpace.sp2),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: FgSize.medidaTexto),
        child: Text(subtitulo, style: FgText.body.copyWith(color: FgColors.inkSoft)),
      ),
    ]);
  }

  /// Foco del paciente: error, carga, domicilio, pendiente o vacío.
  Widget _focoPaciente() {
    final inicio = _w.inicio;
    if (inicio.sinDatos) {
      return FgBanner(
        kind: FgBannerKind.error,
        message: 'No pudimos cargar tu información. Revisa tu conexión y vuelve a intentarlo.',
        actionLabel: 'Reintentar',
        onAction: inicio.load,
      );
    }
    final foco = inicio.foco;
    if (foco == null) {
      return const FgSkeleton(alto: FgSize.tarjetaInteractivaMin * 2, radio: FgRadius.md);
    }
    final avisoPendientes = inicio.errorPendientes != null && foco is! FocoPendiente
        ? Padding(
            padding: const EdgeInsets.only(bottom: FgSpace.sp5),
            child: FgBanner(
              kind: FgBannerKind.aviso,
              message: 'No pudimos cargar tus pendientes.',
              actionLabel: 'Reintentar',
              onAction: inicio.load,
            ),
          )
        : const SizedBox.shrink();
    final bloque = switch (foco) {
      FocoDomicilio() => _bloqueDomicilio(foco),
      FocoPendiente() => _bloquePendiente(foco),
      FocoVacio() => _bloqueVacio(),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [avisoPendientes, bloque]);
  }

  /// Domicilio en curso: estado, llegada, trayecto real y acceso al seguimiento.
  Widget _bloqueDomicilio(FocoDomicilio foco) {
    final detalle = foco.detalle;
    const pasos = DeliveryStatus.steps;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(liveRegion: true, child: Text(foco.estado.label, style: FgText.h2)),
      const SizedBox(height: FgSpace.sp4),
      if (detalle != null) ...[
        _Dato(etiqueta: 'Llegada estimada', valor: DeliveryFormat.eta(detalle.eta), estilo: FgText.num(FgText.h3)),
        if (detalle.distanceToDestinationMeters != null)
          _Dato(
            etiqueta: 'Distancia',
            valor: DeliveryFormat.distance(detalle.distanceToDestinationMeters!),
            estilo: FgText.num(FgText.h3),
          ),
        const SizedBox(height: FgSpace.sp4),
      ],
      FgTrail(etiquetas: [for (final paso in pasos) paso.label], actual: pasos.indexOf(foco.estado)),
      const SizedBox(height: FgSpace.sp5),
      _Dato(etiqueta: 'Entrega', valor: foco.pedido.deliveryAddress),
      const SizedBox(height: FgSpace.sp4),
      FgButton(
        label: 'Ver seguimiento',
        icon: Icons.route_outlined,
        size: FgButtonSize.lg,
        expand: movil,
        onPressed: () => _w.onTracking(foco.pedido.deliveryId),
      ),
    ]);
  }

  /// Pendiente que conviene mirar. El arco de tiempo solo muestra el plazo real del backend.
  Widget _bloquePendiente(FocoPendiente foco) {
    final p = foco.pendiente;
    final vista = PlazoVista.de(p, _w.inicio.desdeCarga);
    final conteo = Text(
      '${p.medicamentosEntregados} de ${p.medicamentosTotal} medicamentos entregados',
      style: FgText.num(FgText.body),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Anillo y texto lado a lado: la tarjeta usa todo su ancho en vez de dejar un hueco a la derecha.
      // En móvil el conteo baja a ancho completo para que el texto de la derecha tenga aire.
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // El anillo muestra el tiempo; su descripción completa va como etiqueta para lectores de pantalla.
        Semantics(
          label: vista.semantica,
          child: DeadlineRing(vista: vista, size: movil ? DeadlineRingSize.m : DeadlineRingSize.l, decorativo: true),
        ),
        const SizedBox(width: FgSpace.sp5),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // El título solo se repite si aporta algo: un vencimiento sin actualizar es un mensaje propio.
            if (vista.vencidoSinActualizar)
              Semantics(header: true, child: Text(vista.titular, style: FgText.h2))
            else if (vista.subtitulo != null)
              Semantics(header: true, child: Text(vista.subtitulo!, style: FgText.h2)),
            if (vista.vencidoSinActualizar && vista.subtitulo != null) ...[
              const SizedBox(height: FgSpace.sp1),
              Text(vista.subtitulo!, style: FgText.body),
            ],
            const SizedBox(height: FgSpace.sp3),
            StatusBadge(estado: p.cumplimientoPlazo),
            const SizedBox(height: FgSpace.sp2),
            Text(vista.fecha, style: FgText.caption),
            if (!movil) ...[
              const SizedBox(height: FgSpace.sp1),
              conteo,
            ],
          ]),
        ),
      ]),
      if (movil) ...[
        const SizedBox(height: FgSpace.sp3),
        conteo,
      ],
      const SizedBox(height: FgSpace.sp5),
      FgButton(
        label: 'Ver pendiente',
        icon: Icons.medication_outlined,
        size: FgButtonSize.lg,
        expand: movil,
        onPressed: () => _w.onPendienteDetalle(p.id),
      ),
    ]);
  }

  /// Sin domicilio en curso ni pendientes: qué pasa y qué hacer. Aquí no se usa ilustración;
  /// el manual §22 la permite solo con condiciones.
  Widget _bloqueVacio() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(header: true, child: const Text('No tienes domicilios ni pendientes activos.', style: FgText.h2)),
        const SizedBox(height: FgSpace.sp2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: FgSize.medidaTexto),
          child: const Text('Cuando pidas un domicilio o se registre un pendiente, lo verás aquí.', style: FgText.body),
        ),
        const SizedBox(height: FgSpace.sp5),
        FgButton(
          label: 'Analizar fórmula',
          icon: Icons.document_scanner_outlined,
          size: FgButtonSize.lg,
          expand: movil,
          onPressed: _w.onAnalyze,
        ),
      ]);

  /// Roles sin datos de paciente: solo su acción principal.
  Widget _focoRol() {
    final admin = pantalla.isAdmin;
    final icono = admin ? Icons.pending_actions_outlined : Icons.delivery_dining_outlined;
    final titulo = admin ? 'Domicilios pendientes' : 'Domicilios disponibles';
    final descripcion = admin
        ? 'Revisa todos los pedidos, síguelos en el mapa o cancélalos.'
        : 'Toma un pedido, recógelo en la farmacia y compártelo en el mapa.';
    final accion = admin ? _w.onAdminOrders : _w.onDriverBoard;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: FgSize.medidaTexto),
        child: Text(descripcion, style: FgText.bodyLg),
      ),
      const SizedBox(height: FgSpace.sp5),
      FgButton(label: titulo, icon: icono, size: FgButtonSize.lg, expand: movil, onPressed: accion),
    ]);
  }

  /// Acciones secundarias del paciente. Un solo botón primario por pantalla: aquí van en ghost.
  Widget _acciones({required bool incluyeAnalizar}) => Wrap(
        spacing: FgSpace.sp4,
        runSpacing: FgSpace.sp3,
        children: [
          if (incluyeAnalizar)
            FgButton(
              label: 'Analizar fórmula',
              icon: Icons.document_scanner_outlined,
              variant: _w.inicio.foco is FocoVacio ? FgButtonVariant.marca : FgButtonVariant.secondary,
              onPressed: _w.onAnalyze,
            ),
          if (_w.onRequestDelivery != null)
            FgButton(
              label: 'Pedir medicamento a casa',
              icon: Icons.home_outlined,
              variant: _w.inicio.foco is FocoVacio ? FgButtonVariant.marca : FgButtonVariant.secondary,
              onPressed: _w.onRequestDelivery,
            ),
          if (_w.onOrdenes != null)
            FgButton(
              label: 'Ver mis órdenes',
              icon: Icons.assignment_outlined,
              variant: FgButtonVariant.secondary,
              onPressed: _w.onOrdenes,
            ),
        ],
      );

  Widget _proximamente() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(header: true, child: Text('Próximamente', style: FgText.label.copyWith(color: FgColors.inkSoft))),
        const SizedBox(height: FgSpace.sp1),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: FgSize.medidaTexto),
          child: const Text(
            'Estamos preparando estas funciones para conectarte con droguerías y repartidores de FARMA GO.',
            style: FgText.body,
          ),
        ),
      ]);
}

/// Panel del estado principal: superficie, línea fina y sombra de tarjeta en reposo (`--e1`).
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  /// Barra de marca de 4 px en el borde superior (manual §22, categoría identidad). Va sin texto:
  /// el contenido empieza debajo, con su propio padding.
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: FgColors.azul100,
          borderRadius: BorderRadius.circular(FgRadius.md),
          border: Border.all(color: FgColors.linea, width: FgBorder.w1),
          boxShadow: FgShadow.e1,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FgRadius.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(gradient: FgGradients.marca),
                child: SizedBox(height: FgBorder.w4),
              ),
              Padding(padding: const EdgeInsets.all(FgSpace.sp5), child: child),
            ],
          ),
        ),
      );
}

/// Banda de contexto: una zona con fondo hundido para información secundaria.
class _Banda extends StatelessWidget {
  const _Banda({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: FgColors.fondoHundido,
          borderRadius: BorderRadius.circular(FgRadius.md),
        ),
        child: Padding(padding: const EdgeInsets.all(FgSpace.sp5), child: child),
      );
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor, this.estilo = FgText.bodyLg});

  final String etiqueta, valor;
  final TextStyle estilo;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(etiqueta, style: FgText.caption),
        const SizedBox(height: FgSpace.sp1),
        Text(valor, style: estilo),
      ]);
}
