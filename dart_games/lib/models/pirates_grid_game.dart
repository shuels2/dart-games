import 'package:uuid/uuid.dart';
import 'player.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum TargetDifficulty {
  easy,   // Any hit on number claims square (S/D/T all OK)
  medium, // Must hit double or triple of the number
  hard,   // Per-cell specific requirement (T = triple only, D = double only, Bull = bullseye)
}

enum CellRequirement {
  any,            // Easy: S/D/T all count
  doubleOrTriple, // Medium: D or T only, not S
  doubleOnly,     // Hard edge cells: D only
  tripleOnly,     // Hard corner cells: T only
  bull,           // Hard center cell: 25 (outer bull) OR 50 (inner bull)
}

enum GameState {
  setup,
  playing,
  finished,
}

// ─── CellTarget ───────────────────────────────────────────────────────────────

/// Immutable cell target requirement.
class CellTarget {
  final int number;                    // 0 means "Bull" cell (special — number is irrelevant)
  final CellRequirement requirement;

  const CellTarget({required this.number, required this.requirement});

  /// Returns true if a dart hit (dartNumber, dartMultiplier) satisfies this cell.
  /// dartMultiplier: 1 = single, 2 = double, 3 = triple
  /// For Bull cells, dartNumber=25 (outer bull) or dartNumber=50 (inner bull).
  bool matches(int dartNumber, int dartMultiplier) {
    switch (requirement) {
      case CellRequirement.bull:
        // Inner bull (50) or outer bull (25)
        return (dartNumber == 25 || dartNumber == 50);
      case CellRequirement.any:
        return dartNumber == number;
      case CellRequirement.doubleOrTriple:
        return dartNumber == number && (dartMultiplier == 2 || dartMultiplier == 3);
      case CellRequirement.doubleOnly:
        return dartNumber == number && dartMultiplier == 2;
      case CellRequirement.tripleOnly:
        return dartNumber == number && dartMultiplier == 3;
    }
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'requirement': requirement.name,
  };

  factory CellTarget.fromJson(Map<String, dynamic> json) => CellTarget(
    number: json['number'] as int,
    requirement: CellRequirement.values.firstWhere(
      (e) => e.name == json['requirement'],
      orElse: () => CellRequirement.any,
    ),
  );
}

// ─── GridPosition ─────────────────────────────────────────────────────────────

/// Grid position (row, col).
class GridPosition {
  final int row; // 0..2
  final int col; // 0..2

  const GridPosition(this.row, this.col);

  Map<String, dynamic> toJson() => {'row': row, 'col': col};

  factory GridPosition.fromJson(Map<String, dynamic> json) =>
      GridPosition(json['row'] as int, json['col'] as int);

  @override
  bool operator ==(Object other) =>
      other is GridPosition && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'GridPosition($row, $col)';
}

// ─── GridCell ─────────────────────────────────────────────────────────────────

/// State of one cell in the grid.
class GridCell {
  final CellTarget target;  // immutable target requirement
  String? claimedBy;        // playerId who has flag here, null = empty

  GridCell({required this.target, this.claimedBy});

  Map<String, dynamic> toJson() => {
    'target': target.toJson(),
    'claimedBy': claimedBy,
  };

  factory GridCell.fromJson(Map<String, dynamic> json) => GridCell(
    target: CellTarget.fromJson(Map<String, dynamic>.from(json['target'])),
    claimedBy: json['claimedBy'] as String?,
  );
}

// ─── PiratesGridGame ──────────────────────────────────────────────────────────

class PiratesGridGame {
  // Identity / setup
  final String id;
  final DateTime startedAt;
  final List<String> playerIds; // exactly 2

  // Settings (immutable per game)
  final TargetDifficulty targetDifficulty;
  final int bestOf;         // 1, 3, or 5
  final bool stealMode;
  final bool speedPlay;

  // Grid state (mutable)
  List<List<GridCell>> grid; // 3x3

  // Turn management
  int currentPlayerIndex;                             // 0 or 1
  Map<String, int> dartsThrown;                       // current turn, per player
  Map<String, int> totalDartsThrown;                  // cumulative
  Map<String, int> totalTurns;                        // cumulative
  Map<String, List<String>> currentTurnDartSegments;  // for save/restore + edit score

  // Round / match state
  int currentRound;                        // 1-based, capped at bestOf
  Map<String, int> roundsWon;
  int currentRoundStartingPlayerIndex;     // alternates between rounds

  // Per-round outcome
  String? winnerId;              // round winner; null = no round winner yet
  bool isDraw;                   // round ended in draw
  List<GridPosition>? winningLine; // 3 cells of the winning line

  // Per-round history
  Map<String, List<int>> flagsPlantedPerRound;  // playerId → [round1flags, round2flags, ...]

  // Per-match outcome
  String? matchWinnerId;         // match winner (final); null until match decided
  bool isMatchDraw;              // entire Best Of ended in draws

  // Lifecycle
  GameState state;
  DateTime? gameEndTime;

  PiratesGridGame({
    required this.id,
    required this.startedAt,
    required this.playerIds,
    required this.targetDifficulty,
    required this.bestOf,
    required this.stealMode,
    required this.speedPlay,
    required this.grid,
    this.currentPlayerIndex = 0,
    Map<String, int>? dartsThrown,
    Map<String, int>? totalDartsThrown,
    Map<String, int>? totalTurns,
    Map<String, List<String>>? currentTurnDartSegments,
    this.currentRound = 1,
    Map<String, int>? roundsWon,
    this.currentRoundStartingPlayerIndex = 0,
    this.winnerId,
    this.isDraw = false,
    this.winningLine,
    Map<String, List<int>>? flagsPlantedPerRound,
    this.matchWinnerId,
    this.isMatchDraw = false,
    this.state = GameState.playing,
    this.gameEndTime,
  })  : dartsThrown = dartsThrown ?? {},
        totalDartsThrown = totalDartsThrown ?? {},
        totalTurns = totalTurns ?? {},
        currentTurnDartSegments = currentTurnDartSegments ?? {},
        roundsWon = roundsWon ?? {},
        flagsPlantedPerRound = flagsPlantedPerRound ?? {} {
    // Ensure all player maps are initialized
    for (final playerId in playerIds) {
      this.dartsThrown[playerId] ??= 0;
      this.totalDartsThrown[playerId] ??= 0;
      this.totalTurns[playerId] ??= 0;
      this.currentTurnDartSegments[playerId] ??= [];
      this.roundsWon[playerId] ??= 0;
      this.flagsPlantedPerRound[playerId] ??= [];
    }
  }

  // ─── Helper methods ──────────────────────────────────────────────────────────

  String getCurrentPlayerId() => playerIds[currentPlayerIndex];

  String getOpponentPlayerId(String playerId) {
    return playerIds.firstWhere((id) => id != playerId);
  }

  int getCurrentPlayerDartsThrown() {
    final currentPlayerId = getCurrentPlayerId();
    return dartsThrown[currentPlayerId] ?? 0;
  }

  List<String> getCurrentTurnDarts(String playerId) {
    return currentTurnDartSegments[playerId] ?? [];
  }

  int getFlagsPlanted(String playerId) {
    int count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell.claimedBy == playerId) count++;
      }
    }
    return count;
  }

  bool hasWinner() {
    return matchWinnerId != null || isMatchDraw;
  }

  bool isGridFull() {
    for (final row in grid) {
      for (final cell in row) {
        if (cell.claimedBy == null) return false;
      }
    }
    return true;
  }

  Player? getWinner(List<Player> players) {
    if (matchWinnerId == null) return null;
    try {
      return players.firstWhere((p) => p.id == matchWinnerId);
    } catch (e) {
      return null;
    }
  }

  // ─── Serialization ───────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'playerIds': playerIds,
      'targetDifficulty': targetDifficulty.name,
      'bestOf': bestOf,
      'stealMode': stealMode,
      'speedPlay': speedPlay,
      // Grid: 3x3 array of GridCell JSON
      'grid': grid.map((row) => row.map((cell) => cell.toJson()).toList()).toList(),
      'currentPlayerIndex': currentPlayerIndex,
      // Map<String, int> → JSON-safe (String keys)
      'dartsThrown': dartsThrown,
      'totalDartsThrown': totalDartsThrown,
      'totalTurns': totalTurns,
      // Map<String, List<String>> → JSON-safe
      'currentTurnDartSegments': currentTurnDartSegments.map(
        (k, v) => MapEntry(k, List<String>.from(v)),
      ),
      'currentRound': currentRound,
      'roundsWon': roundsWon,
      'flagsPlantedPerRound': flagsPlantedPerRound.map(
        (k, v) => MapEntry(k, List<int>.from(v)),
      ),
      'currentRoundStartingPlayerIndex': currentRoundStartingPlayerIndex,
      'winnerId': winnerId,
      'isDraw': isDraw,
      'winningLine': winningLine?.map((p) => p.toJson()).toList(),
      'matchWinnerId': matchWinnerId,
      'isMatchDraw': isMatchDraw,
      'state': state.name,
      'gameEndTime': gameEndTime?.toIso8601String(),
    };
  }

  factory PiratesGridGame.fromJson(Map<String, dynamic> json) {
    // Deserialize grid
    final gridData = json['grid'] as List<dynamic>;
    final grid = gridData.map((rowData) {
      return (rowData as List<dynamic>).map((cellData) {
        return GridCell.fromJson(Map<String, dynamic>.from(cellData));
      }).toList();
    }).toList();

    // Deserialize winningLine
    List<GridPosition>? winningLine;
    if (json['winningLine'] != null) {
      winningLine = (json['winningLine'] as List<dynamic>)
          .map((p) => GridPosition.fromJson(Map<String, dynamic>.from(p)))
          .toList();
    }

    return PiratesGridGame(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      playerIds: List<String>.from(json['playerIds']),
      targetDifficulty: TargetDifficulty.values.firstWhere(
        (e) => e.name == json['targetDifficulty'],
        orElse: () => TargetDifficulty.easy,
      ),
      bestOf: json['bestOf'] as int,
      stealMode: json['stealMode'] as bool,
      speedPlay: json['speedPlay'] as bool,
      grid: grid,
      currentPlayerIndex: json['currentPlayerIndex'] as int,
      dartsThrown: json['dartsThrown'] != null
          ? Map<String, int>.from(json['dartsThrown'])
          : null,
      totalDartsThrown: json['totalDartsThrown'] != null
          ? Map<String, int>.from(json['totalDartsThrown'])
          : null,
      totalTurns: json['totalTurns'] != null
          ? Map<String, int>.from(json['totalTurns'])
          : null,
      currentTurnDartSegments: json['currentTurnDartSegments'] != null
          ? (json['currentTurnDartSegments'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<String>.from(v)))
          : null,
      currentRound: json['currentRound'] as int? ?? 1,
      roundsWon: json['roundsWon'] != null
          ? Map<String, int>.from(json['roundsWon'])
          : null,
      flagsPlantedPerRound: json['flagsPlantedPerRound'] != null
          ? (json['flagsPlantedPerRound'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<int>.from(v)))
          : null,
      currentRoundStartingPlayerIndex:
          json['currentRoundStartingPlayerIndex'] as int? ?? 0,
      winnerId: json['winnerId'] as String?,
      isDraw: json['isDraw'] as bool? ?? false,
      winningLine: winningLine,
      matchWinnerId: json['matchWinnerId'] as String?,
      isMatchDraw: json['isMatchDraw'] as bool? ?? false,
      state: GameState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => GameState.playing,
      ),
      gameEndTime: json['gameEndTime'] != null
          ? DateTime.parse(json['gameEndTime'] as String)
          : null,
    );
  }
}
