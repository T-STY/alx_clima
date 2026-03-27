import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _nc = TextEditingController();
  final _pc = TextEditingController();
  final _wc = TextEditingController();
  final _ec = TextEditingController();
  final _hc = TextEditingController();
  final _twc = TextEditingController();
  final _pricingCtrl = <String, TextEditingController>{};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nc.dispose();
    _pc.dispose();
    _wc.dispose();
    _ec.dispose();
    _hc.dispose();
    _twc.dispose();
    for (final c in _pricingCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrl(String key, dynamic def) {
    _pricingCtrl.putIfAbsent(key, () => TextEditingController(text: '$def'));
    return _pricingCtrl[key]!;
  }

  Future<void> _load() async {
    final compDoc = await _firestore.collection('company').doc('info').get();
    final d = compDoc.data();
    if (d != null) {
      _nc.text = d['name'] ?? '';
      _pc.text = d['phone'] ?? '';
      _wc.text = d['whatsApp'] ?? '';
      _ec.text = d['email'] ?? '';
      _hc.text = d['businessHours'] ?? '';
      _twc.text = d['techWarranty'] ?? '1 año general + 3 meses en electrónicos';
    }

    final pricDoc = await _firestore.collection('config').doc('pricing').get();
    final p = pricDoc.data() ?? {};
    final io = (p['installOnly'] as Map<String, dynamic>?) ?? {};
    final fp = (p['fullPackage'] as Map<String, dynamic>?) ?? {};
    for (final btu in ['12000', '18000', '24000', '36000']) {
      _ctrl('io$btu', io[btu] ?? 0);
      _ctrl('fp$btu', fp[btu] ?? 0);
    }
    _ctrl('sf', p['secondFloorSurcharge'] ?? 0.3);
    _ctrl('df', p['differentFloorSurcharge'] ?? 0.25);
    _ctrl('md', p['multiUnitDiscount'] ?? 0.1);

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajustes',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 24),
              _section(
                context,
                'Información de la Empresa',
                Iconsax.building,
                [
                  _field(_nc, 'Nombre', Iconsax.building),
                  _field(_pc, 'Teléfono', Iconsax.call),
                  _field(_wc, 'WhatsApp', Iconsax.message),
                  _field(_ec, 'Correo', Iconsax.sms),
                  _field(_hc, 'Horario de atención', Iconsax.clock),
                  _field(_twc, 'Garantía del técnico', Iconsax.shield_tick),
                  const SizedBox(height: 12),
                  AdminButton(
                    text: 'Guardar Empresa',
                    icon: Iconsax.tick_circle,
                    onPressed: _saveCompany,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _section(
                context,
                'Precios - Solo Instalación',
                Iconsax.money,
                [
                  Text(
                    'Cliente ya tiene equipo',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ..._priceFields('io'),
                ],
              ),
              const SizedBox(height: 20),
              _section(
                context,
                'Precios - Equipo + Instalación',
                Iconsax.money,
                [
                  Text(
                    'Compra equipo contigo',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ..._priceFields('fp'),
                ],
              ),
              const SizedBox(height: 20),
              _section(
                context,
                'Recargos y Descuentos',
                Iconsax.discount_shape,
                [
                  _field(
                    _ctrl('sf', 0),
                    'Recargo segundo piso (0.3 = 30%)',
                    Iconsax.building_4,
                    isNum: true,
                  ),
                  _field(
                    _ctrl('df', 0),
                    'Recargo compresor piso diferente',
                    Iconsax.arrow_swap,
                    isNum: true,
                  ),
                  _field(
                    _ctrl('md', 0),
                    'Descuento multi-equipo (0.1 = 10%)',
                    Iconsax.discount_shape,
                    isNum: true,
                  ),
                  const SizedBox(height: 12),
                  AdminButton(
                    text: 'Guardar Precios',
                    icon: Iconsax.tick_circle,
                    onPressed: _savePricing,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCompany() async {
    await _firestore.collection('company').doc('info').set({
      'name': _nc.text.trim(),
      'phone': _pc.text.trim(),
      'whatsApp': _wc.text.trim(),
      'email': _ec.text.trim(),
      'businessHours': _hc.text.trim(),
      'techWarranty': _twc.text.trim(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Información actualizada'),
          backgroundColor: AdminTheme.successColor,
        ),
      );
    }
  }

  Future<void> _savePricing() async {
    await _firestore.collection('config').doc('pricing').set({
      'installOnly': {
        '12000': num.tryParse(_ctrl('io12000', 0).text) ?? 0,
        '18000': num.tryParse(_ctrl('io18000', 0).text) ?? 0,
        '24000': num.tryParse(_ctrl('io24000', 0).text) ?? 0,
        '36000': num.tryParse(_ctrl('io36000', 0).text) ?? 0,
      },
      'fullPackage': {
        '12000': num.tryParse(_ctrl('fp12000', 0).text) ?? 0,
        '18000': num.tryParse(_ctrl('fp18000', 0).text) ?? 0,
        '24000': num.tryParse(_ctrl('fp24000', 0).text) ?? 0,
        '36000': num.tryParse(_ctrl('fp36000', 0).text) ?? 0,
      },
      'secondFloorSurcharge': num.tryParse(_ctrl('sf', 0).text) ?? 0.3,
      'differentFloorSurcharge': num.tryParse(_ctrl('df', 0).text) ?? 0.25,
      'multiUnitDiscount': num.tryParse(_ctrl('md', 0).text) ?? 0.1,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Precios actualizados'),
          backgroundColor: AdminTheme.successColor,
        ),
      );
    }
  }

  Widget _section(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AdminTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(controller: ctrl, keyboardType: isNum ? TextInputType.number : null, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20))),
    );
  }

  List<Widget> _priceFields(String pfx) {
    const btus = ['12000', '18000', '24000', '36000'];
    const labels = ['12K BTU', '18K BTU', '24K BTU', '36K BTU'];
    return List.generate(btus.length, (i) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(controller: _ctrl('$pfx${btus[i]}', 0), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: labels[i], prefixIcon: const Icon(Iconsax.money, size: 20), prefixText: '\$ ')),
    ));
  }
}
