import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';
import 'catalog_helpers.dart';
import 'catalog_brands.dart';
import 'catalog_types.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Catálogo',
                style: GoogleFonts.exo2(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionHeader(context, 'Equipos en venta'),
            const SizedBox(height: 8),
            _EquipmentList(),
            const SizedBox(height: 24),
            _sectionHeader(context, 'Marcas y modelos'),
            const SizedBox(height: 8),
            const CatalogBrandsSection(),
            const SizedBox(height: 24),
            _sectionHeader(context, 'Tipos de equipo'),
            const SizedBox(height: 8),
            const CatalogTypesSection(),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: GoogleFonts.exo2(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _EquipmentList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quoteCatalog')
          .orderBy('brand')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ...List.generate(docs.length, (i) {
                final data = docs[i].data() as Map<String, dynamic>;
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
                      title: Text(
                        '${data['brand'] ?? ''} ${data['name'] ?? ''}',
                        style: GoogleFonts.exo2(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${data['btuCapacity'] ?? ''} BTU · \$${data['price'] ?? 0}',
                        style: GoogleFonts.exo2(
                          fontSize: 12,
                          color: AdminTheme.secondaryColor,
                        ),
                      ),
                      trailing: const Icon(
                        Iconsax.edit_2,
                        size: 18,
                        color: AdminTheme.primaryColor,
                      ),
                      onTap: () => showEditCatalogSheet(context, docs[i]),
                    ),
                  ],
                );
              })
                  .animate(interval: 50.ms)
                  .fadeIn(duration: 200.ms),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () => showAddCatalogSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
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
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Agregar equipo',
                                style: GoogleFonts.exo2(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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
