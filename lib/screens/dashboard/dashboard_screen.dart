import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/models/appointment.dart';
import 'package:alx_clima/providers/appointment_provider.dart';
import 'package:alx_clima/providers/dashboard_provider.dart';
import 'package:alx_clima/widgets/empty_state_widget.dart';
import 'package:alx_clima/widgets/equipment_tile.dart';
import 'package:alx_clima/widgets/section_header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer2<DashboardProvider, AppointmentProvider>(
          builder: (context, dashboard, appointments, _) {
            final upcoming = appointments.upcomingAppointments;
            final needingService = dashboard.equipmentNeedingService;
            final nextDate = dashboard.nextServiceDate;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  Text(
                    'Mi Equipo',
                    style: Theme.of(context).textTheme.headlineMedium,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.1, end: 0),

                  const SizedBox(height: 6),

                  Text(
                    'Gestiona tus equipos y servicios',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(duration: 400.ms, delay: 50.ms),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _DashStatCard(
                          icon: Iconsax.cpu_setting,
                          label: 'Equipos\nInstalados',
                          value: '${dashboard.totalEquipment}',
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DashStatCard(
                          icon: Iconsax.calendar_1,
                          label: 'Próximo\nServicio',
                          value: nextDate != null
                              ? DateFormat('dd/MM').format(nextDate)
                              : 'Al día',
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DashStatCard(
                          icon: Iconsax.warning_2,
                          label: 'Servicios\nPendientes',
                          value: '${needingService.length}',
                          color: needingService.isNotEmpty
                              ? AppTheme.warningColor
                              : AppTheme.successColor,
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 100.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 28),

                  const SectionHeader(title: 'Mis Equipos')
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms),

                  const SizedBox(height: 12),

                  if (dashboard.equipment.isEmpty)
                    EmptyStateWidget(
                      icon: Iconsax.cpu_setting,
                      title: 'Aún no tienes equipos registrados',
                      subtitle:
                          'Cotiza e instala tu primer equipo de climatización',
                      actionText: 'Cotizar Equipo',
                      onAction: () => context.go('/quote'),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dashboard.equipment.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final equip = dashboard.equipment[index];
                        return EquipmentTile(
                          equipment: equip,
                          onTap: () => context
                              .push('/dashboard/equipment/${equip.id}'),
                        )
                            .animate()
                            .fadeIn(
                                duration: 400.ms,
                                delay: (250 + index * 80).ms)
                            .slideX(begin: 0.05, end: 0);
                      },
                    ),

                  const SizedBox(height: 28),

                  if (upcoming.isNotEmpty) ...[
                    const SectionHeader(title: 'Próximas Citas')
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 400.ms),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: upcoming.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final apt = upcoming[index];
                        final equip = apt.equipmentId != null
                            ? dashboard.getEquipmentById(apt.equipmentId!)
                            : null;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Iconsax.calendar_tick,
                                  color: AppTheme.primaryColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      equip?.equipmentName ??
                                          'Equipo ${apt.equipmentId}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${DateFormat('dd/MM/yyyy').format(apt.preferredDate)} \u00b7 ${apt.preferredTimeSlot.displayName}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: apt.status ==
                                          AppointmentStatus.confirmed
                                      ? AppTheme.successColor
                                          .withValues(alpha: 0.12)
                                      : AppTheme.warningColor
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  apt.status.displayName,
                                  style: TextStyle(
                                    color: apt.status ==
                                            AppointmentStatus.confirmed
                                        ? AppTheme.successColor
                                        : AppTheme.warningColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(
                                duration: 400.ms,
                                delay: (450 + index * 80).ms);
                      },
                    ),
                    const SizedBox(height: 28),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dashboard/schedule'),
        icon: const Icon(Iconsax.calendar_add),
        label: const Text('Agendar Servicio'),
      ),
    );
  }
}

class _DashStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DashStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
