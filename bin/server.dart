import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:idp_order/models/order.dart';
import 'package:idp_order/services/order_repository.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

const _jsonHeaders = {'Content-Type': 'application/json; charset=utf-8'};

Response _json(int status, Object? body) =>
    Response(status, body: jsonEncode(body), headers: _jsonHeaders);

Response _error(int status, String message) =>
    _json(status, {'error': message});

Router buildApiRouter(OrderRepository repository) {
  final router = Router();

  router.get('/api/orders', (Request request) {
    final search = request.url.queryParameters['search'] ?? '';
    final result = repository.search(search);
    return _json(200, result.map((o) => o.toJson()).toList());
  });

  router.post('/api/orders', (Request request) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(await request.readAsString());
    } on FormatException {
      return _error(400, 'Invalid JSON body');
    }
    if (decoded is! Map<String, dynamic>) {
      return _error(400, 'Request body must be a JSON object');
    }
    try {
      final created = await repository.add(Order.fromJson(decoded));
      return _json(201, created.toJson());
    } on ArgumentError catch (e) {
      return _error(400, e.message.toString());
    } on StateError catch (e) {
      return _error(409, e.message);
    }
  });

  router.delete('/api/orders/<item>', (Request request, String item) async {
    final code = Uri.decodeComponent(item);
    if (await repository.delete(code)) {
      return _json(200, {'deleted': code});
    }
    return _error(404, 'Item $code not found');
  });

  return router;
}

Future<void> main() async {
  final env = Platform.environment;
  final port = int.tryParse(env['PORT'] ?? '') ?? 8080;
  final dataFile = env['DATA_FILE'] ?? 'data/order.json';
  final webDir = env['WEB_DIR'] ?? 'build/web';

  final repository = OrderRepository(dataFile);
  await repository.load();
  print('Loaded ${repository.orders.length} orders from $dataFile');

  var cascade = Cascade().add(buildApiRouter(repository).call);
  if (Directory(webDir).existsSync()) {
    cascade = cascade.add(
      createStaticHandler(webDir, defaultDocument: 'index.html'),
    );
  } else {
    print('Warning: web directory "$webDir" not found, static files disabled');
  }

  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(cascade.handler);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Server running on http://localhost:${server.port}');

  late final StreamSubscription<ProcessSignal> sigint;
  sigint = ProcessSignal.sigint.watch().listen((_) async {
    print('Shutting down');
    await sigint.cancel();
    await server.close(force: true);
    exit(0);
  });
}
