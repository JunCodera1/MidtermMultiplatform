// ============================================================
// lib/widgets/product_image.dart
// Hiển thị hình sản phẩm (Base64 data URL, URL mạng hoặc placeholder)
// ============================================================

import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String image;
  final double size;
  final double radius;

  const ProductImage(
      {super.key, required this.image, this.size = 64, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: _content()),
    );
  }

  Widget _content() {
    if (image.isEmpty) return _placeholder();
    if (image.startsWith('data:image')) {
      try {
        final bytes = base64Decode(image.substring(image.indexOf(',') + 1));
        return Image.memory(bytes,
            fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder());
      } catch (_) {
        return _placeholder();
      }
    }
    return CachedNetworkImage(
      imageUrl: image,
      fit: BoxFit.cover,
      placeholder: (_, __) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.blue.shade50,
        child: Icon(Icons.inventory_2_outlined,
            size: size * 0.5, color: Colors.blue.shade300),
      );
}
