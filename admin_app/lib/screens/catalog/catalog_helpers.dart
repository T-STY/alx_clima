import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alx_clima_admin/widgets/sheet_widgets.dart';

void showAddCatalogSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  String? selectedBrand;
  String? selectedModel;
  int? selectedBtu;
  final priceCtrl = TextEditingController();
  final warrantyCtrl = TextEditingController(
    text: 'Garantía de fábrica de 5 años en compresor',
  );
  final descCtrl = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) {
        return frostedSheet(
          ctx,
          isDark,
          'Agregar equipo',
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('equipmentCatalog')
                .orderBy('order')
                .snapshots(),
            builder: (ctx, snap) {
              final brands = snap.data?.docs ?? [];
              final brandNames =
                  brands.map((b) => b['name'] as String).toList();
              final models = <String>[];
              if (selectedBrand != null) {
                final match = brands.where(
                  (b) => b['name'] == selectedBrand,
                );
                if (match.isNotEmpty) {
                  models.addAll(
                    (match.first['models'] as List).cast<String>(),
                  );
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  sheetDropdown(
                    'Marca',
                    selectedBrand,
                    brandNames,
                    (v) => setSt(() {
                      selectedBrand = v;
                      selectedModel = null;
                    }),
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  sheetDropdown(
                    'Modelo',
                    selectedModel,
                    models,
                    (v) => setSt(() => selectedModel = v),
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  sheetDropdown<int>(
                    'BTU',
                    selectedBtu,
                    const [12000, 18000, 24000, 36000],
                    (v) => setSt(() => selectedBtu = v),
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  sheetInput(priceCtrl, 'Precio', isDark,
                      keyboard: TextInputType.number),
                  const SizedBox(height: 12),
                  sheetInput(warrantyCtrl, 'Garantía', isDark),
                  const SizedBox(height: 12),
                  sheetInput(descCtrl, 'Descripción (opcional)', isDark),
                  const SizedBox(height: 20),
                  sheetGradientButton('Guardar', () async {
                    if (selectedBrand == null ||
                        selectedModel == null ||
                        selectedBtu == null) return;
                    await FirebaseFirestore.instance
                        .collection('quoteCatalog')
                        .add({
                      'brand': selectedBrand,
                      'name': selectedModel,
                      'btuCapacity': selectedBtu,
                      'price': double.tryParse(priceCtrl.text) ?? 0,
                      'manufacturerWarrantyDetails': warrantyCtrl.text,
                      'description': descCtrl.text,
                      'type': 'miniSplit',
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  }),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}

void showEditCatalogSheet(BuildContext context, DocumentSnapshot doc) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final data = doc.data() as Map<String, dynamic>;
  final priceCtrl =
      TextEditingController(text: '${data['price'] ?? ''}');
  final warrantyCtrl = TextEditingController(
    text: data['manufacturerWarrantyDetails'] ?? '',
  );
  final descCtrl =
      TextEditingController(text: data['description'] ?? '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => frostedSheet(
      ctx,
      isDark,
      'Editar ${data['brand']} ${data['name']}',
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          sheetInput(priceCtrl, 'Precio', isDark,
              keyboard: TextInputType.number),
          const SizedBox(height: 12),
          sheetInput(warrantyCtrl, 'Garantía', isDark),
          const SizedBox(height: 12),
          sheetInput(descCtrl, 'Descripción', isDark),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: sheetGlassButton(ctx, isDark, 'Eliminar', () async {
                  await doc.reference.delete();
                  if (ctx.mounted) Navigator.pop(ctx);
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: sheetGradientButton('Guardar', () async {
                  await doc.reference.update({
                    'price': double.tryParse(priceCtrl.text) ?? 0,
                    'manufacturerWarrantyDetails': warrantyCtrl.text,
                    'description': descCtrl.text,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                }),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
