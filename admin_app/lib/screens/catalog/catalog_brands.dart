import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';
import 'package:alx_clima_admin/screens/catalog/catalog_brand_sheets.dart';

class CatalogBrandsSection extends StatelessWidget {
  final FirebaseFirestore firestore;
  const CatalogBrandsSection({super.key, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(stream: firestore.collection('equipmentCatalog').orderBy('order').snapshots(), builder: (context, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      final docs = snap.data!.docs;
      if (docs.isEmpty) return Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4), width: 0.5)), child: Center(child: Text('Sin marcas registradas', style: theme.textTheme.bodySmall)));
      return Column(children: docs.asMap().entries.map((e) {
        final d = e.value.data() as Map<String, dynamic>; final ms = List<String>.from(d['models'] ?? []);
        return GestureDetector(onTap: () => showEditBrandSheet(context, e.value), child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4), width: 0.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: AdminTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: const Icon(Iconsax.building, color: AdminTheme.primaryColor, size: 16)),
              const SizedBox(width: 12), Expanded(child: Text(d['name'] ?? e.value.id, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14))), Icon(Iconsax.arrow_right_3, size: 16, color: theme.textTheme.bodySmall?.color)]),
            if (ms.isNotEmpty) ...[const SizedBox(height: 12), Wrap(spacing: 6, runSpacing: 6, children: ms.map((m) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3), width: 0.5)), child: Text(m, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)))).toList())],
          ]),
        ).animate().fadeIn(duration: 250.ms, delay: (160 + e.key * 30).ms));
      }).toList());
    });
  }
}

void showAddBrandSheet(BuildContext context, FirebaseFirestore fs) {
  final nc = TextEditingController(); final mc = TextEditingController(); final oc = TextEditingController(); final models = <String>[]; bool saving = false;
  showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) {
    return StatefulBuilder(builder: (ctx, ss) {
      final theme = Theme.of(ctx);
      return Padding(padding: EdgeInsets.fromLTRB(24, 14, 24, MediaQuery.of(ctx).viewInsets.bottom + 24), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 22), Text('Nueva Marca', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 22), TextField(controller: nc, decoration: const InputDecoration(labelText: 'Nombre')),
        const SizedBox(height: 12), TextField(controller: oc, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Orden')),
        const SizedBox(height: 14),
        if (models.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: models.map((m) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5), width: 0.5)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Text(m, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)), const SizedBox(width: 6), GestureDetector(onTap: () => ss(() => models.remove(m)), child: Icon(Iconsax.close_circle, size: 16, color: AdminTheme.errorColor.withValues(alpha: 0.7)))]))).toList()),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: TextField(controller: mc, decoration: const InputDecoration(hintText: 'Agregar modelo'))), const SizedBox(width: 10),
          GestureDetector(onTap: () { if (mc.text.trim().isEmpty) return; ss(() { models.add(mc.text.trim()); mc.clear(); }); },
            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AdminTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: const Icon(Iconsax.add_circle, color: AdminTheme.primaryColor, size: 22)))]),
        const SizedBox(height: 22),
        AdminButton(text: 'Crear Marca', icon: Iconsax.add_circle, isLoading: saving, onPressed: () async {
          if (nc.text.trim().isEmpty) return; ss(() => saving = true);
          await fs.collection('equipmentCatalog').add({'name': nc.text.trim(), 'models': models, 'order': int.tryParse(oc.text) ?? 0});
          ss(() => saving = false); if (ctx.mounted) Navigator.pop(ctx);
        }),
      ])));
    });
  });
}
