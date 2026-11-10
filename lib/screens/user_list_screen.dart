// ============================================================
// lib/screens/user_list_screen.dart
// Màn hình Admin Dashboard - Danh sách người dùng
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../widgets/user_card.dart';
import '../widgets/loading_overlay.dart';
import 'login_screen.dart';
import 'add_user_screen.dart';
import 'edit_user_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    // Load danh sách users khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers();
    });
  }

  /// Hiển thị dialog xác nhận xóa
  void _showDeleteDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc muốn xóa người dùng này không?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Username: ${user.username}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Email: ${user.email}',
                      style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hành động này không thể hoàn tác!',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Hủy',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteUser(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  /// Thực hiện xóa user
  Future<void> _deleteUser(UserModel user) async {
    final userProvider = context.read<UserProvider>();
    final success = await userProvider.deleteUser(user.id!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(success
                  ? 'Xóa người dùng thành công!'
                  : userProvider.errorMessage ?? 'Có lỗi xảy ra'),
            ],
          ),
          backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  /// Đăng xuất
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return LoadingOverlay(
          isLoading: userProvider.isOperating,
          message: 'Đang xử lý...',
          child: Scaffold(
            backgroundColor: Colors.grey.shade100,
            appBar: AppBar(
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Quản lý người dùng',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.blue.shade800,
              elevation: 0,
              actions: [
                // User count badge
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${userProvider.users.length} users',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Logout button
                IconButton(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Đăng xuất',
                ),
              ],
            ),
            body: _buildBody(userProvider),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddUserScreen()),
                );
                if (result == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Thêm người dùng thành công!'),
                        ],
                      ),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              },
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: const Text('Thêm user'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(UserProvider userProvider) {
    // Loading state
    if (userProvider.isLoading && userProvider.users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải danh sách người dùng...'),
          ],
        ),
      );
    }

    // Error state
    if (userProvider.state == UserState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              userProvider.errorMessage ?? 'Có lỗi xảy ra',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<UserProvider>().loadUsers(),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (userProvider.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có người dùng nào',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn nút + để thêm người dùng mới',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    // User list
    return RefreshIndicator(
      onRefresh: () async {
        context.read<UserProvider>().loadUsers();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: userProvider.users.length,
        itemBuilder: (context, index) {
          final user = userProvider.users[index];
          return UserCard(
            user: user,
            onEdit: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditUserScreen(user: user),
                ),
              );
              if (result == true && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Cập nhật người dùng thành công!'),
                      ],
                    ),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }
            },
            onDelete: () => _showDeleteDialog(context, user),
          );
        },
      ),
    );
  }
}
