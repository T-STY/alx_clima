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
            _EquipmentGrid(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: GestureDetector(
                onTap: () => showAddCatalogSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: AdminTheme.primaryGradient,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.add, size: 18, color: Colors.white),
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
            const SizedBox(height: 16),
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

class _EquipmentGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quoteCatalog')
          .orderBy('brand')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassCard(
              child: Center(
                child: Text(
                  'Sin equipos en catálogo',
                  style: GoogleFonts.exo2(fontSize: 14),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width - 40;
              final cardWidth = (screenWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(docs.length, (i) {
                  return SizedBox(
                    width: cardWidth,
                    child: _ProductCard(doc: docs[i])
                        .animate()
                        .fadeIn(duration: 250.ms, delay: (i * 50).ms)
                        .slideY(begin: 0.08, end: 0),
                  );
                }),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _ProductCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = data['brand'] ?? '';
    final name = data['name'] ?? '';
    final btu = data['btuCapacity'] ?? 0;
    final price = data['price'] ?? 0;
    final imageUrl = data['imageUrl'] as String? ?? '';

    return GestureDetector(
      onTap: () => showEditCatalogSheet(context, doc),
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _gradientFallback(isDark),
                      )
                    : _gradientFallback(isDark),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AdminTheme.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        brand,
                        style: GoogleFonts.exo2(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AdminTheme.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: GoogleFonts.exo2(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AdminTheme.secondaryColor
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$btu BTU',
                            style: GoogleFonts.exo2(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AdminTheme.secondaryColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$$price',
                          style: GoogleFonts.exo2(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientFallback(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AdminTheme.primaryColor.withValues(alpha: 0.15),
            AdminTheme.secondaryColor.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Iconsax.cpu_setting,
          size: 40,
          color: isDark
              ? AdminTheme.secondaryColor.withValues(alpha: 0.6)
              : AdminTheme.primaryColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
