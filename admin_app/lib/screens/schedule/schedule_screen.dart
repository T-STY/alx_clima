import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _firestore = FirebaseFirestore.instance;

  List<bool> _workDays = List.filled(7, false);
  int _startHour = 8;
  int _endHour = 18;
  int _weeksToGenerate = 2;
  bool _isGenerating = false;
  bool _isSavingConfig = false;

  final List<String> _dayLabels = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  final List<int> _weekOptions = [2, 4, 6, 8];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final doc = await _firestore.collection('config').doc('workSchedule').get();
    if (doc.exists) {
      final data = doc.data()!;
      final days = List<int>.from(data['workDays'] ?? []);
      setState(() {
        _workDays = List.generate(7, (i) => days.contains(i + 1));
        _startHour = data['startHour'] ?? 8;
        _endHour = data['endHour'] ?? 18;
      });
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSavingConfig = true);
    final activeDays = <int>[];
    for (var i = 0; i < 7; i++) {
      if (_workDays[i]) activeDays.add(i + 1);
    }
    await _firestore.collection('config').doc('workSchedule').set({
      'workDays': activeDays,
      'startHour': _startHour,
      'endHour': _endHour,
    }, SetOptions(merge: true));
    setState(() => _isSavingConfig = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada')),
      );
    }
  }

  Future<void> _generateAvailability() async {
    setState(() => _isGenerating = true);
    final activeDays = <int>[];
    for (var i = 0; i < 7; i++) {
      if (_workDays[i]) activeDays.add(i + 1);
    }

    final now = DateTime.now();
    final batch = _firestore.batch();

    for (var d = 0; d < _weeksToGenerate * 7; d++) {
      final date = now.add(Duration(days: d));
      if (!activeDays.contains(date.weekday)) continue;

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final slots = <String>[];
      for (var h = _startHour; h < _endHour; h++) {
        final start = '${h.toString().padLeft(2, '0')}:00';
        final end = '${(h + 1).toString().padLeft(2, '0')}:00';
        slots.add('$start - $end');
      }

      final docRef = _firestore.collection('schedule').doc(dateStr);
      batch.set(docRef, {
        'date': dateStr,
        'slots': slots,
      }, SetOptions(merge: true));
    }

    await batch.commit();
    setState(() => _isGenerating = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Disponibilidad generada para $_weeksToGenerate semanas',
          ),
        ),
      );
    }
  }

  void _showEditDateSheet(String dateId, List<String> currentSlots) {
    final slots = List<String>.from(currentSlots);
    slots.sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AdminTheme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Editar $dateId',
                    style: const TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slots.map((slot) {
                      return Chip(
                        label: Text(
                          slot,
                          style: const TextStyle(
                            color: AdminTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: AdminTheme.surfaceColor,
                        deleteIcon: const Icon(
                          Iconsax.close_circle,
                          size: 16,
                          color: AdminTheme.errorColor,
                        ),
                        onDeleted: () {
                          setSheetState(() => slots.remove(slot));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  AdminButton(
                    text: 'Agregar Horario',
                    icon: Iconsax.add,
                    isOutlined: true,
                    onPressed: () async {
                      final startTime = await showTimePicker(
                        context: ctx,
                        initialTime: const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (startTime == null) return;
                      final endTime = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay(
                          hour: startTime.hour + 1,
                          minute: 0,
                        ),
                      );
                      if (endTime == null) return;

                      final startStr =
                          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                      final endStr =
                          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
                      final newSlot = '$startStr - $endStr';

                      setSheetState(() {
                        if (!slots.contains(newSlot)) {
                          slots.add(newSlot);
                          slots.sort();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  AdminButton(
                    text: 'Guardar',
                    icon: Iconsax.tick_circle,
                    onPressed: () async {
                      await _firestore
                          .collection('schedule')
                          .doc(dateId)
                          .update({'slots': slots});
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestión de Horarios',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AdminTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminTheme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Días Laborales',
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(7, (i) {
                        return FilterChip(
                          label: Text(_dayLabels[i]),
                          selected: _workDays[i],
                          selectedColor:
                              AdminTheme.primaryColor.withValues(alpha: 0.2),
                          checkmarkColor: AdminTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: _workDays[i]
                                ? AdminTheme.primaryColor
                                : AdminTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: _workDays[i]
                                ? AdminTheme.primaryColor
                                : AdminTheme.dividerColor,
                          ),
                          onSelected: (val) {
                            setState(() => _workDays[i] = val);
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hora Inicio',
                                style: TextStyle(
                                  color: AdminTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildHourDropdown(
                                _startHour,
                                (v) => setState(() => _startHour = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hora Fin',
                                style: TextStyle(
                                  color: AdminTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildHourDropdown(
                                _endHour,
                                (v) => setState(() => _endHour = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AdminButton(
                      text: 'Guardar Configuración',
                      icon: Iconsax.tick_circle,
                      isLoading: _isSavingConfig,
                      onPressed: _saveConfig,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AdminTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminTheme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generar Disponibilidad',
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _weekOptions.map((w) {
                        final selected = _weeksToGenerate == w;
                        return ChoiceChip(
                          label: Text('$w semanas'),
                          selected: selected,
                          selectedColor:
                              AdminTheme.secondaryColor.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: selected
                                ? AdminTheme.secondaryColor
                                : AdminTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: selected
                                ? AdminTheme.secondaryColor
                                : AdminTheme.dividerColor,
                          ),
                          onSelected: (_) {
                            setState(() => _weeksToGenerate = w);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    AdminButton(
                      text: 'Generar Disponibilidad',
                      icon: Iconsax.calendar_add,
                      isLoading: _isGenerating,
                      color: AdminTheme.secondaryColor,
                      onPressed: _generateAvailability,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

              const SizedBox(height: 24),

              Text(
                'Fechas Programadas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('schedule')
                    .orderBy('date')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AdminTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Sin fechas programadas',
                          style: TextStyle(color: AdminTheme.textSecondary),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: docs.asMap().entries.map((entry) {
                      final data =
                          entry.value.data() as Map<String, dynamic>;
                      final dateStr = data['date'] as String? ?? '';
                      final slots = List<String>.from(data['slots'] ?? []);
                      slots.sort();

                      return GestureDetector(
                        onTap: () => _showEditDateSheet(entry.value.id, slots),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AdminTheme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AdminTheme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AdminTheme.primaryColor
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Iconsax.calendar_1,
                                  color: AdminTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDateLabel(dateStr),
                                      style: const TextStyle(
                                        color: AdminTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${slots.length} horarios',
                                      style: const TextStyle(
                                        color: AdminTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Iconsax.arrow_right_3,
                                color: AdminTheme.textSecondary,
                                size: 18,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(
                              duration: 300.ms,
                              delay: (300 + entry.key * 40).ms,
                            ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourDropdown(int value, ValueChanged<int?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.dividerColor),
      ),
      child: DropdownButton<int>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AdminTheme.cardColor,
        style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
        items: List.generate(24, (i) {
          return DropdownMenuItem(
            value: i,
            child: Text('${i.toString().padLeft(2, '0')}:00'),
          );
        }),
        onChanged: onChanged,
      ),
    );
  }

  String _formatDateLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE dd MMM yyyy', 'es').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}
