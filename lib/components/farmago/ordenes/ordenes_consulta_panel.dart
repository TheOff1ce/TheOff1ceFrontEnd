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
  });

  /// `null` mientras no hay respuesta (cargando) o en un bloqueo.
  final RespuestaOrdenes? respuesta;
  final bool cargando;
  final bool lento;
  final VoidCallback? onRecargar;

  /// «Ver cuáles»: solo con 2 o más órdenes. Activa el filtro y desplaza hasta la lista.
  final VoidCallback? onVerElegibles;

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
                  _Cifras(respuesta: r, onVerElegibles: onVerElegibles),
                  const SizedBox(height: FgSpace.sp4),
                  FgEntrada(
                    retraso: FgMotion.escalon * 3,
                    child: _FilaConsulta(consultadoEn: r.consultadoEn, onRecargar: onRecargar, compacto: compacto),
                  ),
                  // El descargo vive con la hora de la consulta, no en un bloque aparte antes de las órdenes.
                  const SizedBox(height: FgSpace.sp3),
                  const Text(OrdenesTextos.notaEps, style: FgText.caption),
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

/// Una sola cifra: los medicamentos que se pueden pedir a domicilio, que es lo que lleva a la acción.
/// Lo demás (por autorizar, vigentes, vencidas) ya está en los filtros y en los grupos de la lista.
/// Sin elegibles no hay cifra: solo la frase que lo dice.
class _Cifras extends StatelessWidget {
  const _Cifras({required this.respuesta, this.onVerElegibles});

  final RespuestaOrdenes respuesta;
  final VoidCallback? onVerElegibles;

  @override
  Widget build(BuildContext context) {
    final elegibles = respuesta.totalElegibles;
    if (elegibles == 0) return const Text(OrdenesTextos.sinElegibles, style: FgText.bodyLg);
    final compacto = FgBreakpoint.esCompacto(MediaQuery.sizeOf(context).width);
    final etiqueta = OrdenesTextos.cifraElegibles(elegibles);
    final numero = FgConteo(
      valor: elegibles,
      style: FgText.display,
      semantica: '$elegibles $etiqueta',
    );
    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: FgText.bodyLg),
        // El enlace trae 8 px de relleno para su área táctil: se corre para alinear su texto.
        if (respuesta.ordenes.length >= 2 && onVerElegibles != null)
          Transform.translate(
            offset: const Offset(-FgSpace.sp2, 0),
            child: FgLinkButton(label: OrdenesTextos.verCuales, onPressed: onVerElegibles),
          ),
      ],
    );
    return Row(
      crossAxisAlignment: compacto ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        ConstrainedBox(constraints: const BoxConstraints(minWidth: FgSpace.sp7), child: numero),
        const SizedBox(width: FgSpace.sp4),
        Expanded(child: Padding(padding: EdgeInsets.only(top: compacto ? FgSpace.sp1 : 0), child: texto)),
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
    final hora = consultadoEn == null ? null : OrdenesTextos.consultadoEl(PendienteFormat.fechaHora(consultadoEn!));
    // Es una foto de lo que la EPS respondió a esa hora, no un flujo continuo: sin punto «en vivo».
    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(OrdenesTextos.respuestaDeEps, style: FgText.label),
        if (hora != null) Text(hora, style: FgText.num(FgText.caption.copyWith(color: FgColors.ink))),
      ],
    );
    final boton = FgButton(
      label: OrdenesTextos.recargar,
      icon: Icons.refresh,
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
          const ExcludeSemantics(child: Icon(Icons.schedule_outlined, size: FgSize.iconoMd, color: FgColors.azul800)),
        compacto ? SizedBox(width: double.infinity, child: texto) : texto,
        compacto ? SizedBox(width: double.infinity, child: boton) : boton,
      ],
    );
  }
}
