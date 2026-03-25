import 'package:alx_clima/models/equipment.dart';
import 'package:alx_clima/models/installation.dart';
import 'package:alx_clima/models/quote.dart';

class PricingRules {
  PricingRules._();

  static const double baseInstallationCost = 350.0;

  static const double fullPackageInstallationCost = 500.0;

  static const double _multiplierFirstSame = 1.0;

  static const double _multiplierSecondSame = 1.3;

  static const double _multiplierFirstDifferent = 1.25;

  static const double _multiplierSecondDifferent = 1.5;

  static double _getLocationMultiplier(InstallationDetails details) {
    if (details.floorLevel == FloorLevel.first) {
      return details.compressorSameFloor
          ? _multiplierFirstSame
          : _multiplierFirstDifferent;
    } else {
      return details.compressorSameFloor
          ? _multiplierSecondSame
          : _multiplierSecondDifferent;
    }
  }

  static double _getBtuAdjustment(int btuCapacity) {
    if (btuCapacity <= 12000) {
      return 0.0;
    } else if (btuCapacity <= 18000) {
      return 75.0;
    } else if (btuCapacity <= 24000) {
      return 150.0;
    } else {
      return 250.0;
    }
  }

  static double calculateInstallationCost(
    InstallationDetails details,
    InstallationType type, {
    int btuCapacity = 12000,
  }) {
    final double baseCost = type == InstallationType.fullPackage
        ? fullPackageInstallationCost
        : baseInstallationCost;

    final double locationMultiplier = _getLocationMultiplier(details);
    final double btuAdjustment = _getBtuAdjustment(btuCapacity);

    return (baseCost * locationMultiplier) + btuAdjustment;
  }

  static Quote generateQuote(
    Equipment? equipment,
    InstallationDetails details,
    InstallationType type,
  ) {
    final double equipmentPrice =
        (type == InstallationType.fullPackage && equipment != null)
            ? equipment.price
            : 0.0;

    final int btu = equipment?.btuCapacity ?? 12000;

    final double installationPrice = calculateInstallationCost(
      details,
      type,
      btuCapacity: btu,
    );

    final double totalPrice = equipmentPrice + installationPrice;
    final bool includesWarranty = type == InstallationType.fullPackage;

    return Quote(
      equipment: equipment,
      installationType: type,
      installationDetails: details,
      equipmentPrice: equipmentPrice,
      installationPrice: installationPrice,
      totalPrice: totalPrice,
      includesWarranty: includesWarranty,
      createdAt: DateTime.now(),
    );
  }
}
