import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:alx_clima/config/constants.dart';
import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/services/firebase_service.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;

  String _phone = AppConstants.technicianPhone;
  String _whatsApp = AppConstants.technicianWhatsApp;
  String _email = AppConstants.technicianEmail;
  String _companyName = AppConstants.appName;
  String _businessHours = 'Lunes a Sábado: 8:00 AM - 6:00 PM';

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  Future<void> _loadCompanyInfo() async {
    try {
      final data = await _firebaseService.getCompanyInfo();
      if (data != null && mounted) {
        setState(() {
          _phone = data['phone'] ?? _phone;
          _whatsApp = data['whatsApp'] ?? _whatsApp;
          _email = data['email'] ?? _email;
          _companyName = data['name'] ?? _companyName;
          _businessHours = data['businessHours'] ?? _businessHours;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacto y Soporte'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.06),
                          AppTheme.secondaryColor.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.secondaryColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Iconsax.wind,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _companyName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tu solución en climatización',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: -0.05, end: 0),
                  const SizedBox(height: 28),
                  _ContactCard(
                    icon: Iconsax.call,
                    title: 'Llamar',
                    subtitle: _phone,
                    color: AppTheme.primaryColor,
                    onTap: () async {
                      final uri = Uri.parse('tel:$_phone');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 150.ms)
                      .slideX(begin: 0.05, end: 0),
                  const SizedBox(height: 12),
                  _ContactCard(
                    icon: Iconsax.message,
                    title: 'WhatsApp',
                    subtitle: 'Escríbenos por WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () async {
                      final uri = Uri.parse(
                        'https://wa.me/$_whatsApp?text=Hola%2C%20me%20comunico%20desde%20la%20app%20ALX-Clima.',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 230.ms)
                      .slideX(begin: 0.05, end: 0),
                  const SizedBox(height: 12),
                  _ContactCard(
                    icon: Iconsax.sms,
                    title: 'Correo Electrónico',
                    subtitle: _email,
                    color: AppTheme.secondaryColor,
                    onTap: () async {
                      final uri = Uri.parse(
                        'mailto:$_email?subject=Contacto%20desde%20ALX-Clima',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 310.ms)
                      .slideX(begin: 0.05, end: 0),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Iconsax.clock,
                                color: AppTheme.primaryColor, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Horario de Atención',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _businessHours,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.info_circle,
                                  color: AppTheme.primaryColor, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Si nos contactas fuera de este horario, '
                                  'podrás recibir una respuesta hasta el '
                                  'siguiente día hábil',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.primaryColor,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 400.ms),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.location,
                          size: 36,
                          color:
                              AppTheme.primaryColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ubicación',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mapa próximamente',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 500.ms),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              color: color.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
