import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

void showClientDetail(BuildContext context, FirebaseFirestore fs, String uid, Map<String, dynamic> data) {
  final sus = data['suspended'] == true;
  showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) {
    return StatefulBuilder(builder: (ctx, setS) {
      return DraggableScrollableSheet(initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.4, expand: false, builder: (ctx, sc) {
        final theme = Theme.of(ctx);
        return Padding(padding: const EdgeInsets.fromLTRB(24, 14, 24, 24), child: ListView(controller: sc, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 22),
          Text(data['name'] ?? 'Sin nombre', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const SizedBox(height: 14),
          _ir(ctx, Iconsax.call, data['phone'] ?? ''),
          if ((data['email'] ?? '').isNotEmpty) _ir(ctx, Iconsax.sms, data['email']),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5))),
          Row(children: [Expanded(child: AdminButton(text: sus ? 'Reactivar' : 'Suspender', icon: sus ? Iconsax.tick_circle : Iconsax.slash, color: sus ? AdminTheme.successColor : AdminTheme.errorColor, isOutlined: true,
            onPressed: () async { await fs.collection('users').doc(uid).update({'suspended': !sus}); if (ctx.mounted) Navigator.of(ctx).pop(); }))]),
          const SizedBox(height: 20),
          Row(children: [
            Text('Equipos', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2)),
            const Spacer(),
            GestureDetector(onTap: () => _addEq(ctx, fs, uid), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AdminTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Iconsax.add_circle, size: 14, color: AdminTheme.primaryColor), const SizedBox(width: 5), Text('Agregar', style: TextStyle(color: AdminTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600))]))),
          ]),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(stream: fs.collection('users').doc(uid).collection('equipment').snapshots(), builder: (ctx, snap) {
            if (!snap.hasData) return const SizedBox();
            final docs = snap.data!.docs;
            if (docs.isEmpty) return Text('Sin equipos registrados', style: theme.textTheme.bodySmall);
            return Column(children: docs.map((d) { final eq = d.data() as Map<String, dynamic>;
              return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4), width: 0.5)),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AdminTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)), child: const Icon(Iconsax.cpu_setting, size: 14, color: AdminTheme.primaryColor)),
                  const SizedBox(width: 10), Expanded(child: Text('${eq['brand']} ${eq['equipmentName']}', style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13))),
                  Text('${eq['btuCapacity']} BTU', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)), const SizedBox(width: 10),
                  GestureDetector(onTap: () => d.reference.delete(), child: Icon(Iconsax.trash, size: 14, color: AdminTheme.errorColor.withValues(alpha: 0.7))),
                ]));
            }).toList());
          }),
        ]));
      });
    });
  });
}

Widget _ir(BuildContext ctx, IconData ic, String t) {
  final theme = Theme.of(ctx);
  return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
    Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)), child: Icon(ic, size: 14, color: theme.textTheme.bodySmall?.color)),
    const SizedBox(width: 10), Text(t, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13)),
  ]));
}

void _addEq(BuildContext context, FirebaseFirestore fs, String uid) {
  final nc = TextEditingController(); final bc = TextEditingController(); final btc = TextEditingController(text: '12000'); final lc = TextEditingController();
  showDialog(context: context, builder: (ctx) {
    final theme = Theme.of(ctx);
    return AlertDialog(
      title: Text('Agregar Equipo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: bc, decoration: const InputDecoration(labelText: 'Marca')), const SizedBox(height: 10),
        TextField(controller: nc, decoration: const InputDecoration(labelText: 'Nombre / Modelo')), const SizedBox(height: 10),
        TextField(controller: btc, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'BTU')), const SizedBox(height: 10),
        TextField(controller: lc, decoration: const InputDecoration(labelText: 'Ubicación')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
        TextButton(onPressed: () async {
          await fs.collection('users').doc(uid).collection('equipment').add({'equipmentName': nc.text.trim(), 'brand': bc.text.trim(), 'type': 'miniSplit', 'btuCapacity': int.tryParse(btc.text) ?? 12000, 'installDate': FieldValue.serverTimestamp(), 'nextServiceDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 180))), 'installationType': 'fullPackage', 'location': lc.text.trim(), 'isUserAdded': false, 'warrantyDetails': ''});
          if (ctx.mounted) Navigator.of(ctx).pop();
        }, child: const Text('Agregar')),
      ],
    );
  });
}
