import 'package:flutter/material.dart';

import '../../../app/theme/farmago_tokens.dart';
import '../../../hooks/domicilio_orden_controller.dart';
import '../../../types/ordenes.dart';
import '../buttons.dart';
import '../deadline_ring.dart';
import '../feedback.dart';
import '../inputs.dart';
import '../sello_estado.dart';
import 'ordenes_textos.dart';

/// Cómo se cerró el diálogo de domicilio.
enum SalidaDomicilio { cerrar, seguirEnDomicilios }

/// Abre «Pedir a domicilio»: diálogo de 640 en tablet y desktop, hoja inferior (máx. 90 %) en móvil.
/// Un solo modal: las fases reemplazan el contenido dentro de la misma ventana (§7.1, regla 2).
Future<SalidaDomicilio?> mostrarDomicilioOrden(BuildContext context, DomicilioOrdenController controlador) {
  final compacto = FgBreakpoint.esCompacto(MediaQuery.sizeOf(context).width);
  if (compacto) {
    return showModalBottomSheet<SalidaDomicilio>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: FgColors.scrim,
      elevation: 0,
      sheetAnimationStyle: AnimationStyle(
        duration: FgMotion.reducir(context, FgMotion.lenta),
        reverseDuration: FgMotion.reducir(context, FgMotion.media),
        curve: FgMotion.ease,
        reverseCurve: FgMotion.easeSalida,
      ),
      builder: (contexto) => FarmaGoThemed(
        child: _Contenido(controlador: controlador, compacto: true),
      ),
    );
  }
  return showGeneralDialog<SalidaDomicilio>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: FgColors.scrim,
    transitionDuration: FgMotion.reducir(context, FgMotion.media),
    pageBuilder: (contexto, _, __) => FarmaGoThemed(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: FgSize.dialogMd,
            maxHeight: MediaQuery.sizeOf(contexto).height - FgSpace.sp8 - FgSpace.sp5 * 2,
          ),
          child: _Contenido(controlador: controlador, compacto: false),
        ),
      ),
    ),
    transitionBuilder: (contexto, animacion, _, hijo) {
      final curva = CurvedAnimation(parent: animacion, curve: FgMotion.ease, reverseCurve: FgMotion.easeSalida);
      return FadeTransition(
        opacity: curva,
        child: ScaleTransition(scale: Tween<double>(begin: .96, end: 1).animate(curva), child: hijo),
      );
    },
  );
}

class _Contenido extends StatefulWidget {
  const _Contenido({required this.controlador, required this.compacto});

  final DomicilioOrdenController controlador;
  final bool compacto;

  @override
  State<_Contenido> createState() => _ContenidoState();
}

class _ContenidoState extends State<_Contenido> {
  @override
  void initState() {
    super.initState();
    // Después del primer fotograma: verificar notifica a los oyentes y no debe ocurrir al construir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controlador.verificar();
    });
  }

  void _cerrar([SalidaDomicilio salida = SalidaDomicilio.cerrar]) => Navigator.of(context).pop(salida);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controlador,
        builder: (context, _) {
          final c = widget.controlador;
          final radio = widget.compacto
              ? const BorderRadius.vertical(top: Radius.circular(FgRadius.lg))
              : BorderRadius.circular(FgRadius.lg);
          final relleno = widget.compacto ? FgSpace.sp4h : FgSpace.sp6;
          return PopScope(
            canPop: c.sePuedeCerrar,
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: 'Pedir a domicilio',
              // La sombra va fuera del recorte: dentro, oscurecería el cuerpo de la ventana.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radio,
                  boxShadow: widget.compacto ? FgShadow.eArriba : FgShadow.e4,
                ),
                child: Material(
                  color: FgColors.superficie,
                  shape: RoundedRectangleBorder(borderRadius: radio),
                  clipBehavior: Clip.antiAlias,
                  elevation: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.compacto) const _Asa(),
                      _Encabezado(controlador: c, relleno: relleno, onCerrar: c.sePuedeCerrar ? _cerrar : null),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(relleno, 0, relleno, FgSpace.sp5),
                          child: _Cuerpo(controlador: c),
                        ),
                      ),
                      _Pie(controlador: c, compacto: widget.compacto, relleno: relleno, onSalir: _cerrar),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _Asa extends StatelessWidget {
  const _Asa();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: FgSpace.sp3),
        child: Center(
          child: ExcludeSemantics(
            child: Container(
              width: FgSize.simboloM,
              height: FgBorder.w4,
              decoration: BoxDecoration(color: FgColors.lineaControl, borderRadius: BorderRadius.circular(FgRadius.pill)),
            ),
          ),
        ),
      );
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.controlador, required this.relleno, required this.onCerrar});

  final DomicilioOrdenController controlador;
  final double relleno;
  final VoidCallback? onCerrar;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(relleno, FgSpace.sp5, relleno - (onCerrar == null ? 0 : FgSpace.sp2), FgSpace.sp4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(header: true, child: const Text(OrdenesTextos.pedirADomicilio, style: FgText.h2)),
                  Text(OrdenesTextos.ordenId(controlador.orden.id), style: FgText.num(FgText.caption)),
                ],
              ),
            ),
            if (onCerrar != null) FgIconButton(icon: Icons.close_rounded, tooltip: 'Cerrar', onPressed: onCerrar),
          ],
        ),
      );
}

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.controlador});

  final DomicilioOrdenController controlador;

  MedicamentoOrden? _med(String id) {
    for (final m in controlador.orden.medicamentos) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = controlador;
    final n = c.medicamentoIds.length;
    switch (c.fase) {
      case FaseDomicilio.verificando:
        return _Lista(
          introduccion: 'Revisando con tu EPS que sigan disponibles…',
          nota: 'Antes de enviar, volvemos a consultar a tu EPS. Si algo cambió, te avisamos y no enviamos nada.',
          filas: [for (final id in c.medicamentoIds) _Fila(nombre: _med(id)?.nombre ?? id, estado: _EstadoFila.consultando)],
        );
      case FaseDomicilio.listo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Lista(
              introduccion: 'Tu EPS confirma ${n == 1 ? 'tu medicamento' : 'tus $n medicamentos'}.',
              filas: [
                for (final (i, id) in c.medicamentoIds.indexed)
                  _Fila(nombre: _med(id)?.nombre ?? id, estado: i < c.revelados ? _EstadoFila.confirmado : _EstadoFila.consultando),
              ],
            ),
            const SizedBox(height: FgSpace.sp4),
            _CampoDireccion(controlador: c),
          ],
        );
      case FaseDomicilio.enviando:
        return _Lista(
          introduccion: 'Confirmando con tu EPS y enviando…',
          filas: [for (final id in c.medicamentoIds) _Fila(nombre: _med(id)?.nombre ?? id, estado: _EstadoFila.enviando)],
        );
      case FaseDomicilio.listoConCambios:
      case FaseDomicilio.cambio:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FgBanner(
              kind: FgBannerKind.aviso,
              title: 'Tu EPS cambió algo mientras elegías',
              message: 'No enviamos nada. Actualizamos la orden con lo que informa tu EPS ahora.',
            ),
            if (c.cambios.isNotEmpty) ...[
              const SizedBox(height: FgSpace.sp4),
              for (final cambio in c.cambios)
                Padding(
                  padding: const EdgeInsets.only(bottom: FgSpace.sp3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_med(cambio.id)?.nombre ?? cambio.id, style: FgText.h3),
                      Text(
                        OrdenesTextos.frasesMotivos(cambio.motivos) ?? 'Tu EPS no lo reporta como disponible.',
                        style: FgText.caption,
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      case FaseDomicilio.exito:
        return _Exito(cantidad: n, referencia: c.referencia ?? '');
      case FaseDomicilio.vencida:
        return const FgBanner(
          kind: FgBannerKind.aviso,
          title: 'Esta orden venció mientras elegías',
          message: 'No enviamos nada. La orden queda solo para consulta y ya no se puede pedir a domicilio.',
        );
      case FaseDomicilio.errorEnvio:
        final rechazado = c.error?.code == 'DOMICILIO_RECHAZADO';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FgBanner(
              kind: FgBannerKind.error,
              title: 'No pudimos enviar tu pedido',
              message: rechazado ? c.error!.userMessage : 'Domicilios no respondió. Tu selección sigue lista: vuelve a intentarlo.',
            ),
            const SizedBox(height: FgSpace.sp4),
            _CampoDireccion(controlador: c),
          ],
        );
      case FaseDomicilio.errorVerificar:
        return const FgBanner(
          kind: FgBannerKind.error,
          title: 'No pudimos confirmar con tu EPS',
          message: 'No enviamos nada. Vuelve a intentarlo.',
        );
    }
  }
}

/// Dirección de entrega, precargada con la del perfil. Sin una válida no se puede confirmar.
class _CampoDireccion extends StatefulWidget {
  const _CampoDireccion({required this.controlador});

  final DomicilioOrdenController controlador;

  @override
  State<_CampoDireccion> createState() => _CampoDireccionState();
}

class _CampoDireccionState extends State<_CampoDireccion> {
  late final _texto = TextEditingController(text: widget.controlador.direccionEntrega);

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controlador;
    final vacia = c.direccionEntrega.trim().isEmpty;
    return FgTextField(
      label: 'Dirección de entrega',
      controller: _texto,
      ayuda: 'Calle, número y ciudad. Ahí te llevamos el pedido.',
      error: vacia || c.direccionValida ? null : 'Escribe la dirección completa, por ejemplo «Calle 100 # 15-20, Bogotá».',
      keyboardType: TextInputType.streetAddress,
      autofillHints: const [AutofillHints.fullStreetAddress],
      onChanged: c.cambiarDireccion,
    );
  }
}

enum _EstadoFila { consultando, confirmado, enviando }

class _Lista extends StatelessWidget {
  const _Lista({required this.introduccion, required this.filas, this.nota});

  final String introduccion;
  final String? nota;
  final List<Widget> filas;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(liveRegion: true, child: Text(introduccion, style: FgText.body)),
          const SizedBox(height: FgSpace.sp4),
          ...filas,
          if (nota != null) ...[const SizedBox(height: FgSpace.sp2), FgNota(texto: nota!)],
        ],
      );
}

class _Fila extends StatelessWidget {
  const _Fila({required this.nombre, required this.estado});

  final String nombre;
  final _EstadoFila estado;

  @override
  Widget build(BuildContext context) {
    final confirmado = estado == _EstadoFila.confirmado;
    final leyenda = switch (estado) {
      _EstadoFila.consultando => 'Consultando a tu EPS…',
      _EstadoFila.confirmado => 'Tu EPS confirma que puedes pedirlo',
      _EstadoFila.enviando => 'Enviando…',
    };
    return Container(
      constraints: const BoxConstraints(minHeight: FgSize.filaTabla),
      padding: const EdgeInsets.symmetric(vertical: FgSpace.sp2),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: FgColors.linea, width: FgBorder.w1))),
      child: Row(
        children: [
          SizedBox(
            width: FgSize.anilloSello,
            height: FgSize.anilloSello,
            child: AnimatedSwitcher(
              duration: FgMotion.reducir(context, FgMotion.media),
              switchInCurve: FgMotion.ease,
              transitionBuilder: (hijo, animacion) => FadeTransition(
                opacity: animacion,
                child: ScaleTransition(scale: Tween<double>(begin: .6, end: 1).animate(animacion), child: hijo),
              ),
              child: confirmado
                  ? const FgGlifo(
                      key: ValueKey('ok'),
                      color: FgColors.cumplidoSolid,
                      simbolo: Icons.check,
                      diametro: FgSize.anilloSello,
                    )
                  : const FgSpinner(key: ValueKey('espera')),
            ),
          ),
          const SizedBox(width: FgSpace.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: FgText.label.copyWith(fontWeight: FontWeight.w700)),
                Text(leyenda, style: FgText.caption.copyWith(color: confirmado ? FgColors.cumplidoFg : FgColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Exito extends StatelessWidget {
  const _Exito({required this.cantidad, required this.referencia});

  final int cantidad;
  final String referencia;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: FgMotion.reducir(context, FgMotion.reloj),
                curve: FgMotion.ease,
                builder: (context, v, _) => AnilloMarca(
                  forma: FormaAnillo.parcial,
                  color: FgColors.cumplidoSolid,
                  diametro: DeadlineRingSize.s.lado,
                  trazo: DeadlineRingSize.s.trazo,
                  fraccion: v,
                  centro: Opacity(
                    opacity: v,
                    child: const Icon(Icons.check_rounded, size: FgSize.simboloS, color: FgColors.cumplidoSolid),
                  ),
                ),
              ),
            ),
            const SizedBox(height: FgSpace.sp4),
            Text(OrdenesTextos.envioExitoso(cantidad), style: FgText.h2),
            const SizedBox(height: FgSpace.sp2),
            Text(
              'Tu EPS confirmó que puedes pedirlos. Ahora sigues en Domicilios para elegir la entrega.',
              style: FgText.body.copyWith(color: FgColors.inkSoft),
            ),
            const SizedBox(height: FgSpace.sp5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(FgSpace.sp4),
              decoration: BoxDecoration(color: FgColors.fondoHundido, borderRadius: BorderRadius.circular(FgRadius.sm)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Referencia del pedido', style: FgText.caption),
                  Text(referencia, style: FgText.num(FgText.cifra)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Pie extends StatelessWidget {
  const _Pie({required this.controlador, required this.compacto, required this.relleno, required this.onSalir});

  final DomicilioOrdenController controlador;
  final bool compacto;
  final double relleno;
  final void Function([SalidaDomicilio salida]) onSalir;

  @override
  Widget build(BuildContext context) {
    final c = controlador;
    final size = compacto ? FgButtonSize.lg : FgButtonSize.md;
    FgButton secundario(String etiqueta, [VoidCallback? accion]) => FgButton(
          label: etiqueta,
          variant: FgButtonVariant.secondary,
          size: size,
          expand: compacto,
          onPressed: accion ?? () => onSalir(),
        );
    FgButton primario(String etiqueta, VoidCallback? accion, {bool cargando = false, String? cargandoEtiqueta}) =>
        FgButton(
          label: etiqueta,
          size: size,
          expand: compacto,
          loading: cargando,
          loadingLabel: cargandoEtiqueta,
          onPressed: accion,
        );
    final List<Widget> botones = switch (c.fase) {
      FaseDomicilio.verificando => [secundario('Cancelar'), primario(OrdenesTextos.confirmarPedido, null, cargando: true, cargandoEtiqueta: 'Verificando…')],
      FaseDomicilio.listo => [secundario('Cancelar'), primario(OrdenesTextos.confirmarPedido, c.direccionValida ? c.confirmar : null)],
      FaseDomicilio.listoConCambios || FaseDomicilio.cambio => [primario('Volver a elegir', () => onSalir())],
      FaseDomicilio.enviando => [primario(OrdenesTextos.confirmarPedido, null, cargando: true, cargandoEtiqueta: 'Enviando…')],
      FaseDomicilio.exito => [
          secundario('Volver a mis órdenes'),
          primario('Seguir en Domicilios', () => onSalir(SalidaDomicilio.seguirEnDomicilios)),
        ],
      FaseDomicilio.vencida => [primario('Entendido', () => onSalir())],
      FaseDomicilio.errorEnvio => [secundario('Cancelar'), primario('Reintentar', c.direccionValida ? c.confirmar : null)],
      FaseDomicilio.errorVerificar => [secundario('Cancelar'), primario('Reintentar', c.verificar)],
    };
    return Container(
      padding: EdgeInsets.fromLTRB(relleno, FgSpace.sp4, relleno, compacto ? FgSpace.sp4 : FgSpace.sp5),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: FgColors.linea, width: FgBorder.w1))),
      child: compacto
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Primario arriba, secundario debajo (manual §7.2).
                for (final (i, b) in botones.reversed.indexed) ...[if (i > 0) const SizedBox(height: FgSpace.sp3), b],
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [for (final (i, b) in botones.indexed) ...[if (i > 0) const SizedBox(width: FgSpace.sp4), b]],
            ),
    );
  }
}
