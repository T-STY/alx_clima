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

  (Color, String) _statusInfo(String status) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Citas',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filter,
                        icon: const Icon(Iconsax.arrow_down_1, size: 16),
                        dropdownColor: theme.cardColor,
                        items: _filterOptions.entries.map((e) {
                          return DropdownMenuItem(
                            value: e.key,
                            child: Text(
                              e.value,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _filter = v ?? 'all'),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 14),
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
                          Icon(
                            Iconsax.calendar,
                            size: 48,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sin citas',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final ref = docs[index].reference;
                      return _buildCard(context, data, ref)
                          .animate()
                          .fadeIn(duration: 250.ms, delay: (index * 30).ms);
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

  Widget _buildCard(
    BuildContext context,
    Map<String, dynamic> data,
    DocumentReference ref,
  ) {
    final theme = Theme.of(context);
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final equipField = data['equipment'];
    final allEquipment = _parseEquipment(equipField);
    final status = data['status'] ?? 'pending';
    final info = _statusInfo(status);

    return GestureDetector(
      onTap: () => _showDetail(context, data),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 36,
                  decoration: BoxDecoration(
                    color: info.$1,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer['name'] ?? 'Sin nombre',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data['date']} \u00b7 ${data['timeSlotDisplay'] ?? ''}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: info.$1.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    info.$2,
                    style: TextStyle(
                      color: info.$1,
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
                Icon(
                  Iconsax.setting_2,
                  size: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Text(
                  data['serviceTypeDisplay'] ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Iconsax.cpu_setting,
                  size: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _equipmentSummary(allEquipment),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildActions(context, status, data, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    String status,
    Map<String, dynamic> data,
    DocumentReference ref,
  ) {
    return Row(
      children: [
        if (status == 'pending') ...[
          Expanded(
            child: _actionBtn(
              'Confirmar',
              AdminTheme.successColor,
              Iconsax.tick_circle,
              () => ref.update({'status': 'confirmed'}),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _actionBtn(
              'Reagendar',
              AdminTheme.primaryColor,
              Iconsax.calendar_edit,
              () => _reschedule(context, data, ref),
            ),
          ),
          const SizedBox(width: 6),
        ],
        if (status == 'confirmed') ...[
          Expanded(
            child: _actionBtn(
              'Completar',
              AdminTheme.primaryColor,
              Iconsax.tick_square,
              () => _complete(context, data, ref),
            ),
          ),
          const SizedBox(width: 6),
        ],
        if (status != 'cancelled' && status != 'completed')
          Expanded(
            child: _actionBtn(
              'Cancelar',
              AdminTheme.errorColor,
              Iconsax.close_circle,
              () => _cancel(data, ref),
            ),
          ),
        if (status == 'cancelled' || status == 'completed')
          Expanded(
            child: _actionBtn(
              'Eliminar',
              Colors.grey,
              Iconsax.trash,
              () => ref.delete(),
            ),
          ),
      ],
    );
  }

  Widget _actionBtn(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _parseEquipment(dynamic equipField) {
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

  String _equipmentSummary(List<Map<String, dynamic>> eq) {
    if (eq.isEmpty) return '';
    final first = '${eq.first['brand']} ${eq.first['name']}';
    if (eq.length > 1) return '$first +${eq.length - 1}';
    return first;
  }

  void _showDetail(BuildContext context, Map<String, dynamic> data) {
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final allEquipment = _parseEquipment(data['equipment']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
                  color: Theme.of(ctx).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Detalle de Cita',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            _detailRow(ctx, Iconsax.user, customer['name'] ?? ''),
            _detailRow(ctx, Iconsax.call, customer['phone'] ?? ''),
            if ((customer['email'] ?? '').isNotEmpty)
              _detailRow(ctx, Iconsax.sms, customer['email']),
            if ((customer['address'] ?? '').isNotEmpty)
              _detailRow(ctx, Iconsax.home_2, customer['address']),
            Divider(height: 20, color: Theme.of(ctx).dividerColor),
            _detailRow(
              ctx,
              Iconsax.calendar_1,
              '${data['date']} \u00b7 ${data['timeSlotDisplay'] ?? ''}',
            ),
            _detailRow(
              ctx,
              Iconsax.setting_2,
              data['serviceTypeDisplay'] ?? '',
            ),
            if ((data['notes'] ?? '').isNotEmpty)
              _detailRow(ctx, Iconsax.note_text, data['notes']),
            Divider(height: 20, color: Theme.of(ctx).dividerColor),
            Text(
              'Equipos (${allEquipment.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...allEquipment.map((eq) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surface,
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
                            color: Theme.of(ctx).textTheme.bodySmall?.color,
                          ),
                        ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext ctx, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(ctx).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _cancel(
    Map<String, dynamic> data,
    DocumentReference ref,
  ) async {
    await ref.update({'status': 'cancelled'});
    final date = data['date'] as String?;
    final slotsField = data['timeSlots'];
    final slotsToRestore = <String>[];
    if (slotsField is List) slotsToRestore.addAll(slotsField.cast<String>());
    if (date != null && slotsToRestore.isNotEmpty) {
      final schedRef = _firestore.collection('schedule').doc(date);
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
        final snp = await _firestore
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

  Future<void> _reschedule(
    BuildContext context,
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
      await _firestore
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

    await _cancel(data, ref);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cita reagendada. Se notificó al cliente.'),
          backgroundColor: AdminTheme.successColor,
        ),
      );
    }
  }

  Future<void> _complete(
    BuildContext context,
    Map<String, dynamic> data,
    DocumentReference ref,
  ) async {
    final eqItems = _parseEquipment(data['equipment']);
    await ref.update({'status': 'completed'});
    final userId = data['userId'] as String?;
    if (userId == null) return;
    for (final eq in eqItems) {
      await _firestore
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
}
