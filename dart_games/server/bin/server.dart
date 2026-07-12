import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/database/database_registry.dart';
import 'package:dart_games_server/middleware/cors_middleware.dart';
import 'package:dart_games_server/middleware/logging_middleware.dart';
import 'package:dart_games_server/routes/dartboard_routes.dart';
import 'package:dart_games_server/routes/failed_stats_routes.dart';
import 'package:dart_games_server/routes/health_routes.dart';
import 'package:dart_games_server/routes/player_routes.dart';
import 'package:dart_games_server/routes/saved_game_routes.dart';
import 'package:dart_games_server/routes/settings_routes.dart';
import 'package:dart_games_server/routes/test_routes.dart';
import 'package:dart_games_server/routes/victory_music_routes.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('port', abbr: 'p', defaultsTo: '8080')
    ..addOption('data-dir', abbr: 'd', defaultsTo: 'data')
    ..addOption('db-path')
    ..addOption(
      'web-root',
      help: 'Serve the Flutter web build from this directory '
          '(e.g. ../build/web). Omit to run API-only.',
    );

  final results = parser.parse(args);
  final port = int.parse(results['port'] as String);
  final dataDir = results['data-dir'] as String;
  final dbPath = (results['db-path'] as String?) ?? '$dataDir/dart_games.db';
  final webRoot = results['web-root'] as String?;

  // Ensure data directories exist.
  Directory(dataDir).createSync(recursive: true);
  Directory('$dataDir/music').createSync(recursive: true);
  Directory('$dataDir/photos').createSync(recursive: true);

  // Initialize database and registry.
  final database = Database(dbPath);
  final registry = DatabaseRegistry(database, dataDir);
  DatabaseRegistry.initialize(registry);
  print('Database initialized at $dbPath');

  // Build the router.
  final app = Router();

  // Mount route groups.
  app.mount('/api/v1/health', HealthRoutes().router.call);
  app.mount('/api/v1/settings', SettingsRoutes().router.call);
  app.mount('/api/v1/dartboard', DartboardRoutes().router.call);
  app.mount('/api/v1/players', PlayerRoutes(dataDir).router.call);
  app.mount('/api/v1/games', SavedGameRoutes().router.call);
  app.mount('/api/v1/music', VictoryMusicRoutes(dataDir).router.call);
  app.mount('/api/v1/stats', FailedStatsRoutes().router.call);
  app.mount('/api/v1/test', TestRoutes(dataDir).router.call);

  // Build the request handler. If --web-root is set, layer a static-file
  // handler under the API router and add an SPA fallback so Flutter web's
  // client-side routing works (unknown paths -> index.html).
  Handler rootHandler;
  if (webRoot != null) {
    final absWebRoot = p.absolute(webRoot);
    if (!Directory(absWebRoot).existsSync()) {
      print('ERROR: --web-root directory does not exist: $absWebRoot');
      exit(1);
    }
    final indexPath = p.join(absWebRoot, 'index.html');
    final indexFile = File(indexPath);
    if (!indexFile.existsSync()) {
      print('ERROR: --web-root has no index.html: $indexPath');
      exit(1);
    }
    print('Serving Flutter web build from $absWebRoot');

    final staticHandler = createStaticHandler(
      absWebRoot,
      defaultDocument: 'index.html',
    );

    final indexBytes = indexFile.readAsBytesSync();
    Response spaFallback(Request req) {
      // Only rewrite to index.html for likely client-side route requests;
      // a missing /assets/foo.png should still 404 so the browser shows
      // the real error instead of getting HTML.
      if (req.method != 'GET') {
        return Response.notFound('Not found');
      }
      final segments = req.url.pathSegments;
      // NEVER rewrite API paths. A missing setting (`GET /api/v1/settings/
      // voice_enabled` when the row doesn't exist) is a real 404 the
      // router intentionally returns, and clients rely on that status to
      // treat "no value stored" as null. If we fall through to
      // index.html here, `api_client.dart:getSetting` gets 200 with an
      // HTML body, `jsonDecode` throws, and the queue's `loadSettings`
      // try/catch swallows the error before it applies ANY subsequent
      // voice preference — so on every restart the app defaults to
      // browser TTS + OS-default voice (German on a de-DE Windows
      // kiosk) even though `voice_engine`, `system_voice`, etc. are
      // persisted correctly server-side.
      if (segments.isNotEmpty && segments.first == 'api') {
        return Response.notFound('Not found');
      }
      if (segments.isNotEmpty && segments.last.contains('.')) {
        return Response.notFound('Not found');
      }
      return Response.ok(
        indexBytes,
        headers: {
          'content-type': 'text/html; charset=utf-8',
          'cache-control': 'no-cache',
        },
      );
    }

    rootHandler = Cascade()
        .add(app.call)
        .add(staticHandler)
        .add(spaFallback)
        .handler;
  } else {
    rootHandler = app.call;
  }

  // Apply middleware.
  final handler = const Pipeline()
      .addMiddleware(loggingMiddleware())
      .addMiddleware(corsMiddleware())
      .addMiddleware(dbSessionMiddleware())
      .addHandler(rootHandler);

  // Start server.
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('Server running on http://${server.address.host}:${server.port}');

  // Handle shutdown.
  ProcessSignal.sigint.watch().listen((_) {
    print('\nShutting down...');
    registry.closeAll();
    server.close();
    exit(0);
  });
}
