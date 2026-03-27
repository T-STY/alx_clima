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

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                          'Panel de Control',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE dd MMMM yyyy', 'es').format(DateTime.now()),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

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

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        icon: Iconsax.calendar_tick,
                        value: '$todayAppts',
                        label: 'Citas Hoy',
                        color: AdminTheme.primaryColor,
                      ),
                      StatCard(
                        icon: Iconsax.clock,
                        value: '$pendingAppts',
                        label: 'Pendientes',
                        color: AdminTheme.warningColor,
                      ),
                      StatCard(
                        icon: Iconsax.tick_circle,
                        value: '$confirmedAppts',
                        label: 'Confirmadas',
                        color: AdminTheme.successColor,
                      ),
                      StatCard(
                        icon: Iconsax.tick_square,
                        value: '$completedAppts',
                        label: 'Completadas',
                        color: AdminTheme.accentColor,
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
                },
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Citas Recientes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/appointments'),
                    icon: const Text('Ver todas'),
                    label: const Icon(Iconsax.arrow_right_3, size: 16),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('appointments')
                    .orderBy('createdAt', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AdminTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'Sin citas registradas',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
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
                        default:
                          statusColor = AdminTheme.warningColor;
                          statusLabel = 'Pendiente';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AdminTheme.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AdminTheme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 40,
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer['name'] ?? 'Sin nombre',
                                    style: TextStyle(
                                      color: AdminTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
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
                      ).animate().fadeIn(
                          duration: 300.ms, delay: (250 + entry.key * 60).ms);
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
