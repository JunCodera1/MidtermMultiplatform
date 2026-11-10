// ============================================================
// lib/providers/user_provider.dart
// Provider quản lý trạng thái danh sách users và CRUD operations
// ============================================================

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/image_service.dart';

enum UserState { initial, loading, loaded, error }

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final ImageService _imageService = ImageService();

  List<UserModel> _users = [];
  UserState _state = UserState.initial;
  String? _errorMessage;
  String? _successMessage;
  bool _isOperating = false; // loading khi đang add/edit/delete

  List<UserModel> get users => _users;
  UserState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isLoading => _state == UserState.loading;
  bool get isOperating => _isOperating;

  /// Load danh sách users (real-time stream)
  void loadUsers() {
    _state = UserState.loading;
    notifyListeners();

    _userService.getUsersStream().listen(
      (users) {
        _users = users;
        _state = UserState.loaded;
        notifyListeners();
      },
      onError: (e) {
        _state = UserState.error;
        _errorMessage = 'Không thể tải danh sách người dùng';
        notifyListeners();
      },
    );
  }

  /// Thêm user mới (có upload ảnh nếu có)
  Future<bool> addUser({
    required String username,
    required String email,
    required String password,
    XFile? imageFile,
  }) async {
    _isOperating = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      if (await _userService.isEmailExists(email)) {
        _isOperating = false;
        _errorMessage = 'Email này đã tồn tại';
        notifyListeners();
        return false;
      }
      String imageUrl = '';

      // Upload ảnh nếu có chọn
      if (imageFile != null) {
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await _imageService.uploadImage(
              imageFile: imageFile,
              userId: tempId,
            ) ?? '';
        if (imageUrl.isEmpty) {
          throw Exception('Không thể upload ảnh. Vui lòng thử lại');
        }
      }

      // Tạo UserModel với đúng 4 field
      final user = UserModel(
        username: username.trim(),
        email: email.trim(),
        password: password,
        image: imageUrl,
      );

      final docId = await _userService.addUser(user);

      _isOperating = false;

      if (docId != null) {
        _successMessage = 'Thêm người dùng thành công!';
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Không thể thêm người dùng. Vui lòng thử lại';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isOperating = false;
      _errorMessage = 'Có lỗi xảy ra: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật user
  Future<bool> updateUser({
    required String userId,
    required String username,
    required String email,
    required String password,
    required String currentImageUrl,
    XFile? newImageFile,
  }) async {
    _isOperating = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      if (await _userService.isEmailExists(email, excludeId: userId)) {
        _isOperating = false;
        _errorMessage = 'Email này đã tồn tại';
        notifyListeners();
        return false;
      }
      String imageUrl = currentImageUrl;

      // Upload ảnh mới nếu có chọn ảnh mới
      if (newImageFile != null) {
        imageUrl = await _imageService.uploadImage(
              imageFile: newImageFile,
              userId: userId,
            ) ?? '';
        if (imageUrl.isEmpty) {
          throw Exception('Không thể upload ảnh. Vui lòng thử lại');
        }
      }

      final updatedUser = UserModel(
        id: userId,
        username: username.trim(),
        email: email.trim(),
        password: password,
        image: imageUrl,
      );

      final success = await _userService.updateUser(userId, updatedUser);

      _isOperating = false;

      if (success) {
        _successMessage = 'Cập nhật người dùng thành công!';
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Không thể cập nhật người dùng. Vui lòng thử lại';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isOperating = false;
      _errorMessage = 'Có lỗi xảy ra: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Xóa user
  Future<bool> deleteUser(String userId) async {
    _isOperating = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final success = await _userService.deleteUser(userId);

    _isOperating = false;

    if (success) {
      _successMessage = 'Xóa người dùng thành công!';
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Không thể xóa người dùng. Vui lòng thử lại';
      notifyListeners();
      return false;
    }
  }

  /// Upload ảnh (standalone, dùng trong form)
  Future<String?> uploadImage(XFile imageFile, String userId) async {
    return await _imageService.uploadImage(
      imageFile: imageFile,
      userId: userId,
    );
  }

  /// Chọn ảnh từ gallery
  Future<XFile?> pickImage() async {
    return await _imageService.pickImageFromGallery();
  }

  /// Xóa message sau khi hiển thị
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
