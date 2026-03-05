import 'dart:math';
import 'package:uuid/uuid.dart';
import '../utils/dartboard_layout.dart';

enum ReefRoyaleGameState { setup, playing, finished }

enum ReefRoyaleGameMode { standard, cursedTide }

enum SeaCreature {
  coralClownfish,
  shellyTurtle,
  jetOctopus,
  bubblesSeahorse,
  spikePufferfish,
  pearlJellyfish,
  captainCrab,
  finnDolphin
}

enum ReefBuff { riptideRush, pearlFever, inkCloud }

class ReefRoyaleGame {
  final String id;
  final DateTime startedAt;
  final int maxDartsPerTurn;

  // Game options
  final ReefRoyaleGameMode gameMode;
  final bool easyClaim;
  final bool neighborNumbers;
  final bool randomReefs;
  final bool bonusBuffsEnabled;
  final bool showHints;
  final bool speedPlayEnabled;
  final int roundLimit;

  // Players
  final List<String> playerIds;
  final Map<String, SeaCreature> creatureAssignments;

  // Targets & corals
  final List<int> activeTargets; // 7 target numbers (25 = Bull)
  final List<String> coralOrder; // Coral type names parallel to activeTargets

  // Runtime state
  ReefRoyaleGameState state;
  int currentPlayerIndex;
  int currentRound;
  int turnsCompletedThisRound;
  ReefBuff? activeBuff;

  // Per-player per-target marks: playerId -> {target -> markCount}
  Map<String, Map<int, int>> marks;
  // Per-player claimed targets: playerId -> set of claimed targets
  Map<String, Set<int>> claimed;
  // Targets locked by all players
  Set<int> locked;
  // Pearl counts
  Map<String, int> pearls;

  // Per-turn tracking
  Map<String, int> dartsThrown;
  Map<String, List<String>> currentTurnDarts;

  // Per-dart tracking arrays for UI/announcements
  Map<String, List<int>> dartThrowMarksAdded;
  Map<String, List<int>> dartThrowPearlsScored;
  Map<String, List<bool>> dartThrowClaimedCoral;
  Map<String, List<bool>> dartThrowLockedReef;
  Map<String, List<int?>> dartThrowTargetNumber;
  Map<String, List<bool>> dartThrowIsNeighbor;
  Map<String, List<String?>> dartThrowPearlRecipientId;
  Map<String, List<int>> dartThrowTargetCount; // Number of targets hit per dart (>1 = shared neighbor)

  // Lifetime stats
  Map<String, int> totalDartsThrown;
  Map<String, int> totalTurns;

  // Winner
  String? winnerId;
  List<String>? winnerIds;

  // Turn start snapshots for edit score
  Map<String, Map<int, int>> turnStartMarks;
  Map<String, Set<int>> turnStartClaimed;
  Set<int> turnStartLocked;
  Map<String, int> turnStartPearls;
  ReefRoyaleGameState turnStartState;
  String? turnStartWinnerId;
  List<String>? turnStartWinnerIds;

  // Standard targets: 20, 19, 18, 17, 16, 15, Bull
  static const List<int> standardTargets = [20, 19, 18, 17, 16, 15, 25];
  static const List<String> standardCoralOrder = [
    'FireCoral',
    'BrainCoral',
    'FanCoral',
    'StaghornCoral',
    'MushroomCoral',
    'TubeCoral',
    'PearlOyster'
  ];

  ReefRoyaleGame({
    required this.id,
    required this.startedAt,
    this.maxDartsPerTurn = 3,
    required this.gameMode,
    required this.easyClaim,
    required this.neighborNumbers,
    required this.randomReefs,
    required this.bonusBuffsEnabled,
    required this.showHints,
    required this.speedPlayEnabled,
    required this.roundLimit,
    required this.playerIds,
    required this.creatureAssignments,
    required this.activeTargets,
    required this.coralOrder,
    this.state = ReefRoyaleGameState.setup,
    this.currentPlayerIndex = 0,
    this.currentRound = 1,
    this.turnsCompletedThisRound = 0,
    this.activeBuff,
    Map<String, Map<int, int>>? marks,
    Map<String, Set<int>>? claimed,
    Set<int>? locked,
    Map<String, int>? pearls,
    Map<String, int>? dartsThrown,
    Map<String, List<String>>? currentTurnDarts,
    Map<String, List<int>>? dartThrowMarksAdded,
    Map<String, List<int>>? dartThrowPearlsScored,
    Map<String, List<bool>>? dartThrowClaimedCoral,
    Map<String, List<bool>>? dartThrowLockedReef,
    Map<String, List<int?>>? dartThrowTargetNumber,
    Map<String, List<bool>>? dartThrowIsNeighbor,
    Map<String, List<String?>>? dartThrowPearlRecipientId,
    Map<String, List<int>>? dartThrowTargetCount,
    Map<String, int>? totalDartsThrown,
    Map<String, int>? totalTurns,
    this.winnerId,
    this.winnerIds,
    Map<String, Map<int, int>>? turnStartMarks,
    Map<String, Set<int>>? turnStartClaimed,
    Set<int>? turnStartLocked,
    Map<String, int>? turnStartPearls,
    ReefRoyaleGameState? turnStartState,
    this.turnStartWinnerId,
    this.turnStartWinnerIds,
  })  : marks = marks ?? {},
        claimed = claimed ?? {},
        locked = locked ?? {},
        pearls = pearls ?? {},
        dartsThrown = dartsThrown ?? {},
        currentTurnDarts = currentTurnDarts ?? {},
        dartThrowMarksAdded = dartThrowMarksAdded ?? {},
        dartThrowPearlsScored = dartThrowPearlsScored ?? {},
        dartThrowClaimedCoral = dartThrowClaimedCoral ?? {},
        dartThrowLockedReef = dartThrowLockedReef ?? {},
        dartThrowTargetNumber = dartThrowTargetNumber ?? {},
        dartThrowIsNeighbor = dartThrowIsNeighbor ?? {},
        dartThrowPearlRecipientId = dartThrowPearlRecipientId ?? {},
        dartThrowTargetCount = dartThrowTargetCount ?? {},
        totalDartsThrown = totalDartsThrown ?? {},
        totalTurns = totalTurns ?? {},
        turnStartMarks = turnStartMarks ?? {},
        turnStartClaimed = turnStartClaimed ?? {},
        turnStartLocked = turnStartLocked ?? {},
        turnStartPearls = turnStartPearls ?? {},
        turnStartState = turnStartState ?? ReefRoyaleGameState.setup {
    // Initialize per-player state
    for (var playerId in playerIds) {
      this.marks[playerId] ??= {};
      this.claimed[playerId] ??= {};
      this.pearls[playerId] ??= 0;
      this.dartsThrown[playerId] ??= 0;
      this.currentTurnDarts[playerId] ??= [];
      this.dartThrowMarksAdded[playerId] ??= [];
      this.dartThrowPearlsScored[playerId] ??= [];
      this.dartThrowClaimedCoral[playerId] ??= [];
      this.dartThrowLockedReef[playerId] ??= [];
      this.dartThrowTargetNumber[playerId] ??= [];
      this.dartThrowIsNeighbor[playerId] ??= [];
      this.dartThrowPearlRecipientId[playerId] ??= [];
      this.dartThrowTargetCount[playerId] ??= [];
      this.totalDartsThrown[playerId] ??= 0;
      this.totalTurns[playerId] ??= 0;
      // Initialize marks for all targets
      for (var target in activeTargets) {
        this.marks[playerId]![target] ??= 0;
      }
    }
  }

  factory ReefRoyaleGame.create({
    required List<String> playerIds,
    required ReefRoyaleGameMode gameMode,
    required bool easyClaim,
    required bool neighborNumbers,
    required bool randomReefs,
    required bool bonusBuffsEnabled,
    required bool showHints,
    required bool speedPlayEnabled,
    required int roundLimit,
  }) {
    final random = Random();

    // Assign creatures (unique per player)
    final availableCreatures = List<SeaCreature>.from(SeaCreature.values)
      ..shuffle(random);
    final creatureAssignments = <String, SeaCreature>{};
    for (int i = 0; i < playerIds.length; i++) {
      creatureAssignments[playerIds[i]] = availableCreatures[i];
    }

    // Determine targets and coral order
    List<int> activeTargets;
    List<String> coralOrder;
    if (randomReefs) {
      final numbers = List.generate(20, (i) => i + 1)..shuffle(random);
      activeTargets = numbers.take(6).toList()
        ..sort((a, b) => b.compareTo(a));
      activeTargets.add(25); // Bull always 7th
      final numberCorals = [
        'FireCoral',
        'BrainCoral',
        'FanCoral',
        'StaghornCoral',
        'MushroomCoral',
        'TubeCoral'
      ]..shuffle(random);
      coralOrder = [...numberCorals, 'PearlOyster'];
    } else {
      activeTargets = List.from(standardTargets);
      coralOrder = List.from(standardCoralOrder);
    }

    return ReefRoyaleGame(
      id: const Uuid().v4(),
      startedAt: DateTime.now(),
      maxDartsPerTurn: 3,
      gameMode: gameMode,
      easyClaim: easyClaim,
      neighborNumbers: neighborNumbers,
      randomReefs: randomReefs,
      bonusBuffsEnabled: bonusBuffsEnabled,
      showHints: showHints,
      speedPlayEnabled: speedPlayEnabled,
      roundLimit: roundLimit,
      playerIds: playerIds,
      creatureAssignments: creatureAssignments,
      activeTargets: activeTargets,
      coralOrder: coralOrder,
      state: ReefRoyaleGameState.playing,
      currentPlayerIndex: 0,
      currentRound: 1,
      turnsCompletedThisRound: 0,
    );
  }

  // --- Accessors ---

  String getCurrentPlayerId() => playerIds[currentPlayerIndex];

  int get markThreshold => easyClaim ? 2 : 3;

  int getPlayerMarks(String playerId, int target) =>
      marks[playerId]?[target] ?? 0;

  bool hasPlayerClaimed(String playerId, int target) =>
      claimed[playerId]?.contains(target) ?? false;

  bool isTargetLocked(int target) => locked.contains(target);

  int getPlayerPearls(String playerId) => pearls[playerId] ?? 0;

  int getPlayerClaimedCount(String playerId) =>
      claimed[playerId]?.length ?? 0;

  int getCurrentPlayerDartsThrown() =>
      dartsThrown[getCurrentPlayerId()] ?? 0;

  List<String> getCurrentTurnDarts(String playerId) =>
      currentTurnDarts[playerId] ?? [];

  int getPlayerCount() => playerIds.length;

  // --- Target Resolution ---

  /// Resolve what target a thrown number maps to.
  /// Returns null if not a valid target.
  int? resolveTarget(int hitNumber) {
    // Bull
    if (hitNumber == 50 || hitNumber == 25) {
      return activeTargets.contains(25) ? 25 : null;
    }

    // Direct target hit
    if (activeTargets.contains(hitNumber)) {
      return hitNumber;
    }

    // Neighbor hit
    if (neighborNumbers) {
      return DartboardLayout.findNeighborTarget(
        hitNumber,
        activeTargets.where((t) => t != 25).toList(),
      );
    }

    return null;
  }

  /// Resolve ALL targets a thrown number maps to.
  /// A neighbor number shared by two targets returns both.
  List<int> resolveAllTargets(int hitNumber) {
    // Bull
    if (hitNumber == 50 || hitNumber == 25) {
      return activeTargets.contains(25) ? [25] : [];
    }

    // Direct target hit (always single target)
    if (activeTargets.contains(hitNumber)) {
      return [hitNumber];
    }

    // Neighbor hit — may match multiple targets
    if (neighborNumbers) {
      return DartboardLayout.findAllNeighborTargets(
        hitNumber,
        activeTargets.where((t) => t != 25).toList(),
      );
    }

    return [];
  }

  // --- Dart Processing ---

  void _incrementTurnIfFirst(String playerId) {
    if (dartsThrown[playerId] == 1) {
      totalTurns[playerId] = (totalTurns[playerId] ?? 0) + 1;
    }
  }

  void _recordMissDartTracking(String playerId) {
    dartThrowMarksAdded[playerId]!.add(0);
    dartThrowPearlsScored[playerId]!.add(0);
    dartThrowClaimedCoral[playerId]!.add(false);
    dartThrowLockedReef[playerId]!.add(false);
    dartThrowTargetNumber[playerId]!.add(null);
    dartThrowIsNeighbor[playerId]!.add(false);
    dartThrowPearlRecipientId[playerId]!.add(null);
    dartThrowTargetCount[playerId]!.add(0);
  }

  /// Process a miss (no valid target hit).
  void processMiss(String playerId) {
    if (state != ReefRoyaleGameState.playing) return;
    if (playerId != playerIds[currentPlayerIndex]) return;
    if (dartsThrown[playerId]! >= maxDartsPerTurn) return;

    dartsThrown[playerId] = (dartsThrown[playerId] ?? 0) + 1;
    totalDartsThrown[playerId] = (totalDartsThrown[playerId] ?? 0) + 1;
    _incrementTurnIfFirst(playerId);
    _recordMissDartTracking(playerId);
  }

  /// Process a dart hit on resolved target(s).
  /// [hitNumber]: actual number thrown (1-20, 25=outer bull, 50=inner bull)
  /// [multiplier]: 'single', 'double', 'triple'
  /// [resolvedTargets]: list of all targets this hit counts toward (can be multiple for shared neighbors)
  void processDart(
    String playerId,
    int hitNumber,
    String multiplier, {
    required List<int> resolvedTargets,
  }) {
    if (state != ReefRoyaleGameState.playing) return;
    if (playerId != playerIds[currentPlayerIndex]) return;
    if (dartsThrown[playerId]! >= maxDartsPerTurn) return;
    if (resolvedTargets.isEmpty) return;

    // Increment dart count ONCE per dart thrown (not per target hit)
    dartsThrown[playerId] = (dartsThrown[playerId] ?? 0) + 1;
    totalDartsThrown[playerId] = (totalDartsThrown[playerId] ?? 0) + 1;
    _incrementTurnIfFirst(playerId);

    // Calculate multiplier value
    int multiplierValue = 1;
    if (multiplier == 'double') multiplierValue = 2;
    if (multiplier == 'triple') multiplierValue = 3;

    // Aggregated tracking data (one entry per dart thrown)
    int totalMarksAdded = 0;
    int totalPearlsScored = 0;
    bool anyClaimedCoral = false;
    bool anyLockedReef = false;
    bool anyDirectHit = false; // True if ANY target was hit directly (not as neighbor)
    List<int> targetsHit = [];
    String? pearlRecipient;

    // Process each resolved target
    for (final target in resolvedTargets) {
      // Determine if this specific target was hit as a neighbor
      bool isNeighborHit = (hitNumber != target) &&
          !(hitNumber == 50 && target == 25) &&
          !(hitNumber == 25 && target == 25);

      // If ANY hit is direct, the dart shows as direct
      if (!isNeighborHit) {
        anyDirectHit = true;
      }

      targetsHit.add(target);

      // Calculate marks to add for this target
      int marksToAdd;
      if (hitNumber == 50) {
        marksToAdd = 2; // Inner bull = 2 marks
      } else if (hitNumber == 25) {
        marksToAdd = 1; // Outer bull = 1 mark
      } else {
        marksToAdd = multiplierValue; // Applies to both direct and neighbor hits
      }

      // Riptide Rush doubles marks
      if (activeBuff == ReefBuff.riptideRush) {
        marksToAdd *= 2;
      }

      // Locked target - no effect from this target
      if (locked.contains(target)) {
        anyLockedReef = true;
        continue;
      }

      bool playerClaimed = claimed[playerId]!.contains(target);

      if (!playerClaimed) {
        // Process marking for this target
        var result = _processMarkingForTarget(playerId, target, hitNumber,
            multiplierValue, marksToAdd, isNeighborHit);
        totalMarksAdded += result['marksAdded'] as int;
        totalPearlsScored += result['pearlsScored'] as int;
        if (result['claimed'] as bool) anyClaimedCoral = true;
        if (result['locked'] as bool) anyLockedReef = true;
        if (result['pearlRecipient'] != null) pearlRecipient = result['pearlRecipient'] as String?;
      } else {
        // Process scoring for this target
        var result = _processScoringForTarget(playerId, target, hitNumber,
            multiplierValue, isNeighborHit);
        totalPearlsScored += result['pearlsScored'] as int;
        if (result['pearlRecipient'] != null) pearlRecipient = result['pearlRecipient'] as String?;
      }
    }

    // Add ONE aggregated tracking entry per dart thrown
    dartThrowMarksAdded[playerId]!.add(totalMarksAdded);
    dartThrowPearlsScored[playerId]!.add(totalPearlsScored);
    dartThrowClaimedCoral[playerId]!.add(anyClaimedCoral);
    dartThrowLockedReef[playerId]!.add(anyLockedReef);
    dartThrowTargetNumber[playerId]!.add(targetsHit.isNotEmpty ? targetsHit.first : null);
    dartThrowIsNeighbor[playerId]!.add(!anyDirectHit); // Neighbor only if NO direct hits
    dartThrowPearlRecipientId[playerId]!.add(pearlRecipient);
    dartThrowTargetCount[playerId]!.add(resolvedTargets.length);
  }

  /// Process marking for a single target and return results (does not add to tracking lists)
  Map<String, dynamic> _processMarkingForTarget(String playerId, int target,
      int hitNumber, int multiplierValue, int marksToAdd, bool isNeighborHit) {
    int currentMarks = marks[playerId]![target] ?? 0;
    int newMarks = currentMarks + marksToAdd;
    marks[playerId]![target] = newMarks;

    bool justClaimed = false;
    bool justLocked = false;
    int pearlsScoredThisDart = 0;
    String? pearlRecipient;

    if (newMarks >= markThreshold) {
      // Coral blooms!
      claimed[playerId]!.add(target);
      justClaimed = true;

      // Check if locked
      bool allClaimed =
          playerIds.every((pid) => claimed[pid]!.contains(target));
      if (allClaimed) {
        locked.add(target);
        justLocked = true;
      }

      // Excess marks can score if not locked
      int excessMarks = newMarks - markThreshold;
      if (excessMarks > 0 && !locked.contains(target)) {
        bool anyOpponentUnclaimed = playerIds.any(
            (pid) => pid != playerId && !claimed[pid]!.contains(target));
        if (anyOpponentUnclaimed) {
          int pearlValue = excessMarks * getPearlValuePerMark(target);
          pearlsScoredThisDart =
              _applyPearlScoring(playerId, target, pearlValue);
          if (gameMode == ReefRoyaleGameMode.cursedTide) {
            pearlRecipient = playerIds.firstWhere(
              (pid) =>
                  pid != playerId && !claimed[pid]!.contains(target),
              orElse: () => playerId,
            );
          }
        }
      }

      _checkWinCondition();
    }

    return {
      'marksAdded': marksToAdd,
      'pearlsScored': pearlsScoredThisDart,
      'claimed': justClaimed,
      'locked': justLocked,
      'pearlRecipient': pearlRecipient,
    };
  }

  /// Process scoring for a single target and return results (does not add to tracking lists)
  Map<String, dynamic> _processScoringForTarget(String playerId, int target,
      int hitNumber, int multiplierValue, bool isNeighborHit) {
    bool anyOpponentUnclaimed = playerIds
        .any((pid) => pid != playerId && !claimed[pid]!.contains(target));

    int pearlsScoredThisDart = 0;
    String? pearlRecipient;

    if (anyOpponentUnclaimed) {
      int pearlValue;
      if (hitNumber == 50) {
        pearlValue = 50;
      } else if (hitNumber == 25) {
        pearlValue = 25;
      } else {
        pearlValue = target * multiplierValue; // Applies to both direct and neighbor hits
      }

      pearlsScoredThisDart =
          _applyPearlScoring(playerId, target, pearlValue);
      if (gameMode == ReefRoyaleGameMode.cursedTide) {
        pearlRecipient = playerIds.firstWhere(
          (pid) =>
              pid != playerId && !claimed[pid]!.contains(target),
          orElse: () => playerId,
        );
      }
    }

    return {
      'marksAdded': 0,
      'pearlsScored': pearlsScoredThisDart,
      'claimed': false,
      'locked': false,
      'pearlRecipient': pearlRecipient,
    };
  }

  /// Apply pearl scoring based on game mode. Returns the pearl value applied.
  int _applyPearlScoring(String playerId, int target, int pearlValue) {
    // Pearl Fever doubles pearls
    if (activeBuff == ReefBuff.pearlFever) {
      pearlValue *= 2;
    }

    if (gameMode == ReefRoyaleGameMode.cursedTide) {
      // Pearls go to all opponents who haven't claimed this target
      for (final opponentId in playerIds) {
        if (opponentId != playerId &&
            !claimed[opponentId]!.contains(target)) {
          pearls[opponentId] = (pearls[opponentId] ?? 0) + pearlValue;
        }
      }
    } else {
      pearls[playerId] = (pearls[playerId] ?? 0) + pearlValue;
    }

    return pearlValue;
  }

  /// Get pearl value per mark for a target (used for excess mark scoring).
  static int getPearlValuePerMark(int target) {
    if (target == 25) return 25; // Bull = 25 per mark
    return target;
  }

  // --- Win Condition ---

  void _checkWinCondition() {
    // Check if any player claimed all 7 and has pearl lead
    for (final playerId in playerIds) {
      if (claimed[playerId]!.length == activeTargets.length) {
        bool hasPearlLead;
        if (gameMode == ReefRoyaleGameMode.cursedTide) {
          hasPearlLead = playerIds.every((pid) =>
              pid == playerId ||
              (pearls[playerId] ?? 0) <= (pearls[pid] ?? 0));
        } else {
          hasPearlLead = playerIds.every((pid) =>
              pid == playerId ||
              (pearls[playerId] ?? 0) >= (pearls[pid] ?? 0));
        }

        if (hasPearlLead) {
          state = ReefRoyaleGameState.finished;
          winnerId = playerId;
          winnerIds = [playerId];
          return;
        }
      }
    }

    // All targets locked -> determine winner by ranking
    if (locked.length == activeTargets.length) {
      state = ReefRoyaleGameState.finished;
      _determineWinnerByRanking();
    }
  }

  void _checkRoundLimit() {
    if (!speedPlayEnabled) return;
    if (currentRound > roundLimit) {
      state = ReefRoyaleGameState.finished;
      _determineWinnerByRanking();
    }
  }

  void _determineWinnerByRanking() {
    final sorted = getRankedPlayerIds();

    // Check for ties at the top
    final topCorals = claimed[sorted[0]]?.length ?? 0;
    final topPearls = pearls[sorted[0]] ?? 0;
    final tiedPlayers = sorted.where((pid) {
      return (claimed[pid]?.length ?? 0) == topCorals &&
          (pearls[pid] ?? 0) == topPearls;
    }).toList();

    if (tiedPlayers.length == 1) {
      winnerId = tiedPlayers[0];
      winnerIds = tiedPlayers;
    } else {
      // Multiple winners tied - keep all of them
      final firstInOrder =
          playerIds.firstWhere((pid) => tiedPlayers.contains(pid));
      winnerId = firstInOrder; // Primary winner for legacy compatibility
      winnerIds = tiedPlayers; // All tied winners
    }
  }

  bool hasWinner() {
    if (state != ReefRoyaleGameState.finished) return false;
    return winnerId != null;
  }

  /// Get ranked player IDs (best first).
  List<String> getRankedPlayerIds() {
    final sorted = List<String>.from(playerIds);
    sorted.sort((a, b) {
      final coralsCompare =
          (claimed[b]?.length ?? 0).compareTo(claimed[a]?.length ?? 0);
      if (coralsCompare != 0) return coralsCompare;
      if (gameMode == ReefRoyaleGameMode.cursedTide) {
        return (pearls[a] ?? 0).compareTo(pearls[b] ?? 0);
      } else {
        return (pearls[b] ?? 0).compareTo(pearls[a] ?? 0);
      }
    });
    return sorted;
  }

  // --- Turn Management ---

  void advanceToNextPlayer() {
    if (state != ReefRoyaleGameState.playing) return;

    final currentPlayerId = getCurrentPlayerId();

    // Reset tracking
    dartsThrown[currentPlayerId] = 0;
    currentTurnDarts[currentPlayerId] = [];
    dartThrowMarksAdded[currentPlayerId] = [];
    dartThrowPearlsScored[currentPlayerId] = [];
    dartThrowClaimedCoral[currentPlayerId] = [];
    dartThrowLockedReef[currentPlayerId] = [];
    dartThrowTargetNumber[currentPlayerId] = [];
    dartThrowIsNeighbor[currentPlayerId] = [];
    dartThrowPearlRecipientId[currentPlayerId] = [];
    dartThrowTargetCount[currentPlayerId] = [];

    turnsCompletedThisRound++;

    // Check for round completion
    if (turnsCompletedThisRound >= playerIds.length) {
      turnsCompletedThisRound = 0;

      // Check if we've reached the round limit before incrementing
      if (speedPlayEnabled && currentRound >= roundLimit) {
        state = ReefRoyaleGameState.finished;
        _determineWinnerByRanking();
        _saveTurnStartState();
        return;
      }

      currentRound++;

      // Trigger buff at start of new round
      if (bonusBuffsEnabled) {
        if (_shouldTriggerBuff()) {
          activeBuff = _selectRandomBuff();
        } else {
          activeBuff = null;
        }
      }
    }

    // Move to next player
    currentPlayerIndex = (currentPlayerIndex + 1) % playerIds.length;

    _saveTurnStartState();
  }

  bool _shouldTriggerBuff() => Random().nextInt(3) == 0;

  ReefBuff _selectRandomBuff() {
    final buffs = ReefBuff.values;
    return buffs[Random().nextInt(buffs.length)];
  }

  // --- Edit Score Support ---

  void _saveTurnStartState() {
    turnStartMarks = {};
    for (final entry in marks.entries) {
      turnStartMarks[entry.key] = Map.from(entry.value);
    }
    turnStartClaimed = {};
    for (final entry in claimed.entries) {
      turnStartClaimed[entry.key] = Set.from(entry.value);
    }
    turnStartLocked = Set.from(locked);
    turnStartPearls = Map.from(pearls);
    turnStartState = state;
    turnStartWinnerId = winnerId;
    turnStartWinnerIds =
        winnerIds != null ? List.from(winnerIds!) : null;
  }

  void saveInitialTurnStartState() => _saveTurnStartState();

  void resetToStartOfTurn(String playerId) {
    marks = {};
    for (final entry in turnStartMarks.entries) {
      marks[entry.key] = Map.from(entry.value);
    }
    claimed = {};
    for (final entry in turnStartClaimed.entries) {
      claimed[entry.key] = Set.from(entry.value);
    }
    locked = Set.from(turnStartLocked);
    pearls = Map.from(turnStartPearls);
    state = turnStartState;
    winnerId = turnStartWinnerId;
    winnerIds =
        turnStartWinnerIds != null ? List.from(turnStartWinnerIds!) : null;
  }

  // --- Display Helpers ---

  String getCreatureImagePath(String playerId) {
    final creature = creatureAssignments[playerId]!;
    final fileName = getCreatureFileName(creature);
    return 'assets/games/reef_royale/characters/$fileName.png';
  }

  String getCoralImagePath(int target, bool isClaimed) {
    final index = activeTargets.indexOf(target);
    if (index == -1) return '';
    final coralName = coralOrder[index];
    final stateName = isClaimed ? 'Claimed' : 'Unclaimed';
    return 'assets/games/reef_royale/corals/$coralName-$stateName.png';
  }

  String getCoralDisplayName(int target) {
    final index = activeTargets.indexOf(target);
    if (index == -1) return 'Unknown';
    final coralName = coralOrder[index];
    return coralName.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
  }

  String getTargetDisplayName(int target) {
    if (target == 25) return 'Bull';
    return '$target';
  }

  static String getCreatureFileName(SeaCreature creature) {
    switch (creature) {
      case SeaCreature.coralClownfish:
        return 'CoralClownfish';
      case SeaCreature.shellyTurtle:
        return 'ShellyTurtle';
      case SeaCreature.jetOctopus:
        return 'JetOctopus';
      case SeaCreature.bubblesSeahorse:
        return 'BubblesSeahorse';
      case SeaCreature.spikePufferfish:
        return 'SpikePufferfish';
      case SeaCreature.pearlJellyfish:
        return 'PearlJellyfish';
      case SeaCreature.captainCrab:
        return 'CaptainCrab';
      case SeaCreature.finnDolphin:
        return 'FinnDolphin';
    }
  }

  static String getCreatureDisplayName(SeaCreature creature) {
    switch (creature) {
      case SeaCreature.coralClownfish:
        return 'Coral the Clownfish';
      case SeaCreature.shellyTurtle:
        return 'Shelly the Sea Turtle';
      case SeaCreature.jetOctopus:
        return 'Jet the Octopus';
      case SeaCreature.bubblesSeahorse:
        return 'Bubbles the Seahorse';
      case SeaCreature.spikePufferfish:
        return 'Spike the Pufferfish';
      case SeaCreature.pearlJellyfish:
        return 'Pearl the Jellyfish';
      case SeaCreature.captainCrab:
        return 'Captain Crab';
      case SeaCreature.finnDolphin:
        return 'Finn the Dolphin';
    }
  }

  static String getCoralName(int target) {
    switch (target) {
      case 20:
        return 'Fire Coral';
      case 19:
        return 'Brain Coral';
      case 18:
        return 'Fan Coral';
      case 17:
        return 'Staghorn Coral';
      case 16:
        return 'Mushroom Coral';
      case 15:
        return 'Tube Coral';
      case 25:
        return 'Pearl Oyster';
      default:
        return 'Coral $target';
    }
  }

  static String getBuffDisplayName(ReefBuff buff) {
    switch (buff) {
      case ReefBuff.riptideRush:
        return 'Riptide Rush';
      case ReefBuff.pearlFever:
        return 'Pearl Fever';
      case ReefBuff.inkCloud:
        return 'Ink Cloud';
    }
  }

  static String getBuffDescription(ReefBuff buff) {
    switch (buff) {
      case ReefBuff.riptideRush:
        return 'Double marks this round!';
      case ReefBuff.pearlFever:
        return 'Double pearls this round!';
      case ReefBuff.inkCloud:
        return 'All opponent info is hidden this round!';
    }
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'maxDartsPerTurn': maxDartsPerTurn,
      'gameMode': gameMode.name,
      'easyClaim': easyClaim,
      'neighborNumbers': neighborNumbers,
      'randomReefs': randomReefs,
      'bonusBuffsEnabled': bonusBuffsEnabled,
      'showHints': showHints,
      'speedPlayEnabled': speedPlayEnabled,
      'roundLimit': roundLimit,
      'playerIds': playerIds,
      'creatureAssignments': creatureAssignments.map(
          (k, v) => MapEntry(k, v.name)),
      'activeTargets': activeTargets,
      'coralOrder': coralOrder,
      'state': state.name,
      'currentPlayerIndex': currentPlayerIndex,
      'currentRound': currentRound,
      'turnsCompletedThisRound': turnsCompletedThisRound,
      'activeBuff': activeBuff?.name,
      'marks': marks.map((k, v) => MapEntry(k, v.map(
          (mk, mv) => MapEntry(mk.toString(), mv)))),
      'claimed': claimed.map((k, v) => MapEntry(k, v.toList())),
      'locked': locked.toList(),
      'pearls': pearls,
      'dartsThrown': dartsThrown,
      'currentTurnDarts': currentTurnDarts,
      'dartThrowMarksAdded': dartThrowMarksAdded,
      'dartThrowPearlsScored': dartThrowPearlsScored,
      'dartThrowClaimedCoral': dartThrowClaimedCoral,
      'dartThrowLockedReef': dartThrowLockedReef,
      'dartThrowTargetNumber': dartThrowTargetNumber,
      'dartThrowIsNeighbor': dartThrowIsNeighbor,
      'dartThrowPearlRecipientId': dartThrowPearlRecipientId,
      'dartThrowTargetCount': dartThrowTargetCount,
      'totalDartsThrown': totalDartsThrown,
      'totalTurns': totalTurns,
      'winnerId': winnerId,
      'winnerIds': winnerIds,
      'turnStartMarks': turnStartMarks.map((k, v) => MapEntry(k, v.map(
          (mk, mv) => MapEntry(mk.toString(), mv)))),
      'turnStartClaimed': turnStartClaimed.map(
          (k, v) => MapEntry(k, v.toList())),
      'turnStartLocked': turnStartLocked.toList(),
      'turnStartPearls': turnStartPearls,
      'turnStartState': turnStartState.name,
      'turnStartWinnerId': turnStartWinnerId,
      'turnStartWinnerIds': turnStartWinnerIds,
    };
  }

  // Create from JSON
  factory ReefRoyaleGame.fromJson(Map<String, dynamic> json) {
    // Helper to deserialize marks maps (Map<String, Map<int, int>>)
    Map<String, Map<int, int>>? deserializeMarks(dynamic data) {
      if (data == null) return null;
      return (data as Map<String, dynamic>).map((k, v) =>
        MapEntry(k, (v as Map<String, dynamic>).map(
          (mk, mv) => MapEntry(int.parse(mk), mv as int))));
    }

    // Helper to deserialize claimed maps (Map<String, Set<int>>)
    Map<String, Set<int>>? deserializeClaimed(dynamic data) {
      if (data == null) return null;
      return (data as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, Set<int>.from(v as List)));
    }

    return ReefRoyaleGame(
      id: json['id'],
      startedAt: DateTime.parse(json['startedAt']),
      maxDartsPerTurn: json['maxDartsPerTurn'] ?? 3,
      gameMode: ReefRoyaleGameMode.values.firstWhere(
        (e) => e.name == json['gameMode'],
        orElse: () => ReefRoyaleGameMode.standard,
      ),
      easyClaim: json['easyClaim'] ?? false,
      neighborNumbers: json['neighborNumbers'] ?? false,
      randomReefs: json['randomReefs'] ?? false,
      bonusBuffsEnabled: json['bonusBuffsEnabled'] ?? false,
      showHints: json['showHints'] ?? false,
      speedPlayEnabled: json['speedPlayEnabled'] ?? false,
      roundLimit: json['roundLimit'] ?? 10,
      playerIds: List<String>.from(json['playerIds']),
      creatureAssignments: (json['creatureAssignments'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, SeaCreature.values.firstWhere(
          (e) => e.name == v,
        )),
      ),
      activeTargets: List<int>.from(json['activeTargets']),
      coralOrder: List<String>.from(json['coralOrder']),
      state: ReefRoyaleGameState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => ReefRoyaleGameState.setup,
      ),
      currentPlayerIndex: json['currentPlayerIndex'],
      currentRound: json['currentRound'] ?? 1,
      turnsCompletedThisRound: json['turnsCompletedThisRound'] ?? 0,
      activeBuff: json['activeBuff'] != null
          ? ReefBuff.values.firstWhere(
              (e) => e.name == json['activeBuff'],
            )
          : null,
      marks: deserializeMarks(json['marks']),
      claimed: deserializeClaimed(json['claimed']),
      locked: json['locked'] != null
          ? Set<int>.from(json['locked'])
          : null,
      pearls: json['pearls'] != null
          ? Map<String, int>.from(json['pearls'])
          : null,
      dartsThrown: json['dartsThrown'] != null
          ? Map<String, int>.from(json['dartsThrown'])
          : null,
      currentTurnDarts: json['currentTurnDarts'] != null
          ? (json['currentTurnDarts'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<String>.from(v)))
          : null,
      dartThrowMarksAdded: json['dartThrowMarksAdded'] != null
          ? (json['dartThrowMarksAdded'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<int>.from(v)))
          : null,
      dartThrowPearlsScored: json['dartThrowPearlsScored'] != null
          ? (json['dartThrowPearlsScored'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<int>.from(v)))
          : null,
      dartThrowClaimedCoral: json['dartThrowClaimedCoral'] != null
          ? (json['dartThrowClaimedCoral'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<bool>.from(v)))
          : null,
      dartThrowLockedReef: json['dartThrowLockedReef'] != null
          ? (json['dartThrowLockedReef'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<bool>.from(v)))
          : null,
      dartThrowTargetNumber: json['dartThrowTargetNumber'] != null
          ? (json['dartThrowTargetNumber'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<int?>.from(v)))
          : null,
      dartThrowIsNeighbor: json['dartThrowIsNeighbor'] != null
          ? (json['dartThrowIsNeighbor'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<bool>.from(v)))
          : null,
      dartThrowPearlRecipientId: json['dartThrowPearlRecipientId'] != null
          ? (json['dartThrowPearlRecipientId'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<String?>.from(v)))
          : null,
      dartThrowTargetCount: json['dartThrowTargetCount'] != null
          ? (json['dartThrowTargetCount'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<int>.from(v)))
          : null,
      totalDartsThrown: json['totalDartsThrown'] != null
          ? Map<String, int>.from(json['totalDartsThrown'])
          : null,
      totalTurns: json['totalTurns'] != null
          ? Map<String, int>.from(json['totalTurns'])
          : null,
      winnerId: json['winnerId'],
      winnerIds: json['winnerIds'] != null
          ? List<String>.from(json['winnerIds'])
          : null,
      turnStartMarks: deserializeMarks(json['turnStartMarks']),
      turnStartClaimed: deserializeClaimed(json['turnStartClaimed']),
      turnStartLocked: json['turnStartLocked'] != null
          ? Set<int>.from(json['turnStartLocked'])
          : null,
      turnStartPearls: json['turnStartPearls'] != null
          ? Map<String, int>.from(json['turnStartPearls'])
          : null,
      turnStartState: json['turnStartState'] != null
          ? ReefRoyaleGameState.values.firstWhere(
              (e) => e.name == json['turnStartState'],
              orElse: () => ReefRoyaleGameState.setup,
            )
          : null,
      turnStartWinnerId: json['turnStartWinnerId'],
      turnStartWinnerIds: json['turnStartWinnerIds'] != null
          ? List<String>.from(json['turnStartWinnerIds'])
          : null,
    );
  }
}
