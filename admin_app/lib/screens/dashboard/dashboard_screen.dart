import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panel de Control',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 2),
              Text(
                _capitalize(DateFormat('EEEE dd MMMM yyyy', 'es').format(DateTime.now())),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('appointments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  final todayAppts = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return data['date'] == today && data['status'] != 'cancelled';
                  }).length;
                  final pendingAppts = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return data['status'] == 'pending';
                  }).length;
                  final confirmedAppts = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return data['status'] == 'confirmed';
                  }).length;
                  final completedAppts = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return data['status'] == 'completed';
                  }).length;

                  return Column(
                    children: [
                      Row(children: [
                        Expanded(child: StatCard(icon: Iconsax.calendar_tick, value: '$todayAppts', label: 'Hoy', color: AdminTheme.primaryColor)),
                        const SizedBox(width: 10),
                        Expanded(child: StatCard(icon: Iconsax.clock, value: '$pendingAppts', label: 'Pendientes', color: AdminTheme.warningColor)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: StatCard(icon: Iconsax.tick_circle, value: '$confirmedAppts', label: 'Confirmadas', color: AdminTheme.successColor)),
                        const SizedBox(width: 10),
                        Expanded(child: StatCard(icon: Iconsax.tick_square, value: '$completedAppts', label: 'Completadas', color: AdminTheme.accentColor)),
                      ]),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
                },
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Citas Recientes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  TextButton(onPressed: () => context.go('/appointments'), child: const Text('Ver todas')),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

              const SizedBox(height: 8),

              StreamBuilder<QuerySnapshot>(
                stream: firestore.collection('appointments').orderBy('createdAt', descending: true).limit(5).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text('Sin citas registradas', style: Theme.of(context).textTheme.bodyMedium)),
                    );
                  }

                  return Column(
                    children: docs.asMap().entries.map((entry) {
                      final data = entry.value.data() as Map<String, dynamic>;
                      final customer = data['customer'] as Map<String, dynamic>? ?? {};
                      final status = data['status'] ?? 'pending';

                      Color statusColor;
                      String statusLabel;
                      switch (status) {
                        case 'confirmed': statusColor = AdminTheme.successColor; statusLabel = 'Confirmada'; break;
                        case 'cancelled': statusColor = AdminTheme.errorColor; statusLabel = 'Cancelada'; break;
                        case 'completed': statusColor = Colors.grey; statusLabel = 'Completada'; break;
                        default: statusColor = AdminTheme.warningColor; statusLabel = 'Pendiente';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(width: 4, height: 36, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(customer['name'] ?? 'Sin nombre', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('${data['date']} \u00b7 ${data['timeSlotDisplay'] ?? ''}', style: Theme.of(context).textTheme.bodySmall),
                            ])),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                              child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: (200 + entry.key * 50).ms);
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
