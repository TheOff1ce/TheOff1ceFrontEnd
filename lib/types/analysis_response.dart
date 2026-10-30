import 'medication.dart';

class AnalysisResponse {
  const AnalysisResponse({
    required this.medications,
    required this.requiresHumanReview,
    required this.warnings,
  });

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
        'medications': medications.map((e) => e.toJson()).toList(),
        'requires_human_review': requiresHumanReview,
        'warnings': warnings,
      };
}
