import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:alx_clima_admin/config/theme.dart';

Future<void> showPdfActions(
  BuildContext context,
  Uint8List pdfBytes,
  String fileName,
) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A1D27).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Factura',
              style: GoogleFonts.exo2(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _actionTile(
                    ctx,
                    icon: Iconsax.share,
                    label: 'Compartir',
                    color: AdminTheme.primaryColor,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final dir = await getTemporaryDirectory();
                      final file = File('${dir.path}/$fileName');
                      await file.writeAsBytes(pdfBytes);
                      await Share.shareXFiles(
                        [XFile(file.path)],
                        text: 'Factura ALX-Clima',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionTile(
                    ctx,
                    icon: Iconsax.printer,
                    label: 'Imprimir',
                    color: AdminTheme.secondaryColor,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Printing.layoutPdf(
                        onLayout: (_) async => pdfBytes,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _actionTile(
  BuildContext context, {
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? color.withValues(alpha: 0.12)
            : color.withValues(alpha: 0.08),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.exo2(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}
