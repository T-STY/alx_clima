import 'package:alx_clima/models/equipment.dart';
import 'package:alx_clima/models/installation.dart';

class Quote {
  final Equipment? equipment;
  final InstallationType installationType;
  final InstallationDetails installationDetails;
  final double equipmentPrice;
  final double installationPrice;
  final double totalPrice;
  final bool includesWarranty;
  final DateTime createdAt;

  const Quote({
    this.equipment,
    required this.installationType,
    required this.installationDetails,
    required this.equipmentPrice,
    required this.installationPrice,
    required this.totalPrice,
    required this.includesWarranty,
    required this.createdAt,
  });

  String get summary {
    final tipo = installationType.displayName;
    final piso = installationDetails.floorLevel.displayName;
    return '$tipo - $piso - Total: \$${totalPrice.toStringAsFixed(2)}';
  }

  bool get hasEquipment => equipment != null;
}
