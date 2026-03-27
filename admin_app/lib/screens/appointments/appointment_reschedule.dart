import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:alx_clima_admin/config/theme.dart';

Future<void> rescheduleAppointment(
  BuildContext context,
  FirebaseFirestore firestore,
  DocumentSnapshot doc,
) async {
  final scheduleSnap = await firestore.collection('schedule').get();
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final availableDates = scheduleSnap.docs
      .where((d) => d.id.compareTo(today) >= 0)
      .map((d) => d.id)
      .toList()
    ..sort();

  if (!context.mounted || availableDates.isEmpty) return;

  String? selectedDate;
  String? selectedSlot;
  List<String> availableSlots = [];

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REAGENDAR CITA',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    letterSpacing: 1.5, color: Theme.of(ctx).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: selectedDate,
                  hint: Text('Seleccionar fecha', style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color)),
                  dropdownColor: Theme.of(ctx).cardColor,
                  isExpanded: true,
                  items: availableDates.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    final dateDoc = await firestore.collection('schedule').doc(v).get();
                    final allSlots = List<String>.from(dateDoc.data()?['slots'] ?? []);
                    final bookedSnap = await firestore
                        .collection('bookedSlots')
                        .where('date', isEqualTo: v)
                        .get();
                    final bookedSet = bookedSnap.docs.map((d) => d['slot'] as String).toSet();
                    setModalState(() {
                      selectedDate = v;
                      selectedSlot = null;
                      availableSlots = allSlots.where((s) => !bookedSet.contains(s)).toList();
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (availableSlots.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableSlots.map((slot) {
                      final picked = slot == selectedSlot;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedSlot = slot),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: picked
                                ? AdminTheme.primaryColor.withValues(alpha: 0.2)
                                : Theme.of(ctx).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            slot,
                            style: TextStyle(
                              fontSize: 13,
                              color: picked ? AdminTheme.primaryColor : Theme.of(ctx).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                if (selectedDate != null && availableSlots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Sin horarios disponibles',
                      style: TextStyle(fontSize: 13, color: Theme.of(ctx).textTheme.bodySmall?.color),
                    ),
                  ),
                const SizedBox(height: 20),
                if (selectedDate != null && selectedSlot != null)
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Text(
                      'Confirmar reagendamiento',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminTheme.primaryColor),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );

  if (selectedDate == null || selectedSlot == null || !context.mounted) return;

  final data = doc.data() as Map<String, dynamic>;
  final oldDate = data['date'] as String?;
  final oldSlots = List<String>.from(data['timeSlots'] ?? []);
  final userId = data['userId'] as String?;

  if (oldDate != null && oldSlots.isNotEmpty) {
    await _restoreOldSlots(firestore, oldDate, oldSlots);
  }

  await firestore.collection('appointments').doc(doc.id).update({
    'date': selectedDate,
    'timeSlots': [selectedSlot],
    'timeSlotDisplay': selectedSlot,
    'status': 'pending',
  });

  await firestore.collection('bookedSlots').add({
    'date': selectedDate,
    'slot': selectedSlot,
    'userId': userId,
  });

  if (userId != null) {
    await firestore.collection('users').doc(userId).collection('notifications').add({
      'title': 'Cita reagendada',
      'body': 'Tu cita ha sido movida al $selectedDate a las $selectedSlot.',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cita reagendada')));
  }
}

Future<void> _restoreOldSlots(FirebaseFirestore firestore, String date, List<String> slots) async {
  final scheduleRef = firestore.collection('schedule').doc(date);
  final snap = await scheduleRef.get();
  if (snap.exists) {
    final existing = List<String>.from(snap.data()?['slots'] ?? []);
    final merged = {...existing, ...slots}.toList();
    merged.sort((a, b) {
      final parse = (String s) {
        final p = s.split(':');
        return int.parse(p[0]) * 60 + int.parse(p[1]);
      };
      return parse(a).compareTo(parse(b));
    });
    await scheduleRef.update({'slots': merged});
  }
  for (final slot in slots) {
    final booked = await firestore
        .collection('bookedSlots')
        .where('date', isEqualTo: date)
        .where('slot', isEqualTo: slot)
        .get();
    for (final d in booked.docs) {
      await d.reference.delete();
    }
  }
}
