import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/models/customer_equipment.dart';

class EquipmentTile extends StatelessWidget {
  final CustomerEquipment equipment;
  final VoidCallback? onTap;

  const EquipmentTile({
    super.key,
    required this.equipment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final needsService = equipment.needsService;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: needsService
                ? AppTheme.warningColor.withValues(alpha: 0.4)
                : AppTheme.dividerColor,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: needsService
                    ? AppTheme.warningColor.withValues(alpha: 0.1)
                    : AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                'https://img.icons8.com/ios/100/air-conditioner.png',
                width: 36,
                height: 36,
                errorBuilder: (_, __, ___) => Icon(
                  Iconsax.cpu_setting,
                  color: needsService
                      ? AppTheme.warningColor
                      : AppTheme.primaryColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          equipment.equipmentName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(equipment.btuCapacity / 1000).toStringAsFixed(0)}K',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${equipment.brand} \u00b7 ${equipment.location}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (needsService) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Servicio pendiente',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.warningColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
