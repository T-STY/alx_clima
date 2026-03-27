import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';

class WorkScheduleCard extends StatefulWidget {
  const WorkScheduleCard({super.key});

  @override
  State<WorkScheduleCard> createState() => _WorkScheduleCardState();
}

class _WorkScheduleCardState extends State<WorkScheduleCard> {
  static const _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  Set<int> _workDays = {1, 2, 3, 4, 5};
  int _startHour = 9;
  int _endHour = 18;
  int _daysAhead = 30;
  bool _loaded = false;
  bool _generating = false;

  Future<void> _load() async {
    if (_loaded) return;
    final doc = await FirebaseFirestore.instance.collection('config').doc('workSchedule').get();
    if (doc.exists) {
      final d = doc.data()!;
      _workDays = ((d['workDays'] as List?) ?? [1, 2, 3, 4, 5]).cast<int>().toSet();
      _startHour = d['startHour'] ?? 9;
      _endHour = d['endHour'] ?? 18;
    }
    _loaded = true;
  }

  Future<void> _saveConfig() async {
    await FirebaseFirestore.instance.collection('config').doc('workSchedule').set({
      'workDays': _workDays.toList()..sort(), 'startHour': _startHour, 'endHour': _endHour,
    });
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    await _saveConfig();

    final now = DateTime.now();
    final batch = FirebaseFirestore.instance.batch();

    for (var i = 0; i < _daysAhead; i++) {
      final date = now.add(Duration(days: i));
      final weekday = date.weekday;

      if (!_workDays.contains(weekday)) continue;

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final slots = <String>[];

      for (var h = _startHour; h < _endHour; h++) {
        final start = '${h.toString().padLeft(2, '0')}:00';
        final end = '${(h + 1).toString().padLeft(2, '0')}:00';
        slots.add('$start - $end');
      }

      final ref =
          FirebaseFirestore.instance.collection('schedule').doc(dateStr);
      batch.set(ref, {'slots': slots});
    }

    await batch.commit();

    if (mounted) {
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Horarios generados para $_daysAhead días', style: GoogleFonts.exo2(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder(
      future: _load(),
      builder: (context, _) {
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Días laborales',
                style: GoogleFonts.exo2(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  color: AdminTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final active = _workDays.contains(day);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (active) {
                        _workDays.remove(day);
                      } else {
                        _workDays.add(day);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient:
                            active ? AdminTheme.primaryGradient : null,
                        color: active
                            ? null
                            : isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.white.withValues(alpha: 0.7),
                        border: active
                            ? null
                            : Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black
                                        .withValues(alpha: 0.06),
                              ),
                      ),
                      child: Text(
                        _dayNames[i],
                        style: GoogleFonts.exo2(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: active ? Colors.white : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _hourField(
                      'Inicio',
                      _startHour,
                      (v) => setState(() => _startHour = v),
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _hourField(
                      'Fin',
                      _endHour,
                      (v) => setState(() => _endHour = v),
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _daysField(isDark),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _generating ? null : _generate,
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
                      if (_generating)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else ...[
                        const Icon(
                          Iconsax.calendar_add,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Generar horarios',
                          style: GoogleFonts.exo2(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _hourField(
    String label,
    int value,
    ValueChanged<int> onChanged,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.exo2(fontSize: 11, letterSpacing: 0.3),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: value,
          isDense: true,
          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
          style: GoogleFonts.exo2(fontSize: 13),
          items: List.generate(24, (h) => DropdownMenuItem(
            value: h, child: Text('${h.toString().padLeft(2, '0')}:00', style: GoogleFonts.exo2(fontSize: 13)),
          )),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ],
    );
  }

  Widget _daysField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Días', style: GoogleFonts.exo2(fontSize: 11, letterSpacing: 0.3)),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: _daysAhead,
          isDense: true,
          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
          style: GoogleFonts.exo2(fontSize: 13),
          items: [15, 30, 60, 90].map((d) => DropdownMenuItem(value: d, child: Text('$d', style: GoogleFonts.exo2(fontSize: 13)))).toList(),
          onChanged: (v) { if (v != null) setState(() => _daysAhead = v); },
        ),
      ],
    );
  }
}
