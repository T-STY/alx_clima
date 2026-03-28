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
  static const _btuLabels = ['12K', '18K', '24K', '36K'];

  final _maintenanceCtrls = <String, TextEditingController>{};
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
      _maintenanceCtrls[b] = TextEditingController();
      _installCtrls[b] = TextEditingController();
      _fullCtrls[b] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final m in [_maintenanceCtrls, _installCtrls, _fullCtrls]) {
      for (final c in m.values) {
        c.dispose();
      }
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
      final maintenance =
          d['maintenance'] as Map<String, dynamic>? ?? {};
      final install = d['installOnly'] as Map<String, dynamic>? ?? {};
      final full = d['fullPackage'] as Map<String, dynamic>? ?? {};
      for (final b in _btus) {
        _maintenanceCtrls[b]!.text = '${maintenance[b] ?? ''}';
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
    final maintenanceMap = <String, num>{};
    final installMap = <String, num>{};
    final fullMap = <String, num>{};
    for (final b in _btus) {
      maintenanceMap[b] = num.tryParse(_maintenanceCtrls[b]!.text) ?? 0;
      installMap[b] = num.tryParse(_installCtrls[b]!.text) ?? 0;
      fullMap[b] = num.tryParse(_fullCtrls[b]!.text) ?? 0;
    }

    await FirebaseFirestore.instance
        .collection('config')
        .doc('pricing')
        .set({
      'maintenance': maintenanceMap,
      'installOnly': installMap,
      'fullPackage': fullMap,
      'secondFloorSurcharge': num.tryParse(_secondFloorCtrl.text) ?? 0,
      'differentFloorSurcharge': num.tryParse(_diffFloorCtrl.text) ?? 0,
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
        title: Text(
          'Precios',
          style: GoogleFonts.exo2(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder(
        future: _load(),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
            children: [
              _sectionHeader(Iconsax.setting_4, 'Mantenimiento'),
              GlassCard(child: _btuGrid(_maintenanceCtrls)),
              const SizedBox(height: 8),
              _sectionHeader(Iconsax.cpu_setting, 'Solo Instalación'),
              GlassCard(child: _btuGrid(_installCtrls)),
              const SizedBox(height: 8),
              _sectionHeader(Iconsax.box_1, 'Equipo + Instalación'),
              GlassCard(child: _btuGrid(_fullCtrls)),
              const SizedBox(height: 8),
              _sectionHeader(Iconsax.arrow_up_3, 'Recargos'),
              GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _labeledField(
                      'Segundo piso',
                      _secondFloorCtrl,
                      'Ej. 0.3',
                    ),
                    const SizedBox(height: 10),
                    _labeledField(
                      'Compresor en piso diferente',
                      _diffFloorCtrl,
                      'Ej. 0.3',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _sectionHeader(Iconsax.discount_shape, 'Descuentos'),
              GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _labeledField(
                      'Descuento multi-equipo',
                      _multiCtrl,
                      'Ej. 0.1',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _saveButton(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AdminTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.exo2(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AdminTheme.primaryColor,
          )),
        ]),
      );

  Widget _btuGrid(Map<String, TextEditingController> ctrls) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_btus.length, (i) {
            return SizedBox(
              width: w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_btuLabels[i]} BTU',
              style: GoogleFonts.exo2(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AdminTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: TextField(
                controller: ctrls[_btus[i]],
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
          }),
        );
      },
    );
  }

  static final _labelStyle = GoogleFonts.exo2(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AdminTheme.secondaryColor,
  );

  Widget _labeledField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: GoogleFonts.exo2(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.exo2(fontSize: 14),
            prefixIcon: const Icon(Iconsax.dollar_circle, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _saveButton() => GestureDetector(
        onTap: _save,
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
