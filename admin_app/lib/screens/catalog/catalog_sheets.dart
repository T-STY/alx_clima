import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

export 'package:alx_clima_admin/screens/catalog/catalog_edit_sheet.dart';

void showAddCatalogSheet(BuildContext context, FirebaseFirestore fs) {
  String? brand, model, btu; final pc = TextEditingController(); final dc = TextEditingController();
  final wc = TextEditingController(text: '5 años en compresor, 1 año en partes y accesorios.'); bool saving = false;
  showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) {
    return StatefulBuilder(builder: (ctx, ss) {
      final theme = Theme.of(ctx);
      return Padding(padding: EdgeInsets.fromLTRB(24, 14, 24, MediaQuery.of(ctx).viewInsets.bottom + 24), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 22),
        Text('Agregar al Catálogo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 22),
        StreamBuilder<QuerySnapshot>(stream: fs.collection('equipmentCatalog').orderBy('order').snapshots(), builder: (ctx, snap) {
          final brands = snap.data?.docs ?? [];
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _dd<String>(ctx, 'Marca', brand, brands.map((b) { final n = (b.data() as Map<String, dynamic>)['name'] as String? ?? b.id; return DropdownMenuItem(value: b.id, child: Text(n)); }).toList(), (v) => ss(() { brand = v; model = null; })),
            const SizedBox(height: 14),
            if (brand != null) Builder(builder: (_) {
              final bd = brands.where((b) => b.id == brand).firstOrNull;
              final ms = bd != null ? List<String>.from((bd.data() as Map<String, dynamic>)['models'] ?? []) : <String>[];
              return Column(children: [_dd<String>(ctx, 'Modelo', model, ms.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), (v) => ss(() => model = v)), const SizedBox(height: 14)]);
            }),
          ]);
        }),
        Text('BTU', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, letterSpacing: 0.3)), const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: ['12K', '18K', '24K', '36K'].map((b) { final sel = btu == b;
          return GestureDetector(onTap: () => ss(() => btu = b), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(color: sel ? AdminTheme.primaryColor.withValues(alpha: 0.12) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? AdminTheme.primaryColor : theme.dividerColor.withValues(alpha: 0.5), width: sel ? 1.5 : 0.5)),
            child: Text(b, style: TextStyle(color: sel ? AdminTheme.primaryColor : theme.textTheme.bodySmall?.color, fontWeight: FontWeight.w600)))); }).toList()),
        const SizedBox(height: 14),
        TextField(controller: pc, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$ ')),
        const SizedBox(height: 12), TextField(controller: dc, maxLines: 2, decoration: const InputDecoration(labelText: 'Descripción (opcional)')),
        const SizedBox(height: 12), TextField(controller: wc, decoration: const InputDecoration(labelText: 'Garantía')),
        const SizedBox(height: 22),
        AdminButton(text: 'Agregar', icon: Iconsax.add_circle, isLoading: saving, onPressed: () async {
          if (brand == null || model == null || btu == null || pc.text.isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Completa los campos requeridos'))); return; }
          ss(() => saving = true);
          await fs.collection('quoteCatalog').add({'brand': brand, 'name': model, 'btuCapacity': btu, 'price': int.tryParse(pc.text) ?? 0, 'description': dc.text, 'manufacturerWarrantyDetails': wc.text, 'createdAt': FieldValue.serverTimestamp()});
          ss(() => saving = false); if (ctx.mounted) Navigator.pop(ctx);
        }),
      ])));
    });
  });
}

Widget _dd<T>(BuildContext ctx, String label, T? val, List<DropdownMenuItem<T>> items, ValueChanged<T?> cb) {
  final theme = Theme.of(ctx);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, letterSpacing: 0.3)), const SizedBox(height: 8),
    Container(padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(11), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5), width: 0.5)),
      child: DropdownButton<T>(value: val, isExpanded: true, underline: const SizedBox(), dropdownColor: theme.cardColor, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14), hint: Text('Seleccionar $label', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14)), items: items, onChanged: cb)),
  ]);
}
