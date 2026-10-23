import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/auth_ui.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key, required this.onLogin, required this.onRegister});

  final VoidCallback onLogin, onRegister;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
                const FarmaGoMark(),
                const SizedBox(height: AppSpacing.xl),
                const _NetworkVisual(),
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                  header: true,
                  child: Text('Medicamentos a tiempo,\ncon trazabilidad.', style: context.text.displaySmall),
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'FARMA GO conecta EPS, gestores farmacéuticos, droguerías, repartidores y pacientes para coordinar la entrega oportuna de medicamentos.',
                  style: context.text.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(onPressed: onLogin, child: const Text('Iniciar sesión')),
                const SizedBox(height: AppSpacing.m),
                OutlinedButton(onPressed: onRegister, child: const Text('Crear cuenta')),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  decoration: BoxDecoration(
                    color: context.status.brandSurface,
                    borderRadius: BorderRadius.circular(AppRadii.l),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Una misma red para cada solicitud', style: context.text.titleMedium),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Las fórmulas y solicitudes se canalizan por la misma operación logística para dar visibilidad del proceso de dispensación y entrega.',
                      style: context.text.bodyLarge,
                    ),
                  ]),
                ),
                const SizedBox(height: AppSpacing.l),
                const Wrap(spacing: AppSpacing.s, runSpacing: AppSpacing.s, children: [
                  _Benefit(icon: Icons.route_outlined, text: 'Seguimiento del proceso'),
                  _Benefit(icon: Icons.storefront_outlined, text: 'Red de dispensación'),
                  _Benefit(icon: Icons.local_shipping_outlined, text: 'Entrega coordinada'),
                ]),
              ]),
            ),
          ),
        ),
      );
}

/// Decorative illustration; it adapts to the width and is hidden from screen readers.
class _NetworkVisual extends StatelessWidget {
  const _NetworkVisual();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.l + 4),
          decoration: BoxDecoration(
            color: context.status.decorative,
            borderRadius: BorderRadius.circular(AppRadii.xl + 8),
          ),
          child: Column(children: [
            Row(children: [
              const _NetworkNode(icon: Icons.account_balance_outlined, label: 'EPS'),
              Expanded(child: Divider(color: context.colors.surface, thickness: 2)),
              const _NetworkNode(icon: Icons.local_pharmacy_outlined, label: 'Dispensación'),
            ]),
            const SizedBox(height: AppSpacing.s),
            Icon(Icons.local_shipping_outlined, color: context.colors.primary, size: 28),
            const SizedBox(height: AppSpacing.s),
            const _NetworkNode(icon: Icons.person_outline_rounded, label: 'Paciente'),
          ]),
        ),
      );
}

class _NetworkNode extends StatelessWidget {
  const _NetworkNode({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: context.colors.surface,
          child: Icon(icon, color: context.colors.primary, size: 21),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: context.text.labelSmall?.copyWith(color: context.colors.primary)),
      ]);
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s + 2),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.s),
          border: Border.all(color: context.status.decorative),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ExcludeSemantics(child: Icon(icon, size: 18, color: context.colors.primary)),
          const SizedBox(width: AppSpacing.s),
          Text(text, style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurface)),
        ]),
      );
}
