import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:alx_clima_admin/config/theme.dart';

export 'package:alx_clima_admin/screens/catalog/catalog_brands.dart';

void showAddCatalogSheet(BuildContext context, FirebaseFirestore firestore) {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final warrantyCtrl = TextEditingController();
  String? selectedBrand;
  String? selectedModel;
  int? selectedBtu;
  String? selectedType;
  List<String> brands = [];
  Map<String, List<String>> brandModels = {};
  List<String> types = [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          if (brands.isEmpty) {
            firestore.collection('equipmentCatalog').orderBy('order').get().then((snap) {
              final b = <String>[];
              final m = <String, List<String>>{};
              for (final doc in snap.docs) {
                final d = doc.data();
                b.add(d['name'] as String? ?? '');
                m[d['name'] as String? ?? ''] = List<String>.from(d['models'] ?? []);
              }
              setModalState(() { brands = b; brandModels = m; });
            });
            firestore.doc('config/equipmentTypes').get().then((snap) {
              if (snap.exists) setModalState(() => types = List<String>.from(snap.data()?['types'] ?? []));
            });
          }
          final theme = Theme.of(ctx);
          return Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('AGREGAR EQUIPO', theme),
                  const SizedBox(height: 16),
                  _drop<String>(selectedBrand, 'Marca', theme, brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(), (v) => setModalState(() { selectedBrand = v; selectedModel = null; })),
                  const SizedBox(height: 8),
                  if (selectedBrand != null)
                    _drop<String>(selectedModel, 'Modelo', theme, (brandModels[selectedBrand] ?? []).map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), (v) => setModalState(() { selectedModel = v; nameCtrl.text = v ?? ''; })),
                  const SizedBox(height: 8),
                  _drop<String>(selectedType, 'Tipo', theme, types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), (v) => setModalState(() => selectedType = v)),
                  const SizedBox(height: 8),
                  _drop<int>(selectedBtu, 'Capacidad BTU', theme, [12000, 18000, 24000, 36000, 48000, 60000].map((b) => DropdownMenuItem(value: b, child: Text('$b BTU'))).toList(), (v) => setModalState(() => selectedBtu = v)),
                  const SizedBox(height: 8),
                  TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Precio')),
                  const SizedBox(height: 8),
                  TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Descripción'), maxLines: 2),
                  const SizedBox(height: 8),
                  TextField(controller: warrantyCtrl, decoration: const InputDecoration(hintText: 'Garantía del fabricante')),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      if (selectedBrand == null || selectedBtu == null) return;
                      firestore.collection('quoteCatalog').add({
                        'name': nameCtrl.text.isNotEmpty ? nameCtrl.text : selectedModel ?? '',
                        'brand': selectedBrand, 'type': selectedType ?? '', 'btuCapacity': selectedBtu,
                        'price': double.tryParse(priceCtrl.text) ?? 0,
                        'description': descCtrl.text, 'manufacturerWarrantyDetails': warrantyCtrl.text,
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text('Guardar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminTheme.primaryColor)),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void showEditCatalogSheet(BuildContext context, FirebaseFirestore firestore, DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final priceCtrl = TextEditingController(text: '${data['price'] ?? ''}');
  final descCtrl = TextEditingController(text: data['description'] ?? '');
  final warrantyCtrl = TextEditingController(text: data['manufacturerWarrantyDetails'] ?? '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('EDITAR EQUIPO', theme),
            const SizedBox(height: 8),
            Text('${data['brand'] ?? ''} ${data['name'] ?? ''}'.trim(), style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 16),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Precio')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Descripción'), maxLines: 2),
            const SizedBox(height: 8),
            TextField(controller: warrantyCtrl, decoration: const InputDecoration(hintText: 'Garantía')),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    firestore.collection('quoteCatalog').doc(doc.id).update({
                      'price': double.tryParse(priceCtrl.text) ?? 0,
                      'description': descCtrl.text, 'manufacturerWarrantyDetails': warrantyCtrl.text,
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text('Guardar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminTheme.primaryColor)),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () { firestore.collection('quoteCatalog').doc(doc.id).delete(); Navigator.pop(ctx); },
                  child: Text('Eliminar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminTheme.errorColor)),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _label(String text, ThemeData theme) {
  return Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: theme.textTheme.bodySmall?.color));
}

Widget _drop<T>(T? value, String hint, ThemeData theme, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
  return DropdownButton<T>(
    value: value,
    hint: Text(hint, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
    dropdownColor: theme.cardColor,
    isExpanded: true,
    items: items,
    onChanged: onChanged,
  );
}
