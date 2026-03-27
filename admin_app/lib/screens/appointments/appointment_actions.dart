import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/screens/appointments/appointment_reschedule.dart';

List<Map<String, dynamic>> parseEquipment(dynamic raw) {
  if (raw is List) {
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
}

String equipmentSummary(List<Map<String, dynamic>> equipment) {
  if (equipment.isEmpty) return 'Sin equipos';
  return equipment.map((e) => '${e['brand'] ?? ''} ${e['name'] ?? ''}'.trim()).join(', ');
}

(Color, String) statusInfo(String status) {
  switch (status) {
    case 'confirmed':
      return (AdminTheme.primaryColor, 'Confirmada');
    case 'completed':
      return (AdminTheme.successColor, 'Completada');
    case 'cancelled':
      return (AdminTheme.errorColor, 'Cancelada');
    default:
      return (AdminTheme.warningColor, 'Pendiente');
  }
}

void showAppointmentDetail(
  BuildContext context,
  FirebaseFirestore firestore,
  DocumentSnapshot doc,
) {
  final data = doc.data() as Map<String, dynamic>;
  final customer = data['customer'] as Map<String, dynamic>? ?? {};
  final status = data['status'] as String? ?? 'pending';
  final equipment = parseEquipment(data['equipment']);
  final info = statusInfo(status);
  final theme = Theme.of(context);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scroll) {
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.all(24),
            children: [
              _statusHeader(info, doc.id, theme),
              const SizedBox(height: 20),
              _sectionLabel('CLIENTE', theme),
              _row('Nombre', customer['name'] ?? '', theme),
              _row('Teléfono', customer['phone'] ?? '', theme),
              _row('Email', customer['email'] ?? '', theme),
              _row('Dirección', customer['address'] ?? '', theme),
              const SizedBox(height: 16),
              _sectionLabel('CITA', theme),
              _row('Fecha', data['date'] ?? '', theme),
              _row('Horario', data['timeSlotDisplay'] ?? (data['timeSlots'] as List?)?.join(', ') ?? '', theme),
              _row('Servicio', data['serviceTypeDisplay'] ?? data['serviceType'] ?? '', theme),
              _row('Equipos', '${data['equipmentCount'] ?? equipment.length}', theme),
              if (data['notes'] != null && (data['notes'] as String).isNotEmpty)
                _row('Notas', data['notes'], theme),
              const SizedBox(height: 16),
              _sectionLabel('EQUIPOS', theme),
              ...equipment.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${e['brand'] ?? ''} ${e['name'] ?? ''} - ${e['btuCapacity'] ?? ''} BTU - ${e['location'] ?? ''}',
                      style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color),
                    ),
                  )),
              const SizedBox(height: 24),
              _buildActions(ctx, context, firestore, doc, status),
            ],
          );
        },
      );
    },
  );
}

Widget _statusHeader((Color, String) info, String docId, ThemeData theme) {
  return Row(
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: info.$1)),
      const SizedBox(width: 8),
      Text(info.$2, style: TextStyle(fontSize: 13, color: info.$1)),
      const Spacer(),
      Text(
        docId.length >= 8 ? docId.substring(0, 8).toUpperCase() : docId.toUpperCase(),
        style: TextStyle(fontSize: 11, letterSpacing: 1, color: theme.textTheme.bodySmall?.color),
      ),
    ],
  );
}

Widget _sectionLabel(String title, ThemeData theme) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: theme.textTheme.bodySmall?.color),
    ),
  );
}

Widget _row(String label, String value, ThemeData theme) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color))),
      ],
    ),
  );
}

Widget _buildActions(BuildContext ctx, BuildContext outerCtx, FirebaseFirestore fs, DocumentSnapshot doc, String status) {
  if (status != 'pending' && status != 'confirmed') return const SizedBox.shrink();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          if (status == 'pending')
            _actionBtn('Confirmar', AdminTheme.primaryColor, () {
              fs.collection('appointments').doc(doc.id).update({'status': 'confirmed'});
              Navigator.pop(ctx);
            }),
          if (status == 'pending') const SizedBox(width: 16),
          _actionBtn('Reagendar', AdminTheme.secondaryColor, () {
            Navigator.pop(ctx);
            rescheduleAppointment(outerCtx, fs, doc);
          }),
          const SizedBox(width: 16),
          _actionBtn('Cancelar', AdminTheme.errorColor, () {
            Navigator.pop(ctx);
            cancelAppointment(outerCtx, fs, doc);
          }),
        ],
      ),
      if (status == 'confirmed')
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _actionBtn('Completar', AdminTheme.successColor, () {
            Navigator.pop(ctx);
            completeAppointment(outerCtx, fs, doc);
          }),
        ),
    ],
  );
}

Widget _actionBtn(String label, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
  );
}

Future<void> cancelAppointment(BuildContext context, FirebaseFirestore firestore, DocumentSnapshot doc) async {
  final data = doc.data() as Map<String, dynamic>;
  final date = data['date'] as String?;
  final timeSlots = List<String>.from(data['timeSlots'] ?? []);
  final userId = data['userId'] as String?;

  await firestore.collection('appointments').doc(doc.id).update({'status': 'cancelled'});

  if (date != null && timeSlots.isNotEmpty) {
    await _restoreSlots(firestore, date, timeSlots);
  }

  if (userId != null) {
    await firestore.collection('users').doc(userId).collection('notifications').add({
      'title': 'Cita cancelada',
      'body': 'Tu cita del $date ha sido cancelada.',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cita cancelada')));
  }
}

Future<void> completeAppointment(BuildContext context, FirebaseFirestore firestore, DocumentSnapshot doc) async {
  final data = doc.data() as Map<String, dynamic>;
  final userId = data['userId'] as String?;
  final equipment = parseEquipment(data['equipment']);

  await firestore.collection('appointments').doc(doc.id).update({'status': 'completed'});

  if (userId != null) {
    for (final eq in equipment) {
      await firestore.collection('users').doc(userId).collection('serviceHistory').add({
        'appointmentId': doc.id,
        'date': data['date'],
        'serviceType': data['serviceType'],
        'serviceTypeDisplay': data['serviceTypeDisplay'],
        'equipmentId': eq['id'],
        'equipmentName': '${eq['brand'] ?? ''} ${eq['name'] ?? ''}'.trim(),
        'btuCapacity': eq['btuCapacity'],
        'location': eq['location'],
        'completedAt': FieldValue.serverTimestamp(),
      });
    }
    await firestore.collection('users').doc(userId).collection('notifications').add({
      'title': 'Servicio completado',
      'body': 'Tu servicio del ${data['date']} ha sido completado.',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cita completada')));
  }
}

Future<void> _restoreSlots(FirebaseFirestore firestore, String date, List<String> slots) async {
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
    final booked = await firestore.collection('bookedSlots').where('date', isEqualTo: date).where('slot', isEqualTo: slot).get();
    for (final d in booked.docs) {
      await d.reference.delete();
    }
  }
}
