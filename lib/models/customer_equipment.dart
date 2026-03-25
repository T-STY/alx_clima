import 'package:alx_clima/models/equipment.dart';
import 'package:alx_clima/models/installation.dart';

class CustomerEquipment {
  final String id;
  final String equipmentName;
  final String brand;
  final EquipmentType type;
  final int btuCapacity;
  final DateTime installDate;
  final DateTime? lastServiceDate;
  final DateTime nextServiceDate;
  final InstallationType installationType;
  final String? notes;
  final String? location;

  const CustomerEquipment({
    required this.id,
    required this.equipmentName,
    required this.brand,
    required this.type,
    required this.btuCapacity,
    required this.installDate,
    this.lastServiceDate,
    required this.nextServiceDate,
    required this.installationType,
    this.notes,
    this.location,
  });

  bool get needsService => DateTime.now().isAfter(nextServiceDate);

  CustomerEquipment copyWith({
    String? id,
    String? equipmentName,
    String? brand,
    EquipmentType? type,
    int? btuCapacity,
    DateTime? installDate,
    DateTime? lastServiceDate,
    DateTime? nextServiceDate,
    InstallationType? installationType,
    String? notes,
    String? location,
  }) {
    return CustomerEquipment(
      id: id ?? this.id,
      equipmentName: equipmentName ?? this.equipmentName,
      brand: brand ?? this.brand,
      type: type ?? this.type,
      btuCapacity: btuCapacity ?? this.btuCapacity,
      installDate: installDate ?? this.installDate,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      installationType: installationType ?? this.installationType,
      notes: notes ?? this.notes,
      location: location ?? this.location,
    );
  }
}
