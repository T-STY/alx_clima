import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

List<Map<String, dynamic>> parseEquipment(dynamic f) {
  final r = <Map<String, dynamic>>[];
  if (f is List) { for (final e in f) { if (e is Map<String, dynamic>) r.add(e); } }
  else if (f is Map<String, dynamic>) r.add(f);
  return r;
}

String equipmentSummary(List<Map<String, dynamic>> eq) {
  if (eq.isEmpty) return '';
  final f = '${eq.first['brand']} ${eq.first['name']}';
  return eq.length > 1 ? '$f +${eq.length - 1}' : f;
}

(Color, String) statusInfo(String s) => switch (s) {
  'confirmed' => (AdminTheme.successColor, 'Confirmada'),
  'cancelled' => (AdminTheme.errorColor, 'Cancelada'),
  'completed' => (AdminTheme.accentColor, 'Completada'),
  'modified' => (AdminTheme.primaryColor, 'Modificada'),
  _ => (AdminTheme.warningColor, 'Pendiente'),
};

void showAppointmentDetail(BuildContext context, Map<String, dynamic> data) {
  final cust = data['customer'] as Map<String, dynamic>? ?? {};
  final allEq = parseEquipment(data['equipment']);
  final info = statusInfo(data['status'] ?? 'pending');
  showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) {
    final theme = Theme.of(ctx);
    return Padding(padding: const EdgeInsets.fromLTRB(24, 14, 24, 32), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 22),
      Row(children: [
        Expanded(child: Text('Detalle de Cita', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: info.$1.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: info.$1, shape: BoxShape.circle)), const SizedBox(width: 6), Text(info.$2, style: TextStyle(color: info.$1, fontSize: 12, fontWeight: FontWeight.w600))])),
      ]),
      const SizedBox(height: 20),
      _dr(ctx, Iconsax.user, cust['name'] ?? ''), _dr(ctx, Iconsax.call, cust['phone'] ?? ''),
      if ((cust['email'] ?? '').isNotEmpty) _dr(ctx, Iconsax.sms, cust['email']),
      if ((cust['address'] ?? '').isNotEmpty) _dr(ctx, Iconsax.home_2, cust['address']),
      Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5))),
      _dr(ctx, Iconsax.calendar_1, '${data['date']} \u00b7 ${data['timeSlotDisplay'] ?? ''}'),
      _dr(ctx, Iconsax.setting_2, data['serviceTypeDisplay'] ?? ''),
      if ((data['notes'] ?? '').isNotEmpty) _dr(ctx, Iconsax.note_text, data['notes']),
      Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5))),
      Text('Equipos (${allEq.length})', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2)),
      const SizedBox(height: 10),
      ...allEq.map((eq) => Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4), width: 0.5)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AdminTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)), child: const Icon(Iconsax.cpu_setting, size: 14, color: AdminTheme.primaryColor)),
          const SizedBox(width: 10),
          Expanded(child: Text('${eq['brand']} ${eq['name']} (${eq['btuCapacity']} BTU)', style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13))),
          if ((eq['location'] ?? '').isNotEmpty) Text(eq['location'], style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
        ]),
      )),
    ]));
  });
}

Widget _dr(BuildContext ctx, IconData ic, String t) {
  final theme = Theme.of(ctx);
  return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
    Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)), child: Icon(ic, size: 14, color: theme.textTheme.bodySmall?.color)),
    const SizedBox(width: 10),
    Expanded(child: Text(t, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13))),
  ]));
}

Future<void> cancelAppointment(FirebaseFirestore fs, Map<String, dynamic> data, DocumentReference ref) async {
  await ref.update({'status': 'cancelled'});
  final date = data['date'] as String?;
  final sf = data['timeSlots'];
  final restore = <String>[]; if (sf is List) restore.addAll(sf.cast<String>());
  if (date != null && restore.isNotEmpty) {
    final sr = fs.collection('schedule').doc(date); final sd = await sr.get();
    if (sd.exists) { final ex = (sd.data()?['slots'] as List?)?.cast<String>() ?? []; await sr.update({'slots': ({...ex, ...restore}.toList()..sort())}); }
    else { await sr.set({'slots': restore..sort()}); }
    for (final slot in restore) {
      final snp = await fs.collection('bookedSlots').where('date', isEqualTo: date).where('slot', isEqualTo: slot).limit(1).get();
      for (final d in snp.docs) await d.reference.delete();
    }
  }
}

Future<void> rescheduleAppointment(BuildContext context, FirebaseFirestore fs, Map<String, dynamic> data, DocumentReference ref) async {
  final sm = ScaffoldMessenger.of(context);
  final snap = await fs.collection('schedule').get();
  final avail = <String, List<String>>{};
  for (final doc in snap.docs) { final s = (doc.data()['slots'] as List?)?.cast<String>() ?? []; if (s.isNotEmpty) avail[doc.id] = [...s]..sort(); }
  if (avail.isEmpty) { sm.showSnackBar(SnackBar(content: const Text('No hay fechas disponibles para reagendar'), backgroundColor: AdminTheme.errorColor)); return; }
  if (!context.mounted) return;
  String? selDate; String? selSlot;
  await showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) {
    return StatefulBuilder(builder: (ctx, setS) {
      final theme = Theme.of(ctx); final sorted = avail.keys.toList()..sort();
      final slots = selDate != null ? (avail[selDate] ?? []) : <String>[];
      return Padding(padding: const EdgeInsets.fromLTRB(24, 14, 24, 32), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 22),
        Text('Reagendar Cita', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 6), Text('Selecciona nueva fecha y horario', style: theme.textTheme.bodySmall),
        const SizedBox(height: 20),
        Text('Fecha', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 10),
        SizedBox(height: 42, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: sorted.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) {
          final d = sorted[i]; final sel = selDate == d;
          return GestureDetector(onTap: () => setS(() { selDate = d; selSlot = null; }), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: sel ? AdminTheme.primaryColor : theme.cardColor, borderRadius: BorderRadius.circular(11), border: Border.all(color: sel ? AdminTheme.primaryColor : theme.dividerColor.withValues(alpha: 0.5), width: sel ? 1.5 : 0.5)),
            child: Text(d, style: TextStyle(color: sel ? Colors.white : null, fontWeight: FontWeight.w500, fontSize: 13))));
        })),
        if (selDate != null) ...[
          const SizedBox(height: 20), Text('Horario', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 14)), const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: slots.map((s) { final sel = selSlot == s;
            return GestureDetector(onTap: () => setS(() => selSlot = s), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: sel ? AdminTheme.primaryColor.withValues(alpha: 0.12) : theme.cardColor, borderRadius: BorderRadius.circular(11), border: Border.all(color: sel ? AdminTheme.primaryColor : theme.dividerColor.withValues(alpha: 0.5), width: sel ? 1.5 : 0.5)),
              child: Text(s, style: TextStyle(color: sel ? AdminTheme.primaryColor : null, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, fontSize: 13))));
          }).toList()),
        ],
        const SizedBox(height: 24),
        AdminButton(text: 'Confirmar Reagendación', icon: Iconsax.tick_circle, onPressed: (selDate != null && selSlot != null) ? () async {
          await cancelAppointment(fs, data, ref);
          final nd = Map<String, dynamic>.from(data)..['date'] = selDate..['timeSlots'] = [selSlot]..['timeSlotDisplay'] = selSlot..['status'] = 'confirmed'..['createdAt'] = FieldValue.serverTimestamp()..['adminNote'] = 'Reagendada por el técnico'; nd.remove('appointmentId'); nd['appointmentId'] = 'apt-${DateTime.now().millisecondsSinceEpoch}';
          await fs.collection('appointments').add(nd);
          final sr = fs.collection('schedule').doc(selDate); final sd = await sr.get();
          if (sd.exists) { final ex = (sd.data()?['slots'] as List?)?.cast<String>() ?? []; ex.remove(selSlot); if (ex.isEmpty) await sr.delete(); else await sr.update({'slots': ex}); }
          await fs.collection('bookedSlots').add({'date': selDate, 'slot': selSlot, 'userId': data['userId'], 'bookedAt': FieldValue.serverTimestamp()});
          final uid = data['userId'] as String?;
          if (uid != null) await fs.collection('users').doc(uid).collection('notifications').add({'type': 'reschedule', 'title': 'Cita Reagendada', 'message': 'Tu cita ha sido reagendada para el $selDate a las $selSlot.', 'createdAt': FieldValue.serverTimestamp(), 'read': false});
          if (ctx.mounted) Navigator.of(ctx).pop();
          sm.showSnackBar(SnackBar(content: const Text('Cita reagendada exitosamente'), backgroundColor: AdminTheme.successColor));
        } : null),
      ]));
    });
  });
}

Future<void> completeAppointment(FirebaseFirestore fs, Map<String, dynamic> data, DocumentReference ref) async {
  final eqs = parseEquipment(data['equipment']); await ref.update({'status': 'completed'});
  final uid = data['userId'] as String?; if (uid == null) return;
  for (final eq in eqs) await fs.collection('users').doc(uid).collection('serviceHistory').add({'equipmentId': eq['id'] ?? '', 'serviceDate': FieldValue.serverTimestamp(), 'serviceType': data['serviceType'] ?? 'maintenance', 'description': '${data['serviceTypeDisplay'] ?? 'Servicio'} completado', 'technicianNotes': data['notes'] ?? '', 'cost': 0});
}
