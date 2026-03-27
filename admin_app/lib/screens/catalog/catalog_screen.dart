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
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catálogo',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Equipos en Catálogo',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  AdminButton(
                    text: 'Agregar',
                    icon: Iconsax.add,
                    expand: false,
                    onPressed: () => showAddCatalogSheet(context, _firestore),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms, delay: 80.ms),
              const SizedBox(height: 12),
              _buildCatalogList(context),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Marcas y Modelos',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  AdminButton(
                    text: 'Nueva Marca',
                    icon: Iconsax.add,
                    isOutlined: true,
                    expand: false,
                    onPressed: () => showAddBrandSheet(context, _firestore),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms, delay: 160.ms),
              const SizedBox(height: 12),
              CatalogBrandsSection(firestore: _firestore),
              const SizedBox(height: 28),
              Text(
                'Tipos de Equipo',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 240.ms),
              const SizedBox(height: 12),
              CatalogTypesSection(firestore: _firestore),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogList(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('quoteCatalog')
          .orderBy('brand')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'Sin equipos en el catálogo',
                style: theme.textTheme.bodySmall,
              ),
            ),
          );
        }
        return Column(
          children: docs.asMap().entries.map((entry) {
            final data = entry.value.data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => showEditCatalogSheet(
                context,
                entry.value,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AdminTheme.secondaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Iconsax.cpu,
                        color: AdminTheme.secondaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data['brand']} ${data['name'] ?? data['model'] ?? ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${data['btuCapacity'] ?? data['btu'] ?? ''} BTU \u00b7 \$${data['price'] ?? 0}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Iconsax.edit_2,
                      size: 18,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ],
                ),
              ).animate().fadeIn(
                    duration: 250.ms,
                    delay: (80 + entry.key * 30).ms,
                  ),
            );
          }).toList(),
        );
      },
    );
  }
}
