import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<List<int>> buildInvoicePdf(
  Map<String, dynamic> data,
  Map<String, dynamic> customer,
  List<Map<String, dynamic>> equipment,
  double total,
  String notes, {
  double equipmentCost = 0,
  double serviceFee = 0,
}) async {
  final pdf = pw.Document();
  final companySnap =
      await FirebaseFirestore.instance.collection('company').doc('info').get();
  final company = companySnap.data() ?? {};
  final companyName = company['name'] ?? 'ALX Clima';
  final companyPhone = company['phone'] ?? '';
  final companyEmail = company['email'] ?? '';
  final warranty = company['techWarranty'] ?? '';

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      companyPhone,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      companyEmail,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'FACTURA DE SERVICIO',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Fecha: ${data['date'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 2, color: PdfColors.blue800),
            pw.SizedBox(height: 16),
            pw.Text(
              'Datos del cliente',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            _infoLine('Nombre', customer['name'] ?? ''),
            _infoLine('Teléfono', customer['phone'] ?? ''),
            _infoLine('Email', customer['email'] ?? ''),
            _infoLine('Dirección', customer['address'] ?? ''),
            pw.SizedBox(height: 12),
            _infoLine('Servicio', data['serviceTypeDisplay'] ?? ''),
            _infoLine('Horario', data['timeSlotDisplay'] ?? ''),
            pw.SizedBox(height: 16),
            pw.Text(
              'Equipos',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(0.8),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.blue50),
                  children: [
                    _cell('Marca', bold: true),
                    _cell('Modelo', bold: true),
                    _cell('BTU', bold: true),
                    _cell('Precio', bold: true),
                  ],
                ),
                ...equipment.map(
                  (eq) {
                    final breakdown = data['quoteBreakdown'] as Map<String, dynamic>?;
                    final perEquip = (breakdown?['perEquipment'] as List?) ?? [];
                    final matchedBreakdown = perEquip.where((pe) =>
                        pe['name'] == eq['name'] && pe['brand'] == eq['brand']).firstOrNull;
                    final price = (matchedBreakdown?['equipmentCost'] as num?) ??
                        (eq['equipmentCost'] as num?) ??
                        (eq['price'] as num?) ?? 0;
                    return pw.TableRow(
                      children: [
                        _cell('${eq['brand'] ?? ''}'),
                        _cell('${eq['name'] ?? ''}'),
                        _cell('${eq['btuCapacity'] ?? ''}'),
                        _cell(price > 0 ? _fmtMoney(price.toDouble()) : '-'),
                      ],
                    );
                  },
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Garantías',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            if (warranty.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  'Técnico: $warranty',
                  style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                ),
              ),
            ...equipment.map((eq) {
              final mfgWarranty = eq['manufacturerWarrantyDetails'] as String? ?? '';
              if (mfgWarranty.isEmpty) return pw.SizedBox.shrink();
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  '${eq['brand']} ${eq['name']}: $mfgWarranty',
                  style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                ),
              );
            }),
            pw.SizedBox(height: 16),
            _buildPdfBreakdown(data, total, equipmentCost, serviceFee),
            if (notes.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text(
                'Notas: $notes',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 6),
            if (warranty.isNotEmpty)
              pw.Text(
                'Garantía del técnico: $warranty',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Documento generado por $companyName. Gracias por su preferencia.',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey500,
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

pw.Widget _infoLine(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ],
    ),
  );
}

pw.Widget _cell(String text, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

pw.Widget _buildPdfBreakdown(
  Map<String, dynamic> data,
  double total,
  double equipmentCost,
  double serviceFee,
) {
  final breakdown = data['quoteBreakdown'] as Map<String, dynamic>?;
  final serviceLabel = data['serviceTypeDisplay'] as String? ?? 'Servicio';
  String fmt(num v) => _fmtMoney(v.toDouble());

  final rows = <pw.Widget>[];

  if (breakdown != null) {
    rows.add(pw.Text(
      'Desglose de costos',
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    ));
    rows.add(pw.SizedBox(height: 6));

    final perEquip = (breakdown['perEquipment'] as List?) ?? [];
    for (final eq in perEquip) {
      rows.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(
          '${eq['brand'] ?? ''} ${eq['name'] ?? ''} (${eq['btuCapacity'] ?? 0} BTU)',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ));
      final eqCost = (eq['equipmentCost'] as num?) ?? 0;
      if (eqCost > 0) {
        rows.add(_pdfRow('  Equipo', fmt(eqCost)));
      }
      final instCost = (eq['installCost'] as num?) ?? 0;
      if (instCost > 0) {
        rows.add(_pdfRow('  $serviceLabel', fmt(instCost)));
      }
      if (eq['floorLevel'] == 'second') {
        rows.add(_pdfRow('  Recargo segundo piso', 'Incluido'));
      }
      if (eq['compressorSameFloor'] == false) {
        rows.add(_pdfRow('  Recargo compresor diferente', 'Incluido'));
      }
    }

    if (breakdown['multiUnitDiscount'] == true) {
      rows.add(_pdfRow('Descuento multi-equipo', 'Aplicado'));
    }
  }

  rows.add(pw.Divider(color: PdfColors.grey400));

  if (equipmentCost > 0) {
    rows.add(_pdfRow('Subtotal equipos', fmt(equipmentCost)));
  }
  if (serviceFee > 0) {
    rows.add(_pdfRow(serviceLabel, fmt(serviceFee)));
  }

  rows.add(pw.SizedBox(height: 4));
  rows.add(pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColors.blue50,
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'TOTAL',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          '${fmt(total)} MXN',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  ));

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: rows,
  );
}

String _fmtMoney(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final intPart = parts[0];
  final decPart = parts[1];
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  return '\$$buf.$decPart';
}

pw.Widget _pdfRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ],
    ),
  );
}
