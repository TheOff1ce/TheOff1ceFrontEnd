import 'medication.dart';

/// Patient as printed on the prescription (HU-031).
class PrescriptionPatient {
  const PrescriptionPatient({this.name, this.documentType, this.documentNumber});

  final String? name, documentType, documentNumber;

  String? get document => [documentType, documentNumber].whereType<String>().join(' ').trim().nullIfEmpty;

  static PrescriptionPatient? fromJson(Object? json) {
    if (json is! Map) return null;
    String? text(Object? v) => v == null ? null : '$v'.trim().nullIfEmpty;
    final patient = PrescriptionPatient(
      name: text(json['name']),
      documentType: text(json['document_type']),
      documentNumber: text(json['document_number']),
    );
    return patient.name == null && patient.documentNumber == null ? null : patient;
  }

  Map<String, dynamic> toJson() =>
      {'name': name, 'document_type': documentType, 'document_number': documentNumber};
}

String? _text(Object? v) => v == null ? null : '$v'.trim().nullIfEmpty;

/// Datos de la fórmula tal como aparecen impresos (paso 3). `issueDate` llega en ISO si el
/// servicio la reconoció; si no, como se leyó, para que el paciente la corrija.
class PrescriptionInfo {
  const PrescriptionInfo({
    this.issueDate,
    this.authorizationNumber,
    this.prescriberName,
    this.prescriberLicense,
    this.epsName,
  });

  final String? issueDate, authorizationNumber, prescriberName, prescriberLicense, epsName;

  static PrescriptionInfo? fromJson(Object? json) {
    if (json is! Map) return null;
    final info = PrescriptionInfo(
      issueDate: _text(json['issue_date']),
      authorizationNumber: _text(json['authorization_number']),
      prescriberName: _text(json['prescriber_name']),
      prescriberLicense: _text(json['prescriber_license']),
      epsName: _text(json['eps_name']),
    );
    final empty = [info.issueDate, info.authorizationNumber, info.prescriberName, info.prescriberLicense, info.epsName]
        .every((v) => v == null);
    return empty ? null : info;
  }

  Map<String, dynamic> toJson() => {
        'issue_date': issueDate,
        'authorization_number': authorizationNumber,
        'prescriber_name': prescriberName,
        'prescriber_license': prescriberLicense,
        'eps_name': epsName,
      };
}

/// Resultado de la validación de la fórmula (paso 4), hecha por código en el servicio, sin IA.
enum PrescriptionValidationStatus {
  valid('VALID'),
  incomplete('INCOMPLETE'),
  expired('EXPIRED'),
  unknown('UNKNOWN');

  const PrescriptionValidationStatus(this.code);

  final String code;

  static PrescriptionValidationStatus fromCode(Object? code) =>
      values.firstWhere((s) => s.code == code, orElse: () => PrescriptionValidationStatus.unknown);
}

class PrescriptionValidation {
  const PrescriptionValidation({
    required this.status,
    this.missingFields = const [],
    this.issueDate,
    this.expiresOn,
  });

  final PrescriptionValidationStatus status;

  /// Campos que faltan o no se pudieron confirmar: `patient.name`, `patient.document_number`,
  /// `prescription.issue_date` y `medications`.
  final List<String> missingFields;
  final DateTime? issueDate, expiresOn;

  bool get isValid => status == PrescriptionValidationStatus.valid;

  static PrescriptionValidation? fromJson(Object? json) {
    if (json is! Map) return null;
    return PrescriptionValidation(
      status: PrescriptionValidationStatus.fromCode(json['status']),
      missingFields: (json['missing_fields'] as List? ?? const []).map((e) => '$e').toList(),
      issueDate: DateTime.tryParse(json['issue_date']?.toString() ?? ''),
      expiresOn: DateTime.tryParse(json['expires_on']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.code,
        'missing_fields': missingFields,
        'issue_date': issueDate == null ? null : _isoDate(issueDate!),
        'expires_on': expiresOn == null ? null : _isoDate(expiresOn!),
      };

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

class AnalysisResponse {
  const AnalysisResponse({
    required this.medications,
    required this.requiresHumanReview,
    required this.warnings,
    this.patient,
    this.prescription,
    this.validation,
    this.documentStored = false,
  });

  final PrescriptionPatient? patient;

  /// Fecha, autorización, médico y EPS leídos de la fórmula (servicios recientes).
  final PrescriptionInfo? prescription;

  /// `null` con versiones antiguas del servicio de IA.
  final PrescriptionValidation? validation;

  /// The prescription image was kept in FarmaGo's private storage.
  final bool documentStored;
  final bool requiresHumanReview;
  final List<Medication> medications;
  final List<String> warnings;

  bool get isEmpty => medications.isEmpty;

  factory AnalysisResponse.fromJson(Map<String, dynamic> j) {
    final medications = (j['medications'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Medication.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return AnalysisResponse(
      patient: PrescriptionPatient.fromJson(j['patient']),
      prescription: PrescriptionInfo.fromJson(j['prescription']),
      validation: PrescriptionValidation.fromJson(j['validation']),
      documentStored: j['document'] is Map,
      medications: medications,
      // An empty extraction always needs a human look, even with older APIs.
      requiresHumanReview: j['requires_human_review'] == true || medications.isEmpty,
      warnings: (j['warnings'] as List? ?? const [])
          .map((e) => '$e'.trim())
          .where((e) => e.isNotEmpty)
          .take(_maxWarnings)
          .map((e) => e.length > _maxWarningLength ? '${e.substring(0, _maxWarningLength)}…' : e)
          .toList(),
    );
  }

  static const _maxWarnings = 5;
  static const _maxWarningLength = 160;

  Map<String, dynamic> toJson() => {
        'success': true,
        'patient': patient?.toJson(),
        'prescription': prescription?.toJson(),
        'validation': validation?.toJson(),
        'document': documentStored ? const {'stored': true} : null,
        'medications': medications.map((e) => e.toJson()).toList(),
        'requires_human_review': requiresHumanReview,
        'warnings': warnings,
      };
}
