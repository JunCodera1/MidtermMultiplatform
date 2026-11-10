// ============================================================
// lib/utils/validators.dart
// Validate input cho các form
// ============================================================

class Validators {
  /// Validate username - không được rỗng
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username không được để trống';
    }
    if (value.trim().length < 3) {
      return 'Username phải có ít nhất 3 ký tự';
    }
    return null;
  }

  /// Validate email - đúng format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email không được để trống';
    }
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

  /// Validate password - không được rỗng
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password không được để trống';
    }
    if (value.length < 6) {
      return 'Password phải có ít nhất 6 ký tự';
    }
    return null;
  }

  /// Validate login email/username
  static String? validateLoginField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Trường này không được để trống';
    }
    return null;
  }
}
