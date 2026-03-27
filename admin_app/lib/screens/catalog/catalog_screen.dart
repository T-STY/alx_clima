import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/screens/catalog/catalog_helpers.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestore = FirebaseFirestore.instance;
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Row(
              children: [
                Expanded(child: Text('Catálogo', style: theme.textTheme.headlineSmall)),
                SizedBox(
                  width: 100,
                  child: GestureDetector(
                    onTap: () => showAddCatalogSheet(context, firestore),
                    child: Text(
                      'Agregar',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminTheme.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionLabel(text: 'EQUIPOS EN CATÁLOGO'),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('quoteCatalog').snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Sin equipos', style: theme.textTheme.bodyMedium),
                  );
                }

                return Container(
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text('Equipo', style: _headerStyle(theme))),
                            Expanded(flex: 2, child: Text('BTU', style: _headerStyle(theme))),
                            Expanded(flex: 2, child: Text('Precio', style: _headerStyle(theme))),
                          ],
                        ),
                      ),
                      for (var i = 0; i < docs.length; i++) ...[
                        Divider(height: 1, color: theme.dividerColor),
                        _CatalogRow(
                          doc: docs[i],
                          currencyFormat: currencyFormat,
                          onTap: () => showEditCatalogSheet(context, firestore, docs[i]),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            CatalogBrandsSection(firestore: firestore),
            const SizedBox(height: 32),
            CatalogTypesSection(firestore: firestore),
          ],
        ),
      ),
    );
  }

  TextStyle _headerStyle(ThemeData theme) {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      color: theme.textTheme.bodySmall?.color,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
    );
  }
}

class _CatalogRow extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const _CatalogRow({
    required this.doc,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = doc.data() as Map<String, dynamic>;
    final price = (data['price'] ?? 0).toDouble();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                '${data['brand'] ?? ''} ${data['name'] ?? ''}'.trim(),
                style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${data['btuCapacity'] ?? ''}',
                style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                currencyFormat.format(price),
                style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
