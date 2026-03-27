import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:alx_clima_admin/config/theme.dart';

class ScheduleDates extends StatelessWidget {
  final FirebaseFirestore firestore;
  const ScheduleDates({super.key, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('schedule').snapshots(),
      builder: (context, snapshot) {
        final docs = (snapshot.data?.docs ?? [])
            .where((d) => d.id.compareTo(today) >= 0)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Sin fechas generadas', style: theme.textTheme.bodyMedium),
          );
        }

        return Container(
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              for (var i = 0; i < docs.length; i++) ...[
                if (i > 0) Divider(height: 1, color: theme.dividerColor),
                _DateRow(doc: docs[i], firestore: firestore),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DateRow extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final FirebaseFirestore firestore;
  const _DateRow({required this.doc, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slots = List<String>.from((doc.data() as Map<String, dynamic>)['slots'] ?? []);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showEditSheet(context, slots),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(doc.id, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color))),
            Text('${slots.length} horarios', style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, List<String> currentSlots) {
    final editSlots = List<String>.from(currentSlots);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HORARIOS: ${doc.id}',
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      letterSpacing: 1.5, color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: editSlots.map((s) {
                      return GestureDetector(
                        onTap: () => setModalState(() => editSlots.remove(s)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(s, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color)),
                              const SizedBox(width: 6),
                              Icon(Icons.close, size: 14, color: AdminTheme.errorColor),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showAddSlotDialog(ctx, editSlots, setModalState),
                        child: Text(
                          'Agregar horario',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminTheme.secondaryColor),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          editSlots.sort((a, b) {
                            final parse = (String s) {
                              final p = s.split(':');
                              return int.parse(p[0]) * 60 + int.parse(p[1]);
                            };
                            return parse(a).compareTo(parse(b));
                          });
                          firestore.collection('schedule').doc(doc.id).update({'slots': editSlots});
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Guardar',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSlotDialog(BuildContext context, List<String> slots, StateSetter setModalState) {
    int hour = 8;
    int minute = 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                'Agregar horario',
                style: TextStyle(fontSize: 14, color: Theme.of(ctx).textTheme.bodyLarge?.color),
              ),
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: hour,
                    dropdownColor: Theme.of(ctx).cardColor,
                    items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text(i.toString().padLeft(2, '0')))),
                    onChanged: (v) => setDialogState(() => hour = v ?? hour),
                  ),
                  const Text(' : '),
                  DropdownButton<int>(
                    value: minute,
                    dropdownColor: Theme.of(ctx).cardColor,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('00')),
                      DropdownMenuItem(value: 30, child: Text('30')),
                    ],
                    onChanged: (v) => setDialogState(() => minute = v ?? minute),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color)),
                ),
                TextButton(
                  onPressed: () {
                    final slot = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                    if (!slots.contains(slot)) {
                      setModalState(() => slots.add(slot));
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text('Agregar', style: TextStyle(color: AdminTheme.primaryColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
