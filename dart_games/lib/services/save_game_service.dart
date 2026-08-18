import '../models/saved_game_metadata.dart';
import 'api/api_client.dart';

class SaveGameService {
  /// Client used when none is injected. `main()` points this at the app-wide
  /// [ApiClient] so the many `SaveGameService()` call sites in game screens
  /// share one http client instead of each minting one that nothing disposes.
  static ApiClient? defaultClient;

  ApiClient? _client;

  /// Creates a SaveGameService. If no [ApiClient] is provided, [defaultClient]
  /// is used, falling back to a fresh client (tests, tooling).
  SaveGameService([this._client]);

  /// Set the API client. Supports late initialization.
  void initialize(ApiClient client) {
    _client = client;
  }

  ApiClient get _api => _client ??= (defaultClient ?? ApiClient());

  Future<bool> saveGame(SavedGameMetadata metadata) async {
    final result = await _api.saveGame(metadata.toJson());
    if (result.isEmpty) {
      return false;
    }
    return true;
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
