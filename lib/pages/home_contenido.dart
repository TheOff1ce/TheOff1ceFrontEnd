part of 'home_page.dart';

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
    return ColoredBox(
      color: FgColors.fondo,
      child: FgFondo(
          child: ListView(
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
            final dosColumnas =
                !movil && constraints.maxWidth >= 880 && pantalla.isPatient && _w.inicio.foco is! FocoVacio;
            if (dosColumnas) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  flex: 5,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    saludo,
                    const SizedBox(height: FgSpace.sp6),
                    _acciones(incluyeAnalizar: true),
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
              ],
            ]);
          }),
        ],
      )),
    );
  }

  Widget _saludo() {
    final name = _w.auth.user?.name.trim();
    final firstName = name?.isNotEmpty == true ? name!.split(RegExp(r'\s+')).first : null;
    final subtitulo = pantalla.isAdmin
        ? 'Administra los usuarios y los domicilios de FarmaGo.'
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

  /// Roles sin datos de paciente: su acción principal y, debajo, el resto de lo que pueden hacer
  /// (§23: antes la pantalla quedaba vacía; reconocer antes que recordar).
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
      const SizedBox(height: FgSpace.sp7),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: FgSize.contenidoPaciente),
        child: FgAcciones(acciones: [
          if (admin && _w.onAdminUsers != null)
            FgAccionTarjeta(
              icono: Icons.manage_accounts_outlined,
              titulo: 'Usuarios y roles',
              descripcion: 'Busca personas, corrige documentos y cambia roles.',
              onTap: _w.onAdminUsers,
            ),
          if (pantalla._pendientesVisible)
            FgAccionTarjeta(
              icono: Icons.medication_outlined,
              titulo: pantalla._rol!.tituloEntrada,
              descripcion: pantalla._rol!.descripcionEntrada,
              onTap: _w.onPendientes,
            ),
          if (admin)
            FgAccionTarjeta(
              icono: Icons.document_scanner_outlined,
              titulo: 'Analizar fórmula',
              descripcion: 'Toma una foto y te decimos qué medicamentos indica.',
              onTap: _w.onAnalyze,
            ),
          FgAccionTarjeta(
            icono: Icons.account_circle_outlined,
            titulo: 'Mi cuenta',
            descripcion: 'Tus datos, tu contraseña y cerrar sesión.',
            onTap: _w.onAccount,
          ),
        ]),
      ),
    ]);
  }

  /// Acciones secundarias del paciente como tarjetas del mismo tamaño (§23, ley de Hick y
  /// similitud). El único botón primario de la pantalla está en el panel del estado.
  /// Se quitó la caja «Próximamente»: no llevaba a ninguna acción (diseño minimalista).
  Widget _acciones({required bool incluyeAnalizar}) => FgAcciones(acciones: [
        if (incluyeAnalizar)
          FgAccionTarjeta(
            icono: Icons.document_scanner_outlined,
            titulo: 'Analizar fórmula',
            descripcion: 'Toma una foto y te decimos qué medicamentos indica.',
            onTap: _w.onAnalyze,
          ),
        if (_w.onRequestDelivery != null)
          FgAccionTarjeta(
            icono: Icons.add_home_outlined,
            titulo: 'Pedir medicamento a casa',
            descripcion: 'Un repartidor lo recoge en la farmacia y lo lleva a tu puerta.',
            onTap: _w.onRequestDelivery,
          ),
        if (_w.onOrdenes != null)
          FgAccionTarjeta(
            icono: Icons.assignment_outlined,
            titulo: 'Ver mis órdenes',
            descripcion: 'Tus órdenes médicas y qué puedes pedir a domicilio.',
            onTap: _w.onOrdenes,
          ),
      ]);
}

/// Panel del estado principal (§23): tarjeta blanca con sombra baja. Se quitó la franja de
/// degradado de marca: decoraba sin informar (diseño minimalista); la jerarquía la da el botón
/// primario del panel (Von Restorff).
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: FgDecor.tarjeta(),
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
