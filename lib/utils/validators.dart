// ============================================================
// lib/utils/validators.dart
// Validate dữ liệu nhập
// ============================================================

import 'limits.dart';

class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email không được để trống';
    }
    final regex = RegExp(r'^[\w\-.+]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Email không đúng định dạng';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Mật khẩu không được để trống';
    if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  /// Trường bắt buộc (dùng cho ô mật khẩu ở màn hình đăng nhập)
  static String? validateLoginField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Trường này không được để trống';
    }
    return null;
  }

  static String? validateProductName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tên sản phẩm không được để trống';
    }
    if (value.trim().length < 2) return 'Tên sản phẩm phải có ít nhất 2 ký tự';
    return null;
  }

  /// Giá: số không âm (chấp nhận dấu chấm thập phân)
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Giá không được để trống';
    final n = num.tryParse(value.trim());
    if (n == null) return 'Giá phải là một số';
    if (n < 0) return 'Giá không được âm';
    if (n > maxPrice) return 'Giá quá lớn (tối đa $maxPrice)';
    return null;
  }

  /// Số lượng: số nguyên không âm
  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Số lượng không được để trống';
    }
    final n = int.tryParse(value.trim());
    if (n == null) return 'Số lượng phải là số nguyên';
    if (n < 0) return 'Số lượng không được âm';
    if (n > maxQuantity) return 'Số lượng quá lớn (tối đa $maxQuantity)';
    return null;
  }
}
