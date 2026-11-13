import 'package:flutter/material.dart';

import '../app/theme/farmago_tokens.dart';
import '../components/calificar_entrega.dart';
import '../components/delivery_widgets.dart';
import '../components/farmago/buttons.dart';
import '../components/farmago/card.dart';
import '../components/farmago/feedback.dart';
import '../hooks/admin_ratings_controller.dart';
import '../types/calificaciones.dart';
import '../utils/pendiente_format.dart';

/// Administradores: cómo califican los pacientes las entregas, por repartidor, y las malas con su
/// comentario para revisarlas.
class AdminRatingsPage extends StatefulWidget {
  const AdminRatingsPage({super.key, required this.controller, required this.onVerEntrega, required this.onBack});

  final AdminRatingsController controller;
  final ValueChanged<String> onVerEntrega;
  final VoidCallback onBack;

  @override
  State<AdminRatingsPage> createState() => _AdminRatingsPageState();
}

String _decimal(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

class _AdminRatingsPageState extends State<AdminRatingsPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final c = widget.controller;
          final r = c.reporte;
          return DeliveryScaffold(
            title: 'Calificaciones',
            onBack: widget.onBack,
            onRefresh: c.load,
            children: [
              Wrap(spacing: FgSpace.sp2, runSpacing: FgSpace.sp2, children: [
                for (final dias in AdminRatingsController.ventanas)
                  ChoiceChip(
                    label: Text('Últimos $dias días'),
                    selected: c.dias == dias,
                    onSelected: c.loading ? null : (_) => c.setDias(dias),
                  ),
              ]),
              const SizedBox(height: FgSpace.sp4),
              ErrorBanner(error: c.error),
              if (r == null && c.loading)
                const FgListaCargando(cantidad: 2, etiqueta: 'Cargando calificaciones')
              else if (r != null && r.total == 0)
                const EmptyState(
                  icon: Icons.star_outline_rounded,
                  title: 'Aún no hay calificaciones',
                  message: 'Cuando los pacientes califiquen sus entregas, aquí verás el promedio de cada repartidor.',
                )
              else if (r != null) ...[
                _Resumen(reporte: r),
                const SizedBox(height: FgSpace.sp5),
                _Repartidores(reporte: r, controller: c),
                const SizedBox(height: FgSpace.sp5),
                _Malas(reporte: r, controller: c, onVerEntrega: widget.onVerEntrega),
                if (r.truncado) ...[
                  const SizedBox(height: FgSpace.sp3),
                  const Text('Hay muchas calificaciones en este periodo: las cifras cubren las más recientes.',
                      style: FgText.caption),
                ],
              ],
            ],
          );
        },
      );
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.reporte});

  final ReporteCalificaciones reporte;

  @override
  Widget build(BuildContext context) {
    final r = reporte;
    final maximo = r.distribucion.fold<int>(0, (a, b) => a > b ? a : b);
    return FgCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(
          label: 'Promedio ${_decimal(r.promedio ?? 0)} de 5, con ${r.total} '
              '${r.total == 1 ? 'calificación' : 'calificaciones'} en los últimos ${r.dias} días.',
          excludeSemantics: true,
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(_decimal(r.promedio ?? 0), style: FgText.num(FgText.h1Movil)),
            const SizedBox(width: FgSpace.sp3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                EstrellasPromedio(valor: r.promedio ?? 0, tamano: 24),
                const SizedBox(height: FgSpace.sp1),
                Text('${r.total} ${r.total == 1 ? 'calificación' : 'calificaciones'} · últimos ${r.dias} días',
                    style: FgText.caption),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: FgSpace.sp4),
        for (var estrellas = 5; estrellas >= 1; estrellas--)
          Semantics(
            label: '$estrellas ${estrellas == 1 ? 'estrella' : 'estrellas'}: ${r.distribucion[estrellas - 1]}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: FgSpace.sp1),
              child: Row(children: [
                SizedBox(width: 28, child: Text('$estrellas★', style: FgText.caption)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(FgRadius.sm),
                    child: LinearProgressIndicator(
                      value: maximo == 0 ? 0 : r.distribucion[estrellas - 1] / maximo,
                      minHeight: 8,
                      backgroundColor: FgColors.fondoHundido,
                      color: estrellas <= 2 ? FgColors.incumplidoSolid : FgColors.azul600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text('${r.distribucion[estrellas - 1]}', textAlign: TextAlign.end, style: FgText.caption),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _Repartidores extends StatelessWidget {
  const _Repartidores({required this.reporte, required this.controller});

  final ReporteCalificaciones reporte;
  final AdminRatingsController controller;

  @override
  Widget build(BuildContext context) => FgCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionHeading('Por repartidor'),
          const Text('El promedio más bajo aparece primero.', style: FgText.caption),
          const SizedBox(height: FgSpace.sp3),
          if (reporte.repartidores.isEmpty) const Text('Sin repartidores calificados.', style: FgText.body),
          for (final (i, d) in reporte.repartidores.indexed) ...[
            if (i > 0) const Divider(height: FgSpace.sp5, color: FgColors.lineaSuave),
            Semantics(
              label: '${controller.nombreDe(d.repartidorId)}: promedio ${_decimal(d.promedio)}, '
                  '${d.cantidad} ${d.cantidad == 1 ? 'calificación' : 'calificaciones'}'
                  '${d.malas > 0 ? ', ${d.malas} ${d.malas == 1 ? 'mala' : 'malas'}' : ''}.',
              excludeSemantics: true,
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(controller.nombreDe(d.repartidorId), style: FgText.label),
                    const SizedBox(height: FgSpace.sp1),
                    Text('${d.cantidad} ${d.cantidad == 1 ? 'calificación' : 'calificaciones'}', style: FgText.caption),
                  ]),
                ),
                if (d.malas > 0) ...[
                  StatusChip(label: '${d.malas} ${d.malas == 1 ? 'mala' : 'malas'}', tone: StatusTone.warning),
                  const SizedBox(width: FgSpace.sp3),
                ],
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(_decimal(d.promedio), style: FgText.num(FgText.h3)),
                  EstrellasPromedio(valor: d.promedio, tamano: 14),
                ]),
              ]),
            ),
          ],
        ]),
      );
}

class _Malas extends StatelessWidget {
  const _Malas({required this.reporte, required this.controller, required this.onVerEntrega});

  final ReporteCalificaciones reporte;
  final AdminRatingsController controller;
  final ValueChanged<String> onVerEntrega;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(header: true, child: const Text('Calificaciones malas (1 o 2 estrellas)', style: FgText.h3)),
        const SizedBox(height: FgSpace.sp3),
        if (reporte.malas.isEmpty)
          const FgBanner(kind: FgBannerKind.exito, message: 'No hubo calificaciones malas en este periodo.')
        else
          for (final m in reporte.malas)
            Padding(
              padding: const EdgeInsets.only(bottom: FgSpace.sp3),
              child: FgCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Semantics(
                      label: '${m.estrellas} de 5 estrellas',
                      child: EstrellasPromedio(valor: m.estrellas.toDouble(), tamano: 18),
                    ),
                    const Spacer(),
                    if (m.fecha != null) Text(PendienteFormat.fechaHora(m.fecha!), style: FgText.caption),
                  ]),
                  const SizedBox(height: FgSpace.sp2),
                  Text(
                    m.comentario == null ? 'Sin comentario.' : '«${m.comentario}»',
                    style: m.comentario == null ? FgText.body.copyWith(color: FgColors.inkSoft) : FgText.bodyLg,
                  ),
                  const SizedBox(height: FgSpace.sp2),
                  Text(controller.nombreDe(m.repartidorId), style: FgText.caption),
                  const SizedBox(height: FgSpace.sp3),
                  FgButton(
                    label: 'Ver entrega',
                    icon: Icons.map_outlined,
                    variant: FgButtonVariant.secondary,
                    size: FgButtonSize.sm,
                    onPressed: () => onVerEntrega(m.entregaId),
                  ),
                ]),
              ),
            ),
      ]);
}
