import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

Future<void> cargarFuenteIconosMaterial() async {
  for (final ruta in _rutasMaterialIcons()) {
    final archivo = File(ruta);
    if (!archivo.existsSync()) continue;
    final cargadorIconos = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(archivo.readAsBytesSync().buffer)));
    await cargadorIconos.load();
    return;
  }
}

Iterable<String> _rutasMaterialIcons() sync* {
  for (final raiz in _raicesFlutter()) {
    yield '${raiz}${Platform.pathSeparator}bin${Platform.pathSeparator}cache${Platform.pathSeparator}artifacts${Platform.pathSeparator}material_fonts${Platform.pathSeparator}MaterialIcons-Regular.otf';
    yield '${raiz}${Platform.pathSeparator}bin${Platform.pathSeparator}cache${Platform.pathSeparator}dart-sdk${Platform.pathSeparator}bin${Platform.pathSeparator}resources${Platform.pathSeparator}devtools${Platform.pathSeparator}assets${Platform.pathSeparator}fonts${Platform.pathSeparator}MaterialIcons-Regular.otf';
  }
  yield r'C:\Users\NIKOL\Downloads\flutter\bin\cache\dart-sdk\bin\resources\devtools\assets\fonts\MaterialIcons-Regular.otf';
}

Iterable<String> _raicesFlutter() sync* {
  final visitadas = <String>{};
  for (final candidata in [
    Platform.environment['FLUTTER_ROOT'],
    Platform.environment['FLUTTER_HOME'],
    _flutterRootDesdeDart(),
  ]) {
    if (candidata == null || candidata.isEmpty || !visitadas.add(candidata)) continue;
    yield candidata;
  }
}

String? _flutterRootDesdeDart() {
  final regex = RegExp(r'^(.*)[/\\]bin[/\\]cache[/\\]dart-sdk[/\\]bin[/\\]dart(?:\.exe)?$');
  final match = regex.firstMatch(Platform.resolvedExecutable);
  return match?.group(1);
}
