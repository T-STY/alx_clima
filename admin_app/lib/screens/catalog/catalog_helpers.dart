import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alx_clima_admin/config/theme.dart';
import 'package:alx_clima_admin/widgets/sheet_widgets.dart';

Widget _imagePickerArea({
  required bool isDark,
  required File? pickedFile,
  required String? existingUrl,
  required bool isUploading,
  required VoidCallback onTap,
}) {
  Widget child;
  if (isUploading) {
    child = const SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  } else if (pickedFile != null) {
    child = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(pickedFile, fit: BoxFit.contain,
          width: double.infinity, height: double.infinity),
    );
  } else if (existingUrl != null && existingUrl.isNotEmpty) {
    child = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(existingUrl, fit: BoxFit.contain,
          width: double.infinity, height: double.infinity),
    );
  } else {
    child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Iconsax.gallery_add, size: 36,
            color: AdminTheme.primaryColor.withValues(alpha: 0.5)),
        const SizedBox(height: 6),
        Text(
          'Agregar imagen',
          style: GoogleFonts.exo2(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        border: Border.all(
          color: AdminTheme.primaryColor.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: child,
    ),
  );
}

Future<String?> _uploadImage(File file) async {
  final path = 'catalog_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
  final ref = FirebaseStorage.instance.ref().child(path);
  await ref.putFile(file);
  return ref.getDownloadURL();
}

Future<void> _pickImage(
  StateSetter setSt,
  void Function(File) onPicked,
) async {
  final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (xFile != null) {
    setSt(() => onPicked(File(xFile.path)));
  }
}

void showAddCatalogSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  String? selectedBrand;
  String? selectedModel;
  int? selectedBtu;
  File? pickedImage;
  bool isUploading = false;
  final priceCtrl = TextEditingController();
  final warrantyCtrl = TextEditingController(
    text: 'Garantía de fábrica de 5 años en compresor',
  );
  final descCtrl = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) {
        return frostedSheet(
          ctx,
          isDark,
          'Agregar equipo',
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('equipmentCatalog')
                .orderBy('order')
                .snapshots(),
            builder: (ctx, snap) {
              final brands = snap.data?.docs ?? [];
              final brandNames =
                  brands.map((b) => b['name'] as String).toList();
              final models = <String>[];
              if (selectedBrand != null) {
                final match = brands.where(
                  (b) => b['name'] == selectedBrand,
                );
                if (match.isNotEmpty) {
                  models.addAll(
                    (match.first['models'] as List).cast<String>(),
                  );
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _imagePickerArea(
                    isDark: isDark,
                    pickedFile: pickedImage,
                    existingUrl: null,
                    isUploading: isUploading,
                    onTap: () => _pickImage(
                      setSt,
                      (f) => pickedImage = f,
                    ),
                  ),
                  const SizedBox(height: 12),
                  sheetDropdown(
                    'Marca',
                    selectedBrand,
                    brandNames,
                    (v) => setSt(() {
                      selectedBrand = v;
                      selectedModel = null;
                    }),
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  sheetDropdown(
                    'Modelo',
                    selectedModel,
                    models,
                    (v) => setSt(() => selectedModel = v),
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  sheetDropdown<int>(
                    'BTU',
                    selectedBtu,
                    const [12000, 18000, 24000, 36000],
                    (v) => setSt(() => selectedBtu = v),
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  sheetInput(priceCtrl, 'Precio', isDark,
                      keyboard: TextInputType.number),
                  const SizedBox(height: 12),
                  sheetInput(warrantyCtrl, 'Garantía', isDark),
                  const SizedBox(height: 12),
                  sheetInput(descCtrl, 'Descripción (opcional)', isDark),
                  const SizedBox(height: 20),
                  sheetGradientButton('Guardar', () async {
                    if (selectedBrand == null ||
                        selectedModel == null ||
                        selectedBtu == null) return;

                    String? imageUrl;
                    if (pickedImage != null) {
                      setSt(() => isUploading = true);
                      imageUrl = await _uploadImage(pickedImage!);
                      setSt(() => isUploading = false);
                    }

                    final docData = <String, dynamic>{
                      'brand': selectedBrand,
                      'name': selectedModel,
                      'btuCapacity': selectedBtu,
                      'price': double.tryParse(priceCtrl.text) ?? 0,
                      'manufacturerWarrantyDetails': warrantyCtrl.text,
                      'description': descCtrl.text,
                      'type': 'miniSplit',
                    };
                    if (imageUrl != null) docData['imageUrl'] = imageUrl;

                    await FirebaseFirestore.instance
                        .collection('quoteCatalog')
                        .add(docData);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}

void showEditCatalogSheet(BuildContext context, DocumentSnapshot doc) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final data = doc.data() as Map<String, dynamic>;
  final priceCtrl =
      TextEditingController(text: '${data['price'] ?? ''}');
  final warrantyCtrl = TextEditingController(
    text: data['manufacturerWarrantyDetails'] ?? '',
  );
  final descCtrl =
      TextEditingController(text: data['description'] ?? '');
  File? pickedImage;
  bool isUploading = false;
  final existingImageUrl = data['imageUrl'] as String? ?? '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) {
        return frostedSheet(
          ctx,
          isDark,
          'Editar ${data['brand']} ${data['name']}',
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imagePickerArea(
                isDark: isDark,
                pickedFile: pickedImage,
                existingUrl: existingImageUrl,
                isUploading: isUploading,
                onTap: () => _pickImage(
                  setSt,
                  (f) => pickedImage = f,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Precio',
                style: GoogleFonts.exo2(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.exo2(fontSize: 14),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: GoogleFonts.exo2(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: '0.00',
                  hintStyle: GoogleFonts.exo2(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Garantía del fabricante',
                style: GoogleFonts.exo2(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 6),
              sheetInput(warrantyCtrl, 'Texto de garantía', isDark),
              const SizedBox(height: 16),
              Text(
                'Descripción',
                style: GoogleFonts.exo2(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: null,
                minLines: 3,
                style: GoogleFonts.exo2(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Descripción del equipo',
                  hintStyle: GoogleFonts.exo2(fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: sheetGlassButton(ctx, isDark, 'Eliminar',
                        () async {
                      await doc.reference.delete();
                      if (ctx.mounted) Navigator.pop(ctx);
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: sheetGradientButton('Guardar', () async {
                      final updateData = <String, dynamic>{
                        'price': double.tryParse(priceCtrl.text) ?? 0,
                        'manufacturerWarrantyDetails': warrantyCtrl.text,
                        'description': descCtrl.text,
                      };

                      if (pickedImage != null) {
                        setSt(() => isUploading = true);
                        final url = await _uploadImage(pickedImage!);
                        setSt(() => isUploading = false);
                        if (url != null) updateData['imageUrl'] = url;
                      }

                      await doc.reference.update(updateData);
                      if (ctx.mounted) Navigator.pop(ctx);
                    }),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
