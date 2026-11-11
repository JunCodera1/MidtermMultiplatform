// ============================================================
// lib/utils/csv.dart
// Xuất báo cáo tồn kho dạng CSV (name, price, soluong; không kèm ảnh vì quá dài)
// ============================================================

import '../models/product_model.dart';

String _cell(String v) {
  final needsQuote = v.contains(',') ||
      v.contains('"') ||
      v.contains('\n') ||
      v.contains('\r');
  return needsQuote ? '"${v.replaceAll('"', '""')}"' : v;
}

String _num(num v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

String productsToCsv(List<ProductModel> products) {
  final rows = <String>['name,price,soluong'];
  for (final p in products) {
    rows.add('${_cell(p.name)},${_num(p.price)},${p.soluong}');
  }
  return rows.join('\n');
}

/// Tách văn bản CSV thành các dòng, mỗi dòng là danh sách ô (hỗ trợ ô trong ngoặc kép,
/// dấu phẩy và xuống dòng trong ô, và "" là một dấu ngoặc kép).
List<List<String>> parseCsvRows(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var inQuotes = false;
  var cellStarted = false;

  void endCell() {
    row.add(cell.toString());
    cell.clear();
    cellStarted = false;
  }

  void endRow() {
    endCell();
    rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        cell.write(c);
      }
    } else if (c == '"' && !cellStarted) {
      inQuotes = true;
      cellStarted = true;
    } else if (c == ',') {
      endCell();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
        i++;
      }
      endRow();
    } else {
      cell.write(c);
      cellStarted = true;
    }
  }
  if (inQuotes) {
    throw const FormatException('CSV có dấu ngoặc kép chưa đóng');
  }
  if (cell.isNotEmpty || cellStarted || row.isNotEmpty) endRow();
  return rows;
}

/// Đọc CSV có dòng tiêu đề name,price,soluong[,image] thành danh sách sản phẩm.
/// Ném [FormatException] (tiếng Việt) nếu sai định dạng.
List<ProductModel> parseProductsCsv(String text) {
  final rows = parseCsvRows(text)
      .where((r) => !(r.length == 1 && r.first.trim().isEmpty))
      .toList();
  if (rows.isEmpty) throw const FormatException('File CSV trống');

  final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
  const allowed = {'name', 'price', 'soluong', 'image'};
  final extra = header.where((h) => !allowed.contains(h)).toList();
  if (extra.isNotEmpty) {
    throw FormatException(
        'Cột không được phép: ${extra.join(', ')} (chỉ có name, price, soluong, image)');
  }
  for (final need in const ['name', 'price', 'soluong']) {
    if (!header.contains(need)) {
      throw FormatException('Thiếu cột "$need" ở dòng tiêu đề');
    }
  }

  final data = <Map<String, Object?>>[];
  for (var i = 1; i < rows.length; i++) {
    final r = rows[i];
    if (r.length != header.length) {
      throw FormatException('Dòng $i có ${r.length} cột, cần ${header.length}');
    }
    final m = <String, Object?>{};
    for (var c = 0; c < header.length; c++) {
      final v = r[c].trim();
      m[header[c]] = (header[c] == 'price' || header[c] == 'soluong')
          ? (num.tryParse(v) ?? v)
          : r[c];
    }
    data.add(m);
  }
  return productsFromList(data, label: 'Dòng');
}
