// ============================================================
// lib/widgets/app_dialogs.dart
// Các hộp thoại có ô nhập liệu. Mỗi hộp thoại là một StatefulWidget TỰ quản lý
// TextEditingController và giải phóng trong dispose(), nên không bị lỗi
// "TextEditingController was used after being disposed" khi hộp thoại đang đóng.
// ============================================================

import 'package:flutter/material.dart';
import '../utils/limits.dart';
import '../utils/product_filter.dart';

/// Nhập / xuất kho theo số lượng tùy ý. Trả về số dương (nhập) hoặc số âm (xuất); null nếu hủy.
Future<int?> showStockAdjustDialog(BuildContext context,
    {required int current}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _StockAdjustDialog(current: current),
  );
}

class _StockAdjustDialog extends StatefulWidget {
  final int current;
  const _StockAdjustDialog({required this.current});

  @override
  State<_StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends State<_StockAdjustDialog> {
  final _controller = TextEditingController(text: '1');
  bool _importing = true;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final n = int.tryParse(_controller.text.trim());
    if (n == null || n <= 0) {
      setState(() => _error = 'Nhập một số nguyên dương');
      return;
    }
    if (!_importing && n > widget.current) {
      setState(
          () => _error = 'Kho chỉ còn ${widget.current}, không thể xuất $n');
      return;
    }
    if (_importing && applyStockDelta(widget.current, n) == null) {
      setState(() => _error = 'Vượt giới hạn tối đa $maxQuantity');
      return;
    }
    Navigator.pop(context, _importing ? n : -n);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nhập / xuất kho'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hiện có ${widget.current} trong kho.'),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: true,
                    label: Text('Nhập kho'),
                    icon: Icon(Icons.add_box_outlined)),
                ButtonSegment(
                    value: false,
                    label: Text('Xuất kho'),
                    icon: Icon(Icons.outbox_outlined)),
              ],
              selected: {_importing},
              onSelectionChanged: (v) => setState(() {
                _importing = v.first;
                _error = null;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                  labelText: 'Số lượng', errorText: _error, errorMaxLines: 2),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: _submit, child: const Text('Xác nhận')),
      ],
    );
  }
}

/// Hộp thoại quên mật khẩu. Trả về email đã nhập; null nếu hủy.
Future<String?> showForgotPasswordDialog(BuildContext context,
    {String initialEmail = ''}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ForgotPasswordDialog(initialEmail: initialEmail),
  );
}

class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quên mật khẩu'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
        decoration: const InputDecoration(
            labelText: 'Email đã đăng ký',
            prefixIcon: Icon(Icons.email_outlined)),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
            child: const Text('Gửi email')),
      ],
    );
  }
}
