import '../components/farmago/dialogs.dart';
import '../components/account/profile_form.dart';
import '../types/user_profile.dart';
import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../app/theme/farmago_tokens.dart';
import '../components/farmago/buttons.dart';
import '../components/delivery_widgets.dart';
import '../components/farmago/feedback.dart';
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
    final confirmed = await showFgConfirm(
      context,
      titulo: '¿Cambiar el rol?',
      mensaje: '${user.name.isEmpty ? user.email : user.name} pasará de ${user.roleLabel} a ${role.label}. '
          'Se cerrará su sesión y tendrá que volver a entrar.',
      confirmar: 'Cambiar a ${role.label}',
      cancelar: 'Dejar como está',
    );
    if (!confirmed) return;
    final error = await widget.controller.changeRole(user, role);
    if (mounted) showAppSnackBar(context, error?.userMessage ?? 'Rol actualizado: ${role.label}.', error: error != null);
  }

  Future<void> _correctDocument(AdminUser user) async {
    final result = await showDialog<(DocumentType, String)>(
      context: context,
      builder: (context) => _DocumentDialog(user: user),
    );
    if (result == null) return;
    final error = await widget.controller.correctDocument(user, result.$1, result.$2);
    if (mounted) showAppSnackBar(context, error?.userMessage ?? 'Documento corregido: ${result.$1.code} ${result.$2}.');
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
              if (c.loading && c.users.isEmpty) const FgListaCargando(etiqueta: 'Cargando usuarios'),
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
                  onDocument: () => _correctDocument(user),
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
  const _UserCard({
    required this.user,
    required this.isSelf,
    required this.saving,
    required this.onRole,
    required this.onDocument,
  });

  final AdminUser user;
  final bool isSelf, saving;
  final ValueChanged<UserRole> onRole;
  final VoidCallback onDocument;

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
          const SizedBox(height: AppSpacing.s),
          // §23: cada dato con su icono, en vez de una línea larga unida con «·» (ley de Miller).
          Wrap(spacing: FgSpace.sp4, runSpacing: FgSpace.sp1, children: [
            _Meta(
              icono: user.isGoogle ? Icons.account_circle_outlined : Icons.mail_outline,
              texto: user.isGoogle ? 'Cuenta de Google' : 'Correo y contraseña',
            ),
            _Meta(
              icono: user.emailVerified ? Icons.verified_outlined : Icons.error_outline,
              texto: user.emailVerified ? 'Correo verificado' : 'Correo sin verificar',
            ),
            if (created != null) _Meta(icono: Icons.calendar_today_outlined, texto: 'Desde el ${_date(created)}'),
          ]),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                user.document == null ? 'Sin documento' : 'Documento ${user.document}',
                style: context.text.bodySmall,
              ),
              if (!user.profileComplete) const StatusChip(label: 'Perfil incompleto', tone: StatusTone.warning),
              TextButton(
                onPressed: saving ? null : onDocument,
                child: Text(user.document == null ? 'Registrar documento' : 'Corregir documento'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          // §23: el mismo campo con etiqueta que el resto de formularios (consistencia), no el
          // desplegable subrayado de Material.
          Row(children: [
            Expanded(
              // Controlado por `user.role`: si se cancela la confirmación, vuelve a mostrar el rol real.
              child: InputDecorator(
                decoration: InputDecoration(labelText: 'Rol', enabled: !isSelf),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserRole>(
                    value: user.role,
                    isExpanded: true,
                    isDense: true,
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
              ),
            ),
            if (saving) ...[
              const SizedBox(width: AppSpacing.m),
              const FgSpinner(),
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


/// Dato secundario de la tarjeta de usuario: icono de 20 px y texto 16 px en tinta suave.
class _Meta extends StatelessWidget {
  const _Meta({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: FgSize.iconoSm, color: FgColors.inkSoft),
        const SizedBox(width: FgSpace.sp1),
        Text(texto, style: FgText.caption),
      ]);
}

/// Corrección del documento por un administrador. Valida el formato antes de enviar.
class _DocumentDialog extends StatefulWidget {
  const _DocumentDialog({required this.user});

  final AdminUser user;

  @override
  State<_DocumentDialog> createState() => _DocumentDialogState();
}

class _DocumentDialogState extends State<_DocumentDialog> {
  late DocumentType _type = widget.user.documentType ?? DocumentType.cc;
  late final _number = TextEditingController(text: widget.user.documentNumber ?? '');
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  void _save() {
    final error = ProfileRules.document(_type, _number.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, (_type, ProfileRules.normalizeDocument(_type, _number.text)));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Corregir documento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.user.name.isEmpty ? widget.user.email : widget.user.name,
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.m),
            DropdownButtonFormField<DocumentType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo de documento'),
              items: [for (final t in DocumentType.values) DropdownMenuItem(value: t, child: Text(t.label))],
              onChanged: (t) => setState(() => _type = t ?? _type),
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: _number,
              autofocus: true,
              decoration: InputDecoration(labelText: 'Número de documento', errorText: _error),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: _save, child: const Text('Guardar')),
        ],
      );
}
