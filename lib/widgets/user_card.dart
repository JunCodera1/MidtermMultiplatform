// ============================================================
// lib/widgets/user_card.dart
// Card hiển thị thông tin một user trong danh sách
// ============================================================

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'user_avatar.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UserCard({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            UserAvatar(
              imageUrl: user.image,
              username: user.username,
              radius: 30,
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Email
                  Row(
                    children: [
                      Icon(Icons.email_outlined,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Password (ẩn dạng dots)
                  Row(
                    children: [
                      Icon(Icons.lock_outline,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '••••••',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Column(
              children: [
                // Edit button
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  color: Colors.blue.shade700,
                  tooltip: 'Sửa',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                  ),
                ),
                const SizedBox(height: 4),
                // Delete button
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red.shade700,
                  tooltip: 'Xóa',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
