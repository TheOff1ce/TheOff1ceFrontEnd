/// Datos personales que cada rol completa después de crear la cuenta (local o Google).
library;

enum DocumentType {
  cc('CC', 'Cédula de ciudadanía'),
  ti('TI', 'Tarjeta de identidad'),
  ce('CE', 'Cédula de extranjería'),
  pa('PA', 'Pasaporte'),
  ppt('PPT', 'Permiso por protección temporal');

  const DocumentType(this.code, this.label);

  final String code, label;

  /// Cédula y tarjeta de identidad son solo números; extranjería y pasaporte admiten letras.
  bool get allowsLetters => this == DocumentType.ce || this == DocumentType.pa;

  static DocumentType? fromCode(String? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

enum VehicleType {
  moto('MOTO', 'Moto'),
  bicicleta('BICICLETA', 'Bicicleta'),
  carro('CARRO', 'Carro');

  const VehicleType(this.code, this.label);

  final String code, label;

  bool get needsPlate => this != VehicleType.bicicleta;

  static VehicleType? fromCode(String? code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

/// Sugerencias para el campo EPS. Es texto libre: el mapa de EPS cambia con frecuencia.
const epsSuggestions = [
  'Nueva EPS',
  'EPS Sura',
  'Sanitas',
  'Salud Total',
  'Compensar',
  'Famisanar',
  'Coosalud',
  'Mutual Ser',
  'SOS (Servicio Occidental de Salud)',
  'Aliansalud',
  'Emssanar',
  'Asmet Salud',
  'Savia Salud',
  'Capital Salud',
  'Cajacopi',
  'Capresoca',
  'Comfenalco Valle',
  'Salud Mía',
  'Familiar de Colombia',
  'Dusakawi',
  'Pijaos Salud',
  'Anas Wayuu',
  'Mallamas',
];

class UserProfile {
  const UserProfile({
    this.documentType,
    this.documentNumber,
    this.phone,
    this.birthDate,
    this.eps,
    this.address,
    this.vehicleType,
    this.vehiclePlate,
    this.organization,
    this.position,
    this.dataConsentAt,
  });

  static const empty = UserProfile();

  final DocumentType? documentType;
  final String? documentNumber, phone, eps, address, vehiclePlate, organization, position;
  final DateTime? birthDate, dataConsentAt;
  final VehicleType? vehicleType;

  bool get hasDocument => documentType != null && (documentNumber ?? '').isNotEmpty;
  bool get hasConsent => dataConsentAt != null;

  factory UserProfile.fromJson(Object? json) {
    if (json is! Map) return empty;
    String? text(String key) {
      final value = json[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    return UserProfile(
      documentType: DocumentType.fromCode(text('documentType')),
      documentNumber: text('documentNumber'),
      phone: text('phone'),
      birthDate: DateTime.tryParse(text('birthDate') ?? ''),
      eps: text('eps'),
      address: text('address'),
      vehicleType: VehicleType.fromCode(text('vehicleType')),
      vehiclePlate: text('vehiclePlate'),
      organization: text('organization'),
      position: text('position'),
      dataConsentAt: DateTime.tryParse(text('dataConsentAt') ?? ''),
    );
  }
}

/// Lo que se envía a `PATCH /auth/profile`. Solo viajan los campos presentes.
class ProfileInput {
  const ProfileInput({
    this.documentType,
    this.documentNumber,
    this.phone,
    this.birthDate,
    this.eps,
    this.address,
    this.vehicleType,
    this.vehiclePlate,
    this.organization,
    this.position,
    this.acceptDataPolicy,
  });

  final DocumentType? documentType;
  final String? documentNumber, phone, eps, address, vehiclePlate, organization, position;
  final DateTime? birthDate;
  final VehicleType? vehicleType;
  final bool? acceptDataPolicy;

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        if (documentType != null) 'documentType': documentType!.code,
        if (documentNumber != null) 'documentNumber': documentNumber,
        if (phone != null) 'phone': phone,
        if (birthDate != null) 'birthDate': _day(birthDate!),
        if (eps != null) 'eps': eps,
        if (address != null) 'address': address,
        if (vehicleType != null) 'vehicleType': vehicleType!.code,
        if (vehiclePlate != null) 'vehiclePlate': vehiclePlate,
        if (organization != null) 'organization': organization,
        if (position != null) 'position': position,
        if (acceptDataPolicy != null) 'acceptDataPolicy': acceptDataPolicy,
      };
}
