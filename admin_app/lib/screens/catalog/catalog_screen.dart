import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';
import 'package:alx_clima_admin/screens/catalog/catalog_sheets.dart';
import 'package:alx_clima_admin/screens/catalog/catalog_brands.dart';
import 'package:alx_clima_admin/screens/catalog/catalog_types.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _fs = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 32, 20, 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Catálogo', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8, fontSize: 26)).animate().fadeIn(duration: 350.ms).moveY(begin: -8, end: 0, duration: 350.ms),
      const SizedBox(height: 28),
      Row(children: [
        Expanded(child: Text('Equipos en Catálogo', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 16, color: theme.textTheme.bodyLarge?.color, letterSpacing: -0.3))),
        AdminButton(text: 'Agregar', icon: Iconsax.add, expand: false, onPressed: () => showAddCatalogSheet(context, _fs)),
      ]).animate().fadeIn(duration: 300.ms, delay: 80.ms),
      const SizedBox(height: 14),
      _catalogList(context),
      const SizedBox(height: 32),
      Row(children: [
        Expanded(child: Text('Marcas y Modelos', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 16, color: theme.textTheme.bodyLarge?.color, letterSpacing: -0.3))),
        AdminButton(text: 'Nueva Marca', icon: Iconsax.add, isOutlined: true, expand: false, onPressed: () => showAddBrandSheet(context, _fs)),
      ]).animate().fadeIn(duration: 300.ms, delay: 160.ms),
      const SizedBox(height: 14),
      CatalogBrandsSection(firestore: _fs),
      const SizedBox(height: 32),
      Text('Tipos de Equipo', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 16, color: theme.textTheme.bodyLarge?.color, letterSpacing: -0.3)).animate().fadeIn(duration: 300.ms, delay: 240.ms),
      const SizedBox(height: 14),
      CatalogTypesSection(firestore: _fs),
    ]))));
  }

  Widget _catalogList(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(stream: _fs.collection('quoteCatalog').orderBy('brand').snapshots(), builder: (context, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      final docs = snap.data!.docs;
      if (docs.isEmpty) return Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4), width: 0.5)), child: Center(child: Text('Sin equipos en el catálogo', style: theme.textTheme.bodySmall)));
      return Column(children: docs.asMap().entries.map((e) {
        final d = e.value.data() as Map<String, dynamic>;
        return GestureDetector(onTap: () => showEditCatalogSheet(context, e.value), child: Container(
          margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4), width: 0.5)),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AdminTheme.secondaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(11)), child: const Icon(Iconsax.cpu, color: AdminTheme.secondaryColor, size: 18)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${d['brand']} ${d['name'] ?? d['model'] ?? ''}', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 3), Text('${d['btuCapacity'] ?? d['btu'] ?? ''} BTU \u00b7 \$${d['price'] ?? 0}', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
            ])),
            Icon(Iconsax.edit_2, size: 16, color: theme.textTheme.bodySmall?.color),
          ]),
        ).animate().fadeIn(duration: 250.ms, delay: (80 + e.key * 30).ms));
      }).toList());
    });
  }
}
