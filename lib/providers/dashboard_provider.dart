import 'package:flutter/foundation.dart';
import 'package:alx_clima/models/customer_equipment.dart';
import 'package:alx_clima/models/customer_profile.dart';
import 'package:alx_clima/models/equipment.dart';
import 'package:alx_clima/models/installation.dart';
import 'package:alx_clima/models/service_record.dart';

class DashboardProvider extends ChangeNotifier {
  List<CustomerEquipment> _equipment = [];
  List<ServiceRecord> _serviceHistory = [];
  CustomerProfile? _profile;

  DashboardProvider() {
    _initializeDemoData();
  }

  List<CustomerEquipment> get equipment => List.unmodifiable(_equipment);
  List<ServiceRecord> get serviceHistory => List.unmodifiable(_serviceHistory);
  CustomerProfile? get profile => _profile;

  int get totalEquipment => _equipment.length;

  List<CustomerEquipment> get equipmentNeedingService =>
      _equipment.where((e) => e.needsService).toList();

  DateTime? get nextServiceDate {
    if (_equipment.isEmpty) return null;
    final upcoming = _equipment
        .where((e) => e.nextServiceDate.isAfter(DateTime.now()))
        .toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.nextServiceDate.compareTo(b.nextServiceDate));
    return upcoming.first.nextServiceDate;
  }

  List<ServiceRecord> getServiceHistoryForEquipment(String equipmentId) {
    return _serviceHistory
        .where((s) => s.equipmentId == equipmentId)
        .toList()
      ..sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
  }

  CustomerEquipment? getEquipmentById(String id) {
    try {
      return _equipment.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void addEquipment(CustomerEquipment item) {
    _equipment = [..._equipment, item];
    notifyListeners();
  }

  void removeEquipment(String equipmentId) {
    _equipment = _equipment.where((e) => e.id != equipmentId).toList();
    _serviceHistory =
        _serviceHistory.where((s) => s.equipmentId != equipmentId).toList();
    notifyListeners();
  }

  void addServiceRecord(ServiceRecord record) {
    _serviceHistory = [..._serviceHistory, record];
    notifyListeners();
  }

  void updateProfile(CustomerProfile newProfile) {
    _profile = newProfile;
    notifyListeners();
  }

  void _initializeDemoData() {
    final now = DateTime.now();

    _profile = const CustomerProfile(
      name: 'Carlos Mendoza',
      phone: '+52 614 555 1234',
      email: 'carlos.mendoza@email.com',
      address: 'Av. Tecnol\u00f3gico 1234, Col. Centro, Chihuahua, Chih.',
      notes: 'Cliente desde 2023',
    );

    _equipment = [
      CustomerEquipment(
        id: 'ce-001',
        equipmentName: 'Minisplit Mirage Absolut X 12000 BTU',
        brand: 'Mirage',
        type: EquipmentType.miniSplit,
        btuCapacity: 12000,
        installDate: DateTime(2023, 6, 15),
        lastServiceDate: DateTime(now.year, now.month - 2, 10),
        nextServiceDate: DateTime(now.year, now.month + 4, 10),
        installationType: InstallationType.fullPackage,
        notes: 'Funcionando correctamente',
        location: 'Sala',
      ),
      CustomerEquipment(
        id: 'ce-002',
        equipmentName: 'Minisplit Hisense Inverter 12000 BTU',
        brand: 'Hisense',
        type: EquipmentType.miniSplit,
        btuCapacity: 12000,
        installDate: DateTime(2024, 1, 20),
        lastServiceDate: DateTime(now.year - 1, 11, 5),
        nextServiceDate: DateTime(now.year, now.month - 1, 5),
        installationType: InstallationType.fullPackage,
        notes: 'Requiere limpieza profunda',
        location: 'Rec\u00e1mara Principal',
      ),
      CustomerEquipment(
        id: 'ce-003',
        equipmentName: 'Minisplit Carrier Xpower 18000 BTU',
        brand: 'Carrier',
        type: EquipmentType.miniSplit,
        btuCapacity: 18000,
        installDate: DateTime(2024, 8, 3),
        lastServiceDate: DateTime(now.year, now.month - 1, 15),
        nextServiceDate: DateTime(now.year, now.month + 5, 15),
        installationType: InstallationType.installOnly,
        notes: '',
        location: 'Oficina',
      ),
    ];

    _serviceHistory = [
      ServiceRecord(
        id: 'sr-001',
        equipmentId: 'ce-001',
        serviceDate: DateTime(now.year, now.month - 2, 10),
        serviceType: ServiceType.maintenance,
        description: 'Servicio preventivo completo: limpieza de filtros, '
            'revisi\u00f3n de gas refrigerante y verificaci\u00f3n el\u00e9ctrica.',
        technicianNotes: 'Equipo en buen estado general.',
        cost: 850.0,
      ),
      ServiceRecord(
        id: 'sr-002',
        equipmentId: 'ce-002',
        serviceDate: DateTime(now.year - 1, 11, 5),
        serviceType: ServiceType.inspection,
        description: 'Limpieza general de unidad interior y exterior.',
        technicianNotes:
            'Se recomienda servicio preventivo completo en la pr\u00f3xima visita.',
        cost: 600.0,
      ),
      ServiceRecord(
        id: 'sr-003',
        equipmentId: 'ce-003',
        serviceDate: DateTime(now.year, now.month - 1, 15),
        serviceType: ServiceType.installation,
        description: 'Instalaci\u00f3n de equipo proporcionado por el cliente. '
            'Segundo piso, compresor en mismo nivel.',
        technicianNotes: 'Instalaci\u00f3n exitosa. Pruebas de funcionamiento OK.',
        cost: 3500.0,
      ),
    ];
  }
}
