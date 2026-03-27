import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text('Clientes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ).animate().fadeIn(duration: 400.ms),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre...',
                  prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var docs = snapshot.data!.docs;
                  if (_search.isNotEmpty) {
                    docs = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return (data['name'] ?? '').toString().toLowerCase().contains(_search);
                    }).toList();
                  }
                  if (docs.isEmpty) {
                    return Center(child: Text('Sin clientes', style: Theme.of(context).textTheme.bodyMedium));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final uid = docs[i].id;
                      final isSuspended = data['suspended'] == true;
                      return GestureDetector(
                        onTap: () => _showClientDetail(context, uid, data),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isSuspended ? AdminTheme.errorColor.withValues(alpha: 0.4) : Theme.of(context).dividerColor),
                          ),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: isSuspended ? AdminTheme.errorColor.withValues(alpha: 0.15) : AdminTheme.primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Iconsax.user, size: 18, color: isSuspended ? AdminTheme.errorColor : AdminTheme.primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(data['name'] ?? 'Sin nombre', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                                if (isSuspended)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AdminTheme.errorColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                    child: Text('Suspendido', style: TextStyle(color: AdminTheme.errorColor, fontSize: 10, fontWeight: FontWeight.w600)),
                                  ),
                              ]),
                              const SizedBox(height: 2),
                              Text(data['phone'] ?? '', style: Theme.of(context).textTheme.bodySmall),
                            ])),
                            const Icon(Iconsax.arrow_right_3, size: 16),
                          ]),
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: (i * 30).ms);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClientDetail(BuildContext context, String uid, Map<String, dynamic> data) {
    final isSuspended = data['suspended'] == true;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (ctx, scrollCtrl) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    Text(data['name'] ?? 'Sin nombre', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _infoRow(ctx, Iconsax.call, data['phone'] ?? ''),
                    if ((data['email'] ?? '').isNotEmpty) _infoRow(ctx, Iconsax.sms, data['email']),
                    Divider(height: 24, color: Theme.of(ctx).dividerColor),
                    Row(children: [
                      Expanded(
                        child: AdminButton(
                          text: isSuspended ? 'Reactivar' : 'Suspender',
                          icon: isSuspended ? Iconsax.tick_circle : Iconsax.slash,
                          color: isSuspended ? AdminTheme.successColor : AdminTheme.errorColor,
                          isOutlined: true,
                          onPressed: () async {
                            await _firestore.collection('users').doc(uid).update({'suspended': !isSuspended});
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          },
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Text('Equipos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showAddEquipment(ctx, uid),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Iconsax.add_circle, size: 16, color: AdminTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text('Agregar', style: TextStyle(color: AdminTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('users').doc(uid).collection('equipment').snapshots(),
                      builder: (ctx, snap) {
                        if (!snap.hasData) return const SizedBox();
                        final eqDocs = snap.data!.docs;
                        if (eqDocs.isEmpty) return Text('Sin equipos registrados', style: Theme.of(ctx).textTheme.bodySmall);
                        return Column(children: eqDocs.map((eqDoc) {
                          final eq = eqDoc.data() as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.surface, borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              const Icon(Iconsax.cpu_setting, size: 14, color: AdminTheme.primaryColor),
                              const SizedBox(width: 8),
                              Expanded(child: Text('${eq['brand']} ${eq['equipmentName']}', style: TextStyle(fontSize: 13))),
                              Text('${eq['btuCapacity']} BTU', style: TextStyle(fontSize: 11, color: Theme.of(ctx).textTheme.bodySmall?.color)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => eqDoc.reference.delete(),
                                child: const Icon(Iconsax.trash, size: 14, color: AdminTheme.errorColor),
                              ),
                            ]),
                          );
                        }).toList());
                      },
                    ),
                  ],
                ),
              );
            },
          );
        });
      },
    );
  }

  Widget _infoRow(BuildContext ctx, IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, size: 14, color: Theme.of(ctx).textTheme.bodySmall?.color),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(fontSize: 13)),
    ]),
  );

  void _showAddEquipment(BuildContext context, String uid) {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final btuCtrl = TextEditingController(text: '12000');
    final locCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Equipo'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Marca')),
          const SizedBox(height: 8),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre / Modelo')),
          const SizedBox(height: 8),
          TextField(controller: btuCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'BTU')),
          const SizedBox(height: 8),
          TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Ubicación')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(onPressed: () async {
            await _firestore.collection('users').doc(uid).collection('equipment').add({
              'equipmentName': nameCtrl.text.trim(),
              'brand': brandCtrl.text.trim(),
              'type': 'miniSplit',
              'btuCapacity': int.tryParse(btuCtrl.text) ?? 12000,
              'installDate': FieldValue.serverTimestamp(),
              'nextServiceDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 180))),
              'installationType': 'fullPackage',
              'location': locCtrl.text.trim(),
              'isUserAdded': false,
              'warrantyDetails': '',
            });
            if (ctx.mounted) Navigator.of(ctx).pop();
          }, child: const Text('Agregar')),
        ],
      ),
    );
  }
}
