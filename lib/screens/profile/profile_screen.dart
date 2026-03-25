import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/models/customer_profile.dart';
import 'package:alx_clima/providers/dashboard_provider.dart';
import 'package:alx_clima/widgets/futuristic_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initializeControllers(CustomerProfile? profile) {
    if (!_initialized && profile != null) {
      _nameController.text = profile.name;
      _phoneController.text = profile.phone;
      _emailController.text = profile.email ?? '';
      _addressController.text = profile.address ?? '';
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboard, _) {
          _initializeControllers(dashboard.profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.15),
                              AppTheme.secondaryColor.withValues(alpha: 0.15),
                            ],
                          ),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Iconsax.user,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.camera,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

                const SizedBox(height: 32),

                _buildTextField(
                  controller: _nameController,
                  label: 'Nombre',
                  icon: Iconsax.user,
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _phoneController,
                  label: 'Teléfono',
                  icon: Iconsax.call,
                  keyboardType: TextInputType.phone,
                ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  label: 'Correo Electrónico',
                  icon: Iconsax.sms,
                  keyboardType: TextInputType.emailAddress,
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _addressController,
                  label: 'Dirección',
                  icon: Iconsax.location,
                  maxLines: 2,
                ).animate().fadeIn(duration: 400.ms, delay: 250.ms),

                const SizedBox(height: 28),

                FuturisticButton(
                  text: 'Guardar Cambios',
                  icon: Iconsax.tick_circle,
                  onPressed: () {
                    final updated = CustomerProfile(
                      name: _nameController.text.trim(),
                      phone: _phoneController.text.trim(),
                      email: _emailController.text.trim(),
                      address: _addressController.text.trim(),
                    );
                    context.read<DashboardProvider>().updateProfile(updated);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Perfil actualizado correctamente'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  },
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 300.ms),

                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis Estadísticas',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              icon: Iconsax.cpu_setting,
                              value: '${dashboard.totalEquipment}',
                              label: 'Equipos',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppTheme.dividerColor,
                          ),
                          Expanded(
                            child: _StatItem(
                              icon: Iconsax.document_text,
                              value: '${dashboard.serviceHistory.length}',
                              label: 'Servicios',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppTheme.dividerColor,
                          ),
                          Expanded(
                            child: _StatItem(
                              icon: Iconsax.calendar_1,
                              value: '2023',
                              label: 'Miembro',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 400.ms),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}
