import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/screens/clients/client_detail.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Clientes', style: theme.textTheme.headlineSmall),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(hintText: 'Buscar por nombre o email'),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'USUARIOS',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  letterSpacing: 1.5, color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  var docs = snapshot.data?.docs ?? [];
                  if (_query.isNotEmpty) {
                    docs = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      final email = (data['email'] ?? '').toString().toLowerCase();
                      return name.contains(_query) || email.contains(_query);
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return Center(child: Text('Sin usuarios', style: theme.textTheme.bodyMedium));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _tableHeader(theme);
                      final doc = docs[index - 1];
                      final data = doc.data() as Map<String, dynamic>;
                      final suspended = data['suspended'] == true;
                      final isLast = index == docs.length;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => showClientDetail(context, _firestore, doc),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: isLast
                                ? const BorderRadius.vertical(bottom: Radius.circular(12))
                                : null,
                          ),
                          child: Column(
                            children: [
                              Divider(height: 1, color: theme.dividerColor),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        data['name'] ?? 'Sin nombre',
                                        style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        data['email'] ?? '',
                                        style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: suspended ? AdminTheme.errorColor : AdminTheme.successColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
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

  Widget _tableHeader(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Nombre', style: _hStyle(theme))),
          Expanded(flex: 3, child: Text('Email', style: _hStyle(theme))),
          Expanded(flex: 1, child: Text('Estado', style: _hStyle(theme))),
        ],
      ),
    );
  }

  TextStyle _hStyle(ThemeData theme) {
    return TextStyle(
      fontSize: 10, fontWeight: FontWeight.w600,
      letterSpacing: 1.2, color: theme.textTheme.bodySmall?.color,
    );
  }
}
