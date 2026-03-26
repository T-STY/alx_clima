import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/widgets/futuristic_button.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(icon: Icon(Iconsax.calendar_tick, size: 18), text: 'Citas'),
            Tab(icon: Icon(Iconsax.clock, size: 18), text: 'Horarios'),
            Tab(icon: Icon(Iconsax.money, size: 18), text: 'Precios'),
            Tab(icon: Icon(Iconsax.box_1, size: 18), text: 'Catálogo'),
            Tab(icon: Icon(Iconsax.building, size: 18), text: 'Empresa'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AppointmentsTab(firestore: _firestore),
          _ScheduleTab(firestore: _firestore),
          _PricingTab(firestore: _firestore),
          _CatalogTab(firestore: _firestore),
          _CompanyTab(firestore: _firestore),
        ],
      ),
    );
  }
}

class _AppointmentsTab extends StatelessWidget {
  final FirebaseFirestore firestore;
  const _AppointmentsTab({required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('appointments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.calendar,
                    size: 48,
                    color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text('Sin citas registradas',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final ref = docs[index].reference;
            final customer =
                data['customer'] as Map<String, dynamic>? ?? {};
            final equipField = data['equipment'];
            Map<String, dynamic> equipment;
            if (equipField is List && equipField.isNotEmpty) {
              equipment = equipField.first as Map<String, dynamic>;
            } else if (equipField is Map<String, dynamic>) {
              equipment = equipField;
            } else {
              equipment = {};
            }
            final equipCount = data['equipmentCount'] ?? 1;
            final status = data['status'] ?? 'pending';

            Color statusColor;
            switch (status) {
              case 'confirmed':
                statusColor = AppTheme.successColor;
                break;
              case 'cancelled':
                statusColor = AppTheme.errorColor;
                break;
              case 'completed':
                statusColor = AppTheme.textSecondary;
                break;
              case 'modified':
                statusColor = AppTheme.primaryColor;
                break;
              default:
                statusColor = AppTheme.warningColor;
            }

            return GestureDetector(
              onTap: () => _showAppointmentDetail(context, data, ref),
              child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer['name'] ?? 'Sin nombre',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _AdminDetailRow(
                      Iconsax.calendar_1, '${data['date']} \u00b7 ${data['timeSlotDisplay'] ?? ''}'),
                  _AdminDetailRow(
                      Iconsax.setting_2, data['serviceTypeDisplay'] ?? ''),
                  _AdminDetailRow(
                      Iconsax.cpu_setting,
                      '${equipment['brand']} ${equipment['name']} (${equipment['btuCapacity']} BTU)${equipCount > 1 ? ' +${equipCount - 1} más' : ''}'),
                  if ((equipment['location'] ?? '').isNotEmpty)
                    _AdminDetailRow(
                        Iconsax.location, equipment['location']),
                  _AdminDetailRow(
                      Iconsax.call, customer['phone'] ?? ''),
                  if ((customer['email'] ?? '').isNotEmpty)
                    _AdminDetailRow(
                        Iconsax.sms, customer['email']),
                  if ((customer['address'] ?? '').isNotEmpty)
                    _AdminDetailRow(
                        Iconsax.home_2, customer['address']),
                  if ((data['notes'] ?? '').isNotEmpty)
                    _AdminDetailRow(
                        Iconsax.note_text, data['notes']),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (status == 'pending') ...[
                        Expanded(
                          child: _SmallButton(
                            label: 'Confirmar',
                            color: AppTheme.successColor,
                            icon: Iconsax.tick_circle,
                            onTap: () =>
                                ref.update({'status': 'confirmed'}),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (status == 'confirmed') ...[
                        Expanded(
                          child: _SmallButton(
                            label: 'Completar',
                            color: AppTheme.primaryColor,
                            icon: Iconsax.tick_square,
                            onTap: () => _showCompleteDialog(
                                context, ref, data, firestore),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (status != 'cancelled' &&
                          status != 'completed')
                        Expanded(
                          child: _SmallButton(
                            label: 'Cancelar',
                            color: AppTheme.errorColor,
                            icon: Iconsax.close_circle,
                            onTap: () async {
                              await ref
                                  .update({'status': 'cancelled'});
                              final date = data['date'] as String?;
                              final slotsField = data['timeSlots'];
                              final singleSlot =
                                  data['timeSlot'] as String?;
                              final slotsToRestore = <String>[];
                              if (slotsField is List) {
                                slotsToRestore
                                    .addAll(slotsField.cast<String>());
                              } else if (singleSlot != null) {
                                slotsToRestore.add(singleSlot);
                              }
                              if (date != null &&
                                  slotsToRestore.isNotEmpty) {
                                final schedRef = firestore
                                    .collection('schedule')
                                    .doc(date);
                                final schedDoc =
                                    await schedRef.get();
                                if (schedDoc.exists) {
                                  final existing = (schedDoc.data()?['slots']
                                          as List?)
                                      ?.cast<String>() ?? [];
                                  final merged = {
                                    ...existing,
                                    ...slotsToRestore
                                  }.toList()
                                    ..sort();
                                  await schedRef.update({'slots': merged});
                                } else {
                                  final sorted = [...slotsToRestore]..sort();
                                  await schedRef.set({'slots': sorted});
                                }
                                for (final slot in slotsToRestore) {
                                  final bookedSnap = await firestore
                                      .collection('bookedSlots')
                                      .where('date',
                                          isEqualTo: date)
                                      .where('slot',
                                          isEqualTo: slot)
                                      .limit(1)
                                      .get();
                                  for (final d in bookedSnap.docs) {
                                    await d.reference.delete();
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      if (status == 'cancelled' ||
                          status == 'completed')
                        Expanded(
                          child: _SmallButton(
                            label: 'Eliminar',
                            color: AppTheme.textSecondary,
                            icon: Iconsax.trash,
                            onTap: () => ref.delete(),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }

  void _showCompleteDialog(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> data,
    FirebaseFirestore firestore,
  ) {
    final equipField = data['equipment'];
    final eqItems = <Map<String, dynamic>>[];
    if (equipField is List) {
      for (final e in equipField) {
        if (e is Map<String, dynamic>) eqItems.add(e);
      }
    } else if (equipField is Map<String, dynamic>) {
      eqItems.add(equipField);
    }

    if (eqItems.length <= 1) {
      _completeForEquipment(ref, data, eqItems, firestore);
      return;
    }

    final selected = List.filled(eqItems.length, true);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Completar Servicio'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('¿Cuáles equipos fueron atendidos?'),
                  const SizedBox(height: 12),
                  ...eqItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final eq = entry.value;
                    return CheckboxListTile(
                      value: selected[i],
                      onChanged: (v) =>
                          setDialogState(() => selected[i] = v ?? true),
                      title: Text(
                          '${eq['brand']} ${eq['name']}',
                          style: const TextStyle(fontSize: 14)),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    final attended = <Map<String, dynamic>>[];
                    for (var i = 0; i < eqItems.length; i++) {
                      if (selected[i]) attended.add(eqItems[i]);
                    }
                    _completeForEquipment(
                        ref, data, attended, firestore);
                  },
                  child: const Text('Completar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _completeForEquipment(
    DocumentReference ref,
    Map<String, dynamic> data,
    List<Map<String, dynamic>> attendedEquipment,
    FirebaseFirestore firestore,
  ) async {
    await ref.update({'status': 'completed'});
    final userId = data['userId'] as String?;
    if (userId == null) return;
    for (final eq in attendedEquipment) {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('serviceHistory')
          .add({
        'equipmentId': eq['id'] ?? '',
        'serviceDate': FieldValue.serverTimestamp(),
        'serviceType': data['serviceType'] ?? 'maintenance',
        'description':
            '${data['serviceTypeDisplay'] ?? 'Servicio'} completado',
        'technicianNotes': data['notes'] ?? '',
        'cost': 0,
      });
    }
  }

  void _showAppointmentDetail(
    BuildContext context,
    Map<String, dynamic> data,
    DocumentReference ref,
  ) {
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final equipField = data['equipment'];
    final allEquipment = <Map<String, dynamic>>[];
    if (equipField is List) {
      for (final e in equipField) {
        if (e is Map<String, dynamic>) allEquipment.add(e);
      }
    } else if (equipField is Map<String, dynamic>) {
      allEquipment.add(equipField);
    }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Detalle Completo',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _AdminDetailRow(Iconsax.user, customer['name'] ?? ''),
              _AdminDetailRow(Iconsax.call, customer['phone'] ?? ''),
              if ((customer['email'] ?? '').isNotEmpty)
                _AdminDetailRow(Iconsax.sms, customer['email']),
              if ((customer['address'] ?? '').isNotEmpty)
                _AdminDetailRow(Iconsax.home_2, customer['address']),
              const Divider(height: 20),
              _AdminDetailRow(Iconsax.calendar_1,
                  '${data['date']} \u00b7 ${data['timeSlotDisplay'] ?? ''}'),
              _AdminDetailRow(
                  Iconsax.setting_2, data['serviceTypeDisplay'] ?? ''),
              if ((data['notes'] ?? '').isNotEmpty)
                _AdminDetailRow(Iconsax.note_text, data['notes']),
              const Divider(height: 20),
              Text('Equipos (${allEquipment.length})',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...allEquipment.map((eq) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.cpu_setting,
                            size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${eq['brand']} ${eq['name']} (${eq['btuCapacity']} BTU)',
                            style:
                                Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textPrimary,
                                    ),
                          ),
                        ),
                        if ((eq['location'] ?? '').isNotEmpty)
                          Text(
                            eq['location'],
                            style:
                                Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                    ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmada';
      case 'cancelled':
        return 'Cancelada';
      case 'completed':
        return 'Completada';
      case 'modified':
        return 'Modificada';
      default:
        return 'Pendiente';
    }
  }
}

class _AdminDetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _AdminDetailRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleTab extends StatefulWidget {
  final FirebaseFirestore firestore;
  const _ScheduleTab({required this.firestore});

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  static const _dayNames = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  Set<int> _workDays = {1, 2, 3, 4, 5, 6};
  int _startHour = 9;
  int _endHour = 18;
  int _weeksAhead = 4;
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final doc = await widget.firestore
        .collection('config')
        .doc('workSchedule')
        .get();
    final data = doc.data();
    if (data != null && mounted) {
      setState(() {
        _workDays = ((data['workDays'] as List?) ?? [1, 2, 3, 4, 5, 6])
            .cast<int>()
            .toSet();
        _startHour = data['startHour'] ?? 9;
        _endHour = data['endHour'] ?? 18;
        _weeksAhead = data['weeksAhead'] ?? 4;
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Horario de Trabajo',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Configura tus días y horario laboral. Se generarán bloques de 1 hora automáticamente.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text('Días laborales',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (i) {
              final day = i + 1;
              final isSelected = _workDays.contains(day);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _workDays.remove(day);
                    } else {
                      _workDays.add(day);
                    }
                  });
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.dividerColor,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _dayNames[day],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Text('Horario',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _startHour,
                      isExpanded: true,
                      items: List.generate(
                          14,
                          (i) => DropdownMenuItem(
                                value: i + 6,
                                child: Text(
                                    '${(i + 6).toString().padLeft(2, '0')}:00'),
                              )),
                      onChanged: (v) =>
                          setState(() => _startHour = v ?? 9),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('a',
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _endHour,
                      isExpanded: true,
                      items: List.generate(
                          14,
                          (i) => DropdownMenuItem(
                                value: i + 7,
                                child: Text(
                                    '${(i + 7).toString().padLeft(2, '0')}:00'),
                              )),
                      onChanged: (v) =>
                          setState(() => _endHour = v ?? 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Generar disponibilidad para',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [2, 4, 6, 8].map((w) {
              final isSelected = _weeksAhead == w;
              return FilterChip(
                label: Text('$w semanas'),
                selected: isSelected,
                onSelected: (_) =>
                    setState(() => _weeksAhead = w),
                selectedColor:
                    AppTheme.primaryColor.withValues(alpha: 0.12),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimary,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          FuturisticButton(
            text: _isGenerating
                ? 'Generando...'
                : 'Guardar y Generar Disponibilidad',
            icon: Iconsax.calendar_tick,
            isLoading: _isGenerating,
            onPressed: _isGenerating
                ? null
                : () async {
                    setState(() => _isGenerating = true);

                    final config = {
                      'workDays': _workDays.toList()..sort(),
                      'startHour': _startHour,
                      'endHour': _endHour,
                      'weeksAhead': _weeksAhead,
                    };

                    await widget.firestore
                        .collection('config')
                        .doc('workSchedule')
                        .set(config);

                    final slots = <String>[];
                    for (var h = _startHour; h < _endHour; h++) {
                      slots.add(
                          '${h.toString().padLeft(2, '0')}:00 - ${(h + 1).toString().padLeft(2, '0')}:00');
                    }

                    final now = DateTime.now();
                    for (var d = 1; d <= _weeksAhead * 7; d++) {
                      final date = now.add(Duration(days: d));
                      if (!_workDays.contains(date.weekday)) continue;
                      final key =
                          DateFormat('yyyy-MM-dd').format(date);
                      final existing = await widget.firestore
                          .collection('schedule')
                          .doc(key)
                          .get();
                      if (!existing.exists) {
                        await widget.firestore
                            .collection('schedule')
                            .doc(key)
                            .set({'slots': slots});
                      }
                    }

                    if (mounted) {
                      setState(() => _isGenerating = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Disponibilidad generada exitosamente'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(height: 28),
          Text('Disponibilidad Actual',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: widget.firestore
                .collection('schedule')
                .orderBy(FieldPath.documentId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Text('Sin horarios configurados',
                    style:
                        Theme.of(context).textTheme.bodyMedium);
              }
              return Column(
                children: docs.map((doc) {
                  final slotsList =
                      (doc['slots'] as List?)?.cast<String>() ?? [];
                  return GestureDetector(
                    onTap: () => _showEditDayDialog(
                        context, doc.reference, doc.id, slotsList),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.id,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                ),
                                Text(
                                    '${slotsList.length} bloques \u00b7 Toca para editar',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall),
                              ],
                            ),
                          ),
                          const Icon(Iconsax.edit_2,
                              size: 16,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () =>
                                doc.reference.delete(),
                            icon: const Icon(Iconsax.trash,
                                size: 16,
                                color: AppTheme.errorColor),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditDayDialog(
    BuildContext context,
    DocumentReference ref,
    String dateId,
    List<String> currentSlots,
  ) {
    final slots = [...currentSlots]..sort();
    var addStart = const TimeOfDay(hour: 9, minute: 0);
    var addEnd = const TimeOfDay(hour: 10, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Editar $dateId',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toca un bloque para eliminarlo',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slots.map((slot) {
                      return Chip(
                        label: Text(slot),
                        deleteIcon: const Icon(
                            Iconsax.close_circle, size: 16),
                        onDeleted: () {
                          setSheetState(() => slots.remove(slot));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Agregar bloque',
                      style: Theme.of(ctx)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: addStart,
                            );
                            if (t != null) {
                              setSheetState(() => addStart = t);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${addStart.hour.toString().padLeft(2, '0')}:${addStart.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('a'),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: addEnd,
                            );
                            if (t != null) {
                              setSheetState(() => addEnd = t);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${addEnd.hour.toString().padLeft(2, '0')}:${addEnd.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          final label =
                              '${addStart.hour.toString().padLeft(2, '0')}:${addStart.minute.toString().padLeft(2, '0')} - ${addEnd.hour.toString().padLeft(2, '0')}:${addEnd.minute.toString().padLeft(2, '0')}';
                          if (!slots.contains(label)) {
                            setSheetState(() {
                              slots.add(label);
                              slots.sort();
                            });
                          }
                        },
                        icon: const Icon(Iconsax.add_circle,
                            color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FuturisticButton(
                    text: 'Guardar Cambios',
                    icon: Iconsax.tick_circle,
                    onPressed: () async {
                      if (slots.isEmpty) {
                        await ref.delete();
                      } else {
                        await ref.update({'slots': slots});
                      }
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PricingTab extends StatefulWidget {
  final FirebaseFirestore firestore;
  const _PricingTab({required this.firestore});

  @override
  State<_PricingTab> createState() => _PricingTabState();
}

class _PricingTabState extends State<_PricingTab> {
  final _c = <String, TextEditingController>{};
  bool _isLoading = true;
  Map<String, dynamic> _pricing = {};

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPricing() async {
    final doc = await widget.firestore
        .collection('config')
        .doc('pricing')
        .get();
    if (mounted) {
      setState(() {
        _pricing = doc.data() ?? {};
        _isLoading = false;
      });
    }
  }

  TextEditingController _ctrl(String key, dynamic def) {
    _c.putIfAbsent(key, () => TextEditingController(text: '$def'));
    return _c[key]!;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final io = (_pricing['installOnly'] as Map<String, dynamic>?) ?? {};
    final fp = (_pricing['fullPackage'] as Map<String, dynamic>?) ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Solo Instalación (cliente ya tiene equipo)'),
          Text(
            'Precio que cobras por instalar un equipo que el cliente ya compró por su cuenta.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ..._priceFields('io', io),
          const SizedBox(height: 20),
          _sectionTitle(
              context, 'Equipo + Instalación (compra equipo contigo)'),
          Text(
            'Precio de instalación cuando el cliente compra el equipo a través de ti. El costo del equipo se suma aparte.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ..._priceFields('fp', fp),
          const SizedBox(height: 20),
          _sectionTitle(context, 'Recargos y Descuentos'),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl(
                'sf', _pricing['secondFloorSurcharge'] ?? 0.3),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Recargo segundo piso (0.3 = 30%)',
              prefixIcon: Icon(Iconsax.building_4, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl(
                'df', _pricing['differentFloorSurcharge'] ?? 0.25),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Recargo compresor piso diferente',
              prefixIcon: Icon(Iconsax.arrow_swap, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl(
                'md', _pricing['multiUnitDiscount'] ?? 0.1),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Descuento multi-equipo (0.1 = 10%)',
              prefixIcon: Icon(Iconsax.discount_shape, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          FuturisticButton(
            text: 'Guardar Precios',
            icon: Iconsax.tick_circle,
            onPressed: () async {
              await widget.firestore
                  .collection('config')
                  .doc('pricing')
                  .set({
                'installOnly': {
                  '12000': num.tryParse(_ctrl('io12000', 0).text) ?? 0,
                  '18000': num.tryParse(_ctrl('io18000', 0).text) ?? 0,
                  '24000': num.tryParse(_ctrl('io24000', 0).text) ?? 0,
                  '36000': num.tryParse(_ctrl('io36000', 0).text) ?? 0,
                },
                'fullPackage': {
                  '12000': num.tryParse(_ctrl('fp12000', 0).text) ?? 0,
                  '18000': num.tryParse(_ctrl('fp18000', 0).text) ?? 0,
                  '24000': num.tryParse(_ctrl('fp24000', 0).text) ?? 0,
                  '36000': num.tryParse(_ctrl('fp36000', 0).text) ?? 0,
                },
                'secondFloorSurcharge':
                    num.tryParse(_ctrl('sf', 0).text) ?? 0.3,
                'differentFloorSurcharge':
                    num.tryParse(_ctrl('df', 0).text) ?? 0.25,
                'multiUnitDiscount':
                    num.tryParse(_ctrl('md', 0).text) ?? 0.1,
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Precios actualizados'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
    );
  }

  List<Widget> _priceFields(String pfx, Map<String, dynamic> p) {
    const btus = ['12000', '18000', '24000', '36000'];
    const labels = ['12K BTU', '18K BTU', '24K BTU', '36K BTU'];
    return List.generate(btus.length, (i) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: _ctrl('$pfx${btus[i]}', p[btus[i]] ?? 0),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: labels[i],
            prefixIcon: const Icon(Iconsax.money, size: 20),
            prefixText: '\$ ',
          ),
        ),
      );
    });
  }
}

class _CatalogTab extends StatefulWidget {
  final FirebaseFirestore firestore;
  const _CatalogTab({required this.firestore});

  @override
  State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> {
  List<Map<String, dynamic>> _brands = [];

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    final snap = await widget.firestore
        .collection('equipmentCatalog')
        .orderBy('order')
        .get();
    if (mounted) {
      setState(() {
        _brands = snap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Equipos en Catálogo',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              IconButton(
                onPressed: () =>
                    _showAddEquipmentDialog(context),
                icon: const Icon(Iconsax.add_circle,
                    color: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: widget.firestore
                .collection('quoteCatalog')
                .orderBy('brand')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Text('Sin equipos',
                    style:
                        Theme.of(context).textTheme.bodyMedium);
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${d['brand']} - ${d['name']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                              Text(
                                '${d['btuCapacity']} BTU \u00b7 \$${d['price']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              doc.reference.delete(),
                          icon: const Icon(Iconsax.trash,
                              size: 18,
                              color: AppTheme.errorColor),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Marcas y Modelos',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Agrega marcas y sus modelos. Se usan en los selectores del cliente y del catálogo.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _BrandManager(
            firestore: widget.firestore,
            onBrandsChanged: _loadBrands,
          ),
          const SizedBox(height: 24),
          Text('Tipos de Equipo',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _EquipmentTypesManager(firestore: widget.firestore),
        ],
      ),
    );
  }

  void _showAddEquipmentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _AddCatalogEquipmentSheet(
          firestore: widget.firestore,
          brands: _brands,
        );
      },
    );
  }
}

class _AddCatalogEquipmentSheet extends StatefulWidget {
  final FirebaseFirestore firestore;
  final List<Map<String, dynamic>> brands;

  const _AddCatalogEquipmentSheet({
    required this.firestore,
    required this.brands,
  });

  @override
  State<_AddCatalogEquipmentSheet> createState() =>
      _AddCatalogEquipmentSheetState();
}

class _AddCatalogEquipmentSheetState
    extends State<_AddCatalogEquipmentSheet> {
  String? _selectedBrand;
  String? _selectedModel;
  int? _selectedBtu;
  List<String> _modelsForBrand = [];
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _warrantyCtrl = TextEditingController(
    text: '5 años en compresor, 1 año en partes y accesorios.',
  );

  static const List<int> _btuOptions = [12000, 18000, 24000, 36000];
  static const Map<int, String> _btuLabels = {
    12000: '12K',
    18000: '18K',
    24000: '24K',
    36000: '36K',
  };

  @override
  void dispose() {
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _warrantyCtrl.dispose();
    super.dispose();
  }

  void _onBrandSelected(String? brand) {
    setState(() {
      _selectedBrand = brand;
      _selectedModel = null;
      _modelsForBrand = [];
    });
    if (brand != null) {
      final brandData = widget.brands.firstWhere(
        (b) => b['name'] == brand,
        orElse: () => <String, dynamic>{},
      );
      final models = brandData['models'];
      if (models is List) {
        setState(() => _modelsForBrand = models.cast<String>());
      }
    }
  }

  bool get _canSave =>
      _selectedBrand != null &&
      _selectedModel != null &&
      _selectedBtu != null &&
      _priceCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('Agregar al Catálogo',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 20),

            Text('Marca',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    )),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBrand,
                  hint: const Text('Seleccionar marca'),
                  isExpanded: true,
                  icon: const Icon(Iconsax.arrow_down_1),
                  items: widget.brands
                      .map((b) => DropdownMenuItem(
                            value: b['name'] as String,
                            child: Text(b['name'] as String),
                          ))
                      .toList(),
                  onChanged: _onBrandSelected,
                ),
              ),
            ),

            const SizedBox(height: 14),

            Text('Modelo',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    )),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedModel,
                  hint: Text(_selectedBrand == null
                      ? 'Selecciona una marca primero'
                      : 'Seleccionar modelo'),
                  isExpanded: true,
                  icon: const Icon(Iconsax.arrow_down_1),
                  items: _modelsForBrand
                      .map((m) =>
                          DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: _selectedBrand == null
                      ? null
                      : (val) => setState(() => _selectedModel = val),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Text('Capacidad',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    )),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _btuOptions.map((btu) {
                final isSelected = _selectedBtu == btu;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBtu = btu),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.12)
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
                      '${_btuLabels[btu]} BTU',
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Precio del equipo',
                prefixIcon: Icon(Iconsax.money, size: 20),
                prefixText: '\$ ',
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText:
                    'Ej: Mini Split inverter de alta eficiencia. Ideal para habitaciones de hasta 20m².',
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _warrantyCtrl,
              decoration: const InputDecoration(
                labelText: 'Garantía del fabricante',
                prefixIcon: Icon(Iconsax.shield_tick, size: 20),
              ),
            ),

            const SizedBox(height: 20),

            FuturisticButton(
              text: 'Agregar al Catálogo',
              icon: Iconsax.add_circle,
              onPressed: _canSave
                  ? () async {
                      await widget.firestore
                          .collection('quoteCatalog')
                          .add({
                        'brand': _selectedBrand,
                        'name': _selectedModel,
                        'type': 'miniSplit',
                        'btuCapacity': _selectedBtu,
                        'price':
                            double.tryParse(_priceCtrl.text) ?? 0,
                        'description': _descCtrl.text.trim(),
                        'manufacturerWarrantyDetails':
                            _warrantyCtrl.text.trim(),
                      });
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Equipo agregado al catálogo'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandManager extends StatefulWidget {
  final FirebaseFirestore firestore;
  final VoidCallback? onBrandsChanged;
  const _BrandManager({required this.firestore, this.onBrandsChanged});

  @override
  State<_BrandManager> createState() => _BrandManagerState();
}

class _BrandManagerState extends State<_BrandManager> {
  final _nc = TextEditingController();
  final _mc = TextEditingController();
  final _oc = TextEditingController(text: '1');

  @override
  void dispose() {
    _nc.dispose();
    _mc.dispose();
    _oc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
            controller: _nc,
            decoration: const InputDecoration(
              labelText: 'Nombre de marca',
              prefixIcon: Icon(Iconsax.tag, size: 20),
            )),
        const SizedBox(height: 10),
        TextField(
            controller: _mc,
            decoration: const InputDecoration(
              labelText: 'Modelos (separados por coma)',
              prefixIcon: Icon(Iconsax.cpu_setting, size: 20),
            )),
        const SizedBox(height: 10),
        TextField(
            controller: _oc,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Orden (1 = primero)',
              prefixIcon: Icon(Iconsax.sort, size: 20),
            )),
        const SizedBox(height: 12),
        FuturisticButton(
          text: 'Guardar Marca',
          icon: Iconsax.tick_circle,
          onPressed: () async {
            final name = _nc.text.trim();
            if (name.isEmpty) return;
            final models = _mc.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            await widget.firestore
                .collection('equipmentCatalog')
                .doc(name.toLowerCase().replaceAll(' ', '_'))
                .set({
              'name': name,
              'models': models,
              'order': int.tryParse(_oc.text) ?? 1,
            });
            if (mounted) {
              _nc.clear();
              _mc.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Marca guardada'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
              widget.onBrandsChanged?.call();
            }
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: widget.firestore
              .collection('equipmentCatalog')
              .orderBy('order')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(d['name'] ?? doc.id,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    )),
                          ),
                          IconButton(
                            onPressed: () =>
                                _showEditBrandDialog(
                                    context, doc.reference, d),
                            icon: const Icon(Iconsax.edit_2,
                                size: 16,
                                color: AppTheme.primaryColor),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              doc.reference.delete();
                              widget.onBrandsChanged?.call();
                            },
                            icon: const Icon(Iconsax.trash,
                                size: 16,
                                color: AppTheme.errorColor),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: ((d['models'] as List?) ?? [])
                            .cast<String>()
                            .map((m) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.08),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(m,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.primaryColor)),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showEditBrandDialog(
    BuildContext context,
    DocumentReference ref,
    Map<String, dynamic> data,
  ) {
    final models =
        ((data['models'] as List?) ?? []).cast<String>().toList();
    final addCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20, 12, 20,
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
                  const SizedBox(height: 16),
                  Text(
                    'Editar ${data['name']}',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: models
                        .map((m) => Chip(
                              label: Text(m),
                              deleteIcon: const Icon(
                                  Iconsax.close_circle, size: 16),
                              onDeleted: () {
                                setSheetState(() => models.remove(m));
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nuevo modelo',
                            prefixIcon:
                                Icon(Iconsax.add_circle, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          final val = addCtrl.text.trim();
                          if (val.isNotEmpty && !models.contains(val)) {
                            setSheetState(() => models.add(val));
                            addCtrl.clear();
                          }
                        },
                        icon: const Icon(Iconsax.tick_circle,
                            color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FuturisticButton(
                    text: 'Guardar Cambios',
                    icon: Iconsax.tick_circle,
                    onPressed: () async {
                      await ref.update({'models': models});
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        widget.onBrandsChanged?.call();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EquipmentTypesManager extends StatefulWidget {
  final FirebaseFirestore firestore;
  const _EquipmentTypesManager({required this.firestore});

  @override
  State<_EquipmentTypesManager> createState() =>
      _EquipmentTypesManagerState();
}

class _EquipmentTypesManagerState
    extends State<_EquipmentTypesManager> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  labelText: 'Nuevo tipo (ej. Mini Split)',
                  prefixIcon: Icon(Iconsax.category, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () async {
                final val = _ctrl.text.trim();
                if (val.isEmpty) return;
                await widget.firestore
                    .collection('config')
                    .doc('equipmentTypes')
                    .set({
                  'types': FieldValue.arrayUnion([val])
                }, SetOptions(merge: true));
                _ctrl.clear();
              },
              icon: const Icon(Iconsax.add_circle,
                  color: AppTheme.primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<DocumentSnapshot>(
          stream: widget.firestore
              .collection('config')
              .doc('equipmentTypes')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final data =
                snapshot.data!.data() as Map<String, dynamic>?;
            final types =
                (data?['types'] as List?)?.cast<String>() ?? [];
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: types.map((t) {
                return Chip(
                  label: Text(t),
                  deleteIcon: const Icon(Iconsax.close_circle,
                      size: 16),
                  onDeleted: () {
                    widget.firestore
                        .collection('config')
                        .doc('equipmentTypes')
                        .update({
                      'types': FieldValue.arrayRemove([t])
                    });
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CompanyTab extends StatefulWidget {
  final FirebaseFirestore firestore;
  const _CompanyTab({required this.firestore});

  @override
  State<_CompanyTab> createState() => _CompanyTabState();
}

class _CompanyTabState extends State<_CompanyTab> {
  final _nc = TextEditingController();
  final _pc = TextEditingController();
  final _wc = TextEditingController();
  final _ec = TextEditingController();
  final _hc = TextEditingController();
  final _twc = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nc.dispose();
    _pc.dispose();
    _wc.dispose();
    _ec.dispose();
    _hc.dispose();
    _twc.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final doc = await widget.firestore
        .collection('company')
        .doc('info')
        .get();
    final d = doc.data();
    if (d != null && mounted) {
      _nc.text = d['name'] ?? '';
      _pc.text = d['phone'] ?? '';
      _wc.text = d['whatsApp'] ?? '';
      _ec.text = d['email'] ?? '';
      _hc.text = d['businessHours'] ?? '';
      _twc.text = d['techWarranty'] ?? '1 año general + 3 meses en electrónicos';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información de la Empresa',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextField(
              controller: _nc,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Iconsax.building, size: 20),
              )),
          const SizedBox(height: 12),
          TextField(
              controller: _pc,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Iconsax.call, size: 20),
              )),
          const SizedBox(height: 12),
          TextField(
              controller: _wc,
              decoration: const InputDecoration(
                labelText: 'WhatsApp',
                prefixIcon: Icon(Iconsax.message, size: 20),
              )),
          const SizedBox(height: 12),
          TextField(
              controller: _ec,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Iconsax.sms, size: 20),
              )),
          const SizedBox(height: 12),
          TextField(
              controller: _hc,
              decoration: const InputDecoration(
                labelText: 'Horario de atención',
                prefixIcon: Icon(Iconsax.clock, size: 20),
              )),
          const SizedBox(height: 12),
          TextField(
              controller: _twc,
              decoration: const InputDecoration(
                labelText: 'Garantía del técnico',
                prefixIcon: Icon(Iconsax.shield_tick, size: 20),
              )),
          const SizedBox(height: 20),
          FuturisticButton(
            text: 'Guardar',
            icon: Iconsax.tick_circle,
            onPressed: () async {
              await widget.firestore
                  .collection('company')
                  .doc('info')
                  .set({
                'name': _nc.text.trim(),
                'phone': _pc.text.trim(),
                'whatsApp': _wc.text.trim(),
                'email': _ec.text.trim(),
                'businessHours': _hc.text.trim(),
                'techWarranty': _twc.text.trim(),
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Información actualizada'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
