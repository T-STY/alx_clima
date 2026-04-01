import 'package:alx_clima/models/service_record.dart';

enum TimeSlot {
  morning,
  afternoon;

  String get displayName {
    switch (this) {
      case TimeSlot.morning:
        return 'Mañana (9:00 - 13:00)';
      case TimeSlot.afternoon:
        return 'Tarde (14:00 - 18:00)';
    }
  }
}

enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  modified;

  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pendiente';
      case AppointmentStatus.confirmed:
        return 'Confirmada';
      case AppointmentStatus.completed:
        return 'Completada';
      case AppointmentStatus.cancelled:
        return 'Cancelada';
      case AppointmentStatus.modified:
        return 'Cita Modificada';
    }
  }
}

class Appointment {
  final String id;
  final String? equipmentId;
  final DateTime preferredDate;
  final TimeSlot preferredTimeSlot;
  final String? preferredTimeLabel;
  final ServiceType serviceType;
  final String? notes;
  final AppointmentStatus status;

  const Appointment({
    required this.id,
    this.equipmentId,
    required this.preferredDate,
    required this.preferredTimeSlot,
    this.preferredTimeLabel,
    required this.serviceType,
    this.notes,
    this.status = AppointmentStatus.pending,
  });

  Appointment copyWith({
    String? id,
    String? equipmentId,
    DateTime? preferredDate,
    TimeSlot? preferredTimeSlot,
    String? preferredTimeLabel,
    ServiceType? serviceType,
    String? notes,
    AppointmentStatus? status,
  }) {
    return Appointment(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTimeSlot: preferredTimeSlot ?? this.preferredTimeSlot,
      preferredTimeLabel: preferredTimeLabel ?? this.preferredTimeLabel,
      serviceType: serviceType ?? this.serviceType,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}
