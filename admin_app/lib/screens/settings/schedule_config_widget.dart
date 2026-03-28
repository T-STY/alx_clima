import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';

class ScheduleConfigSection extends StatelessWidget {
  final Set<int> workDays;
  final int startHour;
  final int endHour;
  final int daysAhead;
  final bool isDark;
  final bool generating;
  final ValueChanged<int> onToggleDay;
  final ValueChanged<int> onStartChanged;
  final ValueChanged<int> onEndChanged;
  final ValueChanged<int> onDaysChanged;
  final VoidCallback onGenerate;

  static const _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  const ScheduleConfigSection({
    super.key,
    required this.workDays,
    required this.startHour,
    required this.endHour,
    required this.daysAhead,
    required this.isDark,
    required this.generating,
    required this.onToggleDay,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onDaysChanged,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Días laborales', style: GoogleFonts.exo2(
            fontSize: 13, fontWeight: FontWeight.w500, color: AdminTheme.secondaryColor,
          )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(7, (i) {
              final day = i + 1;
              final active = workDays.contains(day);
              return GestureDetector(
                onTap: () => onToggleDay(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44, height: 36, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: active ? AdminTheme.primaryGradient : null,
                    color: active ? null : isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.7),
                    border: active ? null : Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Text(_dayNames[i], style: GoogleFonts.exo2(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: active ? Colors.white : null,
                  )),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _hourDropdown(context, 'Inicio', startHour, onStartChanged)),
            const SizedBox(width: 12),
            Expanded(child: _hourDropdown(context, 'Fin', endHour, onEndChanged)),
            const SizedBox(width: 12),
            Expanded(child: _daysDropdown(context)),
          ]),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: generating ? null : onGenerate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: AdminTheme.primaryGradient,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (generating)
                    const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  else ...[
                    const Icon(Iconsax.calendar_add, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Generar horarios', style: GoogleFonts.exo2(
                        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hourDropdown(BuildContext context, String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.exo2(fontSize: 11, letterSpacing: 0.3)),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: value, isDense: true,
          dropdownColor: Theme.of(context).cardColor,
          decoration: const InputDecoration(isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
          style: GoogleFonts.exo2(fontSize: 13, color: isDark ? Colors.white : Colors.black),
          items: List.generate(24, (h) => DropdownMenuItem(value: h,
              child: Text('${h.toString().padLeft(2, '0')}:00',
                  style: GoogleFonts.exo2(fontSize: 13, color: isDark ? Colors.white : Colors.black)))),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ],
    );
  }

  Widget _daysDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Días', style: GoogleFonts.exo2(fontSize: 11, letterSpacing: 0.3)),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: daysAhead, isDense: true,
          dropdownColor: Theme.of(context).cardColor,
          decoration: const InputDecoration(isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
          style: GoogleFonts.exo2(fontSize: 13, color: isDark ? Colors.white : Colors.black),
          items: [15, 30, 60, 90].map((d) => DropdownMenuItem(value: d,
              child: Text('$d días', style: GoogleFonts.exo2(fontSize: 13,
                  color: isDark ? Colors.white : Colors.black)))).toList(),
          onChanged: (v) { if (v != null) onDaysChanged(v); },
        ),
      ],
    );
  }
}
