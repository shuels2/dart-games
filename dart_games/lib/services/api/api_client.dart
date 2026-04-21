import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// HTTP client for the Dart Games backend API.
///
/// Provides typed methods for all API endpoints. All methods return
/// parsed JSON or throw [ApiException] on failure.
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void dispose() {
    _client.close();
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// GET /api/v1/settings - Returns all settings as { key: value }.
  Future<Map<String, String>> getSettings() async {
    final response = await _get('/api/v1/settings');
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as String));
  }

  /// GET /api/v1/settings/<key> - Returns a single setting.
  Future<String?> getSetting(String key) async {
    final response = await _client.get(_bustCache('/api/v1/settings/$key'));
    if (response.statusCode == 404) return null;
    _checkResponse(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['value'] as String;
  }

  /// PUT /api/v1/settings/<key> - Create/update a setting.
  Future<void> putSetting(String key, String value) async {
    await _put('/api/v1/settings/$key', {'value': value});
  }

  /// DELETE /api/v1/settings/<key> - Delete a setting.
  Future<void> deleteSetting(String key) async {
    await _delete('/api/v1/settings/$key');
  }

  /// PUT /api/v1/settings - Bulk update settings.
  Future<void> putSettings(Map<String, String> settings) async {
    await _put('/api/v1/settings', settings);
  }

  // ---------------------------------------------------------------------------
  // Dartboard
  // ---------------------------------------------------------------------------

  /// GET /api/v1/dartboard - Get dartboard configuration.
  Future<Map<String, dynamic>> getDartboard() async {
    final response = await _get('/api/v1/dartboard');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// PUT /api/v1/dartboard - Update dartboard configuration.
  Future<Map<String, dynamic>> updateDartboard(Map<String, dynamic> config) async {
    final response = await _put('/api/v1/dartboard', config);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// DELETE /api/v1/dartboard - Clear dartboard configuration.
  Future<void> clearDartboard() async {
    await _delete('/api/v1/dartboard');
  }

  /// GET /api/v1/dartboard/profiles - List all connection profiles.
  Future<List<Map<String, dynamic>>> getDartboardProfiles() async {
    final response = await _get('/api/v1/dartboard/profiles');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// PUT /api/v1/dartboard/profiles/<serialNumber> - Upsert a profile.
  Future<void> upsertDartboardProfile(
    String serialNumber,
    Map<String, dynamic> profile,
  ) async {
    await _put('/api/v1/dartboard/profiles/$serialNumber', profile);
  }

  /// DELETE /api/v1/dartboard/profiles/<serialNumber> - Delete a profile.
  Future<void> deleteDartboardProfile(String serialNumber) async {
    await _delete('/api/v1/dartboard/profiles/$serialNumber');
  }

  // ---------------------------------------------------------------------------
  // Players
  // ---------------------------------------------------------------------------

  /// GET /api/v1/players - List all players with game history.
  Future<List<Map<String, dynamic>>> getPlayers() async {
    final response = await _get('/api/v1/players');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /api/v1/players/<id> - Get a single player.
  Future<Map<String, dynamic>?> getPlayer(String id) async {
    final response = await _client.get(_bustCache('/api/v1/players/$id'));
    if (response.statusCode == 404) return null;
    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /api/v1/players - Create a player.
  Future<Map<String, dynamic>> createPlayer(Map<String, dynamic> player) async {
    final response = await _post('/api/v1/players', player);
    if (response.statusCode == 409) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// PUT /api/v1/players/<id> - Update a player.
  Future<Map<String, dynamic>> updatePlayer(String id, Map<String, dynamic> data) async {
    final response = await _put('/api/v1/players/$id', data);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// DELETE /api/v1/players/<id> - Delete a player.
  Future<void> deletePlayer(String id) async {
    await _delete('/api/v1/players/$id');
  }

  /// POST /api/v1/players/<id>/photo - Upload a player photo.
  Future<String> uploadPlayerPhoto(String id, String base64Data, String fileName) async {
    final response = await _post('/api/v1/players/$id/photo', {
      'photoData': base64Data,
      'fileName': fileName,
    });
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['photoPath'] as String;
  }

  /// GET /api/v1/players/<id>/photo - Get player photo bytes.
  Future<Uint8List?> getPlayerPhoto(String id) async {
    final response = await _client.get(_bustCache('/api/v1/players/$id/photo'));
    if (response.statusCode == 404) return null;
    _checkResponse(response);
    return response.bodyBytes;
  }

  /// DELETE /api/v1/players/<id>/photo - Delete player photo.
  Future<void> deletePlayerPhoto(String id) async {
    await _delete('/api/v1/players/$id/photo');
  }

  /// POST /api/v1/players/<id>/history - Add game history entry.
  Future<Map<String, dynamic>> addPlayerHistory(
    String id,
    Map<String, dynamic> entry,
  ) async {
    final response = await _post('/api/v1/players/$id/history', entry);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// PUT /api/v1/players/<id>/stats - Update player stats.
  Future<void> updatePlayerStats(
    String id, {
    required int gamesPlayed,
    required int gamesWon,
  }) async {
    await _put('/api/v1/players/$id/stats', {
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
    });
  }

  // ---------------------------------------------------------------------------
  // Saved Games
  // ---------------------------------------------------------------------------

  /// GET /api/v1/games - List all saved games.
  Future<List<Map<String, dynamic>>> getSavedGames() async {
    final response = await _get('/api/v1/games');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /api/v1/games/<gameType> - List saved games by type.
  Future<List<Map<String, dynamic>>> getSavedGamesByType(String gameType) async {
    final response = await _get('/api/v1/games/$gameType');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// POST /api/v1/games - Save/upsert a game.
  Future<Map<String, dynamic>> saveGame(Map<String, dynamic> game) async {
    final response = await _post('/api/v1/games', game);
    if (response.statusCode == 409) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// DELETE /api/v1/games/<id> - Delete a saved game.
  Future<void> deleteSavedGame(String id) async {
    await _delete('/api/v1/games/$id');
  }

  /// DELETE /api/v1/games/type/<gameType> - Delete all games of a type.
  Future<void> deleteSavedGamesByType(String gameType) async {
    await _delete('/api/v1/games/type/$gameType');
  }

  // ---------------------------------------------------------------------------
  // Victory Music
  // ---------------------------------------------------------------------------

  /// GET /api/v1/music - List all music files.
  Future<List<Map<String, dynamic>>> getMusic() async {
    final response = await _get('/api/v1/music');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /api/v1/music/current - Get current music info.
  Future<Map<String, dynamic>?> getCurrentMusic() async {
    final response = await _client.get(_bustCache('/api/v1/music/current'));
    if (response.statusCode == 404) return null;
    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /api/v1/music - Upload a music file (base64).
  Future<Map<String, dynamic>> uploadMusic(String fileName, String base64Data) async {
    final response = await _post('/api/v1/music', {
      'fileName': fileName,
      'fileData': base64Data,
    });
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// PUT /api/v1/music/<id>/current - Set as current music.
  Future<void> setCurrentMusic(String id) async {
    await _put('/api/v1/music/$id/current', {});
  }

  /// GET /api/v1/music/<id>/file - Download music file bytes.
  Future<Uint8List?> getMusicFile(String id) async {
    final response = await _client.get(_bustCache('/api/v1/music/$id/file'));
    if (response.statusCode == 404) return null;
    _checkResponse(response);
    return response.bodyBytes;
  }

  /// DELETE /api/v1/music/<id> - Delete a music file.
  Future<void> deleteMusic(String id) async {
    await _delete('/api/v1/music/$id');
  }

  /// DELETE /api/v1/music - Delete all music files.
  Future<void> deleteAllMusic() async {
    await _delete('/api/v1/music');
  }

  // ---------------------------------------------------------------------------
  // Failed Stats
  // ---------------------------------------------------------------------------

  /// GET /api/v1/stats/failed - List all failed stats entries.
  Future<List<Map<String, dynamic>>> getFailedStats() async {
    final response = await _get('/api/v1/stats/failed');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// POST /api/v1/stats/failed - Log a failed stats update.
  Future<void> logFailedStats(Map<String, dynamic> entry) async {
    await _post('/api/v1/stats/failed', entry);
  }

  // ---------------------------------------------------------------------------
  // Health
  // ---------------------------------------------------------------------------

  /// GET /api/v1/health - Check server health.
  Future<Map<String, dynamic>> health() async {
    final response = await _get('/api/v1/health');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // HTTP helpers
  // ---------------------------------------------------------------------------

  /// Build a cache-busting URI for GET requests.
  ///
  /// Appends a unique `_=<timestamp>` query parameter so every GET request
  /// has a distinct URL.  This prevents the browser from serving stale
  /// cached responses via XMLHttpRequest/fetch — even when `Cache-Control`
  /// request headers are set, some browsers still honour cached entries for
  /// the same URL.  A unique URL guarantees a fresh server round-trip.
  static Uri _bustCache(String path) {
    final base = Uri.parse(ApiConfig.url(path));
    return base.replace(queryParameters: {
      ...base.queryParameters,
      '_': DateTime.now().microsecondsSinceEpoch.toString(),
    });
  }

  Future<http.Response> _get(String path) async {
    final response = await _client.get(_bustCache(path));
    _checkResponse(response);
    return response;
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final headers = <String, String>{'content-type': 'application/json'};
    final epoch = ApiConfig.testEpoch;
    if (epoch != null) {
      headers['X-Test-Epoch'] = epoch.toString();
    }
    final response = await _client.post(
      Uri.parse(ApiConfig.url(path)),
      headers: headers,
      body: jsonEncode(body),
    );
    // Silently accept 409 from the server's test epoch guard — the server
    // correctly rejected a stale request from a prior test epoch.
    if (response.statusCode == 409 && epoch != null) {
      return response;
    }
    _checkResponse(response);
    return response;
  }

  Future<http.Response> _put(String path, Map<String, dynamic> body) async {
    final headers = <String, String>{'content-type': 'application/json'};
    final epoch = ApiConfig.testEpoch;
    if (epoch != null) {
      headers['X-Test-Epoch'] = epoch.toString();
    }
    final response = await _client.put(
      Uri.parse(ApiConfig.url(path)),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 409 && epoch != null) {
      return response;
    }
    _checkResponse(response);
    return response;
  }

  Future<http.Response> _delete(String path) async {
    final response = await _client.delete(Uri.parse(ApiConfig.url(path)));
    _checkResponse(response);
    return response;
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(response.statusCode, response.body);
  }
}

/// Exception thrown when an API call returns a non-2xx status.
class ApiException implements Exception {
  final int statusCode;
  final String body;

  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
