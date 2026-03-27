import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final todayCount =
                docs.where((d) => d['date'] == today).length;
            final pending =
                docs.where((d) => d['status'] == 'pending').length;
            final confirmed =
                docs.where((d) => d['status'] == 'confirmed').length;
            final completed =
                docs.where((d) => d['status'] == 'completed').length;

            final recent = List<QueryDocumentSnapshot>.from(docs);
            recent.sort((a, b) {
              final aDate = a['createdAt'] as Timestamp?;
              final bDate = b['createdAt'] as Timestamp?;
              if (aDate == null || bDate == null) return 0;
              return bDate.compareTo(aDate);
            });
            final recentList = recent.take(8).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Panel',
                    style: GoogleFonts.exo2(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildStatGrid(
                  todayCount,
                  pending,
                  confirmed,
                  completed,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Citas recientes',
                    style: GoogleFonts.exo2(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _RecentAppointmentsList(appointments: recentList),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatGrid(
    int today,
    int pending,
    int confirmed,
    int completed,
  ) {
    final stats = [
      _StatData('Hoy', '$today', Iconsax.calendar_1, AdminTheme.primaryColor),
      _StatData('Pendientes', '$pending', Iconsax.clock, AdminTheme.warningColor),
      _StatData('Confirmadas', '$confirmed', Iconsax.tick_circle, AdminTheme.secondaryColor),
      _StatData('Completadas', '$completed', Iconsax.verify, AdminTheme.successColor),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.6,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: stats
            .map((s) => _StatCard(data: s))
            .toList()
            .animate(interval: 80.ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.1, end: 0),
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatData(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.all(4),
      tintColor: data.color,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  data.color,
                  data.color.withValues(alpha: 0.4),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  data.color.withValues(alpha: 0.25),
                  data.color.withValues(alpha: 0.08),
                ],
              ),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: GoogleFonts.exo2(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  data.label,
                  style: GoogleFonts.exo2(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.6),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentAppointmentsList extends StatelessWidget {
  final List<QueryDocumentSnapshot> appointments;

  const _RecentAppointmentsList({required this.appointments});

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return GlassCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Sin citas recientes',
              style: GoogleFonts.exo2(fontSize: 14),
            ),
          ),
        ),
      );
    }

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(appointments.length, (i) {
          final data = appointments[i].data() as Map<String, dynamic>;
          final customer = data['customer'] as Map<String, dynamic>? ?? {};
          final status = data['status'] ?? '';
          final color = _statusColor(status);

          return Column(
            children: [
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer['name'] ?? 'Cliente',
                            style: GoogleFonts.exo2(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${data['date'] ?? ''} · ${data['serviceTypeDisplay'] ?? data['serviceType'] ?? ''}',
                            style: GoogleFonts.exo2(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _statusLabel(status),
                      style: GoogleFonts.exo2(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AdminTheme.warningColor;
      case 'confirmed':
        return AdminTheme.secondaryColor;
      case 'completed':
        return AdminTheme.successColor;
      case 'cancelled':
        return AdminTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmada';
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }
}
