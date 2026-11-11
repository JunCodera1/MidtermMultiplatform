// ============================================================
// lib/utils/product_file.dart
// Đọc / ghi file dữ liệu sản phẩm (JSON hoặc CSV). Hàm thuần, dễ kiểm thử.
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import '../models/product_model.dart';
import 'csv.dart';

/// Dung lượng tối đa của file nhập (10 MB).
const int maxImportFileBytes = 10 * 1024 * 1024;

enum ProductFileFormat {
  json('json', 'application/json'),
  csv('csv', 'text/csv');

  final String extension;
  final String mimeType;
  const ProductFileFormat(this.extension, this.mimeType);
}

/// Tên file khi xuất, ví dụ products_20261111_1905.json
String exportFileName(ProductFileFormat format, DateTime now) {
  String two(int v) => v.toString().padLeft(2, '0');
  return 'products_${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}.${format.extension}';
}

/// Nội dung file xuất. CSV có dấu BOM UTF-8 để Excel hiển thị đúng tiếng Việt.
Uint8List encodeProductsFile(String content, ProductFileFormat format) {
  final body = utf8.encode(content);
  if (format == ProductFileFormat.csv) {
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...body]);
  }
  return Uint8List.fromList(body);
}

/// Đọc file đã chọn (theo [name] và [bytes]) thành danh sách sản phẩm.
/// Ném [FormatException] với thông báo tiếng Việt nếu file không hợp lệ.
List<ProductModel> parseProductsFile(
    {required String name, required Uint8List bytes}) {
  if (bytes.isEmpty) throw const FormatException('File trống');
  if (bytes.length > maxImportFileBytes) {
    throw FormatException(
        'File quá lớn (${(bytes.length / 1048576).toStringAsFixed(1)} MB, tối đa ${maxImportFileBytes ~/ 1048576} MB)');
  }

  final dot = name.lastIndexOf('.');
  final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  if (ext != 'json' && ext != 'csv') {
    throw FormatException(
        'Chỉ nhập được file .json hoặc .csv (file này là ${ext.isEmpty ? 'không có đuôi' : '.$ext'})');
  }

  final String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    throw const FormatException('File không phải văn bản UTF-8 hợp lệ');
  }
  final clean = text.startsWith('﻿') ? text.substring(1) : text;
  return ext == 'csv' ? parseProductsCsv(clean) : parseProductsJson(clean);
}
