// ============================================================
// lib/services/auth_service.dart
// Đăng nhập / đăng ký / quên mật khẩu bằng Firebase Authentication.
// Không ghi gì vào Firestore: cơ sở dữ liệu chỉ có collection `products`.
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng nhập bằng email + mật khẩu. Trả về null nếu thành công, ngược lại là thông báo lỗi.
  Future<String?> signIn(
      {required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
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

  /// Đăng ký tài khoản admin mới (chỉ tạo tài khoản Firebase Auth).
  Future<String?> register(
      {required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email này đã được đăng ký';
        case 'invalid-email':
          return 'Email không đúng định dạng';
        case 'weak-password':
          return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
        case 'operation-not-allowed':
          return 'Chưa bật Email/Password trong Firebase Authentication';
        default:
          return 'Đăng ký thất bại: ${e.message}';
      }
    } catch (e) {
      return 'Có lỗi xảy ra. Vui lòng thử lại';
    }
  }

  /// Gửi email đặt lại mật khẩu. Trả về null nếu thành công.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'Email không đúng định dạng';
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này';
        case 'too-many-requests':
          return 'Quá nhiều lần thử. Vui lòng thử lại sau';
        default:
          return 'Gửi email thất bại: ${e.message}';
      }
    } catch (e) {
      return 'Có lỗi xảy ra. Vui lòng thử lại';
    }
  }

  Future<void> signOut() => _auth.signOut();
}
