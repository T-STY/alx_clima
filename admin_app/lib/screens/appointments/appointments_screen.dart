import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                'Citas',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 16),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _filterChip('Todas', 'all'),
                  const SizedBox(width: 8),
                  _filterChip('Pendientes', 'pending'),
                  const SizedBox(width: 8),
                  _filterChip('Confirmadas', 'confirmed'),
                  const SizedBox(width: 8),
                  _filterChip('Completadas', 'completed'),
                  const SizedBox(width: 8),
                  _filterChip('Canceladas', 'cancelled'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('appointments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var docs = snapshot.data!.docs;
                  if (_filter != 'all') {
                    docs = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return data['status'] == _filter;
                    }).toList();
                  }
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.calendar,
                              size: 48,
                              color: AdminTheme.textSecondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('Sin citas',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final ref = docs[index].reference;
                      return _AppointmentCard(
                        data: data,
                        ref: ref,
                        firestore: _firestore,
                      ).animate().fadeIn(
                          duration: 300.ms, delay: (index * 40).ms);
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

  Widget _filterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AdminTheme.primaryColor.withValues(alpha: 0.2)
              : AdminTheme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AdminTheme.primaryColor : AdminTheme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AdminTheme.primaryColor : AdminTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final DocumentReference ref;
  final FirebaseFirestore firestore;

  const _AppointmentCard({
    required this.data,
    required this.ref,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final equipField = data['equipment'];
    final allEquipment = <Map<String, dynamic>>[];
    if (equipField is List) {
      for (final e in equipField) {
        if (e is Map<String, dynamic>) allEquipment.add(e);
      }
    } else if (equipField is Map<String, dynamic>) {
      allEquipment.add(equipField);
    }
    final status = data['status'] ?? 'pending';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'confirmed':
        statusColor = AdminTheme.successColor;
        statusLabel = 'Confirmada';
        break;
      case 'cancelled':
        statusColor = AdminTheme.errorColor;
        statusLabel = 'Cancelada';
        break;
      case 'completed':
        statusColor = AdminTheme.textSecondary;
        statusLabel = 'Completada';
        break;
      case 'modified':
        statusColor = AdminTheme.primaryColor;
        statusLabel = 'Modificada';
        break;
      default:
        statusColor = AdminTheme.warningColor;
        statusLabel = 'Pendiente';
    }

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdminTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTheme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer['name'] ?? 'Sin nombre',
                        style: TextStyle(
                          color: AdminTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data['date']} \u00b7 ${data['timeSlotDisplay'] ?? ''}',
                        style: TextStyle(
                          color: AdminTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Iconsax.setting_2, size: 14, color: AdminTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  data['serviceTypeDisplay'] ?? '',
                  style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Iconsax.cpu_setting, size: 14, color: AdminTheme.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    allEquipment.isNotEmpty
                        ? '${allEquipment.first['brand']} ${allEquipment.first['name']}${allEquipment.length > 1 ? ' +${allEquipment.length - 1}' : ''}'
                        : '',
                    style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (status == 'pending') ...[
                  Expanded(child: _actionBtn('Confirmar', AdminTheme.successColor, Iconsax.tick_circle,
                      () => ref.update({'status': 'confirmed'}))),
                  const SizedBox(width: 8),
                ],
                if (status == 'confirmed') ...[
                  Expanded(child: _actionBtn('Completar', AdminTheme.primaryColor, Iconsax.tick_square,
                      () => _completeAppointment(context))),
                  const SizedBox(width: 8),
                ],
                if (status != 'cancelled' && status != 'completed')
                  Expanded(child: _actionBtn('Cancelar', AdminTheme.errorColor, Iconsax.close_circle,
                      () => _cancelAppointment())),
                if (status == 'cancelled' || status == 'completed')
                  Expanded(child: _actionBtn('Eliminar', AdminTheme.textSecondary, Iconsax.trash,
                      () => ref.delete())),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final equipField = data['equipment'];
    final allEquipment = <Map<String, dynamic>>[];
    if (equipField is List) {
      for (final e in equipField) {
        if (e is Map<String, dynamic>) allEquipment.add(e);
      }
    } else if (equipField is Map<String, dynamic>) {
      allEquipment.add(equipField);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AdminTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Detalle de Cita',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
              const SizedBox(height: 16),
              _row(Iconsax.user, customer['name'] ?? ''),
              _row(Iconsax.call, customer['phone'] ?? ''),
              if ((customer['email'] ?? '').isNotEmpty)
                _row(Iconsax.sms, customer['email']),
              if ((customer['address'] ?? '').isNotEmpty)
                _row(Iconsax.home_2, customer['address']),
              const Divider(height: 20, color: AdminTheme.dividerColor),
              _row(Iconsax.calendar_1, '${data['date']} \u00b7 ${data['timeSlotDisplay'] ?? ''}'),
              _row(Iconsax.setting_2, data['serviceTypeDisplay'] ?? ''),
              if ((data['notes'] ?? '').isNotEmpty)
                _row(Iconsax.note_text, data['notes']),
              const Divider(height: 20, color: AdminTheme.dividerColor),
              Text('Equipos (${allEquipment.length})',
                  style: TextStyle(
                    color: AdminTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  )),
              const SizedBox(height: 8),
              ...allEquipment.map((eq) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AdminTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.cpu_setting, size: 14, color: AdminTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${eq['brand']} ${eq['name']} (${eq['btuCapacity']} BTU)',
                            style: TextStyle(color: AdminTheme.textPrimary, fontSize: 13),
                          ),
                        ),
                        if ((eq['location'] ?? '').isNotEmpty)
                          Text(eq['location'],
                              style: TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AdminTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: AdminTheme.textPrimary, fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment() async {
    await ref.update({'status': 'cancelled'});
    final date = data['date'] as String?;
    final slotsField = data['timeSlots'];
    final slotsToRestore = <String>[];
    if (slotsField is List) {
      slotsToRestore.addAll(slotsField.cast<String>());
    }
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
        final snp = await firestore.collection('bookedSlots')
            .where('date', isEqualTo: date)
            .where('slot', isEqualTo: slot)
            .limit(1).get();
        for (final d in snp.docs) {
          await d.reference.delete();
        }
      }
    }
  }

  Future<void> _completeAppointment(BuildContext context) async {
    final equipField = data['equipment'];
    final eqItems = <Map<String, dynamic>>[];
    if (equipField is List) {
      for (final e in equipField) {
        if (e is Map<String, dynamic>) eqItems.add(e);
      }
    } else if (equipField is Map<String, dynamic>) {
      eqItems.add(equipField);
    }

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
