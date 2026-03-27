import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/screens/appointments/appointment_actions.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String _filter = 'all';
  final _firestore = FirebaseFirestore.instance;

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
              child: Row(
                children: [
                  Expanded(
                    child: Text('Citas', style: theme.textTheme.headlineSmall),
                  ),
                  DropdownButton<String>(
                    value: _filter,
                    dropdownColor: theme.cardColor,
                    underline: const SizedBox.shrink(),
                    style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Todas')),
                      DropdownMenuItem(value: 'pending', child: Text('Pendientes')),
                      DropdownMenuItem(value: 'confirmed', child: Text('Confirmadas')),
                      DropdownMenuItem(value: 'completed', child: Text('Completadas')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Canceladas')),
                    ],
                    onChanged: (v) => setState(() => _filter = v ?? 'all'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionLabel(text: 'LISTADO DE CITAS'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _filter == 'all'
                    ? _firestore.collection('appointments').orderBy('createdAt', descending: true).snapshots()
                    : _firestore
                        .collection('appointments')
                        .where('status', isEqualTo: _filter)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Text('Sin citas', style: theme.textTheme.bodyMedium),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 3,
                                child: Text('Cliente', style: _headerStyle(theme)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Fecha', style: _headerStyle(theme)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Servicio', style: _headerStyle(theme)),
                              ),
                            ],
                          ),
                        );
                      }
                      final doc = docs[index - 1];
                      final data = doc.data() as Map<String, dynamic>;
                      final customer = data['customer'] as Map<String, dynamic>? ?? {};
                      final status = data['status'] as String? ?? 'pending';
                      final isLast = index == docs.length;

                      return GestureDetector(
                        onTap: () => showAppointmentDetail(context, _firestore, doc),
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
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: statusInfo(status).$1,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        customer['name'] ?? 'Sin nombre',
                                        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        data['date'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        data['serviceTypeDisplay'] ?? data['serviceType'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.textTheme.bodySmall?.color,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
