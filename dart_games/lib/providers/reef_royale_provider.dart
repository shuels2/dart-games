import 'package:flutter/foundation.dart';
import '../models/reef_royale_game.dart';
import '../models/player.dart';
import '../models/saved_game_metadata.dart';
import '../services/save_game_service.dart';
import '../services/game_skip_turn_helper.dart';
import '../services/api/api_client.dart';

class ReefRoyaleProvider extends ChangeNotifier {
  ReefRoyaleGame? _currentGame;
  bool _waitingForTakeout = false;
  ApiClient? _apiClient;

  ReefRoyaleProvider({ApiClient? apiClient}) : _apiClient = apiClient;

  // Getters
  ReefRoyaleGame? get currentGame => _currentGame;

  bool get isGameActive =>
      _currentGame?.state == ReefRoyaleGameState.playing;

  bool get shouldPromptTakeout => _waitingForTakeout;

  bool get hasWinner => _currentGame?.hasWinner() ?? false;

  String? getCurrentPlayerId() => _currentGame?.getCurrentPlayerId();

  int getCurrentPlayerDartsThrown() =>
      _currentGame?.getCurrentPlayerDartsThrown() ?? 0;

  List<String> getCurrentTurnDarts(String playerId) =>
      _currentGame?.getCurrentTurnDarts(playerId) ?? [];

  int getPlayerPearls(String playerId) =>
      _currentGame?.getPlayerPearls(playerId) ?? 0;

  int getPlayerClaimedCount(String playerId) =>
      _currentGame?.getPlayerClaimedCount(playerId) ?? 0;

  int getPlayerMarks(String playerId, int target) =>
      _currentGame?.getPlayerMarks(playerId, target) ?? 0;

  bool hasPlayerClaimed(String playerId, int target) =>
      _currentGame?.hasPlayerClaimed(playerId, target) ?? false;

  bool isTargetLocked(int target) =>
      _currentGame?.isTargetLocked(target) ?? false;

  ReefBuff? getActiveBuff() => _currentGame?.activeBuff;

  /// Set the active buff programmatically (for testing)
  void setActiveBuff(ReefBuff? buff) {
    if (_currentGame == null) return;
    _currentGame!.activeBuff = buff;
    notifyListeners();
  }

  int getCurrentRound() => _currentGame?.currentRound ?? 1;

  int getRoundLimit() => _currentGame?.roundLimit ?? 10;

  ReefRoyaleGameMode? getGameMode() => _currentGame?.gameMode;

  List<String> getRankedPlayerIds() =>
      _currentGame?.getRankedPlayerIds() ?? [];

  List<int> getDartThrowMarksAdded(String playerId) =>
      _currentGame?.dartThrowMarksAdded[playerId] ?? [];

  List<int> getDartThrowPearlsScored(String playerId) =>
      _currentGame?.dartThrowPearlsScored[playerId] ?? [];

  List<bool> getDartThrowClaimedCoral(String playerId) =>
      _currentGame?.dartThrowClaimedCoral[playerId] ?? [];

  List<bool> getDartThrowLockedReef(String playerId) =>
      _currentGame?.dartThrowLockedReef[playerId] ?? [];

  List<int?> getDartThrowTargetNumber(String playerId) =>
      _currentGame?.dartThrowTargetNumber[playerId] ?? [];

  List<bool> getDartThrowIsNeighbor(String playerId) =>
      _currentGame?.dartThrowIsNeighbor[playerId] ?? [];

  List<String?> getDartThrowPearlRecipientId(String playerId) =>
      _currentGame?.dartThrowPearlRecipientId[playerId] ?? [];

  List<int> getDartThrowTargetCount(String playerId) =>
      _currentGame?.dartThrowTargetCount[playerId] ?? [];

  SeaCreature? getCreatureType(String playerId) =>
      _currentGame?.creatureAssignments[playerId];

  String? getCreatureImagePath(String playerId) =>
      _currentGame?.getCreatureImagePath(playerId);

  // Start a new game
  void startGame(
    List<Player> players,
    ReefRoyaleGameMode gameMode,
    bool easyClaim,
    bool neighborNumbers,
    bool randomReefs,
    bool bonusBuffs,
    bool showHints,
    bool speedPlay,
    int roundLimit,
  ) {
    if (players.length < 2) {
      debugPrint('Cannot start game with less than 2 players');
      return;
    }

    final playerIds = players.map((p) => p.id).toList();
    _currentGame = ReefRoyaleGame.create(
      playerIds: playerIds,
      gameMode: gameMode,
      easyClaim: easyClaim,
      neighborNumbers: neighborNumbers,
      randomReefs: randomReefs,
      bonusBuffsEnabled: bonusBuffs,
      showHints: showHints,
      speedPlayEnabled: speedPlay,
      roundLimit: roundLimit,
    );
    _waitingForTakeout = false;
    _currentGame!.saveInitialTurnStartState();
    notifyListeners();
  }

  // Process a dart throw from dartboard event
  void processDartThrow(String sector) {
    if (_currentGame == null || !isGameActive) return;
    if (_waitingForTakeout) return;

    final parsed = _parseSector(sector);
    final currentPlayerId = _currentGame!.getCurrentPlayerId();
    _currentGame!.currentTurnDarts[currentPlayerId] ??= [];

    if (parsed == null) {
      // Complete miss (None, empty, or unparseable)
      _currentGame!.currentTurnDarts[currentPlayerId]!.add('Miss');
      _currentGame!.processMiss(currentPlayerId);
      _checkTakeoutCondition();
      notifyListeners();
      return;
    }

    final hitNumber = parsed['number'] as int;
    final multiplier = parsed['multiplier'] as String;

    // Resolve all targets (neighbor may match multiple)
    final resolvedTargets = _currentGame!.resolveAllTargets(hitNumber);

    if (resolvedTargets.isEmpty) {
      // Non-target number hit — display the sector info
      _currentGame!.currentTurnDarts[currentPlayerId]!.add(sector);
      _currentGame!.processMiss(currentPlayerId);
      _checkTakeoutCondition();
      notifyListeners();
      return;
    }

    // Add display text
    _currentGame!.currentTurnDarts[currentPlayerId]!.add(sector);

    // Process all resolved targets in one call (aggregates tracking data per dart)
    _currentGame!.processDart(
      currentPlayerId,
      hitNumber,
      multiplier,
      resolvedTargets: resolvedTargets,
    );

    _checkTakeoutCondition();
    notifyListeners();
  }

  void _checkTakeoutCondition() {
    final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();
    if (dartsThrown >= 3 || _currentGame!.hasWinner()) {
      _waitingForTakeout = true;
    }
  }

  // Parse dartboard sector string
  Map<String, dynamic>? _parseSector(String sector) {
    if (sector == 'Bull') {
      return {'number': 50, 'multiplier': 'single'};
    }
    if (sector == '25') {
      return {'number': 25, 'multiplier': 'single'};
    }
    if (sector == 'None' || sector.isEmpty) {
      return null;
    }

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

    if (!GameSkipTurnHelper.canSkipTurn(
      gameActive: isGameActive,
      waitingForTakeout: _waitingForTakeout,
      currentDartCount: dartsThrown,
      maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
    )) {
      return;
    }

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

    if (_currentGame!.hasWinner()) {
      _waitingForTakeout = false;
      notifyListeners();
      return;
    }

    if (!isGameActive) return;

    _currentGame!.advanceToNextPlayer();
    _waitingForTakeout = false;
    notifyListeners();
  }

  // Update a specific dart score and recalculate turn
  void updateDartScore(
      String playerId, int dartIndex, String newSector) {
    if (_currentGame == null) return;
    if (playerId != _currentGame!.getCurrentPlayerId()) return;

    final currentTurnDarts =
        _currentGame!.currentTurnDarts[playerId] ?? [];
    if (dartIndex >= currentTurnDarts.length) return;

    final currentPlayerIndex = _currentGame!.currentPlayerIndex;

    // Reset dart tracking
    _currentGame!.currentTurnDarts[playerId] = [];
    _currentGame!.dartsThrown[playerId] = 0;
    _currentGame!.dartThrowMarksAdded[playerId] = [];
    _currentGame!.dartThrowPearlsScored[playerId] = [];
    _currentGame!.dartThrowClaimedCoral[playerId] = [];
    _currentGame!.dartThrowLockedReef[playerId] = [];
    _currentGame!.dartThrowTargetNumber[playerId] = [];
    _currentGame!.dartThrowIsNeighbor[playerId] = [];
    _currentGame!.dartThrowPearlRecipientId[playerId] = [];
    _currentGame!.dartThrowTargetCount[playerId] = [];

    _currentGame!.resetToStartOfTurn(playerId);

    // Replay all darts with the updated one
    for (int i = 0; i < currentTurnDarts.length; i++) {
      final sector =
          i == dartIndex ? newSector : currentTurnDarts[i];
      _replayDart(playerId, sector);
    }

    _currentGame!.currentPlayerIndex = currentPlayerIndex;
    _checkTakeoutCondition();
    notifyListeners();
  }

  // Update all three dart scores at once
  void updateAllDartScores(
      String playerId, List<String> newDartSegments) {
    if (_currentGame == null) return;
    if (playerId != _currentGame!.getCurrentPlayerId()) return;
    if (newDartSegments.length != 3) return;

    final currentPlayerIndex = _currentGame!.currentPlayerIndex;

    // Reset dart tracking
    _currentGame!.currentTurnDarts[playerId] = [];
    _currentGame!.dartsThrown[playerId] = 0;
    _currentGame!.dartThrowMarksAdded[playerId] = [];
    _currentGame!.dartThrowPearlsScored[playerId] = [];
    _currentGame!.dartThrowClaimedCoral[playerId] = [];
    _currentGame!.dartThrowLockedReef[playerId] = [];
    _currentGame!.dartThrowTargetNumber[playerId] = [];
    _currentGame!.dartThrowIsNeighbor[playerId] = [];
    _currentGame!.dartThrowPearlRecipientId[playerId] = [];
    _currentGame!.dartThrowTargetCount[playerId] = [];

    _currentGame!.resetToStartOfTurn(playerId);

    for (int i = 0; i < 3; i++) {
      _replayDart(playerId, newDartSegments[i]);
    }

    _currentGame!.currentPlayerIndex = currentPlayerIndex;
    _checkTakeoutCondition();
    notifyListeners();
  }

  // Replay a single dart (used by edit score)
  void _replayDart(String playerId, String sector) {
    _currentGame!.currentTurnDarts[playerId]!.add(sector);

    final parsed = _parseSector(sector);
    if (parsed == null || sector == 'Miss') {
      _currentGame!.processMiss(playerId);
      return;
    }

    final hitNumber = parsed['number'] as int;
    final multiplier = parsed['multiplier'] as String;
    final resolvedTargets = _currentGame!.resolveAllTargets(hitNumber);

    if (resolvedTargets.isEmpty) {
      _currentGame!.processMiss(playerId);
      return;
    }

    // Process all resolved targets in one call (aggregates tracking data per dart)
    _currentGame!.processDart(
      playerId,
      hitNumber,
      multiplier,
      resolvedTargets: resolvedTargets,
    );
  }

  // --- Save/Restore ---

  String? _resumedSavedGameId;
  bool _saving = false;
  String? get resumedSavedGameId => _resumedSavedGameId;

  void clearResumedSavedGameId() {
    _resumedSavedGameId = null;
  }

  Future<void> saveGame(List<Player> players) async {
    debugPrint('[ReefRoyaleProvider] saveGame called — _saving=$_saving, resumedId=$_resumedSavedGameId');
    if (_currentGame == null || _saving) {
      debugPrint('[ReefRoyaleProvider] saveGame BLOCKED — game=${_currentGame != null}, _saving=$_saving');
      return;
    }
    _saving = true;
    try {
    final game = _currentGame!;

    // Find leading player (most corals, then most/fewest pearls based on mode)
    final ranked = game.getRankedPlayerIds();
    final leaderId = ranked.isNotEmpty ? ranked.first : game.playerIds.first;
    final leaderPlayer = players.firstWhere((p) => p.id == leaderId,
        orElse: () => players.first);
    final leaderCorals = game.getPlayerClaimedCount(leaderId);

    final metadata = SavedGameMetadata.create(
      gameType: 'reef_royale',
      playerNames: players
          .where((p) => game.playerIds.contains(p.id))
          .map((p) => p.name)
          .toList(),
      progressInfo: 'Round ${game.currentRound}',
      gameModeName: '${game.gameMode == ReefRoyaleGameMode.cursedTide ? "Cursed Tide" : "Standard"}${game.easyClaim ? ", Easy" : ""}${game.neighborNumbers ? ", Neighbors" : ""}${game.randomReefs ? ", Random" : ""}${game.bonusBuffsEnabled ? ", Buffs" : ""}${game.speedPlayEnabled ? ", Speed (${game.roundLimit})" : ""}',
      leadingPlayerName: leaderPlayer.name,
      leadingPlayerScore: '$leaderCorals/7 corals',
      gameState: game.toJson(),
      waitingForTakeout: _waitingForTakeout,
      existingId: _resumedSavedGameId,
    );

    debugPrint('[ReefRoyaleProvider] saving with id=${metadata.id}');
    await SaveGameService(_apiClient).saveGame(metadata);
    _resumedSavedGameId = metadata.id;
    debugPrint('[ReefRoyaleProvider] saveGame completed — resumedId=$_resumedSavedGameId');
    } finally {
      _saving = false;
    }
  }

  void restoreGame(SavedGameMetadata savedGame) {
    _currentGame = ReefRoyaleGame.fromJson(
        Map<String, dynamic>.from(savedGame.gameState));
    _waitingForTakeout = savedGame.waitingForTakeout;
    _resumedSavedGameId = savedGame.id;
    notifyListeners();
  }

  // End the current game
  void endGame() {
    if (_currentGame != null) {
      _currentGame!.state = ReefRoyaleGameState.finished;
    }
    notifyListeners();
  }

  // Clear the current game
  void clearGame() {
    _currentGame = null;
    _waitingForTakeout = false;
    notifyListeners();
  }
}
