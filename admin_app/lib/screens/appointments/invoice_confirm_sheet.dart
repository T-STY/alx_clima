import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:alx_clima_admin/config/theme.dart';

class InvoiceConfirmSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> customer;
  final List<Map<String, dynamic>> equipment;
  final TextEditingController equipCostCtrl;
  final TextEditingController serviceFeeCtrl;
  final String serviceLabel;
  final TextEditingController notesCtrl;
  final bool isDark;

  const InvoiceConfirmSheet({
    super.key,
    required this.data,
    required this.customer,
    required this.equipment,
    required this.equipCostCtrl,
    required this.serviceFeeCtrl,
    required this.serviceLabel,
    required this.notesCtrl,
    required this.isDark,
  });

  @override
  State<InvoiceConfirmSheet> createState() => _InvoiceConfirmSheetState();
}

class _InvoiceConfirmSheetState extends State<InvoiceConfirmSheet> {
  double get _total =>
      (double.tryParse(widget.equipCostCtrl.text) ?? 0) +
      (double.tryParse(widget.serviceFeeCtrl.text) ?? 0);

  @override
  void initState() {
    super.initState();
    widget.equipCostCtrl.addListener(() => setState(() {}));
    widget.serviceFeeCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final customer = widget.customer;
    final equipment = widget.equipment;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: widget.isDark
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
                    controller: widget.equipCostCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.exo2(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Costo de equipos (\$)',
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
                    controller: widget.serviceFeeCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.exo2(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Costo de ${widget.serviceLabel} (\$)',
                      labelStyle: GoogleFonts.exo2(fontSize: 13),
                      prefixText: '\$ ',
                      prefixStyle: GoogleFonts.exo2(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.exo2(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        fmt.format(_total),
                        style: GoogleFonts.exo2(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AdminTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.notesCtrl,
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
