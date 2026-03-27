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
  final _fs = FirebaseFirestore.instance;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 32, 20, 0), child: Text('Clientes', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8, fontSize: 26))).animate().fadeIn(duration: 350.ms).moveY(begin: -8, end: 0, duration: 350.ms),
      Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 12), child: TextField(
        onChanged: (v) => setState(() => _search = v.toLowerCase()),
        decoration: InputDecoration(hintText: 'Buscar por nombre...', prefixIcon: Icon(Iconsax.search_normal, size: 18, color: theme.textTheme.bodySmall?.color), filled: true, fillColor: theme.cardColor),
      )),
      Expanded(child: StreamBuilder<QuerySnapshot>(stream: _fs.collection('users').snapshots(), builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        var docs = snap.data!.docs;
        if (_search.isNotEmpty) docs = docs.where((d) => ((d.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase().contains(_search)).toList();
        if (docs.isEmpty) return Center(child: Text('Sin clientes', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)));
        return ListView.separated(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), itemCount: docs.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (context, i) {
          final data = docs[i].data() as Map<String, dynamic>; final uid = docs[i].id; final sus = data['suspended'] == true;
          return _card(context, uid, data, sus, i);
        });
      })),
    ])));
  }

  Widget _card(BuildContext ctx, String uid, Map<String, dynamic> data, bool sus, int i) {
    final theme = Theme.of(ctx);
    return GestureDetector(onTap: () => showClientDetail(ctx, _fs, uid, data), child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: sus ? AdminTheme.errorColor.withValues(alpha: 0.25) : theme.dividerColor.withValues(alpha: 0.4), width: 0.5)),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: (sus ? AdminTheme.errorColor : AdminTheme.primaryColor).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Icon(Iconsax.user, size: 18, color: sus ? AdminTheme.errorColor : AdminTheme.primaryColor)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(data['name'] ?? 'Sin nombre', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14))),
            if (sus) Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: AdminTheme.errorColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 5, height: 5, decoration: const BoxDecoration(color: AdminTheme.errorColor, shape: BoxShape.circle)), const SizedBox(width: 4), Text('Suspendido', style: TextStyle(color: AdminTheme.errorColor, fontSize: 10, fontWeight: FontWeight.w600))])),
          ]),
          const SizedBox(height: 3), Text(data['phone'] ?? '', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
        ])),
        Icon(Iconsax.arrow_right_3, size: 16, color: theme.textTheme.bodySmall?.color),
      ]),
    )).animate().fadeIn(duration: 250.ms, delay: (i * 30).ms);
  }
}
