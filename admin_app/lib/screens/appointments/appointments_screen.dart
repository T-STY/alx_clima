import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/screens/appointments/appointment_detail_sheet.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _filter = 'all';
  static const _opts = {'all': 'Todas', 'pending': 'Pendientes', 'confirmed': 'Confirmadas', 'completed': 'Completadas', 'cancelled': 'Canceladas'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 32, 20, 0), child: Row(children: [
        Expanded(child: Text('Citas', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8, fontSize: 26))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(11), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5), width: 0.5)),
          child: DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: _filter, icon: Icon(Iconsax.arrow_down_1, size: 14, color: theme.textTheme.bodySmall?.color), dropdownColor: theme.cardColor, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            items: _opts.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _filter = v ?? 'all'),
          )),
        ),
      ])).animate().fadeIn(duration: 300.ms).moveY(begin: -6, end: 0, duration: 300.ms),
      const SizedBox(height: 18),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('appointments').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          var docs = snapshot.data!.docs;
          if (_filter != 'all') docs = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == _filter).toList();
          if (docs.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Iconsax.calendar, size: 44, color: theme.textTheme.bodySmall?.color), const SizedBox(height: 14), Text('Sin citas', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))]));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), itemCount: docs.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _card(context, data, docs[i].reference).animate().fadeIn(duration: 250.ms, delay: (i * 30).ms);
            },
          );
        },
      )),
    ])));
  }

  Widget _card(BuildContext context, Map<String, dynamic> data, DocumentReference ref) {
    final theme = Theme.of(context);
    final cust = data['customer'] as Map<String, dynamic>? ?? {};
    final eq = parseEquipment(data['equipment']);
    final status = data['status'] ?? 'pending';
    final info = statusInfo(status);
    return GestureDetector(onTap: () => showAppointmentDetail(context, data), child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4), width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 3, height: 38, decoration: BoxDecoration(color: info.$1, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cust['name'] ?? 'Sin nombre', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 3),
            Text('${data['date']} \u00b7 ${data['timeSlotDisplay'] ?? ''}', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: info.$1.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 5, height: 5, decoration: BoxDecoration(color: info.$1, shape: BoxShape.circle)), const SizedBox(width: 5), Text(info.$2, style: TextStyle(color: info.$1, fontSize: 11, fontWeight: FontWeight.w600))])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Icon(Iconsax.setting_2, size: 12, color: theme.textTheme.bodySmall?.color), const SizedBox(width: 5),
          Text(data['serviceTypeDisplay'] ?? '', style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)), const SizedBox(width: 14),
          Icon(Iconsax.cpu_setting, size: 12, color: theme.textTheme.bodySmall?.color), const SizedBox(width: 5),
          Expanded(child: Text(equipmentSummary(eq), style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color), overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 12),
        _actions(context, status, data, ref),
      ]),
    ));
  }

  Widget _actions(BuildContext ctx, String s, Map<String, dynamic> d, DocumentReference r) {
    return Row(children: [
      if (s == 'pending') ...[
        Expanded(child: _btn('Confirmar', AdminTheme.successColor, Iconsax.tick_circle, () => r.update({'status': 'confirmed'}))), const SizedBox(width: 8),
        Expanded(child: _btn('Reagendar', AdminTheme.primaryColor, Iconsax.calendar_edit, () => rescheduleAppointment(ctx, _firestore, d, r))), const SizedBox(width: 8),
      ],
      if (s == 'confirmed') ...[Expanded(child: _btn('Completar', AdminTheme.primaryColor, Iconsax.tick_square, () => completeAppointment(_firestore, d, r))), const SizedBox(width: 8)],
      if (s != 'cancelled' && s != 'completed') Expanded(child: _btn('Cancelar', AdminTheme.errorColor, Iconsax.close_circle, () => cancelAppointment(_firestore, d, r))),
      if (s == 'cancelled' || s == 'completed') Expanded(child: _btn('Eliminar', Colors.grey, Iconsax.trash, () => r.delete())),
    ]);
  }

  Widget _btn(String l, Color c, IconData ic, VoidCallback tap) {
    return GestureDetector(onTap: tap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(9)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(ic, size: 13, color: c), const SizedBox(width: 5), Text(l, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600))]),
    ));
  }
}
