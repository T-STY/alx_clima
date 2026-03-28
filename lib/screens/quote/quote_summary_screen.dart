import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:alx_clima/config/constants.dart';
import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/models/installation.dart';
import 'package:alx_clima/providers/quote_provider.dart';
import 'package:alx_clima/services/firebase_service.dart';
import 'package:alx_clima/widgets/futuristic_button.dart';
import 'package:alx_clima/widgets/price_row.dart';
import 'package:alx_clima/widgets/warranty_info_card.dart';

class QuoteSummaryScreen extends StatefulWidget {
  const QuoteSummaryScreen({super.key});

  @override
  State<QuoteSummaryScreen> createState() => _QuoteSummaryScreenState();
}

class _QuoteSummaryScreenState extends State<QuoteSummaryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _companyPhone = AppConstants.technicianPhone;

  @override
  void initState() {
    super.initState();
    _loadCompanyPhone();
  }

  Future<void> _loadCompanyPhone() async {
    try {
      final data = await _firebaseService.getCompanyInfo();
      if (data != null && mounted) {
        setState(() {
          _companyPhone = data['phone'] ?? _companyPhone;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Cotización'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<QuoteProvider>(
        builder: (context, quoteProvider, _) {
          final quote = quoteProvider.currentQuote;

          if (quote == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.document,
                      size: 48, color: AppTheme.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    'No hay cotización disponible',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final isFullPackage =
              quote.installationType == InstallationType.fullPackage;
          final items = quoteProvider.items;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (items.isNotEmpty) ...[
                        Text(
                          items.length > 1
                              ? 'Equipos (${items.length})'
                              : 'Equipo',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium,
                        )
                            .animate()
                            .fadeIn(duration: 400.ms),
                        const SizedBox(height: 12),
                        ...items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            margin:
                                const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius:
                                  BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppTheme.dividerColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Image.network(
                                    'https://img.icons8.com/ios/100/air-conditioner.png',
                                    width: 32,
                                    height: 32,
                                    errorBuilder:
                                        (_, __, ___) => const Icon(
                                      Iconsax.cpu_setting,
                                      color:
                                          AppTheme.textSecondary,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.equipment.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: AppTheme
                                                  .textPrimary,
                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.equipment.brand} \u00b7 ${item.equipment.btuFormatted} \u00b7 ${item.installationDetails.floorLevel.displayName}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(
                                    quoteProvider
                                        .getInstallCostForItem(item),
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color:
                                            AppTheme.primaryColor,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(
                                  duration: 400.ms,
                                  delay: (index * 80).ms)
                              .slideY(begin: 0.05, end: 0);
                        }),
                        const SizedBox(height: 12),
                      ],

                      Text(
                        'Desglose de Precios',
                        style:
                            Theme.of(context).textTheme.titleMedium,
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 100.ms),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.dividerColor),
                        ),
                        child: Column(
                          children: [
                            if (isFullPackage)
                              PriceRow(
                                label:
                                    'Equipos (${items.length})',
                                price: currencyFormat.format(
                                    quote.equipmentPrice),
                              ),
                            PriceRow(
                              label:
                                  'Instalación (${items.length})',
                              price: currencyFormat.format(
                                  quote.installationPrice),
                            ),
                            if (items.length > 1)
                              PriceRow(
                                label: 'Descuento multi-equipo',
                                price: 'Aplicado',
                              ),
                            const Divider(height: 20),
                            PriceRow(
                              label: 'Total',
                              price: currencyFormat
                                  .format(quote.totalPrice),
                              isBold: true,
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 200.ms),
                      const SizedBox(height: 20),
                      WarrantyInfoCard(
                        equipment: isFullPackage
                            ? quote.equipment
                            : null,
                        installationType: quote.installationType,
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 300.ms),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Iconsax.info_circle,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppConstants.disclaimerText,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          AppTheme.textSecondary,
                                      fontSize: 11,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 400.ms),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor
                          .withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FuturisticButton(
                            text: 'Compartir',
                            icon: Iconsax.share,
                            isOutlined: true,
                            onPressed: () => _shareQuote(
                                quoteProvider, currencyFormat),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FuturisticButton(
                            text: 'Agendar',
                            icon: Iconsax.calendar_1,
                            onPressed: () {
                              context.push(
                                '/dashboard/schedule?fromQuote=true',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _shareQuote(
      QuoteProvider quoteProvider, NumberFormat currencyFormat) {
    final quote = quoteProvider.currentQuote;
    if (quote == null) return;

    final isFullPackage =
        quote.installationType == InstallationType.fullPackage;
    final buffer = StringBuffer();
    buffer.writeln('Cotización ${AppConstants.appName}');
    buffer.writeln('---');

    for (var i = 0; i < quoteProvider.items.length; i++) {
      final item = quoteProvider.items[i];
      buffer.writeln(
          'Equipo ${i + 1}: ${item.equipment.name} (${item.equipment.btuFormatted})');
    }

    if (isFullPackage) {
      buffer.writeln(
          'Equipos: ${currencyFormat.format(quote.equipmentPrice)}');
    }
    buffer.writeln(
        'Instalación: ${currencyFormat.format(quote.installationPrice)}');
    buffer.writeln(
        'Total: ${currencyFormat.format(quote.totalPrice)}');
    buffer.writeln('---');
    buffer.writeln(
        'Garantía: ${isFullPackage ? "Incluida" : "No incluida"}');
    buffer.writeln('');
    buffer.writeln('Contacto: $_companyPhone');

    Share.share(buffer.toString());
  }
}
