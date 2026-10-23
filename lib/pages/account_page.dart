import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../components/ui.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, required this.auth, required this.onBack});

  final AuthController auth;
  final VoidCallback onBack;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _signingOut = false;

  Future<void> _logout() async {
    setState(() => _signingOut = true);
    // Never fails from the user's point of view: the local session is always closed.
    await widget.auth.logout();
    if (mounted) setState(() => _signingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.user;
    final initial = user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi cuenta'),
        leading: IconButton(tooltip: 'Volver al inicio', onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: context.status.brandSurface,
                  child: Text(initial, style: context.text.headlineSmall?.copyWith(color: context.colors.primary)),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Text(user?.name ?? 'Usuario', style: context.text.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text(user?.email ?? '', style: context.text.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Sesión activa', style: context.text.titleMedium),
                  const SizedBox(height: AppSpacing.s),
                  Text('Tipo de cuenta: ${user?.roleLabel ?? 'No disponible'}', style: context.text.bodyLarge),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.error,
                  foregroundColor: context.colors.onError,
                ),
                onPressed: _signingOut ? null : _logout,
                icon: const Icon(Icons.logout_rounded),
                label: Text(_signingOut ? 'Cerrando sesión…' : 'Cerrar sesión'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
