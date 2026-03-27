import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'appointment_actions.dart';

Future<void> rescheduleAppointment(
  BuildContext context, QueryDocumentSnapshot doc,
) async {
  final scheduleSnap = await FirebaseFirestore.instance.collection('schedule').get();
  final available = <String, List<String>>{};
  for (final sDoc in scheduleSnap.docs) {
    final slots = (sDoc.data()['slots'] as List?)?.cast<String>() ?? [];
    if (slots.isNotEmpty) available[sDoc.id] = slots;
  }
  final dates = available.keys.toList()..sort();
  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RescheduleSheet(
      doc: doc,
      dates: dates,
      available: available,
    ),
  );
}

class _RescheduleSheet extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final List<String> dates;
  final Map<String, List<String>> available;

  const _RescheduleSheet({
    required this.doc,
    required this.dates,
    required this.available,
  });

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  String? _selectedDate;
  final _selectedSlots = <String>{};
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slots = _selectedDate != null ? (widget.available[_selectedDate] ?? []) : <String>[];
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B0D14).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                child: Text(
                  'Reagendar cita',
                  style: GoogleFonts.exo2(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    Text(
                      'Fecha disponible',
                      style: GoogleFonts.exo2(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.dates.map((date) {
                        final selected = _selectedDate == date;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedDate = date;
                            _selectedSlots.clear();
                          }),
                          child: _pill(date, selected, isDark),
                        );
                      }).toList(),
                    ),
                    if (slots.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Horarios disponibles',
                        style: GoogleFonts.exo2(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: slots.map((slot) {
                          final selected = _selectedSlots.contains(slot);
                          return GestureDetector(
                            onTap: () => setState(() {
                              selected ? _selectedSlots.remove(slot) : _selectedSlots.add(slot);
                            }),
                            child: _pill(slot, selected, isDark),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildConfirmButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, bool selected, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: selected ? AdminTheme.primaryGradient : null,
        color: selected
            ? null
            : isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.7),
        border: selected
            ? null
            : Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
              ),
      ),
      child: Text(
        text,
        style: GoogleFonts.exo2(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: selected ? Colors.white : null,
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final canConfirm =
        _selectedDate != null && _selectedSlots.isNotEmpty && !_loading;

    return GestureDetector(
      onTap: canConfirm ? _doReschedule : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: canConfirm ? AdminTheme.primaryGradient : null,
          color: canConfirm ? null : Colors.grey.withValues(alpha: 0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else ...[
              const Icon(Iconsax.calendar_tick, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Confirmar reagendación',
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
    );
  }

  Future<void> _doReschedule() async {
    if (_selectedDate == null || _selectedSlots.isEmpty) return;
    setState(() => _loading = true);

    final data = widget.doc.data() as Map<String, dynamic>;
    final sortedSlots = _selectedSlots.toList()..sort();

    await cancelAppointment(widget.doc);

    final newRef =
        FirebaseFirestore.instance.collection('appointments').doc();
    final display = sortedSlots.length == 1
        ? sortedSlots.first
        : '${sortedSlots.first.split(' - ').first} - ${sortedSlots.last.split(' - ').last}';

    await newRef.set({
      ...data,
      'appointmentId': newRef.id,
      'date': _selectedDate,
      'timeSlots': sortedSlots,
      'timeSlotDisplay': display,
      'status': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final schedRef = FirebaseFirestore.instance
        .collection('schedule')
        .doc(_selectedDate);
    final schedDoc = await schedRef.get();
    if (schedDoc.exists) {
      final existing =
          (schedDoc.data()?['slots'] as List?)?.cast<String>() ?? [];
      existing.removeWhere((s) => sortedSlots.contains(s));
      await schedRef.update({'slots': existing});
    }

    for (final slot in sortedSlots) {
      await FirebaseFirestore.instance.collection('bookedSlots').add({
        'date': _selectedDate,
        'slot': slot,
        'userId': data['userId'],
        'bookedAt': FieldValue.serverTimestamp(),
      });
    }

    final userId = data['userId'] as String?;
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'reschedule',
        'title': 'Cita reagendada',
        'message':
            'Tu cita ha sido reagendada al $_selectedDate de $display',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
