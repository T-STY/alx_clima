import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _formatToday() {
    final raw = DateFormat('EEEE dd \'de\' MMMM, yyyy', 'es').format(DateTime.now());
    final parts = raw.split(' ');
    if (parts.length >= 4) { parts[0] = _cap(parts[0]); parts[3] = _cap(parts[3]); }
    return parts.join(' ');
  }

  (Color, String) _statusInfo(String s) => switch (s) {
    'confirmed' => (AdminTheme.successColor, 'Confirmada'),
    'cancelled' => (AdminTheme.errorColor, 'Cancelada'),
    'completed' => (AdminTheme.accentColor, 'Completada'),
    'modified' => (AdminTheme.primaryColor, 'Modificada'),
    _ => (AdminTheme.warningColor, 'Pendiente'),
  };

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final theme = Theme.of(context);
    return Scaffold(body: SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Panel de Control', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8, fontSize: 26)).animate().fadeIn(duration: 350.ms).moveY(begin: -8, end: 0, duration: 350.ms),
        const SizedBox(height: 6),
        Text(_formatToday(), style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, letterSpacing: 0.2)),
        const SizedBox(height: 28),
        StreamBuilder<QuerySnapshot>(
          stream: fs.collection('appointments').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            int tc = 0, pe = 0, co = 0, cm = 0;
            for (final d in docs) { final m = d.data() as Map<String, dynamic>; final st = m['status'] ?? 'pending';
              if (m['date'] == today && st != 'cancelled') tc++; if (st == 'pending') pe++; if (st == 'confirmed') co++; if (st == 'completed') cm++; }
            return Column(children: [
              Row(children: [Expanded(child: StatCard(icon: Iconsax.calendar_tick, value: '$tc', label: 'Hoy', color: AdminTheme.primaryColor)), const SizedBox(width: 12), Expanded(child: StatCard(icon: Iconsax.clock, value: '$pe', label: 'Pendientes', color: AdminTheme.warningColor))]),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: StatCard(icon: Iconsax.tick_circle, value: '$co', label: 'Confirmadas', color: AdminTheme.successColor)), const SizedBox(width: 12), Expanded(child: StatCard(icon: Iconsax.tick_square, value: '$cm', label: 'Completadas', color: AdminTheme.accentColor))]),
            ]).animate().fadeIn(duration: 350.ms, delay: 100.ms);
          },
        ),
        const SizedBox(height: 32),
        Row(children: [
          Expanded(child: Text('Citas Recientes', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 16, color: theme.textTheme.bodyLarge?.color, letterSpacing: -0.3))),
          GestureDetector(onTap: () => context.go('/appointments'), child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AdminTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: Text('Ver todas', style: TextStyle(color: AdminTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
          )),
        ]).animate().fadeIn(duration: 300.ms, delay: 200.ms),
        const SizedBox(height: 14),
        StreamBuilder<QuerySnapshot>(
          stream: fs.collection('appointments').orderBy('createdAt', descending: true).limit(5).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
            final docs = snap.data!.docs;
            if (docs.isEmpty) return Container(width: double.infinity, padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5), width: 0.5)), child: Center(child: Text('Sin citas registradas', style: theme.textTheme.bodySmall)));
            return Container(
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5), width: 0.5)),
              child: Column(children: docs.asMap().entries.map((entry) {
                final data = entry.value.data() as Map<String, dynamic>;
                final cust = data['customer'] as Map<String, dynamic>? ?? {};
                final info = _statusInfo(data['status'] ?? 'pending');
                final last = entry.key == docs.length - 1;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4), width: 0.5))),
                  child: Row(children: [
                    Container(width: 3, height: 36, decoration: BoxDecoration(color: info.$1, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(cust['name'] ?? 'Sin nombre', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 3),
                      Text('${data['date']} \u00b7 ${data['timeSlotDisplay'] ?? ''}', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: info.$1.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 5, height: 5, decoration: BoxDecoration(color: info.$1, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(info.$2, style: TextStyle(color: info.$1, fontSize: 10, fontWeight: FontWeight.w600)),
                    ])),
                  ]),
                ).animate().fadeIn(duration: 250.ms, delay: (150 + entry.key * 50).ms);
              }).toList()),
            );
          },
        ),
      ]),
    )));
  }
}
