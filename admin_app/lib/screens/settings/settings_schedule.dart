import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';

class WorkSchedulePage extends StatefulWidget {
  const WorkSchedulePage({super.key});

  @override
  State<WorkSchedulePage> createState() => _WorkSchedulePageState();
}

class _WorkSchedulePageState extends State<WorkSchedulePage> {
  static const _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

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
    _blockedDates = snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
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
        final start = '${h.toString().padLeft(2, '0')}:00';
        final end = '${(h + 1).toString().padLeft(2, '0')}:00';
        slots.add('$start - $end');
      }
      batch.set(
        FirebaseFirestore.instance.collection('schedule').doc(dateStr),
        {'slots': slots},
      );
    }
    await batch.commit();

    if (mounted) {
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Horarios generados para $_daysAhead días',
          style: GoogleFonts.exo2(fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ));
    }
  }

  Future<void> _blockDateAction() async {
    if (_blockDate == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_blockDate!);
    await FirebaseFirestore.instance
        .collection('blockedDates')
        .doc(dateStr)
        .set({
      'reason': _blockReasonCtrl.text.trim(),
      'blockedAt': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance
        .collection('schedule')
        .doc(dateStr)
        .delete();
    _blockReasonCtrl.clear();
    await _loadBlockedDates();
    if (mounted) {
      setState(() => _blockDate = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Fecha $dateStr bloqueada',
          style: GoogleFonts.exo2(fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ));
    }
  }

  Future<void> _blockSlotAction() async {
    if (_blockSlotDate == null || _blockSlotHour == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_blockSlotDate!);
    final ref =
        FirebaseFirestore.instance.collection('schedule').doc(dateStr);
    final doc = await ref.get();
    if (doc.exists) {
      final slots = List<String>.from(doc.data()?['slots'] ?? []);
      slots.remove(_blockSlotHour);
      await ref.set({'slots': slots});
    }
    if (mounted) {
      setState(() {
        _blockSlotHour = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Horario $_blockSlotHour eliminado de $dateStr',
          style: GoogleFonts.exo2(fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ));
    }
  }

  Future<void> _deleteBlockedDate(String docId) async {
    await FirebaseFirestore.instance
        .collection('blockedDates')
        .doc(docId)
        .delete();
    await _loadBlockedDates();
    if (mounted) setState(() {});
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
        title: Text(
          'Horario de trabajo',
          style: GoogleFonts.exo2(fontWeight: FontWeight.w600),
        ),
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
              _buildScheduleConfig(isDark),
              const SizedBox(height: 8),
              _sectionHeader(Iconsax.calendar_remove, 'Bloquear Fecha'),
              _buildBlockDate(isDark),
              const SizedBox(height: 8),
              _sectionHeader(Iconsax.clock, 'Bloquear Horario'),
              _buildBlockSlot(isDark),
              if (_blockedDates.isNotEmpty) ...[
                const SizedBox(height: 8),
                _sectionHeader(Iconsax.danger, 'Fechas Bloqueadas'),
                _buildBlockedList(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AdminTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.exo2(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AdminTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleConfig(bool isDark) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Días laborales',
            style: GoogleFonts.exo2(
              fontSize: 13,
              fontWeight: FontWeight.w500,
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
                  active ? _workDays.remove(day) : _workDays.add(day);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: active ? AdminTheme.primaryGradient : null,
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
                                : Colors.black.withValues(alpha: 0.06),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _hourDropdown(
                  'Inicio',
                  _startHour,
                  (v) => setState(() => _startHour = v),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _hourDropdown(
                  'Fin',
                  _endHour,
                  (v) => setState(() => _endHour = v),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _daysDropdown(isDark)),
            ],
          ),
          const SizedBox(height: 14),
          _generateButton(),
        ],
      ),
    );
  }

  Widget _buildBlockDate(bool isDark) {
    final dateLabel = _blockDate != null
        ? DateFormat('dd/MM/yyyy').format(_blockDate!)
        : 'Seleccionar fecha';
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickDate((d) => setState(() => _blockDate = d)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
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
                        Text(
                          dateLabel,
                          style: GoogleFonts.exo2(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _blockReasonCtrl,
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
            onTap: _blockDate != null ? _blockDateAction : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: _blockDate != null
                    ? AdminTheme.primaryGradient
                    : null,
                color: _blockDate == null
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
                    color: _blockDate != null ? Colors.white : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockSlot(bool isDark) {
    final slotDateLabel = _blockSlotDate != null
        ? DateFormat('dd/MM/yyyy').format(_blockSlotDate!)
        : 'Seleccionar fecha';
    final hourItems = List.generate(_endHour - _startHour, (i) {
      final h = _startHour + i;
      final start = '${h.toString().padLeft(2, '0')}:00';
      final end = '${(h + 1).toString().padLeft(2, '0')}:00';
      return '$start - $end';
    });

    return GlassCard(
      child: Column(
        children: [
          GestureDetector(
            onTap: () =>
                _pickDate((d) => setState(() => _blockSlotDate = d)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
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
                  Text(
                    slotDateLabel,
                    style: GoogleFonts.exo2(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _blockSlotHour,
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
            onChanged: (v) => setState(() => _blockSlotHour = v),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: (_blockSlotDate != null && _blockSlotHour != null)
                ? _blockSlotAction
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient:
                    (_blockSlotDate != null && _blockSlotHour != null)
                        ? AdminTheme.primaryGradient
                        : null,
                color: (_blockSlotDate == null || _blockSlotHour == null)
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
                    color: (_blockSlotDate != null &&
                            _blockSlotHour != null)
                        ? Colors.white
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedList() {
    return GlassCard(
      child: Column(
        children: _blockedDates.map((bd) {
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
                        Text(
                          reason,
                          style: GoogleFonts.exo2(fontSize: 11),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteBlockedDate(id),
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

  Widget _hourDropdown(
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
          dropdownColor: Theme.of(context).cardColor,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
          ),
          style: GoogleFonts.exo2(
            fontSize: 13,
            color: isDark ? Colors.white : Colors.black,
          ),
          items: List.generate(
            24,
            (h) => DropdownMenuItem(
              value: h,
              child: Text(
                '${h.toString().padLeft(2, '0')}:00',
                style: GoogleFonts.exo2(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _daysDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Días',
          style: GoogleFonts.exo2(fontSize: 11, letterSpacing: 0.3),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: _daysAhead,
          isDense: true,
          dropdownColor: Theme.of(context).cardColor,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
          ),
          style: GoogleFonts.exo2(
            fontSize: 13,
            color: isDark ? Colors.white : Colors.black,
          ),
          items: [15, 30, 60, 90]
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(
                      '$d días',
                      style: GoogleFonts.exo2(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _daysAhead = v);
          },
        ),
      ],
    );
  }

  Widget _generateButton() {
    return GestureDetector(
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
    );
  }
}
