import 'package:flutter/foundation.dart';
import '../models/clockwork_quest_game.dart';
import '../models/player.dart';
import '../models/saved_game_metadata.dart';
import '../services/save_game_service.dart';
import '../services/game_skip_turn_helper.dart';
import '../services/api/api_client.dart';

class ClockworkQuestProvider extends ChangeNotifier {
  ClockworkQuestGame? _currentGame;
  bool _waitingForTakeout = false;
  ApiClient? _apiClient;

  ClockworkQuestProvider({ApiClient? apiClient}) : _apiClient = apiClient;

  // Getters
  ClockworkQuestGame? get currentGame => _currentGame;

  bool get isGameActive =>
      _currentGame?.state == ClockworkQuestGameState.playing;

  bool get shouldPromptTakeout => _waitingForTakeout;

  bool get hasWinner => _currentGame?.isGameOver ?? false;

  String? getCurrentPlayerId() => _currentGame?.currentPlayerId;

  int getCurrentPlayerDartsThrown() {
    final playerId = getCurrentPlayerId();
    if (playerId == null || _currentGame == null) return 0;
    return _currentGame!.dartsThrown[playerId] ?? 0;
  }

  List<String> getCurrentTurnDarts(String playerId) =>
      _currentGame?.currentTurnDarts[playerId] ?? [];

  int getPlayerCurrentTarget(String playerId) =>
      _currentGame?.currentTarget[playerId] ?? 1;

  int getPlayerLapsCompleted(String playerId) =>
      _currentGame?.lapsCompleted[playerId] ?? 0;

  ClockworkInventor? getInventorType(String playerId) =>
      _currentGame?.inventorAssignments[playerId];

  String? getInventorImagePath(String playerId) {
    final inventor = getInventorType(playerId);
    if (inventor == null) return null;
    final inventorName = inventor.toString().split('.').last;
    final capitalizedName =
        inventorName[0].toUpperCase() + inventorName.substring(1);
    return 'assets/games/clockwork_quest/images/characters/$capitalizedName.png';
  }

  List<bool> getDartThrowHitTarget(String playerId) =>
      _currentGame?.dartThrowHitTarget[playerId] ?? [];

  List<int> getDartThrowScoreValue(String playerId) =>
      _currentGame?.dartThrowScoreValue[playerId] ?? [];

  List<int> getDartThrowMultiplier(String playerId) =>
      _currentGame?.dartThrowMultiplier[playerId] ?? [];

  List<int> getDartThrowTargetNumber(String playerId) =>
      _currentGame?.dartThrowTargetNumber[playerId] ?? [];

  List<bool> getDartThrowAdvanced(String playerId) =>
      _currentGame?.dartThrowAdvanced[playerId] ?? [];

  List<bool> getDartThrowCompletedLap(String playerId) =>
      _currentGame?.dartThrowCompletedLap[playerId] ?? [];

  List<int> getPlayerCompletedTargets(String playerId) =>
      _currentGame?.completedTargets[playerId] ?? [];

  // Start a new game
  void startGame(
    List<Player> players,
    bool includeBullseye,
    bool speedMode,
    int numberOfLaps,
  ) {
    if (players.length < 2) {
      debugPrint('Cannot start game with less than 2 players');
      return;
    }

    if (players.length > 8) {
      debugPrint('Cannot start game with more than 8 players');
      return;
    }

    final playerIds = players.map((p) => p.id).toList();

    // Assign inventors to players
    final availableInventors = List<ClockworkInventor>.from(
        ClockworkInventor.values.take(players.length));
    availableInventors.shuffle();

    final inventorAssignments = <String, ClockworkInventor>{};
    for (int i = 0; i < playerIds.length; i++) {
      inventorAssignments[playerIds[i]] = availableInventors[i];
    }

    _currentGame = ClockworkQuestGame(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startedAt: DateTime.now(),
      maxDartsPerTurn: 3,
      includeBullseye: includeBullseye,
      speedMode: speedMode,
      numberOfLaps: numberOfLaps,
      playerIds: playerIds,
      inventorAssignments: inventorAssignments,
      state: ClockworkQuestGameState.playing,
    );

    _waitingForTakeout = false;
    _saveInitialTurnStartState();
    notifyListeners();
  }

  // Process a dart throw from dartboard event
  void processDartThrow(String sector) {
    if (_currentGame == null || !isGameActive) return;
    if (_waitingForTakeout) return;

    final parsed = _parseSector(sector);
    final currentPlayerId = _currentGame!.currentPlayerId;
    _currentGame!.currentTurnDarts[currentPlayerId] ??= [];

    if (parsed == null) {
      // Complete miss (None, empty, or unparseable)
      _currentGame!.currentTurnDarts[currentPlayerId]!.add('Miss');
      _processMiss(currentPlayerId);
      _checkTakeoutCondition();
      notifyListeners();
      return;
    }

    final hitNumber = parsed['number'] as int;
    final multiplier = parsed['multiplier'] as int;

    // Build display string for current turn darts
    String displayStr;
    if (hitNumber == 25) {
      displayStr = multiplier == 2 ? 'DBull' : 'Bull';
    } else {
      if (multiplier == 1) {
        displayStr = 'S$hitNumber';
      } else if (multiplier == 2) {
        displayStr = 'D$hitNumber';
      } else {
        displayStr = 'T$hitNumber';
      }
    }
    _currentGame!.currentTurnDarts[currentPlayerId]!.add(displayStr);

    // Process the dart throw
    _processHit(currentPlayerId, hitNumber, multiplier);
    _checkTakeoutCondition();
    notifyListeners();
  }

  void _processMiss(String playerId) {
    // Record dart tracking data for miss
    _currentGame!.dartThrowHitTarget[playerId]!.add(false);
    _currentGame!.dartThrowScoreValue[playerId]!.add(0);
    _currentGame!.dartThrowMultiplier[playerId]!.add(0);
    _currentGame!.dartThrowTargetNumber[playerId]!
        .add(_currentGame!.currentTarget[playerId]!);
    _currentGame!.dartThrowAdvanced[playerId]!.add(false);
    _currentGame!.dartThrowCompletedLap[playerId]!.add(false);

    // Increment darts thrown
    _currentGame!.dartsThrown[playerId] =
        (_currentGame!.dartsThrown[playerId] ?? 0) + 1;
    _currentGame!.totalDartsThrown[playerId] =
        (_currentGame!.totalDartsThrown[playerId] ?? 0) + 1;
  }

  void _processHit(String playerId, int hitNumber, int multiplier) {
    final currentTarget = _currentGame!.currentTarget[playerId]!;
    bool hitTarget = false;
    bool advanced = false;
    bool completedLap = false;

    if (_currentGame!.speedMode) {
      // Speed mode: any uncompleted gear number counts, no ordering required
      final completed = _currentGame!.completedTargets[playerId]!;
      final maxTarget = _currentGame!.maxTarget;

      int? gearNumber;
      if (hitNumber == 25 && _currentGame!.includeBullseye) {
        gearNumber = 21;
      } else if (hitNumber >= 1 && hitNumber <= 20) {
        gearNumber = hitNumber;
      }

      if (gearNumber != null && !completed.contains(gearNumber)) {
        hitTarget = true;
        advanced = true;
      }

      // Record dart tracking data
      _currentGame!.dartThrowHitTarget[playerId]!.add(hitTarget);
      _currentGame!.dartThrowScoreValue[playerId]!.add(hitNumber);
      _currentGame!.dartThrowMultiplier[playerId]!.add(multiplier);
      _currentGame!.dartThrowTargetNumber[playerId]!.add(gearNumber ?? hitNumber);
      _currentGame!.dartThrowAdvanced[playerId]!.add(advanced);

      if (advanced) {
        completed.add(gearNumber!);
        _currentGame!.currentTarget[playerId] = completed.length + 1;

        if (completed.length >= maxTarget) {
          _currentGame!.completedTargets[playerId] = [];
          _currentGame!.currentTarget[playerId] = 1;
          _currentGame!.lapsCompleted[playerId] =
              (_currentGame!.lapsCompleted[playerId] ?? 0) + 1;
          completedLap = true;

          if (_currentGame!.lapsCompleted[playerId]! >=
              _currentGame!.numberOfLaps) {
            _currentGame!.winnerId = playerId;
            _currentGame!.state = ClockworkQuestGameState.finished;
          }
        }
      }
    } else {
      // Normal mode: ordered sequential targets
      if (currentTarget == 21 && hitNumber == 25) {
        hitTarget = true;
        advanced = true;
      } else if (hitNumber == currentTarget) {
        hitTarget = true;
        advanced = true;
      }

      // Record dart tracking data
      _currentGame!.dartThrowHitTarget[playerId]!.add(hitTarget);
      _currentGame!.dartThrowScoreValue[playerId]!.add(hitNumber);
      _currentGame!.dartThrowMultiplier[playerId]!.add(multiplier);
      _currentGame!.dartThrowTargetNumber[playerId]!.add(currentTarget);
      _currentGame!.dartThrowAdvanced[playerId]!.add(advanced);

      if (advanced) {
        final maxTarget = _currentGame!.maxTarget;
        if (currentTarget >= maxTarget) {
          _currentGame!.currentTarget[playerId] = 1;
          _currentGame!.lapsCompleted[playerId] =
              (_currentGame!.lapsCompleted[playerId] ?? 0) + 1;
          completedLap = true;

          if (_currentGame!.lapsCompleted[playerId]! >=
              _currentGame!.numberOfLaps) {
            _currentGame!.winnerId = playerId;
            _currentGame!.state = ClockworkQuestGameState.finished;
          }
        } else {
          _currentGame!.currentTarget[playerId] = currentTarget + 1;
        }
      }
    }

    _currentGame!.dartThrowCompletedLap[playerId]!.add(completedLap);

    // Increment darts thrown
    _currentGame!.dartsThrown[playerId] =
        (_currentGame!.dartsThrown[playerId] ?? 0) + 1;
    _currentGame!.totalDartsThrown[playerId] =
        (_currentGame!.totalDartsThrown[playerId] ?? 0) + 1;
  }

  void _checkTakeoutCondition() {
    if (_currentGame == null || !isGameActive) return;
    final currentPlayerId = _currentGame!.currentPlayerId;
    final dartsThrown = _currentGame!.dartsThrown[currentPlayerId] ?? 0;

    if (dartsThrown >= _currentGame!.maxDartsPerTurn) {
      _waitingForTakeout = true;
    }
  }

  // Confirm darts removed (called when RemoveDartsModal is confirmed)
  void confirmDartsRemoved() {
    if (_currentGame == null) return;
    _waitingForTakeout = false;
    advanceTurn();
  }

  // Advance to next turn
  void advanceTurn() {
    if (_currentGame == null) return;

    final currentPlayerId = _currentGame!.currentPlayerId;

    // Reset per-turn tracking
    _currentGame!.dartsThrown[currentPlayerId] = 0;
    _currentGame!.currentTurnDarts[currentPlayerId] = [];
    _currentGame!.dartThrowHitTarget[currentPlayerId] = [];
    _currentGame!.dartThrowScoreValue[currentPlayerId] = [];
    _currentGame!.dartThrowMultiplier[currentPlayerId] = [];
    _currentGame!.dartThrowTargetNumber[currentPlayerId] = [];
    _currentGame!.dartThrowAdvanced[currentPlayerId] = [];
    _currentGame!.dartThrowCompletedLap[currentPlayerId] = [];

    // Increment total turns
    _currentGame!.totalTurns[currentPlayerId] =
        (_currentGame!.totalTurns[currentPlayerId] ?? 0) + 1;

    // Move to next player
    _currentGame!.currentPlayerIndex =
        (_currentGame!.currentPlayerIndex + 1) %
            _currentGame!.playerIds.length;

    // Save turn start state for the new player
    _saveInitialTurnStartState();

    _waitingForTakeout = false;
    notifyListeners();
  }

  // Skip current turn
  void skipTurn() {
    if (_currentGame == null || !isGameActive) return;

    if (!GameSkipTurnHelper.canSkipTurn(
      gameActive: isGameActive,
      waitingForTakeout: _waitingForTakeout,
      currentDartCount: getCurrentPlayerDartsThrown(),
      maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
    )) {
      return;
    }

    final currentPlayerId = _currentGame!.currentPlayerId;
    GameSkipTurnHelper.skipRemainingDarts(
      currentDartCount: getCurrentPlayerDartsThrown(),
      maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
      addVisualMarker: (marker) {
        _currentGame!.currentTurnDarts[currentPlayerId]!.add(marker);
      },
    );

    advanceTurn();
  }

  // Edit score (restore to turn start, then apply new throws)
  void editScore(List<Map<String, dynamic>> newThrows) {
    if (_currentGame == null) return;

    // Restore to turn start state
    _restoreToTurnStart();

    // Apply new throws
    for (final throwData in newThrows) {
      final sector = throwData['sector'] as String;
      processDartThrow(sector);
    }
  }

  void _saveInitialTurnStartState() {
    if (_currentGame == null) return;

    // Save current state as turn start state
    _currentGame!.turnStartCurrentTarget =
        Map.from(_currentGame!.currentTarget);
    _currentGame!.turnStartLapsCompleted =
        Map.from(_currentGame!.lapsCompleted);
    _currentGame!.turnStartState = _currentGame!.state;
    _currentGame!.turnStartWinnerId = _currentGame!.winnerId;
    _currentGame!.turnStartCompletedTargets =
        _currentGame!.completedTargets.map((k, v) => MapEntry(k, List.from(v)));
  }

  void _restoreToTurnStart() {
    if (_currentGame == null) return;

    final currentPlayerId = _currentGame!.currentPlayerId;

    // Restore game state
    _currentGame!.currentTarget = Map.from(_currentGame!.turnStartCurrentTarget);
    _currentGame!.lapsCompleted =
        Map.from(_currentGame!.turnStartLapsCompleted);
    _currentGame!.state = _currentGame!.turnStartState;
    _currentGame!.winnerId = _currentGame!.turnStartWinnerId;
    _currentGame!.completedTargets =
        _currentGame!.turnStartCompletedTargets.map((k, v) => MapEntry(k, List<int>.from(v)));

    // Clear current turn data
    _currentGame!.dartsThrown[currentPlayerId] = 0;
    _currentGame!.currentTurnDarts[currentPlayerId] = [];
    _currentGame!.dartThrowHitTarget[currentPlayerId] = [];
    _currentGame!.dartThrowScoreValue[currentPlayerId] = [];
    _currentGame!.dartThrowMultiplier[currentPlayerId] = [];
    _currentGame!.dartThrowTargetNumber[currentPlayerId] = [];
    _currentGame!.dartThrowAdvanced[currentPlayerId] = [];
    _currentGame!.dartThrowCompletedLap[currentPlayerId] = [];

    _waitingForTakeout = false;
  }

  // Parse sector string from dartboard
  Map<String, dynamic>? _parseSector(String sector) {
    if (sector.isEmpty ||
        sector == 'None' ||
        sector == 'Miss' ||
        sector == 'none') {
      return null;
    }

    // Handle bullseye
    if (sector == 'Bull' || sector == 'bull' || sector == 'SBull') {
      return {'number': 25, 'multiplier': 1};
    }
    if (sector == 'DBull' || sector == 'dbull') {
      return {'number': 25, 'multiplier': 2};
    }

    // Parse standard format: S20, s20 (inner single), D20, T20
    final match = RegExp(r'^([SDTsdt])(\d+)$').firstMatch(sector);
    if (match == null) return null;

    final multiplierStr = match.group(1)!.toUpperCase();
    final numberStr = match.group(2);

    int multiplier;
    if (multiplierStr == 'S') {
      multiplier = 1;
    } else if (multiplierStr == 'D') {
      multiplier = 2;
    } else {
      multiplier = 3;
    }

    final number = int.tryParse(numberStr!);
    if (number == null) return null;

    return {'number': number, 'multiplier': multiplier};
  }

  // Save/Resume functionality
  String? _resumedSavedGameId;
  String? get resumedSavedGameId => _resumedSavedGameId;

  void clearResumedSavedGameId() {
    _resumedSavedGameId = null;
    notifyListeners();
  }

  Future<void> saveGame(List<Player> players) async {
    if (_currentGame == null) return;
    final game = _currentGame!;

    // Find leading player (furthest along in laps)
    String leaderId = game.playerIds.first;
    int maxProgress = 0;
    for (final playerId in game.playerIds) {
      final laps = game.lapsCompleted[playerId] ?? 0;
      final target = game.currentTarget[playerId] ?? 1;
      final progress = (laps * game.maxTarget) + target;
      if (progress > maxProgress) {
        maxProgress = progress;
        leaderId = playerId;
      }
    }

    final leaderPlayer = players.firstWhere((p) => p.id == leaderId,
        orElse: () => players.first);
    final leaderLaps = game.lapsCompleted[leaderId] ?? 0;
    final leaderTarget = game.currentTarget[leaderId] ?? 1;

    final metadata = SavedGameMetadata.create(
      gameType: 'clockwork_quest',
      playerNames: players
          .where((p) => game.playerIds.contains(p.id))
          .map((p) => p.name)
          .toList(),
      progressInfo:
          'Lap ${leaderLaps + 1}/${game.numberOfLaps}, Target $leaderTarget',
      gameModeName:
          '${game.includeBullseye ? "With Bullseye" : "No Bullseye"}${game.speedMode ? ", Speed" : ""}${game.numberOfLaps > 1 ? ", ${game.numberOfLaps} laps" : ""}',
      leadingPlayerName: leaderPlayer.name,
      leadingPlayerScore: 'Lap ${leaderLaps + 1}, #$leaderTarget',
      gameState: game.toJson(),
      waitingForTakeout: _waitingForTakeout,
      existingId: _resumedSavedGameId,
    );

    await SaveGameService(_apiClient).saveGame(metadata);
    _resumedSavedGameId = metadata.id;
  }

  void restoreGame(SavedGameMetadata savedGame) {
    _currentGame = ClockworkQuestGame.fromJson(
        Map<String, dynamic>.from(savedGame.gameState));
    _waitingForTakeout = savedGame.waitingForTakeout;
    _resumedSavedGameId = savedGame.id;
    notifyListeners();
  }

  // End the current game
  void endGame() {
    if (_currentGame != null) {
      _currentGame!.state = ClockworkQuestGameState.finished;
    }
    notifyListeners();
  }

  // Clear the current game
  void clearGame() {
    _currentGame = null;
    _waitingForTakeout = false;
    _resumedSavedGameId = null;
    notifyListeners();
  }
}
