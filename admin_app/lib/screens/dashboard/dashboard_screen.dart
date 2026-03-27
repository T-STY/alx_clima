import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'dashboard_widgets.dart';

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
                const SizedBox(height: 12),
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
                RecentAppointmentsList(appointments: recentList),
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
      StatData('Confirmadas', '$confirmed', Iconsax.tick_circle, AdminTheme.secondaryColor),
      StatData('Completadas', '$completed', Iconsax.verify, AdminTheme.successColor),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.8,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: stats
            .map((s) => StatCard(data: s))
            .toList()
            .animate(interval: 80.ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.1, end: 0),
      ),
    );
  }
}
