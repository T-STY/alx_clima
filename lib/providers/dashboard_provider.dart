import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DashboardProvider() {
    _listenToAuthChanges();
  }

  List<CustomerEquipment> get equipment => List.unmodifiable(_equipment);
  List<ServiceRecord> get serviceHistory => List.unmodifiable(_serviceHistory);
  CustomerProfile? get profile => _profile;
  bool get isLoading => _isLoading;

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

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        loadUserData();
      } else {
        _equipment = [];
        _serviceHistory = [];
        _profile = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        _profile = CustomerProfile.fromMap(userDoc.data()!);
      }

      final equipSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('equipment')
          .get();
      _equipment = equipSnap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return _equipmentFromMap(data);
      }).toList();

      final servicesSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('serviceHistory')
          .get();
      _serviceHistory = servicesSnap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return _serviceRecordFromMap(data);
      }).toList();
    } catch (_) {
      // Network errors handled silently, data stays empty
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addEquipment(CustomerEquipment item) {
    _equipment = [..._equipment, item];
    notifyListeners();
  }

  void updateEquipment(CustomerEquipment updated) {
    _equipment = _equipment.map((e) {
      if (e.id == updated.id) return updated;
      return e;
    }).toList();
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

  CustomerEquipment _equipmentFromMap(Map<String, dynamic> data) {
    return CustomerEquipment(
      id: data['id'] ?? '',
      equipmentName: data['equipmentName'] ?? '',
      brand: data['brand'] ?? '',
      type: _parseEquipmentType(data['type']),
      btuCapacity: data['btuCapacity'] ?? 12000,
      installDate: _parseDate(data['installDate']),
      lastServiceDate: _parseDate(data['lastServiceDate']),
      nextServiceDate: _parseDate(data['nextServiceDate']),
      installationType: _parseInstallationType(data['installationType']),
      notes: data['notes'] ?? '',
      location: data['location'] ?? '',
      isUserAdded: data['isUserAdded'] ?? false,
    );
  }

  ServiceRecord _serviceRecordFromMap(Map<String, dynamic> data) {
    return ServiceRecord(
      id: data['id'] ?? '',
      equipmentId: data['equipmentId'] ?? '',
      serviceDate: _parseDate(data['serviceDate']),
      serviceType: _parseServiceType(data['serviceType']),
      description: data['description'] ?? '',
      technicianNotes: data['technicianNotes'] ?? '',
      cost: (data['cost'] ?? 0).toDouble(),
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  EquipmentType _parseEquipmentType(dynamic value) {
    if (value is String) {
      return EquipmentType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => EquipmentType.miniSplit,
      );
    }
    return EquipmentType.miniSplit;
  }

  InstallationType _parseInstallationType(dynamic value) {
    if (value is String) {
      return InstallationType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => InstallationType.fullPackage,
      );
    }
    return InstallationType.fullPackage;
  }

  ServiceType _parseServiceType(dynamic value) {
    if (value is String) {
      return ServiceType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ServiceType.maintenance,
      );
    }
    return ServiceType.maintenance;
  }
}
