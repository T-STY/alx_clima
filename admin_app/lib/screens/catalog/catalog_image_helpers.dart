import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alx_clima_admin/config/theme.dart';

Widget catalogImagePickerArea({
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
      child: Image.file(
        pickedFile,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  } else if (existingUrl != null && existingUrl.isNotEmpty) {
    child = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        existingUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  } else {
    child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Iconsax.gallery_add,
          size: 36,
          color: AdminTheme.primaryColor.withValues(alpha: 0.5),
        ),
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
        ),
      ),
      child: child,
    ),
  );
}

Future<String?> uploadCatalogImage(File file) async {
  final path = 'catalog_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
  final ref = FirebaseStorage.instance.ref().child(path);
  await ref.putFile(file);
  return ref.getDownloadURL();
}

Future<void> pickCatalogImage(
  StateSetter setSt,
  void Function(File) onPicked,
) async {
  final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (xFile != null) {
    setSt(() => onPicked(File(xFile.path)));
  }
}
