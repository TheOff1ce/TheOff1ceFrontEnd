import 'package:flutter/material.dart';

import '../app/theme/farmago_tokens.dart';
import '../auth/auth_controller.dart';
import '../components/account/change_password_form.dart';
import '../components/account/profile_form.dart';
import '../components/farmago/buttons.dart';
import '../components/farmago/feedback.dart';
import '../components/farmago/layout.dart';
import '../types/auth_models.dart';
import '../utils/pendiente_format.dart';

/// "Mi cuenta": datos de la cuenta, cambio de contraseña (HU-005 / HU-039) y cierre de sesión.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key, required this.auth, required this.onBack});

  final AuthController auth;
  final VoidCallback onBack;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _changingPassword = false;
  bool _editingProfile = false;
  bool _signingOut = false;

  void _profileSaved() {
    setState(() => _editingProfile = false);
    showFgToast(context, 'Guardamos tus datos.');
  }

  Future<void> _logout() async {
    setState(() => _signingOut = true);
    // Nunca falla para la persona: la sesión local siempre se cierra.
    await widget.auth.logout();
    if (mounted) setState(() => _signingOut = false);
  }

  void _passwordChanged() {
    setState(() => _changingPassword = false);
    showFgToast(context, 'Contraseña cambiada. Cerramos tu sesión en los demás dispositivos.');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.auth,
        builder: (context, _) {
          final user = widget.auth.user;
          // §23: contenido centrado a ancho de lectura (antes pegado a la izquierda).
          return FgScreen(
            titulo: 'Mi cuenta',
            onBack: widget.onBack,
            anchoMaximo: FgSize.lectura,
            children: [
              Builder(
                builder: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (user != null) _Identity(user: user),
                    const SizedBox(height: FgSpace.sp6),
                    if (user != null) ...[
                      const _SectionTitle('Tus datos'),
                      AnimatedSize(
                        duration: FgMotion.reducir(context, FgMotion.media),
                        curve: FgMotion.ease,
                        alignment: Alignment.topCenter,
                        child: _editingProfile
                            ? Container(
                                padding: const EdgeInsets.all(FgSpace.sp5),
                                decoration: FgDecor.tarjeta(),
                                child: ProfileForm(
                                  auth: widget.auth,
                                  onDone: _profileSaved,
                                  onCancel: () => setState(() => _editingProfile = false),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _Details(user: user),
                                  if (user.role != 'ADMIN') ...[
                                    const SizedBox(height: FgSpace.sp4),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: FgButton(
                                        label: 'Editar datos',
                                        icon: Icons.edit_outlined,
                                        variant: FgButtonVariant.secondary,
                                        onPressed: () => setState(() => _editingProfile = true),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                      const SizedBox(height: FgSpace.sp6),
                      const _SectionTitle('Contraseña'),
                      _PasswordSection(
                        user: user,
                        auth: widget.auth,
                        open: _changingPassword,
                        onOpen: () => setState(() => _changingPassword = true),
                        onCancel: () => setState(() => _changingPassword = false),
                        onDone: _passwordChanged,
                      ),
                      const SizedBox(height: FgSpace.sp6),
                    ],
                    const _SectionTitle('Sesión'),
                    Text(
                      'Cierra la sesión en este dispositivo. Tus datos se quedan guardados.',
                      style: FgText.body.copyWith(color: FgColors.inkSoft),
                    ),
                    const SizedBox(height: FgSpace.sp4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FgButton(
                        label: 'Cerrar sesión',
                        icon: Icons.logout,
                        variant: FgButtonVariant.danger,
                        loading: _signingOut,
                        loadingLabel: 'Cerrando sesión…',
                        onPressed: _logout,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
}

String _initials(String name, String email) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();
  final first = words.first[0];
  final last = words.length > 1 ? words.last[0] : '';
  return '$first$last'.toUpperCase();
}

/// Bloque de identidad: monograma, nombre, correo y rol. §23: sin la franja de degradado de marca
/// (decoraba sin informar); tarjeta con sombra baja.
class _Identity extends StatelessWidget {
  const _Identity({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final compacto = FgBreakpoint.esCompacto(MediaQuery.sizeOf(context).width);
    final monograma = Container(
      width: compacto ? 64 : 80,
      height: compacto ? 64 : 80,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: FgColors.azul100, shape: BoxShape.circle),
      child: ExcludeSemantics(
        child: Text(
          _initials(user.name, user.email),
          style: (compacto ? FgText.h3 : FgText.h2).copyWith(color: FgColors.azul800),
        ),
      ),
    );
    final datos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(user.name.isEmpty ? 'Sin nombre' : user.name, style: FgText.h2),
        ),
        const SizedBox(height: FgSpace.sp1),
        Text(user.email, style: FgText.body.copyWith(color: FgColors.inkSoft)),
        const SizedBox(height: FgSpace.sp3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp3, vertical: FgSpace.sp1),
          decoration: BoxDecoration(
            color: FgColors.vigenteBg,
            borderRadius: BorderRadius.circular(FgRadius.pill),
          ),
          child: Text(
            user.roleLabel,
            style: FgText.caption.copyWith(color: FgColors.vigenteFg, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
    return Container(
      padding: EdgeInsets.all(compacto ? FgSpace.sp4 : FgSpace.sp5),
      decoration: FgDecor.tarjeta(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          monograma,
          SizedBox(width: compacto ? FgSpace.sp4 : FgSpace.sp5),
          Expanded(child: datos),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: FgSpace.sp3),
        child: Semantics(header: true, child: Text(text, style: FgText.h3)),
      );
}

/// Datos agrupados por tema (§23, ley de Miller y Gestalt proximidad): antes eran 12 filas seguidas
/// en una sola caja. Cada grupo es una tarjeta; los grupos sin datos no se muestran.
class _Details extends StatelessWidget {
  const _Details({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final p = user.profile;
    final birth = p.birthDate;
    final created = user.createdAt;
    final lastLogin = user.lastLoginAt;
    final grupos = <(String, List<(String, Widget)>)>[
      (
        'Datos personales',
        [
          ('Nombre', _value(user.name.isEmpty ? 'Sin nombre' : user.name)),
          if (p.hasDocument) ('Documento', _value('${p.documentType!.code} ${p.documentNumber}', numeric: true)),
          if (birth != null) ('Fecha de nacimiento', _value(PendienteFormat.fecha(birth), numeric: true)),
          if (p.eps != null) ('EPS', _value(p.eps!)),
        ]
      ),
      (
        'Contacto',
        [
          ('Correo', _EmailValue(user: user)),
          if (p.phone != null) ('Celular', _value(p.phone!, numeric: true)),
          if (p.address != null) ('Dirección de entrega', _value(p.address!)),
        ]
      ),
      (
        'Trabajo',
        [
          if (p.vehicleType != null)
            (
              'Vehículo',
              _value(p.vehiclePlate == null ? p.vehicleType!.label : '${p.vehicleType!.label} · ${p.vehiclePlate}')
            ),
          if (p.organization != null) ('EPS donde trabajas', _value(p.organization!)),
          if (p.position != null) ('Cargo', _value(p.position!)),
        ]
      ),
      (
        'Actividad',
        [
          if (created != null) ('Cuenta creada', _value(PendienteFormat.fecha(created), numeric: true)),
          if (lastLogin != null) ('Último ingreso', _value(PendienteFormat.fechaHora(lastLogin), numeric: true)),
        ]
      ),
    ];
    final visibles = [
      for (final g in grupos)
        if (g.$2.isNotEmpty) g
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (titulo, filas)) in visibles.indexed) ...[
          if (i > 0) const SizedBox(height: FgSpace.sp4),
          Container(
            decoration: FgDecor.tarjeta(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(FgSpace.sp4, FgSpace.sp4, FgSpace.sp4, FgSpace.sp1),
                  child: Semantics(header: true, child: Text(titulo, style: FgText.captionFuerte)),
                ),
                for (final (index, (label, value)) in filas.indexed) ...[
                  if (index > 0)
                    const Divider(
                      height: FgBorder.w1,
                      thickness: FgBorder.w1,
                      color: FgColors.lineaSuave,
                      indent: FgSpace.sp4,
                      endIndent: FgSpace.sp4,
                    ),
                  _DetailRow(label: label, value: value),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  static Widget _value(String text, {bool numeric = false}) =>
      Text(text, style: numeric ? FgText.num(FgText.body) : FgText.body);
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final compacto = FgBreakpoint.esCompacto(MediaQuery.sizeOf(context).width);
    final etiqueta = Text(label, style: FgText.caption);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FgSpace.sp4, vertical: FgSpace.sp3),
        child: compacto
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [etiqueta, const SizedBox(height: FgSpace.sp1), value],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [SizedBox(width: 200, child: etiqueta), Expanded(child: value)],
              ),
      ),
    );
  }
}

class _EmailValue extends StatelessWidget {
  const _EmailValue({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    // Sin datos de verificación (versiones anteriores de Auth) solo se muestra el correo.
    final known = user.provider.isNotEmpty;
    final verified = user.emailVerified;
    return Wrap(
      spacing: FgSpace.sp3,
      runSpacing: FgSpace.sp1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(user.email, style: FgText.body),
        if (known)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                verified ? Icons.verified_outlined : Icons.error_outline,
                size: FgSize.iconoSm,
                color: verified ? FgColors.cumplidoFg : FgColors.riesgoFg,
              ),
              const SizedBox(width: FgSpace.sp1),
              Text(
                verified ? 'Verificado' : 'Sin verificar',
                style: FgText.caption.copyWith(
                  color: verified ? FgColors.cumplidoFg : FgColors.riesgoFg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _PasswordSection extends StatelessWidget {
  const _PasswordSection({
    required this.user,
    required this.auth,
    required this.open,
    required this.onOpen,
    required this.onCancel,
    required this.onDone,
  });

  final AuthUser user;
  final AuthController auth;
  final bool open;
  final VoidCallback onOpen, onCancel, onDone;

  @override
  Widget build(BuildContext context) {
    if (!user.hasPassword) {
      return Text(
        'Entras con tu cuenta de Google, así que FarmaGo no guarda una contraseña tuya. '
        'Si quieres cambiarla, hazlo desde tu cuenta de Google.',
        style: FgText.body.copyWith(color: FgColors.inkSoft),
      );
    }
    return AnimatedSize(
      duration: FgMotion.reducir(context, FgMotion.media),
      curve: FgMotion.ease,
      alignment: Alignment.topCenter,
      child: open
          ? Container(
              padding: const EdgeInsets.all(FgSpace.sp5),
              decoration: FgDecor.tarjeta(),
              child: ChangePasswordForm(auth: auth, onDone: onDone, onCancel: onCancel),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'La usas para entrar con tu correo. Al cambiarla, se cierra tu sesión en los demás '
                  'dispositivos y este sigue abierto.',
                  style: FgText.body.copyWith(color: FgColors.inkSoft),
                ),
                const SizedBox(height: FgSpace.sp4),
                FgButton(
                  label: 'Cambiar contraseña',
                  icon: Icons.lock_reset,
                  variant: FgButtonVariant.secondary,
                  onPressed: onOpen,
                ),
              ],
            ),
    );
  }
}
