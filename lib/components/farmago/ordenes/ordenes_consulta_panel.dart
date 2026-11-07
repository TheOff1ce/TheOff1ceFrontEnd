import 'package:flutter/material.dart';

import '../../../app/theme/farmago_tokens.dart';
import '../../../types/ordenes.dart';
import '../../../utils/pendiente_format.dart';
import '../buttons.dart';
import '../entrada.dart';
import '../feedback.dart';
import 'ordenes_textos.dart';

/// Panel de consulta: lo que la EPS acaba de responder. Es el foco de la pantalla (D3).
///
/// `azul100` con el filete de marca de 4 px arriba, sin texto encima. Contiene el único `<h1>`, las
/// cifras que el backend ya entregó (sin recalcular reglas), la hora exacta de la consulta con el
/// punto «en vivo» y «Recargar». Mientras consulta, el filete se desplaza y aparecen esqueletos.
class OrdenesConsultaPanel extends StatelessWidget {
  const OrdenesConsultaPanel({
    super.key,
    required this.respuesta,
    required this.cargando,
    required this.lento,
    required this.onRecargar,
    this.onVerElegibles,
    this.onVerPorAutorizar,
  });

  /// `null` mientras no hay respuesta (cargando) o en un bloqueo.
  final RespuestaOrdenes? respuesta;
  final bool cargando;
  final bool lento;
  final VoidCallback? onRecargar;

  /// «Ver cuáles»: solo con 2 o más órdenes. Activa el filtro y desplaza hasta la lista.
  final VoidCallback? onVerElegibles;
  final VoidCallback? onVerPorAutorizar;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final compacto = FgBreakpoint.esCompacto(ancho);
    final r = respuesta;
    final relleno = compacto
        ? const EdgeInsets.fromLTRB(FgSpace.sp4h, FgSpace.sp5, FgSpace.sp4h, FgSpace.sp4h)
        : const EdgeInsets.all(FgSpace.sp6);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: FgColors.azul100, borderRadius: BorderRadius.circular(FgRadius.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FgFileteMarca(cargando: cargando),
          Padding(
            padding: relleno,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r != null && (r.eps != null || r.documentoEnmascarado != null)) ...[
                  _EpsYDocumento(eps: r.eps, documento: r.documentoEnmascarado),
                  const SizedBox(height: FgSpace.sp2),
                ],
                Semantics(header: true, child: Text(OrdenesTextos.tituloPanel, style: FgText.h1(ancho))),
                const SizedBox(height: FgSpace.sp5),
                if (cargando)
                  _Cargando(lento: lento, compacto: compacto)
                else if (r != null) ...[
                  _Cifras(respuesta: r, onVerElegibles: onVerElegibles, onVerPorAutorizar: onVerPorAutorizar),
                  const SizedBox(height: FgSpace.sp5),
                  FgEntrada(
                    retraso: FgMotion.escalon * 3,
                    child: _FilaConsulta(consultadoEn: r.consultadoEn, onRecargar: onRecargar, compacto: compacto),
                  ),
                ] else
                  _FilaConsulta(consultadoEn: null, onRecargar: onRecargar, compacto: compacto),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EpsYDocumento extends StatelessWidget {
  const _EpsYDocumento({required this.eps, required this.documento});

  final String? eps;
  final String? documento;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          children: [
            if (eps != null) TextSpan(text: eps, style: FgText.label.copyWith(fontWeight: FontWeight.w700)),
            if (eps != null && documento != null) const TextSpan(text: ' · '),
            if (documento != null) TextSpan(text: documento, style: FgText.num(FgText.caption.copyWith(color: FgColors.ink))),
          ],
        ),
        style: FgText.caption.copyWith(color: FgColors.ink),
      );
}

class _Cargando extends StatelessWidget {
  const _Cargando({required this.lento, required this.compacto});

  final bool lento;
  final bool compacto;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        label: lento ? '${OrdenesTextos.consultando} ${OrdenesTextos.consultandoLento}' : OrdenesTextos.consultando,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(
              child: Row(
                children: [
                  FgSpinner(),
                  SizedBox(width: FgSpace.sp3),
                  Flexible(child: Text(OrdenesTextos.consultando, style: FgText.bodyLg)),
                ],
              ),
            ),
            if (lento) ...[
              const SizedBox(height: FgSpace.sp2),
              ExcludeSemantics(
                child: Text(OrdenesTextos.consultandoLento, style: FgText.body.copyWith(color: FgColors.inkSoft)),
              ),
            ],
            const SizedBox(height: FgSpace.sp5),
            Wrap(
              spacing: FgSpace.sp5,
              runSpacing: FgSpace.sp4,
              children: [
                for (var i = 0; i < (compacto ? 2 : 3); i++)
                  const FgSkeleton(ancho: 190, alto: FgSize.ctrlLg + FgSpace.sp6, radio: FgRadius.sm),
              ],
            ),
          ],
        ),
      );
}

/// Cifras con filete superior de 2 px, en composición libre (no son tarjetas).
class _Cifras extends StatelessWidget {
  const _Cifras({required this.respuesta, this.onVerElegibles, this.onVerPorAutorizar});

  final RespuestaOrdenes respuesta;
  final VoidCallback? onVerElegibles;
  final VoidCallback? onVerPorAutorizar;

  static const _minimo = 190.0;

  @override
  Widget build(BuildContext context) {
    final elegibles = respuesta.totalElegibles;
    final porAutorizar = respuesta.totalPorAutorizar;
    final vigentes = respuesta.vigentes.length;
    final proximo = respuesta.proximoVencimiento;
    final cifras = <Widget>[
      if (elegibles > 0)
        _Cifra(
          valor: elegibles,
          etiqueta: OrdenesTextos.cifraElegibles(elegibles),
          filete: FgColors.azul600,
          onVer: respuesta.ordenes.length >= 2 ? onVerElegibles : null,
        ),
      if (porAutorizar > 0)
        _Cifra(
          valor: porAutorizar,
          etiqueta: OrdenesTextos.cifraPorAutorizar(porAutorizar),
          filete: FgColors.riesgoSolid,
          colorCifra: FgColors.riesgoFg,
          onVer: respuesta.ordenes.length >= 2 ? onVerPorAutorizar : null,
        ),
      _Cifra(
        valor: vigentes,
        etiqueta: OrdenesTextos.cifraVigentes(vigentes),
        filete: FgColors.azul200,
        detalle: proximo == null ? null : 'La próxima vence el ${PendienteFormat.fecha(proximo)}',
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        const hueco = FgSpace.sp5;
        final columnas = ((c.maxWidth + hueco) / (_minimo + hueco)).floor().clamp(1, cifras.length);
        final ancho = (c.maxWidth - hueco * (columnas - 1)) / columnas;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: hueco,
              runSpacing: FgSpace.sp5,
              children: [
                for (final (i, cifra) in cifras.indexed)
                  SizedBox(
                    width: ancho,
                    child: FgEntrada(retraso: FgMotion.escalon * i, child: _ConRetraso(indice: i, child: cifra)),
                  ),
              ],
            ),
            if (elegibles == 0) ...[
              const SizedBox(height: FgSpace.sp5),
              const Text(OrdenesTextos.sinElegibles, style: FgText.bodyLg),
            ],
          ],
        );
      },
    );
  }
}

/// Pasa el retraso del escalón al conteo de la cifra, para que empiece junto con su entrada.
class _ConRetraso extends InheritedWidget {
  const _ConRetraso({required this.indice, required super.child});

  final int indice;

  static Duration de(BuildContext context) =>
      FgMotion.escalon * (context.dependOnInheritedWidgetOfExactType<_ConRetraso>()?.indice ?? 0);

  @override
  bool updateShouldNotify(_ConRetraso old) => old.indice != indice;
}

class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.valor,
    required this.etiqueta,
    required this.filete,
    this.colorCifra = FgColors.ink,
    this.detalle,
    this.onVer,
  });

  final int valor;
  final String etiqueta;
  final Color filete;
  final Color colorCifra;
  final String? detalle;
  final VoidCallback? onVer;

  @override
  Widget build(BuildContext context) {
    final compacto = FgBreakpoint.esCompacto(MediaQuery.sizeOf(context).width);
    final numero = FgConteo(
      valor: valor,
      style: FgText.display.copyWith(color: colorCifra),
      semantica: '$valor $etiqueta',
      retraso: _ConRetraso.de(context),
    );
    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: FgText.body),
        if (detalle != null) Text(detalle!, style: FgText.num(FgText.caption)),
        // El enlace trae 8 px de relleno para su área táctil: se corre para alinear su texto.
        if (onVer != null)
          Transform.translate(
            offset: const Offset(-FgSpace.sp2, 0),
            child: FgLinkButton(label: OrdenesTextos.verCuales, onPressed: onVer),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: FgBorder.w2, color: filete),
        const SizedBox(height: FgSpace.sp3),
        // En móvil la cifra va junto a su texto: tres bloques apilados empujarían las órdenes fuera de la vista.
        if (compacto)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(constraints: const BoxConstraints(minWidth: FgSpace.sp7), child: numero),
              const SizedBox(width: FgSpace.sp3),
              Expanded(child: Padding(padding: const EdgeInsets.only(top: FgSpace.sp1), child: texto)),
            ],
          )
        else ...[
          numero,
          texto,
        ],
      ],
    );
  }
}

class _FilaConsulta extends StatelessWidget {
  const _FilaConsulta({required this.consultadoEn, required this.onRecargar, required this.compacto});

  final DateTime? consultadoEn;
  final VoidCallback? onRecargar;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final hora = consultadoEn == null ? null : 'Hecha el ${PendienteFormat.fechaHora(consultadoEn!)}';
    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FgPuntoEnVivo(),
            SizedBox(width: FgSpace.sp2),
            Flexible(child: Text(OrdenesTextos.consultaEnVivo, style: FgText.label)),
          ],
        ),
        if (hora != null) Text(hora, style: FgText.num(FgText.caption.copyWith(color: FgColors.ink))),
      ],
    );
    final boton = FgButton(
      label: OrdenesTextos.recargar,
      icon: Icons.refresh_rounded,
      variant: FgButtonVariant.secondary,
      onPressed: onRecargar,
      expand: compacto,
    );
    return Wrap(
      spacing: FgSpace.sp4,
      runSpacing: FgSpace.sp3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!compacto)
          const ExcludeSemantics(child: Icon(Icons.schedule_rounded, size: FgSize.iconoMd, color: FgColors.azul800)),
        compacto ? SizedBox(width: double.infinity, child: texto) : texto,
        compacto ? SizedBox(width: double.infinity, child: boton) : boton,
      ],
    );
  }
}
