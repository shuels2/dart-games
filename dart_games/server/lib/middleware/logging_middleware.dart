import 'package:shelf/shelf.dart';

/// Simple request/response logger.
Middleware loggingMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final stopwatch = Stopwatch()..start();
      final response = await innerHandler(request);
      stopwatch.stop();

      final method = request.method;
      final path = request.requestedUri.path;
      final status = response.statusCode;
      final ms = stopwatch.elapsedMilliseconds;

      print('$method $path -> $status (${ms}ms)');
      return response;
    };
  };
}
