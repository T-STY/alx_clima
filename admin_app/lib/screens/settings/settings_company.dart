import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/glass_card.dart';

class CompanyInfoPage extends StatefulWidget {
  const CompanyInfoPage({super.key});

  @override
  State<CompanyInfoPage> createState() => _CompanyInfoPageState();
}

class _CompanyInfoPageState extends State<CompanyInfoPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsAppCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _warrantyCtrl = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsAppCtrl.dispose();
    _emailCtrl.dispose();
    _hoursCtrl.dispose();
    _warrantyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loaded) return;
    final doc = await FirebaseFirestore.instance
        .collection('company')
        .doc('info')
        .get();
    if (doc.exists) {
      final d = doc.data()!;
      _nameCtrl.text = d['name'] ?? '';
      _phoneCtrl.text = d['phone'] ?? '';
      _whatsAppCtrl.text = d['whatsApp'] ?? '';
      _emailCtrl.text = d['email'] ?? '';
      _hoursCtrl.text = d['businessHours'] ?? '';
      _warrantyCtrl.text = d['techWarranty'] ?? '';
    }
    _loaded = true;
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance
        .collection('company')
        .doc('info')
        .set({
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'whatsApp': _whatsAppCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'businessHours': _hoursCtrl.text.trim(),
      'techWarranty': _warrantyCtrl.text.trim(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Información guardada',
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
        title: Text('Empresa', style: GoogleFonts.exo2(fontWeight: FontWeight.w600)),
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
                  children: [
              _field(_nameCtrl, 'Nombre', Iconsax.building),
              const SizedBox(height: 10),
              _field(_phoneCtrl, 'Teléfono', Iconsax.call),
              const SizedBox(height: 10),
              _field(_whatsAppCtrl, 'WhatsApp', Iconsax.message),
              const SizedBox(height: 10),
              _field(_emailCtrl, 'Email', Iconsax.sms),
              const SizedBox(height: 10),
              _field(_hoursCtrl, 'Horario', Iconsax.clock),
              const SizedBox(height: 10),
              _field(_warrantyCtrl, 'Garantía técnica', Iconsax.shield_tick),
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
}

Widget _field(
  TextEditingController ctrl,
  String hint,
  IconData icon,
) {
  return TextField(
    controller: ctrl,
    style: GoogleFonts.exo2(fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.exo2(fontSize: 14),
      prefixIcon: Icon(icon, size: 18),
    ),
  );
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
