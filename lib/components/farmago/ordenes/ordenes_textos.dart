import '../../../hooks/ordenes_controller.dart' show FiltroOrdenes;
import '../../../types/ordenes.dart';

/// Textos de «Órdenes y autorizaciones». Español de Colombia, «tú», frases cortas.
abstract final class OrdenesTextos {
  static const tituloPantalla = 'Órdenes';
  static const tituloPanel = 'Tus órdenes de medicamentos';
  static const notaEps = 'Los estados son los que informa tu EPS. FarmaGo no autoriza ni niega medicamentos.';
  static const consultaEnVivo = 'Consulta en vivo a tu EPS';
  static const recargar = 'Recargar';
  static const consultando = 'Consultando tu EPS en vivo…';
  static const consultandoLento = 'Tu EPS está tardando más de lo normal. Seguimos esperando su respuesta.';
  static const sinElegibles = 'Por ahora ningún medicamento se puede pedir a domicilio.';
  static const verCuales = 'Ver cuáles';
  static const estadosSegunEps = 'Estados según tu EPS';
  static const vigentes = 'Vigentes';
  static const sinVencimiento = 'Sin vencimiento informado';
  static const vencidasGrupo = 'Vencidas en los últimos 3 meses';
  static const soloConsulta = 'Solo para consulta.';
  static const quitarSeleccion = 'Quitar selección';
  static const pedirADomicilio = 'Pedir a domicilio';
  static const confirmarPedido = 'Confirmar pedido';
  static const actualizadoPorEps = 'Tu EPS actualizó este medicamento';
  static const tienePendiente = 'Este medicamento tiene un pendiente.';
  static const verEnPendientes = 'Ver en Pendientes';

  static const vacioTitulo = 'No tienes órdenes en este momento';
  static const vacioMensaje =
      'Cuando tu EPS emita una orden de medicamentos, la verás aquí con el estado de cada medicamento.';
  static const sinResultadosTitulo = 'No hay órdenes con este filtro';
  static const sinResultadosMensaje = 'Elige otro filtro para ver tus órdenes.';

  static const notaVencida = 'Esta orden venció. Puedes consultarla, pero ya no se puede pedir a domicilio.';
  static const notaSinVencimiento =
      'Como tu EPS no informó hasta cuándo puedes reclamarla, esta orden no se puede pedir a domicilio.';

  static String filtro(FiltroOrdenes f) => switch (f) {
        FiltroOrdenes.todas => 'Todas',
        FiltroOrdenes.domicilio => 'Para domicilio',
        FiltroOrdenes.porAutorizar => 'Por autorizar',
        FiltroOrdenes.vencidas => 'Vencidas',
      };

  static String medicamentos(int n) => n == 1 ? '1 medicamento' : '$n medicamentos';

  static String elegidos(int n) => n == 1 ? '1 medicamento elegido' : '$n medicamentos elegidos';

  static String puedesPedir(int n) => 'Puedes pedir $n a domicilio. Marca los que quieras.';

  static String elegirLos(int n) => 'Elegir los $n';

  static String cifraElegibles(int n) =>
      n == 1 ? 'medicamento que puedes pedir a domicilio' : 'medicamentos que puedes pedir a domicilio';

  static String cifraPorAutorizar(int n) =>
      n == 1 ? 'espera autorización de tu EPS' : 'esperan autorización de tu EPS';

  static String cifraVigentes(int n) => n == 1 ? 'orden vigente' : 'órdenes vigentes';

  static String ordenId(String id) => 'Orden $id';

  static String envioExitoso(int n) => 'Enviaste ${medicamentos(n)} a Domicilios';

  /// Motivos de no elegibilidad por fila. `null` para los de orden (van en la nota de la orden).
  static String? motivo(MotivoNoElegible motivo) => switch (motivo) {
        MotivoNoElegible.autorizacionPendiente => 'tu EPS aún no lo autoriza',
        MotivoNoElegible.autorizacionSinInformacion => 'tu EPS no informó si está autorizado',
        MotivoNoElegible.yaReclamado => 'ya lo reclamaste',
        MotivoNoElegible.reclamacionSinInformacion => 'tu EPS no informó si ya lo reclamaste',
        MotivoNoElegible.noPerteneceALaOrden => 'ya no hace parte de esta orden',
        MotivoNoElegible.ordenVencida || MotivoNoElegible.ordenSinVencimiento => null,
        MotivoNoElegible.desconocido => 'tu EPS no lo reporta como disponible',
      };

  /// «No se puede pedir a domicilio: tu EPS aún no lo autoriza.» o `null` si no hay motivo de fila.
  static String? frasesMotivos(List<MotivoNoElegible> motivos) {
    final textos = <String>[
      for (final m in motivos)
        if (motivo(m) case final t?) t,
    ];
    if (textos.isEmpty) return null;
    return 'No se puede pedir a domicilio: ${textos.toSet().join(' y ')}.';
  }
}
