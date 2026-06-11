import 'dart:math';
import 'package:uuid/uuid.dart';

// ─── Target sentinel constants ────────────────────────────────────────────────

/// Sentinel: "Any Double" round — any double segment scores number × 2.
const int kTargetAnyDouble = -1;

/// Sentinel: "Any Triple" round — any triple segment scores number × 3.
const int kTargetAnyTriple = -2;

/// Sentinel: Bull round — outer bull (25) or inner bull (50) scores 25 or 50.
const int kTargetBull = 25;

// ─── Enums ────────────────────────────────────────────────────────────────────

enum TreasureDivideGameMode { solo, team }

enum TreasureDivideTeamAssignment { random, manual }

enum TreasureDivideGameState { playing, finished }

// ─── Asset Constants ──────────────────────────────────────────────────────────

/// All 6 available team crest paths.
const _kAllCrestPaths = [
  'assets/games/treasure_divide/teams/CrossedCutlasses.png',
  'assets/games/treasure_divide/teams/GoldDoubloon.png',
  'assets/games/treasure_divide/teams/CompassRose.png',
  'assets/games/treasure_divide/teams/ShipsWheel.png',
  'assets/games/treasure_divide/teams/Anchor.png',
  'assets/games/treasure_divide/teams/Kraken.png',
];

/// Theme index → display name.
const Map<int, String> kThemeDisplayNames = {
  0: 'Captain',
  1: 'First Mate',
  2: 'Bosun',
  3: 'Navigator',
  4: 'Lookout',
  5: 'Cook',
  6: 'Gunner',
  7: 'Cabin Boy',
};

/// Theme index → list of accessory asset paths (2 or 3 accessories per theme).
const Map<int, List<String>> kThemeAccessoryPaths = {
  0: [
    'assets/games/treasure_divide/themes/captain/hat.png',
    'assets/games/treasure_divide/themes/captain/eyepatch.png',
    'assets/games/treasure_divide/themes/captain/parrot.png',
  ],
  1: [
    'assets/games/treasure_divide/themes/first_mate/bandana.png',
    'assets/games/treasure_divide/themes/first_mate/monkey.png',
  ],
  2: [
    'assets/games/treasure_divide/themes/bosun/tricorn.png',
    'assets/games/treasure_divide/themes/bosun/crab.png',
    'assets/games/treasure_divide/themes/bosun/scar.png',
  ],
  3: [
    'assets/games/treasure_divide/themes/navigator/sailor_cap.png',
    'assets/games/treasure_divide/themes/navigator/monocle.png',
    'assets/games/treasure_divide/themes/navigator/compass.png',
  ],
  4: [
    'assets/games/treasure_divide/themes/lookout/lookout_bandana.png',
    'assets/games/treasure_divide/themes/lookout/telescope.png',
  ],
  5: [
    'assets/games/treasure_divide/themes/cook/chef_hat.png',
    'assets/games/treasure_divide/themes/cook/neckerchief.png',
    'assets/games/treasure_divide/themes/cook/spoon.png',
  ],
  6: [
    'assets/games/treasure_divide/themes/gunner/floppy_hat.png',
    'assets/games/treasure_divide/themes/gunner/cannonball.png',
  ],
  7: [
    'assets/games/treasure_divide/themes/cabin_boy/tiny_cap.png',
    'assets/games/treasure_divide/themes/cabin_boy/seahorse.png',
    'assets/games/treasure_divide/themes/cabin_boy/freckles.png',
  ],
};

// ─── TreasureDivideGame ───────────────────────────────────────────────────────

class TreasureDivideGame {
  // --- Identity ---
  final String id;

  // --- Players ---
  final List<String> playerIds;

  // --- Options ---

  /// Number of rounds: 7, 9, or 12.
  final int numberOfRounds;

  /// When true, missing all darts divides by 4 instead of 2.
  final bool quarterItEnabled;

  /// When true, random numbers replace the standard target sequence.
  final bool customTargetsEnabled;

  /// Solo or Team mode.
  final TreasureDivideGameMode gameMode;

  /// Manual or Random team assignment (only meaningful in Team mode).
  final TreasureDivideTeamAssignment teamAssignment;

  /// Number of teams in Team mode (2-5). In Random mode this is derived from
  /// playerIds.length at game start. In Solo mode this is 1.
  final int teamCount;

  // --- Per-Game Randomization (locked at game-start) ---

  /// Length [teamCount] — crests selected from the 6 available at game start.
  final List<String> teamCrestPaths;

  /// Round-by-round target sequence (length = numberOfRounds).
  /// Number targets are 1-20; sentinels: kTargetAnyDouble = -1,
  /// kTargetAnyTriple = -2, kTargetBull = 25.
  final List<int> targetSequence;

  // --- Team Structure (frozen at game start) ---

  /// teamId → list of playerIds on that team.
  final Map<String, List<String>> teamPlayers;

  /// playerId → teamId (inverse lookup).
  final Map<String, String> playerTeamAssignments;

  // --- Pirate Theme Assignment ---

  /// playerId → theme index 0..7 (per-game shuffle).
  /// If >8 players, repeats are possible (second shuffled pass).
  final Map<String, int> playerPirateThemes;

  // --- Runtime State ---

  TreasureDivideGameState state;

  /// 0-based index of the current round. Game ends when == numberOfRounds.
  int currentRoundIndex;

  /// ID of the currently active player (within the current round + active crew).
  String currentPlayerId;

  /// Number of darts the current player has thrown this turn (0..dartsThisTurn).
  int dartsThrown;

  /// 0-based index of the currently active team (Team mode only).
  int currentTeamIndex;

  /// ID of the currently active team (Team mode only; null in Solo).
  String? activeTeamId;

  /// teamId → index of the next player to play within the current round.
  Map<String, int> teamWithinRoundRotationPointer;

  /// playerId → per-round haul list (length = numberOfRounds).
  /// Entry = int (sum of hits for that round), 0 (all missed / halved indicator
  /// stored separately), or null (not yet thrown).
  Map<String, List<int?>> playerRoundScores;

  /// playerId → raw dart segment strings for the CURRENT round only.
  /// Cleared when the player's turn advances to the next round.
  Map<String, List<String>> currentTurnDartSegments;

  /// Cumulative darts thrown per player across the whole game.
  Map<String, int> totalDartsThrown;

  /// Canonical turn counter: incremented exactly once per turn on first dart.
  Map<String, int> totalTurns;

  /// Number of times each player's score was halved/quartered (Solo + per-member).
  Map<String, int> timesHalvedPerPlayer;

  /// Number of times each crew's treasure was halved/quartered (Team only).
  Map<String, int> timesHalvedPerTeam;

  /// True once a turn-end condition fires (all darts thrown or skip). Resets to
  /// false after handleTakeoutFinished completes.
  bool shouldPromptTakeout;

  /// All tied winners (Solo). Single winner = list of 1; tied = list of N.
  /// Empty until game is finished.
  List<String> winnerIds;

  /// All tied winning crew IDs (Team). Single winner = list of 1; tied = list of N.
  /// Empty until game is finished.
  List<String> winnerTeamIds;

  DateTime? gameStartTime;
  DateTime? gameEndTime;

  // ─── Constructor ─────────────────────────────────────────────────────────────

  TreasureDivideGame({
    required this.id,
    required this.playerIds,
    required this.numberOfRounds,
    required this.quarterItEnabled,
    required this.customTargetsEnabled,
    required this.gameMode,
    required this.teamAssignment,
    required this.teamCount,
    required this.teamCrestPaths,
    required this.targetSequence,
    required this.teamPlayers,
    required this.playerTeamAssignments,
    required this.playerPirateThemes,
    this.state = TreasureDivideGameState.playing,
    this.currentRoundIndex = 0,
    required this.currentPlayerId,
    this.dartsThrown = 0,
    this.currentTeamIndex = 0,
    this.activeTeamId,
    Map<String, int>? teamWithinRoundRotationPointer,
    Map<String, List<int?>>? playerRoundScores,
    Map<String, List<String>>? currentTurnDartSegments,
    Map<String, int>? totalDartsThrown,
    Map<String, int>? totalTurns,
    Map<String, int>? timesHalvedPerPlayer,
    Map<String, int>? timesHalvedPerTeam,
    this.shouldPromptTakeout = false,
    List<String>? winnerIds,
    List<String>? winnerTeamIds,
    this.gameStartTime,
    this.gameEndTime,
  })  : teamWithinRoundRotationPointer = teamWithinRoundRotationPointer ??
            {for (final teamId in teamPlayers.keys) teamId: 0},
        playerRoundScores = playerRoundScores ??
            {for (final id in playerIds) id: List.filled(numberOfRounds, null)},
        currentTurnDartSegments =
            currentTurnDartSegments ?? {for (final id in playerIds) id: []},
        totalDartsThrown =
            totalDartsThrown ?? {for (final id in playerIds) id: 0},
        totalTurns = totalTurns ?? {for (final id in playerIds) id: 0},
        timesHalvedPerPlayer =
            timesHalvedPerPlayer ?? {for (final id in playerIds) id: 0},
        timesHalvedPerTeam = timesHalvedPerTeam ??
            {for (final teamId in teamPlayers.keys) teamId: 0},
        winnerIds = winnerIds ?? [],
        winnerTeamIds = winnerTeamIds ?? [];

  // ─── Factory: Create a new game ───────────────────────────────────────────────

  factory TreasureDivideGame.create({
    required List<String> playerIds,
    required int numberOfRounds,
    required bool quarterItEnabled,
    required bool customTargetsEnabled,
    required TreasureDivideGameMode gameMode,
    required TreasureDivideTeamAssignment teamAssignment,
    required int teamCount,
    required Map<String, List<String>> teamPlayers,
    required Map<String, String> playerTeamAssignments,
    Random? random,
  }) {
    final rng = random ?? Random();

    // --- teamCrestPaths: shuffle all 6 crests, take teamCount ---
    final shuffledCrests = List<String>.from(_kAllCrestPaths)..shuffle(rng);
    final crests = shuffledCrests.take(teamCount).toList();

    // --- targetSequence ---
    final sequence = customTargetsEnabled
        ? customSequenceFor(numberOfRounds, random: rng)
        : sequenceFor(numberOfRounds);

    // --- playerPirateThemes: shuffle [0..7], deal one per player ---
    final themes = <String, int>{};
    final baseThemes = List.generate(8, (i) => i)..shuffle(rng);
    for (int i = 0; i < playerIds.length; i++) {
      if (i < 8) {
        themes[playerIds[i]] = baseThemes[i];
      } else {
        // >8 players: second pass
        final overflow = List.generate(8, (j) => j)..shuffle(rng);
        themes[playerIds[i]] = overflow[i % 8];
      }
    }

    // In team mode, the starting player MUST be a member of team_1 (the active
    // crew at game start). Using unshuffled playerIds[0] is wrong because
    // teams are randomly assigned — playerIds[0] is often in team_2/3/etc.
    // Without this, the first dart of a team game is attributed to the wrong
    // crew. In solo mode the unshuffled order is correct.
    final firstTeamId =
        gameMode == TreasureDivideGameMode.team && teamPlayers.isNotEmpty
            ? teamPlayers.keys.first
            : null;
    final firstPlayer = firstTeamId != null
        ? (teamPlayers[firstTeamId]?.isNotEmpty == true
            ? teamPlayers[firstTeamId]!.first
            : (playerIds.isNotEmpty ? playerIds.first : ''))
        : (playerIds.isNotEmpty ? playerIds.first : '');

    return TreasureDivideGame(
      id: const Uuid().v4(),
      playerIds: playerIds,
      numberOfRounds: numberOfRounds,
      quarterItEnabled: quarterItEnabled,
      customTargetsEnabled: customTargetsEnabled,
      gameMode: gameMode,
      teamAssignment: teamAssignment,
      teamCount: teamCount,
      teamCrestPaths: crests,
      targetSequence: sequence,
      teamPlayers: teamPlayers,
      playerTeamAssignments: playerTeamAssignments,
      playerPirateThemes: themes,
      state: TreasureDivideGameState.playing,
      currentRoundIndex: 0,
      currentPlayerId: firstPlayer,
      dartsThrown: 0,
      currentTeamIndex: 0,
      activeTeamId: firstTeamId,
      teamWithinRoundRotationPointer: {
        for (final teamId in teamPlayers.keys) teamId: 0
      },
      playerRoundScores: {
        for (final id in playerIds) id: List.filled(numberOfRounds, null)
      },
      currentTurnDartSegments: {for (final id in playerIds) id: []},
      totalDartsThrown: {for (final id in playerIds) id: 0},
      totalTurns: {for (final id in playerIds) id: 0},
      timesHalvedPerPlayer: {for (final id in playerIds) id: 0},
      timesHalvedPerTeam: {
        for (final teamId in teamPlayers.keys) teamId: 0
      },
      winnerIds: [],
      winnerTeamIds: [],
      gameStartTime: DateTime.now(),
    );
  }

  // ─── Target Sequence Builders ─────────────────────────────────────────────────

  /// Returns the standard (non-custom) target sequence for the given round count.
  ///
  /// 7 rounds:  [20, 19, 18, -1, 17, -2, 25]
  /// 9 rounds:  [20, 19, 18, -1, 17, 16, 15, -2, 25]
  /// 12 rounds: [20, 19, 18, -1, 17, 16, 15, -2, 14, 13, 12, 25]
  static List<int> sequenceFor(int roundCount) {
    switch (roundCount) {
      case 7:
        return [20, 19, 18, kTargetAnyDouble, 17, kTargetAnyTriple, kTargetBull];
      case 12:
        return [
          20, 19, 18, kTargetAnyDouble,
          17, 16, 15, kTargetAnyTriple,
          14, 13, 12, kTargetBull,
        ];
      case 9:
      default:
        return [
          20, 19, 18, kTargetAnyDouble,
          17, 16, 15, kTargetAnyTriple,
          kTargetBull,
        ];
    }
  }

  /// Returns a custom (randomized) target sequence for the given round count.
  ///
  /// Rules:
  /// - AD (kTargetAnyDouble) is always at index 3
  /// - AT (kTargetAnyTriple) is always at index 7 (9/12 rounds) or 5 (7 rounds)
  /// - Bull (kTargetBull) is always the final round
  /// - All other slots are filled with distinct random numbers from 1..20
  ///
  /// 7 rounds:  5 random + AD(idx 3) + AT(idx 5) + Bull(idx 6)
  /// 9 rounds:  7 random + AD(idx 3) + AT(idx 7) + Bull(idx 8)
  /// 12 rounds: 9 random + AD(idx 3) + AT(idx 7) + Bull(idx 11)
  static List<int> customSequenceFor(int roundCount, {Random? random}) {
    final rng = random ?? Random();

    // Shuffle 1..20 for random number picking
    final pool = List.generate(20, (i) => i + 1)..shuffle(rng);

    List<int> seq;
    switch (roundCount) {
      case 7:
        // Slots: 0,1,2=random; 3=AD; 4=random; 5=AT; 6=Bull
        seq = List.filled(7, 0);
        int poolIdx = 0;
        for (int i = 0; i < 7; i++) {
          if (i == 3) {
            seq[i] = kTargetAnyDouble;
          } else if (i == 5) {
            seq[i] = kTargetAnyTriple;
          } else if (i == 6) {
            seq[i] = kTargetBull;
          } else {
            seq[i] = pool[poolIdx++];
          }
        }
        break;
      case 12:
        // Slots: 0,1,2=random; 3=AD; 4,5,6=random; 7=AT; 8,9,10=random; 11=Bull
        seq = List.filled(12, 0);
        int poolIdx = 0;
        for (int i = 0; i < 12; i++) {
          if (i == 3) {
            seq[i] = kTargetAnyDouble;
          } else if (i == 7) {
            seq[i] = kTargetAnyTriple;
          } else if (i == 11) {
            seq[i] = kTargetBull;
          } else {
            seq[i] = pool[poolIdx++];
          }
        }
        break;
      case 9:
      default:
        // Slots: 0,1,2=random; 3=AD; 4,5,6=random; 7=AT; 8=Bull
        seq = List.filled(9, 0);
        int poolIdx = 0;
        for (int i = 0; i < 9; i++) {
          if (i == 3) {
            seq[i] = kTargetAnyDouble;
          } else if (i == 7) {
            seq[i] = kTargetAnyTriple;
          } else if (i == 8) {
            seq[i] = kTargetBull;
          } else {
            seq[i] = pool[poolIdx++];
          }
        }
        break;
    }
    return seq;
  }

  // ─── Computed Properties ──────────────────────────────────────────────────────

  bool get isGameActive => state == TreasureDivideGameState.playing;

  bool get hasWinner => state == TreasureDivideGameState.finished &&
      (winnerIds.isNotEmpty || winnerTeamIds.isNotEmpty);

  /// The dart budget for the currently active player's turn.
  /// Returns 6 when the active crew is a solo crew (1 member), else 3.
  int get dartsThisTurn {
    if (gameMode == TreasureDivideGameMode.team && activeTeamId != null) {
      final members = teamPlayers[activeTeamId] ?? [];
      if (members.length == 1) return 6;
    }
    return 3;
  }

  /// Computes the cumulative total for [playerId] by replaying all rounds with
  /// path-dependent halving. Completed rounds use stored hauls; incomplete
  /// rounds (null) are skipped.
  int totalForPlayer(String playerId) {
    final scores = playerRoundScores[playerId] ?? [];
    int total = 0;
    for (int i = 0; i < scores.length; i++) {
      final haul = scores[i];
      if (haul == null) continue; // not yet thrown
      if (haul > 0) {
        total += haul;
      } else {
        // All missed → halve/quarter
        final divisor = quarterItEnabled ? 4 : 2;
        total = (total / divisor).floor();
      }
    }
    return total;
  }

  /// Computes the cumulative crew treasure for [teamId] by replaying all
  /// rounds with path-dependent crew-wide halving.
  int totalForTeam(String teamId) {
    final members = teamPlayers[teamId] ?? [];
    int total = 0;
    for (int round = 0; round < numberOfRounds; round++) {
      // Check if all members have thrown in this round
      bool allThrown = members.every((pid) {
        final scores = playerRoundScores[pid];
        if (scores == null || round >= scores.length) return false;
        return scores[round] != null;
      });
      if (!allThrown) continue;

      // Sum hauls for this round
      int crewHaul = 0;
      bool anyHit = false;
      for (final pid in members) {
        final haul = playerRoundScores[pid]?[round] ?? 0;
        crewHaul += haul;
        if (haul > 0) anyHit = true;
      }

      if (anyHit) {
        total += crewHaul;
      } else {
        final divisor = quarterItEnabled ? 4 : 2;
        total = (total / divisor).floor();
      }
    }
    return total;
  }

  /// Returns the best single-round haul for [playerId] (for display/stats).
  int bestRoundHaul(String playerId) {
    final scores = playerRoundScores[playerId] ?? [];
    int best = 0;
    for (final s in scores) {
      if (s != null && s > best) best = s;
    }
    return best;
  }

  /// Returns the best single-round crew haul for [teamId] (for display/stats).
  int bestRoundHaulForTeam(String teamId) {
    final members = teamPlayers[teamId] ?? [];
    int best = 0;
    for (int round = 0; round < numberOfRounds; round++) {
      int crewHaul = 0;
      for (final pid in members) {
        crewHaul += playerRoundScores[pid]?[round] ?? 0;
      }
      if (crewHaul > best) best = crewHaul;
    }
    return best;
  }

  // ─── Serialization ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerIds': playerIds,
      'numberOfRounds': numberOfRounds,
      'quarterItEnabled': quarterItEnabled,
      'customTargetsEnabled': customTargetsEnabled,
      'gameMode': gameMode.name,
      'teamAssignment': teamAssignment.name,
      'teamCount': teamCount,
      'teamCrestPaths': teamCrestPaths,
      'targetSequence': targetSequence,
      'teamPlayers': teamPlayers.map(
        (k, v) => MapEntry(k, List<String>.from(v)),
      ),
      'playerTeamAssignments': playerTeamAssignments,
      'playerPirateThemes': playerPirateThemes.map(
        (k, v) => MapEntry(k, v),
      ),
      'state': state.name,
      'currentRoundIndex': currentRoundIndex,
      'currentPlayerId': currentPlayerId,
      'dartsThrown': dartsThrown,
      'currentTeamIndex': currentTeamIndex,
      'activeTeamId': activeTeamId,
      'teamWithinRoundRotationPointer': teamWithinRoundRotationPointer,
      'playerRoundScores': playerRoundScores.map(
        (k, v) => MapEntry(k, v.map((s) => s).toList()),
      ),
      'currentTurnDartSegments': currentTurnDartSegments,
      'totalDartsThrown': totalDartsThrown,
      'totalTurns': totalTurns,
      'timesHalvedPerPlayer': timesHalvedPerPlayer,
      'timesHalvedPerTeam': timesHalvedPerTeam,
      'shouldPromptTakeout': shouldPromptTakeout,
      'winnerIds': winnerIds,
      'winnerTeamIds': winnerTeamIds,
      'gameStartTime': gameStartTime?.toIso8601String(),
      'gameEndTime': gameEndTime?.toIso8601String(),
    };
  }

  factory TreasureDivideGame.fromJson(Map<String, dynamic> json) {
    // Helper: Map<String, int>
    Map<String, int> toIntMap(dynamic raw) {
      if (raw == null) return {};
      final m = raw as Map<dynamic, dynamic>;
      return m.map((k, v) => MapEntry(k as String, (v as num).toInt()));
    }

    // Helper: Map<String, List<String>>
    Map<String, List<String>> toListStringMap(dynamic raw) {
      if (raw == null) return {};
      final m = raw as Map<dynamic, dynamic>;
      return m.map(
        (k, v) => MapEntry(k as String, List<String>.from(v as List)),
      );
    }

    // Helper: Map<String, String>
    Map<String, String> toStringMap(dynamic raw) {
      if (raw == null) return {};
      final m = raw as Map<dynamic, dynamic>;
      return m.map((k, v) => MapEntry(k as String, v as String));
    }

    // Helper: Map<String, List<int?>> — nullable ints inside list
    Map<String, List<int?>> toNullableIntListMap(dynamic raw) {
      if (raw == null) return {};
      final m = raw as Map<dynamic, dynamic>;
      return m.map((k, v) {
        final list = v as List;
        return MapEntry(
          k as String,
          list.map<int?>((e) => e != null ? (e as num).toInt() : null).toList(),
        );
      });
    }

    final playerIds = List<String>.from(json['playerIds'] as List);

    return TreasureDivideGame(
      id: json['id'] as String,
      playerIds: playerIds,
      numberOfRounds: (json['numberOfRounds'] as num).toInt(),
      quarterItEnabled: json['quarterItEnabled'] as bool,
      customTargetsEnabled: json['customTargetsEnabled'] as bool,
      gameMode: TreasureDivideGameMode.values.firstWhere(
        (e) => e.name == json['gameMode'],
        orElse: () => TreasureDivideGameMode.solo,
      ),
      teamAssignment: TreasureDivideTeamAssignment.values.firstWhere(
        (e) => e.name == json['teamAssignment'],
        orElse: () => TreasureDivideTeamAssignment.random,
      ),
      teamCount: (json['teamCount'] as num).toInt(),
      teamCrestPaths: List<String>.from(json['teamCrestPaths'] as List),
      targetSequence: List<int>.from(
        (json['targetSequence'] as List).map((e) => (e as num).toInt()),
      ),
      teamPlayers: toListStringMap(json['teamPlayers']),
      playerTeamAssignments: toStringMap(json['playerTeamAssignments']),
      playerPirateThemes: toIntMap(json['playerPirateThemes']),
      state: TreasureDivideGameState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => TreasureDivideGameState.playing,
      ),
      currentRoundIndex: (json['currentRoundIndex'] as num).toInt(),
      currentPlayerId: json['currentPlayerId'] as String,
      dartsThrown: (json['dartsThrown'] as num).toInt(),
      currentTeamIndex: (json['currentTeamIndex'] as num?)?.toInt() ?? 0,
      activeTeamId: json['activeTeamId'] as String?,
      teamWithinRoundRotationPointer:
          toIntMap(json['teamWithinRoundRotationPointer']),
      playerRoundScores: toNullableIntListMap(json['playerRoundScores']),
      currentTurnDartSegments: toListStringMap(json['currentTurnDartSegments']),
      totalDartsThrown: toIntMap(json['totalDartsThrown']),
      totalTurns: toIntMap(json['totalTurns']),
      timesHalvedPerPlayer: toIntMap(json['timesHalvedPerPlayer']),
      timesHalvedPerTeam: toIntMap(json['timesHalvedPerTeam']),
      shouldPromptTakeout: json['shouldPromptTakeout'] as bool? ?? false,
      winnerIds: json['winnerIds'] != null
          ? List<String>.from(json['winnerIds'] as List)
          : [],
      winnerTeamIds: json['winnerTeamIds'] != null
          ? List<String>.from(json['winnerTeamIds'] as List)
          : [],
      gameStartTime: json['gameStartTime'] != null
          ? DateTime.parse(json['gameStartTime'] as String)
          : null,
      gameEndTime: json['gameEndTime'] != null
          ? DateTime.parse(json['gameEndTime'] as String)
          : null,
    );
  }
}

