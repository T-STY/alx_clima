import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  static const _btus = ['12000', '18000', '24000', '36000'];

  final _installCtrls = <String, TextEditingController>{};
  final _fullCtrls = <String, TextEditingController>{};
  final _secondFloorCtrl = TextEditingController();
  final _diffFloorCtrl = TextEditingController();
  final _multiCtrl = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    for (final b in _btus) {
      _installCtrls[b] = TextEditingController();
      _fullCtrls[b] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _installCtrls.values) {
      c.dispose();
    }
    for (final c in _fullCtrls.values) {
      c.dispose();
    }
    _secondFloorCtrl.dispose();
    _diffFloorCtrl.dispose();
    _multiCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loaded) return;
    final doc = await FirebaseFirestore.instance
        .collection('config')
        .doc('pricing')
        .get();
    if (doc.exists) {
      final d = doc.data()!;
      final install = d['installOnly'] as Map<String, dynamic>? ?? {};
      final full = d['fullPackage'] as Map<String, dynamic>? ?? {};
      for (final b in _btus) {
        _installCtrls[b]!.text = '${install[b] ?? ''}';
        _fullCtrls[b]!.text = '${full[b] ?? ''}';
      }
      _secondFloorCtrl.text = '${d['secondFloorSurcharge'] ?? ''}';
      _diffFloorCtrl.text = '${d['differentFloorSurcharge'] ?? ''}';
      _multiCtrl.text = '${d['multiUnitDiscount'] ?? ''}';
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final installMap = <String, num>{};
    final fullMap = <String, num>{};
    for (final b in _btus) {
      installMap[b] = num.tryParse(_installCtrls[b]!.text) ?? 0;
      fullMap[b] = num.tryParse(_fullCtrls[b]!.text) ?? 0;
    }

    await FirebaseFirestore.instance
        .collection('config')
        .doc('pricing')
        .set({
      'installOnly': installMap,
      'fullPackage': fullMap,
      'secondFloorSurcharge':
          num.tryParse(_secondFloorCtrl.text) ?? 0,
      'differentFloorSurcharge':
          num.tryParse(_diffFloorCtrl.text) ?? 0,
      'multiUnitDiscount': num.tryParse(_multiCtrl.text) ?? 0,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Precios guardados',
            style: GoogleFonts.exo2(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Precios', style: GoogleFonts.exo2(fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context)),
      ),
      body: FutureBuilder(
        future: _load(),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              _label('Solo instalación'),
              const SizedBox(height: 8),
              ..._btus.map((b) => _btuRow(b, _installCtrls[b]!)),
              const SizedBox(height: 16),
              _label('Paquete completo'),
              const SizedBox(height: 8),
              ..._btus.map((b) => _btuRow(b, _fullCtrls[b]!)),
              const SizedBox(height: 16),
              _label('Recargos y descuento'),
              const SizedBox(height: 8),
              _surchargeRow('2do piso', _secondFloorCtrl),
              _surchargeRow('Piso diferente', _diffFloorCtrl),
              _surchargeRow('Desc. múltiple', _multiCtrl),
              const SizedBox(height: 16),
              _saveButton(_save),
            ],
          ),
        ),
      ],
    );
        },
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.exo2(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: AdminTheme.secondaryColor,
      ),
    );
  }

  Widget _btuRow(String btu, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$btu BTU',
              style: GoogleFonts.exo2(fontSize: 12),
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.exo2(fontSize: 13),
              decoration: InputDecoration(
                hintText: '\$',
                hintStyle: GoogleFonts.exo2(fontSize: 13),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _surchargeRow(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.exo2(fontSize: 12),
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.exo2(fontSize: 13),
              decoration: InputDecoration(
                hintText: '0.0',
                hintStyle: GoogleFonts.exo2(fontSize: 13),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _saveButton(VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: AdminTheme.primaryGradient,
      ),
      child: Center(
        child: Text(
          'Guardar',
          style: GoogleFonts.exo2(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}
