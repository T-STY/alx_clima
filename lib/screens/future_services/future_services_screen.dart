import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/providers/auth_provider.dart';
import 'package:alx_clima/widgets/status_badge.dart';

class FutureServicesScreen extends StatelessWidget {
  const FutureServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Text(
                'Más Servicios',
                style: Theme.of(context).textTheme.headlineMedium,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.1, end: 0),

              const SizedBox(height: 6),

              Text(
                'Todo lo que necesitas en un solo lugar',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(duration: 400.ms, delay: 50.ms),

              const SizedBox(height: 28),

              Text(
                'Disponible Ahora',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms),

              const SizedBox(height: 12),

              _ServiceCard(
                icon: Iconsax.message_question,
                title: 'Contactar Soporte',
                subtitle: 'Llámanos, escríbenos o envía un correo',
                color: AppTheme.primaryColor,
                onTap: () => context.push('/contact'),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 150.ms)
                  .slideX(begin: 0.05, end: 0),

              const SizedBox(height: 10),

              _ServiceCard(
                icon: Iconsax.user,
                title: 'Mi Perfil',
                subtitle: 'Gestiona tu información personal',
                color: AppTheme.secondaryColor,
                onTap: () => context.push('/profile'),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 220.ms)
                  .slideX(begin: 0.05, end: 0),

              const SizedBox(height: 10),

              _ServiceCard(
                icon: Iconsax.lamp_charge,
                title: 'Consejos de Cuidado',
                subtitle: 'Aprende a mantener tu equipo en óptimas condiciones',
                color: AppTheme.successColor,
                onTap: () => context.push('/tips'),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 290.ms)
                  .slideX(begin: 0.05, end: 0),

              const SizedBox(height: 10),

              _ServiceCard(
                icon: Iconsax.document_text,
                title: 'Mis Facturas',
                subtitle: 'Consulta y descarga tus facturas de servicio',
                color: AppTheme.warningColor,
                onTap: () => context.push('/invoices'),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 360.ms)
                  .slideX(begin: 0.05, end: 0),

              const SizedBox(height: 32),

              Text(
                'Próximamente',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 350.ms),

              const SizedBox(height: 12),

              _ComingSoonCard(
                icon: Iconsax.sun_1,
                title: 'Instalación de Paneles Solares',
                subtitle: 'Energía limpia para tu hogar',
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 400.ms),

              const SizedBox(height: 10),

              _ComingSoonCard(
                icon: Iconsax.flash_1,
                title: 'Trabajo Eléctrico',
                subtitle: 'Instalaciones y reparaciones eléctricas',
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 460.ms),

              const SizedBox(height: 10),

              _ComingSoonCard(
                icon: Icons.plumbing_outlined,
                title: 'Plomería',
                subtitle: 'Servicios de plomería profesional',
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 520.ms),

              const SizedBox(height: 24),

              GestureDetector(
                onTap: () => _showSignOutDialog(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Iconsax.logout,
                        color: AppTheme.errorColor,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Cerrar Sesión',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppTheme.errorColor,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 700.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthProvider>().signOut();
            },
            child: Text(
              'Cerrar Sesión',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.textSecondary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const StatusBadge(
              text: 'Próximamente',
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
