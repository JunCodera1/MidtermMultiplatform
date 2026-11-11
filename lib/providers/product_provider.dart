// ============================================================
// lib/providers/product_provider.dart
// Quản lý trạng thái danh sách sản phẩm + CRUD + tìm kiếm/sắp xếp/xuất JSON
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../services/image_service.dart';
import '../services/product_service.dart';
import '../utils/csv.dart';
import '../utils/limits.dart';
import '../utils/product_filter.dart';

export '../utils/product_filter.dart' show ProductSort, StockFilter;

/// Độ dài tối đa của chuỗi Base64 lưu trong trường image (~ 900 KB).
const int maxImageChars = 900000;

enum ProductState { initial, loading, loaded, error }

class ProductProvider extends ChangeNotifier {
  final ProductService _service;

  ProductProvider({ProductService? service})
      : _service = service ?? ProductService();

  final ImageService _imageService = ImageService();

  StreamSubscription<List<ProductModel>>? _subscription;
  List<ProductModel> _products = [];
  ProductState _state = ProductState.initial;
  String? _errorMessage;
  bool _isOperating = false;
  String _searchQuery = '';
  ProductSort _sort = ProductSort.nameAsc;
  StockFilter _stockFilter = StockFilter.all;
  final Set<String> _selected = {};

  List<ProductModel> get products => _products;
  ProductState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ProductState.loading;
  bool get isOperating => _isOperating;
  String get searchQuery => _searchQuery;
  ProductSort get sort => _sort;
  StockFilter get stockFilter => _stockFilter;
  Set<String> get selectedIds => _selected;
  bool get selectionMode => _selected.isNotEmpty;

  /// Số sản phẩm theo từng tình trạng kho (cho các chip lọc)
  Map<StockFilter, int> get stockCounts => countByStock(_products);

  /// Tổng giá trị tồn kho (giá × số lượng)
  num get totalValue =>
      _products.fold<num>(0, (t, p) => t + p.price * p.soluong);

  /// Tổng số lượng tồn kho của tất cả sản phẩm
  int get totalQuantity => _products.fold(0, (total, p) => total + p.soluong);

  /// Danh sách đã lọc theo tên và sắp xếp
  List<ProductModel> get filteredProducts =>
      filterAndSort(_products, _searchQuery, _sort, stock: _stockFilter);

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setSort(ProductSort value) {
    _sort = value;
    notifyListeners();
  }

  void setStockFilter(StockFilter value) {
    _stockFilter = value;
    notifyListeners();
  }

  // ----- Chọn nhiều -----
  void toggleSelect(String id) {
    if (!_selected.remove(id)) _selected.add(id);
    notifyListeners();
  }

  void selectAllVisible() {
    _selected
      ..clear()
      ..addAll(filteredProducts.map((p) => p.id!));
    notifyListeners();
  }

  void clearSelection() {
    if (_selected.isEmpty) return;
    _selected.clear();
    notifyListeners();
  }

  /// Lắng nghe danh sách sản phẩm realtime (hủy stream cũ trước khi đăng ký mới)
  void loadProducts() {
    _state = ProductState.loading;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _service.getProductsStream().listen(
      (items) {
        _products = items;
        final ids = items.map((p) => p.id).toSet();
        _selected.removeWhere((id) => !ids.contains(id));
        _state = ProductState.loaded;
        notifyListeners();
      },
      onError: (e) {
        _state = ProductState.error;
        _errorMessage = _describe(e, 'Không thể tải danh sách sản phẩm');
        notifyListeners();
      },
    );
  }

  /// Hủy stream và xóa dữ liệu (gọi khi đăng xuất)
  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _products = [];
    _searchQuery = '';
    _stockFilter = StockFilter.all;
    _selected.clear();
    _state = ProductState.initial;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<bool> addProduct({
    required String name,
    required num price,
    required int soluong,
    XFile? imageFile,
  }) {
    return _run('Không thể thêm sản phẩm', () async {
      final image = await _encode(imageFile) ?? '';
      await _service.addProduct(ProductModel(
          name: name.trim(), price: price, soluong: soluong, image: image));
    });
  }

  Future<bool> updateProduct({
    required String id,
    required String name,
    required num price,
    required int soluong,
    required String currentImage,
    XFile? newImageFile,
  }) {
    return _run('Không thể cập nhật sản phẩm', () async {
      final image = await _encode(newImageFile) ?? currentImage;
      await _service.updateProduct(
        id,
        ProductModel(
            id: id,
            name: name.trim(),
            price: price,
            soluong: soluong,
            image: image),
      );
    });
  }

  Future<bool> deleteProduct(String id) {
    return _run('Không thể xóa sản phẩm', () => _service.deleteProduct(id));
  }

  /// Nhập (delta > 0) hoặc xuất (delta < 0) kho. Không cho số lượng âm.
  Future<bool> adjustQuantity(String id, int delta) {
    final current = _products.where((p) => p.id == id).firstOrNull;
    if (current == null) {
      _errorMessage = 'Sản phẩm không còn tồn tại';
      notifyListeners();
      return Future.value(false);
    }
    final next = applyStockDelta(current.soluong, delta);
    if (next == null) {
      _errorMessage = delta < 0
          ? 'Không thể xuất ${-delta}: kho chỉ còn ${current.soluong}'
          : 'Không thể nhập thêm $delta: vượt giới hạn tối đa $maxQuantity';
      notifyListeners();
      return Future.value(false);
    }
    return _run(
        'Không thể cập nhật số lượng', () => _service.updateQuantity(id, next));
  }

  /// Nhân bản một sản phẩm (tên thêm "(bản sao)")
  Future<bool> duplicateProduct(ProductModel p) {
    return _run('Không thể nhân bản sản phẩm', () async {
      await _service.addProduct(ProductModel(
          name: '${p.name} (bản sao)',
          price: p.price,
          soluong: p.soluong,
          image: p.image));
    });
  }

  /// Xóa nhiều sản phẩm (đang chọn). Trả về danh sách đã xóa để có thể hoàn tác, hoặc null nếu lỗi.
  Future<List<ProductModel>?> deleteSelected() async {
    final removed = _products.where((p) => _selected.contains(p.id)).toList();
    if (removed.isEmpty) return const [];
    final ok = await _run('Không thể xóa sản phẩm',
        () => _service.deleteProducts(removed.map((p) => p.id!).toList()));
    if (!ok) return null;
    _selected.clear();
    notifyListeners();
    return removed;
  }

  /// Hoàn tác việc xóa: ghi lại các sản phẩm với document ID cũ
  Future<bool> restoreProducts(List<ProductModel> products) {
    return _run('Không thể hoàn tác', () => _service.restoreProducts(products));
  }

  /// Báo cáo tồn kho dạng CSV (name, price, soluong)
  String exportCsv() => productsToCsv(_products);

  /// Chuỗi JSON (mảng các sản phẩm, chỉ 4 trường) để nộp làm file cơ sở dữ liệu
  String exportJson() {
    return const JsonEncoder.withIndent('  ')
        .convert(_products.map((p) => p.toJson()).toList());
  }

  /// Ghi các sản phẩm đã đọc từ file vào Firestore (thêm mới, không xóa dữ liệu cũ).
  /// Trả về số sản phẩm đã nhập; ném [FormatException] (tiếng Việt) nếu ghi thất bại.
  Future<int> importProducts(List<ProductModel> items) async {
    _isOperating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.addProducts(items);
      return items.length;
    } on FirebaseException catch (e) {
      throw FormatException(_describe(e, 'Không thể nhập dữ liệu'));
    } catch (e) {
      throw FormatException('Không thể nhập dữ liệu: $e');
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  Future<XFile?> pickImage(ImageSource source) {
    return source == ImageSource.camera
        ? _imageService.pickImageFromCamera()
        : _imageService.pickImageFromGallery();
  }

  Future<String?> _encode(XFile? file) async {
    if (file == null) return null;
    final data = await _imageService.uploadImage(imageFile: file, userId: '');
    if (data == null) throw Exception('Không thể xử lý ảnh. Vui lòng thử lại');
    // Firestore giới hạn 1 MB cho mỗi document; chừa chỗ cho các trường còn lại.
    if (data.length > maxImageChars) {
      throw Exception(
          'Ảnh quá lớn (${(data.length / 1024).round()} KB). Hãy chọn ảnh nhỏ hơn');
    }
    return data;
  }

  /// Chạy một thao tác ghi, quản lý loading và thông báo lỗi
  Future<bool> _run(String failMessage, Future<void> Function() action) async {
    _isOperating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _errorMessage = _describe(e, failMessage);
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  String _describe(Object e, String fallback) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return '$fallback: Firestore từ chối (kiểm tra firestore.rules và đăng nhập)';
    }
    if (e is FirebaseException) return '$fallback: ${e.message ?? e.code}';
    return '$fallback: $e';
  }
}
