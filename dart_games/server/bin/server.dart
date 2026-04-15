import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:dart_games_server/database/database.dart';
import 'package:dart_games_server/middleware/cors_middleware.dart';
import 'package:dart_games_server/middleware/logging_middleware.dart';
import 'package:dart_games_server/routes/dartboard_routes.dart';
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
    ..addOption('db-path', defaultsTo: 'data/dart_games.db');

  final results = parser.parse(args);
  final port = int.parse(results['port'] as String);
  final dataDir = results['data-dir'] as String;
  final dbPath = results['db-path'] as String;

  // Ensure data directories exist.
  Directory(dataDir).createSync(recursive: true);
  Directory('$dataDir/music').createSync(recursive: true);
  Directory('$dataDir/photos').createSync(recursive: true);

  // Initialize database.
  final database = Database(dbPath);
  final db = database.rawDb;
  print('Database initialized at $dbPath');

  // Build the router.
  final app = Router();

  // Mount route groups.
  app.mount('/api/v1/health', HealthRoutes().router.call);
  app.mount('/api/v1/settings', SettingsRoutes(db).router.call);
  app.mount('/api/v1/dartboard', DartboardRoutes(db).router.call);
  app.mount('/api/v1/players', PlayerRoutes(db, dataDir).router.call);
  app.mount('/api/v1/games', SavedGameRoutes(db).router.call);
  app.mount('/api/v1/music', VictoryMusicRoutes(db, dataDir).router.call);
  app.mount('/api/v1/test', TestRoutes(db, dataDir).router.call);

  // Apply middleware.
  final handler = const Pipeline()
      .addMiddleware(loggingMiddleware())
      .addMiddleware(corsMiddleware())
      .addHandler(app.call);

  // Start server.
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('Server running on http://${server.address.host}:${server.port}');

  // Handle shutdown.
  ProcessSignal.sigint.watch().listen((_) {
    print('\nShutting down...');
    database.close();
    server.close();
    exit(0);
  });
}
