import 'package:flutter/foundation.dart';
import '../models/player.dart';
import '../models/game_history_entry.dart';
import '../services/photo_service.dart';
import '../services/api/api_client.dart';

class PlayerProvider extends ChangeNotifier {
  static const String _lastSortedKey = 'players_last_sorted_at';

  List<Player> _allPlayers = [];
  List<Player> _selectedPlayers = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastSortedAt;

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
          playersJson.map((json) => Player.fromJson(json)).toList();

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

  // Add or update a player
  Future<void> savePlayer(Player player) async {
    try {
      final index = _allPlayers.indexWhere((p) => p.id == player.id);

      if (index >= 0) {
        // Update existing player
        _allPlayers[index] = player;
        notifyListeners();
        await _api.updatePlayer(player.id, {'name': player.name});
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
          await _api.updatePlayerStats(
            playerId,
            gamesPlayed: player.gamesPlayed + 1,
            gamesWon: won ? player.gamesWon + 1 : player.gamesWon,
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
