import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';

void showClientDetail(BuildContext context, DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final suspended = data['suspended'] == true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0B0D14).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      data['name'] ?? 'Cliente',
                      style: GoogleFonts.exo2(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _row(Iconsax.call, data['phone'] ?? ''),
                    _row(Iconsax.sms, data['email'] ?? ''),
                    _row(
                      Iconsax.location,
                      _buildAddress(data),
                    ),
                    const SizedBox(height: 20),
                    _SuspendToggle(
                      docRef: doc.reference,
                      suspended: suspended,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Equipos del cliente',
                      style: GoogleFonts.exo2(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _EquipmentStream(userId: doc.id),
                    const SizedBox(height: 16),
                    _AddEquipmentButton(userId: doc.id),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _buildAddress(Map<String, dynamic> data) {
  final parts = [
    data['street'],
    data['exteriorNumber'],
    data['colonia'],
    data['city'],
    data['state'],
    data['postalCode'],
  ].where((p) => p != null && p.toString().isNotEmpty);
  return parts.join(', ');
}

Widget _row(IconData icon, String text) {
  if (text.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AdminTheme.primaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: GoogleFonts.exo2(fontSize: 13)),
        ),
      ],
    ),
  );
}

class _SuspendToggle extends StatefulWidget {
  final DocumentReference docRef;
  final bool suspended;

  const _SuspendToggle({
    required this.docRef,
    required this.suspended,
  });

  @override
  State<_SuspendToggle> createState() => _SuspendToggleState();
}

class _SuspendToggleState extends State<_SuspendToggle> {
  late bool _suspended;

  @override
  void initState() {
    super.initState();
    _suspended = widget.suspended;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        final newVal = !_suspended;
        await widget.docRef.update({'suspended': newVal});
        setState(() => _suspended = newVal);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _suspended
              ? AdminTheme.errorColor.withValues(alpha: 0.12)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.7),
          border: Border.all(
            color: _suspended
                ? AdminTheme.errorColor.withValues(alpha: 0.3)
                : isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _suspended ? Iconsax.lock : Iconsax.unlock,
              size: 18,
              color:
                  _suspended ? AdminTheme.errorColor : AdminTheme.successColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _suspended ? 'Cliente suspendido' : 'Cliente activo',
                style: GoogleFonts.exo2(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _suspended ? AdminTheme.errorColor : null,
                ),
              ),
            ),
            Text(
              _suspended ? 'Reactivar' : 'Suspender',
              style: GoogleFonts.exo2(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _suspended
                    ? AdminTheme.successColor
                    : AdminTheme.errorColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentStream extends StatelessWidget {
  final String userId;

  const _EquipmentStream({required this.userId});

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

class _AddEquipmentButton extends StatelessWidget {
  final String userId;

  const _AddEquipmentButton({required this.userId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddEquipmentDialog(context, userId),
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

  void _showAddEquipmentDialog(BuildContext context, String uid) {
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
          style: GoogleFonts.exo2(fontSize: 16, fontWeight: FontWeight.w600),
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
                  .doc(uid)
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
