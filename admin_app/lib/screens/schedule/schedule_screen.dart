import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';
import 'package:alx_clima_admin/screens/schedule/schedule_helpers.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _fs = FirebaseFirestore.instance;
  List<bool> _workDays = List.filled(7, false);
  int _startHour = 8;
  int _endHour = 18;
  int _weeks = 2;
  bool _isGenerating = false;
  bool _isSaving = false;
  static const _dayLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final doc = await _fs.collection('config').doc('workSchedule').get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final days = List<int>.from(data['workDays'] ?? []);
    setState(() {
      _workDays = List.generate(7, (i) => days.contains(i + 1));
      _startHour = data['startHour'] ?? 8;
      _endHour = data['endHour'] ?? 18;
    });
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    final active = <int>[for (var i = 0; i < 7; i++) if (_workDays[i]) i + 1];
    await _fs.collection('config').doc('workSchedule').set(
      {'workDays': active, 'startHour': _startHour, 'endHour': _endHour},
      SetOptions(merge: true),
    );
    setState(() => _isSaving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
  }

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    final active = <int>[for (var i = 0; i < 7; i++) if (_workDays[i]) i + 1];
    final now = DateTime.now();
    final batch = _fs.batch();
    for (var d = 0; d < _weeks * 7; d++) {
      final date = now.add(Duration(days: d));
      if (!active.contains(date.weekday)) continue;
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final slots = <String>[
        for (var h = _startHour; h < _endHour; h++)
          '${h.toString().padLeft(2, '0')}:00 - ${(h + 1).toString().padLeft(2, '0')}:00',
      ];
      batch.set(_fs.collection('schedule').doc(dateStr), {'date': dateStr, 'slots': slots}, SetOptions(merge: true));
    }
    await batch.commit();
    setState(() => _isGenerating = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Disponibilidad generada para $_weeks semanas')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Horarios', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 24),
              _configCard(theme),
              const SizedBox(height: 16),
              _generateCard(theme),
              const SizedBox(height: 24),
              Text('Fechas Programadas', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)).animate().fadeIn(duration: 300.ms, delay: 200.ms),
              const SizedBox(height: 12),
              _scheduleList(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _configCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Días Laborales', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: List.generate(7, (i) {
          final on = _workDays[i];
          return GestureDetector(
            onTap: () => setState(() => _workDays[i] = !on),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: on ? AdminTheme.primaryColor.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: on ? AdminTheme.primaryColor : theme.dividerColor),
              ),
              child: Text(_dayLabels[i], style: TextStyle(color: on ? AdminTheme.primaryColor : theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w500, fontSize: 13)),
            ),
          );
        })),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hora Inicio', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            buildHourDropdown(context, _startHour, (v) => setState(() => _startHour = v!)),
          ])),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hora Fin', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            buildHourDropdown(context, _endHour, (v) => setState(() => _endHour = v!)),
          ])),
        ]),
        const SizedBox(height: 14),
        AdminButton(text: 'Guardar Configuración', icon: Iconsax.tick_circle, isLoading: _isSaving, onPressed: _saveConfig),
      ]),
    ).animate().fadeIn(duration: 300.ms, delay: 80.ms);
  }

  Widget _generateCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Generar Disponibilidad', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 12),
        Row(children: [2, 4, 6, 8].map((w) {
          final sel = _weeks == w;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _weeks = w),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AdminTheme.secondaryColor.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sel ? AdminTheme.secondaryColor : theme.dividerColor),
                ),
                child: Text('$w sem', style: TextStyle(color: sel ? AdminTheme.secondaryColor : theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w500, fontSize: 13)),
              ),
            ),
          );
        }).toList()),
        const SizedBox(height: 14),
        AdminButton(text: 'Generar Disponibilidad', icon: Iconsax.calendar_add, isLoading: _isGenerating, color: AdminTheme.secondaryColor, onPressed: _generate),
      ]),
    ).animate().fadeIn(duration: 300.ms, delay: 140.ms);
  }

  Widget _scheduleList(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.collection('schedule').orderBy('date').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text('Sin fechas programadas', style: theme.textTheme.bodySmall)),
          );
        }
        return Column(children: docs.asMap().entries.map((entry) {
          final data = entry.value.data() as Map<String, dynamic>;
          final dateStr = data['date'] as String? ?? '';
          final slots = List<String>.from(data['slots'] ?? [])..sort();
          return GestureDetector(
            onTap: () => showEditDateSheet(context, _fs, entry.value.id, slots),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AdminTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Iconsax.calendar_1, color: AdminTheme.primaryColor, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(formatDateLabel(dateStr), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${slots.length} horarios', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
                ])),
                Icon(Iconsax.arrow_right_3, size: 18, color: theme.textTheme.bodySmall?.color),
              ]),
            ).animate().fadeIn(duration: 250.ms, delay: (200 + entry.key * 30).ms),
          );
        }).toList());
      },
    );
  }
}
