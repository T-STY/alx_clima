import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/screens/settings/schedule_blocking_widgets.dart';

class WorkSchedulePage extends StatefulWidget {
  const WorkSchedulePage({super.key});

  @override
  State<WorkSchedulePage> createState() => _WorkSchedulePageState();
}

class _WorkSchedulePageState extends State<WorkSchedulePage> {
  Set<int> _workDays = {1, 2, 3, 4, 5};
  int _startHour = 9;
  int _endHour = 18;
  int _daysAhead = 30;
  bool _loaded = false;
  bool _generating = false;

  DateTime? _blockDate;
  final _blockReasonCtrl = TextEditingController();
  DateTime? _blockSlotDate;
  String? _blockSlotHour;
  List<Map<String, dynamic>> _blockedDates = [];

  @override
  void dispose() {
    _blockReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loaded) return;
    final doc = await FirebaseFirestore.instance
        .collection('config')
        .doc('workSchedule')
        .get();
    if (doc.exists) {
      final d = doc.data()!;
      _workDays = ((d['workDays'] as List?) ?? [1, 2, 3, 4, 5])
          .cast<int>()
          .toSet();
      _startHour = d['startHour'] ?? 9;
      _endHour = d['endHour'] ?? 18;
    }
    await _loadBlockedDates();
    _loaded = true;
  }

  Future<void> _loadBlockedDates() async {
    final snap = await FirebaseFirestore.instance
        .collection('blockedDates')
        .orderBy('blockedAt', descending: true)
        .get();
    _blockedDates = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> _saveConfig() async {
    await FirebaseFirestore.instance
        .collection('config')
        .doc('workSchedule')
        .set({
      'workDays': _workDays.toList()..sort(),
      'startHour': _startHour,
      'endHour': _endHour,
    });
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    await _saveConfig();
    final now = DateTime.now();
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < _daysAhead; i++) {
      final date = now.add(Duration(days: i));
      if (!_workDays.contains(date.weekday)) continue;
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final slots = <String>[];
      for (var h = _startHour; h < _endHour; h++) {
        final s = '${h.toString().padLeft(2, '0')}:00';
        final e = '${(h + 1).toString().padLeft(2, '0')}:00';
        slots.add('$s - $e');
      }
      batch.set(
        FirebaseFirestore.instance.collection('schedule').doc(dateStr),
        {'slots': slots},
      );
    }
    await batch.commit();
    if (mounted) {
      setState(() => _generating = false);
      _showSnack('Horarios generados para $_daysAhead días');
    }
  }

  Future<void> _blockDateAction() async {
    if (_blockDate == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_blockDate!);
    await FirebaseFirestore.instance.collection('blockedDates').doc(dateStr).set({
      'reason': _blockReasonCtrl.text.trim(),
      'blockedAt': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance.collection('schedule').doc(dateStr).delete();
    _blockReasonCtrl.clear();
    await _loadBlockedDates();
    if (mounted) {
      setState(() => _blockDate = null);
      _showSnack('Fecha $dateStr bloqueada');
    }
  }

  Future<void> _blockSlotAction() async {
    if (_blockSlotDate == null || _blockSlotHour == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_blockSlotDate!);
    final ref = FirebaseFirestore.instance.collection('schedule').doc(dateStr);
    final doc = await ref.get();
    if (doc.exists) {
      final slots = List<String>.from(doc.data()?['slots'] ?? []);
      slots.remove(_blockSlotHour);
      await ref.set({'slots': slots});
    }
    if (mounted) {
      final removed = _blockSlotHour;
      setState(() => _blockSlotHour = null);
      _showSnack('Horario $removed eliminado de $dateStr');
    }
  }

  Future<void> _deleteBlockedDate(String docId) async {
    await FirebaseFirestore.instance.collection('blockedDates').doc(docId).delete();
    await _loadBlockedDates();
    if (mounted) setState(() {});
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.exo2(fontSize: 13)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _pickDate(ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Horario de trabajo',
            style: GoogleFonts.exo2(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder(
        future: _load(),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
            children: [
              _sectionHeader(Iconsax.calendar_1, 'Configuración'),
              ScheduleConfigSection(
                workDays: _workDays,
                startHour: _startHour,
                endHour: _endHour,
                daysAhead: _daysAhead,
                isDark: isDark,
                generating: _generating,
                onToggleDay: (day) => setState(() {
                  _workDays.contains(day)
                      ? _workDays.remove(day)
                      : _workDays.add(day);
                }),
                onStartChanged: (v) => setState(() => _startHour = v),
                onEndChanged: (v) => setState(() => _endHour = v),
                onDaysChanged: (v) => setState(() => _daysAhead = v),
                onGenerate: _generate,
              ),
              const SizedBox(height: 8),
              _sectionHeader(Iconsax.calendar_remove, 'Bloquear Fecha'),
              BlockDateSection(
                blockDate: _blockDate,
                reasonCtrl: _blockReasonCtrl,
                isDark: isDark,
                onPickDate: () => _pickDate((d) => setState(() => _blockDate = d)),
                onBlock: _blockDate != null ? _blockDateAction : null,
              ),
              const SizedBox(height: 8),
              _sectionHeader(Iconsax.clock, 'Bloquear Horario'),
              BlockSlotSection(
                blockSlotDate: _blockSlotDate,
                blockSlotHour: _blockSlotHour,
                isDark: isDark,
                startHour: _startHour,
                endHour: _endHour,
                onPickDate: () =>
                    _pickDate((d) => setState(() => _blockSlotDate = d)),
                onHourChanged: (v) => setState(() => _blockSlotHour = v),
                onBlock: (_blockSlotDate != null && _blockSlotHour != null)
                    ? _blockSlotAction
                    : null,
              ),
              if (_blockedDates.isNotEmpty) ...[
                const SizedBox(height: 8),
                _sectionHeader(Iconsax.danger, 'Fechas Bloqueadas'),
                BlockedDatesList(
                  blockedDates: _blockedDates,
                  onDelete: _deleteBlockedDate,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: AdminTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.exo2(
            fontSize: 14, fontWeight: FontWeight.w600, color: AdminTheme.primaryColor,
          )),
        ]),
      );
}
