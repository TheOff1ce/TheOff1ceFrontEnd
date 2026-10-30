import 'package:farma_go/types/analysis_response.dart';
import 'package:farma_go/types/auth_models.dart';
import 'package:farma_go/types/medication.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Medication maps snake_case backend fields and the review flag', () {
    final item = Medication.fromJson({
      'name': 'Amoxicilina',
      'active_ingredient': 'Amoxicilina',
      'pharmaceutical_form': 'Cápsula',
      'confidence': 0.96,
      'requires_review': false,
    });
    expect(item.activeIngredient, 'Amoxicilina');
    expect(item.pharmaceuticalForm, 'Cápsula');
    expect(item.confidence, .96);
    expect(item.requiresReview, isFalse);
    expect(item.toJson()['active_ingredient'], 'Amoxicilina');
  });

  test('FE-011: an unnamed medication stays null and needs review', () {
    final item = Medication.fromJson({'name': null, 'confidence': 0.99});
    expect(item.name, isNull);
    expect(item.hasName, isFalse);
    expect(item.requiresReview, isTrue);
  });

  test('FE-017: confidence is clamped and never rescaled', () {
    expect(Medication.fromJson({'name': 'A', 'confidence': 87}).confidence, 1.0);
    expect(Medication.fromJson({'name': 'A', 'confidence': 'x'}).confidence, isNull);
  });

  test('AnalysisResponse maps warnings and review state', () {
    final response = AnalysisResponse.fromJson({
      'success': true,
      'requires_human_review': true,
      'warnings': ['Texto poco legible'],
      'medications': [
        {'name': 'Ibuprofeno', 'confidence': 0.9},
      ],
    });
    expect(response.requiresHumanReview, isTrue);
    expect(response.warnings, ['Texto poco legible']);
    expect(response.medications.single.name, 'Ibuprofeno');
  });

  test('an empty result always requires review and warnings are bounded', () {
    final response = AnalysisResponse.fromJson({
      'medications': [],
      'warnings': List.generate(10, (i) => 'w$i ${'x' * 300}'),
    });
    expect(response.requiresHumanReview, isTrue);
    expect(response.warnings, hasLength(5));
    expect(response.warnings.first.length, lessThanOrEqualTo(161));
  });

  test('roles are shown with human labels', () {
    const user = AuthUser(id: '1', name: 'Ana', email: 'a@b.co', role: 'PATIENT');
    expect(user.roleLabel, 'Paciente');
  });
}
