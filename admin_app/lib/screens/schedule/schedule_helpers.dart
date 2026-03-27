import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

Widget buildHourDropdown(
  BuildContext context,
  int value,
  ValueChanged<int?> onChanged,
) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: theme.dividerColor),
    ),
    child: DropdownButton<int>(
      value: value,
      isExpanded: true,
      underline: const SizedBox(),
      dropdownColor: theme.cardColor,
      items: List.generate(24, (i) {
        return DropdownMenuItem(
          value: i,
          child: Text('${i.toString().padLeft(2, '0')}:00'),
        );
      }),
      onChanged: onChanged,
    ),
  );
}

String formatDateLabel(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    final raw = DateFormat('EEEE dd MMM yyyy', 'es').format(date);
    final parts = raw.split(' ');
    if (parts.isNotEmpty) {
      parts[0] = '${parts[0][0].toUpperCase()}${parts[0].substring(1)}';
    }
    return parts.join(' ');
  } catch (_) {
    return dateStr;
  }
}

void showEditDateSheet(
  BuildContext context,
  FirebaseFirestore firestore,
  String dateId,
  List<String> currentSlots,
) {
  final slots = List<String>.from(currentSlots)..sort();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(ctx);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Editar $dateId',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: slots.map((slot) {
                    return Chip(
                      label: Text(slot, style: const TextStyle(fontSize: 13)),
                      deleteIcon: const Icon(
                        Iconsax.close_circle,
                        size: 16,
                        color: AdminTheme.errorColor,
                      ),
                      onDeleted: () {
                        setSheetState(() => slots.remove(slot));
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                AdminButton(
                  text: 'Agregar Horario',
                  icon: Iconsax.add,
                  isOutlined: true,
                  onPressed: () async {
                    final startTime = await showTimePicker(
                      context: ctx,
                      initialTime: const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (startTime == null) return;
                    final endTime = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay(
                        hour: startTime.hour + 1,
                        minute: 0,
                      ),
                    );
                    if (endTime == null) return;
                    final startStr =
                        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                    final endStr =
                        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
                    final newSlot = '$startStr - $endStr';
                    setSheetState(() {
                      if (!slots.contains(newSlot)) {
                        slots.add(newSlot);
                        slots.sort();
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                AdminButton(
                  text: 'Guardar',
                  icon: Iconsax.tick_circle,
                  onPressed: () async {
                    await firestore
                        .collection('schedule')
                        .doc(dateId)
                        .update({'slots': slots});
                    if (ctx.mounted) Navigator.pop(ctx);
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
