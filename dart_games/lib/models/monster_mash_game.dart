import 'dart:math';
import 'package:uuid/uuid.dart';
import 'player.dart';

enum MonsterMashGameState { setup, playing, finished }

enum MonsterType { dracula, frankenstein, mummy, wolfMan, invisibleMan, gillMan, mrHyde, phantom }

enum BonusBuff { bloodMoon, ancientBandages, shadowWalk, laboratorySpark }

class MonsterMashGame {
  final String id;
  final DateTime startedAt;
  final int maxDartsPerTurn;
  final int healthMax;
  final bool bonusBuffsEnabled;
  final bool speedPlayEnabled;
  final int roundLimit;

  // Player management
  final List<String> playerIds;
  final Map<String, int> targetNumbers;
  final Map<String, MonsterType> monsterAssignments;

  // Runtime state
  MonsterMashGameState state;
  int currentPlayerIndex;
  Map<String, int> health;
  Map<String, bool> eliminated;
  int currentRound;
  int turnsCompletedThisRound;
  BonusBuff? activeBuff;

  // Per-turn tracking
  Map<String, int> dartsThrown;
  Map<String, List<String>> currentTurnDarts;

  // Stats tracking
  Map<String, int> totalDartsThrown;
  Map<String, int> totalTurns;
  Map<String, int> totalDamageDealt;

  // Dart throw tracking arrays for UI coloring
  Map<String, List<int>> dartThrowHealAmount;
  Map<String, List<int>> dartThrowDamageDealt;
  Map<String, List<String?>> dartThrowTargetPlayerId;

  // Winner(s)
  String? winnerId;
  List<String>? winnerIds;

  // Turn start state snapshots for edit score
  Map<String, int> turnStartHealth;
  Map<String, bool> turnStartEliminated;
  MonsterMashGameState turnStartState;
  String? turnStartWinnerId;
  List<String>? turnStartWinnerIds;
  Map<String, int> turnStartTotalDamageDealt;

  MonsterMashGame({
    required this.id,
    required this.startedAt,
    this.maxDartsPerTurn = 3,
    required this.healthMax,
    required this.bonusBuffsEnabled,
    required this.speedPlayEnabled,
    required this.roundLimit,
    required this.playerIds,
    required this.targetNumbers,
    required this.monsterAssignments,
    this.state = MonsterMashGameState.setup,
    this.currentPlayerIndex = 0,
    Map<String, int>? health,
    Map<String, bool>? eliminated,
    this.currentRound = 1,
    this.turnsCompletedThisRound = 0,
    this.activeBuff,
    Map<String, int>? dartsThrown,
    Map<String, List<String>>? currentTurnDarts,
    Map<String, int>? totalDartsThrown,
    Map<String, int>? totalTurns,
    Map<String, int>? totalDamageDealt,
    Map<String, List<int>>? dartThrowHealAmount,
    Map<String, List<int>>? dartThrowDamageDealt,
    Map<String, List<String?>>? dartThrowTargetPlayerId,
    this.winnerId,
    this.winnerIds,
    Map<String, int>? turnStartHealth,
    Map<String, bool>? turnStartEliminated,
    MonsterMashGameState? turnStartState,
    this.turnStartWinnerId,
    this.turnStartWinnerIds,
    Map<String, int>? turnStartTotalDamageDealt,
  })  : health = health ?? {},
        eliminated = eliminated ?? {},
        dartsThrown = dartsThrown ?? {},
        currentTurnDarts = currentTurnDarts ?? {},
        totalDartsThrown = totalDartsThrown ?? {},
        totalTurns = totalTurns ?? {},
        totalDamageDealt = totalDamageDealt ?? {},
        dartThrowHealAmount = dartThrowHealAmount ?? {},
        dartThrowDamageDealt = dartThrowDamageDealt ?? {},
        dartThrowTargetPlayerId = dartThrowTargetPlayerId ?? {},
        turnStartHealth = turnStartHealth ?? {},
        turnStartEliminated = turnStartEliminated ?? {},
        turnStartState = turnStartState ?? MonsterMashGameState.setup,
        turnStartTotalDamageDealt = turnStartTotalDamageDealt ?? {} {
    // Initialize per-player state
    for (var playerId in playerIds) {
      this.health[playerId] ??= healthMax;
      this.eliminated[playerId] ??= false;
      this.dartsThrown[playerId] ??= 0;
      this.currentTurnDarts[playerId] ??= [];
      this.totalDartsThrown[playerId] ??= 0;
      this.totalTurns[playerId] ??= 0;
      this.totalDamageDealt[playerId] ??= 0;
      this.dartThrowHealAmount[playerId] ??= [];
      this.dartThrowDamageDealt[playerId] ??= [];
      this.dartThrowTargetPlayerId[playerId] ??= [];
    }
  }

  factory MonsterMashGame.create({
    required List<String> playerIds,
    required int healthMax,
    required bool bonusBuffsEnabled,
    required bool speedPlayEnabled,
    required int roundLimit,
  }) {
    final random = Random();

    // Randomly assign monsters (unique per player)
    final availableMonsters = List<MonsterType>.from(MonsterType.values)..shuffle(random);
    final monsterAssignments = <String, MonsterType>{};
    for (int i = 0; i < playerIds.length; i++) {
      monsterAssignments[playerIds[i]] = availableMonsters[i];
    }

    // Randomly assign target numbers (1-20, unique per player)
    final availableNumbers = List.generate(20, (i) => i + 1)..shuffle(random);
    final targetNumbers = <String, int>{};
    for (int i = 0; i < playerIds.length; i++) {
      targetNumbers[playerIds[i]] = availableNumbers[i];
    }

    // Initialize health to max for all players
    final health = <String, int>{};
    for (final playerId in playerIds) {
      health[playerId] = healthMax;
    }

    return MonsterMashGame(
      id: const Uuid().v4(),
      startedAt: DateTime.now(),
      maxDartsPerTurn: 3,
      healthMax: healthMax,
      bonusBuffsEnabled: bonusBuffsEnabled,
      speedPlayEnabled: speedPlayEnabled,
      roundLimit: roundLimit,
      playerIds: playerIds,
      targetNumbers: targetNumbers,
      monsterAssignments: monsterAssignments,
      health: health,
      state: MonsterMashGameState.playing,
      currentPlayerIndex: 0,
      currentRound: 1,
      turnsCompletedThisRound: 0,
    );
  }

  // Get current player ID
  String getCurrentPlayerId() {
    return playerIds[currentPlayerIndex];
  }

  // Get current player object
  Player getCurrentPlayer(List<Player> players) {
    final currentPlayerId = getCurrentPlayerId();
    return players.firstWhere((p) => p.id == currentPlayerId);
  }

  // Increment turn counter if first dart thrown
  void _incrementTurnIfFirst(String playerId) {
    if (dartsThrown[playerId] == 1) {
      totalTurns[playerId] = (totalTurns[playerId] ?? 0) + 1;
    }
  }

  // Process a miss (dart that doesn't hit any relevant number)
  void processMiss(String playerId) {
    if (state != MonsterMashGameState.playing) return;
    if (playerId != playerIds[currentPlayerIndex]) return;
    if (dartsThrown[playerId]! >= maxDartsPerTurn) return;

    // Initialize tracking for this dart
    dartThrowHealAmount[playerId] ??= [];
    dartThrowHealAmount[playerId]!.add(0);
    dartThrowDamageDealt[playerId] ??= [];
    dartThrowDamageDealt[playerId]!.add(0);
    dartThrowTargetPlayerId[playerId] ??= [];
    dartThrowTargetPlayerId[playerId]!.add(null);

    dartsThrown[playerId] = (dartsThrown[playerId] ?? 0) + 1;
    totalDartsThrown[playerId] = (totalDartsThrown[playerId] ?? 0) + 1;

    _incrementTurnIfFirst(playerId);
  }

  // Process dart hit (core game logic)
  void processDartHit(String playerId, int hitNumber, String multiplier) {
    if (state != MonsterMashGameState.playing) return;
    if (playerId != playerIds[currentPlayerIndex]) return;
    if (dartsThrown[playerId]! >= maxDartsPerTurn) return;

    final playerTarget = targetNumbers[playerId]!;

    // Calculate multiplier value
    int multiplierValue = 1;
    if (multiplier == 'double') multiplierValue = 2;
    if (multiplier == 'triple') multiplierValue = 3;

    // Initialize tracking
    dartThrowHealAmount[playerId] ??= [];
    dartThrowDamageDealt[playerId] ??= [];
    dartThrowTargetPlayerId[playerId] ??= [];

    dartsThrown[playerId] = (dartsThrown[playerId] ?? 0) + 1;
    totalDartsThrown[playerId] = (totalDartsThrown[playerId] ?? 0) + 1;

    _incrementTurnIfFirst(playerId);

    int healAmount = 0;
    int damageAmount = 0;
    String? targetPlayerId;

    // Handle Bullseye (50) and Outer Bull (25)
    if (hitNumber == 50) {
      // Bullseye: heal to max
      final healthBefore = health[playerId]!;
      health[playerId] = healthMax;
      healAmount = healthMax - healthBefore;

      // Laboratory Spark buff: bullseye also damages all opponents -10 HP
      if (activeBuff == BonusBuff.laboratorySpark) {
        for (final opponentId in playerIds) {
          if (opponentId != playerId && !eliminated[opponentId]!) {
            final opponentHealthBefore = health[opponentId]!;
            health[opponentId] = max(0, opponentHealthBefore - 10);
            final actualDamage = opponentHealthBefore - health[opponentId]!;
            totalDamageDealt[playerId] = (totalDamageDealt[playerId] ?? 0) + actualDamage;

            // Check elimination
            if (health[opponentId]! <= 0) {
              eliminated[opponentId] = true;
            }
          }
        }
      }

      dartThrowHealAmount[playerId]!.add(healAmount);
      dartThrowDamageDealt[playerId]!.add(0);
      dartThrowTargetPlayerId[playerId]!.add(null);

      _checkGameEnd();
      return;
    }

    if (hitNumber == 25) {
      // Outer Bull: heal +5
      int healValue = 5;
      final healthBefore = health[playerId]!;
      health[playerId] = min(healthBefore + healValue, healthMax);
      healAmount = health[playerId]! - healthBefore;

      dartThrowHealAmount[playerId]!.add(healAmount);
      dartThrowDamageDealt[playerId]!.add(0);
      dartThrowTargetPlayerId[playerId]!.add(null);

      return;
    }

    // Hit own number: heal
    if (hitNumber == playerTarget) {
      int healValue = multiplierValue;

      // Ancient Bandages buff: heal = 5 regardless of multiplier
      if (activeBuff == BonusBuff.ancientBandages) {
        healValue = 5;
      }

      final healthBefore = health[playerId]!;
      health[playerId] = min(healthBefore + healValue, healthMax);
      healAmount = health[playerId]! - healthBefore;

      dartThrowHealAmount[playerId]!.add(healAmount);
      dartThrowDamageDealt[playerId]!.add(0);
      dartThrowTargetPlayerId[playerId]!.add(null);

      return;
    }

    // Hit opponent's number: damage
    String? hitOpponentId;
    for (final entry in targetNumbers.entries) {
      if (entry.value == hitNumber && entry.key != playerId) {
        hitOpponentId = entry.key;
        break;
      }
    }

    if (hitOpponentId != null && !eliminated[hitOpponentId]!) {
      int damageValue = multiplierValue;

      // Blood Moon buff: damage * 2
      if (activeBuff == BonusBuff.bloodMoon) {
        damageValue *= 2;
      }

      // Shadow Walk buff: damage = 0
      if (activeBuff == BonusBuff.shadowWalk) {
        damageValue = 0;
      }

      final opponentHealthBefore = health[hitOpponentId]!;
      health[hitOpponentId] = max(0, opponentHealthBefore - damageValue);
      damageAmount = opponentHealthBefore - health[hitOpponentId]!;
      targetPlayerId = hitOpponentId;

      totalDamageDealt[playerId] = (totalDamageDealt[playerId] ?? 0) + damageAmount;

      // Check elimination
      if (health[hitOpponentId]! <= 0) {
        eliminated[hitOpponentId] = true;
      }

      dartThrowHealAmount[playerId]!.add(0);
      dartThrowDamageDealt[playerId]!.add(damageAmount);
      dartThrowTargetPlayerId[playerId]!.add(targetPlayerId);

      _checkGameEnd();
      return;
    }

    // Hit unassigned number or eliminated opponent: no effect
    dartThrowHealAmount[playerId]!.add(0);
    dartThrowDamageDealt[playerId]!.add(0);
    dartThrowTargetPlayerId[playerId]!.add(null);
  }

  // Check game end conditions
  void _checkGameEnd() {
    final activePlayers = playerIds.where((id) => !eliminated[id]!).toList();

    if (activePlayers.length <= 1) {
      state = MonsterMashGameState.finished;
      if (activePlayers.length == 1) {
        winnerId = activePlayers.first;
        winnerIds = [activePlayers.first];
      }
    }
  }

  // Check if round limit has been reached (called after round advancement)
  void _checkRoundLimit() {
    if (!speedPlayEnabled) return;
    if (currentRound > roundLimit) {
      state = MonsterMashGameState.finished;
      // Winner determined by getWinner/getWinners using tiebreaker logic
    }
  }

  // Advance to next player
  void advanceToNextPlayer() {
    if (state != MonsterMashGameState.playing) return;

    final currentPlayerId = getCurrentPlayerId();

    // Reset current player's dart tracking
    dartsThrown[currentPlayerId] = 0;
    currentTurnDarts[currentPlayerId] = [];
    dartThrowHealAmount[currentPlayerId] = [];
    dartThrowDamageDealt[currentPlayerId] = [];
    dartThrowTargetPlayerId[currentPlayerId] = [];

    // Track turns for round advancement
    turnsCompletedThisRound++;

    // Count non-eliminated players for round tracking
    final activePlayerCount = playerIds.where((id) => !eliminated[id]!).length;

    // Check if round is complete
    if (turnsCompletedThisRound >= activePlayerCount) {
      turnsCompletedThisRound = 0;
      currentRound++;

      // Check round limit
      _checkRoundLimit();
      if (state == MonsterMashGameState.finished) {
        _saveTurnStartState();
        return;
      }

      // Trigger random buff at start of new round
      if (bonusBuffsEnabled) {
        if (_shouldTriggerBuff()) {
          activeBuff = _selectRandomBuff();
        } else {
          activeBuff = null;
        }
      }
    }

    // Move to next non-eliminated player
    int attempts = 0;
    do {
      currentPlayerIndex = (currentPlayerIndex + 1) % playerIds.length;
      final nextPlayerId = playerIds[currentPlayerIndex];

      if (!eliminated[nextPlayerId]!) {
        break;
      }

      attempts++;
    } while (attempts < playerIds.length);

    _saveTurnStartState();
  }

  // Random determination for buff trigger (roughly 1 in 3 chance)
  bool _shouldTriggerBuff() {
    return Random().nextInt(3) == 0;
  }

  // Select a random buff
  BonusBuff _selectRandomBuff() {
    final buffs = BonusBuff.values;
    return buffs[Random().nextInt(buffs.length)];
  }

  // Save turn start state for edit score
  void _saveTurnStartState() {
    turnStartHealth = Map.from(health);
    turnStartEliminated = Map.from(eliminated);
    turnStartState = state;
    turnStartWinnerId = winnerId;
    turnStartWinnerIds = winnerIds != null ? List.from(winnerIds!) : null;
    turnStartTotalDamageDealt = Map.from(totalDamageDealt);
  }

  // Save initial turn start state (called from provider after game creation)
  void saveInitialTurnStartState() {
    _saveTurnStartState();
  }

  // Reset to start of turn for edit score
  void resetToStartOfTurn(String playerId) {
    health = Map.from(turnStartHealth);
    eliminated = Map.from(turnStartEliminated);
    state = turnStartState;
    winnerId = turnStartWinnerId;
    winnerIds = turnStartWinnerIds != null ? List.from(turnStartWinnerIds!) : null;
    totalDamageDealt = Map.from(turnStartTotalDamageDealt);
  }

  // Get monster image path based on health percentage
  String getMonsterImagePath(String playerId) {
    final monster = monsterAssignments[playerId]!;
    final monsterName = _getMonsterFileName(monster);
    final currentHealth = health[playerId] ?? 0;

    if (currentHealth <= 0 || eliminated[playerId] == true) {
      return 'assets/games/monster_mash/characters/$monsterName-Eliminated.png';
    }

    final healthPercent = (currentHealth / healthMax) * 100;

    if (healthPercent > 70) {
      return 'assets/games/monster_mash/characters/$monsterName-FullHealth.png';
    } else if (healthPercent > 30) {
      return 'assets/games/monster_mash/characters/$monsterName-70Health.png';
    } else {
      return 'assets/games/monster_mash/characters/$monsterName-30Health.png';
    }
  }

  // Convert MonsterType enum to file name prefix (instance method)
  String _getMonsterFileName(MonsterType monster) {
    return getMonsterFileName(monster);
  }

  // Convert MonsterType enum to file name prefix (static)
  static String getMonsterFileName(MonsterType monster) {
    switch (monster) {
      case MonsterType.dracula:
        return 'Dracula';
      case MonsterType.frankenstein:
        return 'Frankenstein';
      case MonsterType.mummy:
        return 'Mummy';
      case MonsterType.wolfMan:
        return 'WolfMan';
      case MonsterType.invisibleMan:
        return 'InvisibleMan';
      case MonsterType.gillMan:
        return 'GillMan';
      case MonsterType.mrHyde:
        return 'MrHyde';
      case MonsterType.phantom:
        return 'Phantom';
    }
  }

  // Get monster display name
  static String getMonsterDisplayName(MonsterType monster) {
    switch (monster) {
      case MonsterType.dracula:
        return 'Dracula';
      case MonsterType.frankenstein:
        return 'Frankenstein';
      case MonsterType.mummy:
        return 'The Mummy';
      case MonsterType.wolfMan:
        return 'Wolf Man';
      case MonsterType.invisibleMan:
        return 'Invisible Man';
      case MonsterType.gillMan:
        return 'Gill Man';
      case MonsterType.mrHyde:
        return 'Mr. Hyde';
      case MonsterType.phantom:
        return 'The Phantom';
    }
  }

  // Check if game has a winner
  bool hasWinner() {
    if (state != MonsterMashGameState.finished) return false;

    // Last player standing
    if (winnerId != null) return true;

    // Speed play: round limit reached, determine winner by health/damage
    if (speedPlayEnabled && currentRound > roundLimit) return true;

    return false;
  }

  // Get winner (single player)
  Player? getWinner(List<Player> players) {
    if (state != MonsterMashGameState.finished) return null;

    // Last player standing
    if (winnerId != null) {
      try {
        return players.firstWhere((p) => p.id == winnerId);
      } catch (e) {
        return null;
      }
    }

    // Speed play: determine by health, then by damage dealt (tiebreaker)
    if (speedPlayEnabled) {
      final activePlayers = playerIds.where((id) => !eliminated[id]!).toList();
      if (activePlayers.isEmpty) return null;

      activePlayers.sort((a, b) {
        final healthCompare = (health[b] ?? 0).compareTo(health[a] ?? 0);
        if (healthCompare != 0) return healthCompare;
        return (totalDamageDealt[b] ?? 0).compareTo(totalDamageDealt[a] ?? 0);
      });

      try {
        return players.firstWhere((p) => p.id == activePlayers.first);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  // Get all winners (handles ties in speed play)
  List<Player> getWinners(List<Player> players) {
    if (state != MonsterMashGameState.finished) return [];

    // Last player standing - single winner
    if (winnerId != null) {
      final winner = getWinner(players);
      return winner != null ? [winner] : [];
    }

    // Speed play: check for ties
    if (speedPlayEnabled) {
      final activePlayers = playerIds.where((id) => !eliminated[id]!).toList();
      if (activePlayers.isEmpty) return [];

      // Find highest health
      int maxHealth = 0;
      for (final id in activePlayers) {
        if ((health[id] ?? 0) > maxHealth) {
          maxHealth = health[id] ?? 0;
        }
      }

      // Get players with highest health
      final topPlayers = activePlayers.where((id) => health[id] == maxHealth).toList();

      if (topPlayers.length == 1) {
        try {
          return [players.firstWhere((p) => p.id == topPlayers.first)];
        } catch (e) {
          return [];
        }
      }

      // Tiebreaker: most damage dealt
      int maxDamage = 0;
      for (final id in topPlayers) {
        if ((totalDamageDealt[id] ?? 0) > maxDamage) {
          maxDamage = totalDamageDealt[id] ?? 0;
        }
      }

      final winners = topPlayers.where((id) => totalDamageDealt[id] == maxDamage).toList();
      return players.where((p) => winners.contains(p.id)).toList();
    }

    return [];
  }

  // Get health percentage for a player (0.0 to 1.0)
  double getHealthPercentage(String playerId) {
    return (health[playerId] ?? 0) / healthMax;
  }

  // Get darts thrown this turn for current player
  int getCurrentPlayerDartsThrown() {
    final currentPlayerId = getCurrentPlayerId();
    return dartsThrown[currentPlayerId] ?? 0;
  }

  // Get current turn darts for a player
  List<String> getCurrentTurnDarts(String playerId) {
    return currentTurnDarts[playerId] ?? [];
  }

  // Get total darts thrown for a player
  int getTotalDartsThrown(String playerId) {
    return totalDartsThrown[playerId] ?? 0;
  }

  // Get total turns for a player
  int getTotalTurns(String playerId) {
    return totalTurns[playerId] ?? 0;
  }

  // Get player count
  int getPlayerCount() {
    return playerIds.length;
  }

  // Get buff display name
  static String getBuffDisplayName(BonusBuff buff) {
    switch (buff) {
      case BonusBuff.bloodMoon:
        return 'Blood Moon';
      case BonusBuff.ancientBandages:
        return 'Ancient Bandages';
      case BonusBuff.shadowWalk:
        return 'Shadow Walk';
      case BonusBuff.laboratorySpark:
        return 'Laboratory Spark';
    }
  }

  // Get buff description
  static String getBuffDescription(BonusBuff buff) {
    switch (buff) {
      case BonusBuff.bloodMoon:
        return 'Attack damage doubled!';
      case BonusBuff.ancientBandages:
        return 'Healing fixed at +5!';
      case BonusBuff.shadowWalk:
        return 'Attacks deal no damage!';
      case BonusBuff.laboratorySpark:
        return 'Bullseye zaps all opponents -10 HP!';
    }
  }
}
