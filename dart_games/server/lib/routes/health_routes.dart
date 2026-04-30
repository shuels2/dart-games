import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class HealthRoutes {
  Router get router {
    final router = Router();
    router.get('/', _health);
    return router;
  }

  Future<Response> _health(Request request) async {
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}
