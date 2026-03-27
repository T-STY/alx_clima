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
    final minSize = expand
        ? const Size(double.infinity, 44)
        : const Size(0, 38);
    final radius = BorderRadius.circular(10);
    final pad = EdgeInsets.symmetric(
      vertical: expand ? 10 : 8,
      horizontal: expand ? 16 : 14,
    );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: btnColor.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: radius),
          minimumSize: minSize,
          padding: pad,
        ),
        child: _body(btnColor),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius),
        minimumSize: minSize,
        padding: pad,
      ),
      child: _body(Colors.white),
    );
  }

  Widget _body(Color c) {
    if (isLoading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: c),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: TextStyle(
            color: c,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
