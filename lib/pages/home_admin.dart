part of 'home_page.dart';

/// Inicio del administrador: cómo va la operación ahora y qué necesita atención. No repite la
/// barra lateral; cada bloque lleva a su pantalla. Todo va en una sola columna con el mismo borde
/// izquierdo y el mismo ancho máximo.
class _InicioAdmin extends StatelessWidget {
  const _InicioAdmin({required this.pantalla, required this.movil});

  final _HomePageState pantalla;
  final bool movil;

  /// Ancho de la columna del administrador (cifras y listas se leen sin recorrer la pantalla).
  static const ancho = 1120.0;

  HomePage get _w => pantalla.widget;

  @override
  Widget build(BuildContext context) {
    final c = _w.inicioAdmin!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: ancho),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Panel(child: _operacion(c)),
        const SizedBox(height: FgSpace.sp5),
        _Panel(child: _semana(c)),
        const SizedBox(height: FgSpace.sp5),
        LayoutBuilder(builder: (context, constraints) {
          final esperan = _Panel(child: _esperan(c));
          final lateral = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Panel(child: _calificaciones(c)),
            const SizedBox(height: FgSpace.sp5),
            Expanded(child: _Panel(child: _usuarios(c))),
          ]);
          final apilado = movil || constraints.maxWidth < 880;
          if (apilado) {
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              esperan,
              const SizedBox(height: FgSpace.sp5),
              _Panel(child: _calificaciones(c)),
              const SizedBox(height: FgSpace.sp5),
              _Panel(child: _usuarios(c)),
            ]);
          }
          // Misma altura en las dos columnas: los bloques terminan sobre la misma línea.
          return IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(flex: 3, child: esperan),
              const SizedBox(width: FgSpace.sp5),
              Expanded(flex: 2, child: lateral),
            ]),
          );
        }),
      ]),
    );
  }

  /// Encabezado de cada bloque: título a la izquierda y su acción a la derecha, en la misma línea.
  /// En columnas angostas las acciones bajan a su propia línea: el título nunca se parte.
  Widget _encabezado(String titulo, {String? accion, VoidCallback? onAccion, Widget? extra}) =>
      Builder(builder: (context) {
        final tituloW = Semantics(header: true, child: Text(titulo, style: FgText.h3));
        final acciones = [
          if (extra != null) extra,
          if (accion != null && onAccion != null) ...[
            const SizedBox(width: FgSpace.sp2),
            _EnlaceEncabezado(texto: accion, onPressed: onAccion),
          ],
        ];
        if (acciones.isEmpty) return tituloW;
        if (MediaQuery.sizeOf(context).width < 480) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            tituloW,
            Row(mainAxisAlignment: MainAxisAlignment.end, children: acciones),
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: tituloW),
          ...acciones,
        ]);
      });

  Widget _error(AppError error, VoidCallback reintentar) => FgBanner(
        kind: FgBannerKind.error,
        message: error.userMessage,
        actionLabel: 'Reintentar',
        onAction: reintentar,
      );

  Widget _operacion(AdminInicioController c) {
    final o = c.operacion;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _encabezado(
        'Domicilios ahora',
        extra: FgIconButton(icon: Icons.refresh, tooltip: 'Actualizar', onPressed: c.loading ? null : c.load),
        accion: 'Ver domicilios',
        onAccion: _w.onAdminOrders,
      ),
      const SizedBox(height: FgSpace.sp4),
      if (o == null && c.errorOperacion != null)
        _error(c.errorOperacion!, c.load)
      else if (o == null)
        const FgListaCargando(cantidad: 1, etiqueta: 'Cargando los domicilios')
      else
        LayoutBuilder(builder: (context, constraints) {
          const gap = FgSpace.sp3;
          final columnas = constraints.maxWidth >= 640 ? 4 : 2;
          final ancho = (constraints.maxWidth - gap * (columnas - 1)) / columnas;
          final cifras = [
            _Cifra(
              valor: '${o.buscandoRepartidor}',
              etiqueta: 'Buscando repartidor',
              fondo: o.buscandoRepartidor > 0 ? FgColors.riesgoBg : FgColors.neutroBg,
              texto: o.buscandoRepartidor > 0 ? FgColors.riesgoFg : FgColors.neutroFg,
            ),
            _Cifra(
              valor: '${o.enCamino}',
              etiqueta: 'En curso',
              fondo: FgColors.vigenteBg,
              texto: FgColors.vigenteFg,
            ),
            _Cifra(
              valor: '${o.entregadosHoy}',
              etiqueta: 'Entregados hoy',
              fondo: FgColors.cumplidoBg,
              texto: FgColors.cumplidoFg,
            ),
            _Cifra(
              valor: '${o.noEntregadosHoy}',
              etiqueta: 'Cancelados o fallidos hoy',
              fondo: o.noEntregadosHoy > 0 ? FgColors.incumplidoBg : FgColors.neutroBg,
              texto: o.noEntregadosHoy > 0 ? FgColors.incumplidoFg : FgColors.neutroFg,
            ),
          ];
          return Wrap(spacing: gap, runSpacing: gap, children: [
            for (final cifra in cifras) SizedBox(width: ancho, child: cifra),
          ]);
        }),
    ]);
  }

  Widget _semana(AdminInicioController c) {
    final o = c.operacion;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _encabezado('Últimos 7 días'),
      const SizedBox(height: FgSpace.sp4),
      if (o == null && c.errorOperacion == null)
        const FgListaCargando(cantidad: 1, etiqueta: 'Cargando la semana')
      else if (o == null)
        const Text('No pudimos cargar la semana.', style: FgText.body)
      else ...[
        Wrap(spacing: FgSpace.sp7, runSpacing: FgSpace.sp3, children: [
          _Dato(etiqueta: 'Entregados', valor: '${o.entregadosSemana}', estilo: FgText.num(FgText.h2)),
          _Dato(etiqueta: 'Cancelados o fallidos', valor: '${o.noEntregadosSemana}', estilo: FgText.num(FgText.h2)),
          _Dato(
            etiqueta: 'Se entregaron',
            valor: o.efectividadSemana == null ? '—' : '${o.efectividadSemana} %',
            estilo: FgText.num(FgText.h2),
          ),
        ]),
        const SizedBox(height: FgSpace.sp4),
        _GraficaSemana(dias: o.semana),
      ],
    ]);
  }

  Widget _esperan(AdminInicioController c) {
    final o = c.operacion;
    const visibles = 5;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _encabezado('Esperan repartidor'),
      const SizedBox(height: FgSpace.sp1),
      const Text('El que lleva más tiempo esperando va primero.', style: FgText.caption),
      const SizedBox(height: FgSpace.sp3),
      if (o == null && c.errorOperacion == null)
        const FgListaCargando(cantidad: 2, etiqueta: 'Cargando los pedidos en espera')
      else if (o == null)
        const Text('No pudimos cargar los pedidos en espera.', style: FgText.body)
      else if (o.esperando.isEmpty)
        Row(children: [
          const Icon(Icons.check_circle_outline, size: FgSize.iconoMd, color: FgColors.cumplidoSolid),
          const SizedBox(width: FgSpace.sp3),
          Expanded(
            child: Text('Ningún pedido espera repartidor.', style: FgText.body.copyWith(color: FgColors.inkSoft)),
          ),
        ])
      else ...[
        for (final (i, d) in o.esperando.take(visibles).indexed) ...[
          if (i > 0) const Divider(height: FgSpace.sp1, color: FgColors.lineaSuave),
          _PedidoEnEspera(entrega: d, ahora: c.ahora, onTap: () => _w.onAdminTracking?.call(d.id)),
        ],
        if (o.esperando.length > visibles) ...[
          const SizedBox(height: FgSpace.sp3),
          Align(
            alignment: Alignment.centerLeft,
            child: FgButton(
              label: 'Ver los ${o.esperando.length} en espera',
              variant: FgButtonVariant.secondary,
              size: FgButtonSize.sm,
              onPressed: _w.onAdminOrders,
            ),
          ),
        ],
      ],
    ]);
  }

  Widget _calificaciones(AdminInicioController c) {
    final r = c.calificaciones;
    final malas = r == null ? 0 : r.distribucion[0] + r.distribucion[1];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _encabezado('Calificaciones de la semana', accion: 'Ver', onAccion: _w.onAdminRatings),
      const SizedBox(height: FgSpace.sp3),
      if (r == null && c.errorCalificaciones != null)
        _error(c.errorCalificaciones!, c.load)
      else if (r == null)
        const FgListaCargando(cantidad: 1, etiqueta: 'Cargando las calificaciones')
      else if (r.total == 0)
        Text('Nadie ha calificado una entrega en los últimos 7 días.',
            style: FgText.body.copyWith(color: FgColors.inkSoft))
      else ...[
        Semantics(
          label: 'Promedio ${_uno(r.promedio ?? 0)} de 5 con ${r.total} '
              '${r.total == 1 ? 'calificación' : 'calificaciones'}.',
          excludeSemantics: true,
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(_uno(r.promedio ?? 0), style: FgText.num(FgText.h1Movil)),
            const SizedBox(width: FgSpace.sp3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                EstrellasPromedio(valor: r.promedio ?? 0, tamano: 20),
                const SizedBox(height: FgSpace.sp1),
                Text('${r.total} ${r.total == 1 ? 'calificación' : 'calificaciones'}', style: FgText.caption),
              ]),
            ),
          ]),
        ),
        if (malas > 0) ...[
          const SizedBox(height: FgSpace.sp3),
          Text(
            malas == 1 ? '1 entrega con 1 o 2 estrellas' : '$malas entregas con 1 o 2 estrellas',
            style: FgText.label.copyWith(color: FgColors.riesgoFg),
          ),
        ],
      ],
    ]);
  }

  Widget _usuarios(AdminInicioController c) {
    final u = c.usuarios;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _encabezado('Usuarios', accion: 'Gestionar', onAccion: _w.onAdminUsers),
      const SizedBox(height: FgSpace.sp3),
      if (u == null && c.errorUsuarios != null)
        _error(c.errorUsuarios!, c.load)
      else if (u == null)
        const FgListaCargando(cantidad: 1, etiqueta: 'Cargando los usuarios')
      else
        Row(children: [
          Expanded(child: _Dato(etiqueta: 'Registrados', valor: '${u.total}', estilo: FgText.num(FgText.h2))),
          Expanded(child: _Dato(etiqueta: 'Repartidores', valor: '${u.repartidores}', estilo: FgText.num(FgText.h2))),
        ]),
    ]);
  }

  static String _uno(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
}

/// Pedido sin repartidor: de qué farmacia, a dónde y cuánto lleva esperando. Abre el seguimiento.
class _PedidoEnEspera extends StatelessWidget {
  const _PedidoEnEspera({required this.entrega, required this.ahora, required this.onTap});

  final Delivery entrega;
  final DateTime ahora;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final desde = entrega.since;
    final espera = desde == null ? null : ahora.difference(desde);
    final demorado = espera != null && espera >= OperacionHoy.demora;
    final tiempo = espera == null ? 'Sin hora' : PendienteFormat.duracion(espera.isNegative ? Duration.zero : espera);
    return Semantics(
      button: true,
      label: 'Recoger en ${entrega.origin.address}, entregar en ${entrega.destination.address}. '
          '${espera == null ? '' : 'Espera hace $tiempo.'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FgRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FgSize.tapMin),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: FgSpace.sp3),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(entrega.origin.address, style: FgText.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: FgSpace.sp1),
                  Text('Entregar en ${entrega.destination.address}',
                      style: FgText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              const SizedBox(width: FgSpace.sp3),
              Text(
                tiempo,
                style: FgText.num(FgText.label).copyWith(color: demorado ? FgColors.riesgoFg : FgColors.inkSoft),
              ),
              const SizedBox(width: FgSpace.sp2),
              const Icon(Icons.chevron_right, size: FgSize.iconoMd, color: FgColors.inkSoft),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Barras apiladas por día: entregados (verde) y cancelados o fallidos (rojo). El día de hoy va al
/// final y se nombra «Hoy». Cada barra se lee como texto para lectores de pantalla.
class _GraficaSemana extends StatelessWidget {
  const _GraficaSemana({required this.dias});

  final List<DiaOperacion> dias;

  static const _alto = 140.0;

  /// Alto fijo del número sobre la barra y de la etiqueta del día: así todas las barras y todos los
  /// días quedan sobre la misma línea.
  static const _cifra = 20.0, _etiqueta = 22.0;
  static const _nombres = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  static const _nombresLargos = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

  @override
  Widget build(BuildContext context) {
    final maximo = dias.fold<int>(0, (a, d) => d.total > a ? d.total : a);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: _alto + _cifra + FgSpace.sp2 + _etiqueta,
        child: LayoutBuilder(builder: (context, constraints) {
          // En pantallas angostas el día va solo con su número («15»): «dom 15» no cabe.
          final corto = constraints.maxWidth / dias.length < 64;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final (i, d) in dias.indexed)
              Expanded(child: _barra(d, maximo, esHoy: i == dias.length - 1, corto: corto)),
          ]);
        }),
      ),
      const SizedBox(height: FgSpace.sp3),
      const Wrap(spacing: FgSpace.sp5, runSpacing: FgSpace.sp2, children: [
        _Leyenda(color: FgColors.cumplidoSolid, texto: 'Entregados'),
        _Leyenda(color: FgColors.incumplidoSolid, texto: 'Cancelados o fallidos'),
      ]),
    ]);
  }

  Widget _barra(DiaOperacion d, int maximo, {required bool esHoy, required bool corto}) {
    double alto(int n) => maximo == 0 ? 0 : _alto * n / maximo;
    final nombre = esHoy ? 'Hoy' : (corto ? '${d.dia.day}' : '${_nombres[d.dia.weekday - 1]} ${d.dia.day}');
    final largo = esHoy ? 'Hoy' : '${_nombresLargos[d.dia.weekday - 1]} ${d.dia.day}';
    return Semantics(
      label: '$largo: ${d.entregados} entregados, ${d.noEntregados} cancelados o fallidos',
      excludeSemantics: true,
      child: Column(children: [
        // Número y barra comparten un área fija alineada abajo: la base de todas las barras coincide.
        SizedBox(
          height: _cifra + _alto,
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            SizedBox(
              height: _cifra,
              child: Text(d.total == 0 ? '' : '${d.total}', style: FgText.num(FgText.caption)),
            ),
            SizedBox(
              width: 28,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(FgRadius.sm),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (d.noEntregados > 0) Container(height: alto(d.noEntregados), color: FgColors.incumplidoSolid),
                  if (d.entregados > 0) Container(height: alto(d.entregados), color: FgColors.cumplidoSolid),
                  if (d.total == 0) Container(height: 2, color: FgColors.linea),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: FgSpace.sp2),
        SizedBox(
          height: _etiqueta,
          child: Text(
            nombre,
            style: FgText.caption.copyWith(
              color: esHoy ? FgColors.ink : FgColors.inkSoft,
              fontWeight: esHoy ? FgWeight.bold : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: FgSpace.sp2),
        Text(texto, style: FgText.caption),
      ]);
}

/// Acción del encabezado de un bloque: texto azul sin relleno a la derecha, para que termine
/// exactamente en el borde del contenido del bloque (como las cifras y las listas).
class _EnlaceEncabezado extends StatelessWidget {
  const _EnlaceEncabezado({required this.texto, required this.onPressed});

  final String texto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: FgColors.azul800,
          minimumSize: const Size(FgSize.tapMin, FgSize.tapMin),
          padding: const EdgeInsets.only(left: FgSpace.sp2),
          alignment: Alignment.centerRight,
          textStyle: FgText.label.copyWith(fontWeight: FgWeight.bold),
        ),
        child: Text(texto),
      );
}
