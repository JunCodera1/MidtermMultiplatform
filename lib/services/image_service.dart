// ============================================================
// lib/services/image_service.dart
// Service xử lý chọn và upload ảnh lên Firebase Storage
// ============================================================

import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Chọn ảnh từ Gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (xFile == null) return null;
      return xFile;
    } catch (e) {
      return null;
    }
  }

  /// Chọn ảnh từ Camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? xFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (xFile == null) return null;
      return xFile;
    } catch (e) {
      return null;
    }
  }

  /// Chuyển ảnh thành data URL để lưu trực tiếp vào field 'image'.
  /// Cách này hoạt động trên Firebase Spark, không yêu cầu billing/Storage.
  Future<String?> uploadImage({
    required XFile imageFile,
    required String userId,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (e) {
      return null;
    }
  }

  /// Xóa ảnh cũ trên Storage (nếu có)
  Future<void> deleteImage(String imageUrl) async {
    // Ảnh được lưu cùng document Firestore nên không có file Storage riêng.
  }
}
