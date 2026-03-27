import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

void showEditBrandSheet(BuildContext context, DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>; final models = List<String>.from(data['models'] ?? []); final mc = TextEditingController(); bool saving = false;
  showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) {
    return StatefulBuilder(builder: (ctx, ss) {
      final theme = Theme.of(ctx);
      return Padding(padding: EdgeInsets.fromLTRB(24, 14, 24, MediaQuery.of(ctx).viewInsets.bottom + 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 22), Text(data['name'] ?? doc.id, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 18),
        if (models.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: models.map((m) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5), width: 0.5)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Text(m, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)), const SizedBox(width: 6), GestureDetector(onTap: () => ss(() => models.remove(m)), child: Icon(Iconsax.close_circle, size: 16, color: AdminTheme.errorColor.withValues(alpha: 0.7)))]))).toList()),
        const SizedBox(height: 14),
        Row(children: [Expanded(child: TextField(controller: mc, decoration: const InputDecoration(hintText: 'Nuevo modelo'))), const SizedBox(width: 10),
          GestureDetector(onTap: () { if (mc.text.trim().isEmpty) return; ss(() { models.add(mc.text.trim()); mc.clear(); }); },
            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AdminTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: const Icon(Iconsax.add_circle, color: AdminTheme.primaryColor, size: 22)))]),
        const SizedBox(height: 18),
        AdminButton(text: 'Guardar', icon: Iconsax.tick_circle, isLoading: saving, onPressed: () async { ss(() => saving = true); await doc.reference.update({'models': models}); ss(() => saving = false); if (ctx.mounted) Navigator.pop(ctx); }),
      ]));
    });
  });
}
