import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:user_admin_app/models/product_model.dart';
import 'package:user_admin_app/providers/product_provider.dart';
import 'package:user_admin_app/screens/product_detail_screen.dart';
import 'package:user_admin_app/services/product_service.dart';
import 'package:user_admin_app/widgets/app_dialogs.dart';

/// Dịch vụ giả: lưu trong bộ nhớ, không cần Firebase.
class FakeProductService extends ProductService {
  final _controller = StreamController<List<ProductModel>>.broadcast();
  List<ProductModel> items;
  final List<int> quantityCalls = [];
  Object? failWith;

  FakeProductService(this.items);

  @override
  Stream<List<ProductModel>> getProductsStream() async* {
    yield items;
    yield* _controller.stream;
  }

  @override
  Future<void> updateQuantity(String id, int soluong) async {
    if (failWith != null) throw failWith!;
    quantityCalls.add(soluong);
    items = [
      for (final p in items)
        if (p.id == id)
          ProductModel(
              id: p.id,
              name: p.name,
              price: p.price,
              soluong: soluong,
              image: p.image)
        else
          p
    ];
    _controller.add(items);
  }
}

Future<(FakeProductService, ProductProvider)> pumpDetail(WidgetTester tester,
    {int stock = 4}) async {
  // Kích thước giống điện thoại để mọi nút nằm trong màn hình
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final p = ProductModel(
      id: 'p1', name: 'Áo thun', price: 150000, soluong: stock, image: '');
  final service = FakeProductService([p]);
  final provider = ProductProvider(service: service)..loadProducts();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(home: ProductDetailScreen(product: p)),
    ),
  );
  await tester.pumpAndSettle();
  return (service, provider);
}

/// Cuộn tới nút "Nhập / xuất kho" (nằm dưới phần cuộn) rồi mở hộp thoại.
Future<void> openStockDialog(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Nhập / xuất kho'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Nhập / xuất kho'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('xuất kho đúng số lượng: không lỗi, kho cập nhật',
      (tester) async {
    final (service, _) = await pumpDetail(tester, stock: 4);
    await openStockDialog(tester);
    await tester.tap(find.text('Xuất kho'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(service.quantityCalls, [1]);
  });

  testWidgets('xuất kho vượt số đang có: báo lỗi trong hộp thoại, không crash',
      (tester) async {
    final (service, _) = await pumpDetail(tester, stock: 4);
    await openStockDialog(tester);
    await tester.tap(find.text('Xuất kho'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '99');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Kho chỉ còn 4'), findsOneWidget);
    expect(service.quantityCalls, isEmpty);
  });

  testWidgets('nhập kho rồi đóng hộp thoại: không lỗi', (tester) async {
    final (service, _) = await pumpDetail(tester, stock: 4);
    await openStockDialog(tester);
    await tester.enterText(find.byType(TextField), '10');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(service.quantityCalls, [14]);
  });

  testWidgets('hủy hộp thoại: không lỗi', (tester) async {
    await pumpDetail(tester);
    await openStockDialog(tester);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('nhập kho vượt giới hạn tối đa: báo lỗi, không crash',
      (tester) async {
    final (service, _) = await pumpDetail(tester, stock: 4);
    await openStockDialog(tester);
    await tester.enterText(find.byType(TextField), '2000000000');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Vượt giới hạn'), findsOneWidget);
    expect(service.quantityCalls, isEmpty);
  });

  testWidgets('nhập chữ / số âm / rỗng: báo lỗi, không crash', (tester) async {
    await pumpDetail(tester);
    await openStockDialog(tester);
    for (final bad in ['abc', '-5', '0', '', '1.5']) {
      await tester.enterText(find.byType(TextField), bad);
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'nhập "$bad"');
      expect(find.text('Nhập một số nguyên dương'), findsOneWidget,
          reason: 'nhập "$bad"');
    }
  });

  testWidgets('lỗi từ máy chủ khi cập nhật kho: báo lỗi, không crash',
      (tester) async {
    final (service, _) = await pumpDetail(tester, stock: 4);
    service.failWith = Exception('mất kết nối');
    await openStockDialog(tester);
    await tester.enterText(find.byType(TextField), '2');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('mất kết nối'), findsOneWidget);
  });

  testWidgets('nút −1 / +1 không crash và cập nhật kho', (tester) async {
    final (service, _) = await pumpDetail(tester, stock: 1);
    await tester.tap(find.byTooltip('Xuất 1'));
    await tester.pumpAndSettle();
    expect(service.quantityCalls, [0]);
    expect(tester.takeException(), isNull);
    // về 0 thì nút −1 bị vô hiệu hóa, nút +1 vẫn dùng được
    await tester.tap(find.byTooltip('Nhập 1'));
    await tester.pumpAndSettle();
    expect(service.quantityCalls, [0, 1]);
  });

  testWidgets('hộp thoại quên mật khẩu: gửi và hủy đều không crash',
      (tester) async {
    String? result = 'chưa';
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result = await showForgotPasswordDialog(
                context,
                initialEmail: 'a@b.com'),
            child: const Text('mở'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi email'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(result, 'a@b.com');

    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(result, isNull);
  });
}
