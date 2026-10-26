/// Roles de Auth que `pendientes-service` acepta al consultar pendientes.
///
/// Qué ve cada uno lo decide el backend: el paciente, solo los suyos; la EPS, los que tiene
/// asignados; el repartidor, todos (pendiente de acordar, ver docs/contratos del servicio).
enum PendientesRol {
  paciente,
  eps,
  repartidor;

  static PendientesRol? fromCode(String? code) => switch (code) {
        'PATIENT' => PendientesRol.paciente,
        'EPS' => PendientesRol.eps,
        'DELIVERY_DRIVER' => PendientesRol.repartidor,
        _ => null,
      };

  /// Solo EPS y repartidor pueden registrar novedades (el paciente solo consulta).
  bool get puedeRegistrarNovedad => this != PendientesRol.paciente;

  /// Muestra el identificador (enmascarado) del paciente: quien ve pendientes de otros.
  bool get veOtrosPacientes => this != PendientesRol.paciente;

  String get tituloLista => this == PendientesRol.paciente ? 'Mis pendientes' : 'Pendientes';

  String get tituloEntrada => tituloLista;

  String get descripcionEntrada => switch (this) {
        PendientesRol.paciente => 'Revisa el plazo y el estado de tus medicamentos pendientes.',
        PendientesRol.eps => 'Controla el plazo de 48 h de los pendientes de tus pacientes.',
        PendientesRol.repartidor => 'Consulta los pendientes por entregar y registra novedades.',
      };

  String get vacioTitulo => this == PendientesRol.paciente ? 'No tienes pendientes' : 'No hay pendientes';

  String get vacioMensaje => this == PendientesRol.paciente
      ? 'Cuando una entrega quede incompleta, la verás aquí.'
      : 'Cuando un dispensario reporte una entrega incompleta, la verás aquí.';
}
