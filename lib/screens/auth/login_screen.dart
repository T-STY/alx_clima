import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/providers/auth_provider.dart';
import 'package:alx_clima/widgets/futuristic_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    bool success;

    if (_isSignUp) {
      success = await auth.signUp(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      success = await auth.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (!success && auth.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        auth.clearError();
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa tu correo para recuperar tu contraseña'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(email);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Se envió un enlace de recuperación a tu correo'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (auth.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        auth.clearError();
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _formKey.currentState?.reset();
      _nameController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo()
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                    ),
                const SizedBox(height: 12),
                Text(
                  'ALX-Clima',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 100.ms),
                const SizedBox(height: 4),
                Text(
                  'Tu solución en climatización',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 150.ms),
                const SizedBox(height: 40),
                _buildForm()
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Iconsax.wind,
        color: Colors.white,
        size: 48,
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isSignUp ? 'Crear Cuenta' : 'Iniciar Sesión',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          if (_isSignUp) ...[
            _buildField(
              controller: _nameController,
              label: 'Nombre completo',
              icon: Iconsax.user,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Ingresa tu nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
          ],

          _buildField(
            controller: _emailController,
            label: 'Correo electrónico',
            icon: Iconsax.sms,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Ingresa tu correo';
              }
              if (!v.contains('@') || !v.contains('.')) {
                return 'Correo inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          _buildField(
            controller: _passwordController,
            label: 'Contraseña',
            icon: Iconsax.lock,
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Ingresa tu contraseña';
              }
              if (_isSignUp && v.length < 6) {
                return 'Mínimo 6 caracteres';
              }
              return null;
            },
          ),

          if (_isSignUp) ...[
            const SizedBox(height: 14),
            _buildField(
              controller: _confirmPasswordController,
              label: 'Confirmar contraseña',
              icon: Iconsax.lock,
              obscure: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Iconsax.eye_slash : Iconsax.eye,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v != _passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
          ],

          if (!_isSignUp) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _resetPassword,
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),
          ],

          const SizedBox(height: 24),

          FuturisticButton(
            text: _isSignUp ? 'Crear Cuenta' : 'Iniciar Sesión',
            icon: _isSignUp ? Iconsax.user_add : Iconsax.login,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignUp
                    ? '¿Ya tienes cuenta?'
                    : '¿No tienes cuenta?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: _toggleMode,
                child: Text(
                  _isSignUp ? 'Inicia sesión' : 'Regístrate',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
