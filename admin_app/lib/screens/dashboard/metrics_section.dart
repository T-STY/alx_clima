import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';

class MetricsSection extends StatelessWidget {
  const MetricsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('invoices').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final metrics = _computeMetrics(docs);

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('config')
              .doc('metricsTargets')
              .snapshots(),
          builder: (context, targetSnap) {
            final targetData = targetSnap.data?.data() as Map<String, dynamic>? ?? {};
            final monthlyTarget = (targetData['monthly'] as num?)?.toDouble() ?? 50000;
            final yearlyTarget = (targetData['yearly'] as num?)?.toDouble() ?? 500000;

        return GlassCard(
          tintColor: AdminTheme.successColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.chart_2,
                    size: 18,
                    color: AdminTheme.successColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ingresos',
                    style: GoogleFonts.exo2(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MetricRow(
                label: 'Hoy',
                amount: metrics.today,
                color: AdminTheme.primaryColor,
              ),
              _MetricRow(
                label: 'Esta semana',
                amount: metrics.week,
                color: AdminTheme.secondaryColor,
              ),
              _MetricRow(
                label: 'Este mes',
                amount: metrics.month,
                color: AdminTheme.accentColor,
              ),
              _MetricRow(
                label: 'Este trimestre',
                amount: metrics.quarter,
                color: AdminTheme.warningColor,
              ),
              _MetricRow(
                label: 'Este año',
                amount: metrics.year,
                color: AdminTheme.successColor,
              ),
              const SizedBox(height: 16),
              _TargetBar(
                label: 'Meta mensual',
                current: metrics.month,
                target: monthlyTarget,
                color: AdminTheme.accentColor,
              ),
              const SizedBox(height: 8),
              _TargetBar(
                label: 'Meta anual',
                current: metrics.year,
                target: yearlyTarget,
                color: AdminTheme.successColor,
              ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  _Metrics _computeMetrics(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
    final quarterStart = DateTime(now.year, quarterMonth, 1);
    final yearStart = DateTime(now.year, 1, 1);

    double today = 0;
    double week = 0;
    double month = 0;
    double quarter = 0;
    double year = 0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final total = (data['total'] as num?)?.toDouble() ?? 0;
      final dateStr = data['date'] as String? ?? '';

      DateTime? date;
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {
        continue;
      }

      if (dateStr == todayStr) today += total;
      if (!date.isBefore(weekStart)) week += total;
      if (!date.isBefore(monthStart)) month += total;
      if (!date.isBefore(quarterStart)) quarter += total;
      if (!date.isBefore(yearStart)) year += total;
    }

    return _Metrics(
      today: today,
      week: week,
      month: month,
      quarter: quarter,
      year: year,
    );
  }
}

class _Metrics {
  final double today;
  final double week;
  final double month;
  final double quarter;
  final double year;

  const _Metrics({
    required this.today,
    required this.week,
    required this.month,
    required this.quarter,
    required this.year,
  });
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.exo2(fontSize: 13),
            ),
          ),
          Text(
            '\$${_formatAmount(amount)}',
            style: GoogleFonts.exo2(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double val) {
    if (val >= 1000) {
      return NumberFormat('#,##0.00', 'es_MX').format(val);
    }
    return val.toStringAsFixed(2);
  }
}

class _TargetBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;

  const _TargetBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).toStringAsFixed(0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.exo2(fontSize: 11),
              ),
            ),
            Text(
              '$pct%',
              style: GoogleFonts.exo2(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.6)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
