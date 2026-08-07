import 'package:flutter/foundation.dart';
import '../models/monster_mash_game.dart';
import '../models/player.dart';
import '../models/saved_game_metadata.dart';
import '../services/save_game_service.dart';
import '../services/game_skip_turn_helper.dart';
import '../services/api/api_client.dart';
import '../utils/dart_sector.dart';

class MonsterMashProvider extends ChangeNotifier {
  MonsterMashGame? _currentGame;
  bool _waitingForTakeout = false;
  ApiClient? _apiClient;

  MonsterMashProvider({ApiClient? apiClient}) : _apiClient = apiClient;

  // Getters
  MonsterMashGame? get currentGame => _currentGame;

  bool get isGameActive => _currentGame?.state == MonsterMashGameState.playing;

  bool get shouldPromptTakeout => _waitingForTakeout;

  bool get hasWinner => _currentGame?.hasWinner() ?? false;

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

  Player? getWinner(List<Player> players) {
    return _currentGame?.getWinner(players);
  }

  List<Player> getWinners(List<Player> players) {
    return _currentGame?.getWinners(players) ?? [];
  }

  int getHealth(String playerId) {
    return _currentGame?.health[playerId] ?? 0;
  }

  double getHealthPercentage(String playerId) {
    return _currentGame?.getHealthPercentage(playerId) ?? 0.0;
  }

  bool isEliminated(String playerId) {
    return _currentGame?.eliminated[playerId] ?? false;
  }

  int? getTargetNumber(String playerId) {
    return _currentGame?.targetNumbers[playerId];
  }

  MonsterType? getMonsterType(String playerId) {
    return _currentGame?.monsterAssignments[playerId];
  }

  String? getMonsterImagePath(String playerId) {
    return _currentGame?.getMonsterImagePath(playerId);
  }

  BonusBuff? getActiveBuff() {
    return _currentGame?.activeBuff;
  }

  /// Set the active buff programmatically. Used by the emulator-only
  /// buff-toggle buttons for visual testing. Pass `null` to clear.
  void setActiveBuff(BonusBuff? buff) {
    if (_currentGame == null) return;
    _currentGame!.activeBuff = buff;
    notifyListeners();
  }

  int getCurrentRound() {
    return _currentGame?.currentRound ?? 1;
  }

  int getRoundLimit() {
    return _currentGame?.roundLimit ?? 10;
  }

  List<int> getDartThrowHealAmount(String playerId) {
    return _currentGame?.dartThrowHealAmount[playerId] ?? [];
  }

  List<int> getDartThrowDamageDealt(String playerId) {
    return _currentGame?.dartThrowDamageDealt[playerId] ?? [];
  }

  List<String?> getDartThrowTargetPlayerId(String playerId) {
    return _currentGame?.dartThrowTargetPlayerId[playerId] ?? [];
  }

  // Start a new game
  void startGame(
    List<Player> players,
    int healthMax,
    bool bonusBuffs,
    bool speedPlay,
    int roundLimit,
  ) {
    if (players.length < 2) {
      debugPrint('Cannot start game with less than 2 players');
      return;
    }

    if (healthMax < 10 || healthMax > 50) {
      debugPrint('Health max must be between 10 and 50');
      return;
    }

    final playerIds = players.map((p) => p.id).toList();
    // A genuinely new game must not inherit the previous game's saved-game
    // slot — otherwise this game's first save overwrites (and destroys) a
    // still-resumable abandoned game. See F2 in the plan notes.
    clearResumedSavedGameId();

    _currentGame = MonsterMashGame.create(
      playerIds: playerIds,
      healthMax: healthMax,
      bonusBuffsEnabled: bonusBuffs,
      speedPlayEnabled: speedPlay,
      roundLimit: roundLimit,
    );
    _waitingForTakeout = false;

    // Save initial turn start state
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

    final displaySector = (parsed == null || sector == 'None' || sector.isEmpty) ? 'Miss' : sector;
    _currentGame!.currentTurnDarts[currentPlayerId]!.add(displaySector);

    if (parsed == null) {
      _currentGame!.processMiss(currentPlayerId);

      final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();
      if (dartsThrown >= 3 || _currentGame!.hasWinner()) {
        _waitingForTakeout = true;
      }

      notifyListeners();
      return;
    }

    final number = parsed['number'] as int;
    final multiplier = parsed['multiplier'] as String;

    _currentGame!.processDartHit(currentPlayerId, number, multiplier);

    final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();
    if (dartsThrown >= 3 || _currentGame!.hasWinner()) {
      _waitingForTakeout = true;
    }

    notifyListeners();
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

  // Update all three dart scores at once
  void updateAllDartScores(String playerId, List<String> newDartSegments) {
    if (_currentGame == null) return;
    if (playerId != _currentGame!.getCurrentPlayerId()) return;
    if (newDartSegments.length != 3) return;

    final currentPlayerIndex = _currentGame!.currentPlayerIndex;

    _currentGame!.currentTurnDarts[playerId] = [];
    _currentGame!.dartsThrown[playerId] = 0;
    _currentGame!.dartThrowHealAmount[playerId] = [];
    _currentGame!.dartThrowDamageDealt[playerId] = [];
    _currentGame!.dartThrowTargetPlayerId[playerId] = [];

    _currentGame!.resetToStartOfTurn(playerId);

    for (int i = 0; i < 3; i++) {
      final sector = newDartSegments[i];

      _currentGame!.currentTurnDarts[playerId]!.add(sector);

      final parsed = _parseSector(sector);
      if (parsed == null || sector == 'Miss') {
        _currentGame!.processMiss(playerId);
      } else {
        final number = parsed['number'] as int;
        final multiplier = parsed['multiplier'] as String;
        _currentGame!.processDartHit(playerId, number, multiplier);
      }
    }

    _currentGame!.currentPlayerIndex = currentPlayerIndex;

    final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();
    if (dartsThrown >= 3 || _currentGame!.hasWinner()) {
      _waitingForTakeout = true;
    }

    notifyListeners();
  }

  // --- Save/Restore ---

  String? _resumedSavedGameId;
  bool _saving = false;
  String? get resumedSavedGameId => _resumedSavedGameId;

  void clearResumedSavedGameId() {
    _resumedSavedGameId = null;
  }

  Future<void> saveGame(List<Player> players, {bool isAutoSave = false}) async {
    debugPrint('[MonsterMashProvider] saveGame called — _saving=$_saving, resumedId=$_resumedSavedGameId');
    if (_currentGame == null || _saving) {
      debugPrint('[MonsterMashProvider] saveGame BLOCKED — game=${_currentGame != null}, _saving=$_saving');
      return;
    }
    _saving = true;
    try {
    final game = _currentGame!;

    // Find leading player (most health)
    String leaderId = game.playerIds.first;
    int maxHealth = 0;
    for (final playerId in game.playerIds) {
      final hp = game.health[playerId] ?? 0;
      if (hp > maxHealth) {
        maxHealth = hp;
        leaderId = playerId;
      }
    }
    final leaderPlayer = players.firstWhere((p) => p.id == leaderId,
        orElse: () => players.first);

    final metadata = SavedGameMetadata.create(
      gameType: 'monster_mash',
      playerNames: players
          .where((p) => game.playerIds.contains(p.id))
          .map((p) => p.name)
          .toList(),
      progressInfo: 'Round ${game.currentRound}',
      gameModeName: 'HP: ${game.healthMax}${game.bonusBuffsEnabled ? ", Buffs" : ""}${game.speedPlayEnabled ? ", Speed (${game.roundLimit})" : ""}',
      leadingPlayerName: leaderPlayer.name,
      leadingPlayerScore: '$maxHealth HP',
      gameState: game.toJson(),
      waitingForTakeout: _waitingForTakeout,
      isAutoSave: isAutoSave,
      existingId: _resumedSavedGameId,
    );

    debugPrint('[MonsterMashProvider] saving with id=${metadata.id}');
    final saved = await SaveGameService(_apiClient).saveGame(metadata);
    if (saved) {
      _resumedSavedGameId = metadata.id;
    }
    debugPrint('[MonsterMashProvider] saveGame completed — saved=$saved, resumedId=$_resumedSavedGameId');
    } finally {
      _saving = false;
    }
  }

  void restoreGame(SavedGameMetadata savedGame) {
    _currentGame = MonsterMashGame.fromJson(
        Map<String, dynamic>.from(savedGame.gameState));
    _waitingForTakeout = savedGame.waitingForTakeout;
    _resumedSavedGameId = savedGame.id;
    notifyListeners();
  }

  // End the current game
  void endGame() {
    if (_currentGame != null) {
      _currentGame!.state = MonsterMashGameState.finished;
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
