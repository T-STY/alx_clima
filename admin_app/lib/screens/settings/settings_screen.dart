import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
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
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 120),
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
            const SizedBox(height: 24),

            _sectionLabel(context, 'General'),
            _settingsTile(
              context,
              icon: Iconsax.building,
              color: AdminTheme.primaryColor,
              title: 'Información de la empresa',
              subtitle: 'Nombre, teléfono, correo, horario',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const CompanyInfoPage(),
              )),
            ),
            _settingsTile(
              context,
              icon: Iconsax.money_3,
              color: AdminTheme.successColor,
              title: 'Precios de instalación',
              subtitle: 'Tarifas por BTU, recargos, descuentos',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const PricingPage(),
              )),
            ),
            _settingsTile(
              context,
              icon: Iconsax.calendar,
              color: AdminTheme.secondaryColor,
              title: 'Horario de trabajo',
              subtitle: 'Días laborales, horario, generar disponibilidad',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const WorkSchedulePage(),
              )),
            ),
            _settingsTile(
              context,
              icon: Iconsax.chart_2,
              color: AdminTheme.warningColor,
              title: 'Metas de ingresos',
              subtitle: 'Configura tus metas mensuales y anuales',
              onTap: () => _showMetricsTargets(context),
            ),
            _settingsTile(
              context,
              icon: Iconsax.document_text,
              color: AdminTheme.accentColor,
              title: 'Facturas',
              subtitle: 'Ver todas las facturas generadas',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const _AllInvoicesPage(),
              )),
            ),

            const SizedBox(height: 24),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Modo oscuro', style: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w500)),
                        Text(
                          isDark ? 'Activado' : 'Desactivado',
                          style: GoogleFonts.exo2(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
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
            _sectionLabel(context, 'Cuenta'),
            _settingsTile(
              context,
              icon: Iconsax.logout,
              color: AdminTheme.errorColor,
              title: 'Cerrar sesión',
              subtitle: FirebaseAuth.instance.currentUser?.email ?? '',
              onTap: () => _showLogoutDialog(context),
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GlassCard(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.exo2(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? color : null,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: GoogleFonts.exo2(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            if (!isDestructive)
              Icon(Iconsax.arrow_right_3, size: 16, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        text,
        style: GoogleFonts.exo2(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cerrar sesión', style: GoogleFonts.exo2(fontWeight: FontWeight.w600)),
        content: Text('¿Estás seguro?', style: GoogleFonts.exo2()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.exo2()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              FirebaseAuth.instance.signOut();
            },
            child: Text('Cerrar sesión', style: GoogleFonts.exo2(color: AdminTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  void _showMetricsTargets(BuildContext context) async {
    final doc = await FirebaseFirestore.instance
        .collection('config')
        .doc('metricsTargets')
        .get();
    final data = doc.data() ?? {};
    final monthlyCtrl = TextEditingController(text: '${data['monthly'] ?? 50000}');
    final yearlyCtrl = TextEditingController(text: '${data['yearly'] ?? 500000}');

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Metas de Ingresos', style: GoogleFonts.exo2(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: monthlyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Meta mensual',
                prefixText: '\$ ',
                prefixStyle: GoogleFonts.exo2(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yearlyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Meta anual',
                prefixText: '\$ ',
                prefixStyle: GoogleFonts.exo2(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.exo2()),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('config')
                  .doc('metricsTargets')
                  .set({
                'monthly': num.tryParse(monthlyCtrl.text) ?? 50000,
                'yearly': num.tryParse(yearlyCtrl.text) ?? 500000,
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Guardar', style: GoogleFonts.exo2(color: AdminTheme.primaryColor)),
          ),
        ],
      ),
    );
  }
}

class _AllInvoicesPage extends StatelessWidget {
  const _AllInvoicesPage();

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Facturas', style: GoogleFonts.exo2(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('invoices')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text('Sin facturas', style: GoogleFonts.exo2(fontSize: 14)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final total = (data['total'] as num?)?.toDouble() ?? 0;

              return GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AdminTheme.primaryColor.withValues(alpha: 0.12),
                      ),
                      child: const Icon(Iconsax.document_text, size: 18, color: AdminTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['customerName'] ?? 'Cliente',
                            style: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            data['date'] ?? '',
                            style: GoogleFonts.exo2(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      fmt.format(total),
                      style: GoogleFonts.exo2(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AdminTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
