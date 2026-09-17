import 'package:farma_go/types/analysis_response.dart';
import 'package:farma_go/types/medication.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Medication maps snake_case backend fields', () {
    final item = Medication.fromJson({
      'name': 'Amoxicilina',
      'active_ingredient': 'Amoxicilina',
      'pharmaceutical_form': 'Cápsula',
      'confidence': 0.96,
    });
    expect(item.activeIngredient, 'Amoxicilina');
    expect(item.pharmaceuticalForm, 'Cápsula');
    expect(item.confidence, .96);
    expect(item.toJson()['active_ingredient'], 'Amoxicilina');
  });

  test('AnalysisResponse maps warnings and review state', () {
    final response = AnalysisResponse.fromJson({
      'success': true,
      'requires_human_review': true,
      'warnings': ['Texto poco legible'],
      'medications': [
        {'name': 'Ibuprofeno'},
      ],
    });
    expect(response.requiresHumanReview, isTrue);
    expect(response.warnings, ['Texto poco legible']);
    expect(response.medications.single.name, 'Ibuprofeno');
  });
}
