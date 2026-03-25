import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:alx_clima/config/constants.dart';
import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/data/care_tips.dart';
import 'package:alx_clima/providers/dashboard_provider.dart';
import 'package:alx_clima/widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<DashboardProvider>(
          builder: (context, dashboard, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  _buildWelcomeHeader(context)
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: -0.1, end: 0),

                  const SizedBox(height: 24),

                  if (dashboard.totalEquipment > 0) ...[
                    _buildQuickStats(context, dashboard)
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 100.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 24),
                  ],

                  _buildActionGrid(context, dashboard),

                  const SizedBox(height: 32),

                  SectionHeader(
                    title: 'Consejos de Mantenimiento',
                    trailingAction: 'Ver todos',
                    onTrailingTap: () => context.push('/tips'),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 400.ms),

                  const SizedBox(height: 12),

                  _buildTipsCarousel(context)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 500.ms)
                      .slideX(begin: 0.05, end: 0),

                  const SizedBox(height: 32),

                  _buildEmergencyButton(context)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 600.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Iconsax.wind,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido a ${AppConstants.appName}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'Tu solución en climatización',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, DashboardProvider dashboard) {
    final nextDate = dashboard.nextServiceDate;
    final nextDateStr = nextDate != null
        ? DateFormat('dd/MM/yyyy').format(nextDate)
        : 'Al día';

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Iconsax.cpu_setting,
            label: 'Equipos',
            value: '${dashboard.totalEquipment}',
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Iconsax.calendar_1,
            label: 'Próximo Servicio',
            value: nextDateStr,
            color: AppTheme.secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context, DashboardProvider dashboard) {
    final actions = [
      _ActionItem(
        icon: Iconsax.cpu_setting,
        title: 'Cotizar Equipo\n+ Instalación',
        gradient: const [AppTheme.primaryColor, Color(0xFF3B9FFF)],
        onTap: () => context.go('/quote'),
      ),
      _ActionItem(
        icon: Iconsax.setting_2,
        title: 'Solo\nInstalación',
        gradient: const [AppTheme.secondaryColor, Color(0xFF40E0FF)],
        onTap: () => context.go('/quote'),
      ),
      _ActionItem(
        icon: Iconsax.chart_21,
        title: 'Mi\nDashboard',
        gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
        badge: dashboard.totalEquipment > 0
            ? '${dashboard.totalEquipment}'
            : null,
        onTap: () => context.go('/dashboard'),
      ),
      _ActionItem(
        icon: Iconsax.calendar_1,
        title: 'Agendar\nServicio',
        gradient: const [AppTheme.successColor, Color(0xFF4ADE80)],
        onTap: () => context.push('/dashboard/schedule'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.15,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(context, action)
            .animate()
            .fadeIn(duration: 400.ms, delay: (200 + index * 100).ms)
            .slideY(begin: 0.15, end: 0);
      },
    );
  }

  Widget _buildActionCard(BuildContext context, _ActionItem action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: action.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: action.gradient.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action.icon, color: Colors.white, size: 24),
                ),
                Text(
                  action.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                ),
              ],
            ),
            if (action.badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    action.badge!,
                    style: TextStyle(
                      color: action.gradient.first,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCarousel(BuildContext context) {
    final tips = CareTips.items;
    final displayTips = tips.take(4).toList();

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayTips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final tip = displayTips[index];
          return Container(
            width: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  tip.icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(height: 10),
                Text(
                  tip.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    tip.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('tel:${AppConstants.technicianPhone}');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.errorColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Iconsax.call,
              color: AppTheme.errorColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              '¿Emergencia? Llámanos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String title;
  final List<Color> gradient;
  final String? badge;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.gradient,
    this.badge,
    required this.onTap,
  });
}
