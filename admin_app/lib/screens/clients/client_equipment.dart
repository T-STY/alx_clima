import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/sheet_widgets.dart';

class ClientEquipmentStream extends StatelessWidget {
  final String userId;

  const ClientEquipmentStream({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('equipment')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin equipos registrados',
              style: GoogleFonts.exo2(
                fontSize: 13,
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withValues(alpha: 0.5),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.5),
          ),
          child: Column(
            children: List.generate(docs.length, (i) {
              final eqData = docs[i].data() as Map<String, dynamic>;
              return Column(
                children: [
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.1),
                    ),
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Iconsax.cpu,
                      size: 18,
                      color: AdminTheme.secondaryColor,
                    ),
                    title: Text(
                      '${eqData['brand'] ?? ''} ${eqData['equipmentName'] ?? eqData['name'] ?? ''}',
                      style: GoogleFonts.exo2(fontSize: 13),
                    ),
                    subtitle: Text(
                      '${eqData['btuCapacity'] ?? ''} BTU · ${eqData['location'] ?? ''}',
                      style: GoogleFonts.exo2(fontSize: 11),
                    ),
                    trailing: GestureDetector(
                      onTap: () => docs[i].reference.delete(),
                      child: const Icon(
                        Iconsax.trash,
                        size: 16,
                        color: AdminTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}

class AddClientEquipmentButton extends StatelessWidget {
  final String userId;

  const AddClientEquipmentButton({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddEquipmentSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: AdminTheme.primaryGradient,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.add, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'Agregar equipo',
              style: GoogleFonts.exo2(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEquipmentSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? selectedBrand;
    String? selectedModel;
    int? selectedBtu;
    final locationCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return frostedSheet(
            ctx,
            isDark,
            'Agregar equipo',
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('equipmentCatalog')
                  .orderBy('order')
                  .snapshots(),
              builder: (ctx, snap) {
                final brands = snap.data?.docs ?? [];
                final brandNames =
                    brands.map((b) => b['name'] as String).toList();
                final models = <String>[];
                if (selectedBrand != null) {
                  final match =
                      brands.where((b) => b['name'] == selectedBrand);
                  if (match.isNotEmpty) {
                    models.addAll(
                      (match.first['models'] as List).cast<String>(),
                    );
                  }
                }

                final textColor = isDark ? Colors.white : Colors.black;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Marca',
                        style: GoogleFonts.exo2(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedBrand,
                      dropdownColor: Theme.of(ctx).cardColor,
                      menuMaxHeight: 250,
                      decoration: InputDecoration(
                        hintText: 'Seleccionar marca',
                        hintStyle: GoogleFonts.exo2(fontSize: 14),
                        isDense: true,
                      ),
                      style: GoogleFonts.exo2(
                          fontSize: 14, color: textColor),
                      items: brandNames
                          .map((b) => DropdownMenuItem(
                                value: b,
                                child: Text(b,
                                    style: GoogleFonts.exo2(
                                        fontSize: 14,
                                        color: textColor)),
                              ))
                          .toList(),
                      onChanged: (v) => setSt(() {
                        selectedBrand = v;
                        selectedModel = null;
                      }),
                    ),
                    const SizedBox(height: 14),
                    Text('Modelo',
                        style: GoogleFonts.exo2(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedModel,
                      dropdownColor: Theme.of(ctx).cardColor,
                      menuMaxHeight: 250,
                      decoration: InputDecoration(
                        hintText: selectedBrand == null
                            ? 'Selecciona una marca'
                            : 'Seleccionar modelo',
                        hintStyle: GoogleFonts.exo2(fontSize: 14),
                        isDense: true,
                      ),
                      style: GoogleFonts.exo2(
                          fontSize: 14, color: textColor),
                      items: models
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m,
                                    style: GoogleFonts.exo2(
                                        fontSize: 14,
                                        color: textColor)),
                              ))
                          .toList(),
                      onChanged: selectedBrand == null
                          ? null
                          : (v) => setSt(() => selectedModel = v),
                    ),
                    const SizedBox(height: 14),
                    Text('Capacidad (BTU)',
                        style: GoogleFonts.exo2(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [12000, 18000, 24000, 36000].map((btu) {
                        final sel = selectedBtu == btu;
                        final label =
                            '${(btu / 1000).toStringAsFixed(0)}K';
                        return GestureDetector(
                          onTap: () => setSt(() => selectedBtu = btu),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: sel
                                  ? AdminTheme.primaryGradient
                                  : null,
                              color: sel
                                  ? null
                                  : isDark
                                      ? Colors.white
                                          .withValues(alpha: 0.06)
                                      : Colors.white
                                          .withValues(alpha: 0.7),
                              border: sel
                                  ? null
                                  : Border.all(
                                      color: isDark
                                          ? Colors.white
                                              .withValues(alpha: 0.1)
                                          : Colors.black.withValues(
                                              alpha: 0.06),
                                    ),
                            ),
                            child: Text(
                              '$label BTU',
                              style: GoogleFonts.exo2(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: sel ? Colors.white : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text('Ubicación (opcional)',
                        style: GoogleFonts.exo2(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    sheetInput(
                        locationCtrl, 'Ej. Sala, Recámara', isDark),
                    const SizedBox(height: 20),
                    sheetGradientButton('Guardar', () async {
                      if (selectedBrand == null ||
                          selectedModel == null ||
                          selectedBtu == null) return;
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('equipment')
                          .add({
                        'brand': selectedBrand,
                        'equipmentName': selectedModel,
                        'btuCapacity': selectedBtu,
                        'location': locationCtrl.text.trim(),
                        'type': 'miniSplit',
                        'isUserAdded': false,
                        'installDate':
                            FieldValue.serverTimestamp(),
                        'nextServiceDate':
                            Timestamp.fromDate(DateTime.now()
                                .add(const Duration(days: 180))),
                        'installationType': 'fullPackage',
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    }),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
