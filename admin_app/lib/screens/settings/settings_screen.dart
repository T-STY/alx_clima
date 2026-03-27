import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';
import 'settings_company.dart';
import 'settings_pricing.dart';
import 'settings_schedule.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Ajustes',
                style: GoogleFonts.exo2(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionLabel(context, 'Apariencia'),
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AdminTheme.accentColor.withValues(alpha: 0.2),
                          AdminTheme.accentColor.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Icon(
                      isDark ? Iconsax.moon : Iconsax.sun_1,
                      size: 18,
                      color: AdminTheme.accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isDark ? 'Modo oscuro' : 'Modo claro',
                      style: GoogleFonts.exo2(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: isDark,
                    onChanged: (_) => themeProvider.toggle(),
                    activeColor: AdminTheme.primaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel(context, 'Información de la empresa'),
            const CompanyInfoCard(),
            const SizedBox(height: 24),
            _sectionLabel(context, 'Precios'),
            const PricingCard(),
            const SizedBox(height: 24),
            _sectionLabel(context, 'Horario de trabajo'),
            const WorkScheduleCard(),
            const SizedBox(height: 32),
            _sectionLabel(context, 'Sesión'),
            GlassCard(
              child: GestureDetector(
                onTap: () => _showLogoutDialog(context),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AdminTheme.errorColor.withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Iconsax.logout,
                        size: 18,
                        color: AdminTheme.errorColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Cerrar Sesión',
                      style: GoogleFonts.exo2(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AdminTheme.errorColor,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Iconsax.arrow_right_3,
                      size: 16,
                      color: AdminTheme.errorColor.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cerrar Sesión', style: GoogleFonts.exo2(fontWeight: FontWeight.w600)),
        content: Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: GoogleFonts.exo2(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: GoogleFonts.exo2()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              FirebaseAuth.instance.signOut();
            },
            child: Text(
              'Cerrar Sesión',
              style: GoogleFonts.exo2(color: AdminTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        text,
        style: GoogleFonts.exo2(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
