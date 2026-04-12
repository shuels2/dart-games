import 'dart:math';

enum ClockworkQuestGameState { setup, playing, finished }

enum ClockworkInventor {
  cogsworthOwl,
  sprocketRabbit,
  tickerHedgehog,
  whistleMouse,
  gizmoFox,
  pistonCat,
  rivetBadger,
  boilerBear
}

class ClockworkQuestGame {
  final String id;
  final DateTime startedAt;
  final int maxDartsPerTurn;

  // Game options (Section 7 of spec)
  final bool includeBullseye; // Include bullseye as 21st target
  final bool speedMode; // hit any gear in any order
  final int numberOfLaps; // 1-5 laps around the clock

  // Players
  final List<String> playerIds;
  final Map<String, ClockworkInventor> inventorAssignments;

  // Runtime state
  ClockworkQuestGameState state;
  int currentPlayerIndex;

  // Per-player progress: playerId -> current target number (1-20 or 1-21 with bullseye)
  Map<String, int> currentTarget;
  // Per-player laps completed
  Map<String, int> lapsCompleted;

  // Per-turn tracking
  Map<String, int> dartsThrown;
  Map<String, List<String>> currentTurnDarts;

  // Per-dart tracking for UI/announcements
  Map<String, List<bool>> dartThrowHitTarget; // Did dart hit current target?
  Map<String, List<int>> dartThrowScoreValue; // Actual score value
  Map<String, List<int>> dartThrowMultiplier; // 1=single, 2=double, 3=triple
  Map<String, List<int>> dartThrowTargetNumber; // Which target they were aiming for
  Map<String, List<bool>> dartThrowAdvanced; // Did this dart advance the target?
  Map<String, List<bool>> dartThrowCompletedLap; // Did this dart complete a lap?

  // Lifetime stats
  Map<String, int> totalDartsThrown;
  Map<String, int> totalTurns;

  // Winner
  String? winnerId;

  // Speed mode: per-player list of gear numbers activated this lap
  Map<String, List<int>> completedTargets;
  Map<String, List<int>> turnStartCompletedTargets; // For edit score restoration

  // Turn start snapshots for edit score
  Map<String, int> turnStartCurrentTarget;
  Map<String, int> turnStartLapsCompleted;
  ClockworkQuestGameState turnStartState;
  String? turnStartWinnerId;

  ClockworkQuestGame({
    required this.id,
    required this.startedAt,
    required this.maxDartsPerTurn,
    required this.includeBullseye,
    required this.speedMode,
    required this.numberOfLaps,
    required this.playerIds,
    required this.inventorAssignments,
    this.state = ClockworkQuestGameState.setup,
    this.currentPlayerIndex = 0,
    Map<String, int>? currentTarget,
    Map<String, int>? lapsCompleted,
    Map<String, int>? dartsThrown,
    Map<String, List<String>>? currentTurnDarts,
    Map<String, List<bool>>? dartThrowHitTarget,
    Map<String, List<int>>? dartThrowScoreValue,
    Map<String, List<int>>? dartThrowMultiplier,
    Map<String, List<int>>? dartThrowTargetNumber,
    Map<String, List<bool>>? dartThrowAdvanced,
    Map<String, List<bool>>? dartThrowCompletedLap,
    Map<String, int>? totalDartsThrown,
    Map<String, int>? totalTurns,
    this.winnerId,
    Map<String, List<int>>? completedTargets,
    Map<String, List<int>>? turnStartCompletedTargets,
    Map<String, int>? turnStartCurrentTarget,
    Map<String, int>? turnStartLapsCompleted,
    this.turnStartState = ClockworkQuestGameState.setup,
    this.turnStartWinnerId,
  })  : currentTarget = currentTarget ?? {},
        lapsCompleted = lapsCompleted ?? {},
        dartsThrown = dartsThrown ?? {},
        currentTurnDarts = currentTurnDarts ?? {},
        dartThrowHitTarget = dartThrowHitTarget ?? {},
        dartThrowScoreValue = dartThrowScoreValue ?? {},
        dartThrowMultiplier = dartThrowMultiplier ?? {},
        dartThrowTargetNumber = dartThrowTargetNumber ?? {},
        dartThrowAdvanced = dartThrowAdvanced ?? {},
        dartThrowCompletedLap = dartThrowCompletedLap ?? {},
        totalDartsThrown = totalDartsThrown ?? {},
        totalTurns = totalTurns ?? {},
        completedTargets = completedTargets ?? {},
        turnStartCompletedTargets = turnStartCompletedTargets ?? {},
        turnStartCurrentTarget = turnStartCurrentTarget ?? {},
        turnStartLapsCompleted = turnStartLapsCompleted ?? {} {
    // Initialize player tracking
    for (String playerId in playerIds) {
      this.currentTarget.putIfAbsent(playerId, () => 1);
      this.lapsCompleted.putIfAbsent(playerId, () => 0);
      this.dartsThrown.putIfAbsent(playerId, () => 0);
      this.currentTurnDarts.putIfAbsent(playerId, () => []);
      this.dartThrowHitTarget.putIfAbsent(playerId, () => []);
      this.dartThrowScoreValue.putIfAbsent(playerId, () => []);
      this.dartThrowMultiplier.putIfAbsent(playerId, () => []);
      this.dartThrowTargetNumber.putIfAbsent(playerId, () => []);
      this.dartThrowAdvanced.putIfAbsent(playerId, () => []);
      this.dartThrowCompletedLap.putIfAbsent(playerId, () => []);
      this.totalDartsThrown.putIfAbsent(playerId, () => 0);
      this.totalTurns.putIfAbsent(playerId, () => 0);
      this.completedTargets.putIfAbsent(playerId, () => []);
      this.turnStartCompletedTargets.putIfAbsent(playerId, () => []);
      this.turnStartCurrentTarget.putIfAbsent(playerId, () => 1);
      this.turnStartLapsCompleted.putIfAbsent(playerId, () => 0);
    }
  }

  String get currentPlayerId => playerIds[currentPlayerIndex];

  int get maxTarget => includeBullseye ? 21 : 20;

  bool get isGameOver => winnerId != null;

  /// Creates a deep copy of the game for testing purposes
  ClockworkQuestGame copyWith({
    String? id,
    DateTime? startedAt,
    int? maxDartsPerTurn,
    bool? includeBullseye,
    bool? speedMode,
    int? numberOfLaps,
    List<String>? playerIds,
    Map<String, ClockworkInventor>? inventorAssignments,
    ClockworkQuestGameState? state,
    int? currentPlayerIndex,
    Map<String, int>? currentTarget,
    Map<String, int>? lapsCompleted,
    Map<String, int>? dartsThrown,
    Map<String, List<String>>? currentTurnDarts,
    Map<String, List<bool>>? dartThrowHitTarget,
    Map<String, List<int>>? dartThrowScoreValue,
    Map<String, List<int>>? dartThrowMultiplier,
    Map<String, List<int>>? dartThrowTargetNumber,
    Map<String, List<bool>>? dartThrowAdvanced,
    Map<String, List<bool>>? dartThrowCompletedLap,
    Map<String, int>? totalDartsThrown,
    Map<String, int>? totalTurns,
    String? winnerId,
    Map<String, List<int>>? completedTargets,
    Map<String, List<int>>? turnStartCompletedTargets,
    Map<String, int>? turnStartCurrentTarget,
    Map<String, int>? turnStartLapsCompleted,
    ClockworkQuestGameState? turnStartState,
    String? turnStartWinnerId,
  }) {
    return ClockworkQuestGame(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      maxDartsPerTurn: maxDartsPerTurn ?? this.maxDartsPerTurn,
      includeBullseye: includeBullseye ?? this.includeBullseye,
      speedMode: speedMode ?? this.speedMode,
      numberOfLaps: numberOfLaps ?? this.numberOfLaps,
      playerIds: playerIds ?? List.from(this.playerIds),
      inventorAssignments:
          inventorAssignments ?? Map.from(this.inventorAssignments),
      state: state ?? this.state,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      currentTarget: currentTarget ?? Map.from(this.currentTarget),
      lapsCompleted: lapsCompleted ?? Map.from(this.lapsCompleted),
      dartsThrown: dartsThrown ?? Map.from(this.dartsThrown),
      currentTurnDarts: currentTurnDarts ??
          this.currentTurnDarts.map((k, v) => MapEntry(k, List.from(v))),
      dartThrowHitTarget: dartThrowHitTarget ??
          this.dartThrowHitTarget.map((k, v) => MapEntry(k, List.from(v))),
      dartThrowScoreValue: dartThrowScoreValue ??
          this.dartThrowScoreValue.map((k, v) => MapEntry(k, List.from(v))),
      dartThrowMultiplier: dartThrowMultiplier ??
          this.dartThrowMultiplier.map((k, v) => MapEntry(k, List.from(v))),
      dartThrowTargetNumber: dartThrowTargetNumber ??
          this.dartThrowTargetNumber.map((k, v) => MapEntry(k, List.from(v))),
      dartThrowAdvanced: dartThrowAdvanced ??
          this.dartThrowAdvanced.map((k, v) => MapEntry(k, List.from(v))),
      dartThrowCompletedLap: dartThrowCompletedLap ??
          this.dartThrowCompletedLap.map((k, v) => MapEntry(k, List.from(v))),
      totalDartsThrown: totalDartsThrown ?? Map.from(this.totalDartsThrown),
      totalTurns: totalTurns ?? Map.from(this.totalTurns),
      winnerId: winnerId ?? this.winnerId,
      completedTargets: completedTargets ??
          this.completedTargets.map((k, v) => MapEntry(k, List.from(v))),
      turnStartCompletedTargets: turnStartCompletedTargets ??
          this.turnStartCompletedTargets.map((k, v) => MapEntry(k, List.from(v))),
      turnStartCurrentTarget:
          turnStartCurrentTarget ?? Map.from(this.turnStartCurrentTarget),
      turnStartLapsCompleted:
          turnStartLapsCompleted ?? Map.from(this.turnStartLapsCompleted),
      turnStartState: turnStartState ?? this.turnStartState,
      turnStartWinnerId: turnStartWinnerId ?? this.turnStartWinnerId,
    );
  }

  /// Serialization methods for save/resume functionality
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'maxDartsPerTurn': maxDartsPerTurn,
      'includeBullseye': includeBullseye,
      'speedMode': speedMode,
      'numberOfLaps': numberOfLaps,
      'playerIds': playerIds,
      'inventorAssignments': inventorAssignments
          .map((key, value) => MapEntry(key, value.toString().split('.').last)),
      'state': state.toString().split('.').last,
      'currentPlayerIndex': currentPlayerIndex,
      'currentTarget': currentTarget,
      'lapsCompleted': lapsCompleted,
      'dartsThrown': dartsThrown,
      'currentTurnDarts': currentTurnDarts,
      'dartThrowHitTarget': dartThrowHitTarget,
      'dartThrowScoreValue': dartThrowScoreValue,
      'dartThrowMultiplier': dartThrowMultiplier,
      'dartThrowTargetNumber': dartThrowTargetNumber,
      'dartThrowAdvanced': dartThrowAdvanced,
      'dartThrowCompletedLap': dartThrowCompletedLap,
      'totalDartsThrown': totalDartsThrown,
      'totalTurns': totalTurns,
      'winnerId': winnerId,
      'completedTargets': completedTargets,
      'turnStartCompletedTargets': turnStartCompletedTargets,
      'turnStartCurrentTarget': turnStartCurrentTarget,
      'turnStartLapsCompleted': turnStartLapsCompleted,
      'turnStartState': turnStartState.toString().split('.').last,
      'turnStartWinnerId': turnStartWinnerId,
    };
  }

  factory ClockworkQuestGame.fromJson(Map<String, dynamic> json) {
    return ClockworkQuestGame(
      id: json['id'],
      startedAt: DateTime.parse(json['startedAt']),
      maxDartsPerTurn: json['maxDartsPerTurn'],
      includeBullseye: json['includeBullseye'],
      speedMode: json['speedMode'],
      numberOfLaps: json['numberOfLaps'],
      playerIds: List<String>.from(json['playerIds']),
      inventorAssignments: (json['inventorAssignments'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(
              key,
              ClockworkInventor.values
                  .firstWhere((e) => e.toString().split('.').last == value))),
      state: ClockworkQuestGameState.values.firstWhere(
          (e) => e.toString().split('.').last == json['state']),
      currentPlayerIndex: json['currentPlayerIndex'],
      currentTarget: Map<String, int>.from(json['currentTarget']),
      lapsCompleted: Map<String, int>.from(json['lapsCompleted']),
      dartsThrown: Map<String, int>.from(json['dartsThrown']),
      currentTurnDarts: (json['currentTurnDarts'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, List<String>.from(value))),
      dartThrowHitTarget: (json['dartThrowHitTarget'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, List<bool>.from(value))),
      dartThrowScoreValue: (json['dartThrowScoreValue'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, List<int>.from(value))),
      dartThrowMultiplier: (json['dartThrowMultiplier'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, List<int>.from(value))),
      dartThrowTargetNumber:
          (json['dartThrowTargetNumber'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, List<int>.from(value))),
      dartThrowAdvanced: (json['dartThrowAdvanced'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, List<bool>.from(value))),
      dartThrowCompletedLap:
          (json['dartThrowCompletedLap'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, List<bool>.from(value))),
      totalDartsThrown: Map<String, int>.from(json['totalDartsThrown']),
      totalTurns: Map<String, int>.from(json['totalTurns']),
      winnerId: json['winnerId'],
      completedTargets: json['completedTargets'] != null
          ? (json['completedTargets'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, List<int>.from(value)))
          : null,
      turnStartCompletedTargets: json['turnStartCompletedTargets'] != null
          ? (json['turnStartCompletedTargets'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, List<int>.from(value)))
          : null,
      turnStartCurrentTarget:
          Map<String, int>.from(json['turnStartCurrentTarget']),
      turnStartLapsCompleted:
          Map<String, int>.from(json['turnStartLapsCompleted']),
      turnStartState: ClockworkQuestGameState.values.firstWhere(
          (e) => e.toString().split('.').last == json['turnStartState']),
      turnStartWinnerId: json['turnStartWinnerId'],
    );
  }
}
