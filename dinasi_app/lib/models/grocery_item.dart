import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum Unit { kg, g, L, mL, pcs, dozen, bunch, pack }

extension UnitLabel on Unit {
  String get label {
    switch (this) {
      case Unit.kg:
        return 'kg';
      case Unit.g:
        return 'g';
      case Unit.L:
        return 'L';
      case Unit.mL:
        return 'mL';
      case Unit.pcs:
        return 'pcs';
      case Unit.dozen:
        return 'dozen';
      case Unit.bunch:
        return 'bunch';
      case Unit.pack:
        return 'pack';
    }
  }

  static Unit fromLabel(String label) {
    return Unit.values.firstWhere(
      (u) => u.label.toLowerCase() == label.toLowerCase(),
      orElse: () => Unit.pcs,
    );
  }
}

class GroceryItem {
  final String id;
  String name;
  double quantity;
  Unit unit;

  GroceryItem({
    String? id,
    required this.name,
    required this.quantity,
    required this.unit,
  }) : id = id ?? _uuid.v4();

  GroceryItem copyWith({String? name, double? quantity, Unit? unit}) {
    return GroceryItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'unit': unit.label,
  };

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
    id: json['id'] as String?,
    name: json['name'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    unit: UnitLabel.fromLabel(json['unit'] as String),
  );
}
