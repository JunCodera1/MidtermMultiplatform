// ============================================================
// lib/services/product_service.dart
// CRUD sản phẩm trong Cloud Firestore (collection `products`)
// Schema CHỈ có 4 field: name, price, soluong, image
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  // Khởi tạo lười: tạo ProductService không đụng tới Firebase (để test được bằng lớp giả)
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _collection = 'products';

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_collection);

  /// Stream danh sách sản phẩm (realtime)
  Stream<List<ProductModel>> getProductsStream() {
    return _col.snapshots().map((snapshot) => snapshot.docs
        .map((d) => ProductModel.fromFirestore(d.data(), d.id))
        .toList());
  }

  /// Thêm sản phẩm, trả về document ID
  Future<String> addProduct(ProductModel product) async {
    final ref = await _col.add(product.toFirestore());
    return ref.id;
  }

  /// Thêm nhiều sản phẩm bằng batch (mỗi batch tối đa 500 thao tác)
  Future<void> addProducts(List<ProductModel> products) async {
    for (var i = 0; i < products.length; i += 400) {
      final batch = _firestore.batch();
      for (final p in products.skip(i).take(400)) {
        batch.set(_col.doc(), p.toFirestore());
      }
      await batch.commit();
    }
  }

  /// Cập nhật sản phẩm
  Future<void> updateProduct(String id, ProductModel product) {
    return _col.doc(id).update(product.toFirestore());
  }

  /// Chỉ cập nhật số lượng (nhập/xuất kho nhanh); các trường khác giữ nguyên
  Future<void> updateQuantity(String id, int soluong) {
    return _col.doc(id).update({'soluong': soluong});
  }

  /// Xóa sản phẩm
  Future<void> deleteProduct(String id) {
    return _col.doc(id).delete();
  }

  /// Xóa nhiều sản phẩm bằng batch
  Future<void> deleteProducts(List<String> ids) async {
    for (var i = 0; i < ids.length; i += 400) {
      final batch = _firestore.batch();
      for (final id in ids.skip(i).take(400)) {
        batch.delete(_col.doc(id));
      }
      await batch.commit();
    }
  }

  /// Khôi phục sản phẩm đã xóa (giữ nguyên document ID cũ)
  Future<void> restoreProducts(List<ProductModel> products) async {
    for (var i = 0; i < products.length; i += 400) {
      final batch = _firestore.batch();
      for (final p in products.skip(i).take(400)) {
        batch.set(_col.doc(p.id), p.toFirestore());
      }
      await batch.commit();
    }
  }
}
