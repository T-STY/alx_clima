import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/models/installation.dart';
import 'package:alx_clima/providers/quote_provider.dart';
import 'package:alx_clima/widgets/status_badge.dart';

class QuoteTypeScreen extends StatelessWidget {
  const QuoteTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              Text(
                '¿Qué necesitas?',
                style: Theme.of(context).textTheme.headlineMedium,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.1, end: 0),

              const SizedBox(height: 8),

              Text(
                'Selecciona el tipo de servicio que buscas',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

              const SizedBox(height: 36),

              _QuoteTypeCard(
                icon: Iconsax.box_1,
                title: 'Equipo + Instalación',
                description:
                    'Incluye equipo, instalación profesional y garantía completa',
                badge: const StatusBadge(
                  text: 'Garantía incluida',
                  color: AppTheme.successColor,
                  icon: Iconsax.shield_tick,
                ),
                gradient: const [AppTheme.primaryColor, Color(0xFF3B9FFF)],
                onTap: () {
                  context
                      .read<QuoteProvider>()
                      .setInstallationType(InstallationType.fullPackage);
                  context.push('/quote/equipment');
                },
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 200.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 16),

              _QuoteTypeCard(
                icon: Iconsax.setting_2,
                title: 'Solo Instalación',
                description:
                    'Ya tienes tu equipo y solo necesitas instalación profesional. Sin garantía.',
                badge: const StatusBadge(
                  text: 'Sin garantía',
                  color: AppTheme.warningColor,
                  icon: Iconsax.info_circle,
                ),
                gradient: const [AppTheme.secondaryColor, Color(0xFF40E0FF)],
                onTap: () {
                  context
                      .read<QuoteProvider>()
                      .setInstallationType(InstallationType.installOnly);
                  context.push('/quote/installation');
                },
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 350.ms)
                  .slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget badge;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuoteTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.dividerColor,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const Spacer(),
                Icon(
                  Iconsax.arrow_right_3,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            badge,
          ],
        ),
      ),
    );
  }
}
