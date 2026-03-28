import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/sheet_widgets.dart';

void showManualAppointmentSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  String? selectedServiceType;
  String? selectedDate;
  String? selectedSlot;
  Map<String, List<String>> availableSlots = {};
  List<_ManualEquipment> equipmentList = [_ManualEquipment()];
  bool isLoading = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) {
        if (availableSlots.isEmpty && !isLoading) {
          isLoading = true;
          FirebaseFirestore.instance.collection('schedule').get().then((snap) {
            final slots = <String, List<String>>{};
            for (final doc in snap.docs) {
              final s = (doc.data()['slots'] as List?)?.cast<String>() ?? [];
              if (s.isNotEmpty) slots[doc.id] = s;
            }
            setSt(() {
              availableSlots = slots;
              isLoading = false;
            });
          });
        }

        final sortedDates = availableSlots.keys.toList()..sort();
        final dateSlots = selectedDate != null
            ? (availableSlots[selectedDate] ?? [])
            : <String>[];

        return frostedSheet(
          ctx,
          isDark,
          'Nueva Cita Manual',
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Datos del cliente',
                  style: GoogleFonts.exo2(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AdminTheme.primaryColor)),
              const SizedBox(height: 8),
              sheetInput(nameCtrl, 'Nombre completo', isDark),
              const SizedBox(height: 8),
              sheetInput(phoneCtrl, 'Teléfono', isDark,
                  keyboard: TextInputType.phone),
              const SizedBox(height: 8),
              sheetInput(emailCtrl, 'Correo (opcional)', isDark,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 8),
              sheetInput(addressCtrl, 'Dirección', isDark),
              const SizedBox(height: 16),

              Text('Tipo de servicio',
                  style: GoogleFonts.exo2(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AdminTheme.primaryColor)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ('installation', 'Instalación'),
                  ('maintenance', 'Mantenimiento'),
                  ('removal', 'Retiro'),
                  ('relocation', 'Reubicación'),
                ].map((e) {
                  final sel = selectedServiceType == e.$1;
                  return GestureDetector(
                    onTap: () => setSt(() => selectedServiceType = e.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: sel ? AdminTheme.primaryGradient : null,
                        color: sel
                            ? null
                            : isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.white.withValues(alpha: 0.7),
                        border: sel
                            ? null
                            : Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                      ),
                      child: Text(
                        e.$2,
                        style: GoogleFonts.exo2(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: sel ? Colors.white : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              Text('Equipos',
                  style: GoogleFonts.exo2(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AdminTheme.primaryColor)),
              const SizedBox(height: 8),
              ...equipmentList.asMap().entries.map((entry) {
                final i = entry.key;
                final eq = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: eq.brandCtrl,
                          style: GoogleFonts.exo2(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Marca',
                            hintStyle: GoogleFonts.exo2(fontSize: 12),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: eq.modelCtrl,
                          style: GoogleFonts.exo2(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Modelo',
                            hintStyle: GoogleFonts.exo2(fontSize: 12),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: eq.btuCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.exo2(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'BTU',
                            hintStyle: GoogleFonts.exo2(fontSize: 12),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                      if (equipmentList.length > 1)
                        GestureDetector(
                          onTap: () => setSt(() => equipmentList.removeAt(i)),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Iconsax.close_circle,
                                size: 16, color: AdminTheme.errorColor),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              GestureDetector(
                onTap: () =>
                    setSt(() => equipmentList.add(_ManualEquipment())),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.add_circle,
                        size: 14, color: AdminTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text('Agregar equipo',
                        style: GoogleFonts.exo2(
                            fontSize: 12,
                            color: AdminTheme.primaryColor,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text('Fecha y horario',
                  style: GoogleFonts.exo2(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AdminTheme.primaryColor)),
              const SizedBox(height: 8),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (sortedDates.isEmpty)
                Text('Sin disponibilidad',
                    style: GoogleFonts.exo2(fontSize: 12))
              else ...[
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: sortedDates.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final d = sortedDates[i];
                      final sel = selectedDate == d;
                      return GestureDetector(
                        onTap: () => setSt(() {
                          selectedDate = d;
                          selectedSlot = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: sel ? AdminTheme.primaryGradient : null,
                            color: sel
                                ? null
                                : isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.white.withValues(alpha: 0.7),
                          ),
                          child: Text(d.substring(5),
                              style: GoogleFonts.exo2(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: sel ? Colors.white : null)),
                        ),
                      );
                    },
                  ),
                ),
                if (dateSlots.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: dateSlots.map((s) {
                      final sel = selectedSlot == s;
                      return GestureDetector(
                        onTap: () => setSt(() => selectedSlot = s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: sel
                                ? AdminTheme.primaryColor.withValues(alpha: 0.2)
                                : isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.white.withValues(alpha: 0.5),
                            border: sel
                                ? Border.all(color: AdminTheme.primaryColor)
                                : null,
                          ),
                          child: Text(s,
                              style: GoogleFonts.exo2(
                                  fontSize: 11,
                                  color: sel
                                      ? AdminTheme.primaryColor
                                      : null)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              sheetInput(notesCtrl, 'Notas (opcional)', isDark),
              const SizedBox(height: 20),
              sheetGradientButton('Agendar Cita', () async {
                if (nameCtrl.text.trim().isEmpty ||
                    selectedServiceType == null ||
                    selectedDate == null ||
                    selectedSlot == null) return;

                final serviceLabels = {
                  'installation': 'Instalación',
                  'maintenance': 'Mantenimiento',
                  'removal': 'Retiro',
                  'relocation': 'Reubicación',
                };

                final eqList = equipmentList
                    .where((e) => e.brandCtrl.text.trim().isNotEmpty)
                    .map((e) => {
                          'brand': e.brandCtrl.text.trim(),
                          'name': e.modelCtrl.text.trim(),
                          'btuCapacity':
                              int.tryParse(e.btuCtrl.text) ?? 0,
                          'location': '',
                          'type': 'Mini Split',
                          'price': 0,
                        })
                    .toList();

                final aptId = 'manual-${DateTime.now().millisecondsSinceEpoch}';

                await FirebaseFirestore.instance
                    .collection('appointments')
                    .add({
                  'appointmentId': aptId,
                  'userId': null,
                  'status': 'confirmed',
                  'date': selectedDate,
                  'timeSlots': [selectedSlot],
                  'timeSlotDisplay': selectedSlot,
                  'serviceType': selectedServiceType,
                  'serviceTypeDisplay':
                      serviceLabels[selectedServiceType] ?? selectedServiceType,
                  'notes': notesCtrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'equipmentCount': eqList.length,
                  'customer': {
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'address': addressCtrl.text.trim(),
                  },
                  'equipment': eqList,
                  'totalUserEquipment': eqList.length,
                  'isManual': true,
                });

                final schedRef = FirebaseFirestore.instance
                    .collection('schedule')
                    .doc(selectedDate);
                final schedDoc = await schedRef.get();
                if (schedDoc.exists) {
                  final existing =
                      (schedDoc.data()?['slots'] as List?)?.cast<String>() ??
                          [];
                  existing.remove(selectedSlot);
                  if (existing.isEmpty) {
                    await schedRef.delete();
                  } else {
                    await schedRef.update({'slots': existing});
                  }
                }

                await FirebaseFirestore.instance
                    .collection('bookedSlots')
                    .add({
                  'date': selectedDate,
                  'slot': selectedSlot,
                  'userId': 'manual',
                  'bookedAt': FieldValue.serverTimestamp(),
                });

                if (ctx.mounted) Navigator.pop(ctx);
              }),
            ],
          ),
        );
      },
    ),
  );
}

class _ManualEquipment {
  final brandCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final btuCtrl = TextEditingController();
}
