import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:user_admin_app/models/product_model.dart';
import 'package:user_admin_app/utils/csv.dart';
import 'package:user_admin_app/utils/format.dart';
import 'package:user_admin_app/utils/limits.dart';
import 'package:user_admin_app/utils/product_filter.dart';
import 'package:user_admin_app/utils/validators.dart';

void main() {
  group('ProductModel', () {
    test('toFirestore chỉ có đúng 4 trường name, price, soluong, image', () {
      const p = ProductModel(
          id: 'abc', name: 'Áo', price: 150000, soluong: 3, image: '');
      expect(
          p.toFirestore().keys.toSet(), {'name', 'price', 'soluong', 'image'});
    });

    test('fromFirestore đọc đúng kiểu dữ liệu và giá trị mặc định', () {
      final p = ProductModel.fromFirestore(
          {'name': 'Giày', 'price': 99.5, 'soluong': 7}, 'id1');
      expect(p.id, 'id1');
      expect(p.price, 99.5);
      expect(p.soluong, 7);
      expect(p.image, '');
    });
  });

  group('Validators', () {
    test('tên sản phẩm', () {
      expect(Validators.validateProductName(''), isNotNull);
      expect(Validators.validateProductName('A'), isNotNull);
      expect(Validators.validateProductName('Áo thun'), isNull);
    });
    test('giá', () {
      expect(Validators.validatePrice(''), isNotNull);
      expect(Validators.validatePrice('abc'), isNotNull);
      expect(Validators.validatePrice('-5'), isNotNull);
      expect(Validators.validatePrice('1500000'), isNull);
      expect(Validators.validatePrice('12.5'), isNull);
    });
    test('số lượng', () {
      expect(Validators.validateQuantity(''), isNotNull);
      expect(Validators.validateQuantity('1.5'), isNotNull);
      expect(Validators.validateQuantity('-1'), isNotNull);
      expect(Validators.validateQuantity('0'), isNull);
      expect(Validators.validateQuantity('25'), isNull);
    });
    test('email và mật khẩu', () {
      expect(Validators.validateEmail('abc'), isNotNull);
      expect(Validators.validateEmail('a@b.com'), isNull);
      expect(Validators.validatePassword('123'), isNotNull);
      expect(Validators.validatePassword('123456'), isNull);
    });
  });

  test('formatPrice', () {
    expect(formatPrice(1500000), '1.500.000 đ');
    expect(formatPrice(0), '0 đ');
    expect(formatPrice(999), '999 đ');
    expect(formatPrice(12.5), '12,5 đ');
  });

  group('filterAndSort', () {
    const a =
        ProductModel(name: 'Áo thun', price: 150000, soluong: 5, image: '');
    const b =
        ProductModel(name: 'quần jean', price: 399000, soluong: 0, image: '');
    const c = ProductModel(name: 'Balo', price: 99000, soluong: 12, image: '');
    final all = [a, b, c];

    List<String> names(List<ProductModel> l) => l.map((p) => p.name).toList();

    test('tìm không phân biệt dấu: "ao" ra "Áo thun", "quan" ra "quần jean"',
        () {
      expect(names(filterAndSort(all, 'ao', ProductSort.nameAsc)), ['Áo thun']);
      expect(names(filterAndSort(all, 'QUAN', ProductSort.nameAsc)),
          ['quần jean']);
      expect(foldVietnamese('Đường Ớt Ỳ'), 'duong ot y');
    });
    test('tìm theo tên, không phân biệt hoa thường', () {
      expect(names(filterAndSort(all, 'JEAN', ProductSort.nameAsc)),
          ['quần jean']);
      expect(filterAndSort(all, 'xyz', ProductSort.nameAsc), isEmpty);
      expect(filterAndSort(all, '  ', ProductSort.nameAsc).length, 3);
    });
    test('sắp xếp theo tên (không phân biệt hoa thường)', () {
      expect(names(filterAndSort(all, '', ProductSort.nameAsc)),
          ['Áo thun', 'Balo', 'quần jean']);
      expect(names(filterAndSort(all, '', ProductSort.nameDesc)).first,
          'quần jean');
    });
    test('sắp xếp theo giá và số lượng', () {
      expect(names(filterAndSort(all, '', ProductSort.priceAsc)),
          ['Balo', 'Áo thun', 'quần jean']);
      expect(names(filterAndSort(all, '', ProductSort.priceDesc)).first,
          'quần jean');
      expect(names(filterAndSort(all, '', ProductSort.quantityAsc)).first,
          'quần jean');
      expect(names(filterAndSort(all, '', ProductSort.quantityDesc)).first,
          'Balo');
    });
    test('không làm thay đổi danh sách gốc', () {
      filterAndSort(all, '', ProductSort.priceDesc);
      expect(names(all), ['Áo thun', 'quần jean', 'Balo']);
    });
  });

  group('parseProductsJson', () {
    test('đọc đúng dữ liệu hợp lệ', () {
      final list = parseProductsJson(
          '[{"name":" Áo ","price":10.5,"soluong":3,"image":""}]');
      expect(list.single.name, 'Áo');
      expect(list.single.price, 10.5);
      expect(list.single.soluong, 3);
    });
    test('image vắng mặt thì mặc định rỗng', () {
      expect(
          parseProductsJson('[{"name":"A","price":1,"soluong":1}]')
              .single
              .image,
          '');
    });
    test('từ chối trường lạ, sai kiểu, sai định dạng', () {
      Matcher bad(String part) => throwsA(isA<FormatException>()
          .having((e) => e.message, 'message', contains(part)));
      expect(() => parseProductsJson('không phải json'), bad('JSON'));
      expect(() => parseProductsJson('{}'), bad('mảng'));
      expect(() => parseProductsJson('[]'), bad('Không có sản phẩm'));
      expect(
          () => parseProductsJson(
              '[{"name":"A","price":1,"soluong":1,"id":"x"}]'),
          bad('không được phép'));
      expect(() => parseProductsJson('[{"name":"","price":1,"soluong":1}]'),
          bad('name'));
      expect(() => parseProductsJson('[{"name":"A","price":-1,"soluong":1}]'),
          bad('price'));
      expect(() => parseProductsJson('[{"name":"A","price":1,"soluong":1.5}]'),
          bad('soluong'));
    });
    test('file docs/database/products.json hợp lệ', () {
      final text = File('docs/database/products.json').readAsStringSync();
      expect(parseProductsJson(text).length, 5);
    });
  });

  group('tình trạng kho', () {
    const out = ProductModel(name: 'Hết', price: 1, soluong: 0, image: '');
    const low = ProductModel(name: 'Sắp hết', price: 1, soluong: 5, image: '');
    const ok = ProductModel(name: 'Còn', price: 1, soluong: 6, image: '');
    final all = [out, low, ok];

    test('stockStatusOf: 0 = hết, 1..5 = sắp hết, >5 = còn', () {
      expect(stockStatusOf(0), StockStatus.out);
      expect(stockStatusOf(-3), StockStatus.out);
      expect(stockStatusOf(1), StockStatus.low);
      expect(stockStatusOf(5), StockStatus.low);
      expect(stockStatusOf(6), StockStatus.ok);
    });
    test('lọc theo tình trạng kho', () {
      List<String> n(StockFilter f) =>
          filterAndSort(all, '', ProductSort.nameAsc, stock: f)
              .map((p) => p.name)
              .toList();
      expect(n(StockFilter.all).length, 3);
      expect(n(StockFilter.out), ['Hết']);
      expect(n(StockFilter.low), ['Sắp hết']);
      expect(n(StockFilter.ok), ['Còn']);
    });
    test('lọc kết hợp tìm kiếm', () {
      expect(
          filterAndSort(all, 'con', ProductSort.nameAsc,
              stock: StockFilter.out),
          isEmpty);
      expect(
          filterAndSort(all, 'sap', ProductSort.nameAsc, stock: StockFilter.low)
              .length,
          1);
    });
    test('countByStock đếm đúng', () {
      final c = countByStock(all);
      expect(c[StockFilter.all], 3);
      expect(c[StockFilter.out], 1);
      expect(c[StockFilter.low], 1);
      expect(c[StockFilter.ok], 1);
    });
  });

  group('applyStockDelta (nhập/xuất kho)', () {
    test('nhập kho cộng thêm', () => expect(applyStockDelta(3, 5), 8));
    test('xuất kho trừ đi', () => expect(applyStockDelta(10, -4), 6));
    test('xuất đúng bằng số đang có về 0',
        () => expect(applyStockDelta(4, -4), 0));
    test('xuất quá số đang có bị từ chối',
        () => expect(applyStockDelta(2, -3), isNull));
  });

  group('productsToCsv', () {
    test('tiêu đề và dòng dữ liệu', () {
      const list = [
        ProductModel(
            name: 'Áo',
            price: 150000,
            soluong: 3,
            image: 'data:image/jpeg;base64,AAAA'),
        ProductModel(name: 'Giày', price: 12.5, soluong: 0, image: ''),
      ];
      expect(
          productsToCsv(list), 'name,price,soluong\nÁo,150000,3\nGiày,12.5,0');
    });
    test('không xuất ảnh', () {
      const p = ProductModel(name: 'A', price: 1, soluong: 1, image: 'SECRET');
      expect(productsToCsv([p]).contains('SECRET'), isFalse);
    });
    test('escape dấu phẩy và ngoặc kép', () {
      const p = ProductModel(
          name: 'Áo "xịn", size M', price: 1, soluong: 1, image: '');
      expect(productsToCsv([p]).split('\n')[1], '"Áo ""xịn"", size M",1,1');
    });
  });

  group('giới hạn dữ liệu', () {
    test('applyStockDelta chặn vượt maxQuantity', () {
      expect(applyStockDelta(maxQuantity, 1), isNull);
      expect(applyStockDelta(maxQuantity - 1, 1), maxQuantity);
    });
    test('validator từ chối giá/số lượng quá lớn hoặc tràn số', () {
      expect(Validators.validateQuantity('${maxQuantity + 1}'), isNotNull);
      expect(Validators.validateQuantity('99999999999999999999999'), isNotNull);
      expect(Validators.validateQuantity('$maxQuantity'), isNull);
      expect(Validators.validatePrice('${maxPrice * 10}'), isNotNull);
      expect(Validators.validatePrice('1e30'), isNotNull);
      expect(Validators.validatePrice('$maxPrice'), isNull);
    });
    test('JSON nhập vào bị từ chối khi vượt giới hạn', () {
      expect(
          () => parseProductsJson(
              '[{"name":"A","price":1,"soluong":${maxQuantity + 1}}]'),
          throwsFormatException);
      expect(
          () => parseProductsJson(
              '[{"name":"A","price":${maxPrice * 2},"soluong":1}]'),
          throwsFormatException);
    });
  });

  group('file dữ liệu mẫu demo', () {
    final text = File('docs/database/products_demo.json').readAsStringSync();

    test(
        'đọc được bằng parseProductsJson (đúng 4 trường, đúng kiểu, trong giới hạn)',
        () {
      final list = parseProductsJson(text);
      expect(list.length, 12);
      expect(list.every((p) => p.image.startsWith('data:image/jpeg;base64,')),
          isTrue);
      expect(list.every((p) => p.image.length < 900000), isTrue);
    });

    test('mỗi phần tử chỉ có đúng 4 khóa name, price, soluong, image', () {
      final rows = jsonDecode(text) as List;
      for (final r in rows) {
        expect((r as Map).keys.toSet(), {'name', 'price', 'soluong', 'image'});
      }
    });

    test('có đủ các tình trạng kho để thử bộ lọc', () {
      final list = parseProductsJson(text);
      final c = countByStock(list);
      expect(c[StockFilter.out], greaterThan(0));
      expect(c[StockFilter.low], greaterThan(0));
      expect(c[StockFilter.ok], greaterThan(0));
    });
  });
}
