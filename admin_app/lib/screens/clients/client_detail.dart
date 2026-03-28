import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'client_equipment.dart';

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
                    _row(Iconsax.location, _buildAddress(data)),
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
                    ClientEquipmentStream(userId: doc.id),
                    const SizedBox(height: 16),
                    AddClientEquipmentButton(userId: doc.id),
                    const SizedBox(height: 24),
                    Text(
                      'Facturas',
                      style: GoogleFonts.exo2(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ClientInvoices(userId: doc.id),
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
              color: _suspended
                  ? AdminTheme.errorColor
                  : AdminTheme.successColor,
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

class _ClientInvoices extends StatelessWidget {
  final String userId;
  const _ClientInvoices({required this.userId});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Text(
            'Sin facturas',
            style: GoogleFonts.exo2(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final total = (data['total'] as num?)?.toDouble() ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () {
                  final pdfBase64 = data['pdfBase64'] as String?;
                  if (pdfBase64 == null || pdfBase64.isEmpty) return;
                  final bytes = Uint8List.fromList(base64Decode(pdfBase64));
                  Printing.layoutPdf(onLayout: (_) async => bytes);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.document_text,
                          size: 14, color: AdminTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['date'] ?? '',
                          style: GoogleFonts.exo2(fontSize: 13),
                        ),
                      ),
                      Text(
                        fmt.format(total),
                        style: GoogleFonts.exo2(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AdminTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
