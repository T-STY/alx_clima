import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';
import 'appointment_actions.dart';
import 'appointment_detail.dart';

class DaySelector extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selectedDay;
  final DateTime today;
  final ValueChanged<DateTime> onDaySelected;

  const DaySelector({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.today,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = DateFormat('yyyy-MM-dd');
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final day = days[i];
          final isSel = fmt.format(day) == fmt.format(selectedDay);
          final isToday = fmt.format(day) == fmt.format(today);
          final dayName = DateFormat('EEE', 'es').format(day).toUpperCase();
          final chipColor = isSel ? null : isToday
              ? AdminTheme.primaryColor.withValues(alpha: 0.12)
              : isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7);
          final textColor = isSel ? Colors.white : null;

          return GestureDetector(
            onTap: () => onDaySelected(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: isSel ? AdminTheme.primaryGradient : null,
                color: chipColor,
                border: isToday && !isSel ? Border.all(color: AdminTheme.primaryColor.withValues(alpha: 0.4)) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayName, style: GoogleFonts.exo2(fontSize: 9, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 2),
                  Text('${day.day}', style: GoogleFonts.exo2(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TimeSlotRow extends StatelessWidget {
  final String hourLabel;
  final List<QueryDocumentSnapshot> appointments;
  final bool isLast;

  const TimeSlotRow({
    super.key,
    required this.hourLabel,
    required this.appointments,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, left: 16),
              child: Text(
                hourLabel,
                style: GoogleFonts.exo2(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: appointments.isNotEmpty
                      ? AdminTheme.primaryColor
                      : isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: appointments.isEmpty
                ? Container(
                    height: 48,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.03),
                      ),
                    ),
                  )
                : Column(
                    children: appointments
                        .map((doc) => _TimelineBlock(doc: doc))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TimelineBlock extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _TimelineBlock({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final status = data['status'] ?? '';
    final info = statusInfo(status);
    final eqCount = data['equipmentCount'] ?? 0;

    return GestureDetector(
      onTap: () => showAppointmentDetail(context, doc),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: info.$1.withValues(alpha: 0.1),
          border: Border.all(color: info.$1.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: info.$1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customer['name'] ?? 'Cliente',
                    style: GoogleFonts.exo2(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${data['serviceTypeDisplay'] ?? ''} · $eqCount equipo${eqCount != 1 ? 's' : ''}',
              style: GoogleFonts.exo2(
                fontSize: 11,
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppointmentListRow extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const AppointmentListRow({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final status = data['status'] ?? '';
    final info = statusInfo(status);

    final subtitleColor = Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5);
    return GestureDetector(
      onTap: () => showAppointmentDetail(context, doc),
      child: GlassCard(
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: info.$1)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer['name'] ?? 'Cliente', style: GoogleFonts.exo2(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${data['timeSlotDisplay'] ?? ''} · ${data['serviceTypeDisplay'] ?? ''}', style: GoogleFonts.exo2(fontSize: 12, color: subtitleColor)),
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
