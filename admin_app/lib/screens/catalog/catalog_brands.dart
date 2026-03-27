import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

class CatalogBrandsSection extends StatelessWidget {
  final FirebaseFirestore firestore;
  const CatalogBrandsSection({super.key, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('equipmentCatalog').orderBy('order').snapshots(),
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
                'Sin marcas registradas',
                style: theme.textTheme.bodySmall,
              ),
            ),
          );
        }
        return Column(
          children: docs.asMap().entries.map((entry) {
            final data = entry.value.data() as Map<String, dynamic>;
            final models = List<String>.from(data['models'] ?? []);
            return GestureDetector(
              onTap: () => _showEditBrand(context, entry.value),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AdminTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Iconsax.building,
                            color: AdminTheme.primaryColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            data['name'] ?? entry.value.id,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(
                          Iconsax.arrow_right_3,
                          size: 18,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ],
                    ),
                    if (models.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: models.map((m) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              m,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(
                    duration: 250.ms,
                    delay: (160 + entry.key * 30).ms,
                  ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showEditBrand(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final models = List<String>.from(data['models'] ?? []);
    final modelController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme = Theme.of(ctx);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    data['name'] ?? doc.id,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: models.map((m) {
                      return Chip(
                        label: Text(m, style: const TextStyle(fontSize: 13)),
                        deleteIcon: const Icon(
                          Iconsax.close_circle,
                          size: 16,
                          color: AdminTheme.errorColor,
                        ),
                        onDeleted: () {
                          setSheetState(() => models.remove(m));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: modelController,
                          decoration: const InputDecoration(
                            hintText: 'Nuevo modelo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          if (modelController.text.trim().isEmpty) return;
                          setSheetState(() {
                            models.add(modelController.text.trim());
                            modelController.clear();
                          });
                        },
                        icon: const Icon(
                          Iconsax.add_circle,
                          color: AdminTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
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
          },
        );
      },
    );
  }
}

void showAddBrandSheet(BuildContext context, FirebaseFirestore firestore) {
  final nameController = TextEditingController();
  final modelController = TextEditingController();
  final orderController = TextEditingController();
  final models = <String>[];
  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(ctx);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Nueva Marca',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: orderController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Orden'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: models.map((m) {
                      return Chip(
                        label: Text(m, style: const TextStyle(fontSize: 13)),
                        deleteIcon: const Icon(
                          Iconsax.close_circle,
                          size: 16,
                          color: AdminTheme.errorColor,
                        ),
                        onDeleted: () {
                          setSheetState(() => models.remove(m));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: modelController,
                          decoration: const InputDecoration(
                            hintText: 'Agregar modelo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          if (modelController.text.trim().isEmpty) return;
                          setSheetState(() {
                            models.add(modelController.text.trim());
                            modelController.clear();
                          });
                        },
                        icon: const Icon(
                          Iconsax.add_circle,
                          color: AdminTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AdminButton(
                    text: 'Crear Marca',
                    icon: Iconsax.add_circle,
                    isLoading: isSaving,
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      setSheetState(() => isSaving = true);
                      await firestore.collection('equipmentCatalog').add({
                        'name': nameController.text.trim(),
                        'models': models,
                        'order': int.tryParse(orderController.text) ?? 0,
                      });
                      setSheetState(() => isSaving = false);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
