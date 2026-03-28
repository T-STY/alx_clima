import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/pdf_actions.dart';
import 'appointment_actions.dart';
import 'invoice_confirm_sheet.dart';
import 'invoice_pdf_builder.dart';

Future<void> invoiceAndComplete(
  BuildContext context,
  QueryDocumentSnapshot doc,
) async {
  final data = doc.data() as Map<String, dynamic>;
  final customer = data['customer'] as Map<String, dynamic>? ?? {};
  final equipment = parseEquipment(data);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final breakdown = data['quoteBreakdown'] as Map<String, dynamic>?;
  final equipCost = (breakdown?['equipmentPrice'] as num?)?.toDouble() ?? 0.0;
  final serviceFee = (breakdown?['installationPrice'] as num?)?.toDouble()
      ?? (data['estimatedCost'] as num?)?.toDouble()
      ?? 0.0;
  final serviceLabel = data['serviceTypeDisplay'] as String? ?? 'Servicio';
  final equipCostCtrl = TextEditingController(text: '${equipCost.toStringAsFixed(0)}');
  final serviceFeeCtrl = TextEditingController(text: '${serviceFee.toStringAsFixed(0)}');
  final notesCtrl = TextEditingController();

  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => InvoiceConfirmSheet(
      data: data,
      customer: customer,
      equipment: equipment,
      equipCostCtrl: equipCostCtrl,
      serviceFeeCtrl: serviceFeeCtrl,
      serviceLabel: serviceLabel,
      notesCtrl: notesCtrl,
      isDark: isDark,
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final finalEquipCost = double.tryParse(equipCostCtrl.text) ?? 0;
  final finalServiceFee = double.tryParse(serviceFeeCtrl.text) ?? 0;
  final total = finalEquipCost + finalServiceFee;
  final notes = notesCtrl.text;
  final pdfBytes = await buildInvoicePdf(
    data, customer, equipment, total, notes,
    equipmentCost: finalEquipCost,
    serviceFee: finalServiceFee,
  );
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
    'equipmentCost': finalEquipCost,
    'serviceFee': finalServiceFee,
    'total': total,
    'notes': notes,
    'pdfBase64': pdfBase64,
    'createdAt': FieldValue.serverTimestamp(),
  });

  await completeAppointment(doc);

  if (!context.mounted) return;

  if (context.mounted) {
    await showPdfActions(
      context,
      Uint8List.fromList(pdfBytes),
      'factura_${data['date'] ?? 'sin_fecha'}.pdf',
    );
  }
}

