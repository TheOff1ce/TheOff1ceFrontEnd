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

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

class AnalysisResponse {
  const AnalysisResponse({
    required this.medications,
    required this.requiresHumanReview,
    required this.warnings,
    this.patient,
    this.documentStored = false,
  });

  final PrescriptionPatient? patient;

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
        'document': documentStored ? const {'stored': true} : null,
        'medications': medications.map((e) => e.toJson()).toList(),
        'requires_human_review': requiresHumanReview,
        'warnings': warnings,
      };
}
