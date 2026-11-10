// ============================================================
// lib/screens/login_screen.dart
// Màn hình đăng nhập Admin
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';
import 'user_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          message: 'Đang đăng nhập...',
          child: Scaffold(
            backgroundColor: Colors.blue.shade900,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo / Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đăng nhập để quản lý người dùng',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Form Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Đăng nhập',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Email hoặc username field
                              CustomTextField(
                                controller: _emailController,
                                label: 'Email hoặc Username',
                                hint: 'admin@example.com hoặc admin',
                                prefixIcon: Icons.person_outline,
                                keyboardType: TextInputType.text,
                                validator: Validators.validateLoginField,
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              CustomTextField(
                                controller: _passwordController,
                                label: 'Mật khẩu',
                                hint: 'Nhập mật khẩu',
                                prefixIcon: Icons.lock_outline,
                                isPassword: true,
                                validator: Validators.validateLoginField,
                              ),
                              const SizedBox(height: 16),

                              // Error message
                              if (authProvider.errorMessage != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.red.shade700,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          authProvider.errorMessage!,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              if (authProvider.errorMessage != null)
                                const SizedBox(height: 16),

                              // Login button
                              ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Hint text
                      Text(
                        'Chỉ Admin mới có quyền truy cập',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
