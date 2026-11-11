// ============================================================
// lib/screens/product_detail_screen.dart
// Xem thông tin chi tiết một sản phẩm (hình, tên, giá, số lượng)
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../utils/format.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/product_image.dart';
import '../widgets/stock_badge.dart';
import 'edit_product_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  void _edit(BuildContext context, ProductModel p) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => EditProductScreen(product: p)));
  }

  void _toast(BuildContext context, String message, {bool ok = true}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
      ));
  }

  /// Nhập (+) hoặc xuất (−) kho theo [delta]; báo lỗi nếu không thực hiện được
  Future<bool> _adjust(BuildContext context, ProductModel p, int delta) async {
    final provider = context.read<ProductProvider>();
    final ok = await provider.adjustQuantity(p.id!, delta);
    if (!context.mounted) return ok;
    if (!ok) {
      _toast(context, provider.errorMessage ?? 'Có lỗi xảy ra', ok: false);
    }
    return ok;
  }

  /// Hộp thoại nhập / xuất kho theo số lượng tùy ý
  Future<void> _stockDialog(BuildContext context, ProductModel p) async {
    final delta = await showStockAdjustDialog(context, current: p.soluong);
    if (delta == null || !context.mounted) return;
    final ok = await _adjust(context, p, delta);
    if (ok && context.mounted) {
      _toast(
          context, delta > 0 ? 'Đã nhập kho $delta' : 'Đã xuất kho ${-delta}');
    }
  }

  Future<void> _duplicate(BuildContext context, ProductModel p) async {
    final provider = context.read<ProductProvider>();
    final ok = await provider.duplicateProduct(p);
    if (!context.mounted) return;
    _toast(
        context,
        ok
            ? 'Đã nhân bản "${p.name}"'
            : (provider.errorMessage ?? 'Có lỗi xảy ra'),
        ok: ok);
  }

  @override
  Widget build(BuildContext context) {
    // Lấy bản mới nhất từ provider để cập nhật ngay sau khi sửa
    final provider = context.watch<ProductProvider>();
    final current =
        provider.products.where((p) => p.id == product.id).firstOrNull;
    if (current == null) {
      // Sản phẩm vừa bị xóa
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
        body: const Center(child: Text('Sản phẩm không còn tồn tại')),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final size = math.min(MediaQuery.of(context).size.width - 32, 420.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        actions: [
          IconButton(
              tooltip: 'Sửa',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context, current)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Hero(
                    tag: 'product-image-${current.id}',
                    child: ProductImage(
                        image: current.image, size: size, radius: 20),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [StockBadge(soluong: current.soluong)]),
                const SizedBox(height: 10),
                Text(current.name,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.2)),
                const SizedBox(height: 8),
                Text(
                  formatPrice(current.price),
                  style: TextStyle(
                      fontSize: 26,
                      color: scheme.primary,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: const Text('Số lượng trong kho'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton.filledTonal(
                              tooltip: 'Xuất 1',
                              icon: const Icon(Icons.remove),
                              onPressed: current.soluong > 0
                                  ? () => _adjust(context, current, -1)
                                  : null,
                            ),
                            SizedBox(
                              width: 48,
                              child: Text('${current.soluong}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'Nhập 1',
                              icon: const Icon(Icons.add),
                              onPressed: () => _adjust(context, current, 1),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.payments_outlined),
                        title: const Text('Giá trị tồn kho'),
                        trailing: Text(
                          formatPrice(current.price * current.soluong),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _stockDialog(context, current),
                        icon: const Icon(Icons.swap_vert),
                        label: const Text('Nhập / xuất kho'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _duplicate(context, current),
                        icon: const Icon(Icons.copy_all_outlined),
                        label: const Text('Nhân bản'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _edit(context, current),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa sản phẩm'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
