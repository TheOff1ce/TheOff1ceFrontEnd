import 'dart:io';

import 'package:farma_go/app/theme/farmago_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carga la fuente real del proyecto (Atkinson) y la fuente de iconos de Material del SDK, para que
/// las capturas (goldens) muestren texto e iconos reales y no cuadros.
///
/// La ruta de iconos sale de `FLUTTER_ROOT`, que la variable de entorno de Flutter define en CI y en
/// cada máquina; nunca de una ruta fija del equipo. Así las capturas se generan igual en cualquier
/// entorno. Si el SDK no está disponible, falla en lugar de capturar cuadros en silencio.
Future<void> cargarFuentesReales() async {
  final cargador = FontLoader(FgText.family);
  for (final peso in [400, 500, 600, 700]) {
    cargador.addFont(rootBundle.load('assets/fonts/atkinson/AtkinsonHyperlegibleNext-$peso.ttf'));
  }
  await cargador.load();

  final iconos = File(_rutaIconosMaterial());
  final cargadorIconos = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.view(iconos.readAsBytesSync().buffer)));
  await cargadorIconos.load();
}

String _rutaIconosMaterial() {
  final raiz = Platform.environment['FLUTTER_ROOT'];
  if (raiz == null || raiz.isEmpty) {
    throw TestFailure(
      'Defina FLUTTER_ROOT con la carpeta del SDK de Flutter para cargar los iconos de las capturas.',
    );
  }
  final ruta = '$raiz/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  if (!File(ruta).existsSync()) {
    throw TestFailure('No se encontró la fuente de iconos en $ruta. Ejecute "flutter precache".');
  }
  return ruta;
}
