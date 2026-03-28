import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';

class AllInvoicesPage extends StatelessWidget {
  const AllInvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Facturas', style: GoogleFonts.exo2(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('invoices')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text('Sin facturas', style: GoogleFonts.exo2(fontSize: 14)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final total = (data['total'] as num?)?.toDouble() ?? 0;

              return GestureDetector(
                onTap: () {
                  final pdfBase64 = data['pdfBase64'] as String?;
                  if (pdfBase64 == null || pdfBase64.isEmpty) return;
                  final bytes = Uint8List.fromList(base64Decode(pdfBase64));
                  Printing.layoutPdf(onLayout: (_) async => bytes);
                },
                child: GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AdminTheme.primaryColor.withValues(alpha: 0.12),
                        ),
                        child: const Icon(Iconsax.document_text, size: 18, color: AdminTheme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['customerName'] ?? 'Cliente',
                              style: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              data['date'] ?? '',
                              style: GoogleFonts.exo2(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        fmt.format(total),
                        style: GoogleFonts.exo2(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AdminTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
