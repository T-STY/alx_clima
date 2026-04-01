import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/sheet_widgets.dart';

void showManualAppointmentSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  String? selectedServiceType = 'maintenance';
  String? selectedDate;
  String? selectedSlot;
  Map<String, List<String>> availableSlots = {};
  List<_EquipmentEntry> equipmentList = [_EquipmentEntry()];
  bool slotsLoaded = false;
  List<Map<String, dynamic>> brands = [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) {
        if (!slotsLoaded) {
          slotsLoaded = true;
          Future.wait([
            FirebaseFirestore.instance.collection('schedule').get(),
            FirebaseFirestore.instance.collection('equipmentCatalog').orderBy('order').get(),
          ]).then((results) {
            final schedSnap = results[0];
            final brandSnap = results[1];
            final slots = <String, List<String>>{};
            for (final doc in schedSnap.docs) {
              final s = (doc.data()['slots'] as List?)?.cast<String>() ?? [];
              if (s.isNotEmpty) slots[doc.id] = s;
            }
            final sortedKeys = slots.keys.toList()..sort();
            setSt(() {
              availableSlots = slots;
              if (sortedKeys.isNotEmpty) selectedDate = sortedKeys.first;
              brands = brandSnap.docs.map((d) {
                final data = d.data();
                data['id'] = d.id;
                return data;
              }).toList();
            });
          });
        }

        final slotsNeeded = equipmentList.length;
        final sortedDates = availableSlots.keys.toList()..sort();
        final dateSlots = selectedDate != null ? (availableSlots[selectedDate] ?? []) : <String>[];

        final windows = <Map<String, dynamic>>[];
        if (slotsNeeded <= 1) {
          for (final s in dateSlots) {
            windows.add({'display': s, 'slots': [s]});
          }
        } else {
          for (var i = 0; i <= dateSlots.length - slotsNeeded; i++) {
            bool consecutive = true;
            for (var j = 0; j < slotsNeeded - 1; j++) {
              final curEnd = dateSlots[i + j].split(' - ').last.trim();
              final nextStart = dateSlots[i + j + 1].split(' - ').first.trim();
              if (curEnd != nextStart) { consecutive = false; break; }
            }
            if (consecutive) {
              final start = dateSlots[i].split(' - ').first.trim();
              final end = dateSlots[i + slotsNeeded - 1].split(' - ').last.trim();
              windows.add({
                'display': '$start - $end',
                'slots': dateSlots.sublist(i, i + slotsNeeded),
              });
            }
          }
        }

        final textColor = isDark ? Colors.white : Colors.black;
        final brandNames = brands.map((b) => b['name'] as String).toList();

        return frostedSheet(ctx, isDark, 'Nueva Cita', Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Buscar cliente existente'),
            const SizedBox(height: 6),
            Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (opt) => opt['name'] ?? '',
              optionsBuilder: (textEditingValue) async {
                if (textEditingValue.text.length < 2) return [];
                final snap = await FirebaseFirestore.instance.collection('users').get();
                final query = textEditingValue.text.toLowerCase();
                return snap.docs
                    .map((d) => d.data()..['uid'] = d.id)
                    .where((u) => (u['name'] ?? '').toString().toLowerCase().contains(query))
                    .take(5);
              },
              onSelected: (client) {
                setSt(() {
                  nameCtrl.text = client['name'] ?? '';
                  phoneCtrl.text = client['phone'] ?? '';
                  emailCtrl.text = client['email'] ?? '';
                  final parts = <String>[];
                  if ((client['street'] ?? '').toString().isNotEmpty) {
                    var line = client['street'];
                    if ((client['exteriorNumber'] ?? '').toString().isNotEmpty) line += ' #${client['exteriorNumber']}';
                    parts.add(line);
                  }
                  if ((client['colonia'] ?? '').toString().isNotEmpty) parts.add('Col. ${client['colonia']}');
                  if ((client['city'] ?? '').toString().isNotEmpty) parts.add(client['city']);
                  if ((client['state'] ?? '').toString().isNotEmpty) parts.add(client['state']);
                  if ((client['postalCode'] ?? '').toString().isNotEmpty) parts.add('C.P. ${client['postalCode']}');
                  addressCtrl.text = parts.join(', ');
                });
              },
              fieldViewBuilder: (ctx2, ctrl, focusNode, onSubmit) {
                return TextField(
                  controller: ctrl,
                  focusNode: focusNode,
                  style: GoogleFonts.exo2(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre...',
                    hintStyle: GoogleFonts.exo2(fontSize: 13),
                    prefixIcon: const Icon(Iconsax.search_normal, size: 16),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _label('Datos del cliente'),
            const SizedBox(height: 6),
            sheetInput(nameCtrl, 'Nombre completo', isDark),
            const SizedBox(height: 8),
            sheetInput(phoneCtrl, 'Teléfono', isDark, keyboard: TextInputType.phone),
            const SizedBox(height: 8),
            sheetInput(emailCtrl, 'Correo (opcional)', isDark, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 8),
            sheetInput(addressCtrl, 'Dirección', isDark),
            const SizedBox(height: 14),

            _label('Tipo de servicio'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                ('installation', 'Instalación'), ('maintenance', 'Mantenimiento'),
                ('removal', 'Retiro'), ('relocation', 'Reubicación'),
              ].map((e) {
                final sel = selectedServiceType == e.$1;
                return GestureDetector(
                  onTap: () => setSt(() => selectedServiceType = e.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: sel ? AdminTheme.primaryGradient : null,
                      color: sel ? null : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.7),
                      border: sel ? null : Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Text(e.$2, style: GoogleFonts.exo2(fontSize: 12, fontWeight: FontWeight.w500, color: sel ? Colors.white : null)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(child: _label('Equipos (${equipmentList.length})')),
                GestureDetector(
                  onTap: () => setSt(() {
                    equipmentList.add(_EquipmentEntry());
                    selectedSlot = null;
                  }),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Iconsax.add_circle, size: 14, color: AdminTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text('Agregar', style: GoogleFonts.exo2(fontSize: 11, color: AdminTheme.primaryColor, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...equipmentList.asMap().entries.map((entry) {
              final i = entry.key;
              final eq = entry.value;
              final models = eq.selectedBrand != null
                  ? ((brands.where((b) => b['name'] == eq.selectedBrand).firstOrNull?['models'] as List?) ?? []).cast<String>()
                  : <String>[];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Equipo ${i + 1}', style: GoogleFonts.exo2(fontSize: 11, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        if (equipmentList.length > 1)
                          GestureDetector(
                            onTap: () => setSt(() { equipmentList.removeAt(i); selectedSlot = null; }),
                            child: const Icon(Iconsax.close_circle, size: 14, color: AdminTheme.errorColor),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: eq.selectedBrand,
                      dropdownColor: Theme.of(ctx).cardColor,
                      menuMaxHeight: 200,
                      decoration: InputDecoration(hintText: 'Marca', hintStyle: GoogleFonts.exo2(fontSize: 13), isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      style: GoogleFonts.exo2(fontSize: 13, color: textColor),
                      items: brandNames.map((b) => DropdownMenuItem(value: b, child: Text(b, style: GoogleFonts.exo2(fontSize: 13, color: textColor)))).toList(),
                      onChanged: (v) => setSt(() { eq.selectedBrand = v; eq.selectedModel = null; }),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: eq.selectedModel,
                      dropdownColor: Theme.of(ctx).cardColor,
                      menuMaxHeight: 200,
                      decoration: InputDecoration(hintText: eq.selectedBrand == null ? 'Selecciona marca' : 'Modelo',
                          hintStyle: GoogleFonts.exo2(fontSize: 13), isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      style: GoogleFonts.exo2(fontSize: 13, color: textColor),
                      items: models.map((m) => DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.exo2(fontSize: 13, color: textColor)))).toList(),
                      onChanged: eq.selectedBrand == null ? null : (v) => setSt(() => eq.selectedModel = v),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: [12000, 18000, 24000, 36000].map((btu) {
                        final sel = eq.selectedBtu == btu;
                        return GestureDetector(
                          onTap: () => setSt(() => eq.selectedBtu = btu),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: sel ? AdminTheme.primaryGradient : null,
                              color: sel ? null : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.7),
                              border: sel ? null : Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
                            ),
                            child: Text('${(btu / 1000).toStringAsFixed(0)}K', style: GoogleFonts.exo2(fontSize: 11, fontWeight: FontWeight.w500, color: sel ? Colors.white : null)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),

            _label('Fecha y horario${slotsNeeded > 1 ? ' ($slotsNeeded hrs)' : ''}'),
            const SizedBox(height: 6),
            if (sortedDates.isEmpty)
              Text('Sin disponibilidad', style: GoogleFonts.exo2(fontSize: 12))
            else ...[
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sortedDates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final d = sortedDates[i];
                    final sel = selectedDate == d;
                    return GestureDetector(
                      onTap: () => setSt(() { selectedDate = d; selectedSlot = null; }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: sel ? AdminTheme.primaryGradient : null,
                          color: sel ? null : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.7),
                        ),
                        child: Text(d.substring(5), style: GoogleFonts.exo2(fontSize: 12, fontWeight: FontWeight.w500, color: sel ? Colors.white : null)),
                      ),
                    );
                  },
                ),
              ),
              if (windows.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: windows.map((w) {
                    final display = w['display'] as String;
                    final sel = selectedSlot == display;
                    return GestureDetector(
                      onTap: () => setSt(() => selectedSlot = display),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: sel ? AdminTheme.primaryColor.withValues(alpha: 0.2) : isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.5),
                          border: sel ? Border.all(color: AdminTheme.primaryColor) : null,
                        ),
                        child: Text(display, style: GoogleFonts.exo2(fontSize: 11, color: sel ? AdminTheme.primaryColor : null)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
            const SizedBox(height: 10),
            sheetInput(notesCtrl, 'Notas (opcional)', isDark),
            const SizedBox(height: 16),
            sheetGradientButton('Agendar Cita', () async {
              if (nameCtrl.text.trim().isEmpty || selectedServiceType == null || selectedDate == null || selectedSlot == null) return;

              final sLabels = {'installation': 'Instalación', 'maintenance': 'Mantenimiento', 'removal': 'Retiro', 'relocation': 'Reubicación'};
              final eqList = equipmentList.where((e) => e.selectedBrand != null).map((e) => {
                'brand': e.selectedBrand ?? '', 'name': e.selectedModel ?? '', 'btuCapacity': e.selectedBtu ?? 0,
                'location': '', 'type': 'Mini Split', 'price': 0,
              }).toList();

              final selectedWindow = windows.where((w) => w['display'] == selectedSlot).firstOrNull;
              final slotsToBook = (selectedWindow?['slots'] as List?)?.cast<String>() ?? [selectedSlot!];

              final aptId = 'apt-${DateTime.now().millisecondsSinceEpoch}';
              await FirebaseFirestore.instance.collection('appointments').add({
                'appointmentId': aptId, 'userId': null, 'status': 'confirmed',
                'date': selectedDate, 'timeSlots': slotsToBook, 'timeSlotDisplay': selectedSlot,
                'serviceType': selectedServiceType, 'serviceTypeDisplay': sLabels[selectedServiceType] ?? selectedServiceType,
                'notes': notesCtrl.text.trim(), 'createdAt': FieldValue.serverTimestamp(),
                'equipmentCount': eqList.length,
                'customer': {'name': nameCtrl.text.trim(), 'phone': phoneCtrl.text.trim(), 'email': emailCtrl.text.trim(), 'address': addressCtrl.text.trim()},
                'equipment': eqList, 'totalUserEquipment': eqList.length, 'isManual': true,
              });

              final schedRef = FirebaseFirestore.instance.collection('schedule').doc(selectedDate);
              final schedDoc = await schedRef.get();
              if (schedDoc.exists) {
                final existing = (schedDoc.data()?['slots'] as List?)?.cast<String>() ?? [];
                for (final s in slotsToBook) { existing.remove(s); }
                if (existing.isEmpty) { await schedRef.delete(); } else { await schedRef.update({'slots': existing}); }
              }
              for (final s in slotsToBook) {
                await FirebaseFirestore.instance.collection('bookedSlots').add({
                  'date': selectedDate, 'slot': s, 'userId': 'manual', 'bookedAt': FieldValue.serverTimestamp(),
                });
              }
              if (ctx.mounted) Navigator.pop(ctx);
            }),
          ],
        ));
      },
    ),
  );
}

Widget _label(String text) => Text(text, style: GoogleFonts.exo2(fontSize: 13, fontWeight: FontWeight.w600, color: AdminTheme.primaryColor));

class _EquipmentEntry {
  String? selectedBrand;
  String? selectedModel;
  int? selectedBtu;
}
