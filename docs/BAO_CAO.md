# Báo cáo giữa kỳ - Lập trình đa nền tảng

Bản báo cáo đầy đủ (có khung chèn ảnh minh họa) là file **[BAO_CAO.docx](BAO_CAO.docx)**.

Đề tài: ứng dụng quản lý sản phẩm (phân hệ Admin) bằng Flutter + Firebase Authentication + Cloud Firestore.
Cơ sở dữ liệu chỉ gồm 4 trường: `name`, `price`, `soluong`, `image`.

## File liên quan

| Hạng mục | Vị trí |
|---|---|
| Báo cáo | `docs/BAO_CAO.docx` |
| File cơ sở dữ liệu (JSON) | `docs/database/products.json` |
| Luật bảo mật Firestore | `firestore.rules` |
| Hướng dẫn cài đặt, chạy | `README.md` |

## Kiểm tra nhanh trước khi nộp

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome      # web
flutter build apk --release   # di động (sau khi flutterfire configure cho Android)
```

- [ ] Đã publish `firestore.rules` và xóa collection `users` cũ (nếu còn).
- [ ] Đã chèn ảnh minh họa và điền thông tin cá nhân vào `BAO_CAO.docx`.
- [ ] Link GitHub, link video demo, file `products.json`.
