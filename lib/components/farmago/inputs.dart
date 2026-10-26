import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/farmago_tokens.dart';
import 'focus_ring.dart';

/// Campo de texto del manual (§8.3).
///
/// - La etiqueta va siempre visible arriba; los campos opcionales dicen "(opcional)".
/// - Alto 56 en móvil y 48 en desktop; el multilínea mide 120 como mínimo.
/// - El error va debajo, con icono "!" y el texto que dice qué corregir.
class FgTextField extends StatefulWidget {
  const FgTextField({
    super.key,
    required this.label,
    required this.controller,
    this.focusNode,
    this.opcional = false,
    this.ayuda,
    this.error,
    this.multilinea = false,
    this.iconoInicial,
    this.limpiable = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.inputFormatters,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool opcional;
  final String? ayuda;

  /// Mensaje de error (qué corregir). `null`: sin error.
  final String? error;
  final bool multilinea;
  final IconData? iconoInicial;

  /// Muestra un botón "limpiar" de 48×48 cuando hay texto (campos de búsqueda).
  final bool limpiable;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;

  @override
  State<FgTextField> createState() => _FgTextFieldState();
}

class _FgTextFieldState extends State<FgTextField> {
  FocusNode? _propio;
  bool _encima = false;

  FocusNode get _focus => widget.focusNode ?? (_propio ??= FocusNode());

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_cambioTexto);
  }

  @override
  void didUpdateWidget(FgTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_cambioTexto);
      widget.controller.addListener(_cambioTexto);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_cambioTexto);
    _propio?.dispose();
    super.dispose();
  }

  void _cambioTexto() {
    if (widget.limpiable && mounted) setState(() {});
  }

  OutlineInputBorder _borde(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(FgRadius.sm),
        borderSide: BorderSide(color: color, width: FgBorder.w2),
      );

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final altoMinimo = widget.multilinea
        ? 120.0
        : (FgBreakpoint.esCompacto(ancho) ? FgSize.inputMovil : FgSize.inputDesktop);
    final hayError = widget.error != null;
    final bordeReposo = hayError ? FgColors.peligro : (_encima ? FgColors.inkSoft : FgColors.lineaControl);
    final bordeFoco = hayError ? FgColors.peligro : FgColors.azul600;
    final texto = widget.controller.text;

    final campo = MouseRegion(
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() => _encima = false),
      child: FgFocusRing(
        focusNode: _focus,
        radius: FgRadius.sm,
        alwaysVisible: true,
        child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          autofocus: widget.autofocus,
          keyboardType: widget.multilinea ? TextInputType.multiline : widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          inputFormatters: widget.inputFormatters,
          autofillHints: widget.autofillHints,
          minLines: widget.multilinea ? 4 : 1,
          maxLines: widget.multilinea ? null : 1,
          style: FgText.body,
          cursorColor: FgColors.azul600,
          decoration: InputDecoration(
            filled: true,
            fillColor: FgColors.superficie,
            constraints: BoxConstraints(minHeight: altoMinimo),
            contentPadding: EdgeInsets.symmetric(
              horizontal: FgSpace.sp4,
              vertical: widget.multilinea ? FgSpace.sp3 : FgSpace.sp2,
            ),
            border: _borde(bordeReposo),
            enabledBorder: _borde(bordeReposo),
            focusedBorder: _borde(bordeFoco),
            errorBorder: _borde(FgColors.peligro),
            focusedErrorBorder: _borde(FgColors.peligro),
            prefixIcon: widget.iconoInicial == null
                ? null
                : Icon(widget.iconoInicial, size: FgSize.iconoMd, color: FgColors.inkSoft),
            suffixIcon: widget.limpiable && texto.isNotEmpty
                ? IconButton(
                    tooltip: 'Limpiar búsqueda',
                    icon: const Icon(Icons.close_rounded, size: FgSize.iconoMd),
                    constraints: const BoxConstraints(minWidth: FgSize.tapMin, minHeight: FgSize.tapMin),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged?.call('');
                    },
                  )
                : null,
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: widget.label,
            style: FgText.label,
            children: [
              if (widget.opcional)
                TextSpan(text: ' (opcional)', style: FgText.body.copyWith(color: FgColors.inkSoft)),
            ],
          ),
        ),
        const SizedBox(height: FgSpace.sp2),
        MergeSemantics(
          child: Semantics(label: widget.label, textField: true, child: campo),
        ),
        if (hayError) ...[
          const SizedBox(height: FgSpace.sp2),
          Semantics(
            liveRegion: true,
            container: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.error_outline_rounded, size: FgSize.iconoSm, color: FgColors.incumplidoFg),
                ),
                const SizedBox(width: FgSpace.sp2),
                Expanded(child: Text(widget.error!, style: FgText.caption.copyWith(color: FgColors.incumplidoFg))),
              ],
            ),
          ),
        ] else if (widget.ayuda != null) ...[
          const SizedBox(height: FgSpace.sp2),
          Text(widget.ayuda!, style: FgText.caption),
        ],
      ],
    );
  }
}
