import '../types/pendiente.dart';
import 'pendiente_format.dart';

/// Cómo se presenta el plazo de un pendiente (manual §8.10 y §8.13).
///
/// Es solo presentación: el estado y la fecha límite vienen del backend. El tiempo restante se
/// calcula contra la hora del servidor (ver [PendienteResumen.ahora]).
class PlazoVista {
  const PlazoVista({
    required this.estado,
    required this.titular,
    required this.fecha,
    required this.fraccion,
    required this.semantica,
    this.palabraEstado,
    this.subtitulo,
    this.centroPrincipal,
    this.centroSecundario,
    this.vencidoSinActualizar = false,
  });

  factory PlazoVista.de(PendienteResumen p, Duration desdeCarga) {
    final limite = PendienteFormat.fechaHora(p.fechaLimite);
    final limiteLargo = PendienteFormat.fechaHoraLarga(p.fechaLimite);
    switch (p.cumplimientoPlazo) {
      case CumplimientoPlazo.vigente:
        final restante = p.restante(desdeCarga);
        if (restante <= Duration.zero) {
          // El backend aún no refleja el vencimiento: no se declara un estado, se pide actualizar.
          return PlazoVista(
            estado: CumplimientoPlazo.vigente,
            titular: 'Pasó la fecha límite',
            palabraEstado: CumplimientoPlazo.vigente.etiqueta,
            subtitulo: 'Actualiza para ver el estado.',
            fecha: 'Fecha límite $limite',
            fraccion: 0,
            semantica: 'Pasó la fecha límite, $limiteLargo. Actualiza para ver el estado actual.',
            vencidoSinActualizar: true,
          );
        }
        final total = p.plazoTotal.inSeconds;
        final fraccion = total <= 0 ? 0.0 : (restante.inSeconds / total).clamp(0.0, 1.0).toDouble();
        final minutosTotales = restante.inMinutes;
        final horas = minutosTotales ~/ 60;
        final minutos = minutosTotales % 60;
        return PlazoVista(
          estado: CumplimientoPlazo.vigente,
          titular: PendienteFormat.duracion(restante),
          palabraEstado: CumplimientoPlazo.vigente.etiqueta,
          fecha: 'Vence $limite',
          fraccion: fraccion,
          centroPrincipal: horas > 0 ? '$horas h' : '$minutos min',
          centroSecundario: horas > 0 ? '$minutos min' : null,
          semantica: 'Quedan ${PendienteFormat.duracionLarga(restante)} para la fecha límite, '
              '$limiteLargo. Estado: vigente.',
        );
      case CumplimientoPlazo.cumplido:
        final entregaOk = p.fechaEntrega;
        return PlazoVista(
          estado: CumplimientoPlazo.cumplido,
          titular: CumplimientoPlazo.cumplido.etiqueta,
          subtitulo: 'Entregado a tiempo',
          fecha: entregaOk == null ? 'Fecha límite $limite' : 'Entregado ${PendienteFormat.fechaHora(entregaOk)}',
          fraccion: 1,
          semantica: 'Cumplido. Entregado a tiempo'
              '${entregaOk == null ? '' : ', ${PendienteFormat.fechaHoraLarga(entregaOk)}'}.',
        );
      case CumplimientoPlazo.incumplido:
        final entregaTarde = p.fechaEntrega;
        if (entregaTarde != null) {
          final retraso = PendienteFormat.duracion(entregaTarde.difference(p.fechaLimite));
          return PlazoVista(
            estado: CumplimientoPlazo.incumplido,
            titular: CumplimientoPlazo.incumplido.etiqueta,
            subtitulo: 'Entregado $retraso después del límite',
            fecha: 'Entregado ${PendienteFormat.fechaHora(entregaTarde)}',
            fraccion: 0,
            semantica: 'Incumplido. Entregado $retraso después de la fecha límite, '
                '${PendienteFormat.fechaHoraLarga(entregaTarde)}.',
          );
        }
        final vencido = p.ahora(desdeCarga).difference(p.fechaLimite);
        return PlazoVista(
          estado: CumplimientoPlazo.incumplido,
          titular: CumplimientoPlazo.incumplido.etiqueta,
          subtitulo: 'Venció hace ${PendienteFormat.duracion(vencido)}',
          fecha: 'Fecha límite $limite',
          fraccion: 0,
          semantica: 'Incumplido. Venció hace ${PendienteFormat.duracionLarga(vencido)}, $limiteLargo.',
        );
    }
  }

  final CumplimientoPlazo estado;

  /// Línea principal (28/700): tiempo restante o palabra del estado.
  final String titular;

  /// Solo en estado vigente: la palabra del estado va aparte del tiempo.
  final String? palabraEstado;
  final String? subtitulo;

  /// Fecha de referencia (límite o entrega).
  final String fecha;

  /// Fracción del anillo que queda (tiempo restante / plazo total).
  final double fraccion;

  /// Texto dentro del anillo grande (m y l) cuando el plazo está vigente.
  final String? centroPrincipal;
  final String? centroSecundario;

  /// Descripción completa para lectores de pantalla.
  final String semantica;

  /// La fecha límite pasó pero el backend todavía dice "vigente": hay que volver a consultar.
  final bool vencidoSinActualizar;
}
