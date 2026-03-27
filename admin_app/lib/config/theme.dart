import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTheme {
  AdminTheme._();

  static const Color primaryColor = Color(0xFF0A84FF);
  static const Color secondaryColor = Color(0xFF00D4FF);
  static const Color accentColor = Color(0xFF6366F1);
  static const Color backgroundColor = Color(0xFF0F1117);
  static const Color surfaceColor = Color(0xFF1A1D27);
  static const Color cardColor = Color(0xFF222536);
  static const Color cardHover = Color(0xFF2A2E42);
  static const Color textPrimary = Color(0xFFF1F3F9);
  static const Color textSecondary = Color(0xFF8B8FA3);
  static const Color dividerColor = Color(0xFF2E3247);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.exo2TextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),

      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
            color: textPrimary, fontWeight: FontWeight.w700),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
            color: textPrimary, fontWeight: FontWeight.w600),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            color: textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
            color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
            color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
            color: textPrimary, fontWeight: FontWeight.w500),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
            color: textSecondary, fontWeight: FontWeight.w500),
        bodyLarge:
            baseTextTheme.bodyLarge?.copyWith(color: textPrimary),
        bodyMedium:
            baseTextTheme.bodyMedium?.copyWith(color: textSecondary),
        bodySmall:
            baseTextTheme.bodySmall?.copyWith(color: textSecondary),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
            color: Colors.white, fontWeight: FontWeight.w600),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.exo2(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: GoogleFonts.exo2(color: textSecondary, fontSize: 14),
        labelStyle: GoogleFonts.exo2(color: textSecondary, fontSize: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.exo2(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.exo2(fontSize: 13, color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: dividerColor),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceColor,
        selectedIconTheme: const IconThemeData(color: primaryColor),
        unselectedIconTheme: IconThemeData(color: textSecondary),
        selectedLabelTextStyle: GoogleFonts.exo2(
          color: primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: GoogleFonts.exo2(
          color: textSecondary,
          fontSize: 12,
        ),
        indicatorColor: primaryColor.withValues(alpha: 0.15),
      ),
    );
  }
}
