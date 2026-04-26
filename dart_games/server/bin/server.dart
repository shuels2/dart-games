import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

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
    ..addOption('db-path', defaultsTo: 'data/dart_games.db');

  final results = parser.parse(args);
  final port = int.parse(results['port'] as String);
  final dataDir = results['data-dir'] as String;
  final dbPath = results['db-path'] as String;

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

  // Apply middleware.
  final handler = const Pipeline()
      .addMiddleware(loggingMiddleware())
      .addMiddleware(corsMiddleware())
      .addMiddleware(dbSessionMiddleware())
      .addHandler(app.call);

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
