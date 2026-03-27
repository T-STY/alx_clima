import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:alx_clima_admin/config/theme.dart';

void showAddBrandSheet(BuildContext context, FirebaseFirestore firestore) {
  _showBrandSheet(context, firestore, null);
}

void showEditBrandSheet(BuildContext context, FirebaseFirestore firestore, DocumentSnapshot doc) {
  _showBrandSheet(context, firestore, doc);
}

void _showBrandSheet(BuildContext context, FirebaseFirestore firestore, DocumentSnapshot? doc) {
  final data = doc != null ? doc.data() as Map<String, dynamic> : <String, dynamic>{};
  final nameCtrl = TextEditingController(text: data['name'] ?? '');
  final modelCtrl = TextEditingController();
  final models = List<String>.from(data['models'] ?? []);
  final isEdit = doc != null;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(ctx);
          return Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'EDITAR MARCA' : 'AGREGAR MARCA',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Nombre')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: modelCtrl, decoration: const InputDecoration(hintText: 'Modelo'))),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: GestureDetector(
                        onTap: () {
                          if (modelCtrl.text.isNotEmpty) { setModalState(() => models.add(modelCtrl.text)); modelCtrl.clear(); }
                        },
                        child: Text('Agregar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AdminTheme.secondaryColor)),
                      ),
                    ),
                  ],
                ),
                if (models.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: models.map((m) => Chip(
                      label: Text(m, style: const TextStyle(fontSize: 12)),
                      onDeleted: () => setModalState(() => models.remove(m)),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (nameCtrl.text.isEmpty) return;
                        if (isEdit) {
                          firestore.collection('equipmentCatalog').doc(doc!.id).update({'name': nameCtrl.text, 'models': models});
                        } else {
                          final count = (await firestore.collection('equipmentCatalog').get()).docs.length;
                          await firestore.collection('equipmentCatalog').add({'name': nameCtrl.text, 'models': models, 'order': count});
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text('Guardar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminTheme.primaryColor)),
                    ),
                    if (isEdit) ...[
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () { firestore.collection('equipmentCatalog').doc(doc!.id).delete(); Navigator.pop(ctx); },
                        child: Text('Eliminar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminTheme.errorColor)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class CatalogBrandsSection extends StatelessWidget {
  final FirebaseFirestore firestore;
  const CatalogBrandsSection({super.key, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('MARCAS Y MODELOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: theme.textTheme.bodySmall?.color)),
            ),
            SizedBox(
              width: 80,
              child: GestureDetector(
                onTap: () => showAddBrandSheet(context, firestore),
                child: Text('Agregar', textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AdminTheme.secondaryColor)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('equipmentCatalog').orderBy('order').snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return Text('Sin marcas', style: theme.textTheme.bodyMedium);
            return Container(
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  for (var i = 0; i < docs.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: theme.dividerColor),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showEditBrandSheet(context, firestore, docs[i]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                (docs[i].data() as Map<String, dynamic>)['name'] ?? '',
                                style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color),
                              ),
                            ),
                            Text(
                              '${List.from((docs[i].data() as Map<String, dynamic>)['models'] ?? []).length} modelos',
                              style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class CatalogTypesSection extends StatelessWidget {
  final FirebaseFirestore firestore;
  const CatalogTypesSection({super.key, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TIPOS DE EQUIPO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: theme.textTheme.bodySmall?.color)),
        const SizedBox(height: 12),
        StreamBuilder<DocumentSnapshot>(
          stream: firestore.doc('config/equipmentTypes').snapshots(),
          builder: (context, snapshot) {
            final types = List<String>.from(
              snapshot.data?.data() is Map ? (snapshot.data!.data() as Map<String, dynamic>)['types'] ?? [] : [],
            );
            return Container(
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: types.map((t) => GestureDetector(
                      onTap: () { firestore.doc('config/equipmentTypes').set({'types': List<String>.from(types)..remove(t)}); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color)),
                            const SizedBox(width: 6),
                            Icon(Icons.close, size: 14, color: AdminTheme.errorColor),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  _AddTypeRow(firestore: firestore, currentTypes: types),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AddTypeRow extends StatefulWidget {
  final FirebaseFirestore firestore;
  final List<String> currentTypes;
  const _AddTypeRow({required this.firestore, required this.currentTypes});

  @override
  State<_AddTypeRow> createState() => _AddTypeRowState();
}

class _AddTypeRowState extends State<_AddTypeRow> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Nuevo tipo', isDense: true))),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: GestureDetector(
            onTap: () {
              if (_ctrl.text.isEmpty) return;
              widget.firestore.doc('config/equipmentTypes').set({'types': [...widget.currentTypes, _ctrl.text]});
              _ctrl.clear();
            },
            child: Text('Agregar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AdminTheme.secondaryColor)),
          ),
        ),
      ],
    );
  }
}
