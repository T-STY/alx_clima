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
import 'package:alx_clima/services/firebase_service.dart';
import 'package:alx_clima/widgets/futuristic_button.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  String? _selectedEquipmentId;
  ServiceType _selectedServiceType = ServiceType.maintenance;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final _notesController = TextEditingController();

  Map<String, List<String>> _availableSlots = {};
  bool _isLoadingSlots = true;

  DateTime _calendarMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  static const String _addNewValue = '__add_new__';

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSlots() async {
    try {
      final slots = await _firebaseService.getAvailableSlots();
      if (mounted) {
        setState(() {
          _availableSlots = slots;
          _isLoadingSlots = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  Set<DateTime> get _availableDates {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final dates = <DateTime>{};
    for (final key in _availableSlots.keys) {
      final parsed = dateFormat.tryParse(key);
      if (parsed != null && parsed.isAfter(DateTime.now())) {
        dates.add(DateTime(parsed.year, parsed.month, parsed.day));
      }
    }
    return dates;
  }

  List<String> get _slotsForSelectedDate {
    if (_selectedDate == null) return [];
    final key = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    return _availableSlots[key] ?? [];
  }

  bool get _canConfirm =>
      _selectedEquipmentId != null &&
      _selectedDate != null &&
      _selectedTimeSlot != null;

  @override
  Widget build(BuildContext context) {
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
                        'Equipo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _buildEquipmentDropdown(dashboard)
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
                              'Retiro', ServiceType.removal),
                          _buildServiceTypeChip(
                              'Reubicación', ServiceType.relocation),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 100.ms),

                      const SizedBox(height: 24),

                      Text(
                        'Fecha Disponible',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      _buildCalendar()
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 200.ms),

                      const SizedBox(height: 24),

                      if (_selectedDate != null) ...[
                        Text(
                          'Horario Disponible',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        _buildTimeSlots()
                            .animate()
                            .fadeIn(duration: 400.ms),
                        const SizedBox(height: 24),
                      ],

                      Text(
                        'Notas (opcional)',
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
                          .fadeIn(duration: 400.ms, delay: 300.ms),

                      const SizedBox(height: 24),

                      if (_canConfirm)
                        _buildSummary(context, dashboard)
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
                  onPressed: _canConfirm ? () => _confirmAppointment() : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEquipmentDropdown(DashboardProvider dashboard) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: _selectedEquipmentId == null
            ? null
            : Border.all(color: AppTheme.primaryColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedEquipmentId,
          hint: const Text('Seleccionar equipo'),
          isExpanded: true,
          icon: const Icon(Iconsax.arrow_down_1),
          items: [
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
    );
  }

  Widget _buildCalendar() {
    if (_isLoadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_availableSlots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Iconsax.calendar_remove,
              size: 36,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              'No hay fechas disponibles por el momento',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Contáctanos para solicitar una cita',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final lastDay = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0);
    final startWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;

    final canGoPrev = _calendarMonth.isAfter(DateTime(now.year, now.month));
    final canGoNext = _calendarMonth
        .isBefore(DateTime(now.year, now.month + 3));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: canGoPrev
                    ? () => setState(() {
                          _calendarMonth = DateTime(
                            _calendarMonth.year,
                            _calendarMonth.month - 1,
                          );
                        })
                    : null,
                icon: Icon(
                  Iconsax.arrow_left_2,
                  size: 20,
                  color: canGoPrev
                      ? AppTheme.textPrimary
                      : AppTheme.dividerColor,
                ),
              ),
              Text(
                DateFormat('MMMM yyyy', 'es').format(_calendarMonth),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
              ),
              IconButton(
                onPressed: canGoNext
                    ? () => setState(() {
                          _calendarMonth = DateTime(
                            _calendarMonth.year,
                            _calendarMonth.month + 1,
                          );
                        })
                    : null,
                icon: Icon(
                  Iconsax.arrow_right_3,
                  size: 20,
                  color: canGoNext
                      ? AppTheme.textPrimary
                      : AppTheme.dividerColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: ['L', 'M', 'Mi', 'J', 'V', 'S', 'D']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: ((startWeekday - 1) + daysInMonth),
            itemBuilder: (context, index) {
              if (index < startWeekday - 1) {
                return const SizedBox();
              }

              final day = index - (startWeekday - 1) + 1;
              final date = DateTime(
                _calendarMonth.year,
                _calendarMonth.month,
                day,
              );
              final isAvailable = _availableDates.contains(date);
              final isSelected = _selectedDate != null &&
                  _selectedDate!.year == date.year &&
                  _selectedDate!.month == date.month &&
                  _selectedDate!.day == date.day;
              final isPast = date.isBefore(
                DateTime(now.year, now.month, now.day),
              );

              return GestureDetector(
                onTap: isAvailable && !isPast
                    ? () => setState(() {
                          _selectedDate = date;
                          _selectedTimeSlot = null;
                        })
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : isAvailable && !isPast
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected || isAvailable
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : isAvailable && !isPast
                                ? AppTheme.primaryColor
                                : isPast
                                    ? AppTheme.dividerColor
                                    : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Disponible',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                    ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Seleccionado',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots() {
    final slots = _slotsForSelectedDate;

    if (slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No hay horarios disponibles para esta fecha',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: slots.map((slot) {
        final isSelected = _selectedTimeSlot == slot;
        return GestureDetector(
          onTap: () => setState(() => _selectedTimeSlot = slot),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.12)
                  : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.clock,
                  size: 16,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  slot,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummary(BuildContext context, DashboardProvider dashboard) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.document_text,
                  size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Resumen de tu cita',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_selectedEquipmentId != null)
            Text(
              'Equipo: ${dashboard.getEquipmentById(_selectedEquipmentId!)?.equipmentName ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          Text(
            'Servicio: ${_selectedServiceType.displayName}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_selectedDate != null)
            Text(
              'Fecha: ${dateFormat.format(_selectedDate!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (_selectedTimeSlot != null)
            Text(
              'Horario: $_selectedTimeSlot',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
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

                  setState(() => _selectedEquipmentId = newEquipment.id);

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

  void _confirmAppointment() {
    if (!_canConfirm) return;

    final appointment = Appointment(
      id: 'apt-${DateTime.now().millisecondsSinceEpoch}',
      equipmentId: _selectedEquipmentId,
      preferredDate: _selectedDate!,
      preferredTimeSlot: TimeSlot.morning,
      preferredTimeLabel: _selectedTimeSlot,
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
