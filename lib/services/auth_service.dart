// ============================================================
// lib/services/auth_service.dart
// Service xử lý đăng nhập bằng Firebase Auth
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy user hiện tại đang đăng nhập
  User? get currentUser => _auth.currentUser;

  /// Stream trạng thái auth
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng nhập bằng email + password
  /// Trả về null nếu thành công, trả về message lỗi nếu thất bại
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      var loginEmail = email.trim();
      if (!loginEmail.contains('@')) {
        final result = await _firestore
            .collection('users')
            .where('username', isEqualTo: loginEmail)
            .limit(1)
            .get();
        if (result.docs.isEmpty) return 'Không tìm thấy username này';
        loginEmail = (result.docs.first.data()['email'] ?? '').toString();
      }
      await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );
      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này';
        case 'wrong-password':
          return 'Mật khẩu không đúng';
        case 'invalid-email':
          return 'Email không đúng định dạng';
        case 'user-disabled':
          return 'Tài khoản đã bị vô hiệu hóa';
        case 'invalid-credential':
          return 'Email hoặc mật khẩu không đúng';
        case 'too-many-requests':
          return 'Quá nhiều lần thử. Vui lòng thử lại sau';
        default:
          return 'Đăng nhập thất bại: ${e.message}';
      }
    } catch (e) {
      return 'Có lỗi xảy ra. Vui lòng thử lại';
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Tạo tài khoản admin lần đầu (dùng khi setup)
  Future<String?> createAdminAccount({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Lưu admin vào collection users với đúng 4 field
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(UserModel(
            username: username,
            email: email.trim(),
            password: password,
            image: '',
          ).toFirestore());

      return null;
    } on FirebaseAuthException catch (e) {
      return 'Lỗi tạo tài khoản: ${e.message}';
    }
  }
}
