import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/models/installation.dart';

class FloorSelector extends StatelessWidget {
  final FloorLevel selectedFloor;
  final bool compressorSameFloor;
  final ValueChanged<FloorLevel> onFloorChanged;
  final ValueChanged<bool> onCompressorLocationChanged;

  const FloorSelector({
    super.key,
    required this.selectedFloor,
    required this.compressorSameFloor,
    required this.onFloorChanged,
    required this.onCompressorLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿En qué piso se instalará?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: FloorLevel.values.map((floor) {
            final isSelected = selectedFloor == floor;
            return Expanded(
              child: GestureDetector(
                onTap: () => onFloorChanged(floor),
                child: Container(
                  margin: EdgeInsets.only(
                    right: floor == FloorLevel.first ? 8 : 0,
                    left: floor == FloorLevel.second ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        floor == FloorLevel.first
                            ? Iconsax.building
                            : Iconsax.building_4,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        floor.displayName,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          '¿El compresor estará en el mismo piso?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCompressorOption(
              context,
              label: 'Sí, mismo piso',
              icon: Iconsax.tick_circle,
              isSelected: compressorSameFloor,
              onTap: () => onCompressorLocationChanged(true),
              marginRight: 8,
            ),
            _buildCompressorOption(
              context,
              label: 'No, diferente piso',
              icon: Iconsax.arrow_swap_horizontal,
              isSelected: !compressorSameFloor,
              onTap: () => onCompressorLocationChanged(false),
              marginLeft: 8,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompressorOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    double marginLeft = 0,
    double marginRight = 0,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(left: marginLeft, right: marginRight),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
