import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:idp_order/models/order.dart';
import 'package:web/web.dart';

const _apiUrl = '/api/orders';
const _svgNs = 'http://www.w3.org/2000/svg';

final _form = document.querySelector('#order-form') as HTMLFormElement;
final _itemInput = document.querySelector('#item') as HTMLInputElement;
final _itemNameInput = document.querySelector('#itemName') as HTMLInputElement;
final _priceInput = document.querySelector('#price') as HTMLInputElement;
final _quantityInput = document.querySelector('#quantity') as HTMLInputElement;
final _currencySelect =
    document.querySelector('#currency') as HTMLSelectElement;
final _addButton = document.querySelector('#add-btn') as HTMLButtonElement;
final _searchInput = document.querySelector('#search') as HTMLInputElement;
final _tableBody = document.querySelector('#orders-body') as HTMLElement;
final _toasts = document.querySelector('#toast-container') as HTMLElement;

Timer? _searchDebounce;
int _requestSeq = 0;

void main() {
  _form.onSubmit.listen((event) {
    event.preventDefault();
    _addOrder();
  });
  _searchInput.onInput.listen((_) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _loadOrders);
  });
  for (final input in [
    _itemInput,
    _itemNameInput,
    _priceInput,
    _quantityInput
  ]) {
    input.onInput.listen((_) => input.classList.remove('invalid'));
  }
  _loadOrders();
}

Future<void> _loadOrders() async {
  final seq = ++_requestSeq;
  final search = _searchInput.value.trim();
  final uri = search.isEmpty
      ? Uri.parse(_apiUrl)
      : Uri(path: _apiUrl, queryParameters: {'search': search});
  try {
    final response = await http.get(uri);
    // Drop responses from older searches that finished after a newer one.
    if (seq != _requestSeq) return;
    if (response.statusCode != 200) {
      _showToast(_errorMessage(response), isError: true);
      return;
    }
    final orders = Order.listFromJsonString(utf8.decode(response.bodyBytes));
    _renderOrders(orders);
  } catch (_) {
    if (seq != _requestSeq) return;
    _renderOrders(const []);
    _showToast('Cannot load orders. Please check the server.', isError: true);
  }
}

Future<void> _addOrder() async {
  final quantityText = _quantityInput.value.trim();
  final order = Order(
    item: _itemInput.value.trim(),
    itemName: _itemNameInput.value.trim(),
    price: double.tryParse(_priceInput.value.trim()) ?? 0,
    currency: _currencySelect.value,
    quantity: int.tryParse(quantityText) ?? 0,
  );

  final errors = order.validate();
  if (quantityText.isNotEmpty && int.tryParse(quantityText) == null) {
    errors.remove('Quantity must be greater than 0');
    errors.add('Quantity must be a whole number');
  }
  _markInvalid(order, quantityText);
  if (errors.isNotEmpty) {
    _showToast(errors.join('; '), isError: true);
    return;
  }

  _addButton.disabled = true;
  try {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(order.toJson()),
    );
    if (response.statusCode == 201) {
      _showToast('Item ${order.item} added to cart');
      _form.reset();
      _currencySelect.value = 'USD';
      await _loadOrders();
    } else {
      _showToast(_errorMessage(response), isError: true);
    }
  } catch (_) {
    _showToast('Cannot connect to the server.', isError: true);
  } finally {
    _addButton.disabled = false;
  }
}

Future<void> _deleteOrder(Order order) async {
  if (!window.confirm('Delete item ${order.item} - ${order.itemName}?')) {
    return;
  }
  try {
    final response = await http.delete(
      Uri.parse('$_apiUrl/${Uri.encodeComponent(order.item)}'),
    );
    if (response.statusCode == 200) {
      _showToast('Item ${order.item} deleted');
      await _loadOrders();
    } else {
      _showToast(_errorMessage(response), isError: true);
    }
  } catch (_) {
    _showToast('Cannot connect to the server.', isError: true);
  }
}

void _markInvalid(Order order, String quantityText) {
  _itemInput.classList.toggle('invalid', order.item.isEmpty);
  _itemNameInput.classList.toggle('invalid', order.itemName.isEmpty);
  _priceInput.classList.toggle('invalid', order.price <= 0);
  _quantityInput.classList.toggle(
    'invalid',
    order.quantity <= 0 || int.tryParse(quantityText) == null,
  );
}

void _renderOrders(List<Order> orders) {
  _tableBody.textContent = '';
  if (orders.isEmpty) {
    final row = document.createElement('tr') as HTMLTableRowElement
      ..className = 'empty';
    final cell = document.createElement('td') as HTMLTableCellElement
      ..colSpan = 7
      ..textContent = 'No orders found';
    row.append(cell);
    _tableBody.append(row);
    return;
  }

  for (var i = 0; i < orders.length; i++) {
    final order = orders[i];
    final row = document.createElement('tr') as HTMLTableRowElement;
    for (final text in [
      '${i + 1}',
      order.item,
      order.itemName,
      '${order.quantity}',
      _formatPrice(order.price),
      order.currency,
    ]) {
      row.append(document.createElement('td')..textContent = text);
    }
    final actionCell = document.createElement('td') as HTMLTableCellElement
      ..className = 'col-action';
    final deleteButton = document.createElement('button') as HTMLButtonElement
      ..type = 'button'
      ..className = 'icon-btn'
      ..title = 'Delete'
      ..setAttribute('aria-label', 'Delete ${order.item}');
    deleteButton.append(_trashIcon());
    deleteButton.onClick.listen((_) => _deleteOrder(order));
    actionCell.append(deleteButton);
    row.append(actionCell);
    _tableBody.append(row);
  }
}

Element _trashIcon() {
  final svg = document.createElementNS(_svgNs, 'svg')
    ..setAttribute('viewBox', '0 0 24 24')
    ..setAttribute('fill', 'none')
    ..setAttribute('stroke', 'currentColor')
    ..setAttribute('stroke-width', '2')
    ..setAttribute('stroke-linecap', 'round')
    ..setAttribute('stroke-linejoin', 'round')
    ..setAttribute('aria-hidden', 'true');
  for (final d in [
    'M3 6h18',
    'M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2',
    'M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6',
    'M10 11v6',
    'M14 11v6',
  ]) {
    svg.append(document.createElementNS(_svgNs, 'path')..setAttribute('d', d));
  }
  return svg;
}

String _formatPrice(double price) {
  final isInteger = price == price.roundToDouble();
  final fixed = isInteger ? price.toStringAsFixed(0) : price.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts[0].replaceFirst('-', '');
  final buffer = StringBuffer(price < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  if (!isInteger) {
    final decimals = parts[1].replaceFirst(RegExp(r'0+$'), '');
    if (decimals.isNotEmpty) buffer.write(',$decimals');
  }
  return buffer.toString();
}

String _errorMessage(http.Response response) {
  try {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is Map && body['error'] != null) return body['error'].toString();
  } catch (_) {}
  return 'Request failed (${response.statusCode})';
}

void _showToast(String message, {bool isError = false}) {
  final toast = document.createElement('div') as HTMLDivElement
    ..className = isError ? 'toast error' : 'toast success'
    ..setAttribute('role', isError ? 'alert' : 'status')
    ..textContent = message;
  _toasts.append(toast);
  Timer(const Duration(milliseconds: 3500), () {
    toast.classList.add('hide');
    Timer(const Duration(milliseconds: 300), () => toast.remove());
  });
}
