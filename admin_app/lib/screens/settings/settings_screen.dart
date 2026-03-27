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
  final _fs = FirebaseFirestore.instance;
  final _nc = TextEditingController(); final _pc = TextEditingController(); final _wc = TextEditingController();
  final _ec = TextEditingController(); final _hc = TextEditingController(); final _twc = TextEditingController();
  final _pr = <String, TextEditingController>{}; bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _nc.dispose(); _pc.dispose(); _wc.dispose(); _ec.dispose(); _hc.dispose(); _twc.dispose(); for (final c in _pr.values) c.dispose(); super.dispose(); }

  TextEditingController _c(String k, dynamic d) { _pr.putIfAbsent(k, () => TextEditingController(text: '$d')); return _pr[k]!; }

  Future<void> _load() async {
    final cd = await _fs.collection('company').doc('info').get(); final d = cd.data();
    if (d != null) { _nc.text = d['name'] ?? ''; _pc.text = d['phone'] ?? ''; _wc.text = d['whatsApp'] ?? ''; _ec.text = d['email'] ?? ''; _hc.text = d['businessHours'] ?? ''; _twc.text = d['techWarranty'] ?? '1 año general + 3 meses en electrónicos'; }
    final pd = await _fs.collection('config').doc('pricing').get(); final p = pd.data() ?? {};
    final io = (p['installOnly'] as Map<String, dynamic>?) ?? {}; final fp = (p['fullPackage'] as Map<String, dynamic>?) ?? {};
    for (final b in ['12000', '18000', '24000', '36000']) { _c('io$b', io[b] ?? 0); _c('fp$b', fp[b] ?? 0); }
    _c('sf', p['secondFloorSurcharge'] ?? 0.3); _c('df', p['differentFloorSurcharge'] ?? 0.25); _c('md', p['multiUnitDiscount'] ?? 0.1);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    final theme = Theme.of(context);
    return Scaffold(body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 32, 20, 36), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Ajustes', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8, fontSize: 26)).animate().fadeIn(duration: 350.ms).moveY(begin: -8, end: 0, duration: 350.ms),
      const SizedBox(height: 28),
      _sec(context, 'Información de la Empresa', Iconsax.building, [
        _f(_nc, 'Nombre', Iconsax.building), _f(_pc, 'Teléfono', Iconsax.call), _f(_wc, 'WhatsApp', Iconsax.message),
        _f(_ec, 'Correo', Iconsax.sms), _f(_hc, 'Horario de atención', Iconsax.clock), _f(_twc, 'Garantía del técnico', Iconsax.shield_tick),
        const SizedBox(height: 14), AdminButton(text: 'Guardar Empresa', icon: Iconsax.tick_circle, onPressed: _saveCo),
      ]),
      const SizedBox(height: 18),
      _sec(context, 'Precios - Solo Instalación', Iconsax.money, [
        Text('Cliente ya tiene equipo', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)), const SizedBox(height: 10), ..._pf('io'),
      ]),
      const SizedBox(height: 18),
      _sec(context, 'Precios - Equipo + Instalación', Iconsax.money, [
        Text('Compra equipo contigo', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)), const SizedBox(height: 10), ..._pf('fp'),
      ]),
      const SizedBox(height: 18),
      _sec(context, 'Recargos y Descuentos', Iconsax.discount_shape, [
        _f(_c('sf', 0), 'Recargo segundo piso (0.3 = 30%)', Iconsax.building_4, n: true),
        _f(_c('df', 0), 'Recargo compresor piso diferente', Iconsax.arrow_swap, n: true),
        _f(_c('md', 0), 'Descuento multi-equipo (0.1 = 10%)', Iconsax.discount_shape, n: true),
        const SizedBox(height: 14), AdminButton(text: 'Guardar Precios', icon: Iconsax.tick_circle, onPressed: _savePr),
      ]),
    ]))));
  }

  Future<void> _saveCo() async {
    await _fs.collection('company').doc('info').set({'name': _nc.text.trim(), 'phone': _pc.text.trim(), 'whatsApp': _wc.text.trim(), 'email': _ec.text.trim(), 'businessHours': _hc.text.trim(), 'techWarranty': _twc.text.trim()});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Información actualizada'), backgroundColor: AdminTheme.successColor));
  }

  Future<void> _savePr() async {
    await _fs.collection('config').doc('pricing').set({
      'installOnly': {'12000': num.tryParse(_c('io12000', 0).text) ?? 0, '18000': num.tryParse(_c('io18000', 0).text) ?? 0, '24000': num.tryParse(_c('io24000', 0).text) ?? 0, '36000': num.tryParse(_c('io36000', 0).text) ?? 0},
      'fullPackage': {'12000': num.tryParse(_c('fp12000', 0).text) ?? 0, '18000': num.tryParse(_c('fp18000', 0).text) ?? 0, '24000': num.tryParse(_c('fp24000', 0).text) ?? 0, '36000': num.tryParse(_c('fp36000', 0).text) ?? 0},
      'secondFloorSurcharge': num.tryParse(_c('sf', 0).text) ?? 0.3, 'differentFloorSurcharge': num.tryParse(_c('df', 0).text) ?? 0.25, 'multiUnitDiscount': num.tryParse(_c('md', 0).text) ?? 0.1,
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Precios actualizados'), backgroundColor: AdminTheme.successColor));
  }

  Widget _sec(BuildContext ctx, String title, IconData ic, List<Widget> ch) {
    final theme = Theme.of(ctx);
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4), width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AdminTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(9)), child: Icon(ic, size: 16, color: AdminTheme.primaryColor)),
          const SizedBox(width: 10), Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.2))]),
        const SizedBox(height: 18), ...ch,
      ]),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _f(TextEditingController c, String l, IconData ic, {bool n = false}) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: c, keyboardType: n ? TextInputType.number : null, decoration: InputDecoration(labelText: l, prefixIcon: Icon(ic, size: 18))));
  }

  List<Widget> _pf(String p) {
    const b = ['12000', '18000', '24000', '36000']; const l = ['12K BTU', '18K BTU', '24K BTU', '36K BTU'];
    return List.generate(b.length, (i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: _c('$p${b[i]}', 0), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l[i], prefixIcon: const Icon(Iconsax.money, size: 18), prefixText: '\$ '))));
  }
}
