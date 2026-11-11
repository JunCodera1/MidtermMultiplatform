// ============================================================
// lib/widgets/product_card.dart
// Thẻ hiển thị thông tin một sản phẩm trong danh sách (có trạng thái được chọn)
// ============================================================

import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../utils/format.dart';
import 'product_image.dart';
import 'stock_badge.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Đang ở chế độ chọn nhiều: ẩn nút sửa/xóa, hiện ô chọn
  final bool selectionMode;
  final bool selected;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? scheme.primaryContainer.withValues(alpha: 0.55) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? scheme.primary
              : scheme.outlineVariant.withValues(alpha: 0.6),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (selectionMode) ...[
                Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? scheme.primary : scheme.outline),
                const SizedBox(width: 10),
              ],
              Hero(
                tag: 'product-image-${product.id}',
                child: ProductImage(image: product.image, size: 84),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatPrice(product.price),
                      style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    StockBadge(soluong: product.soluong),
                  ],
                ),
              ),
              if (!selectionMode)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Sửa',
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(height: 6),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: scheme.error,
                      tooltip: 'Xóa',
                      style: IconButton.styleFrom(
                          backgroundColor:
                              scheme.errorContainer.withValues(alpha: 0.5)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
