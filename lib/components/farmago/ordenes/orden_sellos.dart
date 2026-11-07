import 'package:flutter/material.dart';

import '../../../app/theme/farmago_tokens.dart';
import '../../../types/ordenes.dart';
import '../../../utils/pendiente_format.dart';
import '../deadline_ring.dart';
import '../sello_estado.dart';

/// Sellos de autorización y vigencia (manual §8.8 + D4): forma + símbolo + palabra, nunca solo color.
extension AutorizacionSello on Autorizacion {
  Widget get sello => switch (this) {
        Autorizacion.autorizado => SelloEstado(
            palabra: etiqueta,
            forma: FormaAnillo.completo,
            solido: FgColors.cumplidoSolid,
            texto: FgColors.cumplidoFg,
            simbolo: Icons.check_rounded,
          ),
        Autorizacion.noRequiere => SelloEstado(
            palabra: etiqueta,
            forma: FormaAnillo.completo,
            solido: FgColors.vigenteSolid,
            texto: FgColors.vigenteFg,
            simbolo: Icons.remove_rounded,
          ),
        Autorizacion.porAutorizar => SelloEstado(
            palabra: etiqueta,
            forma: FormaAnillo.parcial,
            solido: FgColors.riesgoSolid,
            texto: FgColors.riesgoFg,
            simbolo: '!',
          ),
        Autorizacion.sinInformacion => SelloEstado(
            palabra: etiqueta,
            forma: FormaAnillo.punteado,
            solido: FgColors.lineaControl,
            texto: FgColors.neutroFg,
            simbolo: '?',
          ),
      };
}

extension VigenciaSello on Vigencia {
  Widget get sello => switch (this) {
        Vigencia.vigente => SelloEstado(
            palabra: etiqueta,
            forma: FormaAnillo.parcial,
            solido: FgColors.vigenteSolid,
            texto: FgColors.vigenteFg,
            simbolo: Icons.schedule_rounded,
          ),
        Vigencia.vencida => SelloEstado(
            palabra: etiqueta,
            forma: FormaAnillo.discontinuo,
            solido: FgColors.lineaControl,
            texto: FgColors.neutroFg,
            simbolo: Icons.close_rounded,
          ),
        Vigencia.sinInformacion => SelloEstado(
            palabra: etiqueta,
            forma: FormaAnillo.punteado,
            solido: FgColors.lineaControl,
            texto: FgColors.neutroFg,
            simbolo: '?',
          ),
      };
}

/// Reclamación: texto secundario con icono y palabra (16/400 `ink-soft`).
class ReclamacionTexto extends StatelessWidget {
  const ReclamacionTexto({super.key, required this.reclamacion});

  final Reclamacion reclamacion;

  IconData get _icono => switch (reclamacion) {
        Reclamacion.pendienteDeReclamar => Icons.inventory_2_outlined,
        Reclamacion.reclamado => Icons.task_alt_rounded,
        Reclamacion.sinInformacion => Icons.help_outline_rounded,
      };

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(_icono, size: FgSize.iconoSm, color: FgColors.inkSoft)),
          const SizedBox(width: FgSpace.sp2),
          Flexible(child: Text(reclamacion.etiqueta, style: FgText.caption)),
        ],
      );
}

/// Qué muestra el arco de una orden y cuánto vale su longitud. Todo sale de fechas del backend.
///
/// La longitud es `(vencimiento − consultadoEn) / (vencimiento − fechaOrden)`, acotada a [0, 1].
/// Se calcula contra `consultadoEn`, no contra el reloj del dispositivo, así que no avanza sola.
class ArcoOrden {
  const ArcoOrden({
    required this.fraccion,
    required this.principal,
    required this.secundario,
    required this.titulo,
    required this.semantica,
  });

  factory ArcoOrden.de(Orden orden, DateTime consultadoEn) {
    final vence = orden.vencimiento!;
    final restante = vence.difference(consultadoEn);
    final total = vence.difference(orden.fechaOrden).inSeconds;
    final fraccion = total <= 0 ? 0.0 : (restante.inSeconds / total).clamp(0.0, 1.0).toDouble();
    final String principal;
    final String secundario;
    final String titulo;
    final String larga;
    if (restante.inHours >= 24) {
      final dias = restante.inDays;
      principal = '$dias';
      secundario = dias == 1 ? 'día' : 'días';
      titulo = 'Vence en $dias ${dias == 1 ? 'día' : 'días'}';
      larga = '$dias ${dias == 1 ? 'día' : 'días'}';
    } else if (restante.inHours >= 1) {
      final horas = restante.inHours;
      principal = '$horas';
      secundario = 'h';
      titulo = 'Vence en $horas h';
      larga = '$horas ${horas == 1 ? 'hora' : 'horas'}';
    } else {
      final minutos = restante.isNegative ? 0 : restante.inMinutes;
      principal = '$minutos';
      secundario = 'min';
      titulo = 'Vence en $minutos min';
      larga = '$minutos ${minutos == 1 ? 'minuto' : 'minutos'}';
    }
    return ArcoOrden(
      fraccion: fraccion,
      principal: principal,
      secundario: secundario,
      titulo: titulo,
      semantica: 'Quedan $larga para el vencimiento de la orden, '
          '${PendienteFormat.fechaHoraLarga(vence)}. Estado: vigente.',
    );
  }

  final double fraccion;
  final String principal;
  final String secundario;
  final String titulo;
  final String semantica;
}

/// Arco de vigencia (D1): el gesto de marca aplicado al vencimiento real de la orden.
///
/// Vigente: arco azul que se dibuja en 600 ms. Vencida: anillo discontinuo neutro con `event_busy`.
/// Sin vencimiento no hay arco: quien lo usa no lo construye (manual §8.13).
class OrdenArco extends StatelessWidget {
  const OrdenArco({super.key, required this.orden, required this.consultadoEn});

  final Orden orden;
  final DateTime consultadoEn;

  static const size = DeadlineRingSize.s;

  @override
  Widget build(BuildContext context) {
    if (orden.vigencia == Vigencia.vencida) {
      return Semantics(
        image: true,
        label: 'Orden vencida${orden.vencimiento == null ? '' : ', ${PendienteFormat.fechaHoraLarga(orden.vencimiento!)}'}.',
        child: ExcludeSemantics(
          child: AnilloMarca(
            forma: FormaAnillo.discontinuo,
            color: FgColors.lineaControl,
            diametro: size.lado,
            trazo: size.trazo,
            centro: const Icon(Icons.event_busy_outlined, size: FgSize.simboloS, color: FgColors.inkSoft),
          ),
        ),
      );
    }
    final arco = ArcoOrden.de(orden, consultadoEn);
    return Semantics(
      image: true,
      label: arco.semantica,
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: arco.fraccion),
          duration: FgMotion.reducir(context, FgMotion.reloj),
          curve: FgMotion.ease,
          builder: (context, valor, _) => AnilloMarca(
            forma: FormaAnillo.parcial,
            color: FgColors.vigenteSolid,
            diametro: size.lado,
            trazo: size.trazo,
            fraccion: valor,
            centro: Padding(
              padding: const EdgeInsets.all(FgSpace.sp1),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(arco.principal, style: FgText.num(FgText.h3.copyWith(height: 1.1))),
                    Text(arco.secundario, style: FgText.caption.copyWith(height: 1.1)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
