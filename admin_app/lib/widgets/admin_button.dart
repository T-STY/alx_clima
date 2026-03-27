import 'package:flutter/material.dart';
import 'package:alx_clima_admin/config/theme.dart';

class AdminButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isLoading;
  final Color? color;
  final bool expand;

  const AdminButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.color,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AdminTheme.primaryColor;
    final minSize = expand ? const Size(double.infinity, 48) : const Size(0, 48);

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: btnColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: minSize,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        child: _content(btnColor),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: minSize,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      child: _content(Colors.white),
    );
  }

  Widget _content(Color c) {
    if (isLoading) {
      return SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: c));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 8),
        ],
        Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
