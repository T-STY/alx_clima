import 'package:alx_clima/models/equipment.dart';

class EquipmentCatalog {
  EquipmentCatalog._();

  static List<Equipment> get items => const [
        Equipment(
          id: 'ms-carrier-12',
          name: 'Carrier Comfort 12K',
          brand: 'Carrier',
          type: EquipmentType.miniSplit,
          btuCapacity: 12000,
          price: 850.00,
          description:
              'Mini Split inverter de alta eficiencia Carrier. Ideal para '
              'habitaciones de hasta 20m². Operación silenciosa y ahorro '
              'energético garantizado. Clasificación SEER 19.',
          imageAsset: 'assets/images/carrier_12k.png',
          manufacturerWarrantyYears: 5,
          manufacturerWarrantyDetails:
              '5 años en compresor, 1 año en partes y accesorios.',
        ),
        Equipment(
          id: 'ms-lg-12',
          name: 'LG DualCool 12K',
          brand: 'LG',
          type: EquipmentType.miniSplit,
          btuCapacity: 12000,
          price: 920.00,
          description:
              'Mini Split inverter LG con tecnología DualCool. Filtro de '
              'aire avanzado y conectividad Wi-Fi. Perfecto para espacios '
              'de hasta 20m². SEER 20.',
          imageAsset: 'assets/images/lg_12k.png',
          manufacturerWarrantyYears: 10,
          manufacturerWarrantyDetails:
              '10 años en compresor, 2 años en partes generales.',
        ),
        Equipment(
          id: 'ms-daikin-12',
          name: 'Daikin Inverter 12K',
          brand: 'Daikin',
          type: EquipmentType.miniSplit,
          btuCapacity: 12000,
          price: 1050.00,
          description:
              'Mini Split inverter premium Daikin. Tecnología japonesa de '
              'última generación con filtro purificador de aire. Para '
              'habitaciones de hasta 22m². SEER 21.',
          imageAsset: 'assets/images/daikin_12k.png',
          manufacturerWarrantyYears: 7,
          manufacturerWarrantyDetails:
              '7 años en compresor, 2 años en partes y accesorios.',
        ),
        Equipment(
          id: 'ms-samsung-12',
          name: 'Samsung WindFree 12K',
          brand: 'Samsung',
          type: EquipmentType.miniSplit,
          btuCapacity: 12000,
          price: 1180.00,
          description:
              'Mini Split Samsung con tecnología WindFree que distribuye '
              'el aire sin corrientes directas. Silencioso y eficiente. '
              'Ideal para dormitorios de hasta 20m². SEER 21.',
          imageAsset: 'assets/images/samsung_12k.png',
          manufacturerWarrantyYears: 10,
          manufacturerWarrantyDetails:
              '10 años en compresor inverter, 2 años en partes.',
        ),

        Equipment(
          id: 'ms-carrier-18',
          name: 'Carrier XPower 18K',
          brand: 'Carrier',
          type: EquipmentType.miniSplit,
          btuCapacity: 18000,
          price: 1150.00,
          description:
              'Mini Split inverter Carrier XPower de 1.5 toneladas. Alto '
              'rendimiento para salas y espacios de hasta 30m². Función '
              'frío/calor. SEER 19.',
          imageAsset: 'assets/images/carrier_18k.png',
          manufacturerWarrantyYears: 5,
          manufacturerWarrantyDetails:
              '5 años en compresor, 1 año en partes y accesorios.',
        ),
        Equipment(
          id: 'ms-lg-18',
          name: 'LG DualCool 18K',
          brand: 'LG',
          type: EquipmentType.miniSplit,
          btuCapacity: 18000,
          price: 1280.00,
          description:
              'Mini Split inverter LG DualCool de 1.5 toneladas. Wi-Fi '
              'integrado y control por app. Excelente para espacios de '
              'hasta 30m². SEER 20.',
          imageAsset: 'assets/images/lg_18k.png',
          manufacturerWarrantyYears: 10,
          manufacturerWarrantyDetails:
              '10 años en compresor, 2 años en partes generales.',
        ),
        Equipment(
          id: 'ms-daikin-18',
          name: 'Daikin Inverter 18K',
          brand: 'Daikin',
          type: EquipmentType.miniSplit,
          btuCapacity: 18000,
          price: 1450.00,
          description:
              'Mini Split inverter Daikin de 1.5 toneladas. Tecnología '
              'de punta con sensor inteligente de movimiento. Para '
              'espacios de hasta 32m². SEER 22.',
          imageAsset: 'assets/images/daikin_18k.png',
          manufacturerWarrantyYears: 7,
          manufacturerWarrantyDetails:
              '7 años en compresor, 2 años en partes y accesorios.',
        ),
        Equipment(
          id: 'ms-samsung-18',
          name: 'Samsung WindFree 18K',
          brand: 'Samsung',
          type: EquipmentType.miniSplit,
          btuCapacity: 18000,
          price: 1580.00,
          description:
              'Mini Split Samsung WindFree de 1.5 toneladas. Distribución '
              'de aire sin corrientes. Modo nocturno ultra silencioso. '
              'Para espacios de hasta 30m². SEER 21.',
          imageAsset: 'assets/images/samsung_18k.png',
          manufacturerWarrantyYears: 10,
          manufacturerWarrantyDetails:
              '10 años en compresor inverter, 2 años en partes.',
        ),

        Equipment(
          id: 'ms-carrier-24',
          name: 'Carrier XPower 24K',
          brand: 'Carrier',
          type: EquipmentType.miniSplit,
          btuCapacity: 24000,
          price: 1550.00,
          description:
              'Mini Split inverter Carrier XPower de 2 toneladas. Potente '
              'climatización para espacios amplios de hasta 40m². Función '
              'frío/calor y deshumidificación. SEER 19.',
          imageAsset: 'assets/images/carrier_24k.png',
          manufacturerWarrantyYears: 5,
          manufacturerWarrantyDetails:
              '5 años en compresor, 1 año en partes y accesorios.',
        ),
        Equipment(
          id: 'ms-lg-24',
          name: 'LG DualCool 24K',
          brand: 'LG',
          type: EquipmentType.miniSplit,
          btuCapacity: 24000,
          price: 1750.00,
          description:
              'Mini Split inverter LG de 2 toneladas con tecnología '
              'DualCool. Ideal para salas grandes y oficinas de hasta '
              '40m². Control inteligente por Wi-Fi. SEER 20.',
          imageAsset: 'assets/images/lg_24k.png',
          manufacturerWarrantyYears: 10,
          manufacturerWarrantyDetails:
              '10 años en compresor, 2 años en partes generales.',
        ),
        Equipment(
          id: 'ms-daikin-24',
          name: 'Daikin Inverter 24K',
          brand: 'Daikin',
          type: EquipmentType.miniSplit,
          btuCapacity: 24000,
          price: 2050.00,
          description:
              'Mini Split inverter Daikin de 2 toneladas. Máxima '
              'eficiencia energética con compresor swing japonés. Para '
              'espacios grandes de hasta 42m². SEER 22.',
          imageAsset: 'assets/images/daikin_24k.png',
          manufacturerWarrantyYears: 7,
          manufacturerWarrantyDetails:
              '7 años en compresor, 2 años en partes y accesorios.',
        ),

        Equipment(
          id: 'ms-carrier-36',
          name: 'Carrier XPower 36K',
          brand: 'Carrier',
          type: EquipmentType.miniSplit,
          btuCapacity: 36000,
          price: 2100.00,
          description:
              'Mini Split inverter Carrier de 3 toneladas. Potencia '
              'industrial para espacios muy amplios de hasta 55m². '
              'Ideal para comercios y salas grandes. SEER 18.',
          imageAsset: 'assets/images/carrier_36k.png',
          manufacturerWarrantyYears: 5,
          manufacturerWarrantyDetails:
              '5 años en compresor, 1 año en partes y accesorios.',
        ),
        Equipment(
          id: 'ms-lg-36',
          name: 'LG DualCool 36K',
          brand: 'LG',
          type: EquipmentType.miniSplit,
          btuCapacity: 36000,
          price: 2400.00,
          description:
              'Mini Split inverter LG de 3 toneladas. Potente '
              'rendimiento para espacios amplios de hasta 55m². '
              'Compresor Dual Inverter para máximo ahorro. SEER 19.',
          imageAsset: 'assets/images/lg_36k.png',
          manufacturerWarrantyYears: 10,
          manufacturerWarrantyDetails:
              '10 años en compresor, 2 años en partes generales.',
        ),
        Equipment(
          id: 'ms-daikin-36',
          name: 'Daikin Inverter 36K',
          brand: 'Daikin',
          type: EquipmentType.miniSplit,
          btuCapacity: 36000,
          price: 2750.00,
          description:
              'Mini Split inverter Daikin de 3 toneladas. El más alto '
              'rendimiento para grandes espacios de hasta 60m². '
              'Tecnología premium japonesa. SEER 20.',
          imageAsset: 'assets/images/daikin_36k.png',
          manufacturerWarrantyYears: 7,
          manufacturerWarrantyDetails:
              '7 años en compresor, 2 años en partes y accesorios.',
        ),
      ];

  static List<Equipment> byType(EquipmentType type) {
    return items.where((e) => e.type == type).toList();
  }

  static List<Equipment> byCapacity(int btu) {
    return items.where((e) => e.btuCapacity == btu).toList();
  }

  static List<Equipment> byBrand(String brand) {
    return items.where((e) => e.brand == brand).toList();
  }

  static List<String> get availableBrands {
    return items.map((e) => e.brand).toSet().toList()..sort();
  }

  static List<int> get availableCapacities {
    return items.map((e) => e.btuCapacity).toSet().toList()..sort();
  }
}
