import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../database/database_helpers.dart';
import '../models/saved_game_model.dart';

class SavedGameRoutes {
  final sqlite3.Database _db;

  SavedGameRoutes(this._db);

  Router get router {
    final router = Router();

    // GET /api/v1/games - List all saved games
    router.get('/', _getAll);

    // GET /api/v1/games/<gameType> - List saved games by type
    router.get('/<gameType>', _getByType);

    // POST /api/v1/games - Save/upsert a game (uses id from body)
    router.post('/', _save);

    // DELETE /api/v1/games/<id> - Delete saved game by id
    router.delete('/<id>', _delete);

    // DELETE /api/v1/games/type/<gameType> - Delete all games of a type
    router.delete('/type/<gameType>', _deleteByType);

    return router;
  }

  Future<Response> _getAll(Request request) async {
    final results = _db.select(
      'SELECT * FROM saved_games ORDER BY saved_at DESC;',
    );
    final games = resultSetToList(results)
        .map((row) => ServerSavedGame.fromDbRow(row).toJson())
        .toList();
    return Response.ok(
      jsonEncode(games),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _getByType(Request request, String gameType) async {
    final results = _db.select(
      'SELECT * FROM saved_games WHERE game_type = ? ORDER BY saved_at DESC;',
      [gameType],
    );
    final games = resultSetToList(results)
        .map((row) => ServerSavedGame.fromDbRow(row).toJson())
        .toList();
    return Response.ok(
      jsonEncode(games),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _save(Request request) async {
    final body = await request.readAsString();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final game = ServerSavedGame.fromJson(json);

    final stmt = _db.prepare('''
      INSERT OR REPLACE INTO saved_games
        (id, game_type, saved_at, player_names, progress_info,
         game_mode_name, leading_player_name, leading_player_score,
         game_state, waiting_for_takeout)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''');
    try {
      stmt.execute([
        game.id,
        game.gameType,
        game.savedAt,
        jsonEncode(game.playerNames),
        game.progressInfo,
        game.gameModeName,
        game.leadingPlayerName,
        game.leadingPlayerScore,
        jsonEncode(game.gameState),
        game.waitingForTakeout ? 1 : 0,
      ]);
    } finally {
      stmt.dispose();
    }

    return Response.ok(
      jsonEncode(game.toJson()),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _delete(Request request, String id) async {
    final stmt = _db.prepare('DELETE FROM saved_games WHERE id = ?;');
    try {
      stmt.execute([id]);
    } finally {
      stmt.dispose();
    }
    return Response(204);
  }

  Future<Response> _deleteByType(Request request, String gameType) async {
    final stmt = _db.prepare('DELETE FROM saved_games WHERE game_type = ?;');
    try {
      stmt.execute([gameType]);
    } finally {
      stmt.dispose();
    }
    return Response(204);
  }
}
