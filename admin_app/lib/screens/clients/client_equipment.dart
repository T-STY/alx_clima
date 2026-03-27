import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';

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
                      '${eqData['brand'] ?? ''} ${eqData['name'] ?? ''}',
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
      onTap: () => _showAddEquipmentDialog(context),
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

  void _showAddEquipmentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final btuCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Agregar equipo',
          style: GoogleFonts.exo2(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: brandCtrl,
                style: GoogleFonts.exo2(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Marca',
                  hintStyle: GoogleFonts.exo2(fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.exo2(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Modelo',
                  hintStyle: GoogleFonts.exo2(fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: btuCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.exo2(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'BTU',
                  hintStyle: GoogleFonts.exo2(fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationCtrl,
                style: GoogleFonts.exo2(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ubicación',
                  hintStyle: GoogleFonts.exo2(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.exo2(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('equipment')
                  .add({
                'brand': brandCtrl.text.trim(),
                'name': nameCtrl.text.trim(),
                'btuCapacity': int.tryParse(btuCtrl.text) ?? 0,
                'location': locationCtrl.text.trim(),
                'type': 'miniSplit',
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(
              'Guardar',
              style: GoogleFonts.exo2(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AdminTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
