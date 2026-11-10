// ============================================================
// lib/services/user_service.dart
// Service xử lý CRUD user trong Firestore
// Schema CHỈ có 4 field: username, email, password, image
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'users';

  /// Lấy danh sách tất cả users (stream để real-time update)
  Stream<List<UserModel>> getUsersStream() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Lấy danh sách users một lần (không real-time)
  Future<List<UserModel>> getUsers() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Lấy một user theo ID
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore.collection(_collection).doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.data()!, doc.id);
  }

  /// Thêm user mới
  /// Trả về document ID mới tạo
  Future<String?> addUser(UserModel user) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(user.toFirestore()); // Chỉ lưu 4 field
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  /// Cập nhật user
  Future<bool> updateUser(String userId, UserModel user) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(userId)
          .update(user.toFirestore()); // Chỉ update 4 field
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Xóa user theo ID
  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Kiểm tra email đã tồn tại chưa (để validate khi thêm user)
  Future<bool> isEmailExists(String email, {String? excludeId}) async {
    final query = await _firestore
        .collection(_collection)
        .where('email', isEqualTo: email.trim())
        .get();

    if (excludeId != null) {
      return query.docs.any((doc) => doc.id != excludeId);
    }
    return query.docs.isNotEmpty;
  }
}
