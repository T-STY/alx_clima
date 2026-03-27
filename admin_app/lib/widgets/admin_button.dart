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
    super.key, required this.text, this.icon, this.onPressed,
    this.isOutlined = false, this.isLoading = false, this.color, this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AdminTheme.primaryColor;
    final sz = expand ? const Size(double.infinity, 46) : const Size(0, 40);
    final r = BorderRadius.circular(11);
    final p = EdgeInsets.symmetric(vertical: expand ? 11 : 9, horizontal: expand ? 18 : 16);
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(side: BorderSide(color: c.withValues(alpha: 0.4)), shape: RoundedRectangleBorder(borderRadius: r), minimumSize: sz, padding: p),
        child: _body(c),
      );
    }
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: c, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: r), minimumSize: sz, padding: p, disabledBackgroundColor: c.withValues(alpha: 0.5)),
      child: _body(Colors.white),
    );
  }

  Widget _body(Color c) {
    if (isLoading) return SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: c));
    return Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
      if (icon != null) ...[Icon(icon, size: 16, color: c), const SizedBox(width: 7)],
      Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.1)),
    ]);
  }
}
