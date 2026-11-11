// ============================================================
// lib/providers/auth_provider.dart
// Provider quản lý trạng thái authentication
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  User? get currentUser => _authService.currentUser;

  AuthProvider() {
    // Lắng nghe trạng thái auth từ Firebase
    _authService.authStateChanges.listen((User? user) {
      if (user != null) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  /// Đăng nhập
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final error = await _authService.signIn(
      email: email,
      password: password,
    );

    _isLoading = false;

    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  /// Đăng ký tài khoản mới
  Future<bool> register({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final error = await _authService.register(
      email: email,
      password: password,
    );

    _isLoading = false;
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  /// Quên mật khẩu: trả về null nếu đã gửi email, ngược lại trả về lỗi
  Future<String?> sendPasswordReset(String email) =>
      _authService.sendPasswordReset(email);

  /// Đăng xuất
  Future<void> signOut() async {
    await _authService.signOut();
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Xóa error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
