import 'package:uuid/uuid.dart';

// ─── Game State Enum ──────────────────────────────────────────────────────────

enum GladiatorArenaGameState { setup, playing, finished }

// ─── GladiatorArenaGame ───────────────────────────────────────────────────────

class GladiatorArenaGame {
  // --- Identity ---
  final String id;
  final DateTime startedAt;
  DateTime? endedAt;

  // --- Players ---
  final List<String> playerIds;

  // --- Options (immutable for game's life) ---

  /// OPTION: targetScore — integer, range 100–500, step 25, default 200
  final int targetScore;

  /// OPTION: doubleFinishEnabled — boolean, default true
  final bool doubleFinishEnabled;

  /// OPTION: shieldRoundEnabled — boolean, default false
  final bool shieldRoundEnabled;

  /// OPTION: speedPlayEnabled — boolean, default false
  final bool speedPlayEnabled;

  // --- Runtime state (mutable) ---

  GladiatorArenaGameState state;

  /// Index into [playerIds] for the current active player.
  int currentPlayerIndex;

  String? winnerId;

  /// Glory Points per player. Starts at 0, updated at turn end.
  Map<String, int> scores;

  /// Darts thrown this turn per player (0–3, resets at turn advance).
  Map<String, int> dartsThrown;

  /// Cumulative darts thrown across all turns per player.
  Map<String, int> totalDartsThrown;

  /// Total turns taken per player (incremented on the FIRST dart of each turn).
  Map<String, int> totalTurns;

  /// Calculated dart point values for the current turn (e.g. [20, 40, 0]).
  /// Pattern A: screen renders D1/D2/D3 from these values.
  Map<String, List<int>> currentTurnDartValues;

  /// Raw segment strings for the current turn (e.g. ['S20', 'D20', 'Miss']).
  /// MANDATORY per skill build decisions — used by the Edit Score dialog.
  Map<String, List<String>> currentTurnDartSegments;

  /// Count of opponents knocked off (score reset) by each player (game-stat).
  Map<String, int> knockoffsDealt;

  /// Count of times each player was knocked off (game-stat).
  Map<String, int> knockoffsReceived;

  /// 1-indexed round counter. Increments when all players complete a turn.
  int round;

  /// Most recent knockoff victim (for Elimination Zone display).
  String? lastKnockoffVictimId;

  /// Most recent knockoff attacker.
  String? lastKnockoffAttackerId;

  /// When the last knockoff occurred (for 5-second auto-fade in UI).
  DateTime? lastKnockoffAt;

  /// Seconds remaining on the current Speed Play turn timer.
  /// Null when timer is not running (speedPlayEnabled=false or between turns).
  int? speedPlayTimeRemaining;

  /// Maps each playerId to their assigned character image asset path.
  /// Populated by the menu screen's startGame() using a randomised shuffle
  /// of the 8 character paths; persists through game-screen and results-screen.
  Map<String, String> playerCharacterPaths;

  // ─── Constructor ─────────────────────────────────────────────────────────────

  GladiatorArenaGame({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.playerIds,
    required this.targetScore,
    required this.doubleFinishEnabled,
    required this.shieldRoundEnabled,
    required this.speedPlayEnabled,
    this.state = GladiatorArenaGameState.playing,
    this.currentPlayerIndex = 0,
    this.winnerId,
    Map<String, int>? scores,
    Map<String, int>? dartsThrown,
    Map<String, int>? totalDartsThrown,
    Map<String, int>? totalTurns,
    Map<String, List<int>>? currentTurnDartValues,
    Map<String, List<String>>? currentTurnDartSegments,
    Map<String, int>? knockoffsDealt,
    Map<String, int>? knockoffsReceived,
    this.round = 1,
    this.lastKnockoffVictimId,
    this.lastKnockoffAttackerId,
    this.lastKnockoffAt,
    this.speedPlayTimeRemaining,
    Map<String, String>? playerCharacterPaths,
  })  : playerCharacterPaths = playerCharacterPaths ?? {},
        scores = scores ?? {},
        dartsThrown = dartsThrown ?? {},
        totalDartsThrown = totalDartsThrown ?? {},
        totalTurns = totalTurns ?? {},
        currentTurnDartValues = currentTurnDartValues ?? {},
        currentTurnDartSegments = currentTurnDartSegments ?? {},
        knockoffsDealt = knockoffsDealt ?? {},
        knockoffsReceived = knockoffsReceived ?? {} {
    // Initialize per-player maps for any players not yet present.
    for (final playerId in playerIds) {
      this.scores[playerId] ??= 0;
      this.dartsThrown[playerId] ??= 0;
      this.totalDartsThrown[playerId] ??= 0;
      this.totalTurns[playerId] ??= 0;
      this.currentTurnDartValues[playerId] ??= [];
      this.currentTurnDartSegments[playerId] ??= [];
      this.knockoffsDealt[playerId] ??= 0;
      this.knockoffsReceived[playerId] ??= 0;
    }
  }

  // ─── Static Factory ──────────────────────────────────────────────────────────

  factory GladiatorArenaGame.create({
    required List<String> playerIds,
    required int targetScore,
    required bool doubleFinishEnabled,
    required bool shieldRoundEnabled,
    required bool speedPlayEnabled,
    Map<String, String>? playerCharacterPaths,
  }) {
    return GladiatorArenaGame(
      id: const Uuid().v4(),
      startedAt: DateTime.now(),
      playerIds: playerIds,
      targetScore: targetScore,
      doubleFinishEnabled: doubleFinishEnabled,
      shieldRoundEnabled: shieldRoundEnabled,
      speedPlayEnabled: speedPlayEnabled,
      state: GladiatorArenaGameState.playing,
      currentPlayerIndex: 0,
      scores: {for (final id in playerIds) id: 0},
      dartsThrown: {for (final id in playerIds) id: 0},
      totalDartsThrown: {for (final id in playerIds) id: 0},
      totalTurns: {for (final id in playerIds) id: 0},
      currentTurnDartValues: {for (final id in playerIds) id: []},
      currentTurnDartSegments: {for (final id in playerIds) id: []},
      knockoffsDealt: {for (final id in playerIds) id: 0},
      knockoffsReceived: {for (final id in playerIds) id: 0},
      round: 1,
      playerCharacterPaths: playerCharacterPaths ?? {},
    );
  }

  // ─── Computed Properties ─────────────────────────────────────────────────────

  /// Emulator-only override: when non-null, forces isShieldRound on or off.
  bool? shieldRoundOverride;

  /// True when it is a shield round: option must be ON and round divisible by 5.
  /// Emulator override takes precedence when set.
  bool get isShieldRound =>
      shieldRoundOverride ?? (shieldRoundEnabled && round % 5 == 0);

  String get currentPlayerId => playerIds[currentPlayerIndex];

  // ─── Serialization ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'playerIds': playerIds,
      'targetScore': targetScore,
      'doubleFinishEnabled': doubleFinishEnabled,
      'shieldRoundEnabled': shieldRoundEnabled,
      'speedPlayEnabled': speedPlayEnabled,
      'state': state.name,
      'currentPlayerIndex': currentPlayerIndex,
      'winnerId': winnerId,
      'scores': scores,
      'dartsThrown': dartsThrown,
      'totalDartsThrown': totalDartsThrown,
      'totalTurns': totalTurns,
      'currentTurnDartValues': currentTurnDartValues.map(
        (k, v) => MapEntry(k, List<int>.from(v)),
      ),
      'currentTurnDartSegments': currentTurnDartSegments.map(
        (k, v) => MapEntry(k, List<String>.from(v)),
      ),
      'knockoffsDealt': knockoffsDealt,
      'knockoffsReceived': knockoffsReceived,
      'round': round,
      'lastKnockoffVictimId': lastKnockoffVictimId,
      'lastKnockoffAttackerId': lastKnockoffAttackerId,
      'lastKnockoffAt': lastKnockoffAt?.toIso8601String(),
      'speedPlayTimeRemaining': speedPlayTimeRemaining,
      'playerCharacterPaths': playerCharacterPaths,
    };
  }

  factory GladiatorArenaGame.fromJson(Map<String, dynamic> json) {
    final playerIds = List<String>.from(json['playerIds'] as List);

    Map<String, int> toIntMap(dynamic raw) {
      if (raw == null) return {};
      return Map<String, int>.from(raw as Map);
    }

    Map<String, List<int>> toListIntMap(dynamic raw) {
      if (raw == null) return {};
      return (raw as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, List<int>.from(v as List)),
      );
    }

    Map<String, List<String>> toListStringMap(dynamic raw) {
      if (raw == null) return {};
      return (raw as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, List<String>.from(v as List)),
      );
    }

    return GladiatorArenaGame(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      playerIds: playerIds,
      targetScore: json['targetScore'] as int,
      doubleFinishEnabled: json['doubleFinishEnabled'] as bool,
      shieldRoundEnabled: json['shieldRoundEnabled'] as bool,
      speedPlayEnabled: json['speedPlayEnabled'] as bool,
      state: GladiatorArenaGameState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => GladiatorArenaGameState.playing,
      ),
      currentPlayerIndex: json['currentPlayerIndex'] as int,
      winnerId: json['winnerId'] as String?,
      scores: toIntMap(json['scores']),
      dartsThrown: toIntMap(json['dartsThrown']),
      totalDartsThrown: toIntMap(json['totalDartsThrown']),
      totalTurns: toIntMap(json['totalTurns']),
      currentTurnDartValues: toListIntMap(json['currentTurnDartValues']),
      currentTurnDartSegments:
          toListStringMap(json['currentTurnDartSegments']),
      knockoffsDealt: toIntMap(json['knockoffsDealt']),
      knockoffsReceived: toIntMap(json['knockoffsReceived']),
      round: json['round'] as int? ?? 1,
      lastKnockoffVictimId: json['lastKnockoffVictimId'] as String?,
      lastKnockoffAttackerId: json['lastKnockoffAttackerId'] as String?,
      lastKnockoffAt: json['lastKnockoffAt'] != null
          ? DateTime.parse(json['lastKnockoffAt'] as String)
          : null,
      speedPlayTimeRemaining: json['speedPlayTimeRemaining'] as int?,
      playerCharacterPaths: json['playerCharacterPaths'] != null
          ? Map<String, String>.from(
              json['playerCharacterPaths'] as Map<dynamic, dynamic>)
          : {},
    );
  }
}
