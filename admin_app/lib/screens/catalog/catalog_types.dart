import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';

class CatalogTypesSection extends StatelessWidget {
  final FirebaseFirestore firestore;
  const CatalogTypesSection({super.key, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeController = TextEditingController();

    return StreamBuilder<DocumentSnapshot>(
      stream: firestore.collection('config').doc('equipmentTypes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final types = List<String>.from(data['types'] ?? []);

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: types.map((t) {
                  return Chip(
                    label: Text(t, style: const TextStyle(fontSize: 13)),
                    deleteIcon: const Icon(
                      Iconsax.close_circle,
                      size: 16,
                      color: AdminTheme.errorColor,
                    ),
                    onDeleted: () {
                      final updated = List<String>.from(types)..remove(t);
                      firestore
                          .collection('config')
                          .doc('equipmentTypes')
                          .set({'types': updated});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: typeController,
                      decoration: const InputDecoration(
                        hintText: 'Nuevo tipo de equipo',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (typeController.text.trim().isEmpty) return;
                      final updated = List<String>.from(types)
                        ..add(typeController.text.trim());
                      firestore
                          .collection('config')
                          .doc('equipmentTypes')
                          .set({'types': updated});
                      typeController.clear();
                    },
                    icon: const Icon(
                      Iconsax.add_circle,
                      color: AdminTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: 280.ms);
      },
    );
  }
}
