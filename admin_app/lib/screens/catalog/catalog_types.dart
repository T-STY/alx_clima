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
    final theme = Theme.of(context); final tc = TextEditingController();
    return StreamBuilder<DocumentSnapshot>(stream: firestore.collection('config').doc('equipmentTypes').snapshots(), builder: (context, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      final data = snap.data?.data() as Map<String, dynamic>? ?? {}; final types = List<String>.from(data['types'] ?? []);
      return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4), width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (types.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: types.map((t) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5), width: 0.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Text(t, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)), const SizedBox(width: 6),
              GestureDetector(onTap: () { final u = List<String>.from(types)..remove(t); firestore.collection('config').doc('equipmentTypes').set({'types': u}); },
                child: Icon(Iconsax.close_circle, size: 16, color: AdminTheme.errorColor.withValues(alpha: 0.7)))]))).toList()),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: TextField(controller: tc, decoration: const InputDecoration(hintText: 'Nuevo tipo de equipo'))), const SizedBox(width: 10),
            GestureDetector(onTap: () { if (tc.text.trim().isEmpty) return; final u = List<String>.from(types)..add(tc.text.trim()); firestore.collection('config').doc('equipmentTypes').set({'types': u}); tc.clear(); },
              child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AdminTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: const Icon(Iconsax.add_circle, color: AdminTheme.primaryColor, size: 22)))]),
        ]),
      ).animate().fadeIn(duration: 300.ms, delay: 280.ms);
    });
  }
}
