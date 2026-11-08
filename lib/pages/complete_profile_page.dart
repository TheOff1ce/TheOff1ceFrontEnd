import 'package:flutter/material.dart';

import '../app/theme/farmago_tokens.dart';
import '../auth/auth_controller.dart';
import '../components/account/profile_form.dart';
import '../components/auth_ui.dart';
import '../components/farmago/buttons.dart';

/// Paso obligatorio después de crear la cuenta (correo o Google): sin estos datos no se usa la
/// app, porque órdenes, pendientes y domicilios necesitan saber quién es la persona.
class CompleteProfilePage extends StatelessWidget {
  const CompleteProfilePage({super.key, required this.auth});

  final AuthController auth;

  static String subtitleFor(String? role) => switch (role) {
        'PATIENT' => 'Con tu documento y tu EPS consultamos tus órdenes y pendientes. Solo te lo pedimos una vez.',
        'DELIVERY_DRIVER' => 'Necesitamos tu documento, tu celular y tu vehículo para asignarte domicilios.',
        'EPS' => 'Necesitamos tu documento y la EPS donde trabajas para darte acceso a sus pendientes.',
        _ => 'Necesitamos algunos datos para terminar de crear tu cuenta.',
      };

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    final name = user?.name.trim().split(RegExp(r'\s+')).first ?? '';
    return AuthShell(
      title: name.isEmpty ? 'Completa tu perfil' : 'Hola, $name. Completa tu perfil',
      subtitle: subtitleFor(user?.role),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // El formulario guarda y el enrutador deja pasar en cuanto el perfil queda completo.
          ProfileForm(auth: auth, submitLabel: 'Guardar y continuar', onDone: () {}),
          const SizedBox(height: FgSpace.sp5),
          Center(
            child: FgButton(
              label: 'Cerrar sesión',
              icon: Icons.logout_rounded,
              variant: FgButtonVariant.ghost,
              onPressed: auth.logout,
            ),
          ),
        ],
      ),
    );
  }
}
