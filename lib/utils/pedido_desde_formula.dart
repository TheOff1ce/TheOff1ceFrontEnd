import '../types/analysis_response.dart';
import '../types/order.dart';

/// Productos para «Pedir a casa» a partir del análisis de la fórmula.
///
/// - Solo los medicamentos con nombre leído (los ilegibles los escribe la persona).
/// - Nombre con la concentración ("Metformina 850 mg"), como lo pide la farmacia.
/// - Cantidad 1: el análisis cuenta tabletas, no cajas; la persona la ajusta antes de pedir.
/// - Sin repetidos y como máximo [max] productos, que es lo que acepta el formulario.
List<OrderItem> pedidoDesdeFormula(AnalysisResponse result, {int max = 20}) {
  final vistos = <String>{};
  final items = <OrderItem>[];
  for (final m in result.medications) {
    final nombre = _limpio([m.name, m.concentration].whereType<String>().join(' '));
    if (nombre.length < 2 || !vistos.add(nombre.toLowerCase())) continue;
    items.add(OrderItem(name: nombre, quantity: 1));
    if (items.length == max) break;
  }
  return items;
}

/// Quita lo que el formulario no acepta (< > { } \) y recorta a 120 caracteres.
String _limpio(String texto) {
  final s = texto.replaceAll(RegExp(r'[<>{}\\]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
  return s.length > 120 ? s.substring(0, 120).trim() : s;
}
