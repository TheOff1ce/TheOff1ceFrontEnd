/// Models returned by TheOff1ceOrderDelivery.
library;

enum OrderStatus {
  published('PUBLISHED', 'Publicado'),
  taken('TAKEN', 'Tomado por un repartidor'),
  cancelled('CANCELLED', 'Cancelado'),
  unknown('UNKNOWN', 'Desconocido');

  const OrderStatus(this.code, this.label);

  final String code, label;

  static OrderStatus fromCode(Object? code) =>
      values.firstWhere((s) => s.code == code, orElse: () => OrderStatus.unknown);

  bool get cancellable => this == published || this == taken;
}

class OrderItem {
  const OrderItem({required this.name, required this.quantity});

  final String name;
  final int quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      OrderItem(name: json['name']?.toString() ?? '', quantity: (json['quantity'] as num?)?.toInt() ?? 0);

  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity};
}

class Pharmacy {
  const Pharmacy({required this.name, required this.address});

  final String name, address;

  factory Pharmacy.fromJson(Map<String, dynamic> json) =>
      Pharmacy(name: json['name']?.toString() ?? '', address: json['address']?.toString() ?? '');

  Map<String, dynamic> toJson() => {'name': name, 'address': address};
}

class RouteSummary {
  const RouteSummary({required this.distanceMeters, required this.durationSeconds});

  final int distanceMeters, durationSeconds;

  factory RouteSummary.fromJson(Map<String, dynamic> json) => RouteSummary(
        distanceMeters: (json['distanceMeters'] as num?)?.round() ?? 0,
        durationSeconds: (json['durationSeconds'] as num?)?.round() ?? 0,
      );
}

/// What the patient asks for when requesting a home delivery.
class DeliveryRequest {
  const DeliveryRequest({required this.pharmacy, required this.deliveryAddress, required this.items, this.notes});

  final Pharmacy pharmacy;
  final String deliveryAddress;
  final List<OrderItem> items;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'pharmacy': pharmacy.toJson(),
        'deliveryAddress': deliveryAddress,
        'items': [for (final item in items) item.toJson()],
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };
}

class PatientOrder {
  const PatientOrder({
    required this.id,
    required this.status,
    required this.pharmacy,
    required this.deliveryAddress,
    required this.items,
    required this.notes,
    required this.deliveryId,
    required this.routeSummary,
    required this.driverAssigned,
    required this.createdAt,
  });

  final String id, deliveryAddress, deliveryId;
  final OrderStatus status;
  final Pharmacy pharmacy;
  final List<OrderItem> items;
  final String? notes;
  final RouteSummary routeSummary;
  final bool driverAssigned;
  final DateTime? createdAt;

  factory PatientOrder.fromJson(Map<String, dynamic> json) => PatientOrder(
        id: json['id']?.toString() ?? '',
        status: OrderStatus.fromCode(json['status']),
        pharmacy: Pharmacy.fromJson(_map(json['pharmacy'])),
        deliveryAddress: json['deliveryAddress']?.toString() ?? '',
        items: _items(json['items']),
        notes: json['notes']?.toString(),
        deliveryId: json['deliveryId']?.toString() ?? '',
        routeSummary: RouteSummary.fromJson(_map(json['routeSummary'])),
        driverAssigned: json['driverAssigned'] == true,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

/// Board entry: no patient address or medications until the driver takes it.
class AvailableOrder {
  const AvailableOrder({required this.id, required this.pharmacy, required this.itemCount, required this.routeSummary});

  final String id;
  final Pharmacy pharmacy;
  final int itemCount;
  final RouteSummary routeSummary;

  factory AvailableOrder.fromJson(Map<String, dynamic> json) => AvailableOrder(
        id: json['id']?.toString() ?? '',
        pharmacy: Pharmacy.fromJson(_map(json['pharmacy'])),
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
        routeSummary: RouteSummary.fromJson(_map(json['routeSummary'])),
      );
}

class DriverOrder {
  const DriverOrder({
    required this.id,
    required this.deliveryId,
    required this.pharmacy,
    required this.deliveryAddress,
    required this.items,
    required this.notes,
    required this.status,
  });

  final String id, deliveryId, deliveryAddress;
  final Pharmacy pharmacy;
  final List<OrderItem> items;
  final String? notes;
  final OrderStatus status;

  factory DriverOrder.fromJson(Map<String, dynamic> json) => DriverOrder(
        id: json['id']?.toString() ?? '',
        deliveryId: json['deliveryId']?.toString() ?? '',
        pharmacy: Pharmacy.fromJson(_map(json['pharmacy'])),
        deliveryAddress: json['deliveryAddress']?.toString() ?? '',
        items: _items(json['items']),
        notes: json['notes']?.toString(),
        status: OrderStatus.fromCode(json['status']),
      );
}

List<OrderItem> _items(Object? value) =>
    value is List ? [for (final item in value) if (item is Map) OrderItem.fromJson(_map(item))] : const [];

Map<String, dynamic> _map(Object? value) =>
    value is Map ? value.map((key, v) => MapEntry(key.toString(), v)) : <String, dynamic>{};
