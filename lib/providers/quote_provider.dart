import 'package:flutter/foundation.dart';
import 'package:alx_clima/models/equipment.dart';
import 'package:alx_clima/models/installation.dart';
import 'package:alx_clima/models/quote.dart';
import 'package:alx_clima/data/pricing_rules.dart';

class QuoteProvider extends ChangeNotifier {
  Equipment? _selectedEquipment;
  InstallationType _installationType = InstallationType.fullPackage;
  InstallationDetails _installationDetails = const InstallationDetails(
    floorLevel: FloorLevel.first,
    compressorSameFloor: true,
  );
  Quote? _currentQuote;

  Equipment? get selectedEquipment => _selectedEquipment;
  InstallationType get installationType => _installationType;
  InstallationDetails get installationDetails => _installationDetails;
  Quote? get currentQuote => _currentQuote;

  void selectEquipment(Equipment equipment) {
    _selectedEquipment = equipment;
    _currentQuote = null;
    notifyListeners();
  }

  void setInstallationType(InstallationType type) {
    _installationType = type;
    _currentQuote = null;
    notifyListeners();
  }

  void setFloorLevel(FloorLevel level) {
    _installationDetails = _installationDetails.copyWith(floorLevel: level);
    _currentQuote = null;
    notifyListeners();
  }

  void setCompressorLocation(bool sameFloor) {
    _installationDetails =
        _installationDetails.copyWith(compressorSameFloor: sameFloor);
    _currentQuote = null;
    notifyListeners();
  }

  bool generateQuote() {
    if (_selectedEquipment == null &&
        _installationType == InstallationType.fullPackage) {
      return false;
    }

    final equipment = _selectedEquipment ??
        const Equipment(
          id: 'generic',
          name: 'Equipo del cliente',
          brand: 'N/A',
          type: EquipmentType.miniSplit,
          btuCapacity: 12000,
          price: 0,
          description: 'Equipo proporcionado por el cliente',
        );

    _currentQuote = PricingRules.generateQuote(
      equipment,
      _installationDetails,
      _installationType,
    );
    notifyListeners();
    return true;
  }

  void resetQuote() {
    _selectedEquipment = null;
    _installationType = InstallationType.fullPackage;
    _installationDetails = const InstallationDetails(
      floorLevel: FloorLevel.first,
      compressorSameFloor: true,
    );
    _currentQuote = null;
    notifyListeners();
  }
}
