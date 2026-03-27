import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

export 'package:alx_clima_admin/screens/catalog/catalog_edit_sheet.dart';

void showAddCatalogSheet(BuildContext context, FirebaseFirestore firestore) {
  String? selectedBrand;
  String? selectedModel;
  String? selectedBtu;
  final priceCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final warrantyCtrl = TextEditingController(text: '5 años en compresor, 1 año en partes y accesorios.');
  final btuOptions = ['12K', '18K', '24K', '36K'];
  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheetState) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Agregar al Catálogo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection('equipmentCatalog').orderBy('order').snapshots(),
                  builder: (ctx, snapshot) {
                    final brands = snapshot.data?.docs ?? [];
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _dropdownField<String>(
                        context: ctx,
                        label: 'Marca',
                        value: selectedBrand,
                        items: brands.map((b) {
                          final name = (b.data() as Map<String, dynamic>)['name'] as String? ?? b.id;
                          return DropdownMenuItem(value: b.id, child: Text(name));
                        }).toList(),
                        onChanged: (v) => setSheetState(() { selectedBrand = v; selectedModel = null; }),
                      ),
                      const SizedBox(height: 12),
                      if (selectedBrand != null) Builder(builder: (_) {
                        final brandDoc = brands.where((b) => b.id == selectedBrand).firstOrNull;
                        final models = brandDoc != null ? List<String>.from((brandDoc.data() as Map<String, dynamic>)['models'] ?? []) : <String>[];
                        return Column(children: [
                          _dropdownField<String>(context: ctx, label: 'Modelo', value: selectedModel, items: models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v) => setSheetState(() => selectedModel = v)),
                          const SizedBox(height: 12),
                        ]);
                      }),
                    ]);
                  },
                ),
                Text('BTU', style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: btuOptions.map((btu) {
                  final sel = selectedBtu == btu;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedBtu = btu),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AdminTheme.primaryColor.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: sel ? AdminTheme.primaryColor : theme.dividerColor),
                      ),
                      child: Text(btu, style: TextStyle(color: sel ? AdminTheme.primaryColor : theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w500)),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 12),
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$ ')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Descripción (opcional)')),
                const SizedBox(height: 12),
                TextField(controller: warrantyCtrl, decoration: const InputDecoration(labelText: 'Garantía')),
                const SizedBox(height: 20),
                AdminButton(
                  text: 'Agregar',
                  icon: Iconsax.add_circle,
                  isLoading: isSaving,
                  onPressed: () async {
                    if (selectedBrand == null || selectedModel == null || selectedBtu == null || priceCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Completa los campos requeridos')));
                      return;
                    }
                    setSheetState(() => isSaving = true);
                    await firestore.collection('quoteCatalog').add({
                      'brand': selectedBrand,
                      'name': selectedModel,
                      'btuCapacity': selectedBtu,
                      'price': int.tryParse(priceCtrl.text) ?? 0,
                      'description': descCtrl.text,
                      'manufacturerWarrantyDetails': warrantyCtrl.text,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    setSheetState(() => isSaving = false);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}

Widget _dropdownField<T>({
  required BuildContext context,
  required String label,
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
}) {
  final theme = Theme.of(context);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: theme.textTheme.bodySmall),
    const SizedBox(height: 6),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.dividerColor)),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: theme.cardColor,
        hint: Text('Seleccionar $label', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14)),
        items: items,
        onChanged: onChanged,
      ),
    ),
  ]);
}
