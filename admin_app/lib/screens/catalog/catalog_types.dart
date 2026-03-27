import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';

class CatalogTypesSection extends StatelessWidget {
  const CatalogTypesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeCtrl = TextEditingController();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('config')
          .doc('equipmentTypes')
          .snapshots(),
      builder: (context, snapshot) {
        final types = (snapshot.data?.data()
                as Map<String, dynamic>?)?['types'] as List? ??
            [];

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: types.map<Widget>((t) {
                  return Chip(
                    label: Text(
                      t.toString(),
                      style: GoogleFonts.exo2(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Iconsax.close_circle, size: 16),
                    onDeleted: () async {
                      final updated = List.from(types)..remove(t);
                      await FirebaseFirestore.instance
                          .collection('config')
                          .doc('equipmentTypes')
                          .set({'types': updated});
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
                    child: TextField(
                      controller: typeCtrl,
                      style: GoogleFonts.exo2(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Nuevo tipo',
                        hintStyle: GoogleFonts.exo2(fontSize: 13),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      if (typeCtrl.text.trim().isEmpty) return;
                      final updated = [...types, typeCtrl.text.trim()];
                      await FirebaseFirestore.instance
                          .collection('config')
                          .doc('equipmentTypes')
                          .set({'types': updated});
                      typeCtrl.clear();
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
    );
  }
}
