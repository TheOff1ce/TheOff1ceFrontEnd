import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../components/delivery_widgets.dart';
import '../components/feedback.dart';
import '../hooks/admin_users_controller.dart';
import '../types/admin.dart';

/// Administrators: every user, searchable, with their role editable in place.
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key, required this.controller, required this.currentUserId, required this.onBack});

  final AdminUsersController controller;

  /// The signed-in administrator, who cannot change their own role.
  final String? currentUserId;
  final VoidCallback onBack;

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late final TextEditingController _search = TextEditingController(text: widget.controller.search);

  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _changeRole(AdminUser user, UserRole role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cambiar el rol?'),
        content: Text(
          '${user.name.isEmpty ? user.email : user.name} pasará de ${user.roleLabel} a ${role.label}. '
          'Se cerrará su sesión y tendrá que volver a entrar.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, cambiar')),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await widget.controller.changeRole(user, role);
    if (mounted) showAppSnackBar(context, error?.userMessage ?? 'Rol actualizado: ${role.label}.');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final c = widget.controller;
          return DeliveryScaffold(
            title: 'Usuarios',
            onBack: widget.onBack,
            onRefresh: c.load,
            children: [
              TextField(
                controller: _search,
                onChanged: c.setSearch,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Buscar por nombre o correo',
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Wrap(spacing: AppSpacing.s, runSpacing: AppSpacing.s, children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: c.roleFilter == null,
                  onSelected: (_) => c.setRoleFilter(null),
                ),
                for (final role in UserRole.values)
                  ChoiceChip(
                    label: Text(role.label),
                    selected: c.roleFilter == role,
                    onSelected: (_) => c.setRoleFilter(role),
                  ),
              ]),
              const SizedBox(height: AppSpacing.m),
              Semantics(
                liveRegion: true,
                child: Text(
                  c.loading ? 'Buscando…' : '${c.total} ${c.total == 1 ? 'usuario' : 'usuarios'}',
                  style: context.text.bodySmall?.copyWith(color: context.status.mutedText),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              ErrorBanner(error: c.error),
              if (c.loading && c.users.isEmpty) const Center(child: DelayedSpinner()),
              if (!c.loading && c.users.isEmpty && c.error == null)
                const EmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'Sin resultados',
                  message: 'Prueba con otro nombre, correo o rol.',
                ),
              for (final user in c.users) ...[
                _UserCard(
                  user: user,
                  isSelf: user.id == widget.currentUserId,
                  saving: c.saving.contains(user.id),
                  onRole: (role) => _changeRole(user, role),
                ),
                const SizedBox(height: AppSpacing.m),
              ],
              if (c.hasMore)
                Center(
                  child: c.loadingMore
                      ? const DelayedSpinner(size: 28)
                      : OutlinedButton(onPressed: c.loadMore, child: const Text('Cargar más')),
                ),
            ],
          );
        },
      );
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.isSelf, required this.saving, required this.onRole});

  final AdminUser user;
  final bool isSelf, saving;
  final ValueChanged<UserRole> onRole;

  @override
  Widget build(BuildContext context) {
    final created = user.createdAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                user.name.isEmpty ? 'Sin nombre' : user.name,
                style: context.text.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelf) const StatusChip(label: 'Tú'),
          ]),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(user.email, style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              user.isGoogle ? 'Cuenta de Google' : 'Correo y contraseña',
              user.emailVerified ? 'correo verificado' : 'correo sin verificar',
              if (created != null) 'desde ${_date(created)}',
            ].join(' · '),
            style: context.text.bodySmall?.copyWith(color: context.status.mutedText),
          ),
          const SizedBox(height: AppSpacing.m),
          Row(children: [
            Text('Rol', style: context.text.labelLarge),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: DropdownButton<UserRole>(
                value: user.role,
                isExpanded: true,
                hint: const Text('Sin rol'),
                items: [
                  for (final role in UserRole.values) DropdownMenuItem(value: role, child: Text(role.label)),
                ],
                onChanged: isSelf || saving
                    ? null
                    : (role) {
                        if (role != null && role != user.role) onRole(role);
                      },
              ),
            ),
            if (saving) ...[
              const SizedBox(width: AppSpacing.s),
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ]),
          if (isSelf)
            Text(
              'No puedes cambiar tu propio rol.',
              style: context.text.bodySmall?.copyWith(color: context.status.mutedText),
            ),
        ]),
      ),
    );
  }

  static String _date(DateTime date) {
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

