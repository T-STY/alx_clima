import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;
  ThemeData get theme => _isDark ? AppTheme.darkTheme : AppTheme.lightTheme;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('clientDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('clientDarkMode', _isDark);
  }
}

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF0A84FF);
  static const Color secondaryColor = Color(0xFF00D4FF);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFF8F9FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color dividerColor = Color(0xFFE5E7EB);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        background: backgroundColor,
        surface: surfaceColor,
        card: cardColor,
        tp: textPrimary,
        ts: textSecondary,
        divider: dividerColor,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        background: const Color(0xFF0F1117),
        surface: const Color(0xFF1A1D27),
        card: const Color(0xFF222536),
        tp: const Color(0xFFF1F3F9),
        ts: const Color(0xFF8B8FA3),
        divider: const Color(0xFF2E3247),
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color card,
    required Color tp,
    required Color ts,
    required Color divider,
  }) {
    final baseTextTheme = brightness == Brightness.light
        ? GoogleFonts.exo2TextTheme()
        : GoogleFonts.exo2TextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: divider,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surface,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: tp,
        onError: Colors.white,
      ),

      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: tp, fontWeight: FontWeight.w700),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: tp, fontWeight: FontWeight.w700),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: tp, fontWeight: FontWeight.w600),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: tp, fontWeight: FontWeight.w600),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: tp, fontWeight: FontWeight.w600),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: tp, fontWeight: FontWeight.w600),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: tp, fontWeight: FontWeight.w500),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: ts, fontWeight: FontWeight.w500),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: tp),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: ts),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: ts),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: tp),
        titleTextStyle: GoogleFonts.exo2(color: tp, fontSize: 18, fontWeight: FontWeight.w600),
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: primaryColor.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.exo2(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.exo2(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: errorColor, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: errorColor, width: 1.5)),
        hintStyle: GoogleFonts.exo2(color: ts.withValues(alpha: 0.5), fontSize: 14),
        labelStyle: GoogleFonts.exo2(color: ts, fontSize: 14),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        elevation: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: ts,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        elevation: 0,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.exo2(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor);
          }
          return GoogleFonts.exo2(fontSize: 12, fontWeight: FontWeight.w500, color: ts);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor, size: 24);
          }
          return IconThemeData(color: ts, size: 24);
        }),
      ),

      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),

      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primaryColor.withValues(alpha: 0.12),
        labelStyle: GoogleFonts.exo2(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: tp,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
