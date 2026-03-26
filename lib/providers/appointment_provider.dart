import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:alx_clima/models/appointment.dart';
import 'package:alx_clima/models/service_record.dart';

class AppointmentProvider extends ChangeNotifier {
  List<Appointment> _appointments = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _appointmentsSub;
  StreamSubscription? _authSub;

  AppointmentProvider() {
    _listenToAuth();
  }

  @override
  void dispose() {
    _appointmentsSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  List<Appointment> get appointments => List.unmodifiable(_appointments);

  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    return _appointments
        .where((a) =>
            a.preferredDate.isAfter(now) &&
            (a.status == AppointmentStatus.pending ||
                a.status == AppointmentStatus.confirmed ||
                a.status == AppointmentStatus.modified))
        .toList()
      ..sort((a, b) => a.preferredDate.compareTo(b.preferredDate));
  }

  int get pendingAppointmentCount => upcomingAppointments.length;

  void _listenToAuth() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _appointmentsSub?.cancel();
      if (user != null) {
        _listenToAppointments(user.uid);
      } else {
        _appointments = [];
        notifyListeners();
      }
    });
  }

  void _listenToAppointments(String uid) {
    _appointmentsSub = _firestore
        .collection('appointments')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      _appointments = [];
      for (final doc in snap.docs) {
        final data = doc.data();
        _appointments.addAll(_appointmentsFromMap(data, doc.id));
      }
      notifyListeners();
    });
  }

  void scheduleAppointment(Appointment appointment) {
    _appointments = [..._appointments, appointment];
    notifyListeners();
  }

  Future<void> cancelAppointment(String appointmentId) async {
    _appointments = _appointments.map((a) {
      if (a.id == appointmentId || a.id.startsWith('$appointmentId-')) {
        return a.copyWith(status: AppointmentStatus.cancelled);
      }
      return a;
    }).toList();
    notifyListeners();

    await _restoreSlotsForAppointment(appointmentId);
  }

  Future<void> rescheduleAppointment(String oldAppointmentId) async {
    await cancelAppointment(oldAppointmentId);
  }

  Future<void> _restoreSlotsForAppointment(String appointmentId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snap;
      snap = await _firestore
          .collection('appointments')
          .where('appointmentId', isEqualTo: appointmentId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        final parts = appointmentId.split('-');
        if (parts.length > 1) {
          final baseId = parts.sublist(0, parts.length - 1).join('-');
          snap = await _firestore
              .collection('appointments')
              .where('appointmentId', isEqualTo: baseId)
              .limit(1)
              .get();
        }
      }

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

  List<Appointment> _appointmentsFromMap(
      Map<String, dynamic> data, String docId) {
    final date = data['date'] as String? ?? '';
    final parsed = DateTime.tryParse(date) ?? DateTime.now();
    final mainId = data['appointmentId'] as String? ?? docId;

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

    final timeSlots = data['timeSlots'] as List?;
    final timeSlot = data['timeSlot'] as String?;
    final timeLabel = data['timeSlotDisplay'] as String? ??
        (timeSlots != null ? timeSlots.cast<String>().join(' + ') : timeSlot) ??
        '';

    final equipField = data['equipment'];
    final equipmentIds = <String>[];

    if (equipField is List) {
      for (final e in equipField) {
        if (e is Map) {
          final id = e['id'] as String?;
          if (id != null) equipmentIds.add(id);
        }
      }
    } else if (equipField is Map) {
      final id = equipField['id'] as String?;
      if (id != null) equipmentIds.add(id);
    }

    if (equipmentIds.isEmpty) {
      return [
        Appointment(
          id: mainId,
          preferredDate: parsed,
          preferredTimeSlot: TimeSlot.morning,
          preferredTimeLabel: timeLabel,
          serviceType: serviceType,
          notes: data['notes'] as String?,
          status: status,
        ),
      ];
    }

    return equipmentIds.map((eqId) {
      return Appointment(
        id: '$mainId-$eqId',
        equipmentId: eqId,
        preferredDate: parsed,
        preferredTimeSlot: TimeSlot.morning,
        preferredTimeLabel: timeLabel,
        serviceType: serviceType,
        notes: data['notes'] as String?,
        status: status,
      );
    }).toList();
  }
}
