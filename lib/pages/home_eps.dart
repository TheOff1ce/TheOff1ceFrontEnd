part of 'home_page.dart';

/// Inicio de la EPS: cuántos pendientes vencen en menos de 12 h, cuántos se vencieron sin
/// entregar y qué porcentaje se entregó a tiempo. Lo urgente primero, con acceso directo.
class _FocoEps extends StatelessWidget {
  const _FocoEps({required this.pantalla, required this.movil});

  final _HomePageState pantalla;
  final bool movil;

  HomePage get _w => pantalla.widget;

  @override
  Widget build(BuildContext context) {
    final c = _w.resumenEps!;
    final r = c.resumen;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (c.error != null && r == null)
        FgBanner(
          kind: FgBannerKind.error,
          title: 'No pudimos cargar las cifras',
          message: c.error!.userMessage,
          actionLabel: 'Reintentar',
          onAction: c.load,
        )
      else if (r == null)
        const FgListaCargando(cantidad: 1, etiqueta: 'Cargando las cifras del plazo')
      else
        _Panel(child: _cifras(context, r, c.desdeCarga)),
      const SizedBox(height: FgSpace.sp6),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: FgSize.contenidoPaciente),
        child: FgAcciones(acciones: [
          if (pantalla._pendientesVisible)
            FgAccionTarjeta(
              icono: Icons.medication_outlined,
              titulo: pantalla._rol!.tituloEntrada,
              descripcion: pantalla._rol!.descripcionEntrada,
              onTap: _w.onPendientes,
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

  Widget _cifras(BuildContext context, ResumenEps r, Duration desdeCarga) {
    final porcentaje = r.porcentajeATiempo;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Semantics(header: true, child: const Text('Plazo de 48 h', style: FgText.h3))),
        FgIconButton(
          icon: Icons.refresh,
          tooltip: 'Actualizar cifras',
          onPressed: _w.resumenEps!.loading ? null : _w.resumenEps!.load,
        ),
      ]),
      const SizedBox(height: FgSpace.sp4),
      LayoutBuilder(builder: (context, constraints) {
        const gap = FgSpace.sp3;
        final columnas = constraints.maxWidth >= 560 ? 4 : 2;
        final ancho = (constraints.maxWidth - gap * (columnas - 1)) / columnas;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final cifra in [
            _Cifra(
              valor: '${r.porVencer}',
              etiqueta: 'Vencen en menos de 12 h',
              fondo: FgColors.riesgoBg,
              texto: FgColors.riesgoFg,
            ),
            _Cifra(
              valor: '${r.vencidosSinEntregar}',
              etiqueta: 'Vencidos sin entregar',
              fondo: FgColors.incumplidoBg,
              texto: FgColors.incumplidoFg,
            ),
            _Cifra(
              valor: '${r.vigentes}',
              etiqueta: 'Pendientes vigentes',
              fondo: FgColors.vigenteBg,
              texto: FgColors.vigenteFg,
            ),
            _Cifra(
              valor: porcentaje == null ? '—' : '$porcentaje %',
              etiqueta: porcentaje == null
                  ? 'Entregados a tiempo'
                  : 'Entregados a tiempo (${r.entregadosATiempo} de ${r.entregados})',
              fondo: FgColors.cumplidoBg,
              texto: FgColors.cumplidoFg,
            ),
          ])
            SizedBox(width: ancho, child: cifra),
        ]);
      }),
      if (r.urgentes.isNotEmpty) ...[
        const SizedBox(height: FgSpace.sp5),
        const Text('Los que vencen primero', style: FgText.label),
        const SizedBox(height: FgSpace.sp2),
        for (final p in r.urgentes)
          _Urgente(
            pendiente: p,
            restante: p.restante(desdeCarga),
            onTap: () => _w.onPendienteDetalle(p.id),
          ),
      ] else if (r.vigentes > 0) ...[
        const SizedBox(height: FgSpace.sp4),
        Text('Ningún pendiente vence en las próximas 12 horas.', style: FgText.body.copyWith(color: FgColors.inkSoft)),
      ],
      if (r.parcial) ...[
        const SizedBox(height: FgSpace.sp3),
        Text(
          'Cifras sobre los ${EpsResumenController.limite} registros más recientes de cada estado '
          '(hay ${r.totalPendientes} pendientes y ${r.totalEntregados} entregados).',
          style: FgText.caption,
        ),
      ],
    ]);
  }
}

/// Una cifra grande con su etiqueta. El color acompaña al texto: el significado no depende de él.
class _Cifra extends StatelessWidget {
  const _Cifra({required this.valor, required this.etiqueta, required this.fondo, required this.texto});

  final String valor, etiqueta;
  final Color fondo, texto;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$etiqueta: $valor',
        excludeSemantics: true,
        child: Container(
          // Misma altura mínima para que la fila de cifras no quede escalonada.
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(FgSpace.sp4),
          decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(FgRadius.md)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(valor, style: FgText.num(FgText.h1Movil).copyWith(color: texto)),
            const SizedBox(height: FgSpace.sp1),
            Text(etiqueta, style: FgText.caption.copyWith(color: texto)),
          ]),
        ),
      );
}

/// Pendiente por vencer: pedido, cuánto le queda y acceso al detalle.
class _Urgente extends StatelessWidget {
  const _Urgente({required this.pendiente, required this.restante, required this.onTap});

  final PendienteResumen pendiente;
  final Duration restante;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Pedido ${pendiente.ordenMedicamentoId}. Vence en ${PendienteFormat.duracionLarga(restante)}.',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FgRadius.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: FgSize.tapMin),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: FgSpace.sp2),
              child: Row(children: [
                const Icon(Icons.schedule, size: FgSize.iconoMd, color: FgColors.riesgoSolid),
                const SizedBox(width: FgSpace.sp3),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pendiente.ordenMedicamentoId, style: FgText.body),
                    Text('Vence en ${PendienteFormat.duracion(restante)}', style: FgText.label),
                  ]),
                ),
                const SizedBox(width: FgSpace.sp2),
                const Icon(Icons.chevron_right, size: FgSize.iconoMd, color: FgColors.inkSoft),
              ]),
            ),
          ),
        ),
      );
}
