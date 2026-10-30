import 'package:flutter/material.dart';

import '../../app/theme/farmago_tokens.dart';
import '../../hooks/pendiente_detail_controller.dart';
import '../../types/pendiente.dart';
import '../../utils/pendiente_format.dart';
import '../../utils/pendientes_rol.dart';
import '../../utils/plazo_vista.dart';
import '../farmago/buttons.dart';
import '../farmago/deadline_ring.dart';
import '../farmago/feedback.dart';
import '../farmago/layout.dart';
import '../farmago/status_badge.dart';

/// Contenido del detalle de un pendiente con sus estados de carga, error y datos.
///
/// Lo usan la pantalla de detalle (móvil) y el panel lateral (tablet y desktop).
class PendienteDetalleCuerpo extends StatelessWidget {
  const PendienteDetalleCuerpo({super.key, required this.controller, required this.rol});

  final PendienteDetailController controller;
  final PendientesRol? rol;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final detalle = controller.detalle;
          final error = controller.error;
          if (detalle == null) {
            if (error != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FgBanner(
                    kind: FgBannerKind.error,
                    title: 'No pudimos cargar el pendiente',
                    message: error.userMessage,
                    referencia: error.showsReference ? error.referenceId : null,
                  ),
                  if (error.retryable) ...[
                    const SizedBox(height: FgSpace.sp4),
                    FgButton(label: 'Reintentar', variant: FgButtonVariant.secondary, onPressed: controller.load),
                  ],
                ],
              );
            }
            return const _EsqueletoDetalle();
          }
          // Cada minuto se reconstruye el reloj; si el plazo venció y el backend aún no lo refleja,
          // se vuelve a consultar una vez.
          return MinuteTicker(
            onTick: controller.actualizarSiVencio,
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (error != null) ...[
                  FgBanner(
                    kind: FgBannerKind.error,
                    message: error.userMessage,
                    referencia: error.showsReference ? error.referenceId : null,
                  ),
                  const SizedBox(height: FgSpace.sp4),
                  FgButton(
                    label: 'Reintentar',
                    variant: FgButtonVariant.secondary,
                    onPressed: () => controller.load(silencioso: true),
                  ),
                  const SizedBox(height: FgSpace.sp5),
                ],
                PendienteDetalleVista(detalle: detalle, desdeCarga: controller.desdeCarga, rol: rol),
              ],
            ),
          );
        },
      );
}

/// Detalle de solo lectura: reloj y sello, datos, medicamentos y novedades.
class PendienteDetalleVista extends StatelessWidget {
  const PendienteDetalleVista({super.key, required this.detalle, required this.desdeCarga, required this.rol});

  final PendienteDetalle detalle;
  final Duration desdeCarga;
  final PendientesRol? rol;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final separacion = FgBreakpoint.esCompacto(ancho) ? FgSpace.sp6 : FgSpace.sp7;
    final p = detalle.resumen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Hero(resumen: p, desdeCarga: desdeCarga),
        SizedBox(height: separacion),
        _Seccion(titulo: 'Datos del pendiente', hijo: _Datos(resumen: p, rol: rol)),
        SizedBox(height: separacion),
        _Seccion(
          titulo: 'Medicamentos',
          hijo: Column(
            children: [
              for (final (indice, medicamento) in detalle.medicamentos.indexed) ...[
                if (indice > 0) const SizedBox(height: FgSpace.sp4),
                _MedicamentoTarjeta(medicamento: medicamento),
              ],
            ],
          ),
        ),
        SizedBox(height: separacion),
        _Seccion(
          titulo: 'Novedades',
          hijo: _Novedades(novedades: detalle.novedades, ahora: p.ahora(desdeCarga)),
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.hijo});

  final String titulo;
  final Widget hijo;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(titulo, style: FgText.h2)),
          const SizedBox(height: FgSpace.sp4),
          hijo,
        ],
      );
}

/// Bloque principal: reloj, sello destacado (uno por pantalla) y tiempo.
class _Hero extends StatelessWidget {
  const _Hero({required this.resumen, required this.desdeCarga});

  final PendienteResumen resumen;
  final Duration desdeCarga;

  @override
  Widget build(BuildContext context) {
    final vista = PlazoVista.de(resumen, desdeCarga);
    return LayoutBuilder(
      builder: (context, restricciones) {
        final grande = restricciones.maxWidth >= 400;
        final tamano = grande ? DeadlineRingSize.l : DeadlineRingSize.m;
        final enVigente = vista.estado == CumplimientoPlazo.vigente && !vista.vencidoSinActualizar;
        final anillo = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DeadlineRing(vista: vista, size: tamano, decorativo: true),
            if (grande && enVigente) ...[
              const SizedBox(height: FgSpace.sp2),
              SizedBox(
                width: tamano.lado,
                child: Text(
                  'para la fecha límite',
                  textAlign: TextAlign.center,
                  style: FgText.body.copyWith(color: FgColors.inkSoft),
                ),
              ),
            ],
          ],
        );
        final textos = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusBadge(estado: vista.estado, destacado: true),
            const SizedBox(height: FgSpace.sp3),
            Text(
              vista.titular,
              style: FgText.num(FgText.cifra.copyWith(
                color: vista.estado == CumplimientoPlazo.vigente ? FgColors.ink : vista.estado.texto,
              )),
            ),
            if (vista.subtitulo != null) Text(vista.subtitulo!, style: FgText.body.copyWith(color: FgColors.inkSoft)),
            Text(vista.fecha, style: FgText.num(FgText.caption)),
            const SizedBox(height: FgSpace.sp2),
            Text(
              PendienteFormat.medicamentosEntregados(resumen.medicamentosEntregados, resumen.medicamentosTotal),
              style: FgText.caption,
            ),
          ],
        );
        // El hero se lee como una sola frase completa en vez de pieza por pieza.
        return Semantics(
          container: true,
          label: '${vista.semantica} '
              '${PendienteFormat.medicamentosEntregados(resumen.medicamentosEntregados, resumen.medicamentosTotal)}.',
          excludeSemantics: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              anillo,
              SizedBox(width: grande ? FgSpace.sp5 : FgSpace.sp4),
              Expanded(child: textos),
            ],
          ),
        );
      },
    );
  }
}

class _Datos extends StatelessWidget {
  const _Datos({required this.resumen, required this.rol});

  final PendienteResumen resumen;
  final PendientesRol? rol;

  @override
  Widget build(BuildContext context) {
    final entrega = resumen.fechaEntrega;
    final filas = <(String, String)>[
      ('Orden de medicamento', resumen.ordenMedicamentoId),
      ('Dispensación incompleta', PendienteFormat.fechaHora(resumen.fechaEvento)),
      ('Fecha límite', PendienteFormat.fechaHora(resumen.fechaLimite)),
      ('Registrado', PendienteFormat.fechaHora(resumen.fechaRegistro)),
      (
        'Entrega completa',
        entrega == null ? 'Faltan medicamentos por entregar' : PendienteFormat.fechaHora(entrega),
      ),
      if (rol?.veOtrosPacientes ?? false) ('Paciente', PendienteFormat.pacienteEnmascarado(resumen.pacienteId)),
    ];
    return Column(
      children: [
        for (final (indice, fila) in filas.indexed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: FgSpace.sp3),
            decoration: BoxDecoration(
              border: indice == 0
                  ? const Border(
                      top: BorderSide(color: FgColors.linea, width: FgBorder.w1),
                      bottom: BorderSide(color: FgColors.linea, width: FgBorder.w1),
                    )
                  : const Border(bottom: BorderSide(color: FgColors.linea, width: FgBorder.w1)),
            ),
            child: Semantics(
              container: true,
              label: '${fila.$1}: ${fila.$2}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fila.$1, style: FgText.caption),
                  Text(fila.$2, style: FgText.num(FgText.body)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Medicamento faltante. La API solo entrega su identificador de origen; el nombre queda pendiente.
class _MedicamentoTarjeta extends StatelessWidget {
  const _MedicamentoTarjeta({required this.medicamento});

  final MedicamentoPendiente medicamento;

  @override
  Widget build(BuildContext context) {
    final habilitado = medicamento.fechaHabilitacion;
    final entregado = medicamento.estadoEntrega == EstadoEntrega.entregado;
    final entrega = medicamento.fechaEntrega;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(FgBreakpoint.esCompacto(MediaQuery.sizeOf(context).width) ? FgSpace.sp4h : FgSpace.sp5),
      decoration: BoxDecoration(
        color: FgColors.superficie,
        borderRadius: BorderRadius.circular(FgRadius.md),
        border: Border.all(color: FgColors.linea, width: FgBorder.w1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(medicamento.medicamentoId, style: FgText.num(FgText.h3), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: FgSpace.sp3),
          _Paso(
            hecho: habilitado != null,
            etiqueta: 'Habilitado',
            detalle: habilitado == null ? 'Sin habilitar' : PendienteFormat.fechaHora(habilitado),
          ),
          const SizedBox(height: FgSpace.sp2),
          _Paso(
            hecho: entregado,
            etiqueta: 'Entregado',
            detalle: entrega != null
                ? PendienteFormat.fechaHora(entrega)
                : (entregado ? 'Entregado' : 'Por entregar'),
          ),
        ],
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({required this.hecho, required this.etiqueta, required this.detalle});

  final bool hecho;
  final String etiqueta;
  final String detalle;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: '$etiqueta: ${hecho ? 'completado' : 'pendiente'}. $detalle',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              hecho ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: FgSize.iconoMd,
              color: hecho ? FgColors.azul600 : FgColors.lineaControl,
            ),
            const SizedBox(width: FgSpace.sp3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta, style: FgText.label.copyWith(color: hecho ? FgColors.azul800 : FgColors.inkSoft)),
                  Text(detalle, style: FgText.num(FgText.caption)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Novedades extends StatelessWidget {
  const _Novedades({required this.novedades, required this.ahora});

  final List<Novedad> novedades;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    if (novedades.isEmpty) {
      return const FgNota(texto: 'Aún no hay novedades en este pendiente.');
    }
    // Las más recientes primero.
    final ordenadas = novedades.reversed.toList();
    return Column(
      children: [
        for (final (indice, novedad) in ordenadas.indexed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: FgSpace.sp3),
            decoration: BoxDecoration(
              border: Border(
                top: indice == 0 ? const BorderSide(color: FgColors.linea, width: FgBorder.w1) : BorderSide.none,
                bottom: const BorderSide(color: FgColors.linea, width: FgBorder.w1),
              ),
            ),
            child: _NovedadItem(novedad: novedad, ahora: ahora),
          ),
      ],
    );
  }
}

class _NovedadItem extends StatelessWidget {
  const _NovedadItem({required this.novedad, required this.ahora});

  final Novedad novedad;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final completa = PendienteFormat.fechaHora(novedad.fechaHora);
    final relativa = PendienteFormat.novedad(novedad.fechaHora, ahora);
    final fecha = relativa == completa ? completa : '$relativa · $completa';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(PendienteFormat.tipoNovedad(novedad.tipo), style: FgText.label),
        const SizedBox(height: FgSpace.sp1),
        Text(novedad.detalle, style: FgText.body),
        const SizedBox(height: FgSpace.sp1),
        Text(fecha, style: FgText.num(FgText.caption)),
      ],
    );
  }
}

class _EsqueletoDetalle extends StatelessWidget {
  const _EsqueletoDetalle();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Cargando el pendiente',
        liveRegion: true,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FgSkeleton(ancho: 120, alto: 120, radio: FgRadius.pill),
                SizedBox(width: FgSpace.sp4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FgSkeleton(ancho: 120, alto: 40, radio: FgRadius.pill),
                      SizedBox(height: FgSpace.sp3),
                      FgSkeleton(ancho: 160, alto: 28),
                      SizedBox(height: FgSpace.sp2),
                      FgSkeleton(ancho: 200, alto: 16),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: FgSpace.sp6),
            FgSkeleton(ancho: 220, alto: 24),
            SizedBox(height: FgSpace.sp4),
            FgSkeleton(alto: 56),
            SizedBox(height: FgSpace.sp2),
            FgSkeleton(alto: 56),
            SizedBox(height: FgSpace.sp2),
            FgSkeleton(alto: 56),
          ],
        ),
      );
}
