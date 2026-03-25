import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/models/customer_profile.dart';
import 'package:alx_clima/providers/dashboard_provider.dart';
import 'package:alx_clima/services/firebase_service.dart';
import 'package:alx_clima/widgets/futuristic_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _streetController = TextEditingController();
  final _exteriorController = TextEditingController();
  final _interiorController = TextEditingController();
  final _coloniaController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _stateController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  int _equipmentCount = 0;
  int _servicesCount = 0;
  DateTime? _memberSince;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _exteriorController.dispose();
    _interiorController.dispose();
    _coloniaController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _firebaseService.getUserProfile();
      final stats = await _firebaseService.getUserStats();

      if (profile != null && mounted) {
        _nameController.text = profile.name;
        _phoneController.text = profile.phone;
        _emailController.text = profile.email ?? '';
        _streetController.text = profile.street ?? '';
        _exteriorController.text = profile.exteriorNumber ?? '';
        _interiorController.text = profile.interiorNumber ?? '';
        _coloniaController.text = profile.colonia ?? '';
        _cityController.text = profile.city ?? '';
        _postalCodeController.text = profile.postalCode ?? '';
        _stateController.text = profile.state ?? '';
      }

      if (mounted) {
        setState(() {
          _equipmentCount = stats['equipmentCount'] ?? 0;
          _servicesCount = stats['servicesCount'] ?? 0;
          _memberSince = stats['memberSince'];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final updated = CustomerProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        street: _streetController.text.trim(),
        exteriorNumber: _exteriorController.text.trim(),
        interiorNumber: _interiorController.text.trim(),
        colonia: _coloniaController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        state: _stateController.text.trim(),
        memberSince: _memberSince,
      );

      await _firebaseService.saveUserProfile(updated);
      context.read<DashboardProvider>().updateProfile(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar. Intenta de nuevo'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: Container(
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
                          color:
                              AppTheme.primaryColor.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Iconsax.user,
                        size: 40,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                      ),
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
                  const SizedBox(height: 24),
                  _buildAddressSection()
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 250.ms),
                  const SizedBox(height: 28),
                  FuturisticButton(
                    text: 'Guardar Cambios',
                    icon: Iconsax.tick_circle,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _saveProfile,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 300.ms),
                  const SizedBox(height: 32),
                  _buildStatsSection()
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 400.ms),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.location, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Dirección',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _streetController,
            label: 'Calle',
            icon: Iconsax.routing,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _exteriorController,
                  label: 'No. Exterior',
                  icon: Iconsax.home_2,
                  keyboardType: TextInputType.text,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _interiorController,
                  label: 'No. Interior',
                  icon: Iconsax.home_1,
                  keyboardType: TextInputType.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _coloniaController,
            label: 'Colonia',
            icon: Iconsax.building,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _cityController,
            label: 'Ciudad / Municipio',
            icon: Iconsax.buildings,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _postalCodeController,
                  label: 'Código Postal',
                  icon: Iconsax.hashtag,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _stateController,
                  label: 'Estado',
                  icon: Iconsax.map,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final memberYear = _memberSince?.year.toString() ?? '-';

    return Container(
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
                  value: '$_equipmentCount',
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
                  value: '$_servicesCount',
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
                  value: memberYear,
                  label: 'Miembro',
                ),
              ),
            ],
          ),
        ],
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
