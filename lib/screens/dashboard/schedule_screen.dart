import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:alx_clima/providers/quote_provider.dart';
import 'package:alx_clima/services/firebase_service.dart';
import 'package:alx_clima/widgets/futuristic_button.dart';

class ScheduleScreen extends StatefulWidget {
  final List<String>? prefilledEquipmentIds;
  final bool fromQuote;

  const ScheduleScreen({
    super.key,
    this.prefilledEquipmentIds,
    this.fromQuote = false,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  List<String> _selectedEquipmentIds = [];
  ServiceType _selectedServiceType = ServiceType.maintenance;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final _notesController = TextEditingController();

  Map<String, List<String>> _availableSlots = {};
  Set<String> _bookedSlots = {};
  bool _isLoadingSlots = true;
  bool _isBooking = false;

  List<QuoteItem> _quoteItems = [];

  final _serviceTypes = <ServiceType>[
    ServiceType.maintenance,
    ServiceType.removal,
    ServiceType.relocation,
  ];

  DateTime _calendarMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  static const String _addNewValue = '__add_new__';

  int get _slotsNeeded => _selectedEquipmentIds.isEmpty ? 1 : _selectedEquipmentIds.length;

  @override
  void initState() {
    super.initState();
    if (widget.fromQuote) {
      final quote = context.read<QuoteProvider>();
      _quoteItems = [...quote.items];
      _selectedEquipmentIds =
          _quoteItems.map((i) => i.equipment.id).toList();
    } else if (widget.prefilledEquipmentIds != null) {
      _selectedEquipmentIds = [...widget.prefilledEquipmentIds!];
    }
    _loadAvailableSlots();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSlots() async {
    try {
      final results = await Future.wait([
        _firebaseService.getAvailableSlots(),
        _firebaseService.getBookedSlots(),
      ]);
      if (mounted) {
        setState(() {
          _availableSlots = results[0] as Map<String, List<String>>;
          _bookedSlots = results[1] as Set<String>;
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
    final allSlots = _availableSlots[key] ?? [];
    return allSlots
        .where((slot) => !_bookedSlots.contains('$key|$slot'))
        .toList();
  }

  List<String> get _consecutiveSlotsFromSelected {
    if (_selectedTimeSlot == null || _slotsNeeded <= 1) {
      return _selectedTimeSlot != null ? [_selectedTimeSlot!] : [];
    }
    final available = _slotsForSelectedDate;
    final startIdx = available.indexOf(_selectedTimeSlot!);
    if (startIdx < 0) return [];
    if (startIdx + _slotsNeeded > available.length) return [];
    return available.sublist(startIdx, startIdx + _slotsNeeded);
  }

  bool get _canConfirm =>
      _selectedEquipmentIds.isNotEmpty &&
      _selectedDate != null &&
      _selectedTimeSlot != null &&
      _consecutiveSlotsFromSelected.length == _slotsNeeded;

  void _selectServiceType(ServiceType type) {
    setState(() {
      _selectedServiceType = type;
      _serviceTypes.remove(type);
      _serviceTypes.insert(0, type);
    });
  }

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
                        'Equipos (${_selectedEquipmentIds.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1 hora por equipo. Selecciona los equipos que necesitan servicio.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(
                        _selectedEquipmentIds.length + 1,
                        (i) {
                          if (i < _selectedEquipmentIds.length) {
                            return _buildEquipmentRow(dashboard, i);
                          }
                          return _buildAddEquipmentButton(dashboard);
                        },
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Tipo de Servicio',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _serviceTypes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final type = _serviceTypes[index];
                            final isSelected =
                                _selectedServiceType == type;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: FilterChip(
                                label: Text(type.displayName),
                                selected: isSelected,
                                onSelected: (_) =>
                                    _selectServiceType(type),
                                selectedColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.12),
                                checkmarkColor: AppTheme.primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
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
                          'Horario Disponible${_slotsNeeded > 1 ? ' ($_slotsNeeded hrs necesarias)' : ''}',
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
                      color:
                          AppTheme.primaryColor.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: FuturisticButton(
                  text: 'Confirmar Cita',
                  icon: Iconsax.tick_circle,
                  isLoading: _isBooking,
                  onPressed:
                      _canConfirm && !_isBooking ? () => _confirmAppointment() : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEquipmentRow(DashboardProvider dashboard, int index) {
    final eqId = _selectedEquipmentIds[index];
    final equip = dashboard.getEquipmentById(eqId);
    final quoteItem = _quoteItems.where((q) => q.equipment.id == eqId).firstOrNull;
    final name = equip?.equipmentName ?? quoteItem?.equipment.name ?? 'Equipo desconocido';
    final loc = equip?.location ?? quoteItem?.location ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.cpu_setting, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                      overflow: TextOverflow.ellipsis),
                  if (loc.isNotEmpty)
                    Text(loc,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            )),
                ],
              ),
            ),
            if (_selectedEquipmentIds.length > 1)
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedEquipmentIds.removeAt(index);
                    _selectedTimeSlot = null;
                  });
                },
                icon: const Icon(Iconsax.close_circle, size: 18, color: AppTheme.errorColor),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddEquipmentButton(DashboardProvider dashboard) {
    return GestureDetector(
      onTap: () => _showEquipmentPicker(dashboard),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.add_circle, color: AppTheme.primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(
              _selectedEquipmentIds.isEmpty
                  ? 'Seleccionar equipo'
                  : 'Agregar otro equipo',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEquipmentPicker(DashboardProvider dashboard) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final available = dashboard.equipment
            .where((e) => !_selectedEquipmentIds.contains(e.id))
            .toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              const SizedBox(height: 16),
              Text('Seleccionar Equipo',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              if (available.isEmpty && dashboard.equipment.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('No tienes equipos registrados',
                      style: Theme.of(ctx).textTheme.bodyMedium),
                )
              else if (available.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Todos tus equipos ya fueron agregados',
                      style: Theme.of(ctx).textTheme.bodyMedium),
                )
              else
                ...available.map((e) {
                  return ListTile(
                    leading: const Icon(Iconsax.cpu_setting, color: AppTheme.primaryColor),
                    title: Text(e.equipmentName),
                    subtitle: e.location != null && e.location!.isNotEmpty
                        ? Text(e.location!)
                        : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _selectedEquipmentIds.add(e.id);
                        _selectedTimeSlot = null;
                      });
                    },
                  );
                }),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showAddEquipmentSheet(context, dashboard);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.add_circle, color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text('Registrar nuevo equipo',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
    final firstDay =
        DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final lastDay =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0);
    final startWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;

    final canGoPrev =
        _calendarMonth.isAfter(DateTime(now.year, now.month));
    final canGoNext =
        _calendarMonth.isBefore(DateTime(now.year, now.month + 3));

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
                style:
                    Theme.of(context).textTheme.titleSmall?.copyWith(
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
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
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
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
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
                            ? AppTheme.primaryColor
                                .withValues(alpha: 0.1)
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
                style:
                    Theme.of(context).textTheme.bodySmall?.copyWith(
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
                style:
                    Theme.of(context).textTheme.bodySmall?.copyWith(
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
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
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
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
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

  Widget _buildSummary(
      BuildContext context, DashboardProvider dashboard) {
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
                style:
                    Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._selectedEquipmentIds.map((id) {
            final eq = dashboard.getEquipmentById(id);
            return Text(
              'Equipo: ${eq?.equipmentName ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodySmall,
            );
          }),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _AddEquipmentSheet(
          dashboard: dashboard,
          onAdded: (equipment) {
            setState(() => _selectedEquipmentId = equipment.id);
          },
        );
      },
    );
  }

  Future<void> _confirmAppointment() async {
    if (!_canConfirm) return;

    setState(() => _isBooking = true);

    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final slotsToBook = _consecutiveSlotsFromSelected;
    final dashboard = context.read<DashboardProvider>();
    final profile = dashboard.profile;

    final booked =
        await _firebaseService.bookSlotsAtomically(dateKey, slotsToBook);

    if (!booked) {
      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('El horario ya no está disponible. Selecciona otro.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        _loadAvailableSlots();
      }
      return;
    }

    if (_quoteItems.isNotEmpty) {
      for (final item in _quoteItems) {
        final existing = dashboard.getEquipmentById(item.equipment.id);
        if (existing == null) {
          final now = DateTime.now();
          final ce = CustomerEquipment(
            id: item.equipment.id,
            equipmentName: item.equipment.name,
            brand: item.equipment.brand,
            type: item.equipment.type,
            btuCapacity: item.equipment.btuCapacity,
            installDate: now,
            nextServiceDate: DateTime(now.year, now.month + 6, now.day),
            installationType: InstallationType.fullPackage,
            location: item.location ?? '',
            isUserAdded: true,
          );
          await dashboard.addEquipment(ce);
        }
      }
    }

    final equipmentList = _selectedEquipmentIds.map((id) {
      final eq = dashboard.getEquipmentById(id);
      final qi = _quoteItems.where((q) => q.equipment.id == id).firstOrNull;
      return {
        'id': eq?.id ?? id,
        'name': eq?.equipmentName ?? qi?.equipment.name ?? '',
        'brand': eq?.brand ?? qi?.equipment.brand ?? '',
        'btuCapacity': eq?.btuCapacity ?? qi?.equipment.btuCapacity ?? 0,
        'location': eq?.location ?? qi?.location ?? '',
        'type': eq?.type.displayName ?? qi?.equipment.type.displayName ?? '',
      };
    }).toList();

    final timeLabel = slotsToBook.join(' + ');

    for (final eqId in _selectedEquipmentIds) {
      final appointment = Appointment(
        id: 'apt-${DateTime.now().millisecondsSinceEpoch}-$eqId',
        equipmentId: eqId,
        preferredDate: _selectedDate!,
        preferredTimeSlot: TimeSlot.morning,
        preferredTimeLabel: timeLabel,
        serviceType: _selectedServiceType,
        notes: _notesController.text.trim(),
        status: AppointmentStatus.pending,
      );
      context.read<AppointmentProvider>().scheduleAppointment(appointment);
    }

    await _firebaseService.createGlobalAppointment({
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'status': 'pending',
      'date': dateKey,
      'timeSlots': slotsToBook,
      'timeSlotDisplay': timeLabel,
      'serviceType': _selectedServiceType.name,
      'serviceTypeDisplay': _selectedServiceType.displayName,
      'notes': _notesController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'equipmentCount': _selectedEquipmentIds.length,
      'customer': {
        'name': profile?.name ?? '',
        'phone': profile?.phone ?? '',
        'email': profile?.email ?? '',
        'address': profile?.displayAddress ?? '',
      },
      'equipment': equipmentList,
      'totalUserEquipment': dashboard.totalEquipment,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.tick_circle,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Cita agendada exitosamente'),
            ),
          ],
        ),
        backgroundColor: AppTheme.successColor,
      ),
    );

    context.go('/home');
  }
}

class _AddEquipmentSheet extends StatefulWidget {
  final DashboardProvider dashboard;
  final ValueChanged<CustomerEquipment> onAdded;

  const _AddEquipmentSheet({
    required this.dashboard,
    required this.onAdded,
  });

  @override
  State<_AddEquipmentSheet> createState() => _AddEquipmentSheetState();
}

class _AddEquipmentSheetState extends State<_AddEquipmentSheet> {
  final FirebaseService _firebaseService = FirebaseService();
  final _locationCtrl = TextEditingController();

  List<Map<String, dynamic>> _brands = [];
  bool _isLoadingBrands = true;

  String? _selectedBrand;
  List<String> _modelsForBrand = [];
  String? _selectedModel;
  int? _selectedBtu;

  static const List<int> _btuOptions = [
    12000,
    18000,
    24000,
    36000,
  ];

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    try {
      final brands = await _firebaseService.getEquipmentBrands();
      if (mounted) {
        setState(() {
          _brands = brands;
          _isLoadingBrands = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBrands = false);
    }
  }

  void _onBrandSelected(String? brand) {
    setState(() {
      _selectedBrand = brand;
      _selectedModel = null;
      _modelsForBrand = [];
    });
    if (brand != null) {
      final brandData = _brands.firstWhere(
        (b) => b['name'] == brand,
        orElse: () => <String, dynamic>{},
      );
      final models = brandData['models'];
      if (models is List) {
        setState(() {
          _modelsForBrand = models.cast<String>();
        });
      }
    }
  }

  void _addEquipment() {
    if (_selectedBrand == null || _selectedModel == null || _selectedBtu == null) {
      return;
    }

    final now = DateTime.now();
    final newEquipment = CustomerEquipment(
      id: 'ce-${now.millisecondsSinceEpoch}',
      equipmentName: _selectedModel!,
      brand: _selectedBrand!,
      type: EquipmentType.miniSplit,
      btuCapacity: _selectedBtu!,
      installDate: now,
      nextServiceDate: DateTime(now.year, now.month + 6, now.day),
      installationType: InstallationType.installOnly,
      location: _locationCtrl.text.trim(),
      isUserAdded: true,
    );

    widget.dashboard.addEquipment(newEquipment);
    Navigator.of(context).pop();
    widget.onAdded(newEquipment);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Equipo agregado'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  bool get _canAdd =>
      _selectedBrand != null &&
      _selectedModel != null &&
      _selectedBtu != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),

            if (_isLoadingBrands)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else ...[
              _buildDropdown(
                label: 'Marca',
                icon: Iconsax.tag,
                value: _selectedBrand,
                hint: 'Seleccionar marca',
                items: _brands.map((b) {
                  final name = b['name'] as String;
                  return DropdownMenuItem(
                    value: name,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: _onBrandSelected,
              ),

              const SizedBox(height: 12),

              _buildDropdown(
                label: 'Modelo',
                icon: Iconsax.cpu_setting,
                value: _selectedModel,
                hint: _selectedBrand == null
                    ? 'Selecciona una marca primero'
                    : 'Seleccionar modelo',
                items: _modelsForBrand
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m),
                        ))
                    .toList(),
                onChanged: _selectedBrand == null
                    ? null
                    : (val) =>
                        setState(() => _selectedModel = val),
              ),

              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Capacidad (BTU)',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _btuOptions.map((btu) {
                  final isSelected = _selectedBtu == btu;
                  final label =
                      '${(btu / 1000).toStringAsFixed(0)}K BTU';
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedBtu = btu),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                                .withValues(alpha: 0.12)
                            : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ubicación (ej. Sala, Recámara)',
                  prefixIcon: Icon(Iconsax.location, size: 20),
                ),
              ),

              const SizedBox(height: 20),

              FuturisticButton(
                text: 'Agregar',
                icon: Iconsax.add_circle,
                onPressed: _canAdd ? _addEquipment : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.textSecondary),
              const SizedBox(width: 10),
              Text(hint),
            ],
          ),
          isExpanded: true,
          icon: const Icon(Iconsax.arrow_down_1),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
