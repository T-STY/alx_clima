import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';
import 'appointment_actions.dart';
import 'appointment_detail.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String _view = 'agenda';
  String _filter = 'active';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Citas',
                      style: GoogleFonts.exo2(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  _viewToggle(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _filterRow(),
            const SizedBox(height: 8),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _viewToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn('agenda', Iconsax.calendar, 'Agenda'),
          _toggleBtn('list', Iconsax.row_vertical, 'Lista'),
        ],
      ),
    );
  }

  Widget _toggleBtn(String value, IconData icon, String label) {
    final sel = _view == value;
    return GestureDetector(
      onTap: () => setState(() => _view = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: sel ? AdminTheme.primaryGradient : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: sel ? Colors.white : Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.exo2(fontSize: 11, fontWeight: FontWeight.w500, color: sel ? Colors.white : Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ),
    );
  }

  Widget _filterRow() {
    const filters = [
      ('active', 'Activas'),
      ('all', 'Todas'),
      ('pending', 'Pendientes'),
      ('confirmed', 'Confirmadas'),
      ('completed', 'Completadas'),
      ('cancelled', 'Canceladas'),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final (value, label) = filters[i];
          final selected = _filter == value;
          return GestureDetector(
            onTap: () => setState(() => _filter = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                gradient: selected ? AdminTheme.primaryGradient : null,
                color: selected ? null : Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.7),
              ),
              child: Text(label, style: GoogleFonts.exo2(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    Query query = FirebaseFirestore.instance.collection('appointments').orderBy('date', descending: false);

    if (_filter == 'active') {
      query = query.where('status', whereIn: ['pending', 'confirmed']);
    } else if (_filter != 'all') {
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
          return Center(child: Text('Sin citas', style: GoogleFonts.exo2(fontSize: 14)));
        }

        if (_view == 'agenda') {
          return _buildAgendaView(docs);
        }
        return _buildListView(docs);
      },
    );
  }

  Widget _buildAgendaView(List<QueryDocumentSnapshot> docs) {
    final grouped = <String, List<QueryDocumentSnapshot>>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = data['date'] as String? ?? 'Sin fecha';
      grouped.putIfAbsent(date, () => []).add(doc);
    }

    final sortedDates = grouped.keys.toList()..sort();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: sortedDates.length,
      itemBuilder: (context, i) {
        final date = sortedDates[i];
        final appts = grouped[date]!;
        appts.sort((a, b) {
          final statusOrder = {'pending': 0, 'confirmed': 1, 'completed': 2, 'cancelled': 3};
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aOrder = statusOrder[aData['status']] ?? 4;
          final bOrder = statusOrder[bData['status']] ?? 4;
          return aOrder.compareTo(bOrder);
        });

        final isToday = date == today;
        String dateLabel;
        try {
          final parsed = DateTime.parse(date);
          final dayName = DateFormat('EEEE', 'es').format(parsed);
          dateLabel = '${dayName[0].toUpperCase()}${dayName.substring(1)}, ${DateFormat('d MMM', 'es').format(parsed)}';
        } catch (_) {
          dateLabel = date;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Row(
                children: [
                  Text(
                    dateLabel,
                    style: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: AdminTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Hoy', style: GoogleFonts.exo2(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ],
                  const Spacer(),
                  Text('${appts.length} cita${appts.length > 1 ? 's' : ''}', style: GoogleFonts.exo2(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5))),
                ],
              ),
            ),
            ...appts.asMap().entries.map((entry) {
              return _AppointmentRow(doc: entry.value)
                  .animate()
                  .fadeIn(duration: 200.ms, delay: (entry.key * 30).ms);
            }),
          ],
        );
      },
    );
  }

  Widget _buildListView(List<QueryDocumentSnapshot> docs) {
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
              decoration: BoxDecoration(shape: BoxShape.circle, color: info.$1),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer['name'] ?? 'Cliente', style: GoogleFonts.exo2(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${data['timeSlotDisplay'] ?? ''} · ${data['serviceTypeDisplay'] ?? ''}',
                    style: GoogleFonts.exo2(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: info.$1.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Text(info.$2, style: GoogleFonts.exo2(fontSize: 11, fontWeight: FontWeight.w500, color: info.$1)),
            ),
          ],
        ),
      ),
    );
  }
}
