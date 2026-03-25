import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/data/pricing_rules.dart';
import 'package:alx_clima/models/installation.dart';
import 'package:alx_clima/providers/quote_provider.dart';
import 'package:alx_clima/widgets/floor_selector.dart';
import 'package:alx_clima/widgets/futuristic_button.dart';

class InstallationDetailsScreen extends StatelessWidget {
  const InstallationDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Instalación'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<QuoteProvider>(
        builder: (context, quote, _) {
          final details = quote.installationDetails;
          final btu = quote.selectedEquipment?.btuCapacity ?? 12000;
          final installCost = PricingRules.calculateInstallationCost(
            details,
            quote.installationType,
            btuCapacity: btu,
          );

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.05),
                              AppTheme.secondaryColor.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.secondaryColor,
                                ],
                              ).createShader(bounds),
                              child: const Icon(
                                Iconsax.building_4,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Configura tu instalación',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: -0.1, end: 0),

                      const SizedBox(height: 28),

                      FloorSelector(
                        selectedFloor: details.floorLevel,
                        compressorSameFloor: details.compressorSameFloor,
                        onFloorChanged: (floor) {
                          context.read<QuoteProvider>().setFloorLevel(floor);
                        },
                        onCompressorLocationChanged: (sameFloor) {
                          context
                              .read<QuoteProvider>()
                              .setCompressorLocation(sameFloor);
                        },
                      )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 200.ms),

                      const SizedBox(height: 28),

                      if (details.floorLevel == FloorLevel.second ||
                          !details.compressorSameFloor) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Iconsax.info_circle,
                                      size: 16, color: AppTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ajustes de precio',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (details.floorLevel == FloorLevel.second)
                                Text(
                                  'Cargo adicional por instalación en segundo piso',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTheme.textPrimary),
                                ),
                              if (!details.compressorSameFloor)
                                Text(
                                  'Cargo adicional por compresor en piso diferente',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTheme.textPrimary),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Costo de instalación',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          currencyFormat.format(installCost),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FuturisticButton(
                      text: 'Continuar',
                      icon: Iconsax.arrow_right_3,
                      onPressed: () {
                        context.read<QuoteProvider>().generateQuote();
                        context.push('/quote/summary');
                      },
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
}
