import 'package:flutter/foundation.dart';
import '../models/target_tag_game.dart';
import '../models/player.dart';
import '../models/saved_game_metadata.dart';
import '../services/save_game_service.dart';
import '../services/game_skip_turn_helper.dart';
import '../services/api/api_client.dart';

class TargetTagProvider extends ChangeNotifier {
  TargetTagGame? _currentGame;
  bool _waitingForTakeout = false;
  ApiClient? _apiClient;

  TargetTagProvider({ApiClient? apiClient}) : _apiClient = apiClient;

  // Getters
  TargetTagGame? get currentGame => _currentGame;

  bool get isGameActive =>
      _currentGame?.state == GameState.playing ||
      _currentGame?.state == GameState.suddenDeath;

  bool get shouldPromptTakeout => _waitingForTakeout;

  bool get isSuddenDeath => _currentGame?.state == GameState.suddenDeath;

  Player? getCurrentPlayer(List<Player> players) {
    if (_currentGame == null) return null;
    return _currentGame!.getCurrentPlayer(players);
  }

  String? getCurrentPlayerId() {
    return _currentGame?.getCurrentPlayerId();
  }

  int getCurrentPlayerDartsThrown() {
    return _currentGame?.getCurrentPlayerDartsThrown() ?? 0;
  }

  List<String> getCurrentTurnDarts(String playerId) {
    return _currentGame?.getCurrentTurnDarts(playerId) ?? [];
  }

  List<bool> getDartThrowTaggedInStatus(String playerId) {
    return _currentGame?.getDartThrowTaggedInStatus(playerId) ?? [];
  }

  List<bool> getDartThrowHeroBonusHit(String playerId) {
    return _currentGame?.getDartThrowHeroBonusHit(playerId) ?? [];
  }

  List<bool> getDartThrowReachedMax(String playerId) {
    return _currentGame?.getDartThrowReachedMax(playerId) ?? [];
  }

  List<bool> getDartThrowCausedElimination(String playerId) {
    return _currentGame?.getDartThrowCausedElimination(playerId) ?? [];
  }

  List<bool> getDartThrowHitOpponentTarget(String playerId) {
    return _currentGame?.getDartThrowHitOpponentTarget(playerId) ?? [];
  }

  bool get hasWinner => _currentGame?.hasWinner() ?? false;

  Player? getWinner(List<Player> players) {
    return _currentGame?.getWinner(players);
  }

  List<Player> getWinners(List<Player> players) {
    return _currentGame?.getWinners(players) ?? [];
  }

  // Get shields for entity (player or team)
  int getShields(String playerId) {
    if (_currentGame == null) return 0;
    final entityId = _currentGame!.mode == GameMode.solo
        ? playerId
        : _currentGame!.playerToTeam![playerId]!;
    return _currentGame!.getEntityShields(entityId);
  }

  // Check if player/team is tagged in
  bool isTaggedIn(String playerId) {
    if (_currentGame == null) return false;
    final entityId = _currentGame!.mode == GameMode.solo
        ? playerId
        : _currentGame!.playerToTeam![playerId]!;
    return _currentGame!.isEntityTaggedIn(entityId);
  }

  // Check if player/team is eliminated
  bool isEliminated(String playerId) {
    if (_currentGame == null) return false;
    final entityId = _currentGame!.mode == GameMode.solo
        ? playerId
        : _currentGame!.playerToTeam![playerId]!;
    return _currentGame!.isEntityEliminated(entityId);
  }

  // Get target number for player
  int? getTargetNumber(String playerId) {
    return _currentGame?.targetNumbers[playerId];
  }

  // Get solo hero buff number for a specific player (if applicable)
  int? getSoloHeroBuffNumber(String playerId) {
    return _currentGame?.soloHeroBuffNumbers?[playerId];
  }

  // Get solo hero buff multiplier for a specific player (if applicable)
  String? getSoloHeroBuffMultiplier(String playerId) {
    return _currentGame?.soloHeroBuffMultipliers?[playerId];
  }

  // Check if player is solo hero (has a buff number)
  bool isSoloHero(String playerId) {
    return _currentGame?.soloHeroBuffNumbers?.containsKey(playerId) ?? false;
  }

  // Start a new solo mode game
  void startSoloGame(List<Player> players, int shieldMax, bool heroBonus) {
    if (players.length < 2) {
      debugPrint('Cannot start solo game with less than 2 players');
      return;
    }

    if (shieldMax < 1 || shieldMax > 10) {
      debugPrint('Shield max must be between 1 and 10');
      return;
    }

    final playerIds = players.map((p) => p.id).toList();
    _currentGame = TargetTagGame.createSolo(
      playerIds: playerIds,
      shieldMax: shieldMax,
      heroBonus: heroBonus,
    );
    _waitingForTakeout = false;

    // Save initial turn start state
    _currentGame!.turnStartShields = Map.from(_currentGame!.shields);
    _currentGame!.turnStartTaggedIn = Map.from(_currentGame!.taggedIn);
    _currentGame!.turnStartEliminated = Map.from(_currentGame!.eliminated);
    _currentGame!.turnStartWinnerId = _currentGame!.winnerId;
    _currentGame!.turnStartState = _currentGame!.state;

    notifyListeners();
  }

  // Start a new team mode game
  void startTeamGame(
    Map<String, List<String>> teams,
    int shieldMax,
    bool soloHeroBonus, [
    Map<String, String>? teamIconOverrides,
  ]) {
    final totalPlayers = teams.values.fold<int>(0, (sum, team) => sum + team.length);

    if (totalPlayers < 3) {
      debugPrint('Cannot start team game with less than 3 players');
      return;
    }

    if (shieldMax < 1 || shieldMax > 10) {
      debugPrint('Shield max must be between 1 and 10');
      return;
    }

    _currentGame = TargetTagGame.createTeam(
      teams: teams,
      shieldMax: shieldMax,
      soloHeroBonus: soloHeroBonus,
      teamIconOverrides: teamIconOverrides,
    );
    _waitingForTakeout = false;

    // Save initial turn start state
    _currentGame!.turnStartShields = Map.from(_currentGame!.shields);
    _currentGame!.turnStartTaggedIn = Map.from(_currentGame!.taggedIn);
    _currentGame!.turnStartEliminated = Map.from(_currentGame!.eliminated);
    _currentGame!.turnStartWinnerId = _currentGame!.winnerId;
    _currentGame!.turnStartState = _currentGame!.state;

    notifyListeners();
  }

  // Process a dart throw from dartboard event
  void processDartThrow(String sector) {
    if (_currentGame == null || !isGameActive) return;
    if (_waitingForTakeout) return;

    // Parse sector string to get number and multiplier
    final parsed = _parseSector(sector);

    // Record the dart segment for display (track misses and "None" as "Miss")
    final currentPlayerId = _currentGame!.getCurrentPlayerId();
    _currentGame!.currentTurnDarts[currentPlayerId] ??= [];

    // Convert "None" or null to "Miss" for display
    final displaySector = (parsed == null || sector == 'None' || sector.isEmpty) ? 'Miss' : sector;
    _currentGame!.currentTurnDarts[currentPlayerId]!.add(displaySector);

    if (parsed == null) {
      // Process miss (increments dart counter, adds tracking arrays)
      _currentGame!.processMiss(currentPlayerId);

      // Check if this was the 3rd dart or if there's a winner
      final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();
      if (dartsThrown >= 3 || _currentGame!.hasWinner()) {
        _waitingForTakeout = true;
      }

      notifyListeners();
      return;
    }

    final number = parsed['number'] as int;
    final multiplier = parsed['multiplier'] as String;

    // Process the hit in game logic
    _currentGame!.processDartHit(currentPlayerId, number, multiplier);

    // Check if this was the 3rd dart or if there's a winner
    final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();
    if (dartsThrown >= 3 || _currentGame!.hasWinner()) {
      _waitingForTakeout = true;
    }

    notifyListeners();
  }

  // Parse dartboard sector string (e.g., "D20", "T19", "S18", "Bull")
  Map<String, dynamic>? _parseSector(String sector) {
    // Handle bulls
    if (sector == 'Bull') {
      return {'number': 50, 'multiplier': 'single'};
    }
    if (sector == '25') {
      return {'number': 25, 'multiplier': 'single'};
    }
    if (sector == 'None' || sector.isEmpty) {
      return null; // Treat "None" as a miss, not a score
    }

    // Parse regular sectors (D20, T19, S18, etc.)
    final match = RegExp(r'[A-Za-z](\d+)').firstMatch(sector);
    if (match == null) return null;

    final baseNumber = int.parse(match.group(1)!);
    String multiplier = 'single';

    if (sector.startsWith('D') || sector.startsWith('d')) {
      multiplier = 'double';
    } else if (sector.startsWith('T') || sector.startsWith('t')) {
      multiplier = 'triple';
    }

    return {'number': baseNumber, 'multiplier': multiplier};
  }

  // Skip remaining darts in current turn
  void skipTurn() {
    if (_currentGame == null) return;

    final currentPlayerId = _currentGame!.getCurrentPlayerId();
    final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();

    // Validate using global helper
    if (!GameSkipTurnHelper.canSkipTurn(
      gameActive: isGameActive,
      waitingForTakeout: _waitingForTakeout,
      currentDartCount: dartsThrown,
      maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
    )) {
      return;
    }

    // Execute skip using global helper
    GameSkipTurnHelper.skipRemainingDarts(
      currentDartCount: dartsThrown,
      maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
      addVisualMarker: (marker) {
        _currentGame!.currentTurnDarts[currentPlayerId] ??= [];
        _currentGame!.currentTurnDarts[currentPlayerId]!.add(marker);
      },
    );

    _waitingForTakeout = true;
    notifyListeners();
  }

  // Handle takeout finished event
  void handleTakeoutFinished() {
    if (_currentGame == null) return;
    if (!_waitingForTakeout) return;

    // If game is finished (winner exists), just clear waiting state
    if (_currentGame!.hasWinner()) {
      _waitingForTakeout = false;
      notifyListeners();
      return;
    }

    // Only advance if game is still active
    if (!isGameActive) return;

    // Advance to next player
    _currentGame!.advanceToNextPlayer();
    _waitingForTakeout = false;

    notifyListeners();
  }

  // --- Save/Restore ---

  String? _resumedSavedGameId;
  bool _saving = false;
  String? get resumedSavedGameId => _resumedSavedGameId;

  void clearResumedSavedGameId() {
    _resumedSavedGameId = null;
  }

  Future<void> saveGame(List<Player> players) async {
    debugPrint('[TargetTagProvider] saveGame called — _saving=$_saving, resumedId=$_resumedSavedGameId');
    if (_currentGame == null || _saving) {
      debugPrint('[TargetTagProvider] saveGame BLOCKED — game=${_currentGame != null}, _saving=$_saving');
      return;
    }
    _saving = true;
    try {
    final game = _currentGame!;

    // Count non-eliminated entities
    final entityIds = game.mode == GameMode.solo
        ? game.playerIds
        : game.teamPlayers!.keys.toList();
    final activeCount = entityIds.where((id) => !(game.eliminated[id] ?? false)).length;

    // Find leading entity (most shields)
    String leaderId = game.playerIds.first;
    int maxShields = 0;
    for (final entityId in entityIds) {
      final shields = game.shields[entityId] ?? 0;
      if (shields > maxShields) {
        maxShields = shields;
        leaderId = entityId;
      }
    }

    // Get leader display name
    String leaderName;
    if (game.mode == GameMode.team) {
      // For teams, get first player name from team
      final teamPlayers = game.teamPlayers![leaderId] ?? [];
      final teamPlayer = teamPlayers.isNotEmpty
          ? players.where((p) => p.id == teamPlayers.first).firstOrNull
          : null;
      leaderName = teamPlayer?.name ?? 'Team';
    } else {
      final player = players.where((p) => p.id == leaderId).firstOrNull;
      leaderName = player?.name ?? 'Unknown';
    }

    final metadata = SavedGameMetadata.create(
      gameType: 'target_tag',
      playerNames: players
          .where((p) => game.playerIds.contains(p.id))
          .map((p) => p.name)
          .toList(),
      progressInfo: '$activeCount of ${entityIds.length} players remaining',
      gameModeName: '${game.mode == GameMode.solo ? "Solo" : "Team"}, Shields: ${game.shieldMax}${game.soloHeroBonus ? ", Hero Bonus" : ""}',
      leadingPlayerName: leaderName,
      leadingPlayerScore: '$maxShields shields',
      gameState: game.toJson(),
      waitingForTakeout: _waitingForTakeout,
      existingId: _resumedSavedGameId,
    );

    debugPrint('[TargetTagProvider] saving with id=${metadata.id}');
    final saved = await SaveGameService(_apiClient).saveGame(metadata);
    if (saved) {
      _resumedSavedGameId = metadata.id;
    }
    debugPrint('[TargetTagProvider] saveGame completed — saved=$saved, resumedId=$_resumedSavedGameId');
    } finally {
      _saving = false;
    }
  }

  void restoreGame(SavedGameMetadata savedGame) {
    _currentGame = TargetTagGame.fromJson(
        Map<String, dynamic>.from(savedGame.gameState));
    _waitingForTakeout = savedGame.waitingForTakeout;
    _resumedSavedGameId = savedGame.id;
    notifyListeners();
  }

  // End the current game
  void endGame() {
    if (_currentGame != null) {
      _currentGame!.state = GameState.finished;
    }
    notifyListeners();
  }

  // Update a specific dart score and recalculate turn
  void updateDartScore(String playerId, int dartIndex, String newSector) {
    if (_currentGame == null) return;
    if (playerId != _currentGame!.getCurrentPlayerId()) return;

    // Get current turn data
    final currentTurnDarts = _currentGame!.currentTurnDarts[playerId] ?? [];
    if (dartIndex >= currentTurnDarts.length) return;

    // Store current game state to restore player index after recalculation
    final currentPlayerIndex = _currentGame!.currentPlayerIndex;

    // Clear the current turn data for this player
    _currentGame!.currentTurnDarts[playerId] = [];
    _currentGame!.dartsThrown[playerId] = 0;
    _currentGame!.dartThrowTaggedInStatus[playerId] = [];
    _currentGame!.dartThrowHeroBonusHit[playerId] = [];
    _currentGame!.dartThrowReachedMax[playerId] = [];
    _currentGame!.dartThrowCausedElimination[playerId] = [];
    _currentGame!.dartThrowHitOpponentTarget[playerId] = [];

    // Reset shields and tagged in status to start of turn
    _currentGame!.resetToStartOfTurn(playerId);

    // Replay all darts with the updated value
    for (int i = 0; i < currentTurnDarts.length; i++) {
      final sector = i == dartIndex ? newSector : currentTurnDarts[i];

      // Add to display
      _currentGame!.currentTurnDarts[playerId]!.add(sector);

      // Parse and process
      final parsed = _parseSector(sector);
      if (parsed == null) {
        _currentGame!.processMiss(playerId);
      } else {
        final number = parsed['number'] as int;
        final multiplier = parsed['multiplier'] as String;
        _currentGame!.processDartHit(playerId, number, multiplier);
      }
    }

    // Restore player index
    _currentGame!.currentPlayerIndex = currentPlayerIndex;

    // Check if turn should end
    final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();
    if (dartsThrown >= 3 || _currentGame!.hasWinner()) {
      _waitingForTakeout = true;
    }

    notifyListeners();
  }

  // Update all three dart scores at once and recalculate turn
  void updateAllDartScores(String playerId, List<String> newDartSegments) {
    if (_currentGame == null) return;
    if (playerId != _currentGame!.getCurrentPlayerId()) return;
    if (newDartSegments.length != 3) return;

    // Store current game state to restore player index after recalculation
    final currentPlayerIndex = _currentGame!.currentPlayerIndex;

    // Clear the current turn data for this player
    _currentGame!.currentTurnDarts[playerId] = [];
    _currentGame!.dartsThrown[playerId] = 0;
    _currentGame!.dartThrowTaggedInStatus[playerId] = [];
    _currentGame!.dartThrowHeroBonusHit[playerId] = [];
    _currentGame!.dartThrowReachedMax[playerId] = [];
    _currentGame!.dartThrowCausedElimination[playerId] = [];
    _currentGame!.dartThrowHitOpponentTarget[playerId] = [];

    // Reset shields and tagged in status to start of turn
    _currentGame!.resetToStartOfTurn(playerId);

    // Replay all three darts with the new values in order
    // This ensures each dart is processed with the correct game state
    for (int i = 0; i < 3; i++) {
      final sector = newDartSegments[i];

      // Add to display
      _currentGame!.currentTurnDarts[playerId]!.add(sector);

      // Parse and process
      final parsed = _parseSector(sector);
      if (parsed == null || sector == 'Miss') {
        _currentGame!.processMiss(playerId);
      } else {
        final number = parsed['number'] as int;
        final multiplier = parsed['multiplier'] as String;
        _currentGame!.processDartHit(playerId, number, multiplier);
      }
    }

    // Restore player index
    _currentGame!.currentPlayerIndex = currentPlayerIndex;

    // Check if turn should end
    final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();
    if (dartsThrown >= 3 || _currentGame!.hasWinner()) {
      _waitingForTakeout = true;
    }

    notifyListeners();
  }

  // Clear the current game
  void clearGame() {
    _currentGame = null;
    _waitingForTakeout = false;
    notifyListeners();
  }

  // Get team icon path
  String? getTeamIcon(String teamId) {
    return _currentGame?.teamIcons?[teamId];
  }

  // Get team players
  List<String>? getTeamPlayers(String teamId) {
    return _currentGame?.teamPlayers?[teamId];
  }

  // Get all active (non-eliminated) players
  List<String> getActivePlayers() {
    if (_currentGame == null) return [];
    return _currentGame!.playerIds
        .where((id) => !isEliminated(id))
        .toList();
  }
}
