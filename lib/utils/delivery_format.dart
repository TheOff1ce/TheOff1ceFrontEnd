/// Human Spanish formatting for distances, durations and arrival times.
abstract final class DeliveryFormat {
  static String distance(int meters) {
    if (meters < 1000) return '$meters m';
    final km = (meters / 1000).toStringAsFixed(1).replaceAll('.', ',');
    return '$km km';
  }

  static String duration(int seconds) {
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }

  /// Local clock time, e.g. "3:45 p. m.".
  static String clock(DateTime time) {
    final local = time.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$hour12:$minutes ${local.hour < 12 ? 'a. m.' : 'p. m.'}';
  }

  static String eta(DateTime? eta, {DateTime? now}) {
    if (eta == null) return 'Sin estimado';
    final remaining = eta.difference(now ?? DateTime.now());
    if (remaining.inMinutes <= 0) return 'Llegando';
    return '${clock(eta)} (en ${duration(remaining.inSeconds)})';
  }

  static String items(int count) => count == 1 ? '1 producto' : '$count productos';
}
