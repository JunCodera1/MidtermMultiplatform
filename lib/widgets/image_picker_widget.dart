// ============================================================
// lib/widgets/image_picker_widget.dart
// Widget chọn và preview ảnh trong form
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class ImagePickerWidget extends StatelessWidget {
  final XFile? selectedImage;     // Ảnh mới được chọn
  final String? currentImageUrl; // URL ảnh hiện tại (khi edit)
  final VoidCallback onPickImage;

  const ImagePickerWidget({
    super.key,
    this.selectedImage,
    this.currentImageUrl,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ảnh đại diện',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPickImage,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildContent(),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Nhấn để chọn ảnh từ thiết bị',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    // Ưu tiên hiển thị ảnh mới chọn
    if (selectedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                ? Image.network(selectedImage!.path, fit: BoxFit.cover)
                : FutureBuilder<Uint8List>(
                    future: selectedImage!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    },
                  ),
          ),
          // Overlay hint
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Đổi ảnh',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Hiển thị ảnh hiện tại (khi edit)
    if (currentImageUrl != null && currentImageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: currentImageUrl!.startsWith('data:image')
                ? Image.memory(
                    base64Decode(currentImageUrl!.substring(currentImageUrl!.indexOf(',') + 1)),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => _buildPlaceholder(),
                  )
                : CachedNetworkImage(
                    imageUrl: currentImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Đổi ảnh',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Placeholder khi chưa có ảnh
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn ảnh',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
