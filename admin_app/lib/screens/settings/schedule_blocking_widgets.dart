import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';

class BlockDateSection extends StatelessWidget {
  final DateTime? blockDate;
  final TextEditingController reasonCtrl;
  final bool isDark;
  final VoidCallback onPickDate;
  final VoidCallback? onBlock;

  const BlockDateSection({
    super.key,
    required this.blockDate,
    required this.reasonCtrl,
    required this.isDark,
    required this.onPickDate,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = blockDate != null
        ? DateFormat('dd/MM/yyyy').format(blockDate!)
        : 'Seleccionar fecha';
    return GlassCard(
      child: Column(
        children: [
          GestureDetector(
            onTap: onPickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.calendar_1, size: 16),
                  const SizedBox(width: 8),
                  Text(dateLabel, style: GoogleFonts.exo2(fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: reasonCtrl,
            style: GoogleFonts.exo2(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Razón del bloqueo',
              hintStyle: GoogleFonts.exo2(fontSize: 13),
              prefixIcon: const Icon(Iconsax.note_text, size: 18),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onBlock,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: blockDate != null ? AdminTheme.primaryGradient : null,
                color: blockDate == null
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.withValues(alpha: 0.2))
                    : null,
              ),
              child: Center(
                child: Text(
                  'Bloquear fecha',
                  style: GoogleFonts.exo2(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: blockDate != null ? Colors.white : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BlockSlotSection extends StatelessWidget {
  final DateTime? blockSlotDate;
  final String? blockSlotHour;
  final bool isDark;
  final int startHour;
  final int endHour;
  final VoidCallback onPickDate;
  final ValueChanged<String?> onHourChanged;
  final VoidCallback? onBlock;

  const BlockSlotSection({
    super.key,
    required this.blockSlotDate,
    required this.blockSlotHour,
    required this.isDark,
    required this.startHour,
    required this.endHour,
    required this.onPickDate,
    required this.onHourChanged,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final slotDateLabel = blockSlotDate != null
        ? DateFormat('dd/MM/yyyy').format(blockSlotDate!)
        : 'Seleccionar fecha';
    final hourItems = List.generate(endHour - startHour, (i) {
      final h = startHour + i;
      final start = '${h.toString().padLeft(2, '0')}:00';
      final end = '${(h + 1).toString().padLeft(2, '0')}:00';
      return '$start - $end';
    });
    final canBlock = blockSlotDate != null && blockSlotHour != null;

    return GlassCard(
      child: Column(
        children: [
          GestureDetector(
            onTap: onPickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.calendar_1, size: 16),
                  const SizedBox(width: 8),
                  Text(slotDateLabel, style: GoogleFonts.exo2(fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: blockSlotHour,
            isDense: true,
            dropdownColor: Theme.of(context).cardColor,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Seleccionar horario',
              hintStyle: GoogleFonts.exo2(fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            style: GoogleFonts.exo2(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black,
            ),
            items: hourItems
                .map((h) => DropdownMenuItem(
                      value: h,
                      child: Text(
                        h,
                        style: GoogleFonts.exo2(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: onHourChanged,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onBlock,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: canBlock ? AdminTheme.primaryGradient : null,
                color: !canBlock
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.withValues(alpha: 0.2))
                    : null,
              ),
              child: Center(
                child: Text(
                  'Bloquear horario',
                  style: GoogleFonts.exo2(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: canBlock ? Colors.white : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BlockedDatesList extends StatelessWidget {
  final List<Map<String, dynamic>> blockedDates;
  final ValueChanged<String> onDelete;

  const BlockedDatesList({
    super.key,
    required this.blockedDates,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: blockedDates.map((bd) {
          final id = bd['id'] as String;
          final reason = bd['reason'] as String? ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(
                  Iconsax.calendar_remove,
                  size: 16,
                  color: AdminTheme.errorColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        id,
                        style: GoogleFonts.exo2(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (reason.isNotEmpty)
                        Text(reason, style: GoogleFonts.exo2(fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onDelete(id),
                  icon: const Icon(
                    Iconsax.trash,
                    size: 16,
                    color: AdminTheme.errorColor,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
