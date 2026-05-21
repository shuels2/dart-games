import 'dart:math';
import 'package:uuid/uuid.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum TikiGolfGameMode { solo, team }

enum TikiGolfTeamAssignment { manual, random }

enum TikiGolfGameState { playing, finished }

// ─── Asset Constants ──────────────────────────────────────────────────────────

/// The 9 hole-theme image paths in canonical order (will be shuffled per game).
const _kHoleImagePaths = [
  'assets/games/tiki_golf/pieces/Volcano.png',
  'assets/games/tiki_golf/pieces/Waterfall.png',
  'assets/games/tiki_golf/pieces/TikiStatue.png',
  'assets/games/tiki_golf/pieces/PalmTree.png',
  'assets/games/tiki_golf/pieces/Lagoon.png',
  'assets/games/tiki_golf/pieces/Shipwreck.png',
  'assets/games/tiki_golf/pieces/BambooTemple.png',
  'assets/games/tiki_golf/pieces/CoralReef.png',
  'assets/games/tiki_golf/pieces/SunsetPier.png',
];

/// All 6 available team crest paths.
const _kAllCrestPaths = [
  'assets/games/tiki_golf/teams/Sharks.png',
  'assets/games/tiki_golf/teams/SeaTurtles.png',
  'assets/games/tiki_golf/teams/Hibiscus.png',
  'assets/games/tiki_golf/teams/Volcanoes.png',
  'assets/games/tiki_golf/teams/Coconuts.png',
  'assets/games/tiki_golf/teams/Parrots.png',
];

// ─── TikiGolfGame ─────────────────────────────────────────────────────────────

class TikiGolfGame {
  // --- Identity ---
  final String id;

  // --- Players ---
  final List<String> playerIds;

  // --- Options ---

  /// Max darts per player per hole. Range 3-6, default 3.
  final int maxStrokes;

  /// Whether each player gets one mulligan re-throw per game.
  final bool mulliganEnabled;

  /// Solo or Team mode.
  final TikiGolfGameMode gameMode;

  /// Manual or Random team assignment (only meaningful in Team mode).
  final TikiGolfTeamAssignment teamAssignment;

  /// Number of teams in Team mode (2-4). In Random mode this is derived from
  /// playerIds.length at game start and stored here for display.
  final int teamCount;

  // --- Per-Game Randomization (locked at game-start) ---

  /// Length 9 — one distinct target number (1..20) per hole, shuffled per game.
  final List<int> holeTargets;

  /// Length 9 — full shuffle of the 9 hole-theme image paths per game.
  final List<String> holeImagePaths;

  /// Length [teamCount] — crests selected from the 6 available at game start.
  final List<String> teamCrestPaths;

  // --- Team Structure (frozen at game start) ---

  /// teamId → list of playerIds on that team.
  final Map<String, List<String>> teamPlayers;

  /// playerId → teamId (inverse lookup).
  final Map<String, String> playerTeamAssignments;

  // --- Runtime State ---

  TikiGolfGameState state;

  /// 1-indexed current hole (1..9). Values > 9 indicate game completed.
  int currentHole;

  /// playerId → list of 9 hole scores (null = not played, int = completed).
  Map<String, List<int?>> playerHoleScores;

  /// playerId → 0 (available) or 1 (used).
  Map<String, int> playerMulligansUsed;

  /// Current-turn dart count per player (resets after each confirmTurnEnd).
  Map<String, int> dartsThrown;

  /// Canonical turn counter: increments exactly once per turn on first dart.
  Map<String, int> totalTurns;

  /// Active player id.
  String? activePlayerId;

  /// Active team id (Team mode only).
  String? activeTeamId;

  /// teamId → index of next player on that team to play within the current hole.
  Map<String, int> teamWithinHoleRotationPointer;

  /// 0-based index of the team currently playing (Team mode only).
  int currentTeamIndex;

  /// True once a turn-end condition fires (hit / all darts missed / skip turn).
  /// Resets to false after confirmTurnEnd completes.
  bool currentTurnEnded;

  String? winnerId;
  String? winnerTeamId;

  /// All players tied at the lowest total (solo mode). Length 1 = solo
  /// outright win; length 2+ = solo tie. Null until [endGame] runs.
  List<String>? winnerIds;

  /// All teams tied at the lowest team total (team mode). Length 1 = team
  /// outright win; length 2+ = team tie. Null until [endGame] runs.
  List<String>? winnerTeamIds;

  DateTime? gameStartTime;
  DateTime? gameEndTime;

  // ─── Constructor ─────────────────────────────────────────────────────────────

  TikiGolfGame({
    required this.id,
    required this.playerIds,
    required this.maxStrokes,
    required this.mulliganEnabled,
    required this.gameMode,
    required this.teamAssignment,
    required this.teamCount,
    required this.holeTargets,
    required this.holeImagePaths,
    required this.teamCrestPaths,
    required this.teamPlayers,
    required this.playerTeamAssignments,
    this.state = TikiGolfGameState.playing,
    this.currentHole = 1,
    Map<String, List<int?>>? playerHoleScores,
    Map<String, int>? playerMulligansUsed,
    Map<String, int>? dartsThrown,
    Map<String, int>? totalTurns,
    this.activePlayerId,
    this.activeTeamId,
    Map<String, int>? teamWithinHoleRotationPointer,
    this.currentTeamIndex = 0,
    this.currentTurnEnded = false,
    this.winnerId,
    this.winnerTeamId,
    this.winnerIds,
    this.winnerTeamIds,
    this.gameStartTime,
    this.gameEndTime,
  })  : playerHoleScores = playerHoleScores ??
            {for (final id in playerIds) id: List.filled(9, null)},
        playerMulligansUsed =
            playerMulligansUsed ?? {for (final id in playerIds) id: 0},
        dartsThrown = dartsThrown ?? {for (final id in playerIds) id: 0},
        totalTurns = totalTurns ?? {for (final id in playerIds) id: 0},
        teamWithinHoleRotationPointer = teamWithinHoleRotationPointer ??
            {for (final teamId in teamPlayers.keys) teamId: 0};

  // ─── Factory: Create a new game ───────────────────────────────────────────────

  factory TikiGolfGame.create({
    required List<String> playerIds,
    required int maxStrokes,
    required bool mulliganEnabled,
    required TikiGolfGameMode gameMode,
    required TikiGolfTeamAssignment teamAssignment,
    required int teamCount,
    required Map<String, List<String>> teamPlayers,
    required Map<String, String> playerTeamAssignments,
    Random? random,
  }) {
    final rng = random ?? Random();

    // --- holeTargets: pick 9 distinct numbers from 1..20 ---
    final numbers = List.generate(20, (i) => i + 1)..shuffle(rng);
    final holeTargets = numbers.take(9).toList();

    // --- holeImagePaths: shuffle the 9 canonical paths ---
    final holeImagePaths = List<String>.from(_kHoleImagePaths)..shuffle(rng);

    // --- teamCrestPaths: shuffle all 6 crests, take teamCount ---
    final shuffledCrests = List<String>.from(_kAllCrestPaths)..shuffle(rng);
    final teamCrestPaths = shuffledCrests.take(teamCount).toList();

    return TikiGolfGame(
      id: const Uuid().v4(),
      playerIds: playerIds,
      maxStrokes: maxStrokes,
      mulliganEnabled: mulliganEnabled,
      gameMode: gameMode,
      teamAssignment: teamAssignment,
      teamCount: teamCount,
      holeTargets: holeTargets,
      holeImagePaths: holeImagePaths,
      teamCrestPaths: teamCrestPaths,
      teamPlayers: teamPlayers,
      playerTeamAssignments: playerTeamAssignments,
      state: TikiGolfGameState.playing,
      currentHole: 1,
      playerHoleScores: {
        for (final id in playerIds) id: List.filled(9, null)
      },
      playerMulligansUsed: {for (final id in playerIds) id: 0},
      dartsThrown: {for (final id in playerIds) id: 0},
      totalTurns: {for (final id in playerIds) id: 0},
      activePlayerId: playerIds.isNotEmpty ? playerIds.first : null,
      activeTeamId: gameMode == TikiGolfGameMode.team &&
              teamPlayers.isNotEmpty
          ? teamPlayers.keys.first
          : null,
      teamWithinHoleRotationPointer: {
        for (final teamId in teamPlayers.keys) teamId: 0
      },
      currentTeamIndex: 0,
      currentTurnEnded: false,
      gameStartTime: DateTime.now(),
    );
  }

  // ─── Computed Properties ──────────────────────────────────────────────────────

  bool get isGameActive => state == TikiGolfGameState.playing;

  /// True when every active player has a score for [currentHole].
  bool get isCurrentHoleComplete {
    final holeIndex = currentHole - 1;
    if (holeIndex < 0 || holeIndex >= 9) return true;
    for (final id in playerIds) {
      final scores = playerHoleScores[id];
      if (scores == null || scores[holeIndex] == null) return false;
    }
    return true;
  }

  bool get isAtFinalHole => currentHole == 9;

  bool get hasWinner => winnerId != null || winnerTeamId != null;

  /// Sum of completed hole scores for [playerId].
  int totalForPlayer(String playerId) {
    final scores = playerHoleScores[playerId] ?? [];
    return scores.fold<int>(0, (sum, s) => sum + (s ?? 0));
  }

  /// Sum of per-hole best-ball scores for [teamId].
  int totalForTeam(String teamId) {
    int total = 0;
    for (int i = 0; i < 9; i++) {
      final best = bestBallForTeam(teamId, i);
      if (best != null) total += best;
    }
    return total;
  }

  /// MIN of teammates' scores for [holeIndex]; null if no teammate has played.
  int? bestBallForTeam(String teamId, int holeIndex) {
    final members = teamPlayers[teamId] ?? [];
    int? best;
    for (final pid in members) {
      final score = playerHoleScores[pid]?[holeIndex];
      if (score != null) {
        best = best == null ? score : (score < best ? score : best);
      }
    }
    return best;
  }

  /// Count of holes where [playerId]'s score == 1 (birdie).
  int birdiesForPlayer(String playerId) {
    final scores = playerHoleScores[playerId] ?? [];
    return scores.where((s) => s == 1).length;
  }

  /// Count of holes where [playerId]'s score >= 3 (bogey or worse).
  int bogeysForPlayer(String playerId) {
    final scores = playerHoleScores[playerId] ?? [];
    return scores.where((s) => s != null && s >= 3).length;
  }

  /// Count of holes where the team's best-ball score == 1.
  int teamBirdies(String teamId) {
    int count = 0;
    for (int i = 0; i < 9; i++) {
      if (bestBallForTeam(teamId, i) == 1) count++;
    }
    return count;
  }

  /// Count of holes where the team's best-ball score >= 3.
  int teamBogeys(String teamId) {
    int count = 0;
    for (int i = 0; i < 9; i++) {
      final best = bestBallForTeam(teamId, i);
      if (best != null && best >= 3) count++;
    }
    return count;
  }

  // ─── Serialization ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerIds': playerIds,
      'maxStrokes': maxStrokes,
      'mulliganEnabled': mulliganEnabled,
      'gameMode': gameMode.name,
      'teamAssignment': teamAssignment.name,
      'teamCount': teamCount,
      'holeTargets': holeTargets,
      'holeImagePaths': holeImagePaths,
      'teamCrestPaths': teamCrestPaths,
      'teamPlayers': teamPlayers.map(
        (k, v) => MapEntry(k, List<String>.from(v)),
      ),
      'playerTeamAssignments': playerTeamAssignments,
      'state': state.name,
      'currentHole': currentHole,
      'playerHoleScores': playerHoleScores.map(
        (k, v) => MapEntry(k, v.map((s) => s).toList()),
      ),
      'playerMulligansUsed': playerMulligansUsed,
      'dartsThrown': dartsThrown,
      'totalTurns': totalTurns,
      'activePlayerId': activePlayerId,
      'activeTeamId': activeTeamId,
      'teamWithinHoleRotationPointer': teamWithinHoleRotationPointer,
      'currentTeamIndex': currentTeamIndex,
      'currentTurnEnded': currentTurnEnded,
      'winnerId': winnerId,
      'winnerTeamId': winnerTeamId,
      'winnerIds': winnerIds,
      'winnerTeamIds': winnerTeamIds,
      'gameStartTime': gameStartTime?.toIso8601String(),
      'gameEndTime': gameEndTime?.toIso8601String(),
    };
  }

  factory TikiGolfGame.fromJson(Map<String, dynamic> json) {
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

    return TikiGolfGame(
      id: json['id'] as String,
      playerIds: playerIds,
      maxStrokes: (json['maxStrokes'] as num).toInt(),
      mulliganEnabled: json['mulliganEnabled'] as bool,
      gameMode: TikiGolfGameMode.values.firstWhere(
        (e) => e.name == json['gameMode'],
        orElse: () => TikiGolfGameMode.solo,
      ),
      teamAssignment: TikiGolfTeamAssignment.values.firstWhere(
        (e) => e.name == json['teamAssignment'],
        orElse: () => TikiGolfTeamAssignment.random,
      ),
      teamCount: (json['teamCount'] as num).toInt(),
      holeTargets: List<int>.from(
        (json['holeTargets'] as List).map((e) => (e as num).toInt()),
      ),
      holeImagePaths: List<String>.from(json['holeImagePaths'] as List),
      teamCrestPaths: List<String>.from(json['teamCrestPaths'] as List),
      teamPlayers: toListStringMap(json['teamPlayers']),
      playerTeamAssignments: toStringMap(json['playerTeamAssignments']),
      state: TikiGolfGameState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => TikiGolfGameState.playing,
      ),
      currentHole: (json['currentHole'] as num).toInt(),
      playerHoleScores: toNullableIntListMap(json['playerHoleScores']),
      playerMulligansUsed: toIntMap(json['playerMulligansUsed']),
      dartsThrown: toIntMap(json['dartsThrown']),
      totalTurns: toIntMap(json['totalTurns']),
      activePlayerId: json['activePlayerId'] as String?,
      activeTeamId: json['activeTeamId'] as String?,
      teamWithinHoleRotationPointer:
          toIntMap(json['teamWithinHoleRotationPointer']),
      currentTeamIndex: (json['currentTeamIndex'] as num?)?.toInt() ?? 0,
      currentTurnEnded: json['currentTurnEnded'] as bool? ?? false,
      winnerId: json['winnerId'] as String?,
      winnerTeamId: json['winnerTeamId'] as String?,
      winnerIds: json['winnerIds'] != null
          ? List<String>.from(json['winnerIds'] as List)
          : null,
      winnerTeamIds: json['winnerTeamIds'] != null
          ? List<String>.from(json['winnerTeamIds'] as List)
          : null,
      gameStartTime: json['gameStartTime'] != null
          ? DateTime.parse(json['gameStartTime'] as String)
          : null,
      gameEndTime: json['gameEndTime'] != null
          ? DateTime.parse(json['gameEndTime'] as String)
          : null,
    );
  }
}
