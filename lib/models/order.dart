import 'dart:convert';

class Order {
  final String item;
  final String itemName;
  final double price;
  final String currency;
  final int quantity;

  Order({
    required this.item,
    required this.itemName,
    required this.price,
    required this.currency,
    required this.quantity,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      item: (json['Item'] ?? '').toString().trim(),
      itemName: (json['ItemName'] ?? '').toString().trim(),
      price: _toDouble(json['Price']),
      currency: (json['Currency'] ?? 'USD').toString().trim(),
      quantity: _toInt(json['Quantity']),
    );
  }

  Map<String, dynamic> toJson() => {
        'Item': item,
        'ItemName': itemName,
        'Price': price == price.roundToDouble() ? price.toInt() : price,
        'Currency': currency,
        'Quantity': quantity,
      };

  List<String> validate() {
    final errors = <String>[];
    if (item.isEmpty) errors.add('Item is required');
    if (itemName.isEmpty) errors.add('ItemName is required');
    if (price <= 0) errors.add('Price must be greater than 0');
    if (quantity <= 0) errors.add('Quantity must be greater than 0');
    if (currency.isEmpty) errors.add('Currency is required');
    return errors;
  }

  static List<Order> listFromJsonString(String source) {
    final decoded = jsonDecode(source) as List<dynamic>;
    return decoded
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJsonString(List<Order> orders, {bool pretty = true}) {
    final data = orders.map((o) => o.toJson()).toList();
    return pretty
        ? const JsonEncoder.withIndent('  ').convert(data)
        : jsonEncode(data);
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  String toString() =>
      'Order($item, $itemName, $price $currency, qty: $quantity)';
}
