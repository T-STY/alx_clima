import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:alx_clima/models/appointment.dart';
import 'package:alx_clima/models/service_record.dart';
import 'package:alx_clima/services/firebase_service.dart';

class AppointmentProvider extends ChangeNotifier {
  List<Appointment> _appointments = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppointmentProvider() {
    _listenToAuth();
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

  void _listenToAuth() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadAppointments(user.uid);
      } else {
        _appointments = [];
        notifyListeners();
      }
    });
  }

  Future<void> _loadAppointments(String uid) async {
    try {
      final snap = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      _appointments = snap.docs.map((doc) {
        final data = doc.data();
        return _appointmentFromMap(data, doc.id);
      }).toList();
      notifyListeners();
    } catch (_) {}
  }

  void scheduleAppointment(Appointment appointment) {
    _appointments = [..._appointments, appointment];
    notifyListeners();
  }

  Future<void> cancelAppointment(String appointmentId) async {
    _appointments = _appointments.map((a) {
      if (a.id == appointmentId) {
        return a.copyWith(status: AppointmentStatus.cancelled);
      }
      return a;
    }).toList();
    notifyListeners();

    try {
      final snap = await _firestore
          .collection('appointments')
          .where('appointmentId', isEqualTo: appointmentId)
          .limit(1)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        await doc.reference.update({'status': 'cancelled'});

        final date = data['date'] as String?;
        final timeSlots = data['timeSlots'] as List?;
        final timeSlot = data['timeSlot'] as String?;

        final slotsToRestore = <String>[];
        if (timeSlots != null) {
          slotsToRestore.addAll(timeSlots.cast<String>());
        } else if (timeSlot != null) {
          slotsToRestore.add(timeSlot);
        }

        if (date != null && slotsToRestore.isNotEmpty) {
          final schedRef = _firestore.collection('schedule').doc(date);
          final schedDoc = await schedRef.get();
          if (schedDoc.exists) {
            await schedRef.update({
              'slots': FieldValue.arrayUnion(slotsToRestore),
            });
          } else {
            await schedRef.set({'slots': slotsToRestore});
          }

          for (final slot in slotsToRestore) {
            final bookedSnap = await _firestore
                .collection('bookedSlots')
                .where('date', isEqualTo: date)
                .where('slot', isEqualTo: slot)
                .limit(1)
                .get();
            for (final d in bookedSnap.docs) {
              await d.reference.delete();
            }
          }
        }
      }
    } catch (_) {}
  }

  List<Appointment> getUpcomingAppointments() => upcomingAppointments;

  Appointment _appointmentFromMap(Map<String, dynamic> data, String docId) {
    final date = data['date'] as String? ?? '';
    final parsed = DateTime.tryParse(date) ?? DateTime.now();

    final serviceTypeStr = data['serviceType'] as String? ?? 'maintenance';
    final serviceType = ServiceType.values.firstWhere(
      (e) => e.name == serviceTypeStr,
      orElse: () => ServiceType.maintenance,
    );

    final statusStr = data['status'] as String? ?? 'pending';
    final status = AppointmentStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => AppointmentStatus.pending,
    );

    String? equipmentId;
    final equipField = data['equipment'];
    if (equipField is List && equipField.isNotEmpty) {
      equipmentId = (equipField.first as Map?)?['id'] as String?;
    } else if (equipField is Map) {
      equipmentId = equipField['id'] as String?;
    }

    final timeSlots = data['timeSlots'] as List?;
    final timeSlot = data['timeSlot'] as String?;
    final timeLabel = data['timeSlotDisplay'] as String? ??
        (timeSlots != null ? timeSlots.cast<String>().join(' + ') : timeSlot);

    return Appointment(
      id: data['appointmentId'] as String? ?? docId,
      equipmentId: equipmentId,
      preferredDate: parsed,
      preferredTimeSlot: TimeSlot.morning,
      preferredTimeLabel: timeLabel,
      serviceType: serviceType,
      notes: data['notes'] as String?,
      status: status,
    );
  }
}
