import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'appointment_actions.dart';
import 'appointment_reschedule.dart';

void showAppointmentDetail(BuildContext context, QueryDocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final customer = data['customer'] as Map<String, dynamic>? ?? {};
  final status = data['status'] ?? '';
  final info = statusInfo(status);
  final equipment = parseEquipment(data);
  final isDark = Theme.of(context).brightness == Brightness.dark;

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
            maxHeight: MediaQuery.of(ctx).size.height * 0.92,
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: info.$1.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            info.$2,
                            style: GoogleFonts.exo2(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: info.$1,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          data['date'] ?? '',
                          style: GoogleFonts.exo2(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _infoRow(Iconsax.user, customer['name'] ?? ''),
                    _infoRow(Iconsax.call, customer['phone'] ?? ''),
                    _infoRow(Iconsax.sms, customer['email'] ?? ''),
                    _infoRow(Iconsax.location, customer['address'] ?? ''),
                    const SizedBox(height: 16),
                    _infoRow(Iconsax.clock, data['timeSlotDisplay'] ?? ''),
                    _infoRow(
                      Iconsax.setting_2,
                      data['serviceTypeDisplay'] ??
                          data['serviceType'] ??
                          '',
                    ),
                    if ((data['notes'] ?? '').toString().isNotEmpty)
                      _infoRow(Iconsax.note_1, data['notes']),
                    if (equipment.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Equipos',
                        style: GoogleFonts.exo2(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...equipment.map((eq) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Iconsax.cpu,
                                  size: 16,
                                  color: AdminTheme.secondaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${eq['brand'] ?? ''} ${eq['name'] ?? ''} · ${eq['btuCapacity'] ?? ''} BTU',
                                    style: GoogleFonts.exo2(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                    const SizedBox(height: 24),
                    _buildActions(ctx, doc, status),
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

Widget _infoRow(IconData icon, String text) {
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

Widget _buildActions(
  BuildContext context,
  QueryDocumentSnapshot doc,
  String status,
) {
  final actions = <Widget>[];
  final isDark = Theme.of(context).brightness == Brightness.dark;

  if (status == 'pending') {
    actions.addAll([
      _gradientButton('Confirmar', Iconsax.tick_circle, () async {
        await doc.reference.update({'status': 'confirmed'});
        if (context.mounted) Navigator.pop(context);
      }),
      const SizedBox(height: 10),
      _glassButton(isDark, 'Reagendar', Iconsax.calendar_edit, () {
        Navigator.pop(context);
        rescheduleAppointment(context, doc);
      }),
      const SizedBox(height: 10),
      _glassButton(isDark, 'Cancelar', Iconsax.close_circle, () async {
        await cancelAppointment(doc);
        if (context.mounted) Navigator.pop(context);
      }),
    ]);
  } else if (status == 'confirmed') {
    actions.addAll([
      _gradientButton('Completar', Iconsax.verify, () async {
        await completeAppointment(doc);
        if (context.mounted) Navigator.pop(context);
      }),
      const SizedBox(height: 10),
      _glassButton(isDark, 'Cancelar', Iconsax.close_circle, () async {
        await cancelAppointment(doc);
        if (context.mounted) Navigator.pop(context);
      }),
    ]);
  } else if (status == 'completed' || status == 'cancelled') {
    actions.add(
      _glassButton(isDark, 'Eliminar', Iconsax.trash, () async {
        await doc.reference.delete();
        if (context.mounted) Navigator.pop(context);
      }),
    );
  }

  return Column(children: actions);
}

Widget _gradientButton(
  String label,
  IconData icon,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: AdminTheme.primaryGradient,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.exo2(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _glassButton(
  bool isDark,
  String label,
  IconData icon,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.7),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.exo2(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
