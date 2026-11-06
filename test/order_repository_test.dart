import 'dart:convert';
import 'dart:io';

import 'package:idp_order/models/order.dart';
import 'package:idp_order/services/order_repository.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String dataFile;
  late OrderRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('order_repo_test');
    dataFile = '${tempDir.path}${Platform.pathSeparator}order.json';
    repo = OrderRepository(dataFile);
    await repo.load();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Order newOrder({String item = 'A1002', String name = 'Samsung S24'}) => Order(
        item: item,
        itemName: name,
        price: 999,
        currency: 'USD',
        quantity: 2,
      );

  test('load seeds two orders and creates the data file', () async {
    expect(repo.getAll(), hasLength(2));
    expect(File(dataFile).existsSync(), isTrue);
    final saved = jsonDecode(await File(dataFile).readAsString()) as List;
    expect(saved, hasLength(2));
    expect((saved.first as Map)['Item'], 'A1000');
  });

  test('search is case-insensitive on ItemName', () {
    expect(repo.search('iphone 16'), hasLength(1));
    expect(repo.search('iphone 16').single.item, 'A1001');
    expect(repo.search('IPHONE'), hasLength(2));
    expect(repo.search(''), hasLength(2));
    expect(repo.search('nokia'), isEmpty);
  });

  test('add persists to the data file', () async {
    final created = await repo.add(newOrder());
    expect(created.item, 'A1002');
    expect(repo.getAll(), hasLength(3));

    final reloaded = OrderRepository(dataFile);
    await reloaded.load();
    expect(reloaded.getAll(), hasLength(3));
    expect(reloaded.search('samsung').single.item, 'A1002');
  });

  test('add rejects duplicate Item regardless of case', () async {
    expect(
      () => repo.add(newOrder(item: 'a1000')),
      throwsA(isA<StateError>()),
    );
    expect(repo.getAll(), hasLength(2));
  });

  test('add rejects invalid order', () async {
    expect(
      () => repo.add(newOrder(item: '', name: '')),
      throwsA(isA<ArgumentError>()),
    );
    expect(repo.getAll(), hasLength(2));
  });

  test('delete removes existing item and saves', () async {
    expect(await repo.delete('A1000'), isTrue);
    expect(await repo.delete('A9999'), isFalse);
    expect(repo.getAll(), hasLength(1));

    final reloaded = OrderRepository(dataFile);
    await reloaded.load();
    expect(reloaded.getAll().single.item, 'A1001');
  });
}
