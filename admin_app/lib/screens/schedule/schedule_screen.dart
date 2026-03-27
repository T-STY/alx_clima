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
  List<bool> _wd = List.filled(7, false);
  int _sh = 8, _eh = 18, _wk = 2;
  bool _gen = false, _sav = false;
  static const _dl = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void initState() { super.initState(); _loadConfig(); }

  Future<void> _loadConfig() async {
    final doc = await _fs.collection('config').doc('workSchedule').get();
    if (!doc.exists) return; final d = doc.data()!; final days = List<int>.from(d['workDays'] ?? []);
    setState(() { _wd = List.generate(7, (i) => days.contains(i + 1)); _sh = d['startHour'] ?? 8; _eh = d['endHour'] ?? 18; });
  }

  Future<void> _saveConfig() async {
    setState(() => _sav = true);
    final a = <int>[for (var i = 0; i < 7; i++) if (_wd[i]) i + 1];
    await _fs.collection('config').doc('workSchedule').set({'workDays': a, 'startHour': _sh, 'endHour': _eh}, SetOptions(merge: true));
    setState(() => _sav = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
  }

  Future<void> _generate() async {
    setState(() => _gen = true);
    final a = <int>[for (var i = 0; i < 7; i++) if (_wd[i]) i + 1]; final now = DateTime.now(); final b = _fs.batch();
    for (var d = 0; d < _wk * 7; d++) { final dt = now.add(Duration(days: d)); if (!a.contains(dt.weekday)) continue;
      final ds = DateFormat('yyyy-MM-dd').format(dt); final sl = <String>[for (var h = _sh; h < _eh; h++) '${h.toString().padLeft(2, '0')}:00 - ${(h + 1).toString().padLeft(2, '0')}:00'];
      b.set(_fs.collection('schedule').doc(ds), {'date': ds, 'slots': sl}, SetOptions(merge: true)); }
    await b.commit(); setState(() => _gen = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Disponibilidad generada para $_wk semanas')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 32, 20, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Horarios', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8, fontSize: 26)).animate().fadeIn(duration: 350.ms).moveY(begin: -8, end: 0, duration: 350.ms),
      const SizedBox(height: 28),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4), width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Días Laborales', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.2)),
          const SizedBox(height: 14),
          Row(children: List.generate(7, (i) { final on = _wd[i];
            return Expanded(child: GestureDetector(onTap: () => setState(() => _wd[i] = !on), child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: EdgeInsets.only(right: i < 6 ? 6 : 0), padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: on ? AdminTheme.primaryColor.withValues(alpha: 0.12) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: on ? AdminTheme.primaryColor : theme.dividerColor.withValues(alpha: 0.5), width: on ? 1.5 : 0.5)),
              child: Center(child: Text(_dl[i], style: TextStyle(color: on ? AdminTheme.primaryColor : theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w600, fontSize: 12)))))); })),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hora Inicio', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, letterSpacing: 0.3)), const SizedBox(height: 8), buildHourDropdown(context, _sh, (v) => setState(() => _sh = v!))])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hora Fin', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, letterSpacing: 0.3)), const SizedBox(height: 8), buildHourDropdown(context, _eh, (v) => setState(() => _eh = v!))])),
          ]),
          const SizedBox(height: 18),
          AdminButton(text: 'Guardar Configuración', icon: Iconsax.tick_circle, isLoading: _sav, onPressed: _saveConfig),
        ]),
      ).animate().fadeIn(duration: 300.ms, delay: 80.ms),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4), width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Generar Disponibilidad', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.2)),
          const SizedBox(height: 14),
          Row(children: [2, 4, 6, 8].map((w) { final sel = _wk == w;
            return Expanded(child: GestureDetector(onTap: () => setState(() => _wk = w), child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: EdgeInsets.only(right: w < 8 ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: sel ? AdminTheme.secondaryColor.withValues(alpha: 0.12) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? AdminTheme.secondaryColor : theme.dividerColor.withValues(alpha: 0.5), width: sel ? 1.5 : 0.5)),
              child: Center(child: Text('$w sem', style: TextStyle(color: sel ? AdminTheme.secondaryColor : theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w600, fontSize: 12)))))); }).toList()),
          const SizedBox(height: 18),
          AdminButton(text: 'Generar Disponibilidad', icon: Iconsax.calendar_add, isLoading: _gen, color: AdminTheme.secondaryColor, onPressed: _generate),
        ]),
      ).animate().fadeIn(duration: 300.ms, delay: 140.ms),
      const SizedBox(height: 28),
      Text('Fechas Programadas', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 16, color: theme.textTheme.bodyLarge?.color, letterSpacing: -0.3)).animate().fadeIn(duration: 300.ms, delay: 200.ms),
      const SizedBox(height: 14),
      StreamBuilder<QuerySnapshot>(stream: _fs.collection('schedule').orderBy('date').snapshots(), builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4), width: 0.5)), child: Center(child: Text('Sin fechas programadas', style: theme.textTheme.bodySmall)));
        return Column(children: docs.asMap().entries.map((e) { final d = e.value.data() as Map<String, dynamic>; final ds = d['date'] as String? ?? ''; final sl = List<String>.from(d['slots'] ?? [])..sort();
          return GestureDetector(onTap: () => showEditDateSheet(context, _fs, e.value.id, sl), child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4), width: 0.5)),
            child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AdminTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(11)), child: const Icon(Iconsax.calendar_1, color: AdminTheme.primaryColor, size: 18)),
              const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(formatDateLabel(ds), style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14)), const SizedBox(height: 3), Text('${sl.length} horarios', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12))])),
              Icon(Iconsax.arrow_right_3, size: 16, color: theme.textTheme.bodySmall?.color)])).animate().fadeIn(duration: 250.ms, delay: (200 + e.key * 30).ms)); }).toList());
      }),
    ]))));
  }
}
