import 'package:flutter/foundation.dart';
import '../models/player.dart';
import '../models/game_history_entry.dart';
import '../services/photo_service.dart';
import '../services/api/api_client.dart';
import '../services/api/api_config.dart';

class PlayerProvider extends ChangeNotifier {
  static const String _lastSortedKey = 'players_last_sorted_at';

  List<Player> _allPlayers = [];
  List<Player> _selectedPlayers = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastSortedAt;

  /// Populated after a photo upload when the server-side face-landmark
  /// detection ran and failed. Set to the sidecar's `errorReason`
  /// (`no-face-detected`, `python-not-found`, `timeout`, etc.) so the
  /// caller (Add Player / Edit Player dialog) can show a non-blocking
  /// hint. Cleared at the START of every `savePlayer` call so a
  /// previous session's error never carries over.
  String? _lastPhotoUploadFaceLandmarksError;
  String? get lastPhotoUploadFaceLandmarksError =>
      _lastPhotoUploadFaceLandmarksError;

  /// O(1) `id → Player` lookup, lazily built. Invalidated on every
  /// [notifyListeners] call (which we override to clear the cache).
  /// Beats `firstWhere` in build methods that do many lookups per render.
  Map<String, Player>? _byIdCache;

  /// Override to invalidate `_byIdCache` on every state change.
  @override
  void notifyListeners() {
    _byIdCache = null;
    super.notifyListeners();
  }

  /// O(1) lookup for a player by id. Returns null if no such player.
  /// Use this in hot paths instead of `allPlayers.firstWhere(...)`.
  Player? byId(String id) {
    return (_byIdCache ??= {for (final p in _allPlayers) p.id: p})[id];
  }

  /// Guard against concurrent loadPlayers() calls.  If a load is already
  /// in flight, subsequent callers await the same future instead of
  /// firing a second GET that could clobber a freshly-saved player.
  Future<void>? _activeLoad;

  /// Monotonically increasing counter.  Incremented by [resetForTesting]
  /// so that any in-flight [_doLoadPlayers] HTTP response that was issued
  /// before the reset is silently discarded instead of overwriting the
  /// now-empty list.
  int _generation = 0;

  /// Per-player cache-bust token for photo URLs. The photo upload
  /// endpoint is the same URL on every replace — `/api/v1/players/<id>
  /// /photo` — and NetworkImage / the browser image cache key off URL
  /// alone, so without a bust suffix a freshly uploaded photo keeps
  /// rendering as the OLD cached bytes. Generated on every successful
  /// upload, cleared on deletion, applied by [_doLoadPlayers] when it
  /// promotes relative server-issued URLs to absolute so the bust
  /// survives subsequent loadPlayers() calls (every game-menu screen
  /// fires one on init).
  final Map<String, String> _photoBusts = {};

  final PhotoService _photoService = PhotoService();
  ApiClient? _apiClient;

  /// Set the API client. Call once at app startup.
  void initialize(ApiClient client) {
    _apiClient = client;
  }

  ApiClient get _api {
    if (_apiClient == null) {
      throw StateError('PlayerProvider not initialized. Call initialize() first.');
    }
    return _apiClient!;
  }

  /// Reset all client-side player state.  Call this from test helpers
  /// *after* the server-side reset so that both sides are in sync.
  ///
  /// Incrementing [_generation] ensures that any in-flight GET /players
  /// response (sent before the reset) is silently discarded when it
  /// finally arrives, instead of repopulating the list with stale data.
  void resetForTesting() {
    _generation++;
    _allPlayers = [];
    _selectedPlayers = [];
    _activeLoad = null;
    _isLoading = false;
    _error = null;
    _lastSortedAt = null;
    _photoBusts.clear();
    notifyListeners();
  }

  // Getters
  List<Player> get allPlayers => List.unmodifiable(_allPlayers);
  List<Player> get selectedPlayers => List.unmodifiable(_selectedPlayers);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load players from API
  Future<void> loadPlayers() async {
    // If a load is already in progress, piggy-back on it instead of
    // starting a second concurrent GET that could clobber local state.
    if (_activeLoad != null) {
      await _activeLoad;
      return;
    }
    _activeLoad = _doLoadPlayers();
    try {
      await _activeLoad;
    } finally {
      _activeLoad = null;
    }
  }

  Future<void> _doLoadPlayers() async {
    final loadGeneration = _generation;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final playersJson = await _api.getPlayers();

      // If a resetForTesting() was called while the GET was in flight,
      // discard this (now stale) response entirely.
      if (_generation != loadGeneration) return;

      final serverPlayers =
          playersJson.map((json) => Player.fromJson(json)).map((p) {
        // Server returns photoPath as a RELATIVE URL (e.g.
        // `/api/v1/players/<id>/photo`) because it doesn't know its own
        // public base. On Flutter web, NetworkImage with a relative URL
        // resolves against the PAGE origin (the Flutter web devserver),
        // not against the API server — so the fetch silently fails.
        // Promote to absolute here using the currently-configured API
        // base so PlayerAvatarWidget and all `NetworkImage(photoPath!)`
        // consumers fetch from the right host.
        //
        // Also re-apply any per-player cache-bust token that was set by
        // a prior upload this session — without it, loadPlayers() would
        // reset photoPath to the canonical (un-busted) URL and the
        // browser would serve the OLD cached bytes that were fetched
        // before the user took a new photo.
        final path = p.photoPath;
        if (path == null) return p;
        if (path.startsWith('/')) {
          final bust = _photoBusts[p.id];
          final busted = bust != null ? '$path?v=$bust' : path;
          return p.copyWith(photoPath: ApiConfig.url(busted));
        }
        return p;
      }).toList();

      // Merge: start with the server's authoritative list, then preserve
      // any locally-known players that the server doesn't have yet
      // (optimistic adds whose POST is still in flight).
      final serverIds = serverPlayers.map((p) => p.id).toSet();
      final localOnly =
          _allPlayers.where((p) => !serverIds.contains(p.id)).toList();
      _allPlayers = [...serverPlayers, ...localOnly];

      // Load last sorted timestamp from settings
      final lastSortedStr = await _api.getSetting(_lastSortedKey);
      if (lastSortedStr != null) {
        _lastSortedAt = DateTime.parse(lastSortedStr);
      }

      // Sort players (alphabetically, with new players at bottom)
      _sortPlayers();
    } catch (e) {
      _error = 'Failed to load players: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sort players alphabetically, keeping newly added players at the bottom
  void _sortPlayers() {
    if (_allPlayers.isEmpty) return;

    final sortedAt = _lastSortedAt ?? DateTime.now(); // Default to now if never sorted

    // Separate into "old" (sorted) and "new" (unsorted) players
    final oldPlayers = _allPlayers
        .where((p) =>
            p.createdAt.isBefore(sortedAt) ||
            p.createdAt.isAtSameMomentAs(sortedAt))
        .toList();
    final newPlayers =
        _allPlayers.where((p) => p.createdAt.isAfter(sortedAt)).toList();

    // Sort old players alphabetically (case-insensitive)
    oldPlayers.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Rebuild list: sorted old players + unsorted new players
    _allPlayers = [...oldPlayers, ...newPlayers];
  }

  /// Overwrite a player's face_landmarks (used by the face-mapping
  /// inspector in System Settings). Writes through to the server, then
  /// updates the in-memory Player and notifies listeners.
  ///
  /// On server failure the local state is left unchanged.
  Future<void> updateFaceLandmarks(
    String playerId,
    Map<String, dynamic> landmarks,
  ) async {
    final persisted =
        await _api.updatePlayerFaceLandmarks(playerId, landmarks);
    final index = _allPlayers.indexWhere((p) => p.id == playerId);
    if (index >= 0) {
      _allPlayers[index] =
          _allPlayers[index].copyWith(faceLandmarks: persisted);
      notifyListeners();
    }
  }

  /// Re-run mediapipe on the player's photo, replace stored landmarks
  /// with the fresh result, and update local state. Returns the new
  /// landmarks so the caller (e.g. the inspector) can refresh its UI.
  Future<Map<String, dynamic>> redetectFaceLandmarks(String playerId) async {
    final fresh = await _api.redetectPlayerFaceLandmarks(playerId);
    final index = _allPlayers.indexWhere((p) => p.id == playerId);
    if (index >= 0) {
      _allPlayers[index] =
          _allPlayers[index].copyWith(faceLandmarks: fresh);
      notifyListeners();
    }
    return fresh;
  }

  // Add or update a player
  Future<void> savePlayer(Player player) async {
    // Reset the photo upload detection-error hint so a stale message
    // from a previous save can't leak into this call's UI treatment.
    _lastPhotoUploadFaceLandmarksError = null;
    try {
      final index = _allPlayers.indexWhere((p) => p.id == player.id);

      if (index >= 0) {
        // Update existing player. Capture the previous photo path BEFORE we
        // overwrite the in-memory entry so _syncPlayerPhoto can tell whether
        // the user removed a photo (previous non-null, new null → delete).
        final previousPhotoPath = _allPlayers[index].photoPath;
        _allPlayers[index] = player;
        notifyListeners();
        await _api.updatePlayer(player.id, {'name': player.name});
        await _syncPlayerPhoto(player, previousPhotoPath);
      } else {
        // Optimistically add to the local list before the server round-trip.
        // This prevents a concurrent loadPlayers() from returning a list
        // that is missing the just-created player.
        _allPlayers.add(player);
        notifyListeners();
        try {
          final result = await _api.createPlayer({
            'id': player.id,
            'name': player.name,
            'createdAt': player.createdAt.toIso8601String(),
          });
          if (result.isEmpty) {
            _allPlayers.removeWhere((p) => p.id == player.id);
            notifyListeners();
            return;
          }
          // A concurrent loadPlayers() may have replaced _allPlayers while
          // the API call was in flight, clobbering the optimistic add.
          // Re-add if the player is no longer present.
          if (!_allPlayers.any((p) => p.id == player.id)) {
            _allPlayers.add(player);
            notifyListeners();
          }
          // Fresh player has no previous photo on the server, so any
          // non-null photoPath here is a freshly-captured upload candidate.
          await _syncPlayerPhoto(player, null);
        } catch (e) {
          // Roll back the optimistic add on server failure
          _allPlayers.removeWhere((p) => p.id == player.id);
          notifyListeners();
          rethrow;
        }
      }
    } catch (e) {
      _error = 'Failed to save player: $e';
      print(_error);
      notifyListeners();
    }
  }

  /// Synchronize the player's photo with the server based on the difference
  /// between `player.photoPath` (the value the caller wants to persist) and
  /// `previousPhotoPath` (what was on the in-memory record before the save).
  ///
  /// Three cases:
  ///   1. New photoPath is a `data:image/...;base64,...` URL (the format
  ///      WebCameraWidget returns on web) → strip the prefix and POST to
  ///      `/players/<id>/photo`. After a successful upload, swap the local
  ///      photoPath to the API URL the server returns photos at, so
  ///      PlayerAvatarWidget's NetworkImage can fetch it the same way as
  ///      a player loaded fresh from the server.
  ///   2. New photoPath is null AND previous was non-null → user removed
  ///      the photo via the dialog's "remove" button. DELETE on the server.
  ///   3. Anything else (mobile filesystem path, already-an-API URL, null
  ///      with no previous photo) → no-op. Mobile photos stay local; an
  ///      unchanged API URL is already in sync.
  ///
  /// Photo upload failures don't roll back the create/update — the player
  /// record is still valid, just photo-less server-side. The error is
  /// logged so the user sees a hint in DevTools.
  Future<void> _syncPlayerPhoto(
      Player player, String? previousPhotoPath) async {
    final newPhoto = player.photoPath;

    // Case 2: photo removed.
    if (newPhoto == null && previousPhotoPath != null) {
      try {
        await _api.deletePlayerPhoto(player.id);
        // Clear any stale bust — the photo no longer exists so future
        // loadPlayers should leave photoPath null without trying to
        // construct a busted URL for a missing resource.
        _photoBusts.remove(player.id);
      } catch (e) {
        debugPrint('[Photo] DELETE failed for player ${player.id}: $e');
      }
      return;
    }

    if (newPhoto == null) return;

    // Case 1: new capture (data URL → upload).
    if (newPhoto.startsWith('data:image/')) {
      final commaIdx = newPhoto.indexOf(',');
      if (commaIdx < 0) return; // malformed; bail silently
      final base64Data = newPhoto.substring(commaIdx + 1);
      try {
        final result = await _api.uploadPlayerPhoto(
            player.id, base64Data, 'photo.jpg');
        // Server now runs face-landmark detection synchronously before
        // responding. On success it echoes the fresh landmarks so we
        // can cache them locally instead of requiring a follow-up GET
        // /players. On failure it echoes an error string so the Add /
        // Edit Player dialog can show a non-blocking hint.
        _lastPhotoUploadFaceLandmarksError = result.faceLandmarksError;
        // Store + apply a per-player cache-bust token. The upload
        // replaces the file behind the SAME endpoint `/api/v1/players/
        // <id>/photo`, and NetworkImage / the browser image cache key
        // off URL alone, so without the suffix a re-uploaded photo
        // serves the stale cached image. Storing the bust in
        // [_photoBusts] also lets [_doLoadPlayers] re-apply it on
        // every subsequent loadPlayers() — without that persistence,
        // the next game-menu's initState-time loadPlayers() would
        // wipe the bust and the browser cache would re-serve the OLD
        // photo bytes that were cached BEFORE the upload happened.
        final cacheBust = DateTime.now().millisecondsSinceEpoch.toString();
        _photoBusts[player.id] = cacheBust;
        final idx = _allPlayers.indexWhere((p) => p.id == player.id);
        if (idx >= 0) {
          _allPlayers[idx] = _allPlayers[idx].copyWith(
            photoPath: ApiConfig.url(
                '/api/v1/players/${player.id}/photo?v=$cacheBust'),
            // Cache the freshly-detected landmarks locally so widgets
            // that watch this provider render themed avatars correctly
            // without waiting for a loadPlayers() cycle. Only overwrite
            // when detection actually ran (result.faceLandmarks non-null)
            // so a `detectLandmarks:false` opt-out upload doesn't blow
            // away a manual override that landed via a previous PATCH.
            faceLandmarks: result.faceLandmarks ??
                _allPlayers[idx].faceLandmarks,
          );
          notifyListeners();
        }
      } catch (e) {
        debugPrint('[Photo] Upload failed for player ${player.id}: $e');
      }
      return;
    }

    // Case 3: filesystem path / existing API URL / unchanged — no-op.
  }

  /// Persist a list of pre-existing GameHistoryEntries to the server for a
  /// given player. Used by the "Load Test Data" feature to seed games_played
  /// and games_won on player records that have a populated `gameHistory`
  /// list. Each entry's `metadata.won` flag drives whether `games_won` is
  /// incremented server-side.
  ///
  /// Does NOT update local state — callers should call [loadPlayers] after
  /// to refresh from the server.
  Future<void> seedPlayerHistory(
      String playerId, List<GameHistoryEntry> history) async {
    if (history.isEmpty) return;
    final entries = history.map((h) => {
          'playerId': playerId,
          'gameName': h.gameName,
          'timestamp': h.timestamp.toIso8601String(),
          'durationMs': h.duration.inMilliseconds,
          'metadata': h.metadata ?? <String, dynamic>{},
          'dartThrows': h.dartThrows,
          'turns': h.turns,
          'playerCount': h.playerCount,
        }).toList();
    try {
      await _api.batchAddPlayerHistory(entries);
    } catch (e) {
      print('seedPlayerHistory: failed for $playerId: $e');
      // Best-effort — caller will refresh via loadPlayers anyway.
    }
  }

  /// Bulk-delete every saved game on the server. Used by the System
  /// Settings "Clear All Data" flow. Saved games are NOT cascaded by
  /// player delete (the saved_games table stores player NAMES, not ids,
  /// and has no FK to players), so this must be called explicitly.
  Future<void> deleteAllSavedGames() async {
    try {
      await _api.deleteAllSavedGames();
    } catch (e) {
      print('deleteAllSavedGames failed: $e');
    }
  }

  /// Bulk-delete every failed_stats row on the server. Used by the
  /// System Settings "Clear All Data" flow. failed_stats has no FK to
  /// players, so its rows persist after player delete unless we wipe
  /// them explicitly.
  Future<void> deleteAllFailedStats() async {
    try {
      await _api.deleteAllFailedStats();
    } catch (e) {
      print('deleteAllFailedStats failed: $e');
    }
  }

  // Delete a player
  Future<void> deletePlayer(String id) async {
    try {
      final player = _allPlayers.firstWhere((p) => p.id == id);

      // Delete photo if exists
      if (player.photoPath != null) {
        await _photoService.deletePhoto(player.photoPath!);
      }

      // Delete via API (cascades to game_history on server)
      await _api.deletePlayer(id);

      _allPlayers.removeWhere((p) => p.id == id);
      _selectedPlayers.removeWhere((p) => p.id == id);

      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete player: $e';
      print(_error);
      notifyListeners();
    }
  }

  // Select a player for the current game
  void selectPlayer(Player player, {int maxPlayers = 8}) {
    if (_selectedPlayers.length >= maxPlayers) {
      _error = 'Maximum $maxPlayers players allowed';
      notifyListeners();
      return;
    }

    if (!_selectedPlayers.any((p) => p.id == player.id)) {
      _selectedPlayers.add(player);
      notifyListeners();
    }
  }

  // Deselect a player
  void deselectPlayer(String id) {
    _selectedPlayers.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // Clear all selected players
  void clearSelection() {
    _selectedPlayers.clear();
    notifyListeners();
  }

  // Mark players as sorted (called when leaving a screen)
  Future<void> markPlayersSorted() async {
    try {
      _lastSortedAt = DateTime.now();
      await _api.putSetting(_lastSortedKey, _lastSortedAt!.toIso8601String());
    } catch (e) {
      print('Failed to save last sorted timestamp: $e');
    }
  }

  // Update player stats after a game
  Future<void> updatePlayerStats(
    String playerId, {
    bool won = false,
    String? gameName,
    Duration? gameDuration,
    int? dartThrows,
    int? turns,
    int? playerCount,
  }) async {
    try {
      final index = _allPlayers.indexWhere((p) => p.id == playerId);
      if (index < 0) {
        // Player no longer exists locally (e.g. cleared by a test reset).
        print('updatePlayerStats: player $playerId not found locally, skipping');
        await _logFailedStatsToServer(
          playerId: playerId,
          won: won,
          gameName: gameName,
          gameDuration: gameDuration,
          dartThrows: dartThrows,
          turns: turns,
          playerCount: playerCount,
          errorMessage: 'Player not found in local list',
        );
        return;
      }

      final player = _allPlayers[index];

      // Create new game history list
      final updatedHistory = List<GameHistoryEntry>.from(player.gameHistory);

      // If we have game details, add to history (for both winners and losers)
      if (gameName != null && gameDuration != null) {
        final entry = GameHistoryEntry.create(
          gameName: gameName,
          duration: gameDuration,
          dartThrows: dartThrows,
          turns: turns,
          playerCount: playerCount,
          metadata: {'won': won},
        );
        updatedHistory.add(entry);

        // Persist to server — tolerate 404 if the player was deleted
        // between game-end and stats-update (e.g. by a test reset).
        try {
          await _api.addPlayerHistory(playerId, {
            'gameName': gameName,
            'timestamp': entry.timestamp.toIso8601String(),
            'durationMs': gameDuration.inMilliseconds,
            'metadata': {'won': won},
            'dartThrows': dartThrows,
            'turns': turns,
            'playerCount': playerCount,
          });
        } catch (e) {
          print('updatePlayerStats: server rejected history for $playerId: $e');
          await _logFailedStatsToServer(
            playerId: playerId,
            playerName: player.name,
            won: won,
            gameName: gameName,
            gameDuration: gameDuration,
            dartThrows: dartThrows,
            turns: turns,
            playerCount: playerCount,
            errorMessage: e.toString(),
          );
        }
      } else {
        try {
          // Deltas, not absolutes: two games finishing at once must not
          // clobber each other's increment.
          await _api.incrementPlayerStats(
            playerId,
            gamesPlayed: 1,
            gamesWon: won ? 1 : 0,
          );
        } catch (e) {
          print('updatePlayerStats: server rejected stats for $playerId: $e');
          await _logFailedStatsToServer(
            playerId: playerId,
            playerName: player.name,
            won: won,
            gameName: gameName,
            gameDuration: gameDuration,
            dartThrows: dartThrows,
            turns: turns,
            playerCount: playerCount,
            errorMessage: e.toString(),
          );
        }
      }

      // Re-check index in case _allPlayers was modified by a concurrent
      // loadPlayers() while we were awaiting the server call.
      final currentIndex = _allPlayers.indexWhere((p) => p.id == playerId);
      if (currentIndex >= 0) {
        final currentPlayer = _allPlayers[currentIndex];
        final updated = currentPlayer.copyWith(
          gamesPlayed: currentPlayer.gamesPlayed + 1,
          gamesWon: won ? currentPlayer.gamesWon + 1 : currentPlayer.gamesWon,
          gameHistory: updatedHistory,
        );
        _allPlayers[currentIndex] = updated;
        final selectedIndex = _selectedPlayers.indexWhere((p) => p.id == playerId);
        if (selectedIndex >= 0) {
          _selectedPlayers[selectedIndex] = updated;
        }
        notifyListeners();
      }
    } catch (e) {
      // Log only — this runs as fire-and-forget from results screens,
      // so setting _error and calling notifyListeners() can cascade-throw
      // if the provider or listening widgets have been disposed.
      print('Failed to update player stats: $e');
    }
  }

  /// Update stats for many players in a single server round-trip.
  ///
  /// Mirrors [updatePlayerStats] for each entry but POSTs once to
  /// `/api/v1/players/history/batch`. Calls [notifyListeners] exactly
  /// once after all local mutations land. Failures (unknown player ids,
  /// server rejections) are routed to `failed_stats` per-entry, just like
  /// the single-player path.
  Future<void> batchUpdatePlayerStats(
    List<PlayerStatsUpdate> updates,
  ) async {
    if (updates.isEmpty) return;

    try {
      // Build the payload + remember per-update local-history rows so we
      // can apply the local mutation after the server confirms.
      final entries = <Map<String, dynamic>>[];
      final pending = <_PendingStatsApply>[];

      for (final u in updates) {
        final index = _allPlayers.indexWhere((p) => p.id == u.playerId);
        if (index < 0) {
          await _logFailedStatsToServer(
            playerId: u.playerId,
            won: u.won,
            gameName: u.gameName,
            gameDuration: u.gameDuration,
            dartThrows: u.dartThrows,
            turns: u.turns,
            playerCount: u.playerCount,
            errorMessage: 'Player not found in local list',
          );
          continue;
        }

        final player = _allPlayers[index];
        final entry = GameHistoryEntry.create(
          gameName: u.gameName,
          duration: u.gameDuration,
          dartThrows: u.dartThrows,
          turns: u.turns,
          playerCount: u.playerCount,
          metadata: {'won': u.won},
        );
        entries.add({
          'playerId': u.playerId,
          'gameName': u.gameName,
          'timestamp': entry.timestamp.toIso8601String(),
          'durationMs': u.gameDuration.inMilliseconds,
          'metadata': {'won': u.won},
          'dartThrows': u.dartThrows,
          'turns': u.turns,
          'playerCount': u.playerCount,
        });
        pending.add(_PendingStatsApply(
          playerId: u.playerId,
          playerName: player.name,
          won: u.won,
          historyEntry: entry,
          source: u,
        ));
      }

      if (entries.isEmpty) return;

      // Single round-trip.  Tolerate a complete server failure the same
      // way the per-player path does — log every entry to failed_stats.
      Map<String, dynamic>? result;
      try {
        result = await _api.batchAddPlayerHistory(entries);
      } catch (e) {
        print('batchUpdatePlayerStats: server rejected batch: $e');
        for (final p in pending) {
          await _logFailedStatsToServer(
            playerId: p.playerId,
            playerName: p.playerName,
            won: p.won,
            gameName: p.source.gameName,
            gameDuration: p.source.gameDuration,
            dartThrows: p.source.dartThrows,
            turns: p.source.turns,
            playerCount: p.source.playerCount,
            errorMessage: e.toString(),
          );
        }
        return;
      }

      // Per-entry failures returned by the server (e.g. unknown id).
      final failedIds = <String>{};
      final failed = result['failed'];
      if (failed is List) {
        for (final f in failed) {
          if (f is Map && f['playerId'] is String) {
            final id = f['playerId'] as String;
            failedIds.add(id);
            final reason = f['reason'] as String? ?? 'unknown';
            final p = pending.firstWhere(
              (e) => e.playerId == id,
              orElse: () => _PendingStatsApply.absent(id),
            );
            await _logFailedStatsToServer(
              playerId: p.playerId,
              playerName: p.playerName,
              won: p.won,
              gameName: p.source.gameName,
              gameDuration: p.source.gameDuration,
              dartThrows: p.source.dartThrows,
              turns: p.source.turns,
              playerCount: p.source.playerCount,
              errorMessage: 'server: $reason',
            );
          }
        }
      }

      // Apply local mutations for the surviving entries; one notify at the end.
      for (final p in pending) {
        if (failedIds.contains(p.playerId)) continue;
        final currentIndex =
            _allPlayers.indexWhere((pl) => pl.id == p.playerId);
        if (currentIndex < 0) continue;
        final currentPlayer = _allPlayers[currentIndex];
        final updatedHistory =
            List<GameHistoryEntry>.from(currentPlayer.gameHistory)
              ..add(p.historyEntry);
        final updated = currentPlayer.copyWith(
          gamesPlayed: currentPlayer.gamesPlayed + 1,
          gamesWon: p.won ? currentPlayer.gamesWon + 1 : currentPlayer.gamesWon,
          gameHistory: updatedHistory,
        );
        _allPlayers[currentIndex] = updated;
        final selectedIndex =
            _selectedPlayers.indexWhere((pl) => pl.id == p.playerId);
        if (selectedIndex >= 0) {
          _selectedPlayers[selectedIndex] = updated;
        }
      }
      notifyListeners();
    } catch (e) {
      print('Failed to batch-update player stats: $e');
    }
  }

  /// Best-effort POST to /api/v1/stats/failed so the failure is
  /// persisted in the database for later investigation or replay.
  Future<void> _logFailedStatsToServer({
    required String playerId,
    String? playerName,
    required bool won,
    String? gameName,
    Duration? gameDuration,
    int? dartThrows,
    int? turns,
    int? playerCount,
    required String errorMessage,
  }) async {
    try {
      await _api.logFailedStats({
        'playerId': playerId,
        'playerName': playerName,
        'gameName': gameName,
        'won': won,
        'durationMs': gameDuration?.inMilliseconds,
        'dartThrows': dartThrows,
        'turns': turns,
        'playerCount': playerCount,
        'errorMessage': errorMessage,
      });
    } catch (e) {
      // If even the failure log fails (e.g. server is down),
      // there's nothing more we can do — just print.
      print('Failed to log stats failure to server: $e');
    }
  }

  // Get player by ID. Backed by [byId] for O(1) lookup.
  Player? getPlayerById(String id) => byId(id);

  // Get game history for a player
  List<GameHistoryEntry> getPlayerHistory(String playerId) {
    final player = getPlayerById(playerId);
    return player?.gameHistory ?? [];
  }

  // Get all wins for a specific game
  List<GameHistoryEntry> getPlayerHistoryForGame(
      String playerId, String gameName) {
    final history = getPlayerHistory(playerId);
    return history.where((entry) => entry.gameName == gameName).toList();
  }

  // Get player's total time played across all games
  Duration getPlayerTotalPlayTime(String playerId) {
    final history = getPlayerHistory(playerId);
    return history.fold(
      Duration.zero,
      (total, entry) => total + entry.duration,
    );
  }

  // Get player's average game duration for a specific game
  Duration? getPlayerAverageGameDuration(String playerId, String gameName) {
    final gameHistory = getPlayerHistoryForGame(playerId, gameName);
    if (gameHistory.isEmpty) return null;

    final totalMs = gameHistory.fold(
      0,
      (sum, entry) => sum + entry.duration.inMilliseconds,
    );
    return Duration(milliseconds: totalMs ~/ gameHistory.length);
  }

  // Get total darts thrown across all games
  int getPlayerTotalDartsThrown(String playerId) {
    final history = getPlayerHistory(playerId);
    return history.fold(0, (total, entry) => total + (entry.dartThrows ?? 0));
  }

  // Get total turns (legs) across all games
  int getPlayerTotalTurns(String playerId) {
    final history = getPlayerHistory(playerId);
    return history.fold(0, (total, entry) => total + (entry.turns ?? 0));
  }

  // Get total players encountered across all games
  int getPlayerTotalPlayersEncountered(String playerId) {
    final history = getPlayerHistory(playerId);
    return history.fold(0, (total, entry) => total + (entry.playerCount ?? 0));
  }

  // Get average darts per game (for specific game)
  double? getPlayerAverageDartsPerGame(String playerId, String gameName) {
    final gameHistory = getPlayerHistoryForGame(playerId, gameName);
    if (gameHistory.isEmpty) return null;

    final totalDarts = gameHistory.fold(0, (sum, entry) => sum + (entry.dartThrows ?? 0));
    return totalDarts / gameHistory.length;
  }

  // Get average turns per game (for specific game)
  double? getPlayerAverageTurnsPerGame(String playerId, String gameName) {
    final gameHistory = getPlayerHistoryForGame(playerId, gameName);
    if (gameHistory.isEmpty) return null;

    final totalTurns = gameHistory.fold(0, (sum, entry) => sum + (entry.turns ?? 0));
    return totalTurns / gameHistory.length;
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// One player's stats update, batched together with peers via
/// [PlayerProvider.batchUpdatePlayerStats].
class PlayerStatsUpdate {
  final String playerId;
  final bool won;
  final String gameName;
  final Duration gameDuration;
  final int? dartThrows;
  final int? turns;
  final int? playerCount;

  const PlayerStatsUpdate({
    required this.playerId,
    required this.won,
    required this.gameName,
    required this.gameDuration,
    this.dartThrows,
    this.turns,
    this.playerCount,
  });
}

/// Internal bookkeeping for a pending stats apply waiting on the server.
class _PendingStatsApply {
  final String playerId;
  final String playerName;
  final bool won;
  final GameHistoryEntry historyEntry;
  final PlayerStatsUpdate source;

  _PendingStatsApply({
    required this.playerId,
    required this.playerName,
    required this.won,
    required this.historyEntry,
    required this.source,
  });

  /// Synthetic record for an entry the server reported as failed before
  /// we had a chance to capture the player's name (i.e. unknown id).
  factory _PendingStatsApply.absent(String playerId) {
    return _PendingStatsApply(
      playerId: playerId,
      playerName: '',
      won: false,
      historyEntry: GameHistoryEntry.create(
        gameName: '',
        duration: Duration.zero,
      ),
      source: PlayerStatsUpdate(
        playerId: playerId,
        won: false,
        gameName: '',
        gameDuration: Duration.zero,
      ),
    );
  }
}
