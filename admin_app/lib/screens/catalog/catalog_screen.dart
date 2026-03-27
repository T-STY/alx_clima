import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/admin_button.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _firestore = FirebaseFirestore.instance;

  void _showAddCatalogSheet() {
    String? selectedBrand;
    String? selectedModel;
    String? selectedBtu;
    final priceController = TextEditingController();
    final descController = TextEditingController();
    final warrantyController = TextEditingController(
      text: '5 años en compresor, 1 año en partes y accesorios.',
    );
    final btuOptions = ['12K', '18K', '24K', '36K'];
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AdminTheme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Agregar al Catálogo',
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('equipmentCatalog')
                          .orderBy('order')
                          .snapshots(),
                      builder: (ctx, snapshot) {
                        final brands = snapshot.data?.docs ?? [];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDropdownField<String>(
                              label: 'Marca',
                              value: selectedBrand,
                              items: brands.map((b) {
                                final name =
                                    (b.data() as Map<String, dynamic>)['name']
                                            as String? ??
                                        b.id;
                                return DropdownMenuItem(
                                  value: b.id,
                                  child: Text(name),
                                );
                              }).toList(),
                              onChanged: (v) {
                                setSheetState(() {
                                  selectedBrand = v;
                                  selectedModel = null;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            if (selectedBrand != null) ...[
                              Builder(
                                builder: (_) {
                                  final brandDoc = brands
                                      .where((b) => b.id == selectedBrand)
                                      .firstOrNull;
                                  final models = brandDoc != null
                                      ? List<String>.from(
                                          (brandDoc.data()
                                                      as Map<String, dynamic>)[
                                                  'models'] ??
                                              [],
                                        )
                                      : <String>[];
                                  return _buildDropdownField<String>(
                                    label: 'Modelo',
                                    value: selectedModel,
                                    items: models
                                        .map(
                                          (m) => DropdownMenuItem(
                                            value: m,
                                            child: Text(m),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      setSheetState(
                                        () => selectedModel = v,
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        );
                      },
                    ),
                    const Text(
                      'BTU',
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: btuOptions.map((btu) {
                        final selected = selectedBtu == btu;
                        return ChoiceChip(
                          label: Text(btu),
                          selected: selected,
                          selectedColor:
                              AdminTheme.primaryColor.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: selected
                                ? AdminTheme.primaryColor
                                : AdminTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: selected
                                ? AdminTheme.primaryColor
                                : AdminTheme.dividerColor,
                          ),
                          onSelected: (_) {
                            setSheetState(() => selectedBtu = btu);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: AdminTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        prefixText: '\$ ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: AdminTheme.textPrimary),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: warrantyController,
                      style: const TextStyle(color: AdminTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Garantía',
                      ),
                    ),
                    const SizedBox(height: 20),
                    AdminButton(
                      text: 'Agregar',
                      icon: Iconsax.add_circle,
                      isLoading: isSaving,
                      onPressed: () async {
                        if (selectedBrand == null ||
                            selectedModel == null ||
                            selectedBtu == null ||
                            priceController.text.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Completa los campos requeridos'),
                            ),
                          );
                          return;
                        }
                        setSheetState(() => isSaving = true);
                        await _firestore.collection('quoteCatalog').add({
                          'brand': selectedBrand,
                          'model': selectedModel,
                          'btu': selectedBtu,
                          'price': int.tryParse(priceController.text) ?? 0,
                          'description': descController.text,
                          'warranty': warrantyController.text,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        setSheetState(() => isSaving = false);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditCatalogItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final priceController =
        TextEditingController(text: '${data['price'] ?? ''}');
    final descController =
        TextEditingController(text: data['description'] ?? '');
    final warrantyController =
        TextEditingController(text: data['warranty'] ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AdminTheme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${data['brand']} ${data['model']} ${data['btu']}',
                    style: const TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: AdminTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      prefixText: '\$ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: AdminTheme.textPrimary),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: warrantyController,
                    style: const TextStyle(color: AdminTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Garantía',
                    ),
                  ),
                  const SizedBox(height: 20),
                  AdminButton(
                    text: 'Guardar',
                    icon: Iconsax.tick_circle,
                    isLoading: isSaving,
                    onPressed: () async {
                      setSheetState(() => isSaving = true);
                      await doc.reference.update({
                        'price': int.tryParse(priceController.text) ?? 0,
                        'description': descController.text,
                        'warranty': warrantyController.text,
                      });
                      setSheetState(() => isSaving = false);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 8),
                  AdminButton(
                    text: 'Eliminar',
                    icon: Iconsax.trash,
                    color: AdminTheme.errorColor,
                    isOutlined: true,
                    onPressed: () async {
                      await doc.reference.delete();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditBrand(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final models = List<String>.from(data['models'] ?? []);
    final modelController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AdminTheme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    data['name'] ?? doc.id,
                    style: const TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: models.map((m) {
                      return Chip(
                        label: Text(
                          m,
                          style: const TextStyle(
                            color: AdminTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: AdminTheme.surfaceColor,
                        deleteIcon: const Icon(
                          Iconsax.close_circle,
                          size: 16,
                          color: AdminTheme.errorColor,
                        ),
                        onDeleted: () {
                          setSheetState(() => models.remove(m));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: modelController,
                          style:
                              const TextStyle(color: AdminTheme.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Nuevo modelo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          if (modelController.text.trim().isEmpty) return;
                          setSheetState(() {
                            models.add(modelController.text.trim());
                            modelController.clear();
                          });
                        },
                        icon: const Icon(
                          Iconsax.add_circle,
                          color: AdminTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AdminButton(
                    text: 'Guardar',
                    icon: Iconsax.tick_circle,
                    isLoading: isSaving,
                    onPressed: () async {
                      setSheetState(() => isSaving = true);
                      await doc.reference.update({'models': models});
                      setSheetState(() => isSaving = false);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddBrandSheet() {
    final nameController = TextEditingController();
    final modelController = TextEditingController();
    final orderController = TextEditingController();
    final models = <String>[];
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AdminTheme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nueva Marca',
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: AdminTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: orderController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: const TextStyle(color: AdminTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Orden'),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: models.map((m) {
                        return Chip(
                          label: Text(
                            m,
                            style: const TextStyle(
                              color: AdminTheme.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          backgroundColor: AdminTheme.surfaceColor,
                          deleteIcon: const Icon(
                            Iconsax.close_circle,
                            size: 16,
                            color: AdminTheme.errorColor,
                          ),
                          onDeleted: () {
                            setSheetState(() => models.remove(m));
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: modelController,
                            style: const TextStyle(
                              color: AdminTheme.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Agregar modelo',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            if (modelController.text.trim().isEmpty) return;
                            setSheetState(() {
                              models.add(modelController.text.trim());
                              modelController.clear();
                            });
                          },
                          icon: const Icon(
                            Iconsax.add_circle,
                            color: AdminTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AdminButton(
                      text: 'Crear Marca',
                      icon: Iconsax.add_circle,
                      isLoading: isSaving,
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;
                        setSheetState(() => isSaving = true);
                        await _firestore.collection('equipmentCatalog').add({
                          'name': nameController.text.trim(),
                          'models': models,
                          'order': int.tryParse(orderController.text) ?? 0,
                        });
                        setSheetState(() => isSaving = false);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catálogo',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              _buildSectionHeader(
                'Equipos en Catálogo',
                trailing: AdminButton(
                  text: 'Agregar al Catálogo',
                  icon: Iconsax.add,
                  onPressed: _showAddCatalogSheet,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('quoteCatalog')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return _buildEmptyState('Sin equipos en el catálogo');
                  }

                  return Column(
                    children: docs.asMap().entries.map((entry) {
                      final data =
                          entry.value.data() as Map<String, dynamic>;
                      return GestureDetector(
                        onTap: () => _showEditCatalogItem(entry.value),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AdminTheme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: AdminTheme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AdminTheme.secondaryColor
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Iconsax.cpu,
                                  color: AdminTheme.secondaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${data['brand']} ${data['model']}',
                                      style: const TextStyle(
                                        color: AdminTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${data['btu']} · \$${data['price']}',
                                      style: const TextStyle(
                                        color: AdminTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Iconsax.edit_2,
                                color: AdminTheme.textSecondary,
                                size: 18,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(
                              duration: 300.ms,
                              delay: (100 + entry.key * 40).ms,
                            ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 28),

              _buildSectionHeader(
                'Marcas y Modelos',
                trailing: AdminButton(
                  text: 'Nueva Marca',
                  icon: Iconsax.add,
                  isOutlined: true,
                  onPressed: _showAddBrandSheet,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('equipmentCatalog')
                    .orderBy('order')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return _buildEmptyState('Sin marcas registradas');
                  }

                  return Column(
                    children: docs.asMap().entries.map((entry) {
                      final data =
                          entry.value.data() as Map<String, dynamic>;
                      final models =
                          List<String>.from(data['models'] ?? []);
                      return GestureDetector(
                        onTap: () => _showEditBrand(entry.value),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AdminTheme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: AdminTheme.dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AdminTheme.primaryColor
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Iconsax.building,
                                      color: AdminTheme.primaryColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      data['name'] ?? entry.value.id,
                                      style: const TextStyle(
                                        color: AdminTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Iconsax.arrow_right_3,
                                    color: AdminTheme.textSecondary,
                                    size: 18,
                                  ),
                                ],
                              ),
                              if (models.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: models.map((m) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AdminTheme.surfaceColor,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        m,
                                        style: const TextStyle(
                                          color: AdminTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ).animate().fadeIn(
                              duration: 300.ms,
                              delay: (200 + entry.key * 40).ms,
                            ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 28),

              _buildSectionHeader('Tipos de Equipo')
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms),

              const SizedBox(height: 12),

              _buildEquipmentTypesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentTypesSection() {
    final typeController = TextEditingController();

    return StreamBuilder<DocumentSnapshot>(
      stream:
          _firestore.collection('config').doc('equipmentTypes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final types = List<String>.from(data['types'] ?? []);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AdminTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminTheme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: types.map((t) {
                  return Chip(
                    label: Text(
                      t,
                      style: const TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    backgroundColor: AdminTheme.surfaceColor,
                    deleteIcon: const Icon(
                      Iconsax.close_circle,
                      size: 16,
                      color: AdminTheme.errorColor,
                    ),
                    onDeleted: () {
                      final updated = List<String>.from(types)..remove(t);
                      _firestore
                          .collection('config')
                          .doc('equipmentTypes')
                          .set({'types': updated});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: typeController,
                      style: const TextStyle(color: AdminTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Nuevo tipo de equipo',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (typeController.text.trim().isEmpty) return;
                      final updated = List<String>.from(types)
                        ..add(typeController.text.trim());
                      _firestore
                          .collection('config')
                          .doc('equipmentTypes')
                          .set({'types': updated});
                      typeController.clear();
                    },
                    icon: const Icon(
                      Iconsax.add_circle,
                      color: AdminTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: 350.ms);
      },
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AdminTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AdminTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AdminTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AdminTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminTheme.dividerColor),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AdminTheme.cardColor,
            hint: Text(
              'Seleccionar $label',
              style: const TextStyle(
                color: AdminTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            style: const TextStyle(
              color: AdminTheme.textPrimary,
              fontSize: 14,
            ),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
