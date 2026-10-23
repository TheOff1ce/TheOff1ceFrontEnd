class Medication {
  const Medication({
    this.name,
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
    this.requiresReview = false,
  });

  /// `null` when the analysis could not read the name (FE-011).
  final String? name;
  final String? activeIngredient,
      concentration,
      pharmaceuticalForm,
      presentation,
      dose,
      frequency,
      duration,
      quantity,
      instructions;

  /// Extraction confidence between 0 and 1, as returned by the API.
  final double? confidence;

  /// Server-side review decision for this medication (FE-017).
  final bool requiresReview;

  bool get hasName => name != null;

  factory Medication.fromJson(Map<String, dynamic> j) {
    final confidence = _confidence(j['confidence']);
    return Medication(
      name: _s(j['name']),
      activeIngredient: _s(j['active_ingredient']),
      concentration: _s(j['concentration']),
      pharmaceuticalForm: _s(j['pharmaceutical_form']),
      presentation: _s(j['presentation']),
      dose: _s(j['dose']),
      frequency: _s(j['frequency']),
      duration: _s(j['duration']),
      quantity: _s(j['quantity']),
      instructions: _s(j['instructions']),
      confidence: confidence,
      // Older API versions do not send the flag: an unnamed medication or a
      // missing confidence always needs review.
      requiresReview: j['requires_review'] == true || _s(j['name']) == null || confidence == null,
    );
  }

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
        'requires_review': requiresReview,
      };

  static String? _s(dynamic v) {
    if (v == null) return null;
    final text = '$v'.trim();
    return text.isEmpty ? null : text;
  }

  static double? _confidence(dynamic v) {
    final value = v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
    if (value == null || value.isNaN) return null;
    return value.clamp(0.0, 1.0).toDouble();
  }
}
