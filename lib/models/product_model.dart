// ============================================================
// lib/models/product_model.dart
// Model sản phẩm: CHỈ có đúng 4 trường theo đề bài
//   name (tên), price (giá), soluong (số lượng), image (hình ảnh)
// ============================================================

import 'dart:convert';
import '../utils/limits.dart';

class ProductModel {
  final String? id; // Document ID của Firestore (không phải trường nghiệp vụ)
  final String name;
  final num price;
  final int soluong;
  final String image; // data:image/jpeg;base64,... hoặc rỗng

  const ProductModel({
    this.id,
    required this.name,
    required this.price,
    required this.soluong,
    required this.image,
  });

  factory ProductModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return ProductModel(
      id: docId,
      name: (data['name'] ?? '').toString(),
      price: (data['price'] as num?) ?? 0,
      soluong: ((data['soluong'] as num?) ?? 0).toInt(),
      image: (data['image'] ?? '').toString(),
    );
  }

  /// Dữ liệu ghi vào Firestore / xuất JSON: chỉ 4 trường.
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'price': price,
        'soluong': soluong,
        'image': image,
      };

  Map<String, dynamic> toJson() => toFirestore();

  @override
  String toString() =>
      'ProductModel(id: $id, name: $name, price: $price, soluong: $soluong)';
}

/// Đọc chuỗi JSON (mảng sản phẩm) và kiểm tra từng phần tử đúng 4 trường, đúng kiểu.
/// Ném [FormatException] với thông báo tiếng Việt nếu dữ liệu không hợp lệ.
List<ProductModel> parseProductsJson(String text) {
  final dynamic data;
  try {
    data = jsonDecode(text);
  } catch (_) {
    throw const FormatException('Không phải JSON hợp lệ');
  }
  if (data is! List) {
    throw const FormatException('JSON phải là một mảng các sản phẩm');
  }
  return productsFromList(data);
}

/// Kiểm tra danh sách các dòng dữ liệu (mỗi dòng là Map) rồi đổi thành sản phẩm.
/// Dùng chung cho nhập JSON và nhập CSV. [label] là chữ mở đầu thông báo lỗi
/// (JSON: "Phần tử", CSV: "Dòng").
List<ProductModel> productsFromList(List data, {String label = 'Phần tử'}) {
  if (data.isEmpty) {
    throw const FormatException('Không có sản phẩm nào để nhập');
  }
  const allowed = {'name', 'price', 'soluong', 'image'};
  final result = <ProductModel>[];
  for (var i = 0; i < data.length; i++) {
    final row = data[i];
    final n = i + 1;
    if (row is! Map) throw FormatException('$label $n không phải đối tượng');
    final extra = row.keys.where((k) => !allowed.contains(k)).toList();
    if (extra.isNotEmpty) {
      throw FormatException(
          '$label $n có trường không được phép: ${extra.join(', ')}');
    }
    final name = row['name'];
    final price = row['price'];
    final soluong = row['soluong'];
    final image = row['image'] ?? '';
    if (name is! String || name.trim().isEmpty) {
      throw FormatException('$label $n: name phải là chuỗi không rỗng');
    }
    if (price is! num || price < 0 || price > maxPrice) {
      throw FormatException('$label $n: price phải là số không âm');
    }
    if (soluong is! num ||
        soluong < 0 ||
        soluong > maxQuantity ||
        soluong != soluong.toInt()) {
      throw FormatException('$label $n: soluong phải là số nguyên không âm');
    }
    if (image is! String) {
      throw FormatException('$label $n: image phải là chuỗi');
    }
    result.add(ProductModel(
        name: name.trim(),
        price: price,
        soluong: soluong.toInt(),
        image: image));
  }
  return result;
}
