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

            final nextAppointmentDate = upcoming.isNotEmpty
                ? upcoming.first.preferredDate
                : null;

            String nextServiceValue;
            Color nextServiceColor;
            if (nextAppointmentDate != null) {
              nextServiceValue =
                  DateFormat('dd/MM').format(nextAppointmentDate);
              nextServiceColor = AppTheme.secondaryColor;
            } else {
              nextServiceValue = '\u2014/\u2014';
              nextServiceColor = AppTheme.textSecondary;
            }

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
                          label: 'Equipos\nRegistrados',
                          value: '${dashboard.totalEquipment}',
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DashStatCard(
                          icon: Iconsax.calendar_1,
                          label: 'Próxima\nCita',
                          value: nextServiceValue,
                          color: nextServiceColor,
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
                        return GestureDetector(
                          onTap: () => _showAppointmentDetail(
                            context,
                            apt,
                            equip?.equipmentName,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: AppTheme.dividerColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.1),
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
                                            'Servicio General',
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
                                        '${DateFormat('dd/MM/yyyy').format(apt.preferredDate)} \u00b7 ${apt.preferredTimeLabel ?? apt.preferredTimeSlot.displayName}',
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

                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => context.push('/dashboard/schedule'),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.calendar_add,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Agendar Servicio',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAppointmentDetail(
    BuildContext context,
    Appointment apt,
    String? equipmentName,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.calendar_tick,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalle de Cita',
                          style: Theme.of(ctx)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: apt.status == AppointmentStatus.confirmed
                                ? AppTheme.successColor
                                    .withValues(alpha: 0.12)
                                : AppTheme.warningColor
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            apt.status.displayName,
                            style: TextStyle(
                              color:
                                  apt.status == AppointmentStatus.confirmed
                                      ? AppTheme.successColor
                                      : AppTheme.warningColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DetailRow(
                icon: Iconsax.cpu_setting,
                label: 'Equipo',
                value: equipmentName ?? 'Servicio General',
              ),
              _DetailRow(
                icon: Iconsax.setting_2,
                label: 'Tipo',
                value: apt.serviceType.displayName,
              ),
              _DetailRow(
                icon: Iconsax.calendar_1,
                label: 'Fecha',
                value: dateFormat.format(apt.preferredDate),
              ),
              _DetailRow(
                icon: Iconsax.clock,
                label: 'Horario',
                value: apt.preferredTimeLabel ??
                    apt.preferredTimeSlot.displayName,
              ),
              if (apt.notes != null && apt.notes!.isNotEmpty)
                _DetailRow(
                  icon: Iconsax.note_text,
                  label: 'Notas',
                  value: apt.notes!,
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showRescheduleDialog(context, apt);
                      },
                      icon: const Icon(Iconsax.calendar_edit, size: 18),
                      label: const Text('Reagendar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showCancelDialog(context, apt.id);
                      },
                      icon: const Icon(Iconsax.close_circle, size: 18),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(
                          color: AppTheme.errorColor,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRescheduleDialog(BuildContext context, Appointment apt) {
    final eqId = apt.equipmentId;
    if (eqId != null) {
      context.push('/dashboard/schedule?equipmentIds=$eqId');
    } else {
      context.push('/dashboard/schedule');
    }
  }

  void _showCancelDialog(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Cita'),
        content:
            const Text('¿Estás seguro de que deseas cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<AppointmentProvider>()
                  .cancelAppointment(appointmentId);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cita cancelada'),
                  backgroundColor: AppTheme.warningColor,
                ),
              );
            },
            child: Text(
              'Sí, cancelar',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
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
