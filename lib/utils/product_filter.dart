// ============================================================
// lib/utils/product_filter.dart
// Lọc (tên, tình trạng kho), sắp xếp và quy tắc tồn kho. Hàm thuần, dễ kiểm thử.
// Chỉ dùng 4 trường name, price, soluong, image.
// ============================================================

import '../models/product_model.dart';
import 'limits.dart';

/// Số lượng từ mức này trở xuống được báo "Sắp hết".
const int lowStockThreshold = 5;

enum StockStatus { out, low, ok }

StockStatus stockStatusOf(int soluong) {
  if (soluong <= 0) return StockStatus.out;
  if (soluong <= lowStockThreshold) return StockStatus.low;
  return StockStatus.ok;
}

/// Bộ lọc theo tình trạng kho trên danh sách.
enum StockFilter { all, ok, low, out }

bool _matchesStock(ProductModel p, StockFilter f) {
  switch (f) {
    case StockFilter.all:
      return true;
    case StockFilter.ok:
      return stockStatusOf(p.soluong) == StockStatus.ok;
    case StockFilter.low:
      return stockStatusOf(p.soluong) == StockStatus.low;
    case StockFilter.out:
      return stockStatusOf(p.soluong) == StockStatus.out;
  }
}

/// Đếm số sản phẩm theo từng bộ lọc (để hiển thị trên chip).
Map<StockFilter, int> countByStock(List<ProductModel> source) => {
      for (final f in StockFilter.values)
        f: source.where((p) => _matchesStock(p, f)).length,
    };

/// Kết quả của việc nhập/xuất kho: số lượng mới, hoặc null nếu xuất quá số đang có
/// hoặc nhập vượt [maxQuantity].
int? applyStockDelta(int current, int delta) {
  final next = current + delta;
  if (next < 0 || next > maxQuantity) return null;
  return next;
}

const _vietnamese = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};
final Map<String, String> _fold = {
  for (final e in _vietnamese.entries)
    for (final ch in e.value.split('')) ch: e.key,
};

/// Chữ thường và bỏ dấu tiếng Việt: "Áo Thun" -> "ao thun". Dùng để so sánh và tìm kiếm.
String foldVietnamese(String input) {
  final lower = input.toLowerCase().replaceAll(RegExp('[\\u0300-\\u036f]'), '');
  return lower.split('').map((c) => _fold[c] ?? c).join();
}

enum ProductSort {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
  quantityAsc,
  quantityDesc
}

/// Trả về danh sách mới đã lọc (tên chứa [query] không phân biệt hoa thường và dấu,
/// đúng tình trạng kho [stock]) rồi sắp xếp theo [sort].
List<ProductModel> filterAndSort(
  List<ProductModel> source,
  String query,
  ProductSort sort, {
  StockFilter stock = StockFilter.all,
}) {
  final q = foldVietnamese(query.trim());
  final list = source
      .where((p) =>
          _matchesStock(p, stock) &&
          (q.isEmpty || foldVietnamese(p.name).contains(q)))
      .toList();
  int byName(ProductModel a, ProductModel b) {
    final c = foldVietnamese(a.name).compareTo(foldVietnamese(b.name));
    return c != 0 ? c : a.name.compareTo(b.name);
  }

  switch (sort) {
    case ProductSort.nameAsc:
      list.sort(byName);
    case ProductSort.nameDesc:
      list.sort((a, b) => byName(b, a));
    case ProductSort.priceAsc:
      list.sort((a, b) => a.price.compareTo(b.price));
    case ProductSort.priceDesc:
      list.sort((a, b) => b.price.compareTo(a.price));
    case ProductSort.quantityAsc:
      list.sort((a, b) => a.soluong.compareTo(b.soluong));
    case ProductSort.quantityDesc:
      list.sort((a, b) => b.soluong.compareTo(a.soluong));
  }
  return list;
}
