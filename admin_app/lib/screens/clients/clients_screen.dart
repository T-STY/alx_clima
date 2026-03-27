import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/screens/clients/client_detail_sheet.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Text(
                'Clientes',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre...',
                  prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var docs = snapshot.data!.docs;
                  if (_search.isNotEmpty) {
                    docs = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return (data['name'] ?? '').toString().toLowerCase().contains(_search);
                    }).toList();
                  }
                  if (docs.isEmpty) {
                    return Center(child: Text('Sin clientes', style: theme.textTheme.bodyMedium));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final uid = docs[i].id;
                      final isSuspended = data['suspended'] == true;
                      return _buildClientCard(context, uid, data, isSuspended, i);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(
    BuildContext context,
    String uid,
    Map<String, dynamic> data,
    bool isSuspended,
    int index,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => showClientDetail(context, _firestore, uid, data),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSuspended
                ? AdminTheme.errorColor.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSuspended
                    ? AdminTheme.errorColor.withValues(alpha: 0.1)
                    : AdminTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Iconsax.user,
                size: 18,
                color: isSuspended ? AdminTheme.errorColor : AdminTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['name'] ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      if (isSuspended)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminTheme.errorColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Suspendido',
                            style: TextStyle(
                              color: AdminTheme.errorColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(data['phone'] ?? '', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 16, color: theme.textTheme.bodySmall?.color),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms, delay: (index * 30).ms);
  }
}
