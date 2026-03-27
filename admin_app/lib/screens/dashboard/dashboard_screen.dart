import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:alx_clima_admin/config/theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestore = FirebaseFirestore.instance;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('appointments').snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final todayCount = docs.where((d) => d['date'] == today).length;
            final pendingCount = docs.where((d) => d['status'] == 'pending').length;
            final confirmedCount = docs.where((d) => d['status'] == 'confirmed').length;
            final completedCount = docs.where((d) => d['status'] == 'completed').length;

            final recent = List<QueryDocumentSnapshot>.from(docs)
              ..sort((a, b) {
                final aDate = a['createdAt'] as Timestamp?;
                final bDate = b['createdAt'] as Timestamp?;
                if (aDate == null || bDate == null) return 0;
                return bDate.compareTo(aDate);
              });
            final recentList = recent.take(8).toList();

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Text(
                  'Panel',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                _SectionLabel(text: 'RESUMEN'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatItem(value: '$todayCount', label: 'Hoy'),
                    _StatItem(value: '$pendingCount', label: 'Pendientes'),
                    _StatItem(value: '$confirmedCount', label: 'Confirmadas'),
                    _StatItem(value: '$completedCount', label: 'Completadas'),
                  ],
                ),
                const SizedBox(height: 32),
                _SectionLabel(text: 'CITAS RECIENTES'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: recentList.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'Sin citas registradas',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < recentList.length; i++) ...[
                              if (i > 0) Divider(height: 1, color: theme.dividerColor),
                              _AppointmentRow(doc: recentList[i]),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
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

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1,
              color: theme.textTheme.headlineSmall?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _AppointmentRow({required this.doc});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AdminTheme.primaryColor;
      case 'completed':
        return AdminTheme.successColor;
      case 'cancelled':
        return AdminTheme.errorColor;
      default:
        return AdminTheme.warningColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = doc.data() as Map<String, dynamic>;
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final status = data['status'] as String? ?? 'pending';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor(status),
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
              style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              data['serviceTypeDisplay'] ?? data['serviceType'] ?? '',
              style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
