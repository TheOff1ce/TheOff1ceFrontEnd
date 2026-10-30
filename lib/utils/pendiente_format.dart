/// Formatos de datos del manual (§12), en español de Colombia, sin dependencias nuevas.
///
/// Todas las fechas se muestran en `America/Bogota` (UTC−5, sin cambio de hora), nunca con la
/// zona del dispositivo (manual §15).
abstract final class PendienteFormat {
  static const _mesesCortos = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  static const _mesesLargos = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  static const _desfaseBogota = Duration(hours: 5);

  /// Los campos de un `DateTime` UTC desplazado 5 h son la hora de pared de Bogotá.
  static DateTime _bogota(DateTime instante) => instante.toUtc().subtract(_desfaseBogota);

  /// `d MMM aaaa`, p. ej. "24 oct 2026".
  static String fecha(DateTime instante) {
    final b = _bogota(instante);
    return '${b.day} ${_mesesCortos[b.month - 1]} ${b.year}';
  }

  /// `h:mm a. m./p. m.` (12 h), p. ej. "3:30 p. m.".
  static String hora(DateTime instante) {
    final b = _bogota(instante);
    final hora12 = b.hour % 12 == 0 ? 12 : b.hour % 12;
    final minutos = b.minute.toString().padLeft(2, '0');
    return '$hora12:$minutos ${b.hour < 12 ? 'a. m.' : 'p. m.'}';
  }

  /// `d MMM aaaa, h:mm a. m./p. m.`, p. ej. "24 oct 2026, 3:30 p. m.".
  static String fechaHora(DateTime instante) => '${fecha(instante)}, ${hora(instante)}';

  /// Para lectores de pantalla: "26 de octubre de 2026, 9:15 a. m.".
  static String fechaHoraLarga(DateTime instante) {
    final b = _bogota(instante);
    return '${b.day} de ${_mesesLargos[b.month - 1]} de ${b.year}, ${hora(instante)}';
  }

  /// `N h M min` (>= 1 h) o `N min`. Redondea hacia abajo; un valor negativo se trata en positivo.
  static String duracion(Duration valor) {
    final minutosTotales = valor.abs().inMinutes;
    final horas = minutosTotales ~/ 60;
    final minutos = minutosTotales % 60;
    return horas > 0 ? '$horas h $minutos min' : '$minutos min';
  }

  /// "31 horas y 20 minutos" (para lectores de pantalla).
  static String duracionLarga(Duration valor) {
    final minutosTotales = valor.abs().inMinutes;
    final horas = minutosTotales ~/ 60;
    final minutos = minutosTotales % 60;
    final partesHoras = horas == 1 ? '1 hora' : '$horas horas';
    final partesMinutos = minutos == 1 ? '1 minuto' : '$minutos minutos';
    if (horas == 0) return partesMinutos;
    if (minutos == 0) return partesHoras;
    return '$partesHoras y $partesMinutos';
  }

  /// Relativo solo para novedades de menos de 24 h ("hace 3 h"); si no, la fecha completa.
  static String novedad(DateTime instante, DateTime ahora) {
    final transcurrido = ahora.difference(instante);
    if (transcurrido.isNegative || transcurrido.inHours >= 24) return fechaHora(instante);
    if (transcurrido.inMinutes < 1) return 'hace un momento';
    if (transcurrido.inMinutes < 60) return 'hace ${transcurrido.inMinutes} min';
    return 'hace ${transcurrido.inHours} h';
  }

  /// "1 de 3 medicamentos entregados".
  static String medicamentosEntregados(int entregados, int total) =>
      '$entregados de $total ${total == 1 ? 'medicamento entregado' : 'medicamentos entregados'}';

  /// Identificador del paciente sin exponerlo completo (manual §11: documento enmascarado).
  static String pacienteEnmascarado(String id) {
    final limpio = id.trim();
    if (limpio.length <= 4) return '•••• $limpio';
    return '•••• ${limpio.substring(limpio.length - 4)}';
  }

  /// El catálogo de tipos de novedad no está definido: el tipo es texto libre.
  /// Se muestra legible ("CONTACTO_PACIENTE" -> "Contacto paciente") sin cambiar el dato.
  static String tipoNovedad(String tipo) {
    final texto = tipo.trim().replaceAll('_', ' ');
    if (texto.isEmpty) return texto;
    final minuscula = texto == texto.toUpperCase() ? texto.toLowerCase() : texto;
    return minuscula[0].toUpperCase() + minuscula.substring(1);
  }
}
