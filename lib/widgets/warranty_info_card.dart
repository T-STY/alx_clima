import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima/config/constants.dart';
import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/models/equipment.dart';
import 'package:alx_clima/models/installation.dart';

class WarrantyInfoCard extends StatelessWidget {
  final Equipment? equipment;
  final InstallationType installationType;

  const WarrantyInfoCard({
    super.key,
    this.equipment,
    required this.installationType,
  });

  @override
  Widget build(BuildContext context) {
    final includesWarranty = installationType == InstallationType.fullPackage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: includesWarranty
            ? AppTheme.successColor.withValues(alpha: 0.06)
            : AppTheme.warningColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: includesWarranty
              ? AppTheme.successColor.withValues(alpha: 0.3)
              : AppTheme.warningColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                includesWarranty ? Iconsax.shield_tick : Iconsax.info_circle,
                color: includesWarranty
                    ? AppTheme.successColor
                    : AppTheme.warningColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                includesWarranty ? 'Garantía Incluida' : 'Sin Garantía',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: includesWarranty
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          if (includesWarranty) ...[
            const SizedBox(height: 12),
            _WarrantyLine(
              label: 'Garantía del Técnico',
              value: AppConstants.warrantyTechnician,
            ),
            const SizedBox(height: 6),
            _WarrantyLine(
              label: 'Garantía del Fabricante',
              value: equipment != null
                  ? equipment!.manufacturerWarrantyDetails
                  : AppConstants.warrantyManufacturerCompressor,
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'La instalación sin compra de equipo no incluye garantía. '
              'Se recomienda adquirir el paquete completo para obtener cobertura.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.warningColor.withValues(alpha: 0.8),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WarrantyLine extends StatelessWidget {
  final String label;
  final String value;

  const _WarrantyLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Iconsax.tick_circle, size: 14, color: AppTheme.successColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
