# My Order

Bài thi IDP - Introduction to Dart Programming (SET01).

Web xem danh sách đơn hàng, thêm đơn hàng mới vào `order.json` và tìm kiếm theo ItemName.

## Chạy bằng Docker

```bash
docker compose up --build
```

Mở trình duyệt vào http://localhost:8080

## Chạy không dùng Docker

```bash
dart pub get
dart compile js web/main.dart -o build/web/main.dart.js
cp web/index.html web/styles.css build/web/
dart run bin/server.dart
```

## Cấu trúc

- `lib/models/order.dart`: class Order
- `lib/data/seed.dart`: chuỗi JSON ban đầu
- `lib/services/order_repository.dart`: đọc, thêm, tìm, xoá đơn hàng trong `order.json`
- `bin/server.dart`: server
- `web/`: giao diện
- `test/`: test (`dart test`)
