enum ServiceType {
  maintenance,
  repair,
  installation,
  inspection,
  removal,
  relocation;

  String get displayName {
    switch (this) {
      case ServiceType.maintenance:
        return 'Mantenimiento';
      case ServiceType.repair:
        return 'Reparación';
      case ServiceType.installation:
        return 'Instalación';
      case ServiceType.inspection:
        return 'Inspección';
      case ServiceType.removal:
        return 'Retiro';
      case ServiceType.relocation:
        return 'Reubicación';
    }
  }
}

class ServiceRecord {
  final String id;
  final String equipmentId;
  final DateTime serviceDate;
  final ServiceType serviceType;
  final String description;
  final String? technicianNotes;
  final double? cost;

  const ServiceRecord({
    required this.id,
    required this.equipmentId,
    required this.serviceDate,
    required this.serviceType,
    required this.description,
    this.technicianNotes,
    this.cost,
  });
}
