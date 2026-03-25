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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                    color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
                    fontSize: isBold ? 16 : 14,
                  ),
            ),
          ),
          Text(
            price,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: isBold ? AppTheme.primaryColor : AppTheme.textPrimary,
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
