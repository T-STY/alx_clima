import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

void showEditBrandSheet(BuildContext context, DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final models = List<String>.from(data['models'] ?? []);
  final modelCtrl = TextEditingController();
  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheetState) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(data['name'] ?? doc.id, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: models.map((m) => Chip(
                label: Text(m, style: const TextStyle(fontSize: 13)),
                deleteIcon: const Icon(Iconsax.close_circle, size: 16, color: AdminTheme.errorColor),
                onDeleted: () => setSheetState(() => models.remove(m)),
              )).toList()),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: modelCtrl, decoration: const InputDecoration(hintText: 'Nuevo modelo'))),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (modelCtrl.text.trim().isEmpty) return;
                    setSheetState(() { models.add(modelCtrl.text.trim()); modelCtrl.clear(); });
                  },
                  icon: const Icon(Iconsax.add_circle, color: AdminTheme.primaryColor),
                ),
              ]),
              const SizedBox(height: 16),
              AdminButton(
                text: 'Guardar',
                icon: Iconsax.tick_circle,
                isLoading: isSaving,
                onPressed: () async {
                  setSheetState(() => isSaving = true);
                  await doc.reference.update({'models': models});
                  setSheetState(() => isSaving = false);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      });
    },
  );
}
