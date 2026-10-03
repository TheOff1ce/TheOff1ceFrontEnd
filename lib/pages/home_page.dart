import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../components/ui.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.auth,
    required this.onAnalyze,
    required this.onAccount,
  });
  final AuthController? auth;
  final VoidCallback onAnalyze;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    final name = auth?.user?.name.trim();
    final firstName =
        name?.isNotEmpty == true ? name!.split(RegExp(r'\s+')).first : null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                Row(children: [
                  const FarmaGoHomeMark(),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Cuenta',
                    onPressed: () => _showAccountPanel(context),
                    icon: const Icon(Icons.account_circle_outlined),
                  ),
                ]),
                const SizedBox(height: 34),
                Text('Hola${firstName == null ? '' : ', $firstName'}',
                    style: AppText.display),
                const SizedBox(height: 8),
                const Text(
                    'Organiza lo importante de tu tratamiento desde un solo lugar.',
                    style: AppText.body),
                const SizedBox(height: 28),
                HomeActionCard(
                  featured: true,
                  icon: Icons.document_scanner_outlined,
                  title: 'Analizar fórmula',
                  description:
                      'Lee una foto de tu fórmula y revisa los medicamentos identificados.',
                  onTap: onAnalyze,
                ),
                const SizedBox(height: 30),
                const Text('Tu salud', style: AppText.heading),
                const SizedBox(height: 6),
                const Text('Accesos preparados para tus próximos pasos.',
                    style: AppText.body),
                const SizedBox(height: 14),
                HomeActionCard(
                  icon: Icons.medication_outlined,
                  title: 'Medicamentos pendientes',
                  description: 'Revisa lo que tienes por gestionar.',
                  onTap: () => _comingSoon(context, 'Medicamentos pendientes'),
                ),
                const SizedBox(height: 12),
                HomeActionCard(
                  icon: Icons.home_outlined,
                  title: 'Pedir medicamento a casa',
                  description:
                      'Solicita entregas cuando esta función esté disponible.',
                  onTap: () => _comingSoon(context, 'Pedidos a domicilio'),
                ),
                const SizedBox(height: 12),
                HomeActionCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Mis medicamentos',
                  description: 'Consulta tu historial de medicamentos.',
                  onTap: () => _comingSoon(context, 'Mis medicamentos'),
                ),
                const SizedBox(height: 12),
                HomeActionCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Mis solicitudes',
                  description: 'Sigue el estado de tus pedidos y solicitudes.',
                  onTap: () => _comingSoon(context, 'Mis solicitudes'),
                ),
                const SizedBox(height: 12),
                HomeActionCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Perfil',
                  description: 'Consulta los datos de tu cuenta y tu sesión.',
                  onTap: onAccount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.schedule_outlined,
                size: 40, color: AppColors.blue),
            const SizedBox(height: 14),
            Text('$feature estará disponible próximamente.',
                style: AppText.title, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
                'Estamos preparando esta función para conectarla con los servicios de FARMA GO.',
                style: AppText.body,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Entendido'),
            ),
          ]),
        ),
      ),
    );
  }

  void _showAccountPanel(BuildContext context) {
    final currentAuth = auth;
    if (currentAuth == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Tu cuenta', style: AppText.heading),
                const SizedBox(height: 8),
                Text(currentAuth.user?.email ?? '', style: AppText.body),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    onAccount();
                  },
                  icon: const Icon(Icons.person_outline_rounded),
                  label: const Text('Ver cuenta'),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.error),
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await currentAuth.logout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                ),
              ]),
        ),
      ),
    );
  }
}

class FarmaGoHomeMark extends StatelessWidget {
  const FarmaGoHomeMark({super.key});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: AppColors.navy, borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.local_pharmacy_rounded,
                size: 21, color: Colors.white)),
        const SizedBox(width: 9),
        const Text('FARMA GO',
            style: TextStyle(
                color: AppColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -.5)),
      ]);
}

class HomeActionCard extends StatelessWidget {
  const HomeActionCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.description,
      required this.onTap,
      this.featured = false});
  final IconData icon;
  final String title, description;
  final VoidCallback onTap;
  final bool featured;
  @override
  Widget build(BuildContext context) => Material(
        color: featured ? AppColors.navy : Colors.white,
        borderRadius: BorderRadius.circular(featured ? 24 : 18),
        child: InkWell(
          borderRadius: BorderRadius.circular(featured ? 24 : 18),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(featured ? 22 : 18),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(featured ? 24 : 18),
                border: featured ? null : Border.all(color: AppColors.sky)),
            child: Row(children: [
              Container(
                  width: featured ? 54 : 44,
                  height: featured ? 54 : 44,
                  decoration: BoxDecoration(
                      color: featured
                          ? Colors.white.withValues(alpha: .16)
                          : AppColors.light,
                      borderRadius: BorderRadius.circular(15)),
                  child: Icon(icon,
                      color: featured ? Colors.white : AppColors.navy)),
              const SizedBox(width: 15),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: featured ? 20 : 16,
                            fontWeight: FontWeight.w800,
                            color: featured ? Colors.white : AppColors.text)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: featured
                                ? const Color(0xFFD9EAF8)
                                : AppColors.secondary)),
                  ])),
              Icon(Icons.chevron_right_rounded,
                  color: featured ? Colors.white : AppColors.blue),
            ]),
          ),
        ),
      );
}

class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    required this.auth,
    required this.onBack,
  });
  final AuthController auth;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    final initial =
        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi cuenta'),
        leading: IconButton(
          tooltip: 'Volver al inicio',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(padding: const EdgeInsets.all(24), children: [
                    CircleAvatar(
                        radius: 38,
                        backgroundColor: AppColors.light,
                        child: Text(initial,
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy))),
                    const SizedBox(height: 20),
                    Text(user?.name ?? 'Usuario',
                        style: AppText.heading, textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text(user?.email ?? '',
                        style: AppText.body, textAlign: TextAlign.center),
                    const SizedBox(height: 28),
                    AppCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('Sesión activa', style: AppText.title),
                          const SizedBox(height: 8),
                          Text('Rol: ${user?.role ?? 'No disponible'}',
                              style: AppText.body)
                        ])),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error),
                        onPressed: () async {
                          await auth.logout();
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Cerrar sesión')),
                  ])))),
    );
  }
}
