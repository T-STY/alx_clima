import 'package:flutter/foundation.dart';
import 'package:alx_clima/models/appointment.dart';

class AppointmentProvider extends ChangeNotifier {
  List<Appointment> _appointments = [];

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
}
