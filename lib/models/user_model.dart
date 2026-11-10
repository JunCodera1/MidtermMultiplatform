// ============================================================
// lib/models/user_model.dart
// Model chỉ có đúng 4 field theo yêu cầu đề bài
// ============================================================

class UserModel {
  final String? id; // Document ID từ Firestore (hệ thống, không phải field nghiệp vụ)
  final String username;
  final String email;
  final String password;
  final String image;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.image,
  });

  /// Chuyển từ Firestore document sang UserModel
  factory UserModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return UserModel(
      id: docId,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      image: data['image'] ?? '',
    );
  }

  /// Chuyển sang Map để lưu vào Firestore
  /// CHỈ có đúng 4 field theo yêu cầu đề bài
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'image': image,
    };
  }

  /// Tạo bản copy với các field được cập nhật
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? image,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      image: image ?? this.image,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email)';
  }
}
