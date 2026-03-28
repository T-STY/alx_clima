import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:printing/printing.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'appointment_actions.dart';
import 'invoice_pdf_builder.dart';

Future<void> invoiceAndComplete(
  BuildContext context,
  QueryDocumentSnapshot doc,
) async {
  final data = doc.data() as Map<String, dynamic>;
  final customer = data['customer'] as Map<String, dynamic>? ?? {};
  final equipment = parseEquipment(data);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final estimated = data['estimatedCost'] ?? data['quoteBreakdown']?['totalPrice'] ?? 0;
  final costCtrl = TextEditingController(text: '$estimated');
  final notesCtrl = TextEditingController();

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _InvoiceConfirmSheet(
      data: data,
      customer: customer,
      equipment: equipment,
      costCtrl: costCtrl,
      notesCtrl: notesCtrl,
      isDark: isDark,
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final total = double.tryParse(costCtrl.text) ?? 0;
  final notes = notesCtrl.text;
  final pdfBytes =
      await buildInvoicePdf(data, customer, equipment, total, notes);
  final pdfBase64 = base64Encode(pdfBytes);

  await FirebaseFirestore.instance.collection('invoices').add({
    'appointmentId': data['appointmentId'] ?? doc.id,
    'userId': data['userId'] ?? '',
    'date': data['date'] ?? '',
    'customerName': customer['name'] ?? '',
    'items': equipment
        .map((e) => {
              'brand': e['brand'] ?? '',
              'model': e['name'] ?? '',
              'btu': e['btuCapacity'] ?? 0,
            })
        .toList(),
    'total': total,
    'notes': notes,
    'pdfBase64': pdfBase64,
    'createdAt': FieldValue.serverTimestamp(),
  });

  await completeAppointment(doc);

  if (!context.mounted) return;

  final shouldPrint = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(ctx).cardColor,
      title: Text(
        'Factura generada',
        style: GoogleFonts.exo2(fontWeight: FontWeight.w600),
      ),
      content: Text(
        'La cita fue completada y la factura guardada.',
        style: GoogleFonts.exo2(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cerrar', style: GoogleFonts.exo2()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Imprimir / Compartir',
            style: GoogleFonts.exo2(color: AdminTheme.primaryColor),
          ),
        ),
      ],
    ),
  );

  if (shouldPrint == true && context.mounted) {
    await Printing.layoutPdf(
      onLayout: (_) async => Uint8List.fromList(pdfBytes),
    );
  }
}

class _InvoiceConfirmSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> customer;
  final List<Map<String, dynamic>> equipment;
  final TextEditingController costCtrl;
  final TextEditingController notesCtrl;
  final bool isDark;

  const _InvoiceConfirmSheet({
    required this.data,
    required this.customer,
    required this.equipment,
    required this.costCtrl,
    required this.notesCtrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0B0D14).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
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
            const SizedBox(height: 16),
            Text(
              'Completar y facturar',
              style: GoogleFonts.exo2(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                children: [
                  _row(Iconsax.user, customer['name'] ?? ''),
                  _row(Iconsax.call, customer['phone'] ?? ''),
                  _row(Iconsax.sms, customer['email'] ?? ''),
                  _row(Iconsax.location, customer['address'] ?? ''),
                  const SizedBox(height: 8),
                  _row(Iconsax.setting_2, data['serviceTypeDisplay'] ?? ''),
                  _row(Iconsax.clock, data['timeSlotDisplay'] ?? ''),
                  _row(Iconsax.calendar_1, data['date'] ?? ''),
                  const SizedBox(height: 8),
                  Text(
                    'Equipos',
                    style: GoogleFonts.exo2(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...equipment.map(
                    (eq) => _row(
                      Iconsax.cpu,
                      '${eq['brand'] ?? ''} ${eq['name'] ?? ''} · ${eq['btuCapacity'] ?? ''} BTU',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: costCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.exo2(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Costo total (\$)',
                      labelStyle: GoogleFonts.exo2(fontSize: 13),
                      prefixText: '\$ ',
                      prefixStyle: GoogleFonts.exo2(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    style: GoogleFonts.exo2(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Notas adicionales',
                      labelStyle: GoogleFonts.exo2(fontSize: 13),
                      hintText: 'Observaciones del servicio...',
                      hintStyle: GoogleFonts.exo2(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
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
                          const Icon(
                            Iconsax.verify,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Confirmar y generar factura',
                            style: GoogleFonts.exo2(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AdminTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: GoogleFonts.exo2(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
