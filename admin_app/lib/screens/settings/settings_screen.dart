import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:alx_clima_admin/config/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _loading = true;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsAppCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _warrantyCtrl = TextEditingController();

  final _btuKeys = [12000, 18000, 24000, 36000, 48000, 60000];
  final Map<int, TextEditingController> _installCtrls = {};
  final Map<int, TextEditingController> _fullCtrls = {};
  final _surcharge2Ctrl = TextEditingController();
  final _surchargeDiffCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final btu in _btuKeys) {
      _installCtrls[btu] = TextEditingController();
      _fullCtrls[btu] = TextEditingController();
    }
    _loadData();
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _whatsAppCtrl, _emailCtrl, _hoursCtrl, _warrantyCtrl, _surcharge2Ctrl, _surchargeDiffCtrl, _discountCtrl]) {
      c.dispose();
    }
    for (final c in [..._installCtrls.values, ..._fullCtrls.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final infoDoc = await _firestore.doc('company/info').get();
    if (infoDoc.exists) {
      final d = infoDoc.data()!;
      _nameCtrl.text = d['name'] ?? '';
      _phoneCtrl.text = d['phone'] ?? '';
      _whatsAppCtrl.text = d['whatsApp'] ?? '';
      _emailCtrl.text = d['email'] ?? '';
      _hoursCtrl.text = d['businessHours'] ?? '';
      _warrantyCtrl.text = d['techWarranty'] ?? '';
    }
    final pricingDoc = await _firestore.doc('config/pricing').get();
    if (pricingDoc.exists) {
      final d = pricingDoc.data()!;
      final install = Map<String, dynamic>.from(d['installOnly'] ?? {});
      final full = Map<String, dynamic>.from(d['fullPackage'] ?? {});
      for (final btu in _btuKeys) {
        _installCtrls[btu]?.text = '${install['$btu'] ?? ''}';
        _fullCtrls[btu]?.text = '${full['$btu'] ?? ''}';
      }
      _surcharge2Ctrl.text = '${d['secondFloorSurcharge'] ?? ''}';
      _surchargeDiffCtrl.text = '${d['differentFloorSurcharge'] ?? ''}';
      _discountCtrl.text = '${d['multiUnitDiscount'] ?? ''}';
    }
    setState(() => _loading = false);
  }

  Future<void> _saveCompany() async {
    await _firestore.doc('company/info').set({
      'name': _nameCtrl.text, 'phone': _phoneCtrl.text,
      'whatsApp': _whatsAppCtrl.text, 'email': _emailCtrl.text,
      'businessHours': _hoursCtrl.text, 'techWarranty': _warrantyCtrl.text,
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Información guardada')));
  }

  Future<void> _savePricing() async {
    final install = <String, dynamic>{};
    final full = <String, dynamic>{};
    for (final btu in _btuKeys) {
      final iv = double.tryParse(_installCtrls[btu]?.text ?? '');
      final fv = double.tryParse(_fullCtrls[btu]?.text ?? '');
      if (iv != null) install['$btu'] = iv;
      if (fv != null) full['$btu'] = fv;
    }
    await _firestore.doc('config/pricing').set({
      'installOnly': install, 'fullPackage': full,
      'secondFloorSurcharge': double.tryParse(_surcharge2Ctrl.text) ?? 0,
      'differentFloorSurcharge': double.tryParse(_surchargeDiffCtrl.text) ?? 0,
      'multiUnitDiscount': double.tryParse(_discountCtrl.text) ?? 0,
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Precios guardados')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text('Ajustes', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),
            _label('INFORMACIÓN DE LA EMPRESA', theme),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Nombre')),
                  const SizedBox(height: 8),
                  TextField(controller: _phoneCtrl, decoration: const InputDecoration(hintText: 'Teléfono')),
                  const SizedBox(height: 8),
                  TextField(controller: _whatsAppCtrl, decoration: const InputDecoration(hintText: 'WhatsApp')),
                  const SizedBox(height: 8),
                  TextField(controller: _emailCtrl, decoration: const InputDecoration(hintText: 'Email')),
                  const SizedBox(height: 8),
                  TextField(controller: _hoursCtrl, decoration: const InputDecoration(hintText: 'Horario de atención')),
                  const SizedBox(height: 8),
                  TextField(controller: _warrantyCtrl, decoration: const InputDecoration(hintText: 'Garantía técnica')),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _saveCompany,
                      child: Text('Guardar información', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminTheme.primaryColor)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _label('PRECIOS', theme),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('SOLO INSTALACIÓN', theme),
                  const SizedBox(height: 8),
                  ..._btuKeys.map((b) => _btuRow(b, _installCtrls[b]!, theme)),
                  Divider(color: theme.dividerColor),
                  const SizedBox(height: 8),
                  _label('PAQUETE COMPLETO', theme),
                  const SizedBox(height: 8),
                  ..._btuKeys.map((b) => _btuRow(b, _fullCtrls[b]!, theme)),
                  Divider(color: theme.dividerColor),
                  const SizedBox(height: 8),
                  _label('CARGOS ADICIONALES', theme),
                  const SizedBox(height: 8),
                  _namedRow('2do piso', _surcharge2Ctrl, theme),
                  _namedRow('Piso diferente', _surchargeDiffCtrl, theme),
                  _namedRow('Desc. multi-unidad', _discountCtrl, theme),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _savePricing,
                    child: Text('Guardar precios', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminTheme.primaryColor)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, ThemeData theme) {
    return Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: theme.textTheme.bodySmall?.color),
    );
  }

  Widget _btuRow(int btu, TextEditingController ctrl, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('$btu', style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color))),
          Expanded(child: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '\$', isDense: true))),
        ],
      ),
    );
  }

  Widget _namedRow(String label, TextEditingController ctrl, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color))),
          Expanded(child: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '\$', isDense: true))),
        ],
      ),
    );
  }
}
