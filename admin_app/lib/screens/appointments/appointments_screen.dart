import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'agenda_widgets.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String _view = 'agenda';
  String _filter = 'active';
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

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
            Icon(
              icon,
              size: 14,
              color: sel
                  ? Colors.white
                  : Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.exo2(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: sel
                    ? Colors.white
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: selected
                    ? null
                    : isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.7),
              ),
              child: Text(
                label,
                style: GoogleFonts.exo2(
                  fontSize: 12,
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

  Widget _buildContent() {
    Query query = FirebaseFirestore.instance
        .collection('appointments')
        .orderBy('date', descending: false);
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
          return Center(
            child: Text('Sin citas', style: GoogleFonts.exo2(fontSize: 14)),
          );
        }
        if (_view == 'agenda') return _buildAgendaView(docs);
        return _buildListView(docs);
      },
    );
  }

  Widget _buildAgendaView(List<QueryDocumentSnapshot> docs) {
    final today = DateTime.now();
    final days = List.generate(7, (i) =>
        DateTime(today.year, today.month, today.day).add(Duration(days: i)));
    final selStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final dayDocs = docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return data['date'] == selStr;
    }).toList();
    final hours = List.generate(10, (i) => i + 9);

    return Column(
      children: [
        DaySelector(
          days: days,
          selectedDay: _selectedDay,
          today: today,
          onDaySelected: (d) => setState(() => _selectedDay = d),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 0, 16, 100),
            itemCount: hours.length,
            itemBuilder: (context, i) {
              final h = hours[i];
              final hStr = '${h.toString().padLeft(2, '0')}:00';
              final nStr = '${(h + 1).toString().padLeft(2, '0')}:00';
              final slot = '$hStr - $nStr';
              final matched = dayDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final slots =
                    (data['timeSlots'] as List?)?.cast<String>() ?? [];
                return slots.contains(slot);
              }).toList();
              return TimeSlotRow(
                hourLabel: hStr,
                appointments: matched,
                isLast: i == hours.length - 1,
              ).animate().fadeIn(duration: 200.ms, delay: (i * 30).ms);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListView(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
      itemCount: docs.length,
      itemBuilder: (context, i) => AppointmentListRow(doc: docs[i])
          .animate()
          .fadeIn(duration: 250.ms, delay: (i * 40).ms)
          .slideX(begin: 0.05, end: 0),
    );
  }
}
