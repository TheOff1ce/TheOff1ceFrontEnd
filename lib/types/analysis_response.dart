import 'medication.dart';

class AnalysisResponse {
  const AnalysisResponse({
    required this.success,
    required this.medications,
    required this.requiresHumanReview,
    required this.warnings,
  });
  final bool success, requiresHumanReview;
  final List<Medication> medications;
  final List<String> warnings;
  factory AnalysisResponse.fromJson(Map<String, dynamic> j) => AnalysisResponse(
        success: j['success'] is bool ? j['success'] : true,
        medications: (j['medications'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Medication.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        requiresHumanReview: j['requires_human_review'] == true,
        warnings: (j['warnings'] as List? ?? []).map((e) => '$e').toList(),
      );
  Map<String, dynamic> toJson() => {
        'success': success,
        'medications': medications.map((e) => e.toJson()).toList(),
        'requires_human_review': requiresHumanReview,
        'warnings': warnings,
      };
}
