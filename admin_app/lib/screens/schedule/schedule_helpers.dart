import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

Widget buildHourDropdown(BuildContext context, int value, ValueChanged<int?> onChanged) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(11), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5), width: 0.5)),
    child: DropdownButton<int>(value: value, isExpanded: true, underline: const SizedBox(), dropdownColor: theme.cardColor, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
      items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('${i.toString().padLeft(2, '0')}:00'))), onChanged: onChanged),
  );
}

String formatDateLabel(String dateStr) {
  try { final d = DateTime.parse(dateStr); final r = DateFormat('EEEE dd MMM yyyy', 'es').format(d); final p = r.split(' ');
    if (p.isNotEmpty) p[0] = '${p[0][0].toUpperCase()}${p[0].substring(1)}'; return p.join(' '); } catch (_) { return dateStr; }
}

void showEditDateSheet(BuildContext context, FirebaseFirestore fs, String dateId, List<String> currentSlots) {
  final slots = List<String>.from(currentSlots)..sort();
  showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) {
    return StatefulBuilder(builder: (ctx, ss) {
      final theme = Theme.of(ctx);
      return Padding(padding: EdgeInsets.fromLTRB(24, 14, 24, MediaQuery.of(ctx).viewInsets.bottom + 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 22),
        Text('Editar $dateId', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 18),
        Wrap(spacing: 8, runSpacing: 8, children: slots.map((s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5), width: 0.5)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Text(s, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)), const SizedBox(width: 6), GestureDetector(onTap: () => ss(() => slots.remove(s)), child: Icon(Iconsax.close_circle, size: 16, color: AdminTheme.errorColor.withValues(alpha: 0.7)))]),
        )).toList()),
        const SizedBox(height: 18),
        AdminButton(text: 'Agregar Horario', icon: Iconsax.add, isOutlined: true, onPressed: () async {
          final st = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 9, minute: 0)); if (st == null) return;
          final et = await showTimePicker(context: ctx, initialTime: TimeOfDay(hour: st.hour + 1, minute: 0)); if (et == null) return;
          final ns = '${st.hour.toString().padLeft(2, '0')}:${st.minute.toString().padLeft(2, '0')} - ${et.hour.toString().padLeft(2, '0')}:${et.minute.toString().padLeft(2, '0')}';
          ss(() { if (!slots.contains(ns)) { slots.add(ns); slots.sort(); } });
        }),
        const SizedBox(height: 12),
        AdminButton(text: 'Guardar', icon: Iconsax.tick_circle, onPressed: () async { await fs.collection('schedule').doc(dateId).update({'slots': slots}); if (ctx.mounted) Navigator.pop(ctx); }),
      ]));
    });
  });
}
