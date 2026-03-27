import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _filter = 'all';

  static const _filterOptions = {
    'all': 'Todas',
    'pending': 'Pendientes',
    'confirmed': 'Confirmadas',
    'completed': 'Completadas',
    'cancelled': 'Canceladas',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Citas', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filter,
                        icon: const Icon(Iconsax.arrow_down_1, size: 16),
                        dropdownColor: Theme.of(context).cardColor,
                        items: _filterOptions.entries.map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, style: TextStyle(fontSize: 13)),
                        )).toList(),
                        onChanged: (v) => setState(() => _filter = v ?? 'all'),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('appointments').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var docs = snapshot.data!.docs;
                  if (_filter != 'all') {
                    docs = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return data['status'] == _filter;
                    }).toList();
                  }
                  if (docs.isEmpty) {
                    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Iconsax.calendar, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(height: 12),
                      Text('Sin citas', style: Theme.of(context).textTheme.bodyMedium),
                    ]));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final ref = docs[index].reference;
                      return _AppointmentCard(data: data, ref: ref, firestore: _firestore)
                          .animate().fadeIn(duration: 300.ms, delay: (index * 30).ms);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final DocumentReference ref;
  final FirebaseFirestore firestore;

  const _AppointmentCard({required this.data, required this.ref, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final equipField = data['equipment'];
    final allEquipment = <Map<String, dynamic>>[];
    if (equipField is List) {
      for (final e in equipField) { if (e is Map<String, dynamic>) allEquipment.add(e); }
    } else if (equipField is Map<String, dynamic>) { allEquipment.add(equipField); }
    final status = data['status'] ?? 'pending';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'confirmed': statusColor = AdminTheme.successColor; statusLabel = 'Confirmada'; break;
      case 'cancelled': statusColor = AdminTheme.errorColor; statusLabel = 'Cancelada'; break;
      case 'completed': statusColor = Colors.grey; statusLabel = 'Completada'; break;
      case 'modified': statusColor = AdminTheme.primaryColor; statusLabel = 'Modificada'; break;
      default: statusColor = AdminTheme.warningColor; statusLabel = 'Pendiente';
    }

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(customer['name'] ?? 'Sin nombre', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${data['date']} \u00b7 ${data['timeSlotDisplay'] ?? ''}', style: Theme.of(context).textTheme.bodySmall),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Iconsax.setting_2, size: 12, color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Text(data['serviceTypeDisplay'] ?? '', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
              const SizedBox(width: 12),
              Icon(Iconsax.cpu_setting, size: 12, color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Expanded(child: Text(
                allEquipment.isNotEmpty ? '${allEquipment.first['brand']} ${allEquipment.first['name']}${allEquipment.length > 1 ? ' +${allEquipment.length - 1}' : ''}' : '',
                style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color), overflow: TextOverflow.ellipsis,
              )),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              if (status == 'pending') ...[
                Expanded(child: _btn(context, 'Confirmar', AdminTheme.successColor, Iconsax.tick_circle, () => ref.update({'status': 'confirmed'}))),
                const SizedBox(width: 6),
                Expanded(child: _btn(context, 'Reagendar', AdminTheme.primaryColor, Iconsax.calendar_edit, () => _reschedule(context))),
                const SizedBox(width: 6),
              ],
              if (status == 'confirmed') ...[
                Expanded(child: _btn(context, 'Completar', AdminTheme.primaryColor, Iconsax.tick_square, () => _complete(context))),
                const SizedBox(width: 6),
              ],
              if (status != 'cancelled' && status != 'completed')
                Expanded(child: _btn(context, 'Cancelar', AdminTheme.errorColor, Iconsax.close_circle, () => _cancel())),
              if (status == 'cancelled' || status == 'completed')
                Expanded(child: _btn(context, 'Eliminar', Colors.grey, Iconsax.trash, () => ref.delete())),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, String label, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final equipField = data['equipment'];
    final allEquipment = <Map<String, dynamic>>[];
    if (equipField is List) {
      for (final e in equipField) { if (e is Map<String, dynamic>) allEquipment.add(e); }
    } else if (equipField is Map<String, dynamic>) { allEquipment.add(equipField); }

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Detalle de Cita', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _row(ctx, Iconsax.user, customer['name'] ?? ''),
          _row(ctx, Iconsax.call, customer['phone'] ?? ''),
          if ((customer['email'] ?? '').isNotEmpty) _row(ctx, Iconsax.sms, customer['email']),
          if ((customer['address'] ?? '').isNotEmpty) _row(ctx, Iconsax.home_2, customer['address']),
          Divider(height: 20, color: Theme.of(ctx).dividerColor),
          _row(ctx, Iconsax.calendar_1, '${data['date']} \u00b7 ${data['timeSlotDisplay'] ?? ''}'),
          _row(ctx, Iconsax.setting_2, data['serviceTypeDisplay'] ?? ''),
          if ((data['notes'] ?? '').isNotEmpty) _row(ctx, Iconsax.note_text, data['notes']),
          Divider(height: 20, color: Theme.of(ctx).dividerColor),
          Text('Equipos (${allEquipment.length})', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          ...allEquipment.map((eq) => Container(
            margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.surface, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Iconsax.cpu_setting, size: 14, color: AdminTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(child: Text('${eq['brand']} ${eq['name']} (${eq['btuCapacity']} BTU)', style: TextStyle(fontSize: 13))),
              if ((eq['location'] ?? '').isNotEmpty)
                Text(eq['location'], style: TextStyle(fontSize: 11, color: Theme.of(ctx).textTheme.bodySmall?.color)),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _row(BuildContext ctx, IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, size: 14, color: Theme.of(ctx).textTheme.bodySmall?.color),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 13))),
    ]),
  );

  Future<void> _cancel() async {
    await ref.update({'status': 'cancelled'});
    final date = data['date'] as String?;
    final slotsField = data['timeSlots'];
    final slotsToRestore = <String>[];
    if (slotsField is List) slotsToRestore.addAll(slotsField.cast<String>());
    if (date != null && slotsToRestore.isNotEmpty) {
      final schedRef = firestore.collection('schedule').doc(date);
      final schedDoc = await schedRef.get();
      if (schedDoc.exists) {
        final existing = (schedDoc.data()?['slots'] as List?)?.cast<String>() ?? [];
        final merged = {...existing, ...slotsToRestore}.toList()..sort();
        await schedRef.update({'slots': merged});
      } else {
        await schedRef.set({'slots': slotsToRestore..sort()});
      }
      for (final slot in slotsToRestore) {
        final snp = await firestore.collection('bookedSlots').where('date', isEqualTo: date).where('slot', isEqualTo: slot).limit(1).get();
        for (final d in snp.docs) { await d.reference.delete(); }
      }
    }
  }

  void _reschedule(BuildContext context) async {
    await ref.update({
      'status': 'modified',
      'adminNote': 'Reagendada por el técnico',
      'modifiedAt': FieldValue.serverTimestamp(),
    });

    final userId = data['userId'] as String?;
    if (userId != null) {
      await firestore.collection('users').doc(userId).collection('notifications').add({
        'type': 'reschedule',
        'title': 'Cita Reagendada',
        'message': 'Tu cita del ${data['date']} ha sido modificada por el técnico. Por favor agenda una nueva fecha.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    await _cancel();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Cita reagendada. Se notificó al cliente.'), backgroundColor: AdminTheme.successColor),
      );
    }
  }

  Future<void> _complete(BuildContext context) async {
    final equipField = data['equipment'];
    final eqItems = <Map<String, dynamic>>[];
    if (equipField is List) {
      for (final e in equipField) { if (e is Map<String, dynamic>) eqItems.add(e); }
    } else if (equipField is Map<String, dynamic>) { eqItems.add(equipField); }

    await ref.update({'status': 'completed'});
    final userId = data['userId'] as String?;
    if (userId == null) return;
    for (final eq in eqItems) {
      await firestore.collection('users').doc(userId).collection('serviceHistory').add({
        'equipmentId': eq['id'] ?? '',
        'serviceDate': FieldValue.serverTimestamp(),
        'serviceType': data['serviceType'] ?? 'maintenance',
        'description': '${data['serviceTypeDisplay'] ?? 'Servicio'} completado',
        'technicianNotes': data['notes'] ?? '',
        'cost': 0,
      });
    }
  }
}
