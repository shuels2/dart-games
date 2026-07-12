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
  ///
  /// Returns `null` if the setting is missing (404) OR if the response body
  /// isn't a well-formed `{"key": ..., "value": ...}` map. The second case
  /// defends against a misrouted server response — e.g. an SPA fallback
  /// catching a missing-key 404 and returning `index.html` with a 200
  /// status. A single unparseable response would otherwise throw out of
  /// `getSetting`, propagate up to `game_announcement_queue_service.dart`'s
  /// `loadSettings` catch, and abort the entire voice-settings load
  /// before ANY subsequent preference (engine, voice, rate) is applied —
  /// which is exactly how the "always defaults to browser TTS + OS voice"
  /// regression manifested. Treating a malformed body as "no value stored"
  /// lets the rest of `loadSettings` proceed with the caller-provided
  /// defaults, matching the missing-key semantics.
  Future<String?> getSetting(String key) async {
    final response = await _client.get(
      _bustCache('/api/v1/settings/$key'),
      headers: _sessionHeaders(),
    );
    if (response.statusCode == 404) return null;
    _checkResponse(response);
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['value'] as String?;
    } catch (_) {
      return null;
    }
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
    final response = await _client.get(
      _bustCache('/api/v1/players/$id'),
      headers: _sessionHeaders(),
    );
    if (response.statusCode == 404) return null;
    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /api/v1/players - Create a player.
  Future<Map<String, dynamic>> createPlayer(Map<String, dynamic> player) async {
    final response = await _post('/api/v1/players', player);
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
  ///
  /// The server now waits for the mediapipe sidecar (or the OpenCV Haar
  /// fallback) to finish detecting face landmarks BEFORE responding, so
  /// the response either includes the fresh landmarks (on success) or
  /// an [UploadPlayerPhotoResult.faceLandmarksError] naming the failure
  /// mode (`no-face-detected`, `python-not-found`, `timeout`, etc.).
  /// Callers should surface the error field non-fatally — the photo is
  /// saved either way.
  ///
  /// When [detectLandmarks] is false the server skips detection entirely
  /// — useful when the caller is about to PATCH a known landmark
  /// override and doesn't want the sidecar racing past it. In that case
  /// both `faceLandmarks` and `faceLandmarksError` will be null on the
  /// returned record.
  Future<UploadPlayerPhotoResult> uploadPlayerPhoto(
    String id,
    String base64Data,
    String fileName, {
    bool detectLandmarks = true,
  }) async {
    final response = await _post('/api/v1/players/$id/photo', {
      'photoData': base64Data,
      'fileName': fileName,
      'detectLandmarks': detectLandmarks,
    });
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final rawLandmarks = body['faceLandmarks'];
    return UploadPlayerPhotoResult(
      photoPath: body['photoPath'] as String,
      faceLandmarks: rawLandmarks is Map
          ? Map<String, dynamic>.from(rawLandmarks as Map)
          : null,
      faceLandmarksError: body['faceLandmarksError'] as String?,
    );
  }

  /// GET /api/v1/players/<id>/photo - Get player photo bytes.
  Future<Uint8List?> getPlayerPhoto(String id) async {
    final response = await _client.get(
      _bustCache('/api/v1/players/$id/photo'),
      headers: _sessionHeaders(),
    );
    if (response.statusCode == 404) return null;
    _checkResponse(response);
    return response.bodyBytes;
  }

  /// DELETE /api/v1/players/<id>/photo - Delete player photo.
  Future<void> deletePlayerPhoto(String id) async {
    await _delete('/api/v1/players/$id/photo');
  }

  /// PATCH /api/v1/players/<id>/face-landmarks - Overwrite stored landmarks
  /// with a manually-corrected payload. Returns the persisted landmarks.
  Future<Map<String, dynamic>> updatePlayerFaceLandmarks(
    String id,
    Map<String, dynamic> landmarks,
  ) async {
    final response =
        await _patch('/api/v1/players/$id/face-landmarks', landmarks);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['faceLandmarks'] as Map).cast<String, dynamic>();
  }

  /// GET /api/v1/players/face-landmarks/diagnostics - Kiosk-friendly
  /// probe of the mediapipe sidecar plumbing. Returns a Map with
  /// pythonCommand / sidecarPath / mediapipeOk / mediapipeError /
  /// workingDirectory / scriptPath / platform so the operator can see
  /// exactly why Re-detect is (or would be) failing.
  Future<Map<String, dynamic>> faceLandmarksDiagnostics() async {
    final response = await _get('/api/v1/players/face-landmarks/diagnostics');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /api/v1/players/<id>/face-landmarks/redetect - Re-run mediapipe on
  /// the player's current photo and overwrite stored landmarks. Returns the
  /// freshly-detected landmarks on success.
  ///
  /// On a 503 (detection failed), the server returns a JSON body of the
  /// shape `{"error": "<reason>: <human message>"}` — see
  /// `FaceLandmarksResult` in the server. We unwrap that here so the
  /// caller sees `FaceLandmarksException` with just the operator-facing
  /// message instead of the raw `ApiException(503): {"error":"..."}`.
  Future<Map<String, dynamic>> redetectPlayerFaceLandmarks(String id) async {
    try {
      final response =
          await _post('/api/v1/players/$id/face-landmarks/redetect', const {});
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['faceLandmarks'] as Map).cast<String, dynamic>();
    } on ApiException catch (e) {
      String message = e.body;
      try {
        final parsed = jsonDecode(e.body);
        if (parsed is Map<String, dynamic> && parsed['error'] is String) {
          message = parsed['error'] as String;
        }
      } catch (_) {
        // Fall back to the raw body if it isn't JSON.
      }
      throw FaceLandmarksException(e.statusCode, message);
    }
  }

  /// POST /api/v1/players/<id>/history - Add game history entry.
  Future<Map<String, dynamic>> addPlayerHistory(
    String id,
    Map<String, dynamic> entry,
  ) async {
    final response = await _post('/api/v1/players/$id/history', entry);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /api/v1/players/history/batch - Add history entries for many
  /// players in one request. Each entry MUST include a `playerId` key plus
  /// the same fields accepted by `addPlayerHistory`. Returns
  /// `{"saved": <count>, "failed": [{"playerId": "...", "reason": "..."}]}`.
  Future<Map<String, dynamic>> batchAddPlayerHistory(
    List<Map<String, dynamic>> entries,
  ) async {
    final response = await _post(
      '/api/v1/players/history/batch',
      {'entries': entries},
    );
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

  /// DELETE /api/v1/games - Delete EVERY saved game (no type filter).
  /// Used by the System Settings "Clear All Data" flow.
  Future<void> deleteAllSavedGames() async {
    await _delete('/api/v1/games');
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
    final response = await _client.get(
      _bustCache('/api/v1/music/current'),
      headers: _sessionHeaders(),
    );
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
    final response = await _client.get(
      _bustCache('/api/v1/music/$id/file'),
      headers: _sessionHeaders(),
    );
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

  /// DELETE /api/v1/stats/failed - Clear EVERY failed-stats entry.
  /// Used by the System Settings "Clear All Data" flow. Note: failed_stats
  /// rows are NOT cascaded by player delete (no FK constraint), so this
  /// must be called explicitly to fully wipe player-related data.
  Future<void> deleteAllFailedStats() async {
    await _delete('/api/v1/stats/failed');
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

  /// Returns headers with X-DB-Session if a session is active.
  static Map<String, String>? _sessionHeaders() {
    final session = ApiConfig.dbSession;
    if (session == null) return null;
    return {'X-DB-Session': session};
  }

  /// Merges content-type, optional session header, into a single map.
  static Map<String, String> _jsonHeaders() {
    final headers = <String, String>{'content-type': 'application/json'};
    final session = ApiConfig.dbSession;
    if (session != null) {
      headers['X-DB-Session'] = session;
    }
    return headers;
  }

  Future<http.Response> _get(String path) async {
    final response = await _client.get(
      _bustCache(path),
      headers: _sessionHeaders(),
    );
    _checkResponse(response);
    return response;
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse(ApiConfig.url(path)),
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );
    _checkResponse(response);
    return response;
  }

  Future<http.Response> _put(String path, Map<String, dynamic> body) async {
    final response = await _client.put(
      Uri.parse(ApiConfig.url(path)),
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );
    _checkResponse(response);
    return response;
  }

  Future<http.Response> _patch(String path, Map<String, dynamic> body) async {
    final response = await _client.patch(
      Uri.parse(ApiConfig.url(path)),
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );
    _checkResponse(response);
    return response;
  }

  Future<http.Response> _delete(String path) async {
    final headers = _sessionHeaders();
    final response = await _client.delete(
      Uri.parse(ApiConfig.url(path)),
      headers: headers,
    );
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

/// Thrown by [ApiClient.redetectPlayerFaceLandmarks] on a 503 so the
/// UI can render just the human-facing failure reason (e.g. "python
/// not found", "no face detected in photo") instead of the raw JSON.
class FaceLandmarksException implements Exception {
  final int statusCode;
  final String reason;

  FaceLandmarksException(this.statusCode, this.reason);

  @override
  String toString() => reason;
}

/// Result of [ApiClient.uploadPlayerPhoto]. The upload always yields a
/// photo path; the face-landmark fields are populated based on what
/// the server-side synchronous detection produced:
///   - `faceLandmarks` set, `faceLandmarksError` null → detection ran
///     and found a face; the map is the mediapipe/OpenCV landmark shape.
///   - `faceLandmarks` null, `faceLandmarksError` set → detection ran
///     but failed; the string is the sidecar's `errorReason` (e.g.
///     `no-face-detected`, `python-not-found`, `timeout`). Callers
///     should surface it non-fatally; the photo is still saved.
///   - Both null → the caller opted out via `detectLandmarks: false`.
class UploadPlayerPhotoResult {
  final String photoPath;
  final Map<String, dynamic>? faceLandmarks;
  final String? faceLandmarksError;

  const UploadPlayerPhotoResult({
    required this.photoPath,
    this.faceLandmarks,
    this.faceLandmarksError,
  });
}
