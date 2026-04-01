import 'package:flutter/material.dart';
import 'package:alx_clima/config/theme.dart';

class PriceRow extends StatelessWidget {
  final String label;
  final String price;
  final bool isBold;
  final bool showStrikethrough;

  const PriceRow({
    super.key,
    required this.label,
    required this.price,
    this.isBold = false,
    this.showStrikethrough = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                    color: isBold
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: isBold ? 16 : 14,
                  ),
            ),
          ),
          Text(
            price,
            style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: isBold
                      ? AppTheme.primaryColor
                      : theme.colorScheme.onSurface,
                  fontSize: isBold ? 18 : 14,
                  decoration:
                      showStrikethrough ? TextDecoration.lineThrough : null,
                ),
          ),
        ],
      ),
    );
  }
}
