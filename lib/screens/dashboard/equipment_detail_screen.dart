import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:alx_clima/config/constants.dart';
import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/models/appointment.dart';
import 'package:alx_clima/models/installation.dart';
import 'package:alx_clima/providers/appointment_provider.dart';
import 'package:alx_clima/providers/dashboard_provider.dart';
import 'package:alx_clima/widgets/futuristic_button.dart';
import 'package:alx_clima/widgets/section_header.dart';
import 'package:alx_clima/widgets/status_badge.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final String equipmentId;

  const EquipmentDetailScreen({super.key, required this.equipmentId});

  @override
  State<EquipmentDetailScreen> createState() =>
      _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  bool _isEditing = false;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Iconsax.close_circle : Iconsax.edit_2,
              color: AppTheme.primaryColor,
            ),
            onPressed: () {
              final dashboard = context.read<DashboardProvider>();
              final equip =
                  dashboard.getEquipmentById(widget.equipmentId);
              if (equip == null) return;

              setState(() {
                _isEditing = !_isEditing;
                if (_isEditing) {
                  _locationController.text = equip.location ?? '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(
              Iconsax.trash,
              color: AppTheme.errorColor,
            ),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboard, _) {
          final equip =
              dashboard.getEquipmentById(widget.equipmentId);

          if (equip == null) {
            return const Center(
              child: Text('Equipo no encontrado'),
            );
          }

          final history = dashboard
              .getServiceHistoryForEquipment(widget.equipmentId);
          final isFullPackage =
              equip.installationType == InstallationType.fullPackage;
          final isUserAdded = equip.isUserAdded;

          String estadoText;
          Color estadoColor;
          IconData estadoIcon;
          if (history.isEmpty && equip.lastServiceDate == null) {
            estadoText = 'Desconocido';
            estadoColor = AppTheme.textSecondary;
            estadoIcon = Iconsax.info_circle;
          } else {
            final lastDate = equip.lastServiceDate ?? equip.installDate;
            final monthsSince = DateTime.now().difference(lastDate).inDays ~/ 30;
            if (monthsSince >= 4) {
              estadoText = 'Requiere Mantenimiento';
              estadoColor = AppTheme.warningColor;
              estadoIcon = Iconsax.warning_2;
            } else {
              estadoText = 'Al día';
              estadoColor = AppTheme.successColor;
              estadoIcon = Iconsax.tick_circle;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.06),
                        AppTheme.secondaryColor
                            .withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor
                          .withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                'https://img.icons8.com/ios/100/air-conditioner.png',
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(
                                  Iconsax.cpu_setting,
                                  color: AppTheme.primaryColor,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  equip.equipmentName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  equip.brand,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.primaryColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Capacidad',
                        value:
                            '${NumberFormat('#,###').format(equip.btuCapacity)} BTU',
                      ),
                      if (_isEditing)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 140,
                                child: Text(
                                  'Ubicación',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color:
                                            AppTheme.textSecondary,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _locationController,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  decoration:
                                      const InputDecoration(
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        _InfoRow(
                          label: 'Ubicación',
                          value: equip.location ?? 'No especificada',
                        ),
                      _InfoRow(
                        label: 'Fecha de Registro',
                        value: dateFormat.format(equip.installDate),
                      ),
                      _InfoRow(
                        label: 'Tipo',
                        value: equip.type.displayName,
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 8),
                        FuturisticButton(
                          text: 'Guardar Cambios',
                          icon: Iconsax.tick_circle,
                          onPressed: () {
                            final updated = equip.copyWith(
                              location:
                                  _locationController.text.trim(),
                            );
                            dashboard.updateEquipment(updated);
                            setState(() => _isEditing = false);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Ubicación actualizada'),
                                backgroundColor:
                                    AppTheme.successColor,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.05, end: 0),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Text(
                      'Estado: ',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    StatusBadge(
                      text: estadoText,
                      color: estadoColor,
                      icon: estadoIcon,
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 100.ms),

                const SizedBox(height: 20),

                if (isUserAdded && !isFullPackage) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary
                          .withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.textSecondary
                            .withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Iconsax.shield_cross,
                                color: AppTheme.textSecondary,
                                size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Garantía',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Limitada a 7 días, aplica únicamente a '
                          'problemas ocasionados por la mano de obra '
                          'de mantenimiento',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: 20),
                ] else if (isFullPackage) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor
                          .withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.successColor
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Iconsax.shield_tick,
                                color: AppTheme.successColor,
                                size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Garantía',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          label: 'Garantía del Técnico',
                          value: AppConstants.warrantyTechnician,
                        ),
                        _InfoRow(
                          label: 'Instalación desde',
                          value:
                              dateFormat.format(equip.installDate),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: 20),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor
                          .withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.warningColor
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.info_circle,
                            color: AppTheme.warningColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Solo Instalación - Sin garantía del técnico',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTheme.warningColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: 20),
                ],

                _buildAppointmentsSection(context, equip.id)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 280.ms),

                const SizedBox(height: 20),

                const SectionHeader(title: 'Historial de Servicios')
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 350.ms),

                const SizedBox(height: 12),

                if (history.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Iconsax.document_text,
                          size: 36,
                          color: AppTheme.textSecondary
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sin registros de servicio aún',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final record = history[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.dividerColor),
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius:
                                    BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                    children: [
                                      Text(
                                        record.serviceType
                                            .displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: AppTheme
                                                  .textPrimary,
                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        dateFormat.format(
                                            record.serviceDate),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    record.description,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                    maxLines: 2,
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                  if (record.cost != null &&
                                      record.cost! > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      NumberFormat.currency(
                                              symbol: '\$',
                                              decimalDigits: 0)
                                          .format(record.cost),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme
                                                .primaryColor,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(
                              duration: 400.ms,
                              delay: (350 + index * 80).ms);
                    },
                  ),

                const SizedBox(height: 28),

                FuturisticButton(
                  text: 'Agendar Mantenimiento',
                  icon: Iconsax.calendar_1,
                  onPressed: () => context.push(
                    '/dashboard/schedule?equipmentIds=${widget.equipmentId}',
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 500.ms),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentsSection(
      BuildContext context, String equipmentId) {
    final appointments = context.watch<AppointmentProvider>().appointments;
    final equipAppts = appointments
        .where((a) =>
            a.equipmentId == equipmentId &&
            (a.status == AppointmentStatus.pending ||
                a.status == AppointmentStatus.confirmed))
        .toList()
      ..sort(
          (a, b) => a.preferredDate.compareTo(b.preferredDate));
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Citas Programadas'),
        const SizedBox(height: 12),
        if (equipAppts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.calendar,
                  size: 20,
                  color: AppTheme.textSecondary
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sin citas programadas',
                  style:
                      Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          )
        else
          ...equipAppts.map((apt) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Iconsax.calendar_tick,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          apt.serviceType.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          '${dateFormat.format(apt.preferredDate)} \u00b7 ${apt.preferredTimeLabel ?? apt.preferredTimeSlot.displayName}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
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
            );
          }),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Equipo'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar este equipo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<DashboardProvider>()
                  .removeEquipment(widget.equipmentId);
              Navigator.of(ctx).pop();
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Equipo eliminado'),
                  backgroundColor: AppTheme.warningColor,
                ),
              );
            },
            child: Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(
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
