part of 'landing_sections.dart';

/// Quién participa y qué hace cada uno (PRODUCT §3).
/// Escritorio: cuatro columnas. Tablet: dos. Móvil: una.
class LandingRoles extends StatelessWidget {
  const LandingRoles({super.key});

  static const _roles = [
    (
      Icons.person_outline,
      'Pacientes',
      'Ven qué les falta, cuándo vence el plazo y en qué estado va su medicamento.'
    ),
    (
      Icons.account_balance_outlined,
      'EPS y gestores',
      'Siguen el cumplimiento y asignan el punto alterno de cada pendiente.'
    ),
    (
      Icons.local_pharmacy_outlined,
      'Farmacias',
      'Notifican la entrega incompleta desde su propio sistema y alistan el medicamento reasignado.'
    ),
    (
      Icons.local_shipping_outlined,
      'Repartidores',
      'Reciben sus entregas y registran cada entrega en ruta.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final columnas = ancho >= FgBreakpoint.desktop
        ? 4
        : ancho >= FgBreakpoint.tablet
            ? 2
            : 1;
    final roles = [
      for (final (icono, titulo, detalle) in _roles)
        _Rol(icono: icono, titulo: titulo, detalle: detalle),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Titular('Quién participa'),
        const SizedBox(height: FgSpace.sp7),
        for (var fila = 0; fila < roles.length; fila += columnas) ...[
          if (fila > 0) const SizedBox(height: FgSpace.sp6),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = fila; i < fila + columnas; i++) ...[
              if (i > fila) const SizedBox(width: FgSpace.sp6),
              Expanded(
                  child: i < roles.length ? roles[i] : const SizedBox.shrink()),
            ],
          ]),
        ],
      ],
    );
  }
}

class _Rol extends StatelessWidget {
  const _Rol(
      {required this.icono, required this.titulo, required this.detalle});

  final IconData icono;
  final String titulo, detalle;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ExcludeSemantics(
          child: Container(
            width: FgSize.tapMin,
            height: FgSize.tapMin,
            decoration: BoxDecoration(
              color: FgColors.azul100,
              borderRadius: BorderRadius.circular(FgRadius.md),
            ),
            child: Icon(icono, size: FgSize.iconoMd, color: FgColors.azul700),
          ),
        ),
        const SizedBox(height: FgSpace.sp4),
        Text(titulo, style: FgText.label),
        const SizedBox(height: FgSpace.sp2),
        Text(detalle, style: FgText.body),
      ]);
}

/// Lo que FarmaGo no decide: la frontera de alcance, dicha sin rodeos (manual §1).
class LandingNoHace extends StatelessWidget {
  const LandingNoHace({super.key});

  static const _limites = [
    'Decisiones clínicas.',
    'Cobertura o autorización de medicamentos, que corresponde a la EPS, al gestor o a la junta médica.',
    'Consulta de inventarios de farmacias.',
  ];

  @override
  Widget build(BuildContext context) => _Medida(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Titular('Lo que FarmaGo no decide'),
            const SizedBox(height: FgSpace.sp3),
            const Text(
              'FarmaGo organiza la logística y el seguimiento de cada entrega. No participa en estas decisiones:',
              style: FgText.bodyLg,
            ),
            const SizedBox(height: FgSpace.sp5),
            for (final limite in _limites)
              Padding(
                padding: const EdgeInsets.only(bottom: FgSpace.sp3),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Guion centrado en la primera línea de texto: la altura de línea sale del propio estilo.
                      SizedBox(
                        height: FgText.body.fontSize! * FgText.body.height!,
                        child: const ExcludeSemantics(
                          child: Center(
                            child: SizedBox(
                              width: FgSpace.sp3,
                              height: FgBorder.w2,
                              child: ColoredBox(color: FgColors.azul800),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: FgSpace.sp3),
                      Expanded(child: Text(limite, style: FgText.body)),
                    ]),
              ),
          ],
        ),
      );
}

/// Cierre: invita a crear la cuenta. La acción ya está en el hero, así que aquí solo va el mensaje,
/// sobre el degradado profundo de marca.
class LandingCierre extends StatelessWidget {
  const LandingCierre({super.key});

  @override
  Widget build(BuildContext context) => _Medida(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Titular('¿Tu medicamento quedó pendiente?',
                color: FgColors.blanco),
            const SizedBox(height: FgSpace.sp3),
            Text(
              'Si eres paciente, crea tu cuenta para ver el estado de tus medicamentos. Las cuentas de las EPS las asigna un administrador.',
              style: FgText.bodyLg.copyWith(color: FgColors.azul100),
            ),
          ],
        ),
      );
}
