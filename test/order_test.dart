import 'dart:convert';

import 'package:idp_order/models/order.dart';
import 'package:test/test.dart';

const examJson =
    '[{"Item": "A1000","ItemName": "Iphone 15","Price": 1200,"Currency": "USD","Quantity":1},{"Item": "A1001","ItemName": "Iphone 16","Price": 1500,"Currency": "USD","Quantity":1}]';

void main() {
  group('Order', () {
    test('fromJson reads exam keys', () {
      final order = Order.fromJson({
        'Item': 'A1000',
        'ItemName': 'Iphone 15',
        'Price': 1200,
        'Currency': 'USD',
        'Quantity': 1,
      });
      expect(order.item, 'A1000');
      expect(order.itemName, 'Iphone 15');
      expect(order.price, 1200.0);
      expect(order.currency, 'USD');
      expect(order.quantity, 1);
    });

    test('toJson writes exam keys and integer price', () {
      final order = Order(
        item: 'A1000',
        itemName: 'Iphone 15',
        price: 1200,
        currency: 'USD',
        quantity: 1,
      );
      final json = order.toJson();
      expect(json.keys, ['Item', 'ItemName', 'Price', 'Currency', 'Quantity']);
      expect(json['Price'], isA<int>());
      expect(json['Price'], 1200);
    });

    test('toJson keeps decimal price', () {
      final order = Order(
        item: 'B1',
        itemName: 'Case',
        price: 9.5,
        currency: 'USD',
        quantity: 2,
      );
      expect(order.toJson()['Price'], 9.5);
    });

    test('listFromJsonString parses the exam string', () {
      final orders = Order.listFromJsonString(examJson);
      expect(orders, hasLength(2));
      expect(orders[0].item, 'A1000');
      expect(orders[0].itemName, 'Iphone 15');
      expect(orders[1].item, 'A1001');
      expect(orders[1].price, 1500.0);
    });

    test('listToJsonString round-trips with integer price', () {
      final orders = Order.listFromJsonString(examJson);
      final decoded =
          jsonDecode(Order.listToJsonString(orders)) as List<dynamic>;
      expect(decoded, jsonDecode(examJson));
      expect((decoded.first as Map)['Price'], isA<int>());
    });

    test('validate accepts a valid order', () {
      final order = Order.listFromJsonString(examJson).first;
      expect(order.validate(), isEmpty);
    });

    test('validate reports every invalid field', () {
      final order = Order.fromJson({
        'Item': ' ',
        'ItemName': '',
        'Price': 0,
        'Currency': '',
        'Quantity': -1,
      });
      expect(order.validate(), [
        'Item is required',
        'ItemName is required',
        'Price must be greater than 0',
        'Quantity must be greater than 0',
        'Currency is required',
      ]);
    });
  });
}
