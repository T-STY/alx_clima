import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'dashboard_widgets.dart';
import 'metrics_section.dart';

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

            final activeDocs = docs.where((d) {
              final status = d['status'] as String?;
              return status == 'pending' || status == 'confirmed';
            }).toList();
            activeDocs.sort((a, b) {
              final aDate = a['createdAt'] as Timestamp?;
              final bDate = b['createdAt'] as Timestamp?;
              if (aDate == null || bDate == null) return 0;
              return bDate.compareTo(aDate);
            });
            final recentList = activeDocs.take(8).toList();

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
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Citas activas',
                    style: GoogleFonts.exo2(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                RecentAppointmentsList(appointments: recentList),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Métricas',
                    style: GoogleFonts.exo2(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const MetricsSection(),
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
      StatData('Hoy', '$today', Iconsax.calendar_1, AdminTheme.primaryColor),
      StatData('Pendientes', '$pending', Iconsax.clock, AdminTheme.warningColor),
      StatData('Confirm.', '$confirmed', Iconsax.tick_circle, AdminTheme.secondaryColor),
      StatData('Complet.', '$completed', Iconsax.verify, AdminTheme.successColor),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Builder(
        builder: (context) {
          final w = (MediaQuery.of(context).size.width - 28) / 2;
          return Wrap(
            spacing: 4,
            runSpacing: 4,
            children: stats.asMap().entries.map((e) {
              return SizedBox(
                width: w,
                child: StatCard(data: e.value)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (e.key * 80).ms)
                    .slideY(begin: 0.1, end: 0),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
