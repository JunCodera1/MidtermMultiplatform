// ============================================================
// lib/widgets/stock_badge.dart
// Nhãn tình trạng tồn kho: Hết hàng / Sắp hết / Còn hàng
// ============================================================

import 'package:flutter/material.dart';
import '../utils/product_filter.dart';

class StockBadge extends StatelessWidget {
  final int soluong;
  const StockBadge({super.key, required this.soluong});

  @override
  Widget build(BuildContext context) {
    final status = stockStatusOf(soluong);
    final dark = Theme.of(context).brightness == Brightness.dark;
    late final Color color;
    late final String label;
    late final IconData icon;
    switch (status) {
      case StockStatus.out:
        color = dark ? Colors.red.shade300 : Colors.red.shade700;
        label = 'Hết hàng';
        icon = Icons.remove_shopping_cart_outlined;
      case StockStatus.low:
        color = dark ? Colors.orange.shade300 : Colors.orange.shade800;
        label = 'Sắp hết · còn $soluong';
        icon = Icons.warning_amber_rounded;
      case StockStatus.ok:
        color = dark ? Colors.green.shade300 : Colors.green.shade700;
        label = 'Còn $soluong';
        icon = Icons.check_circle_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
