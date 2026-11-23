import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../app/theme/farmago_tokens.dart';
import 'farmago/buttons.dart';

/// Trazos de una firma hecha con el dedo, y su exportación a PNG.
///
/// Las coordenadas son las del panel en píxeles lógicos; [toPng] dibuja lo mismo sobre fondo
/// blanco, así la firma se lee igual en modo claro, en modo oscuro y en el archivo guardado.
class SignaturePadController extends ChangeNotifier {
  final List<List<Offset>> _strokes = [];
  Size _size = Size.zero;

  /// Ancho máximo del PNG: de sobra para leer la firma y muy lejos de los 512 KB del servicio.
  static const maxPngWidth = 1200.0;

  bool get isEmpty => _strokes.isEmpty;
  bool get isNotEmpty => _strokes.isNotEmpty;

  /// Tamaño del panel tal como se dibujó la última vez.
  Size get size => _size;

  List<List<Offset>> get strokes => List.unmodifiable(_strokes.map(List<Offset>.unmodifiable));

  void _begin(Offset point) {
    _strokes.add([_clamp(point)]);
    notifyListeners();
  }

  void _extend(Offset point) {
    if (_strokes.isEmpty) return _begin(point);
    _strokes.last.add(_clamp(point));
    notifyListeners();
  }

  Offset _clamp(Offset p) => _size.isEmpty
      ? p
      : Offset(p.dx.clamp(0.0, _size.width).toDouble(), p.dy.clamp(0.0, _size.height).toDouble());

  void clear() {
    if (_strokes.isEmpty) return;
    _strokes.clear();
    notifyListeners();
  }

  /// PNG de la firma, o `null` si está vacía. Usa el tamaño del panel en pantalla.
  Future<Uint8List?> toPng({double pixelRatio = 2}) async {
    final size = _size;
    if (_strokes.isEmpty || size.isEmpty) return null;
    final ratio = math.min(pixelRatio, maxPngWidth / size.width);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    _SignaturePainter.paintStrokes(canvas, size, _strokes);
    final picture = recorder.endRecording();
    final image = await picture.toImage((size.width * ratio).ceil(), (size.height * ratio).ceil());
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }
}

/// Panel táctil para la firma de quien recibe (CU-14), con su etiqueta visible y "Borrar".
///
/// El trazo gana el gesto apenas el dedo toca el panel, para que la pantalla no se desplace
/// mientras firman.
class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    required this.controller,
    this.label = 'Firma de quien recibe',
    this.help = 'Pide a quien recibe que firme con el dedo dentro del recuadro.',
    this.height = FgSize.firmaAlto,
    this.enabled = true,
  });

  final SignaturePadController controller;
  final String label;
  final String help;
  final double height;

  /// `false` mientras se envía: la firma no cambia ni se borra.
  final bool enabled;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  SignaturePadController get _c => widget.controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _c,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.label, style: FgText.label)),
                FgButton(
                  label: 'Borrar',
                  icon: Icons.backspace_outlined,
                  variant: FgButtonVariant.ghost,
                  onPressed: widget.enabled && _c.isNotEmpty ? _c.clear : null,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: FgSpace.sp2),
              child: Text(widget.help, style: FgText.caption),
            ),
            Semantics(
              container: true,
              label: '${widget.label}. Panel para firmar con el dedo',
              value: _c.isEmpty ? 'Sin firma' : 'Firmado',
              child: LayoutBuilder(builder: (context, constraints) {
                _c._size = Size(constraints.maxWidth, widget.height);
                return DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(FgRadius.md),
                    border: Border.all(
                      color: _c.isEmpty ? FgColors.lineaControl : FgColors.azulTexto,
                      width: _c.isEmpty ? FgBorder.control : FgBorder.controlActivo,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(FgRadius.md),
                    child: RawGestureDetector(
                      behavior: HitTestBehavior.opaque,
                      gestures: widget.enabled
                          ? {
                              _ImmediatePanRecognizer: GestureRecognizerFactoryWithHandlers<_ImmediatePanRecognizer>(
                                () => _ImmediatePanRecognizer(debugOwner: this),
                                (r) => r
                                  ..dragStartBehavior = DragStartBehavior.down
                                  ..onStart = ((d) => _c._begin(d.localPosition))
                                  ..onUpdate = ((d) => _c._extend(d.localPosition)),
                              ),
                            }
                          : const <Type, GestureRecognizerFactory>{},
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, widget.height),
                        painter: _SignaturePainter(_c),
                        child: SizedBox(
                          height: widget.height,
                          width: constraints.maxWidth,
                          child: _c.isEmpty
                              ? Center(
                                  child: ExcludeSemantics(
                                    child: Text(
                                      'Firma aquí',
                                      style: FgText.body.copyWith(color: FgColors.firmaGuia),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
}

/// Arrastre que acepta el gesto en cuanto el dedo baja, antes que el desplazamiento de la lista.
class _ImmediatePanRecognizer extends PanGestureRecognizer {
  _ImmediatePanRecognizer({super.debugOwner});

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.controller) : super(repaint: controller);

  final SignaturePadController controller;

  static const _strokeWidth = 3.0;

  static void paintStrokes(Canvas canvas, Size size, List<List<Offset>> strokes) {
    canvas.drawRect(Offset.zero & size, Paint()..color = FgColors.firmaFondo);
    final line = Paint()
      ..color = FgColors.firmaTrazo
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    final dot = Paint()
      ..color = FgColors.firmaTrazo
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, _strokeWidth / 2, dot);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, line);
    }
  }

  @override
  void paint(Canvas canvas, Size size) => paintStrokes(canvas, size, controller._strokes);

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => oldDelegate.controller != controller;
}
