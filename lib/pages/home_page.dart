import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../components/ui.dart';
import '../notifications/notification_controller.dart';
import '../utils/pendientes_rol.dart';
import 'notifications_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.auth,
    required this.notifications,
    required this.onAnalyze,
    required this.onNotifications,
    required this.onAccount,
    this.onRequestDelivery,
    this.onMyOrders,
    this.onDriverBoard,
    this.onPendientes,
    this.onAdminUsers,
    this.onAdminOrders,
  });

  final AuthController auth;
  final NotificationController notifications;
  final VoidCallback onAnalyze;
  final VoidCallback onNotifications;
  final VoidCallback onAccount;
  final VoidCallback? onRequestDelivery;
  final VoidCallback? onMyOrders;
  final VoidCallback? onDriverBoard;
  final VoidCallback? onAdminUsers;
  final VoidCallback? onAdminOrders;

  /// Entrada a los pendientes con plazo de 48 h (paciente, EPS y repartidor).
  final VoidCallback? onPendientes;

  static const _upcoming = [
    (Icons.inventory_2_outlined, 'Mis medicamentos', 'Consulta tu historial de medicamentos.'),
  ];

  bool get _isDriver => auth.user?.role == 'DELIVERY_DRIVER';
  bool get _isPatient => auth.user?.role == 'PATIENT';
  bool get _isAdmin => auth.user?.role == 'ADMIN';
  PendientesRol? get _rolPendientes => PendientesRol.fromCode(auth.user?.role);

  Widget _pendientesCard() {
    final rol = _rolPendientes!;
    return HomeActionCard(
      icon: Icons.medication_outlined,
      title: rol.tituloEntrada,
      description: rol.descripcionEntrada,
      onTap: onPendientes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = auth.user?.name.trim();
    final firstName = name?.isNotEmpty == true ? name!.split(RegExp(r'\s+')).first : null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.l, AppSpacing.xl, AppSpacing.xxl),
              children: [
                Row(children: [
                  const _HomeMark(),
                  const Spacer(),
                  ListenableBuilder(
                    listenable: notifications,
                    builder: (context, _) => NotificationBellButton(
                      unreadCount: notifications.unreadCount,
                      onPressed: onNotifications,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mi cuenta',
                    onPressed: onAccount,
                    icon: const Icon(Icons.account_circle_outlined),
                  ),
                ]),
                const SizedBox(height: AppSpacing.l),
                ListenableBuilder(
                  listenable: auth,
                  builder: (context, _) =>
                      ConnectionBanner(visible: auth.connectionIssue, onRetry: auth.refreshNow),
                ),
                const SizedBox(height: AppSpacing.m),
                Semantics(
                  header: true,
                  child: Text('Hola${firstName == null ? '' : ', $firstName'}', style: context.text.displaySmall),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  _isAdmin
                      ? 'Administra los usuarios y los domicilios de FARMA GO.'
                      : 'Organiza lo importante de tu tratamiento desde un solo lugar.',
                  style: context.text.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_isAdmin) ...[
                  HomeActionCard(
                    featured: true,
                    icon: Icons.pending_actions_outlined,
                    title: 'Domicilios pendientes',
                    description: 'Revisa todos los pedidos, síguelos en el mapa o cancélalos.',
                    onTap: onAdminOrders,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  HomeActionCard(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Usuarios y roles',
                    description: 'Busca usuarios y cambia su rol.',
                    onTap: onAdminUsers,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  HomeActionCard(
                    icon: Icons.document_scanner_outlined,
                    title: 'Analizar fórmula',
                    description: 'Lee una foto de una fórmula y revisa los medicamentos identificados.',
                    onTap: onAnalyze,
                  ),
                ] else if (_isDriver) ...[
                  HomeActionCard(
                    featured: true,
                    icon: Icons.delivery_dining,
                    title: 'Domicilios disponibles',
                    description: 'Toma un pedido, recógelo en la farmacia y compártelo en el mapa.',
                    onTap: onDriverBoard,
                  ),
                  if (onPendientes != null && _rolPendientes != null) ...[
                    const SizedBox(height: AppSpacing.m),
                    _pendientesCard(),
                  ],
                ] else ...[
                  HomeActionCard(
                    featured: true,
                    icon: Icons.document_scanner_outlined,
                    title: 'Analizar fórmula',
                    description: 'Lee una foto de tu fórmula y revisa los medicamentos identificados.',
                    onTap: onAnalyze,
                  ),
                  if (_isPatient) ...[
                    const SizedBox(height: AppSpacing.m),
                    HomeActionCard(
                      icon: Icons.home_outlined,
                      title: 'Pedir medicamento a casa',
                      description: 'Solicita un domicilio y sigue al repartidor en el mapa.',
                      onTap: onRequestDelivery,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    HomeActionCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'Mis domicilios',
                      description: 'Sigue el estado de tus pedidos en tiempo real.',
                      onTap: onMyOrders,
                    ),
                  ],
                  if (onPendientes != null && _rolPendientes != null) ...[
                    const SizedBox(height: AppSpacing.m),
                    _pendientesCard(),
                  ],
                ],
                if (!_isDriver && !_isAdmin) ...[
                  const SizedBox(height: AppSpacing.xxl - 2),
                  Semantics(header: true, child: Text('Próximamente', style: context.text.headlineSmall)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Estamos preparando estas funciones para conectarlas con las droguerías y los repartidores de FARMA GO.',
                    style: context.text.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  for (final (icon, title, description) in _upcoming) ...[
                    HomeActionCard(icon: icon, title: title, description: description),
                    const SizedBox(height: AppSpacing.m),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeMark extends StatelessWidget {
  const _HomeMark();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'FARMA GO',
        header: true,
        child: ExcludeSemantics(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(AppRadii.s)),
              child: Icon(Icons.local_pharmacy_rounded, size: 21, color: context.colors.onPrimary),
            ),
            const SizedBox(width: AppSpacing.s),
            Text(
              'FARMA GO',
              style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: context.colors.primary),
            ),
          ]),
        ),
      );
}

/// Action card. Without [onTap] it renders as an explained, non-interactive
/// "coming soon" item instead of a fake button (FE-013).
class HomeActionCard extends StatelessWidget {
  const HomeActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.featured = false,
  });

  final IconData icon;
  final String title, description;
  final VoidCallback? onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final foreground = featured ? context.colors.onPrimary : context.colors.onSurface;
    final radius = BorderRadius.circular(featured ? AppRadii.xl : AppRadii.l);
    return Semantics(
      button: enabled,
      enabled: enabled,
      label: enabled ? null : '$title. Disponible próximamente.',
      child: Material(
        color: featured ? context.colors.primary : context.colors.surface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(featured ? AppSpacing.xl - 2 : AppSpacing.l + 2),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: featured ? null : Border.all(color: context.status.decorative),
            ),
            child: Row(children: [
              Container(
                width: featured ? 54 : 44,
                height: featured ? 54 : 44,
                decoration: BoxDecoration(
                  color: featured ? context.colors.onPrimary.withValues(alpha: .16) : context.status.brandSurface,
                  borderRadius: BorderRadius.circular(AppRadii.s),
                ),
                child: ExcludeSemantics(child: Icon(icon, color: featured ? foreground : context.colors.primary)),
              ),
              const SizedBox(width: AppSpacing.m + 3),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    title,
                    style: (featured ? context.text.titleLarge : context.text.titleMedium)?.copyWith(color: foreground),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: context.text.bodySmall?.copyWith(
                      color: featured ? foreground : context.status.mutedText,
                    ),
                  ),
                ]),
              ),
              if (enabled)
                ExcludeSemantics(child: Icon(Icons.chevron_right_rounded, color: foreground))
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: context.status.brandSurface,
                    borderRadius: BorderRadius.circular(AppRadii.s),
                  ),
                  child: ExcludeSemantics(child: Text('Pronto', style: context.text.labelSmall)),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
