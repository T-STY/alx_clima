import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text('Clientes',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            ).animate().fadeIn(duration: 400.ms),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre...',
                  prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                  filled: true,
                  fillColor: AdminTheme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AdminTheme.dividerColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AdminTheme.dividerColor)),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var docs = snapshot.data!.docs;
                  if (_search.isNotEmpty) {
                    docs = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      return name.contains(_search);
                    }).toList();
                  }
                  if (docs.isEmpty) {
                    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Iconsax.people, size: 48, color: AdminTheme.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('Sin clientes', style: Theme.of(context).textTheme.bodyMedium),
                    ]));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final uid = docs[i].id;
                      DateTime? memberSince;
                      if (data['memberSince'] is Timestamp) {
                        memberSince = (data['memberSince'] as Timestamp).toDate();
                      }
                      return GestureDetector(
                        onTap: () => _showClientDetail(context, uid, data),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AdminTheme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AdminTheme.dividerColor),
                          ),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AdminTheme.primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Iconsax.user, size: 18, color: AdminTheme.primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(data['name'] ?? 'Sin nombre', style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                              Text(data['phone'] ?? '', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
                            ])),
                            if (memberSince != null)
                              Text('Desde ${memberSince.year}', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
                            const SizedBox(width: 8),
                            const Icon(Iconsax.arrow_right_3, size: 16, color: AdminTheme.textSecondary),
                          ]),
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: (i * 40).ms);
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

  void _showClientDetail(BuildContext context, String uid, Map<String, dynamic> data) async {
    final equipSnap = await _firestore.collection('users').doc(uid).collection('equipment').get();
    final historySnap = await _firestore.collection('users').doc(uid).collection('serviceHistory').get();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: AdminTheme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AdminTheme.dividerColor, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(data['name'] ?? 'Sin nombre', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _row(Iconsax.call, data['phone'] ?? ''),
          if ((data['email'] ?? '').isNotEmpty) _row(Iconsax.sms, data['email']),
          const Divider(height: 20, color: AdminTheme.dividerColor),
          Row(children: [
            _statBadge('${equipSnap.docs.length}', 'Equipos', AdminTheme.primaryColor),
            const SizedBox(width: 12),
            _statBadge('${historySnap.docs.length}', 'Servicios', AdminTheme.successColor),
          ]),
          const SizedBox(height: 12),
          if (equipSnap.docs.isNotEmpty) ...[
            Text('Equipos', style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            ...equipSnap.docs.map((doc) {
              final eq = doc.data();
              return Container(
                margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AdminTheme.surfaceColor, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Iconsax.cpu_setting, size: 14, color: AdminTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${eq['brand']} ${eq['equipmentName']}', style: TextStyle(color: AdminTheme.textPrimary, fontSize: 13))),
                  Text('${eq['btuCapacity']} BTU', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 11)),
                ]),
              );
            }),
          ],
        ]),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, size: 14, color: AdminTheme.textSecondary),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(color: AdminTheme.textPrimary, fontSize: 13)),
    ]),
  );

  Widget _statBadge(String value, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 18)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: color, fontSize: 12)),
    ]),
  );
}
