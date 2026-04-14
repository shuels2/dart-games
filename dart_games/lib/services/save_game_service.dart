import '../models/saved_game_metadata.dart';
import 'api/api_client.dart';

class SaveGameService {
  ApiClient? _client;

  SaveGameService([this._client]);

  /// Set the API client. Supports late initialization.
  void initialize(ApiClient client) {
    _client = client;
  }

  ApiClient get _api {
    if (_client == null) {
      throw StateError('SaveGameService not initialized. Call initialize() first.');
    }
    return _client!;
  }

  Future<void> saveGame(SavedGameMetadata metadata) async {
    await _api.saveGame(metadata.toJson());
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
