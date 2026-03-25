import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/models/appointment.dart';
import 'package:alx_clima/models/customer_equipment.dart';
import 'package:alx_clima/models/equipment.dart';
import 'package:alx_clima/models/installation.dart';
import 'package:alx_clima/models/service_record.dart';
import 'package:alx_clima/providers/appointment_provider.dart';
import 'package:alx_clima/providers/dashboard_provider.dart';
import 'package:alx_clima/widgets/futuristic_button.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String? _selectedEquipmentId;
  ServiceType _selectedServiceType = ServiceType.maintenance;
  DateTime? _selectedDate;
  TimeSlot _selectedTimeSlot = TimeSlot.morning;
  final _notesController = TextEditingController();

  static const String _addNewValue = '__add_new__';

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Servicio'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboard, _) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Equipo (opcional)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedEquipmentId,
                            hint: const Text('Seleccionar equipo'),
                            isExpanded: true,
                            icon: const Icon(Iconsax.arrow_down_1),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Ninguno / General'),
                              ),
                              ...dashboard.equipment.map(
                                (e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(
                                    e.equipmentName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: _addNewValue,
                                child: Row(
                                  children: [
                                    Icon(
                                      Iconsax.add_circle,
                                      size: 18,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Agregar nuevo equipo',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == _addNewValue) {
                                _showAddEquipmentSheet(context, dashboard);
                              } else {
                                setState(() => _selectedEquipmentId = value);
                              }
                            },
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms),

                      const SizedBox(height: 24),

                      Text(
                        'Tipo de Servicio',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildServiceTypeChip(
                              'Mantenimiento', ServiceType.maintenance),
                          _buildServiceTypeChip(
                              'Reparación', ServiceType.repair),
                          _buildServiceTypeChip(
                              'Inspección', ServiceType.inspection),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 100.ms),

                      const SizedBox(height: 24),

                      Text(
                        'Fecha Preferida',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _pickDate(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedDate != null
                                  ? AppTheme.primaryColor
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.calendar_1,
                                color: _selectedDate != null
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDate != null
                                    ? dateFormat.format(_selectedDate!)
                                    : 'Seleccionar fecha',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: _selectedDate != null
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 200.ms),

                      const SizedBox(height: 24),

                      Text(
                        'Horario Preferido',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeSlotCard(
                              context,
                              'Mañana',
                              '8AM - 12PM',
                              Iconsax.sun_1,
                              TimeSlot.morning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTimeSlotCard(
                              context,
                              'Tarde',
                              '1PM - 5PM',
                              Iconsax.moon,
                              TimeSlot.afternoon,
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 300.ms),

                      const SizedBox(height: 24),

                      Text(
                        'Notas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Describe tu problema o solicitud...',
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 400.ms),

                      const SizedBox(height: 24),

                      if (_selectedDate != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.primaryColor
                                  .withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Iconsax.document_text,
                                      size: 18,
                                      color: AppTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Resumen de tu cita',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Servicio: ${_selectedServiceType.displayName}',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Fecha: ${dateFormat.format(_selectedDate!)}',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Horario: ${_selectedTimeSlot.displayName}',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                              if (_selectedEquipmentId != null) ...[
                                Text(
                                  'Equipo: ${dashboard.getEquipmentById(_selectedEquipmentId!)?.equipmentName ?? 'N/A'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 300.ms),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: FuturisticButton(
                  text: 'Confirmar Cita',
                  icon: Iconsax.tick_circle,
                  onPressed: _selectedDate != null
                      ? () => _confirmAppointment()
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddEquipmentSheet(
      BuildContext context, DashboardProvider dashboard) {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
              Text(
                'Agregar Equipo',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del equipo',
                  prefixIcon: Icon(Iconsax.cpu_setting, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: brandCtrl,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  prefixIcon: Icon(Iconsax.tag, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ubicación (ej. Sala, Recámara)',
                  prefixIcon: Icon(Iconsax.location, size: 20),
                ),
              ),
              const SizedBox(height: 20),
              FuturisticButton(
                text: 'Agregar',
                icon: Iconsax.add_circle,
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;

                  final now = DateTime.now();
                  final newEquipment = CustomerEquipment(
                    id: 'ce-${now.millisecondsSinceEpoch}',
                    equipmentName: nameCtrl.text.trim(),
                    brand: brandCtrl.text.trim(),
                    type: EquipmentType.miniSplit,
                    btuCapacity: 12000,
                    installDate: now,
                    nextServiceDate: DateTime(
                      now.year,
                      now.month + 6,
                      now.day,
                    ),
                    installationType: InstallationType.fullPackage,
                    location: locationCtrl.text.trim(),
                  );

                  dashboard.addEquipment(newEquipment);
                  Navigator.of(ctx).pop();

                  setState(
                      () => _selectedEquipmentId = newEquipment.id);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Equipo agregado'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceTypeChip(String label, ServiceType type) {
    final isSelected = _selectedServiceType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedServiceType = type),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.12),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  Widget _buildTimeSlotCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    TimeSlot slot,
  ) {
    final isSelected = _selectedTimeSlot == slot;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeSlot = slot),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.7)
                        : AppTheme.textSecondary,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.backgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _confirmAppointment() {
    if (_selectedDate == null) return;

    final appointment = Appointment(
      id: 'apt-${DateTime.now().millisecondsSinceEpoch}',
      equipmentId: _selectedEquipmentId,
      preferredDate: _selectedDate!,
      preferredTimeSlot: _selectedTimeSlot,
      serviceType: _selectedServiceType,
      notes: _notesController.text.trim(),
      status: AppointmentStatus.pending,
    );

    context.read<AppointmentProvider>().scheduleAppointment(appointment);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Cita agendada exitosamente'),
            ),
          ],
        ),
        backgroundColor: AppTheme.successColor,
      ),
    );

    context.pop();
  }
}
