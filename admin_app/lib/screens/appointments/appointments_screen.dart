import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';
import 'appointment_actions.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String _filter = 'all';

  static const _filters = [
    ('all', 'Todas'),
    ('pending', 'Pendientes'),
    ('confirmed', 'Confirmadas'),
    ('completed', 'Completadas'),
    ('cancelled', 'Canceladas'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Citas',
                style: GoogleFonts.exo2(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            _buildFilterRow(),
            const SizedBox(height: 8),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (value, label) = _filters[i];
          final selected = _filter == value;

          return GestureDetector(
            onTap: () => setState(() => _filter = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: selected ? AdminTheme.primaryGradient : null,
                color: selected
                    ? null
                    : Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.7),
                border: selected
                    ? null
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
              ),
              child: Text(
                label,
                style: GoogleFonts.exo2(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    Query query = FirebaseFirestore.instance
        .collection('appointments')
        .orderBy('createdAt', descending: true);

    if (_filter != 'all') {
      query = query.where('status', isEqualTo: _filter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'Sin citas',
              style: GoogleFonts.exo2(fontSize: 14),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            return _AppointmentRow(doc: docs[i])
                .animate()
                .fadeIn(duration: 250.ms, delay: (i * 40).ms)
                .slideX(begin: 0.05, end: 0);
          },
        );
      },
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  const _AppointmentRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final status = data['status'] ?? '';
    final info = statusInfo(status);

    return GestureDetector(
      onTap: () => showAppointmentDetail(context, doc),
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: info.$1,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data['date'] ?? ''} · ${data['timeSlotDisplay'] ?? ''}',
                    style: GoogleFonts.exo2(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${data['serviceTypeDisplay'] ?? data['serviceType'] ?? ''} · ${equipmentSummary(data)}',
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: info.$1.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                info.$2,
                style: GoogleFonts.exo2(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: info.$1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
