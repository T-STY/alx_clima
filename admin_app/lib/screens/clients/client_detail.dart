import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:alx_clima_admin/config/theme.dart';

void showClientDetail(
  BuildContext context,
  FirebaseFirestore firestore,
  DocumentSnapshot doc,
) {
  final data = doc.data() as Map<String, dynamic>;
  final suspended = data['suspended'] == true;
  final theme = Theme.of(context);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scroll) {
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.all(24),
            children: [
              _sectionLabel('DETALLE DEL CLIENTE', theme),
              const SizedBox(height: 16),
              _infoRow('Nombre', data['name'] ?? '', theme),
              _infoRow('Email', data['email'] ?? '', theme),
              _infoRow('Teléfono', data['phone'] ?? '', theme),
              _infoRow('Dirección', data['address'] ?? '', theme),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: suspended ? AdminTheme.errorColor : AdminTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    suspended ? 'Suspendido' : 'Activo',
                    style: TextStyle(fontSize: 13, color: suspended ? AdminTheme.errorColor : AdminTheme.successColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  firestore.collection('users').doc(doc.id).update({'suspended': !suspended});
                  Navigator.pop(ctx);
                },
                child: Text(
                  suspended ? 'Reactivar cuenta' : 'Suspender cuenta',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: suspended ? AdminTheme.successColor : AdminTheme.errorColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _sectionLabel('EQUIPOS', theme),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: firestore.collection('users').doc(doc.id).collection('equipment').snapshots(),
                builder: (context, snapshot) {
                  final eqDocs = snapshot.data?.docs ?? [];
                  if (eqDocs.isEmpty) {
                    return Text('Sin equipos registrados', style: theme.textTheme.bodyMedium);
                  }
                  return Column(
                    children: eqDocs.map((eq) {
                      final eqData = eq.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${eqData['brand'] ?? ''} ${eqData['name'] ?? ''} - ${eqData['btuCapacity'] ?? ''} BTU',
                                style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => firestore.collection('users').doc(doc.id).collection('equipment').doc(eq.id).delete(),
                              child: Text('Eliminar', style: TextStyle(fontSize: 12, color: AdminTheme.errorColor)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showAddEquipmentDialog(ctx, firestore, doc.id),
                child: Text(
                  'Agregar equipo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminTheme.secondaryColor),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _sectionLabel(String text, ThemeData theme) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 10, fontWeight: FontWeight.w600,
      letterSpacing: 1.5, color: theme.textTheme.bodySmall?.color,
    ),
  );
}

Widget _infoRow(String label, String value, ThemeData theme) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color)),
        ),
      ],
    ),
  );
}

void _showAddEquipmentDialog(BuildContext context, FirebaseFirestore firestore, String userId) {
  final nameCtrl = TextEditingController();
  final brandCtrl = TextEditingController();
  final btuCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final typeCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(
          'Agregar equipo',
          style: TextStyle(fontSize: 14, color: Theme.of(ctx).textTheme.bodyLarge?.color),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: brandCtrl, decoration: const InputDecoration(hintText: 'Marca')),
              const SizedBox(height: 8),
              TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Modelo')),
              const SizedBox(height: 8),
              TextField(controller: btuCtrl, decoration: const InputDecoration(hintText: 'BTU'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: typeCtrl, decoration: const InputDecoration(hintText: 'Tipo')),
              const SizedBox(height: 8),
              TextField(controller: locationCtrl, decoration: const InputDecoration(hintText: 'Ubicación')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color)),
          ),
          TextButton(
            onPressed: () {
              firestore.collection('users').doc(userId).collection('equipment').add({
                'name': nameCtrl.text,
                'brand': brandCtrl.text,
                'btuCapacity': int.tryParse(btuCtrl.text) ?? 0,
                'type': typeCtrl.text,
                'location': locationCtrl.text,
              });
              Navigator.pop(ctx);
            },
            child: Text('Guardar', style: TextStyle(color: AdminTheme.primaryColor)),
          ),
        ],
      );
    },
  );
}
