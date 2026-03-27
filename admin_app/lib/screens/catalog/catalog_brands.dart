import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';
import 'package:alx_clima_admin/widgets/sheet_widgets.dart';

class CatalogBrandsSection extends StatelessWidget {
  const CatalogBrandsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('equipmentCatalog')
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ...List.generate(docs.length, (i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final models =
                    (data['models'] as List?)?.cast<String>() ?? [];
                return Column(
                  children: [
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.1),
                      ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AdminTheme.accentColor.withValues(alpha: 0.2),
                              AdminTheme.accentColor.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Iconsax.building,
                          size: 16,
                          color: AdminTheme.accentColor,
                        ),
                      ),
                      title: Text(
                        data['name'] ?? '',
                        style: GoogleFonts.exo2(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${models.length} modelos',
                        style: GoogleFonts.exo2(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Iconsax.edit_2,
                        size: 18,
                        color: AdminTheme.primaryColor,
                      ),
                      onTap: () => _showEditBrandSheet(context, docs[i]),
                    ),
                  ],
                );
              }),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showAddBrandSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: AdminTheme.primaryGradient,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.add,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Agregar marca',
                              style: GoogleFonts.exo2(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _showAddBrandSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final nameCtrl = TextEditingController();
  final modelsCtrl = TextEditingController();
  final orderCtrl = TextEditingController(text: '10');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => frostedSheet(
      ctx,
      isDark,
      'Agregar marca',
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          sheetInput(nameCtrl, 'Nombre de la marca', isDark),
          const SizedBox(height: 12),
          sheetInput(modelsCtrl, 'Modelos (separados por coma)', isDark),
          const SizedBox(height: 12),
          sheetInput(orderCtrl, 'Orden', isDark,
              keyboard: TextInputType.number),
          const SizedBox(height: 20),
          sheetGradientButton('Guardar', () async {
            if (nameCtrl.text.trim().isEmpty) return;
            final models = modelsCtrl.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            await FirebaseFirestore.instance
                .collection('equipmentCatalog')
                .add({
              'name': nameCtrl.text.trim(),
              'models': models,
              'order': int.tryParse(orderCtrl.text) ?? 10,
            });
            if (ctx.mounted) Navigator.pop(ctx);
          }),
        ],
      ),
    ),
  );
}

void _showEditBrandSheet(BuildContext context, DocumentSnapshot doc) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final data = doc.data() as Map<String, dynamic>;
  final models = (data['models'] as List?)?.cast<String>() ?? [];
  final newModelCtrl = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) {
        return frostedSheet(
          ctx,
          isDark,
          data['name'] ?? 'Marca',
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: models.map<Widget>((m) {
                  return Chip(
                    label: Text(m, style: GoogleFonts.exo2(fontSize: 12)),
                    deleteIcon:
                        const Icon(Iconsax.close_circle, size: 16),
                    onDeleted: () async {
                      models.remove(m);
                      await doc.reference.update({'models': models});
                      setSt(() {});
                    },
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: sheetInput(
                      newModelCtrl,
                      'Agregar modelo',
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      if (newModelCtrl.text.trim().isEmpty) return;
                      models.add(newModelCtrl.text.trim());
                      await doc.reference.update({'models': models});
                      newModelCtrl.clear();
                      setSt(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AdminTheme.primaryGradient,
                      ),
                      child: const Icon(
                        Iconsax.add,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
