import 'package:flutter/foundation.dart';
import '../models/target_tag_game.dart';
import '../models/player.dart';
import '../models/saved_game_metadata.dart';
import '../services/save_game_service.dart';
import '../services/api/api_client.dart';
import '../utils/dart_sector.dart';
import 'game_provider_base.dart';

class TargetTagProvider extends GameProviderBase<TargetTagGame> {
  final ApiClient? _apiClient;

  TargetTagProvider({ApiClient? apiClient}) : _apiClient = apiClient;

  // Getters
  TargetTagGame? get currentGame => game;

  @override
  bool get isGameActive =>
      game?.state == GameState.playing ||
      game?.state == GameState.suddenDeath;

  bool get isSuddenDeath => game?.state == GameState.suddenDeath;

  Player? getCurrentPlayer(List<Player> players) {
    if (game == null) return null;
    return game!.getCurrentPlayer(players);
  }

  String? getCurrentPlayerId() {
    return game?.getCurrentPlayerId();
  }

  int getCurrentPlayerDartsThrown() {
    return game?.getCurrentPlayerDartsThrown() ?? 0;
  }

  List<String> getCurrentTurnDarts(String playerId) {
    return game?.getCurrentTurnDarts(playerId) ?? [];
  }

  List<bool> getDartThrowTaggedInStatus(String playerId) {
    return game?.getDartThrowTaggedInStatus(playerId) ?? [];
  }

  List<bool> getDartThrowHeroBonusHit(String playerId) {
    return game?.getDartThrowHeroBonusHit(playerId) ?? [];
  }

  List<bool> getDartThrowReachedMax(String playerId) {
    return game?.getDartThrowReachedMax(playerId) ?? [];
  }

  List<bool> getDartThrowCausedElimination(String playerId) {
    return game?.getDartThrowCausedElimination(playerId) ?? [];
  }

  List<bool> getDartThrowHitOpponentTarget(String playerId) {
    return game?.getDartThrowHitOpponentTarget(playerId) ?? [];
  }

  @override
  bool get hasWinner => game?.hasWinner() ?? false;

  Player? getWinner(List<Player> players) {
    return game?.getWinner(players);
  }

  List<Player> getWinners(List<Player> players) {
    return game?.getWinners(players) ?? [];
  }

  // Get shields for entity (player or team)
  int getShields(String playerId) {
    if (game == null) return 0;
    final entityId = game!.mode == GameMode.solo
        ? playerId
        : game!.playerToTeam![playerId]!;
    return game!.getEntityShields(entityId);
  }

  // Check if player/team is tagged in
  bool isTaggedIn(String playerId) {
    if (game == null) return false;
    final entityId = game!.mode == GameMode.solo
        ? playerId
        : game!.playerToTeam![playerId]!;
    return game!.isEntityTaggedIn(entityId);
  }

  // Check if player/team is eliminated
  bool isEliminated(String playerId) {
    if (game == null) return false;
    final entityId = game!.mode == GameMode.solo
        ? playerId
        : game!.playerToTeam![playerId]!;
    return game!.isEntityEliminated(entityId);
  }

  // Get target number for player
  int? getTargetNumber(String playerId) {
    return game?.targetNumbers[playerId];
  }

  // Get solo hero buff number for a specific player (if applicable)
  int? getSoloHeroBuffNumber(String playerId) {
    return game?.soloHeroBuffNumbers?[playerId];
  }

  // Get solo hero buff multiplier for a specific player (if applicable)
  String? getSoloHeroBuffMultiplier(String playerId) {
    return game?.soloHeroBuffMultipliers?[playerId];
  }

  // Check if player is solo hero (has a buff number)
  bool isSoloHero(String playerId) {
    return game?.soloHeroBuffNumbers?.containsKey(playerId) ?? false;
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

    // A genuinely new game must not inherit the previous game's saved-game
    // slot — otherwise this game's first save overwrites (and destroys) a
    // still-resumable abandoned game. See F2 in the plan notes.
    clearResumedSavedGameId();

    final playerIds = players.map((p) => p.id).toList();
    game = TargetTagGame.createSolo(
      playerIds: playerIds,
      shieldMax: shieldMax,
      heroBonus: heroBonus,
    );
    waitingForTakeout = false;

    _captureTurnStartState();

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

    // New game — forget any resumed slot (see startSoloGame).
    clearResumedSavedGameId();

    game = TargetTagGame.createTeam(
      teams: teams,
      shieldMax: shieldMax,
      soloHeroBonus: soloHeroBonus,
      teamIconOverrides: teamIconOverrides,
    );
    waitingForTakeout = false;

    _captureTurnStartState();

    notifyListeners();
  }

  /// Snapshots the shields/tagged-in/eliminated maps so Edit Score can replay
  /// a turn from a clean starting point.
  void _captureTurnStartState() {
    final g = game!;
    g.turnStartShields = Map.from(g.shields);
    g.turnStartTaggedIn = Map.from(g.taggedIn);
    g.turnStartEliminated = Map.from(g.eliminated);
    g.turnStartWinnerId = g.winnerId;
    g.turnStartState = g.state;
  }

  // Process a dart throw from dartboard event
  void processDartThrow(String sector) {
    if (game == null || !isGameActive) return;
    if (shouldPromptTakeout) return;

    // Parse sector string to get number and multiplier
    final parsed = _parseSector(sector);

    // Record the dart segment for display (track misses and "None" as "Miss")
    final currentPlayerId = game!.getCurrentPlayerId();
    game!.currentTurnDarts[currentPlayerId] ??= [];

    // Convert "None" or null to "Miss" for display
    final displaySector = (parsed == null || sector == 'None' || sector.isEmpty) ? 'Miss' : sector;
    game!.currentTurnDarts[currentPlayerId]!.add(displaySector);

    if (parsed == null) {
      // Process miss (increments dart counter, adds tracking arrays)
      game!.processMiss(currentPlayerId);
      _latchTakeoutIfTurnOver();
      notifyListeners();
      return;
    }

    final number = parsed['number'] as int;
    final multiplier = parsed['multiplier'] as String;

    // Process the hit in game logic
    game!.processDartHit(currentPlayerId, number, multiplier);

    _latchTakeoutIfTurnOver();

    notifyListeners();
  }

  void _latchTakeoutIfTurnOver() {
    checkTakeoutCondition(
      dartsThrown: game!.getCurrentPlayerDartsThrown(),
      maxDartsPerTurn: game!.maxDartsPerTurn,
    );
  }

  /// Parses a board sector string into this game's legacy map shape.
  ///
  /// Delegates to [DartSector]; null still means "treat as a miss", which is
  /// what every caller here already does.
  Map<String, dynamic>? _parseSector(String sector) {
    final dart = DartSector.parse(sector);
    if (dart.isMiss) return null;
    return {'number': dart.legacyNumber, 'multiplier': dart.multiplierName};
  }

  // Skip remaining darts in current turn
  void skipTurn() {
    if (game == null) return;

    final currentPlayerId = game!.getCurrentPlayerId();

    runSkipTurn(
      dartsThrown: game!.getCurrentPlayerDartsThrown(),
      maxDartsPerTurn: game!.maxDartsPerTurn,
      addVisualMarker: (marker) {
        game!.currentTurnDarts[currentPlayerId] ??= [];
        game!.currentTurnDarts[currentPlayerId]!.add(marker);
      },
    );
  }

  @override
  void advanceToNextPlayer() => game!.advanceToNextPlayer();

  @override
  void loadGameState(Map<String, dynamic> json) {
    game = TargetTagGame.fromJson(json);
  }

  // --- Save ---

  Future<void> saveGame(List<Player> players, {bool isAutoSave = false}) async {
    await persistSave(SaveGameService(_apiClient), (existingId) {
      final g = game!;

      // Count non-eliminated entities
      final entityIds = g.mode == GameMode.solo
          ? g.playerIds
          : g.teamPlayers!.keys.toList();
      final activeCount =
          entityIds.where((id) => !(g.eliminated[id] ?? false)).length;

      // Find leading entity (most shields)
      String leaderId = g.playerIds.first;
      int maxShields = 0;
      for (final entityId in entityIds) {
        final shields = g.shields[entityId] ?? 0;
        if (shields > maxShields) {
          maxShields = shields;
          leaderId = entityId;
        }
      }

      // Get leader display name
      String leaderName;
      if (g.mode == GameMode.team) {
        // For teams, get first player name from team
        final teamPlayers = g.teamPlayers![leaderId] ?? [];
        final teamPlayer = teamPlayers.isNotEmpty
            ? players.where((p) => p.id == teamPlayers.first).firstOrNull
            : null;
        leaderName = teamPlayer?.name ?? 'Team';
      } else {
        final player = players.where((p) => p.id == leaderId).firstOrNull;
        leaderName = player?.name ?? 'Unknown';
      }

      return SavedGameMetadata.create(
        gameType: 'target_tag',
        playerNames: players
            .where((p) => g.playerIds.contains(p.id))
            .map((p) => p.name)
            .toList(),
        progressInfo: '$activeCount of ${entityIds.length} players remaining',
        gameModeName:
            '${g.mode == GameMode.solo ? "Solo" : "Team"}, Shields: ${g.shieldMax}${g.soloHeroBonus ? ", Hero Bonus" : ""}',
        leadingPlayerName: leaderName,
        leadingPlayerScore: '$maxShields shields',
        gameState: g.toJson(),
        waitingForTakeout: shouldPromptTakeout,
        isAutoSave: isAutoSave,
        existingId: existingId,
      );
    });
  }

  // End the current game
  void endGame() {
    if (game != null) {
      game!.state = GameState.finished;
    }
    notifyListeners();
  }

  // Update all three dart scores at once and recalculate turn
  void updateAllDartScores(String playerId, List<String> newDartSegments) {
    if (game == null) return;
    if (playerId != game!.getCurrentPlayerId()) return;
    if (newDartSegments.length != 3) return;

    // Store current game state to restore player index after recalculation
    final currentPlayerIndex = game!.currentPlayerIndex;

    // Clear the current turn data for this player
    game!.currentTurnDarts[playerId] = [];
    game!.dartsThrown[playerId] = 0;
    game!.dartThrowTaggedInStatus[playerId] = [];
    game!.dartThrowHeroBonusHit[playerId] = [];
    game!.dartThrowReachedMax[playerId] = [];
    game!.dartThrowCausedElimination[playerId] = [];
    game!.dartThrowHitOpponentTarget[playerId] = [];

    // Reset shields and tagged in status to start of turn
    game!.resetToStartOfTurn(playerId);

    // Replay all three darts with the new values in order
    // This ensures each dart is processed with the correct game state
    for (int i = 0; i < 3; i++) {
      final sector = newDartSegments[i];

      // Add to display
      game!.currentTurnDarts[playerId]!.add(sector);

      // Parse and process
      final parsed = _parseSector(sector);
      if (parsed == null || sector == 'Miss') {
        game!.processMiss(playerId);
      } else {
        final number = parsed['number'] as int;
        final multiplier = parsed['multiplier'] as String;
        game!.processDartHit(playerId, number, multiplier);
      }
    }

    // Restore player index
    game!.currentPlayerIndex = currentPlayerIndex;

    // Check if turn should end
    _latchTakeoutIfTurnOver();

    notifyListeners();
  }

  // Get team icon path
  String? getTeamIcon(String teamId) {
    return game?.teamIcons?[teamId];
  }

  // Get team players
  List<String>? getTeamPlayers(String teamId) {
    return game?.teamPlayers?[teamId];
  }

  // Get all active (non-eliminated) players
  List<String> getActivePlayers() {
    if (game == null) return [];
    return game!.playerIds.where((id) => !isEliminated(id)).toList();
  }
}
