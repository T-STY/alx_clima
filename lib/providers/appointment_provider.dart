import 'package:flutter/foundation.dart';
import 'package:alx_clima/models/appointment.dart';
import 'package:alx_clima/models/service_record.dart';

class AppointmentProvider extends ChangeNotifier {
  List<Appointment> _appointments = [];

  AppointmentProvider() {
    _initializeDemoData();
  }

  List<Appointment> get appointments => List.unmodifiable(_appointments);

  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    return _appointments
        .where((a) =>
            a.preferredDate.isAfter(now) &&
            (a.status == AppointmentStatus.pending ||
                a.status == AppointmentStatus.confirmed))
        .toList()
      ..sort((a, b) => a.preferredDate.compareTo(b.preferredDate));
  }

  void scheduleAppointment(Appointment appointment) {
    _appointments = [..._appointments, appointment];
    notifyListeners();
  }

  void cancelAppointment(String appointmentId) {
    _appointments = _appointments.map((a) {
      if (a.id == appointmentId) {
        return a.copyWith(status: AppointmentStatus.cancelled);
      }
      return a;
    }).toList();
    notifyListeners();
  }

  List<Appointment> getUpcomingAppointments() => upcomingAppointments;

  void _initializeDemoData() {
    final now = DateTime.now();

    _appointments = [
      Appointment(
        id: 'apt-001',
        equipmentId: 'ce-002',
        preferredDate: DateTime(now.year, now.month, now.day + 5),
        preferredTimeSlot: TimeSlot.morning,
        serviceType: ServiceType.maintenance,
        notes: 'Limpieza profunda solicitada. Equipo presenta mal olor.',
        status: AppointmentStatus.confirmed,
      ),
      Appointment(
        id: 'apt-002',
        equipmentId: 'ce-001',
        preferredDate: DateTime(now.year, now.month + 1, 12),
        preferredTimeSlot: TimeSlot.afternoon,
        serviceType: ServiceType.maintenance,
        notes: 'Servicio preventivo programado cada 6 meses.',
        status: AppointmentStatus.pending,
      ),
      Appointment(
        id: 'apt-003',
        equipmentId: 'ce-003',
        preferredDate: DateTime(now.year, now.month - 1, 8),
        preferredTimeSlot: TimeSlot.morning,
        serviceType: ServiceType.installation,
        notes: 'Instalaci\u00f3n completada exitosamente.',
        status: AppointmentStatus.completed,
      ),
    ];
  }
}
