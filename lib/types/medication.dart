class Medication {
  const Medication({
    required this.name,
    this.activeIngredient,
    this.concentration,
    this.pharmaceuticalForm,
    this.presentation,
    this.dose,
    this.frequency,
    this.duration,
    this.quantity,
    this.instructions,
    this.confidence,
  });
  final String name;
  final String? activeIngredient,
      concentration,
      pharmaceuticalForm,
      presentation,
      dose,
      frequency,
      duration,
      quantity,
      instructions;
  final double? confidence;
  factory Medication.fromJson(Map<String, dynamic> j) => Medication(
        name: '${j['name'] ?? ''}',
        activeIngredient: _s(j['active_ingredient']),
        concentration: _s(j['concentration']),
        pharmaceuticalForm: _s(j['pharmaceutical_form']),
        presentation: _s(j['presentation']),
        dose: _s(j['dose']),
        frequency: _s(j['frequency']),
        duration: _s(j['duration']),
        quantity: _s(j['quantity']),
        instructions: _s(j['instructions']),
        confidence: j['confidence'] is num
            ? (j['confidence'] as num).toDouble()
            : double.tryParse('${j['confidence']}'),
      );
  Map<String, dynamic> toJson() => {
        'name': name,
        'active_ingredient': activeIngredient,
        'concentration': concentration,
        'pharmaceutical_form': pharmaceuticalForm,
        'presentation': presentation,
        'dose': dose,
        'frequency': frequency,
        'duration': duration,
        'quantity': quantity,
        'instructions': instructions,
        'confidence': confidence,
      };
  static String? _s(dynamic v) => v == null || '$v'.isEmpty ? null : '$v';
}
