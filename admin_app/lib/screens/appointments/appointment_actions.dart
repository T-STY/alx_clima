import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alx_clima_admin/config/theme.dart';

List<Map<String, dynamic>> parseEquipment(Map<String, dynamic> data) {
  final raw = data['equipment'];
  if (raw is List) {
    return raw.cast<Map<String, dynamic>>();
  }
  return [];
}

String equipmentSummary(Map<String, dynamic> data) {
  final count = data['equipmentCount'] ?? 0;
  if (count == 1) return '1 equipo';
  return '$count equipos';
}

(Color, String) statusInfo(String status) {
  switch (status) {
    case 'pending':
      return (AdminTheme.warningColor, 'Pendiente');
    case 'confirmed':
      return (AdminTheme.secondaryColor, 'Confirmada');
    case 'completed':
      return (AdminTheme.successColor, 'Completada');
    case 'cancelled':
      return (AdminTheme.errorColor, 'Cancelada');
    default:
      return (Colors.grey, status);
  }
}

Future<void> cancelAppointment(QueryDocumentSnapshot doc) async {
  final data = doc.data() as Map<String, dynamic>;
  final date = data['date'] as String?;
  final slots = (data['timeSlots'] as List?)?.cast<String>() ?? [];

  await doc.reference.update({'status': 'cancelled'});

  if (date != null && slots.isNotEmpty) {
    final schedRef =
        FirebaseFirestore.instance.collection('schedule').doc(date);
    final schedDoc = await schedRef.get();

    if (schedDoc.exists) {
      final existing =
          (schedDoc.data()?['slots'] as List?)?.cast<String>() ?? [];
      final merged = {...existing, ...slots}.toList()..sort();
      await schedRef.update({'slots': merged});
    }

    final bookedQuery = FirebaseFirestore.instance
        .collection('bookedSlots')
        .where('date', isEqualTo: date)
        .where('userId', isEqualTo: data['userId']);

    final bookedDocs = await bookedQuery.get();
    for (final bDoc in bookedDocs.docs) {
      final bSlot = bDoc.data()['slot'] as String?;
      if (slots.contains(bSlot)) {
        await bDoc.reference.delete();
      }
    }
  }
}

Future<void> completeAppointment(QueryDocumentSnapshot doc) async {
  final data = doc.data() as Map<String, dynamic>;
  final userId = data['userId'] as String?;
  final equipment = parseEquipment(data);

  await doc.reference.update({'status': 'completed'});

  if (userId != null && equipment.isNotEmpty) {
    final historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('serviceHistory');

    for (final eq in equipment) {
      await historyRef.add({
        'equipmentId': eq['id'] ?? '',
        'equipmentName': '${eq['brand'] ?? ''} ${eq['name'] ?? ''}',
        'btuCapacity': eq['btuCapacity'],
        'serviceType': data['serviceType'],
        'serviceTypeDisplay': data['serviceTypeDisplay'],
        'date': data['date'],
        'completedAt': FieldValue.serverTimestamp(),
        'appointmentId': data['appointmentId'],
      });
    }
  }
}
