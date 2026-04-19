import 'package:flutter/foundation.dart';
import '../models/saved_game_metadata.dart';
import 'api/api_client.dart';

class SaveGameService {
  ApiClient? _client;

  /// Creates a SaveGameService. If no [ApiClient] is provided, a default
  /// one is created using the current [ApiConfig] base URL.
  SaveGameService([this._client]);

  /// Set the API client. Supports late initialization.
  void initialize(ApiClient client) {
    _client = client;
  }

  ApiClient get _api => _client ??= ApiClient();

  Future<void> saveGame(SavedGameMetadata metadata) async {
    debugPrint('[SaveGameService] saveGame called — id=${metadata.id}, type=${metadata.gameType}');
    await _api.saveGame(metadata.toJson());
    debugPrint('[SaveGameService] saveGame completed — id=${metadata.id}');
  }

  Future<List<SavedGameMetadata>> loadSavedGames(String gameType) async {
    final games = await _api.getSavedGamesByType(gameType);
    return games.map((json) => SavedGameMetadata.fromJson(json)).toList();
  }

  Future<void> deleteSavedGame(String gameType, String id) async {
    await _api.deleteSavedGame(id);
  }

  Future<void> deleteAllSavedGames(String gameType) async {
    await _api.deleteSavedGamesByType(gameType);
  }

  Future<bool> hasSavedGames(String gameType) async {
    final games = await _api.getSavedGamesByType(gameType);
    return games.isNotEmpty;
  }
}
