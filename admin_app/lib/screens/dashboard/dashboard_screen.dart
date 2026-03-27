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

  String _cap(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  String _formatToday() {
    final raw = DateFormat('EEEE dd \'de\' MMMM, yyyy', 'es').format(DateTime.now());
    final parts = raw.split(' ');
    if (parts.length >= 4) {
      parts[0] = _cap(parts[0]);
      parts[3] = _cap(parts[3]);
    }
    return parts.join(' ');
  }

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
    final fs = FirebaseFirestore.instance;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panel de Control',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 4),
              Text(
                _formatToday(),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: fs
                    .collection('appointments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? [];
                  int todayCount = 0;
                  int pending = 0;
                  int confirmed = 0;
                  int completed = 0;
                  for (final d in docs) {
                    final m = d.data() as Map<String, dynamic>;
                    final st = m['status'] ?? 'pending';
                    if (m['date'] == today && st != 'cancelled') todayCount++;
                    if (st == 'pending') pending++;
                    if (st == 'confirmed') confirmed++;
                    if (st == 'completed') completed++;
                  }
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Iconsax.calendar_tick,
                              value: '$todayCount',
                              label: 'Hoy',
                              color: AdminTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              icon: Iconsax.clock,
                              value: '$pending',
                              label: 'Pendientes',
                              color: AdminTheme.warningColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Iconsax.tick_circle,
                              value: '$confirmed',
                              label: 'Confirmadas',
                              color: AdminTheme.successColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              icon: Iconsax.tick_square,
                              value: '$completed',
                              label: 'Completadas',
                              color: AdminTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms, delay: 80.ms);
                },
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Citas Recientes',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/appointments'),
                    child: Text(
                      'Ver todas',
                      style: TextStyle(
                        color: AdminTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: fs
                    .collection('appointments')
                    .orderBy('createdAt', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Sin citas registradas',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: docs.asMap().entries.map((entry) {
                      final data = entry.value.data() as Map<String, dynamic>;
                      final customer = data['customer'] as Map<String, dynamic>? ?? {};
                      final status = data['status'] ?? 'pending';
                      final info = _statusInfo(status);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 34,
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${data['date']} \u00b7 ${data['timeSlotDisplay'] ?? ''}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                    ),
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
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                            duration: 250.ms,
                            delay: (120 + entry.key * 40).ms,
                          );
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
