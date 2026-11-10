// ============================================================
// lib/widgets/user_avatar.dart
// Widget hiển thị avatar của user
// ============================================================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final String username;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    required this.username,
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildDefaultAvatar();
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final encoded = imageUrl.substring(imageUrl.indexOf(',') + 1);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(base64Decode(encoded)),
        );
      } catch (_) {
        return _buildDefaultAvatar();
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue.shade100,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildLoadingAvatar(),
          errorWidget: (context, url, error) => _buildDefaultAvatar(),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue.shade700,
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue.shade100,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
