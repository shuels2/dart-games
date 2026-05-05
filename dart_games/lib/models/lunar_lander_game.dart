import 'dart:math';
import 'package:uuid/uuid.dart';
import 'player.dart';

// ─── Character Enum ──────────────────────────────────────────────────────────

enum LunarLanderCharacter {
  spaceDog,
  moonCat,
  rocketPenguin,
  orbitOwl,
  nebulaFox,
  cometRabbit,
  astroBear,
  starfishHamster;

  String get assetPath {
    switch (this) {
      case LunarLanderCharacter.spaceDog:
        return 'assets/games/lunar_lander/characters/SpaceDog.png';
      case LunarLanderCharacter.moonCat:
        return 'assets/games/lunar_lander/characters/MoonCat.png';
      case LunarLanderCharacter.rocketPenguin:
        return 'assets/games/lunar_lander/characters/RocketPenguin.png';
      case LunarLanderCharacter.orbitOwl:
        return 'assets/games/lunar_lander/characters/OrbitOwl.png';
      case LunarLanderCharacter.nebulaFox:
        return 'assets/games/lunar_lander/characters/NebulaFox.png';
      case LunarLanderCharacter.cometRabbit:
        return 'assets/games/lunar_lander/characters/CometRabbit.png';
      case LunarLanderCharacter.astroBear:
        return 'assets/games/lunar_lander/characters/AstroBear.png';
      case LunarLanderCharacter.starfishHamster:
        return 'assets/games/lunar_lander/characters/StarfishHamster.png';
    }
  }

  String get displayName {
    switch (this) {
      case LunarLanderCharacter.spaceDog:
        return 'Space Dog';
      case LunarLanderCharacter.moonCat:
        return 'Moon Cat';
      case LunarLanderCharacter.rocketPenguin:
        return 'Rocket Penguin';
      case LunarLanderCharacter.orbitOwl:
        return 'Orbit Owl';
      case LunarLanderCharacter.nebulaFox:
        return 'Nebula Fox';
      case LunarLanderCharacter.cometRabbit:
        return 'Comet Rabbit';
      case LunarLanderCharacter.astroBear:
        return 'Astro Bear';
      case LunarLanderCharacter.starfishHamster:
        return 'Starfish Hamster';
    }
  }
}

// ─── Game State Enum ─────────────────────────────────────────────────────────

enum LunarLanderGameState { playing, finished }

// ─── LunarLanderGame ─────────────────────────────────────────────────────────

class LunarLanderGame {
  // --- Configuration (immutable for game's life) ---
  final String id;
  final DateTime startedAt;
  final int maxDartsPerTurn;

  /// OPTION: startingAltitude — integer, range 100–500, step 10, default 200
  final int startingAltitude;

  /// OPTION: hardLandingEnabled — boolean, default false
  final bool hardLandingEnabled;

  final List<String> playerIds;
  final Map<String, LunarLanderCharacter> characterAssignments;

  // --- Runtime state (mutable) ---

  /// Current altitude for each player (starts at startingAltitude).
  Map<String, int> currentAltitudes;

  LunarLanderGameState state;
  int currentPlayerIndex;
  String? winnerId;

  /// Darts thrown this turn per player.
  Map<String, int> dartsThrown;

  /// Cumulative darts thrown across all turns per player.
  Map<String, int> totalDartsThrown;

  /// Total turns taken per player.
  Map<String, int> totalTurns;

  /// Dart scores recorded this turn per player (face_value × multiplier each).
  Map<String, List<int>> currentTurnDartScores;

  /// Whether each dart in the current turn caused a bust (Hard Landing ON).
  Map<String, List<bool>> dartThrowWasBust;

  /// Raw sector strings for each dart this turn (e.g., 'S20', 'D20', 'Bull', 'Miss').
  Map<String, List<String>> currentTurnDartSegments;

  /// Altitude at the start of the current turn per player (for Hard Landing revert).
  Map<String, int> turnStartAltitude;

  /// currentPlayerIndex at start of turn (for edit score revert).
  int? turnStartCurrentPlayerIndex;

  /// Game state at start of turn.
  LunarLanderGameState turnStartState;

  /// winnerId at start of turn.
  String? turnStartWinnerId;

  // ─── Constructor ────────────────────────────────────────────────────────────

  LunarLanderGame({
    required this.id,
    required this.startedAt,
    this.maxDartsPerTurn = 3,
    required this.startingAltitude,
    required this.hardLandingEnabled,
    required this.playerIds,
    required this.characterAssignments,
    Map<String, int>? currentAltitudes,
    this.state = LunarLanderGameState.playing,
    this.currentPlayerIndex = 0,
    this.winnerId,
    Map<String, int>? dartsThrown,
    Map<String, int>? totalDartsThrown,
    Map<String, int>? totalTurns,
    Map<String, List<int>>? currentTurnDartScores,
    Map<String, List<bool>>? dartThrowWasBust,
    Map<String, List<String>>? currentTurnDartSegments,
    Map<String, int>? turnStartAltitude,
    int? turnStartCurrentPlayerIndex,
    LunarLanderGameState? turnStartState,
    String? turnStartWinnerId,
  })  : currentAltitudes = currentAltitudes ?? {},
        dartsThrown = dartsThrown ?? {},
        totalDartsThrown = totalDartsThrown ?? {},
        totalTurns = totalTurns ?? {},
        currentTurnDartScores = currentTurnDartScores ?? {},
        dartThrowWasBust = dartThrowWasBust ?? {},
        currentTurnDartSegments = currentTurnDartSegments ?? {},
        turnStartAltitude = turnStartAltitude ?? {},
        turnStartCurrentPlayerIndex = turnStartCurrentPlayerIndex,
        turnStartState =
            turnStartState ?? LunarLanderGameState.playing,
        turnStartWinnerId = turnStartWinnerId {
    // Initialize per-player maps for any players not yet present.
    for (final playerId in playerIds) {
      this.currentAltitudes[playerId] ??= startingAltitude;
      this.dartsThrown[playerId] ??= 0;
      this.totalDartsThrown[playerId] ??= 0;
      this.totalTurns[playerId] ??= 0;
      this.currentTurnDartScores[playerId] ??= [];
      this.dartThrowWasBust[playerId] ??= [];
      this.currentTurnDartSegments[playerId] ??= [];
      this.turnStartAltitude[playerId] ??= startingAltitude;
    }
  }

  // ─── Static Factory ──────────────────────────────────────────────────────────

  factory LunarLanderGame.create({
    required List<String> playerIds,
    required int startingAltitude,
    required bool hardLandingEnabled,
  }) {
    final random = Random();

    // Assign characters (unique per player) — Reef Royale shuffle pattern
    final available = List<LunarLanderCharacter>.from(
        LunarLanderCharacter.values)
      ..shuffle(random);
    final characterAssignments = <String, LunarLanderCharacter>{};
    for (int i = 0; i < playerIds.length; i++) {
      // With 8 characters and max 8 players the mod is just a safety guard.
      characterAssignments[playerIds[i]] =
          available[i % available.length];
    }

    final altitudes = <String, int>{};
    final turnStartAlt = <String, int>{};
    for (final id in playerIds) {
      altitudes[id] = startingAltitude;
      turnStartAlt[id] = startingAltitude;
    }

    return LunarLanderGame(
      id: const Uuid().v4(),
      startedAt: DateTime.now(),
      maxDartsPerTurn: 3,
      startingAltitude: startingAltitude,
      hardLandingEnabled: hardLandingEnabled,
      playerIds: playerIds,
      characterAssignments: characterAssignments,
      currentAltitudes: altitudes,
      state: LunarLanderGameState.playing,
      currentPlayerIndex: 0,
      dartsThrown: {for (final id in playerIds) id: 0},
      totalDartsThrown: {for (final id in playerIds) id: 0},
      totalTurns: {for (final id in playerIds) id: 0},
      currentTurnDartScores: {for (final id in playerIds) id: []},
      dartThrowWasBust: {for (final id in playerIds) id: []},
      currentTurnDartSegments: {for (final id in playerIds) id: []},
      turnStartAltitude: turnStartAlt,
      turnStartCurrentPlayerIndex: 0,
      turnStartState: LunarLanderGameState.playing,
      turnStartWinnerId: null,
    );
  }

  // ─── Accessors ───────────────────────────────────────────────────────────────

  String getCurrentPlayerId() => playerIds[currentPlayerIndex];

  Player getCurrentPlayer(List<Player> players) {
    final id = getCurrentPlayerId();
    return players.firstWhere((p) => p.id == id);
  }

  int getCurrentPlayerDartsThrown() {
    return dartsThrown[getCurrentPlayerId()] ?? 0;
  }

  List<int> getCurrentTurnDartScores(String playerId) {
    return currentTurnDartScores[playerId] ?? [];
  }

  List<bool> getDartThrowWasBust(String playerId) {
    return dartThrowWasBust[playerId] ?? [];
  }

  List<String> getCurrentTurnDartSegments(String playerId) {
    return currentTurnDartSegments[playerId] ?? [];
  }

  int getCurrentAltitude(String playerId) {
    return currentAltitudes[playerId] ?? startingAltitude;
  }

  LunarLanderCharacter? getCharacter(String playerId) {
    return characterAssignments[playerId];
  }

  bool hasWinner() => winnerId != null;

  Player? getWinner(List<Player> players) {
    if (winnerId == null) return null;
    try {
      return players.firstWhere((p) => p.id == winnerId);
    } catch (_) {
      return null;
    }
  }

  /// True when player's altitude is exactly 0 (successful landing).
  bool isPlayerLanded(String playerId) =>
      currentAltitudes[playerId] == 0;

  /// True when player's altitude is below 0 (overshoot, only possible when
  /// [hardLandingEnabled] is false).
  bool isPlayerBelowZero(String playerId) =>
      (currentAltitudes[playerId] ?? startingAltitude) < 0;

  /// Compute dart score value: score × multiplier.
  /// Bull (50) and outer-bull (25) are passed directly as score with multiplier 1.
  int dartScore({required int score, required int multiplier}) {
    return score * multiplier;
  }

  // ─── Turn State Snapshot (for edit score revert) ─────────────────────────────

  void saveTurnStartState() {
    for (final id in playerIds) {
      turnStartAltitude[id] = currentAltitudes[id] ?? startingAltitude;
    }
    turnStartCurrentPlayerIndex = currentPlayerIndex;
    turnStartState = state;
    turnStartWinnerId = winnerId;
  }

  void resetToStartOfTurn() {
    for (final id in playerIds) {
      currentAltitudes[id] = turnStartAltitude[id] ?? startingAltitude;
    }
    state = turnStartState;
    winnerId = turnStartWinnerId;
  }

  // ─── Advance Turn ────────────────────────────────────────────────────────────

  void advanceToNextPlayer() {
    final currentId = getCurrentPlayerId();

    // totalTurns is incremented in the provider on the FIRST dart of the turn
    // (matches Target Tag pattern). Do NOT increment here.

    // Reset per-turn tracking for current player
    dartsThrown[currentId] = 0;
    currentTurnDartScores[currentId] = [];
    dartThrowWasBust[currentId] = [];
    currentTurnDartSegments[currentId] = [];

    // Advance index
    currentPlayerIndex = (currentPlayerIndex + 1) % playerIds.length;

    // Snapshot new turn's start state
    saveTurnStartState();
  }

  // ─── Serialization ───────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'maxDartsPerTurn': maxDartsPerTurn,
      'startingAltitude': startingAltitude,
      'hardLandingEnabled': hardLandingEnabled,
      'playerIds': playerIds,
      'characterAssignments': characterAssignments.map(
        (k, v) => MapEntry(k, v.name),
      ),
      'currentAltitudes': currentAltitudes,
      'state': state.name,
      'currentPlayerIndex': currentPlayerIndex,
      'winnerId': winnerId,
      'dartsThrown': dartsThrown,
      'totalDartsThrown': totalDartsThrown,
      'totalTurns': totalTurns,
      'currentTurnDartScores': currentTurnDartScores.map(
        (k, v) => MapEntry(k, List<int>.from(v)),
      ),
      'dartThrowWasBust': dartThrowWasBust.map(
        (k, v) => MapEntry(k, List<bool>.from(v)),
      ),
      'currentTurnDartSegments': currentTurnDartSegments.map(
        (k, v) => MapEntry(k, List<String>.from(v)),
      ),
      'turnStartAltitude': turnStartAltitude,
      'turnStartCurrentPlayerIndex': turnStartCurrentPlayerIndex,
      'turnStartState': turnStartState.name,
      'turnStartWinnerId': turnStartWinnerId,
    };
  }

  factory LunarLanderGame.fromJson(Map<String, dynamic> json) {
    final playerIds = List<String>.from(json['playerIds']);

    final characterAssignments = <String, LunarLanderCharacter>{};
    final rawChars =
        json['characterAssignments'] as Map<String, dynamic>? ?? {};
    for (final entry in rawChars.entries) {
      characterAssignments[entry.key] = LunarLanderCharacter.values
          .firstWhere(
        (e) => e.name == entry.value,
        orElse: () => LunarLanderCharacter.spaceDog,
      );
    }

    Map<String, int> _toIntMap(dynamic raw) {
      if (raw == null) return {};
      return Map<String, int>.from(raw as Map);
    }

    Map<String, List<int>> _toListIntMap(dynamic raw) {
      if (raw == null) return {};
      return (raw as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, List<int>.from(v as List)),
      );
    }

    Map<String, List<bool>> _toListBoolMap(dynamic raw) {
      if (raw == null) return {};
      return (raw as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, List<bool>.from(v as List)),
      );
    }

    Map<String, List<String>> _toListStringMap(dynamic raw) {
      if (raw == null) return {};
      return (raw as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, List<String>.from(v as List)),
      );
    }

    return LunarLanderGame(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      maxDartsPerTurn: json['maxDartsPerTurn'] as int? ?? 3,
      startingAltitude: json['startingAltitude'] as int,
      hardLandingEnabled: json['hardLandingEnabled'] as bool,
      playerIds: playerIds,
      characterAssignments: characterAssignments,
      currentAltitudes: _toIntMap(json['currentAltitudes']),
      state: LunarLanderGameState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => LunarLanderGameState.playing,
      ),
      currentPlayerIndex: json['currentPlayerIndex'] as int,
      winnerId: json['winnerId'] as String?,
      dartsThrown: _toIntMap(json['dartsThrown']),
      totalDartsThrown: _toIntMap(json['totalDartsThrown']),
      totalTurns: _toIntMap(json['totalTurns']),
      currentTurnDartScores:
          _toListIntMap(json['currentTurnDartScores']),
      dartThrowWasBust: _toListBoolMap(json['dartThrowWasBust']),
      currentTurnDartSegments:
          _toListStringMap(json['currentTurnDartSegments']),
      turnStartAltitude: _toIntMap(json['turnStartAltitude']),
      turnStartCurrentPlayerIndex:
          json['turnStartCurrentPlayerIndex'] as int?,
      turnStartState: LunarLanderGameState.values.firstWhere(
        (e) => e.name == json['turnStartState'],
        orElse: () => LunarLanderGameState.playing,
      ),
      turnStartWinnerId: json['turnStartWinnerId'] as String?,
    );
  }
}
