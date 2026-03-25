import 'package:flutter/foundation.dart';
import 'package:alx_clima/models/equipment.dart';
import 'package:alx_clima/models/installation.dart';
import 'package:alx_clima/models/quote.dart';

class QuoteItem {
  final Equipment equipment;
  final InstallationDetails installationDetails;

  const QuoteItem({
    required this.equipment,
    required this.installationDetails,
  });

  QuoteItem copyWith({
    Equipment? equipment,
    InstallationDetails? installationDetails,
  }) {
    return QuoteItem(
      equipment: equipment ?? this.equipment,
      installationDetails: installationDetails ?? this.installationDetails,
    );
  }
}

class QuoteProvider extends ChangeNotifier {
  InstallationType _installationType = InstallationType.fullPackage;
  List<QuoteItem> _items = [];
  int _activeItemIndex = 0;
  Quote? _currentQuote;

  Map<String, dynamic>? _pricingConfig;

  InstallationType get installationType => _installationType;
  List<QuoteItem> get items => List.unmodifiable(_items);
  int get activeItemIndex => _activeItemIndex;
  Quote? get currentQuote => _currentQuote;

  Equipment? get selectedEquipment =>
      _items.isNotEmpty ? _items[_activeItemIndex].equipment : null;

  InstallationDetails get installationDetails => _items.isNotEmpty
      ? _items[_activeItemIndex].installationDetails
      : const InstallationDetails(
          floorLevel: FloorLevel.first,
          compressorSameFloor: true,
        );

  void setPricingConfig(Map<String, dynamic> config) {
    _pricingConfig = config;
  }

  void setInstallationType(InstallationType type) {
    _installationType = type;
    _items = [];
    _activeItemIndex = 0;
    _currentQuote = null;
    notifyListeners();
  }

  void addEquipmentItem(Equipment equipment) {
    _items = [
      ..._items,
      QuoteItem(
        equipment: equipment,
        installationDetails: const InstallationDetails(
          floorLevel: FloorLevel.first,
          compressorSameFloor: true,
        ),
      ),
    ];
    _activeItemIndex = _items.length - 1;
    _currentQuote = null;
    notifyListeners();
  }

  void selectEquipment(Equipment equipment) {
    addEquipmentItem(equipment);
  }

  void removeItem(int index) {
    if (index < 0 || index >= _items.length) return;
    _items = [..._items]..removeAt(index);
    if (_activeItemIndex >= _items.length) {
      _activeItemIndex = _items.isEmpty ? 0 : _items.length - 1;
    }
    _currentQuote = null;
    notifyListeners();
  }

  void setActiveItem(int index) {
    if (index < 0 || index >= _items.length) return;
    _activeItemIndex = index;
    notifyListeners();
  }

  void setFloorLevel(FloorLevel level) {
    if (_items.isEmpty) return;
    final updated = _items[_activeItemIndex].copyWith(
      installationDetails:
          _items[_activeItemIndex].installationDetails.copyWith(
        floorLevel: level,
      ),
    );
    _items = [..._items]..[_activeItemIndex] = updated;
    _currentQuote = null;
    notifyListeners();
  }

  void setCompressorLocation(bool sameFloor) {
    if (_items.isEmpty) return;
    final updated = _items[_activeItemIndex].copyWith(
      installationDetails:
          _items[_activeItemIndex].installationDetails.copyWith(
        compressorSameFloor: sameFloor,
      ),
    );
    _items = [..._items]..[_activeItemIndex] = updated;
    _currentQuote = null;
    notifyListeners();
  }

  double getInstallCostForItem(QuoteItem item) {
    if (_pricingConfig == null) return 0;

    final btu = item.equipment.btuCapacity;
    final details = item.installationDetails;

    final prices = _pricingConfig!['installOnly'] as Map<String, dynamic>?;
    if (prices == null) return 0;

    double baseCost;
    if (_installationType == InstallationType.fullPackage) {
      final fullPrices =
          _pricingConfig!['fullPackage'] as Map<String, dynamic>?;
      baseCost = (fullPrices?['$btu'] ?? fullPrices?['12000'] ?? 500)
          .toDouble();
    } else {
      baseCost = (prices['$btu'] ?? prices['12000'] ?? 350).toDouble();
    }

    double multiplier = 1.0;
    if (details.floorLevel == FloorLevel.second) {
      multiplier += (_pricingConfig!['secondFloorSurcharge'] ?? 0.3)
          .toDouble();
    }
    if (!details.compressorSameFloor) {
      multiplier += (_pricingConfig!['differentFloorSurcharge'] ?? 0.25)
          .toDouble();
    }

    return baseCost * multiplier;
  }

  double get totalInstallCost {
    double total = 0;
    for (final item in _items) {
      total += getInstallCostForItem(item);
    }

    final discount = _pricingConfig?['multiUnitDiscount'];
    if (_items.length > 1 && discount != null) {
      total *= (1.0 - (discount as num).toDouble());
    }
    return total;
  }

  double get totalEquipmentCost {
    if (_installationType != InstallationType.fullPackage) return 0;
    double total = 0;
    for (final item in _items) {
      total += item.equipment.price;
    }
    return total;
  }

  double get grandTotal => totalEquipmentCost + totalInstallCost;

  bool generateQuote() {
    if (_items.isEmpty) return false;

    final firstItem = _items.first;

    _currentQuote = Quote(
      equipment:
          _installationType == InstallationType.fullPackage
              ? firstItem.equipment
              : null,
      installationType: _installationType,
      installationDetails: firstItem.installationDetails,
      equipmentPrice: totalEquipmentCost,
      installationPrice: totalInstallCost,
      totalPrice: grandTotal,
      includesWarranty:
          _installationType == InstallationType.fullPackage,
      createdAt: DateTime.now(),
    );
    notifyListeners();
    return true;
  }

  void resetQuote() {
    _items = [];
    _activeItemIndex = 0;
    _installationType = InstallationType.fullPackage;
    _currentQuote = null;
    notifyListeners();
  }
}
