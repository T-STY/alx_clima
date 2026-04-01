enum EquipmentType {
  miniSplit,
  centralAC,
  heatPump;

  String get displayName {
    switch (this) {
      case EquipmentType.miniSplit:
        return 'Mini Split';
      case EquipmentType.centralAC:
        return 'Aire Central';
      case EquipmentType.heatPump:
        return 'Bomba de Calor';
    }
  }
}

class Equipment {
  final String id;
  final String name;
  final String brand;
  final EquipmentType type;
  final int btuCapacity;
  final double price;
  final String description;
  final String imageAsset;
  final String imageUrl;
  final double manufacturerWarrantyYears;
  final String manufacturerWarrantyDetails;

  const Equipment({
    required this.id,
    required this.name,
    required this.brand,
    required this.type,
    required this.btuCapacity,
    required this.price,
    required this.description,
    this.imageAsset = '',
    this.imageUrl = '',
    this.manufacturerWarrantyYears = 1.0,
    this.manufacturerWarrantyDetails = 'Garantía estándar del fabricante',
  });

  Equipment copyWith({
    String? id,
    String? name,
    String? brand,
    EquipmentType? type,
    int? btuCapacity,
    double? price,
    String? description,
    String? imageAsset,
    String? imageUrl,
    double? manufacturerWarrantyYears,
    String? manufacturerWarrantyDetails,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      type: type ?? this.type,
      btuCapacity: btuCapacity ?? this.btuCapacity,
      price: price ?? this.price,
      description: description ?? this.description,
      imageAsset: imageAsset ?? this.imageAsset,
      imageUrl: imageUrl ?? this.imageUrl,
      manufacturerWarrantyYears:
          manufacturerWarrantyYears ?? this.manufacturerWarrantyYears,
      manufacturerWarrantyDetails:
          manufacturerWarrantyDetails ?? this.manufacturerWarrantyDetails,
    );
  }

  String get btuFormatted =>
      '${(btuCapacity / 1000).toStringAsFixed(0)}K BTU';

  @override
  String toString() => '$brand $name ($btuFormatted)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Equipment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
