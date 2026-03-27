import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

void showEditCatalogSheet(BuildContext context, DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final priceCtrl = TextEditingController(text: '${data['price'] ?? ''}');
  final descCtrl = TextEditingController(text: data['description'] ?? '');
  final warrantyCtrl = TextEditingController(
    text: data['manufacturerWarrantyDetails'] ?? data['warranty'] ?? '',
  );
  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(ctx);
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(
                  '${data['brand']} ${data['name'] ?? data['model'] ?? ''}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$ '),
                ),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Descripción')),
                const SizedBox(height: 12),
                TextField(controller: warrantyCtrl, decoration: const InputDecoration(labelText: 'Garantía')),
                const SizedBox(height: 20),
                AdminButton(
                  text: 'Guardar',
                  icon: Iconsax.tick_circle,
                  isLoading: isSaving,
                  onPressed: () async {
                    setSheetState(() => isSaving = true);
                    await doc.reference.update({
                      'price': int.tryParse(priceCtrl.text) ?? 0,
                      'description': descCtrl.text,
                      'manufacturerWarrantyDetails': warrantyCtrl.text,
                    });
                    setSheetState(() => isSaving = false);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                AdminButton(
                  text: 'Eliminar',
                  icon: Iconsax.trash,
                  color: AdminTheme.errorColor,
                  isOutlined: true,
                  onPressed: () async {
                    await doc.reference.delete();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
