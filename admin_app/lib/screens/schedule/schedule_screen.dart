import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/screens/schedule/schedule_dates.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text('Horario', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),
            _sectionLabel('CONFIGURACIÓN', theme),
            const SizedBox(height: 12),
            _WorkScheduleConfig(firestore: _firestore),
            const SizedBox(height: 32),
            _sectionLabel('FECHAS PROGRAMADAS', theme),
            const SizedBox(height: 12),
            ScheduleDates(firestore: _firestore),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, ThemeData theme) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: theme.textTheme.bodySmall?.color,
      ),
    );
  }
}

class _WorkScheduleConfig extends StatefulWidget {
  final FirebaseFirestore firestore;
  const _WorkScheduleConfig({required this.firestore});

  @override
  State<_WorkScheduleConfig> createState() => _WorkScheduleConfigState();
}

class _WorkScheduleConfigState extends State<_WorkScheduleConfig> {
  List<int> _workDays = [1, 2, 3, 4, 5];
  int _startHour = 8;
  int _endHour = 18;
  int _daysAhead = 30;
  bool _loading = true;

  static const _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final doc = await widget.firestore.doc('config/workSchedule').get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _workDays = List<int>.from(data['workDays'] ?? [1, 2, 3, 4, 5]);
        _startHour = data['startHour'] ?? 8;
        _endHour = data['endHour'] ?? 18;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    await widget.firestore.doc('config/workSchedule').set({
      'workDays': _workDays,
      'startHour': _startHour,
      'endHour': _endHour,
    });

    final now = DateTime.now();
    for (var i = 0; i < _daysAhead; i++) {
      final day = now.add(Duration(days: i));
      if (!_workDays.contains(day.weekday)) continue;

      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final existing = await widget.firestore.collection('schedule').doc(dateStr).get();
      if (existing.exists) continue;

      final slots = <String>[];
      for (var h = _startHour; h < _endHour; h++) {
        slots.add('${h.toString().padLeft(2, '0')}:00');
      }
      await widget.firestore.collection('schedule').doc(dateStr).set({'slots': slots});
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Horario generado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));

    return Container(
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(7, (i) {
              final day = i + 1;
              final active = _workDays.contains(day);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    active ? _workDays.remove(day) : _workDays.add(day);
                    _workDays.sort();
                  }),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _dayNames[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? AdminTheme.primaryColor : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Inicio', style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _startHour,
                dropdownColor: theme.cardColor,
                underline: const SizedBox.shrink(),
                items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('${i.toString().padLeft(2, '0')}:00'))),
                onChanged: (v) => setState(() => _startHour = v ?? _startHour),
              ),
              const SizedBox(width: 24),
              Text('Fin', style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _endHour,
                dropdownColor: theme.cardColor,
                underline: const SizedBox.shrink(),
                items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('${i.toString().padLeft(2, '0')}:00'))),
                onChanged: (v) => setState(() => _endHour = v ?? _endHour),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Días a generar', style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _daysAhead,
                dropdownColor: theme.cardColor,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7')),
                  DropdownMenuItem(value: 14, child: Text('14')),
                  DropdownMenuItem(value: 30, child: Text('30')),
                  DropdownMenuItem(value: 60, child: Text('60')),
                ],
                onChanged: (v) => setState(() => _daysAhead = v ?? _daysAhead),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _generate,
            child: Text(
              'Generar horario',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
