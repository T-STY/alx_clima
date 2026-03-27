import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/screens/appointments/appointment_detail_sheet.dart';

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
                            child: Text(e.value, style: const TextStyle(fontSize: 13)),
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
                          Icon(Iconsax.calendar, size: 48, color: theme.textTheme.bodySmall?.color),
                          const SizedBox(height: 12),
                          Text('Sin citas', style: theme.textTheme.bodyMedium),
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

  Widget _buildCard(BuildContext context, Map<String, dynamic> data, DocumentReference ref) {
    final theme = Theme.of(context);
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final allEquipment = parseEquipment(data['equipment']);
    final status = data['status'] ?? 'pending';
    final info = statusInfo(status);

    return GestureDetector(
      onTap: () => showAppointmentDetail(context, data),
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
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: info.$1.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    info.$2,
                    style: TextStyle(color: info.$1, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Iconsax.setting_2, size: 12, color: theme.textTheme.bodySmall?.color),
                const SizedBox(width: 4),
                Text(
                  data['serviceTypeDisplay'] ?? '',
                  style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(width: 12),
                Icon(Iconsax.cpu_setting, size: 12, color: theme.textTheme.bodySmall?.color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    equipmentSummary(allEquipment),
                    style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
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

  Widget _buildActions(BuildContext context, String status, Map<String, dynamic> data, DocumentReference ref) {
    return Row(
      children: [
        if (status == 'pending') ...[
          Expanded(child: _actionBtn('Confirmar', AdminTheme.successColor, Iconsax.tick_circle, () => ref.update({'status': 'confirmed'}))),
          const SizedBox(width: 6),
          Expanded(child: _actionBtn('Reagendar', AdminTheme.primaryColor, Iconsax.calendar_edit, () => rescheduleAppointment(context, _firestore, data, ref))),
          const SizedBox(width: 6),
        ],
        if (status == 'confirmed') ...[
          Expanded(child: _actionBtn('Completar', AdminTheme.primaryColor, Iconsax.tick_square, () => completeAppointment(_firestore, data, ref))),
          const SizedBox(width: 6),
        ],
        if (status != 'cancelled' && status != 'completed')
          Expanded(child: _actionBtn('Cancelar', AdminTheme.errorColor, Iconsax.close_circle, () => cancelAppointment(_firestore, data, ref))),
        if (status == 'cancelled' || status == 'completed')
          Expanded(child: _actionBtn('Eliminar', Colors.grey, Iconsax.trash, () => ref.delete())),
      ],
    );
  }

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback onTap) {
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
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
