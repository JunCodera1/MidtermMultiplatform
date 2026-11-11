// ============================================================
// lib/utils/format.dart
// Định dạng hiển thị
// ============================================================

/// 1500000 -> "1.500.000 đ"; số thập phân giữ tối đa 2 chữ số.
String formatPrice(num value) {
  final isWhole = value == value.roundToDouble();
  final text = isWhole
      ? value.toInt().toString()
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  final parts = text.split('.');
  final intPart =
      parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return '${parts.length > 1 ? '$intPart,${parts[1]}' : intPart} đ';
}
