import 'package:flutter/material.dart';

import '../app/theme/farmago_tokens.dart';
import '../components/farmago/buttons.dart';
import '../components/farmago/entrada.dart';
import '../components/farmago/feedback.dart';
import '../components/farmago/layout.dart';
import '../components/farmago/ordenes/domicilio_orden_sheet.dart';
import '../components/farmago/ordenes/domicilio_seleccion_bar.dart';
import '../components/farmago/ordenes/orden_card.dart';
import '../components/farmago/ordenes/ordenes_consulta_panel.dart';
import '../components/farmago/ordenes/ordenes_textos.dart';
import '../hooks/ordenes_controller.dart';
import '../types/ordenes.dart';

/// Órdenes y autorizaciones: lo que la EPS respondió ahora, y desde aquí el pedido a domicilio.
///
/// La pantalla solo compone: el estado vive en [OrdenesController]. Cada visita consulta de nuevo a
/// la EPS y nada se guarda al salir (el controlador pertenece a esta pantalla).
class OrdenesPage extends StatefulWidget {
  const OrdenesPage({
    super.key,
    required this.createController,
    required this.onBack,
    required this.onRevisarDatos,
    required this.onSeguirEnDomicilios,
    this.ordenEnlace,
  });

  final OrdenesController Function() createController;
  final VoidCallback onBack;

  /// «Revisar mis datos»: destino pendiente del equipo (D9). Mientras tanto, la cuenta.
  final VoidCallback onRevisarDatos;

  /// «Seguir en Domicilios»: destino pendiente del equipo (D9).
  final VoidCallback onSeguirEnDomicilios;

  /// Enlace profundo `/ordenes/:ordenId`.
  final String? ordenEnlace;

  @override
  State<OrdenesPage> createState() => _OrdenesPageState();
}

class _OrdenesPageState extends State<OrdenesPage> {
  late final OrdenesController _c = widget.createController();
  final _claveLista = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Después del primer fotograma: cargar notifica a los oyentes y no debe ocurrir al construir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.recargar(ordenEnlace: widget.ordenEnlace);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _verCuales(FiltroOrdenes filtro) {
    _c.cambiarFiltro(filtro);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contexto = _claveLista.currentContext;
      if (contexto != null && contexto.mounted) {
        Scrollable.ensureVisible(contexto, duration: FgMotion.reducir(contexto, FgMotion.lenta), curve: FgMotion.ease);
      }
    });
  }

  Future<void> _pedir() async {
    if (_c.ordenSeleccionada == null) return;
    final dialogo = _c.nuevoDomicilio();
    final salida = await mostrarDomicilioOrden(context, dialogo);
    if (!mounted) {
      dialogo.dispose();
      return;
    }
    _c.aplicarResultado(dialogo);
    dialogo.dispose();
    if (salida == SalidaDomicilio.seguirEnDomicilios) widget.onSeguirEnDomicilios();
  }

  @override
  Widget build(BuildContext context) => FarmaGoThemed(
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) {
            final ancho = MediaQuery.sizeOf(context).width;
            final compacto = FgBreakpoint.esCompacto(ancho);
            final seleccion = _c.seleccion;
            final orden = _c.ordenSeleccionada;
            return FgScreen(
              titulo: OrdenesTextos.tituloPantalla,
              onBack: widget.onBack,
              onRefresh: _c.recargar,
              tituloEnContenido: false,
              anchoMaximo: FgSize.contenidoPaciente,
              barraAccionConEntrada: true,
              barraAccion: seleccion == null || orden == null
                  ? null
                  : DomicilioSeleccionBar(
                      cantidad: seleccion.ids.length,
                      ordenId: orden.id,
                      avisoUnaOrden: _c.seleccionCambioDeOrden,
                      onQuitar: _c.quitarSeleccion,
                      onPedir: _pedir,
                    ),
              children: [
                _Cuerpo(
                  c: _c,
                  compacto: compacto,
                  claveLista: _claveLista,
                  onVerCuales: _verCuales,
                  onRevisarDatos: widget.onRevisarDatos,
                ),
                // La barra de pedido puede ser más alta que los 88 px que reserva el marco.
                if (seleccion != null) const SizedBox(height: FgSpace.sp8),
              ],
            );
          },
        ),
      );
}

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({
    required this.c,
    required this.compacto,
    required this.claveLista,
    required this.onVerCuales,
    required this.onRevisarDatos,
  });

  final OrdenesController c;
  final bool compacto;
  final GlobalKey claveLista;
  final ValueChanged<FiltroOrdenes> onVerCuales;
  final VoidCallback onRevisarDatos;

  @override
  Widget build(BuildContext context) {
    final vista = c.vista;
    final separacion = compacto ? FgSpace.sp6 : FgSpace.sp7;
    final respuesta = c.respuesta;
    final conDatos = vista is ConOrdenes || vista is Vacio;
    final dosOMas = (respuesta?.ordenes.length ?? 0) >= 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FgEntrada(
          key: ValueKey('panel-${c.entradaId}-${vista.runtimeType}'),
          child: switch (vista) {
            Bloqueado() || ErrorConsulta() => const _TituloSolo(),
            _ => OrdenesConsultaPanel(
                respuesta: respuesta,
                cargando: vista is Cargando,
                lento: vista is Cargando && vista.lento,
                onRecargar: vista is Cargando ? null : c.recargar,
                onVerElegibles: dosOMas ? () => onVerCuales(FiltroOrdenes.domicilio) : null,
                onVerPorAutorizar: dosOMas ? () => onVerCuales(FiltroOrdenes.porAutorizar) : null,
              ),
          },
        ),
        if (conDatos) ...[
          const SizedBox(height: FgSpace.sp5),
          FgEntrada(
            key: ValueKey('nota-${c.entradaId}'),
            retraso: FgMotion.escalon * 4,
            child: const FgNota(texto: OrdenesTextos.notaEps),
          ),
        ],
        if (c.exito case final exito?) ...[
          const SizedBox(height: FgSpace.sp5),
          FgBanner(
            kind: FgBannerKind.exito,
            title: OrdenesTextos.envioExitoso(exito.cantidad),
            message: 'Referencia ${exito.referencia}. Recarga para ver lo que tu EPS informa ahora.',
            actionLabel: OrdenesTextos.recargar,
            onAction: c.recargar,
          ),
        ],
        if (c.ordenNoDisponible) ...[
          const SizedBox(height: FgSpace.sp5),
          const FgBanner(kind: FgBannerKind.info, message: 'Esa orden ya no está disponible.'),
        ],
        SizedBox(height: separacion),
        switch (vista) {
          Cargando() => const _EsqueletoOrdenes(),
          Vacio() => const FgEntrada(
              child: FgEmptyState(titulo: OrdenesTextos.vacioTitulo, mensaje: OrdenesTextos.vacioMensaje),
            ),
          ConOrdenes() => _Ordenes(c: c, compacto: compacto, claveLista: claveLista, separacion: separacion),
          Bloqueado() => _BloqueoVista(vista: vista, c: c, onRevisarDatos: onRevisarDatos),
          ErrorConsulta() => _ErrorVista(vista: vista, c: c),
        },
      ],
    );
  }
}

/// El `<h1>` cuando no hay panel (bloqueo o error): sigue habiendo uno solo por pantalla.
class _TituloSolo extends StatelessWidget {
  const _TituloSolo();

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(OrdenesTextos.tituloPanel, style: FgText.h1(MediaQuery.sizeOf(context).width)),
      );
}

class _EsqueletoOrdenes extends StatelessWidget {
  const _EsqueletoOrdenes();

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          FgSkeleton(alto: 200, radio: FgRadius.md),
          SizedBox(height: FgSpace.sp4),
          FgSkeleton(alto: 200, radio: FgRadius.md),
        ],
      );
}

class _Ordenes extends StatelessWidget {
  const _Ordenes({required this.c, required this.compacto, required this.claveLista, required this.separacion});

  final OrdenesController c;
  final bool compacto;
  final GlobalKey claveLista;
  final double separacion;

  @override
  Widget build(BuildContext context) {
    final respuesta = c.respuesta!;
    final visibles = c.visibles;
    final grupos = <(String, String?, List<Orden>)>[
      (OrdenesTextos.vigentes, null, [for (final o in visibles) if (o.vigencia != Vigencia.vencida && o.vencimiento != null) o]),
      (OrdenesTextos.sinVencimiento, null, [for (final o in visibles) if (o.vigencia != Vigencia.vencida && o.vencimiento == null) o]),
      (OrdenesTextos.vencidasGrupo, OrdenesTextos.soloConsulta, [for (final o in visibles) if (o.vigencia == Vigencia.vencida) o]),
    ];
    var k = 0;
    final hueco = compacto ? FgSpace.sp4 : FgSpace.sp5;
    final lista = <Widget>[];
    for (final (titulo, ayuda, ordenes) in grupos) {
      if (ordenes.isEmpty) continue;
      lista.add(
        FgEntrada(
          key: ValueKey('${c.entradaId}-${c.filtroId}-g-$titulo'),
          retraso: _retrasoTarjeta(k) - FgMotion.escalon,
          child: _EncabezadoGrupo(titulo: titulo, cantidad: ordenes.length, ayuda: ayuda),
        ),
      );
      lista.add(SizedBox(height: hueco));
      for (final orden in ordenes) {
        final indice = k++;
        lista.add(
          FgEntrada(
            key: ValueKey('${c.entradaId}-${c.filtroId}-${orden.id}'),
            retraso: _retrasoTarjeta(indice),
            child: OrdenCard(
              orden: orden,
              consultadoEn: respuesta.consultadoEn,
              marcados: c.seleccion?.ordenId == orden.id ? c.seleccion!.ids : const {},
              actualizados: c.actualizados,
              retrasoBase: _retrasoTarjeta(indice),
              onAlternar: (m) => c.alternar(orden, m),
              onElegirTodos: () => c.elegirTodos(orden),
            ),
          ),
        );
        lista.add(SizedBox(height: hueco));
      }
      lista.add(SizedBox(height: separacion - hueco));
    }
    return Column(
      key: claveLista,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (respuesta.ordenes.length >= 2) ...[
          FgEntrada(
            key: ValueKey('filtros-${c.entradaId}'),
            retraso: FgMotion.escalon * 2,
            child: _Filtros(c: c, compacto: compacto),
          ),
          SizedBox(height: separacion),
        ],
        if (visibles.isEmpty)
          const FgEmptyState(titulo: OrdenesTextos.sinResultadosTitulo, mensaje: OrdenesTextos.sinResultadosMensaje),
        ...lista,
      ],
    );
  }

  /// 180 ms + k × 60 ms, con tope k = 6.
  static Duration _retrasoTarjeta(int k) => FgMotion.escalon * 3 + FgMotion.escalon * (k < 6 ? k : 6);
}

class _EncabezadoGrupo extends StatelessWidget {
  const _EncabezadoGrupo({required this.titulo, required this.cantidad, this.ayuda});

  final String titulo;
  final int cantidad;
  final String? ayuda;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: titulo),
                  TextSpan(text: '  $cantidad', style: FgText.num(FgText.h2.copyWith(color: FgColors.inkSoft))),
                ],
              ),
              style: FgText.h2,
            ),
          ),
          if (ayuda != null) Text(ayuda!, style: FgText.caption),
        ],
      );
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.c, required this.compacto});

  final OrdenesController c;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      for (final f in FiltroOrdenes.values)
        if (f == FiltroOrdenes.todas || c.conteo(f) > 0 || c.filtro == f)
          FgChip(
            label: '${OrdenesTextos.filtro(f)} (${c.conteo(f)})',
            selected: c.filtro == f,
            // El paciente usa siempre el chip de 48 px (§8.6 permite 40 solo en desktop denso).
            compacto: false,
            onPressed: () => c.cambiarFiltro(f),
          ),
    ];
    final fila = Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (final (i, chip) in chips.indexed) ...[if (i > 0) const SizedBox(width: FgSpace.sp2), chip]],
    );
    if (!compacto) return Align(alignment: Alignment.centerLeft, child: Wrap(spacing: FgSpace.sp2, runSpacing: FgSpace.sp2, children: chips));
    // Única excepción del manual: los chips se desplazan en horizontal en móvil.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(vertical: FgSpace.sp2),
      child: fila,
    );
  }
}

class _BloqueoVista extends StatelessWidget {
  const _BloqueoVista({required this.vista, required this.c, required this.onRevisarDatos});

  final Bloqueado vista;
  final OrdenesController c;
  final VoidCallback onRevisarDatos;

  @override
  Widget build(BuildContext context) {
    final Widget bloque;
    switch (vista.tipo) {
      case BloqueoTipo.rectificar:
        bloque = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FgBanner(
              kind: FgBannerKind.aviso,
              title: 'Tu EPS no encuentra tu documento',
              message: 'Revisa que el tipo y número de documento de tu cuenta estén bien.'
                  '${vista.documento == null ? '' : ' Hoy tienes registrado ${vista.documento}.'}',
            ),
            const SizedBox(height: FgSpace.sp4),
            Wrap(
              spacing: FgSpace.sp4,
              runSpacing: FgSpace.sp3,
              children: [
                FgButton(label: 'Revisar mis datos', onPressed: onRevisarDatos),
                FgButton(label: 'Volver a consultar', variant: FgButtonVariant.secondary, onPressed: c.recargar),
              ],
            ),
          ],
        );
      case BloqueoTipo.contactarEps:
        final titulo = switch (vista.codigo) {
          'AFILIACION_SUSPENDIDA' => 'Tu EPS reporta tu afiliación como suspendida',
          'AFILIACION_RETIRADA' => 'Tu EPS reporta tu afiliación como retirada',
          _ => 'Tu EPS reporta que tu afiliación no está activa',
        };
        bloque = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FgBanner(
              kind: FgBannerKind.info,
              title: titulo,
              message: 'Para ver tus órdenes aquí, comunícate con tu EPS. Este dato no se puede cambiar desde FarmaGo.',
            ),
            const SizedBox(height: FgSpace.sp4),
            FgButton(label: 'Volver a consultar', variant: FgButtonVariant.secondary, onPressed: c.recargar),
          ],
        );
      case BloqueoTipo.sinDocumento:
        bloque = const FgBanner(
          kind: FgBannerKind.info,
          title: 'Tu cuenta aún no tiene un documento asociado',
          message: 'Cuando tu cuenta tenga tu documento, aquí verás tus órdenes de medicamentos.',
        );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: bloque),
    );
  }
}

class _ErrorVista extends StatelessWidget {
  const _ErrorVista({required this.vista, required this.c});

  final ErrorConsulta vista;
  final OrdenesController c;

  @override
  Widget build(BuildContext context) {
    final sinAcceso = vista.error.code == 'ROL_NO_PERMITIDO';
    final Widget bloque = sinAcceso
        ? const FgBanner(kind: FgBannerKind.info, message: 'Esta sección es solo para pacientes.')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FgBanner(
                kind: FgBannerKind.error,
                title: 'No pudimos consultar tu EPS en este momento',
                message: 'Para no mostrarte datos viejos, no vemos consultas anteriores. Vuelve a intentarlo en unos minutos.',
                referencia: vista.error.showsReference ? vista.error.referenceId : null,
              ),
              const SizedBox(height: FgSpace.sp4),
              FgButton(label: 'Reintentar', onPressed: c.recargar),
            ],
          );
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: bloque),
    );
  }
}
