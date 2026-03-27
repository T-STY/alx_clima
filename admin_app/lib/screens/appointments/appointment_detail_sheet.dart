import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';

List<Map<String, dynamic>> parseEquipment(dynamic equipField) {
  final result = <Map<String, dynamic>>[];
  if (equipField is List) {
    for (final e in equipField) {
      if (e is Map<String, dynamic>) result.add(e);
    }
  } else if (equipField is Map<String, dynamic>) {
    result.add(equipField);
  }
  return result;
}

String equipmentSummary(List<Map<String, dynamic>> eq) {
  if (eq.isEmpty) return '';
  final first = '${eq.first['brand']} ${eq.first['name']}';
  if (eq.length > 1) return '$first +${eq.length - 1}';
  return first;
}

(Color, String) statusInfo(String status) {
  switch (status) {
    case 'confirmed':
      return (AdminTheme.successColor, 'Confirmada');
    case 'cancelled':
      return (AdminTheme.errorColor, 'Cancelada');
    case 'completed':
      return (AdminTheme.accentColor, 'Completada');
    case 'modified':
      return (AdminTheme.primaryColor, 'Modificada');
    default:
      return (AdminTheme.warningColor, 'Pendiente');
  }
}

void showAppointmentDetail(BuildContext context, Map<String, dynamic> data) {
  final customer = data['customer'] as Map<String, dynamic>? ?? {};
  final allEquipment = parseEquipment(data['equipment']);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Detalle de Cita',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _row(ctx, Iconsax.user, customer['name'] ?? ''),
            _row(ctx, Iconsax.call, customer['phone'] ?? ''),
            if ((customer['email'] ?? '').isNotEmpty)
              _row(ctx, Iconsax.sms, customer['email']),
            if ((customer['address'] ?? '').isNotEmpty)
              _row(ctx, Iconsax.home_2, customer['address']),
            Divider(height: 20, color: theme.dividerColor),
            _row(
              ctx,
              Iconsax.calendar_1,
              '${data['date']} \u00b7 ${data['timeSlotDisplay'] ?? ''}',
            ),
            _row(ctx, Iconsax.setting_2, data['serviceTypeDisplay'] ?? ''),
            if ((data['notes'] ?? '').isNotEmpty)
              _row(ctx, Iconsax.note_text, data['notes']),
            Divider(height: 20, color: theme.dividerColor),
            Text(
              'Equipos (${allEquipment.length})',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...allEquipment.map((eq) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.cpu_setting,
                        size: 14,
                        color: AdminTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${eq['brand']} ${eq['name']} (${eq['btuCapacity']} BTU)',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if ((eq['location'] ?? '').isNotEmpty)
                        Text(
                          eq['location'],
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                    ],
                  ),
                )),
          ],
        ),
      );
    },
  );
}

Widget _row(BuildContext ctx, IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(ctx).textTheme.bodySmall?.color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );
}

Future<void> cancelAppointment(
  FirebaseFirestore firestore,
  Map<String, dynamic> data,
  DocumentReference ref,
) async {
  await ref.update({'status': 'cancelled'});
  final date = data['date'] as String?;
  final slotsField = data['timeSlots'];
  final slotsToRestore = <String>[];
  if (slotsField is List) slotsToRestore.addAll(slotsField.cast<String>());
  if (date != null && slotsToRestore.isNotEmpty) {
    final schedRef = firestore.collection('schedule').doc(date);
    final schedDoc = await schedRef.get();
    if (schedDoc.exists) {
      final existing =
          (schedDoc.data()?['slots'] as List?)?.cast<String>() ?? [];
      final merged = {...existing, ...slotsToRestore}.toList()..sort();
      await schedRef.update({'slots': merged});
    } else {
      await schedRef.set({'slots': slotsToRestore..sort()});
    }
    for (final slot in slotsToRestore) {
      final snp = await firestore
          .collection('bookedSlots')
          .where('date', isEqualTo: date)
          .where('slot', isEqualTo: slot)
          .limit(1)
          .get();
      for (final d in snp.docs) {
        await d.reference.delete();
      }
    }
  }
}

Future<void> rescheduleAppointment(
  BuildContext context,
  FirebaseFirestore firestore,
  Map<String, dynamic> data,
  DocumentReference ref,
) async {
  await ref.update({
    'status': 'modified',
    'adminNote': 'Reagendada por el técnico',
    'modifiedAt': FieldValue.serverTimestamp(),
  });
  final userId = data['userId'] as String?;
  if (userId != null) {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'type': 'reschedule',
      'title': 'Cita Reagendada',
      'message':
          'Tu cita del ${data['date']} ha sido modificada por el técnico. Por favor agenda una nueva fecha.',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
  await cancelAppointment(firestore, data, ref);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cita reagendada. Se notificó al cliente.'),
        backgroundColor: AdminTheme.successColor,
      ),
    );
  }
}

Future<void> completeAppointment(
  FirebaseFirestore firestore,
  Map<String, dynamic> data,
  DocumentReference ref,
) async {
  final eqItems = parseEquipment(data['equipment']);
  await ref.update({'status': 'completed'});
  final userId = data['userId'] as String?;
  if (userId == null) return;
  for (final eq in eqItems) {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('serviceHistory')
        .add({
      'equipmentId': eq['id'] ?? '',
      'serviceDate': FieldValue.serverTimestamp(),
      'serviceType': data['serviceType'] ?? 'maintenance',
      'description': '${data['serviceTypeDisplay'] ?? 'Servicio'} completado',
      'technicianNotes': data['notes'] ?? '',
      'cost': 0,
    });
  }
}
