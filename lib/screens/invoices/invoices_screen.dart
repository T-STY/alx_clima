import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:alx_clima/config/theme.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Facturas'),
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Inicia sesión para ver tus facturas')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Facturas'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('invoices')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.document,
                      size: 48,
                      color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('Sin facturas',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final date = data['date'] ?? '';
              final total = (data['total'] ?? 0).toDouble();
              final currencyFormat =
                  NumberFormat.currency(symbol: '\$', decimalDigits: 2);

              return GestureDetector(
                onTap: () => _viewInvoice(context, data),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.document_text,
                            color: AppTheme.primaryColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Factura - $date',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data['customerName'] ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currencyFormat.format(total),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms);
            },
          );
        },
      ),
    );
  }

  void _viewInvoice(BuildContext context, Map<String, dynamic> data) {
    final pdfBase64 = data['pdfBase64'] as String?;
    if (pdfBase64 == null || pdfBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF no disponible'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final pdfBytes = Uint8List.fromList(base64Decode(pdfBase64));
    final total = (data['total'] ?? 0).toDouble();
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.document_text,
                        color: AppTheme.primaryColor, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Factura - ${data['date']}',
                            style: Theme.of(ctx)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Total: ${currencyFormat.format(total)}',
                            style: Theme.of(ctx)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'El PDF de tu factura está disponible. Compártelo o guárdalo desde el botón de abajo.',
                style: Theme.of(ctx).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await Printing.layoutPdf(
                        onLayout: (_) async => pdfBytes,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Iconsax.document_download,
                        color: Colors.white),
                    label: const Text('Ver / Compartir PDF',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
