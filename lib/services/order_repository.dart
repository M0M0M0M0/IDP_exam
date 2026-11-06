import 'dart:io';

import '../data/seed.dart';
import '../models/order.dart';

class OrderRepository {
  final String dataFilePath;
  final List<Order> orders = [];

  OrderRepository(this.dataFilePath);

  Future<void> load() async {
    final file = File(dataFilePath);
    orders.clear();
    if (!await file.exists()) {
      await file.parent.create(recursive: true);
      orders.addAll(Order.listFromJsonString(seedOrdersJson));
      await save();
      return;
    }
    orders.addAll(Order.listFromJsonString(await file.readAsString()));
  }

  List<Order> getAll() => List.unmodifiable(orders);

  List<Order> search(String text) {
    final query = text.trim().toLowerCase();
    if (query.isEmpty) return getAll();
    return List.unmodifiable(
      orders.where((o) => o.itemName.toLowerCase().contains(query)),
    );
  }

  Future<Order> add(Order order) async {
    final errors = order.validate();
    if (errors.isNotEmpty) {
      throw ArgumentError(errors.join('; '));
    }
    if (_indexOf(order.item) != -1) {
      throw StateError('Item ${order.item} already exists');
    }
    orders.add(order);
    await save();
    return order;
  }

  Future<bool> delete(String item) async {
    final index = _indexOf(item);
    if (index == -1) return false;
    orders.removeAt(index);
    await save();
    return true;
  }

  Future<void> save() async {
    final file = File(dataFilePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(Order.listToJsonString(orders));
  }

  int _indexOf(String item) {
    final code = item.trim().toLowerCase();
    return orders.indexWhere((o) => o.item.toLowerCase() == code);
  }
}
