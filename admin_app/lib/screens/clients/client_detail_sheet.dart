import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

void showClientDetail(
  BuildContext context,
  FirebaseFirestore firestore,
  String uid,
  Map<String, dynamic> data,
) {
  final isSuspended = data['suspended'] == true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setS) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (ctx, scrollCtrl) {
              final theme = Theme.of(ctx);
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      data['name'] ?? 'Sin nombre',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow(ctx, Iconsax.call, data['phone'] ?? ''),
                    if ((data['email'] ?? '').isNotEmpty)
                      _infoRow(ctx, Iconsax.sms, data['email']),
                    Divider(height: 24, color: theme.dividerColor),
                    Row(
                      children: [
                        Expanded(
                          child: AdminButton(
                            text: isSuspended ? 'Reactivar' : 'Suspender',
                            icon: isSuspended ? Iconsax.tick_circle : Iconsax.slash,
                            color: isSuspended ? AdminTheme.successColor : AdminTheme.errorColor,
                            isOutlined: true,
                            onPressed: () async {
                              await firestore.collection('users').doc(uid).update({
                                'suspended': !isSuspended,
                              });
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Equipos',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showAddEquipment(ctx, firestore, uid),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.add_circle, size: 16, color: AdminTheme.primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                'Agregar',
                                style: TextStyle(
                                  color: AdminTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: firestore.collection('users').doc(uid).collection('equipment').snapshots(),
                      builder: (ctx, snap) {
                        if (!snap.hasData) return const SizedBox();
                        final eqDocs = snap.data!.docs;
                        if (eqDocs.isEmpty) {
                          return Text('Sin equipos registrados', style: theme.textTheme.bodySmall);
                        }
                        return Column(
                          children: eqDocs.map((eqDoc) {
                            final eq = eqDoc.data() as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Iconsax.cpu_setting, size: 14, color: AdminTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${eq['brand']} ${eq['equipmentName']}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    '${eq['btuCapacity']} BTU',
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => eqDoc.reference.delete(),
                                    child: const Icon(Iconsax.trash, size: 14, color: AdminTheme.errorColor),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget _infoRow(BuildContext ctx, IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(ctx).textTheme.bodySmall?.color),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );
}

void _showAddEquipment(BuildContext context, FirebaseFirestore firestore, String uid) {
  final nameCtrl = TextEditingController();
  final brandCtrl = TextEditingController();
  final btuCtrl = TextEditingController(text: '12000');
  final locCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Agregar Equipo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Marca')),
            const SizedBox(height: 8),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre / Modelo')),
            const SizedBox(height: 8),
            TextField(
              controller: btuCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'BTU'),
            ),
            const SizedBox(height: 8),
            TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Ubicación')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
        TextButton(
          onPressed: () async {
            await firestore.collection('users').doc(uid).collection('equipment').add({
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
          },
          child: const Text('Agregar'),
        ),
      ],
    ),
  );
}
