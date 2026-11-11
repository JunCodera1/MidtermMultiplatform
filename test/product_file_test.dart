import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_admin_app/models/product_model.dart';
import 'package:user_admin_app/utils/csv.dart';
import 'package:user_admin_app/utils/product_file.dart';

Uint8List b(String s) => Uint8List.fromList(utf8.encode(s));

Matcher badFile(String part) => throwsA(
    isA<FormatException>().having((e) => e.message, 'message', contains(part)));

void main() {
  group('parseProductsFile - JSON', () {
    test('đọc file .json hợp lệ', () {
      final list = parseProductsFile(
          name: 'p.json',
          bytes: b('[{"name":"Áo","price":10,"soluong":2,"image":""}]'));
      expect(list.single.name, 'Áo');
      expect(list.single.soluong, 2);
    });
    test('đuôi file không phân biệt hoa thường', () {
      expect(
          parseProductsFile(
                  name: 'P.JSON',
                  bytes: b('[{"name":"A","price":1,"soluong":1}]'))
              .length,
          1);
    });
    test('bỏ dấu BOM đầu file', () {
      final bytes = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('[{"name":"A","price":1,"soluong":1}]')
      ]);
      expect(parseProductsFile(name: 'p.json', bytes: bytes).length, 1);
    });
    test('file demo products_demo.json đọc được qua parseProductsFile', () {
      final bytes = File('docs/database/products_demo.json').readAsBytesSync();
      expect(parseProductsFile(name: 'products_demo.json', bytes: bytes).length,
          12);
    });
    test('file nộp bài products.json đọc được', () {
      final bytes = File('docs/database/products.json').readAsBytesSync();
      expect(parseProductsFile(name: 'products.json', bytes: bytes).length, 5);
    });
  });

  group('parseProductsFile - lỗi', () {
    test(
        'file trống',
        () => expect(
            () => parseProductsFile(name: 'a.json', bytes: Uint8List(0)),
            badFile('trống')));
    test('sai đuôi file', () {
      expect(() => parseProductsFile(name: 'a.txt', bytes: b('x')),
          badFile('.json hoặc .csv'));
      expect(() => parseProductsFile(name: 'abc', bytes: b('x')),
          badFile('không có đuôi'));
    });
    test('không phải UTF-8', () {
      expect(
          () => parseProductsFile(
              name: 'a.json',
              bytes: Uint8List.fromList([0xFF, 0xFE, 0x41, 0x80])),
          badFile('UTF-8'));
    });
    test('file quá lớn', () {
      expect(
          () => parseProductsFile(
              name: 'a.json', bytes: Uint8List(maxImportFileBytes + 1)),
          badFile('quá lớn'));
    });
    test('JSON sai', () {
      expect(() => parseProductsFile(name: 'a.json', bytes: b('{oops')),
          badFile('JSON'));
      expect(
          () => parseProductsFile(
              name: 'a.json',
              bytes: b('[{"name":"A","price":1,"soluong":1,"id":"x"}]')),
          badFile('không được phép'));
    });
  });

  group('CSV', () {
    test('parseCsvRows: ngoặc kép, dấu phẩy, xuống dòng trong ô, \\r\\n', () {
      final rows = parseCsvRows('a,"b,c","d ""q"" e"\r\n"x\ny",,z\n');
      expect(rows, [
        ['a', 'b,c', 'd "q" e'],
        ['x\ny', '', 'z'],
      ]);
    });
    test('parseCsvRows: ngoặc kép chưa đóng', () {
      expect(() => parseCsvRows('a,"b'), badFile('chưa đóng'));
    });
    test('đọc CSV có tiêu đề, không có cột image', () {
      final list = parseProductsCsv(
          'name,price,soluong\nÁo thun,150000,40\nGiày,12.5,0\n');
      expect(list.length, 2);
      expect(list[0].name, 'Áo thun');
      expect(list[1].price, 12.5);
      expect(list[0].image, '');
    });
    test(
        'tiêu đề không phân biệt hoa thường, cột đảo thứ tự, có cột image (cần đặt trong ngoặc kép vì chứa dấu phẩy)',
        () {
      final list = parseProductsCsv(
          'SoLuong,NAME,Price,image\n5,A,1000,"data:image/jpeg;base64,xx"\n');
      expect(list.single.soluong, 5);
      expect(list.single.image, 'data:image/jpeg;base64,xx');
    });
    test(
        'cột image chứa dấu phẩy mà không đặt trong ngoặc kép thì báo sai số cột',
        () {
      expect(
          () => parseProductsCsv(
              'name,price,soluong,image\nA,1,1,data:image/jpeg;base64,xx\n'),
          badFile('Dòng 1 có 5 cột'));
    });
    test('tên có dấu phẩy và ngoặc kép', () {
      final list =
          parseProductsCsv('name,price,soluong\n"Áo ""xịn"", size M",1,1\n');
      expect(list.single.name, 'Áo "xịn", size M');
    });
    test('bỏ qua dòng trống', () {
      expect(parseProductsCsv('name,price,soluong\n\nA,1,1\n\n').length, 1);
    });
    test('lỗi: thiếu cột, cột lạ, số cột sai, giá trị sai', () {
      expect(() => parseProductsCsv('name,price\nA,1\n'),
          badFile('Thiếu cột "soluong"'));
      expect(() => parseProductsCsv('name,price,soluong,id\nA,1,1,x\n'),
          badFile('Cột không được phép: id'));
      expect(() => parseProductsCsv('name,price,soluong\nA,1\n'),
          badFile('Dòng 1 có 2 cột'));
      expect(() => parseProductsCsv('name,price,soluong\nA,abc,1\n'),
          badFile('Dòng 1: price'));
      expect(() => parseProductsCsv('name,price,soluong\nA,1,1.5\n'),
          badFile('Dòng 1: soluong'));
      expect(() => parseProductsCsv('name,price,soluong\n,1,1\n'),
          badFile('Dòng 1: name'));
      expect(() => parseProductsCsv(''), badFile('trống'));
    });
    test('parseProductsFile đọc file .csv (có BOM, \\r\\n)', () {
      final bytes = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('name,price,soluong\r\nBút,42000,5\r\n')
      ]);
      final list = parseProductsFile(name: 'bao_cao.csv', bytes: bytes);
      expect(list.single.name, 'Bút');
      expect(list.single.soluong, 5);
    });
  });

  group('xuất file', () {
    const products = [
      ProductModel(
          name: 'Áo "xịn", M', price: 150000, soluong: 3, image: 'IMG'),
      ProductModel(name: 'Giày', price: 12.5, soluong: 0, image: ''),
    ];

    test('CSV xuất ra rồi đọc lại được (mất ảnh vì CSV không kèm ảnh)', () {
      final bytes =
          encodeProductsFile(productsToCsv(products), ProductFileFormat.csv);
      final back = parseProductsFile(name: 'x.csv', bytes: bytes);
      expect(back.map((p) => p.name), ['Áo "xịn", M', 'Giày']);
      expect(back.map((p) => p.price), [150000, 12.5]);
      expect(back.map((p) => p.soluong), [3, 0]);
      expect(back.every((p) => p.image.isEmpty), isTrue);
    });
    test('JSON xuất ra rồi đọc lại đủ 4 trường (kể cả ảnh)', () {
      final json = const JsonEncoder.withIndent('  ')
          .convert(products.map((p) => p.toJson()).toList());
      final back = parseProductsFile(
          name: 'x.json',
          bytes: encodeProductsFile(json, ProductFileFormat.json));
      expect(back.first.image, 'IMG');
      expect(back.first.name, 'Áo "xịn", M');
    });
    test('CSV có BOM UTF-8, JSON thì không', () {
      expect(encodeProductsFile('a', ProductFileFormat.csv).take(3),
          [0xEF, 0xBB, 0xBF]);
      expect(encodeProductsFile('a', ProductFileFormat.json), [0x61]);
    });
    test('tên file xuất', () {
      final t = DateTime(2026, 11, 3, 9, 5);
      expect(exportFileName(ProductFileFormat.json, t),
          'products_20261103_0905.json');
      expect(exportFileName(ProductFileFormat.csv, t),
          'products_20261103_0905.csv');
    });
    test('mime type', () {
      expect(ProductFileFormat.json.mimeType, 'application/json');
      expect(ProductFileFormat.csv.mimeType, 'text/csv');
    });
  });
}
