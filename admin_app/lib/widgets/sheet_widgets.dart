import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alx_clima_admin/config/theme.dart';

Widget frostedSheet(
  BuildContext ctx,
  bool isDark,
  String title,
  Widget content,
) {
  return ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0B0D14).withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.exo2(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  MediaQuery.of(ctx).viewInsets.bottom + 100,
                ),
                child: content,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget sheetInput(
  TextEditingController ctrl,
  String hint,
  bool isDark, {
  TextInputType? keyboard,
}) {
  return TextField(
    controller: ctrl,
    keyboardType: keyboard,
    style: GoogleFonts.exo2(fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.exo2(fontSize: 14),
    ),
  );
}

Widget sheetDropdown<T>(
  String label,
  T? value,
  List<T> items,
  ValueChanged<T?> onChanged,
  bool isDark,
) {
  final textColor = isDark ? Colors.white : Colors.black;
  return DropdownButtonFormField<T>(
    value: value,
    dropdownColor: isDark ? const Color(0xFF1A1D27) : Colors.white,
    decoration: InputDecoration(
      hintText: label,
      hintStyle: GoogleFonts.exo2(fontSize: 14),
    ),
    style: GoogleFonts.exo2(fontSize: 14, color: textColor),
    items: items
        .map((e) => DropdownMenuItem(
              value: e,
              child: Text('$e', style: GoogleFonts.exo2(fontSize: 14, color: textColor)),
            ))
        .toList(),
    onChanged: onChanged,
  );
}

Widget sheetGradientButton(String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: AdminTheme.primaryGradient,
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.exo2(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

Widget sheetGlassButton(
  BuildContext ctx,
  bool isDark,
  String label,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.7),
        border: Border.all(
          color: AdminTheme.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.exo2(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AdminTheme.errorColor,
          ),
        ),
      ),
    ),
  );
}
