import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/farmago_tokens.dart';

const _gap = FgSpace.sp2;
const _maxBox = 56.0;

double _boxSize(double available, int length) =>
    math.min(_maxBox, (available - _gap * (length - 1)) / length).clamp(32.0, _maxBox);

/// Una casilla del código: número grande y centrado.
class _Box extends StatelessWidget {
  const _Box({required this.size, required this.char, this.active = false, this.error = false, this.filled = false});

  final double size;
  final String char;
  final bool active, error, filled;

  @override
  Widget build(BuildContext context) {
    final color = error
        ? FgColors.peligro
        : active
            ? FgColors.azul600
            : filled
                ? FgColors.azul800
                : FgColors.lineaControl;
    return AnimatedContainer(
      duration: FgMotion.reducir(context, FgMotion.rapida),
      width: size,
      height: size * 1.15,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FgColors.superficie,
        borderRadius: BorderRadius.circular(FgRadius.sm),
        border: Border.all(color: color, width: active || error ? FgBorder.controlActivo : FgBorder.control),
      ),
      child: Text(char, style: FgText.num(FgText.h2).copyWith(color: FgColors.ink, height: 1)),
    );
  }
}

/// Código de un solo uso en casillas: una por dígito (6 por defecto).
///
/// Por dentro es un solo campo de texto invisible, así que pegar el código, el autocompletado del
/// SMS o correo, borrar y los lectores de pantalla funcionan como en cualquier campo. Las casillas
/// solo muestran lo escrito y cuál sigue.
class FgCodeInput extends StatefulWidget {
  const FgCodeInput({
    super.key,
    required this.controller,
    required this.label,
    this.length = 6,
    this.focusNode,
    this.ayuda,
    this.error,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final int length;
  final FocusNode? focusNode;
  final String? ayuda, error;
  final bool enabled, autofocus;
  final ValueChanged<String>? onChanged;

  /// Enter con el código completo. No se envía solo al escribir el último dígito: un error de
  /// dedo gastaría uno de los intentos, así que la persona confirma con el botón o con Enter.
  final ValueChanged<String>? onSubmitted;

  @override
  State<FgCodeInput> createState() => _FgCodeInputState();
}

class _FgCodeInputState extends State<FgCodeInput> {
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    _focus.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.removeListener(_rebuild);
    _ownFocus?.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _changed(String value) => widget.onChanged?.call(value);

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final hasError = widget.error != null;
    // La casilla activa es la siguiente por llenar (o la última si ya está completo).
    final activeIndex = math.min(text.length, widget.length - 1);
    final note = widget.error ?? widget.ayuda;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Text(widget.label, style: FgText.label)),
        const SizedBox(height: FgSpace.sp2),
        LayoutBuilder(builder: (context, constraints) {
          final size = _boxSize(constraints.maxWidth, widget.length);
          return Stack(children: [
            ExcludeSemantics(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  _Box(
                    size: size,
                    char: i < text.length ? text[i] : '',
                    filled: i < text.length,
                    active: widget.enabled && _focus.hasFocus && i == activeIndex,
                    error: hasError,
                  ),
                ],
              ]),
            ),
            // Campo real, invisible y del tamaño de las casillas: recibe toques, teclado y pegado.
            Positioned.fill(
              child: Semantics(
                label: '${widget.label}, ${widget.length} dígitos',
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  showCursor: false,
                  enableInteractiveSelection: false,
                  style: const TextStyle(color: Colors.transparent, fontSize: 1),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    isCollapsed: true,
                  ),
                  expands: true,
                  maxLines: null,
                  onChanged: _changed,
                  onSubmitted: (value) {
                    if (value.length == widget.length) widget.onSubmitted?.call(value);
                  },
                ),
              ),
            ),
          ]);
        }),
        if (note != null) ...[
          const SizedBox(height: FgSpace.sp2),
          Semantics(
            liveRegion: hasError,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (hasError) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.error_outline, size: 16, color: FgColors.peligro),
                ),
                const SizedBox(width: FgSpace.sp2),
              ],
              Expanded(
                child: Text(note, style: FgText.caption.copyWith(color: hasError ? FgColors.peligro : FgColors.inkSoft)),
              ),
            ]),
          ),
        ],
      ],
    );
  }
}

/// Código ya conocido, en casillas de solo lectura (por ejemplo el del repartidor).
class FgCodeBoxes extends StatelessWidget {
  const FgCodeBoxes({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Código ${code.split('').join(' ')}',
        excludeSemantics: true,
        child: LayoutBuilder(builder: (context, constraints) {
          final size = _boxSize(constraints.maxWidth, code.length);
          return Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < code.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              _Box(size: size, char: code[i], filled: true),
            ],
          ]);
        }),
      );
}
