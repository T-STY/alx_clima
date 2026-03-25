import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import 'package:alx_clima/config/theme.dart';
import 'package:alx_clima/widgets/futuristic_button.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Horarios'),
            Tab(text: 'Precios'),
            Tab(text: 'Catálogo'),
            Tab(text: 'Empresa'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ScheduleTab(firestore: _firestore),
          _PricingTab(firestore: _firestore),
          _CatalogTab(firestore: _firestore),
          _CompanyTab(firestore: _firestore),
        ],
      ),
    );
  }
}

class _ScheduleTab extends StatefulWidget {
  final FirebaseFirestore firestore;
  const _ScheduleTab({required this.firestore});

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  final _dateController = TextEditingController();
  final _slotsController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
    _slotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agregar Disponibilidad',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 120)),
              );
              if (picked != null) {
                _dateController.text =
                    DateFormat('yyyy-MM-dd').format(picked);
              }
            },
            child: AbsorbPointer(
              child: TextField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Fecha (yyyy-MM-dd)',
                  prefixIcon: Icon(Iconsax.calendar_1, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _slotsController,
            decoration: const InputDecoration(
              labelText: 'Horarios (separados por coma)',
              hintText: '9:00 - 11:00, 11:00 - 13:00, 14:00 - 16:00',
              prefixIcon: Icon(Iconsax.clock, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          FuturisticButton(
            text: 'Guardar Horarios',
            icon: Iconsax.tick_circle,
            onPressed: () async {
              final date = _dateController.text.trim();
              final slotsText = _slotsController.text.trim();
              if (date.isEmpty || slotsText.isEmpty) return;

              final slots = slotsText
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();

              await widget.firestore
                  .collection('schedule')
                  .doc(date)
                  .set({'slots': slots});

              if (mounted) {
                _dateController.clear();
                _slotsController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Horarios guardados'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 28),
          Text(
            'Horarios Existentes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: widget.firestore
                .collection('schedule')
                .orderBy(FieldPath.documentId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Text(
                  'Sin horarios configurados',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              return Column(
                children: docs.map((doc) {
                  final slots = (doc['slots'] as List?)
                          ?.cast<String>()
                          .join(', ') ??
                      '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.id,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                              Text(
                                slots,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => doc.reference.delete(),
                          icon: const Icon(Iconsax.trash,
                              size: 18, color: AppTheme.errorColor),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PricingTab extends StatefulWidget {
  final FirebaseFirestore firestore;
  const _PricingTab({required this.firestore});

  @override
  State<_PricingTab> createState() => _PricingTabState();
}

class _PricingTabState extends State<_PricingTab> {
  final _controllers = <String, TextEditingController>{};
  bool _isLoading = true;
  Map<String, dynamic> _pricing = {};

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPricing() async {
    final doc = await widget.firestore
        .collection('config')
        .doc('pricing')
        .get();
    if (mounted) {
      setState(() {
        _pricing = doc.data() ?? {};
        _isLoading = false;
      });
    }
  }

  TextEditingController _ctrl(String key, dynamic defaultVal) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] =
          TextEditingController(text: '$defaultVal');
    }
    return _controllers[key]!;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final installOnly =
        (_pricing['installOnly'] as Map<String, dynamic>?) ?? {};
    final fullPackage =
        (_pricing['fullPackage'] as Map<String, dynamic>?) ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solo Instalación',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ..._buildPriceFields('io', installOnly),
          const SizedBox(height: 20),
          Text(
            'Paquete Completo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ..._buildPriceFields('fp', fullPackage),
          const SizedBox(height: 20),
          Text(
            'Recargos y Descuentos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl('secondFloor',
                _pricing['secondFloorSurcharge'] ?? 0.3),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Recargo segundo piso (ej. 0.3 = 30%)',
              prefixIcon: Icon(Iconsax.building_4, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl('diffFloor',
                _pricing['differentFloorSurcharge'] ?? 0.25),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Recargo compresor piso diferente',
              prefixIcon: Icon(Iconsax.arrow_swap, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl(
                'multiDiscount',
                _pricing['multiUnitDiscount'] ?? 0.1),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Descuento multi-equipo (ej. 0.1 = 10%)',
              prefixIcon: Icon(Iconsax.discount_shape, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          FuturisticButton(
            text: 'Guardar Precios',
            icon: Iconsax.tick_circle,
            onPressed: _savePricing,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPriceFields(
      String prefix, Map<String, dynamic> prices) {
    const btus = ['12000', '18000', '24000', '36000'];
    const labels = ['12K BTU', '18K BTU', '24K BTU', '36K BTU'];
    return List.generate(btus.length, (i) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller:
              _ctrl('$prefix${btus[i]}', prices[btus[i]] ?? 0),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: labels[i],
            prefixIcon: const Icon(Iconsax.money, size: 20),
            prefixText: '\$ ',
          ),
        ),
      );
    });
  }

  Future<void> _savePricing() async {
    final data = <String, dynamic>{
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
      'secondFloorSurcharge':
          num.tryParse(_ctrl('secondFloor', 0).text) ?? 0.3,
      'differentFloorSurcharge':
          num.tryParse(_ctrl('diffFloor', 0).text) ?? 0.25,
      'multiUnitDiscount':
          num.tryParse(_ctrl('multiDiscount', 0).text) ?? 0.1,
    };

    await widget.firestore
        .collection('config')
        .doc('pricing')
        .set(data);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Precios actualizados'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}

class _CatalogTab extends StatefulWidget {
  final FirebaseFirestore firestore;
  const _CatalogTab({required this.firestore});

  @override
  State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Equipos en Catálogo',
                style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
              ),
              IconButton(
                onPressed: () => _showAddEquipmentDialog(context),
                icon: const Icon(Iconsax.add_circle,
                    color: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: widget.firestore
                .collection('quoteCatalog')
                .orderBy('order')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Text(
                  'Sin equipos en el catálogo',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${data['brand']} - ${data['name']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                              Text(
                                '${data['btuCapacity']} BTU \u00b7 \$${data['price']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => doc.reference.delete(),
                          icon: const Icon(Iconsax.trash,
                              size: 18,
                              color: AppTheme.errorColor),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Marcas (Agregar Equipo)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _BrandManager(firestore: widget.firestore),
        ],
      ),
    );
  }

  void _showAddEquipmentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final btuCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final warrantyCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: '10');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Agregar al Catálogo',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: brandCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Marca'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nombre / Modelo'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: btuCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'BTU'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Precio'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: orderCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Orden'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Descripción'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: warrantyCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Detalles de garantía'),
                ),
                const SizedBox(height: 16),
                FuturisticButton(
                  text: 'Agregar',
                  icon: Iconsax.add_circle,
                  onPressed: () async {
                    await widget.firestore
                        .collection('quoteCatalog')
                        .add({
                      'name': nameCtrl.text.trim(),
                      'brand': brandCtrl.text.trim(),
                      'type': 'miniSplit',
                      'btuCapacity':
                          int.tryParse(btuCtrl.text) ?? 12000,
                      'price':
                          double.tryParse(priceCtrl.text) ?? 0,
                      'description': descCtrl.text.trim(),
                      'manufacturerWarrantyDetails':
                          warrantyCtrl.text.trim(),
                      'order':
                          int.tryParse(orderCtrl.text) ?? 10,
                    });
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BrandManager extends StatefulWidget {
  final FirebaseFirestore firestore;
  const _BrandManager({required this.firestore});

  @override
  State<_BrandManager> createState() => _BrandManagerState();
}

class _BrandManagerState extends State<_BrandManager> {
  final _nameCtrl = TextEditingController();
  final _modelsCtrl = TextEditingController();
  final _orderCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _modelsCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre de marca',
            prefixIcon: Icon(Iconsax.tag, size: 20),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _modelsCtrl,
          decoration: const InputDecoration(
            labelText: 'Modelos (separados por coma)',
            hintText: 'Modelo A, Modelo B, Modelo C',
            prefixIcon: Icon(Iconsax.cpu_setting, size: 20),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _orderCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Orden (1 = primero)',
            prefixIcon: Icon(Iconsax.sort, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        FuturisticButton(
          text: 'Guardar Marca',
          icon: Iconsax.tick_circle,
          onPressed: () async {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;

            final models = _modelsCtrl.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();

            await widget.firestore
                .collection('equipmentCatalog')
                .doc(name.toLowerCase().replaceAll(' ', '_'))
                .set({
              'name': name,
              'models': models,
              'order': int.tryParse(_orderCtrl.text) ?? 1,
            });

            if (mounted) {
              _nameCtrl.clear();
              _modelsCtrl.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Marca guardada'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: widget.firestore
              .collection('equipmentCatalog')
              .orderBy('order')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final docs = snapshot.data!.docs;
            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final models =
                    (data['models'] as List?)?.join(', ') ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? doc.id,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            if (models.isNotEmpty)
                              Text(
                                models,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => doc.reference.delete(),
                        icon: const Icon(Iconsax.trash,
                            size: 18,
                            color: AppTheme.errorColor),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CompanyTab extends StatefulWidget {
  final FirebaseFirestore firestore;
  const _CompanyTab({required this.firestore});

  @override
  State<_CompanyTab> createState() => _CompanyTabState();
}

class _CompanyTabState extends State<_CompanyTab> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsAppCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsAppCtrl.dispose();
    _emailCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyInfo() async {
    final doc = await widget.firestore
        .collection('company')
        .doc('info')
        .get();
    final data = doc.data();
    if (data != null && mounted) {
      _nameCtrl.text = data['name'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
      _whatsAppCtrl.text = data['whatsApp'] ?? '';
      _emailCtrl.text = data['email'] ?? '';
      _hoursCtrl.text = data['businessHours'] ?? '';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información de la Empresa',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Iconsax.building, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              prefixIcon: Icon(Iconsax.call, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _whatsAppCtrl,
            decoration: const InputDecoration(
              labelText: 'WhatsApp (solo números)',
              prefixIcon: Icon(Iconsax.message, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Iconsax.sms, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hoursCtrl,
            decoration: const InputDecoration(
              labelText: 'Horario de atención',
              prefixIcon: Icon(Iconsax.clock, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          FuturisticButton(
            text: 'Guardar',
            icon: Iconsax.tick_circle,
            onPressed: () async {
              await widget.firestore
                  .collection('company')
                  .doc('info')
                  .set({
                'name': _nameCtrl.text.trim(),
                'phone': _phoneCtrl.text.trim(),
                'whatsApp': _whatsAppCtrl.text.trim(),
                'email': _emailCtrl.text.trim(),
                'businessHours': _hoursCtrl.text.trim(),
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Información actualizada'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
