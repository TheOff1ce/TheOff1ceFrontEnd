part of 'profile_form.dart';

class _LockedDocument extends StatelessWidget {
  const _LockedDocument({required this.type, required this.number});

  final DocumentType type;
  final String number;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Documento', style: FgText.label),
            const SizedBox(height: FgSpace.sp1),
            Text('${type.label} · $number', style: FgText.num(FgText.body)),
            const SizedBox(height: FgSpace.sp1),
            const Text(
              'Para corregirlo, pide ayuda a un administrador.',
              style: FgText.caption,
            ),
          ],
        ),
      );
}

class _ConsentCheck extends StatelessWidget {
  const _ConsentCheck({required this.value, required this.onChanged, this.error});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: InkWell(
              borderRadius: BorderRadius.circular(FgRadius.sm),
              onTap: onChanged == null ? null : () => onChanged!(!value),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(value: value, onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false)),
                  const SizedBox(width: FgSpace.sp2),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: FgSpace.sp2),
                      child: Text(
                        'Autorizo a FARMA GO a tratar mis datos personales para gestionar mis medicamentos y '
                        'domicilios, según la Ley 1581 de 2012. Puedo consultarlos, corregirlos o pedir que se '
                        'borren.',
                        style: FgText.body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: FgSpace.sp1),
              child: _FieldError(error!),
            ),
        ],
      );
}

/// Error bajo un grupo de opciones o la casilla: icono + texto, como en los campos de texto.
class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.error_outline, size: 16, color: FgColors.peligro),
            ),
            const SizedBox(width: FgSpace.sp2),
            Expanded(child: Text(message, style: FgText.caption.copyWith(color: FgColors.peligro))),
          ],
        ),
      );
}
